import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { Calendar, DollarSign, Users, ChevronRight } from 'lucide-react-native';
import { PayrollPeriod } from '@/types/payroll';

interface PayrollPeriodCardProps {
  period: PayrollPeriod;
  onPress: () => void;
}

export function PayrollPeriodCard({ period, onPress }: PayrollPeriodCardProps) {
  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft': return '#fbbf24';
      case 'processed': return '#3b82f6';
      case 'paid': return '#10b981';
      default: return '#666';
    }
  };

  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.header}>
        <View style={styles.dateContainer}>
          <Calendar size={16} color="#666" />
          <Text style={styles.dateText}>
            {formatDate(period.startDate)} - {formatDate(period.endDate)}
          </Text>
        </View>
        <View style={[styles.statusBadge, { backgroundColor: `${getStatusColor(period.status)}20` }]}>
          <Text style={[styles.statusText, { color: getStatusColor(period.status) }]}>
            {period.status}
          </Text>
        </View>
      </View>

      <View style={styles.stats}>
        <View style={styles.statItem}>
          <Users size={20} color="#666" />
          <Text style={styles.statValue}>{period.employeeCount}</Text>
          <Text style={styles.statLabel}>Employees</Text>
        </View>
        
        <View style={styles.divider} />
        
        <View style={styles.statItem}>
        <DollarSign size={20} color="#10b981" />
          <Text style={styles.statValue}>Rs {period.totalGross.toLocaleString()}</Text>
          <Text style={styles.statLabel}>Gross Pay</Text>
        </View>
        
        <View style={styles.divider} />
        
        <View style={styles.statItem}>
        <DollarSign size={20} color="#2563eb" />
          <Text style={styles.statValue}>Rs {period.totalNet.toLocaleString()}</Text>
          <Text style={styles.statLabel}>Net Pay</Text>
        </View>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>View Details</Text>
        <ChevronRight size={16} color="#666" />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  dateContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dateText: {
    fontSize: 14,
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
  stats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 12,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#f0f0f0',
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginTop: 4,
  },
  statLabel: {
    fontSize: 11,
    color: '#999',
    marginTop: 2,
  },
  divider: {
    width: 1,
    backgroundColor: '#f0f0f0',
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 12,
  },
  footerText: {
    fontSize: 14,
    color: '#666',
    marginRight: 4,
  },
});