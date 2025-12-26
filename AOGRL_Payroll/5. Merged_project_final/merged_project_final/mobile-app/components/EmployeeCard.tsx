import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { User, Mail, Phone, Briefcase } from 'lucide-react-native';
import { Employee } from '@/types/payroll';

interface EmployeeCardProps {
  employee: Employee;
  onPress: () => void;
}

export function EmployeeCard({ employee, onPress }: EmployeeCardProps) {
  // Format pay rate as Mauritian Rupees (Rs).  Salaried rates are displayed per year,
  // hourly rates per hour.  Adjust as needed for other currencies or frequencies.
  const formatSalary = (payType: string, payRate: number) => {
    if (payType === 'salary') {
      return `Rs ${payRate.toLocaleString()}/year`;
    }
    return `Rs ${payRate}/hour`;
  };

  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.7}>
      <View style={styles.header}>
        <View style={styles.avatar}>
          <User size={24} color="#666" />
        </View>
        <View style={styles.headerInfo}>
          <Text style={styles.name}>{employee.firstName} {employee.lastName}</Text>
          <Text style={styles.position}>{employee.position}</Text>
        </View>
        <View style={[styles.statusBadge, employee.status === 'active' ? styles.active : styles.inactive]}>
          <Text style={styles.statusText}>{employee.status}</Text>
        </View>
      </View>
      
      <View style={styles.details}>
        <View style={styles.detailRow}>
          <Mail size={16} color="#666" />
          <Text style={styles.detailText}>{employee.email}</Text>
        </View>
        <View style={styles.detailRow}>
          <Phone size={16} color="#666" />
          <Text style={styles.detailText}>{employee.phone}</Text>
        </View>
        <View style={styles.detailRow}>
          <Briefcase size={16} color="#666" />
          <Text style={styles.detailText}>{employee.department}</Text>
        </View>
      </View>
      
      <View style={styles.footer}>
        <Text style={styles.salaryText}>{formatSalary(employee.payType, employee.payRate)}</Text>
        <Text style={styles.typeText}>{employee.employmentType}</Text>
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
    alignItems: 'center',
    marginBottom: 12,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#f0f0f0',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  headerInfo: {
    flex: 1,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  position: {
    fontSize: 14,
    color: '#666',
    marginTop: 2,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  active: {
    backgroundColor: '#d4f4dd',
  },
  inactive: {
    backgroundColor: '#ffe4e1',
  },
  statusText: {
    fontSize: 12,
    fontWeight: '500',
    textTransform: 'capitalize',
  },
  details: {
    marginBottom: 12,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  detailText: {
    fontSize: 13,
    color: '#666',
    marginLeft: 8,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
  },
  salaryText: {
    fontSize: 15,
    fontWeight: '600',
    color: '#2563eb',
  },
  typeText: {
    fontSize: 13,
    color: '#666',
    textTransform: 'capitalize',
  },
});