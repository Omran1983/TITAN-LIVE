import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams } from 'expo-router';
import { Calendar, DollarSign, User } from 'lucide-react-native';
import { usePayroll, usePayrollEntriesByPeriod, useEmployeeById } from '@/hooks/payroll-store';

export default function PayrollDetailsScreen() {
  const { periodId } = useLocalSearchParams();
  const { payrollPeriods } = usePayroll();
  const entries = usePayrollEntriesByPeriod(periodId as string);
  const period = payrollPeriods.find(p => p.id === periodId);

  if (!period) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>Payroll period not found</Text>
        </View>
      </SafeAreaView>
    );
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', { 
      month: 'long', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <View style={styles.periodInfo}>
            <Calendar size={20} color="#666" />
            <Text style={styles.periodText}>
              {formatDate(period.startDate)} - {formatDate(period.endDate)}
            </Text>
          </View>
          <View style={[styles.statusBadge, { backgroundColor: getStatusColor(period.status) + '20' }]}>
            <Text style={[styles.statusText, { color: getStatusColor(period.status) }]}>
              {period.status}
            </Text>
          </View>
        </View>

        <View style={styles.summaryCards}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Gross</Text>
            <Text style={styles.summaryValue}>${period.totalGross.toLocaleString()}</Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Deductions</Text>
            <Text style={[styles.summaryValue, { color: '#ef4444' }]}>
              -${period.totalDeductions.toLocaleString()}
            </Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryLabel}>Total Net</Text>
            <Text style={[styles.summaryValue, { color: '#10b981' }]}>
              ${period.totalNet.toLocaleString()}
            </Text>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Employee Breakdown</Text>
          {entries.map(entry => (
            <EmployeePayrollCard key={entry.id} entry={entry} />
          ))}
        </View>

        {period.processedDate && (
          <View style={styles.footer}>
            <Text style={styles.footerText}>
              Processed on {formatDate(period.processedDate)}
            </Text>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function EmployeePayrollCard({ entry }: { entry: any }) {
  const employee = useEmployeeById(entry.employeeId);
  
  if (!employee) return null;

  return (
    <View style={styles.employeeCard}>
      <View style={styles.employeeHeader}>
        <View style={styles.employeeInfo}>
          <View style={styles.avatar}>
            <User size={20} color="#666" />
          </View>
          <View>
            <Text style={styles.employeeName}>
              {employee.firstName} {employee.lastName}
            </Text>
            <Text style={styles.employeePosition}>{employee.position}</Text>
          </View>
        </View>
      </View>

      <View style={styles.payDetails}>
        <View style={styles.payRow}>
          <Text style={styles.payLabel}>Hours Worked</Text>
          <Text style={styles.payValue}>{entry.hoursWorked}</Text>
        </View>
        <View style={styles.payRow}>
          <Text style={styles.payLabel}>Regular Hours</Text>
          <Text style={styles.payValue}>{entry.regularHours}</Text>
        </View>
        {entry.overtimeHours > 0 && (
          <View style={styles.payRow}>
            <Text style={styles.payLabel}>Overtime Hours</Text>
            <Text style={styles.payValue}>{entry.overtimeHours}</Text>
          </View>
        )}
        <View style={[styles.payRow, styles.payRowBorder]}>
          <Text style={styles.payLabel}>Gross Pay</Text>
          <Text style={styles.payValue}>${entry.grossPay.toLocaleString()}</Text>
        </View>
        
        {entry.deductions.map((deduction: any, index: number) => (
          <View key={index} style={styles.payRow}>
            <Text style={styles.deductionLabel}>{deduction.deductionId}</Text>
            <Text style={styles.deductionValue}>-${deduction.amount.toFixed(2)}</Text>
          </View>
        ))}
        
        <View style={[styles.payRow, styles.payRowBorder]}>
          <Text style={styles.netLabel}>Net Pay</Text>
          <Text style={styles.netValue}>${entry.netPay.toLocaleString()}</Text>
        </View>
      </View>
    </View>
  );
}

function getStatusColor(status: string) {
  switch (status) {
    case 'draft': return '#fbbf24';
    case 'processed': return '#3b82f6';
    case 'paid': return '#10b981';
    default: return '#666';
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e5e5e5',
  },
  periodInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  periodText: {
    fontSize: 15,
    color: '#333',
    marginLeft: 8,
    fontWeight: '500',
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusText: {
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  summaryCards: {
    padding: 20,
    gap: 12,
  },
  summaryCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  summaryLabel: {
    fontSize: 14,
    color: '#666',
  },
  summaryValue: {
    fontSize: 20,
    fontWeight: '700',
    color: '#333',
  },
  section: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 16,
  },
  employeeCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
  },
  employeeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  employeeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f0f0f0',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  employeeName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
  },
  employeePosition: {
    fontSize: 13,
    color: '#666',
    marginTop: 2,
  },
  payDetails: {
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    paddingTop: 12,
  },
  payRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  payRowBorder: {
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    marginTop: 8,
  },
  payLabel: {
    fontSize: 14,
    color: '#666',
  },
  payValue: {
    fontSize: 14,
    fontWeight: '500',
    color: '#333',
  },
  deductionLabel: {
    fontSize: 13,
    color: '#999',
    marginLeft: 16,
  },
  deductionValue: {
    fontSize: 13,
    color: '#ef4444',
  },
  netLabel: {
    fontSize: 15,
    fontWeight: '600',
    color: '#333',
  },
  netValue: {
    fontSize: 16,
    fontWeight: '700',
    color: '#10b981',
  },
  footer: {
    padding: 20,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 13,
    color: '#666',
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: '#666',
  },
});