import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TextInput, TouchableOpacity, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router, useLocalSearchParams } from 'expo-router';
import { Save, Trash2 } from 'lucide-react-native';
import { usePayroll, useEmployeeById } from '@/hooks/payroll-store';
import { Employee } from '@/types/payroll';
import { departments, positions } from '@/constants/payroll-data';

export default function EmployeeFormScreen() {
  const { employeeId } = useLocalSearchParams();
  const { addEmployee, updateEmployee, deleteEmployee } = usePayroll();
  const existingEmployee = useEmployeeById(employeeId as string);
  
  const [formData, setFormData] = useState<Partial<Employee>>({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    department: departments[0],
    position: positions[0],
    hireDate: new Date().toISOString().split('T')[0],
    employmentType: 'full-time',
    payType: 'salary',
    payRate: 0,
    hoursPerWeek: 40,
    status: 'active',
  });

  useEffect(() => {
    if (existingEmployee) {
      setFormData(existingEmployee);
    }
  }, [existingEmployee]);

  const handleSave = () => {
    if (!formData.firstName || !formData.lastName || !formData.email) {
      Alert.alert('Error', 'Please fill in all required fields');
      return;
    }

    if (existingEmployee) {
      updateEmployee(existingEmployee.id, formData);
      Alert.alert('Success', 'Employee updated successfully');
    } else {
      addEmployee(formData as Omit<Employee, 'id'>);
      Alert.alert('Success', 'Employee added successfully');
    }
    
    router.back();
  };

  const handleDelete = () => {
    Alert.alert(
      'Delete Employee',
      'Are you sure you want to delete this employee?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: () => {
            if (existingEmployee) {
              deleteEmployee(existingEmployee.id);
              router.back();
            }
          }
        }
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Personal Information</Text>
          
          <View style={styles.row}>
            <View style={styles.inputGroup}>
              <Text style={styles.label}>First Name *</Text>
              <TextInput
                style={styles.input}
                value={formData.firstName}
                onChangeText={(text) => setFormData({ ...formData, firstName: text })}
                placeholder="John"
              />
            </View>
            
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Last Name *</Text>
              <TextInput
                style={styles.input}
                value={formData.lastName}
                onChangeText={(text) => setFormData({ ...formData, lastName: text })}
                placeholder="Doe"
              />
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Email *</Text>
            <TextInput
              style={styles.input}
              value={formData.email}
              onChangeText={(text) => setFormData({ ...formData, email: text })}
              placeholder="john.doe@company.com"
              keyboardType="email-address"
              autoCapitalize="none"
            />
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Phone</Text>
            <TextInput
              style={styles.input}
              value={formData.phone}
              onChangeText={(text) => setFormData({ ...formData, phone: text })}
              placeholder="(555) 123-4567"
              keyboardType="phone-pad"
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Employment Details</Text>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Department</Text>
            <View style={styles.pickerContainer}>
              {departments.map(dept => (
                <TouchableOpacity
                  key={dept}
                  style={[styles.pickerOption, formData.department === dept && styles.pickerOptionActive]}
                  onPress={() => setFormData({ ...formData, department: dept })}
                >
                  <Text style={[styles.pickerText, formData.department === dept && styles.pickerTextActive]}>
                    {dept}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Position</Text>
            <TextInput
              style={styles.input}
              value={formData.position}
              onChangeText={(text) => setFormData({ ...formData, position: text })}
              placeholder="Software Engineer"
            />
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Hire Date</Text>
            <TextInput
              style={styles.input}
              value={formData.hireDate}
              onChangeText={(text) => setFormData({ ...formData, hireDate: text })}
              placeholder="YYYY-MM-DD"
            />
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Employment Type</Text>
            <View style={styles.radioGroup}>
              {['full-time', 'part-time', 'contractor'].map(type => (
                <TouchableOpacity
                  key={type}
                  style={styles.radioOption}
                  onPress={() => setFormData({ ...formData, employmentType: type as any })}
                >
                  <View style={styles.radio}>
                    {formData.employmentType === type && <View style={styles.radioSelected} />}
                  </View>
                  <Text style={styles.radioText}>{type.replace('-', ' ')}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Compensation</Text>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Pay Type</Text>
            <View style={styles.radioGroup}>
              {['salary', 'hourly'].map(type => (
                <TouchableOpacity
                  key={type}
                  style={styles.radioOption}
                  onPress={() => setFormData({ ...formData, payType: type as any })}
                >
                  <View style={styles.radio}>
                    {formData.payType === type && <View style={styles.radioSelected} />}
                  </View>
                  <Text style={styles.radioText}>{type}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>
              {formData.payType === 'salary' ? 'Annual Salary' : 'Hourly Rate'}
            </Text>
            <TextInput
              style={styles.input}
              value={formData.payRate?.toString()}
              onChangeText={(text) => setFormData({ ...formData, payRate: parseFloat(text) || 0 })}
              placeholder={formData.payType === 'salary' ? '75000' : '35'}
              keyboardType="numeric"
            />
          </View>
          
          {formData.payType === 'hourly' && (
            <View style={styles.inputGroup}>
              <Text style={styles.label}>Hours per Week</Text>
              <TextInput
                style={styles.input}
                value={formData.hoursPerWeek?.toString()}
                onChangeText={(text) => setFormData({ ...formData, hoursPerWeek: parseFloat(text) || 0 })}
                placeholder="40"
                keyboardType="numeric"
              />
            </View>
          )}
          
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Status</Text>
            <View style={styles.radioGroup}>
              {['active', 'inactive'].map(status => (
                <TouchableOpacity
                  key={status}
                  style={styles.radioOption}
                  onPress={() => setFormData({ ...formData, status: status as any })}
                >
                  <View style={styles.radio}>
                    {formData.status === status && <View style={styles.radioSelected} />}
                  </View>
                  <Text style={styles.radioText}>{status}</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        </View>

        <View style={styles.actions}>
          <TouchableOpacity style={styles.saveButton} onPress={handleSave}>
            <Save size={20} color="#fff" />
            <Text style={styles.saveButtonText}>
              {existingEmployee ? 'Update Employee' : 'Add Employee'}
            </Text>
          </TouchableOpacity>
          
          {existingEmployee && (
            <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
              <Trash2 size={20} color="#ef4444" />
              <Text style={styles.deleteButtonText}>Delete Employee</Text>
            </TouchableOpacity>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
  },
  section: {
    backgroundColor: '#fff',
    padding: 20,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 16,
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  inputGroup: {
    marginBottom: 16,
    flex: 1,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: '#666',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#e5e5e5',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 15,
    color: '#333',
    backgroundColor: '#fff',
  },
  pickerContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  pickerOption: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#f5f5f5',
    borderWidth: 1,
    borderColor: '#f5f5f5',
  },
  pickerOptionActive: {
    backgroundColor: '#eff6ff',
    borderColor: '#2563eb',
  },
  pickerText: {
    fontSize: 14,
    color: '#666',
  },
  pickerTextActive: {
    color: '#2563eb',
    fontWeight: '500',
  },
  radioGroup: {
    flexDirection: 'row',
    gap: 20,
  },
  radioOption: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  radio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: '#d1d5db',
    marginRight: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioSelected: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#2563eb',
  },
  radioText: {
    fontSize: 14,
    color: '#333',
    textTransform: 'capitalize',
  },
  actions: {
    padding: 20,
    gap: 12,
  },
  saveButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#2563eb',
    paddingVertical: 14,
    borderRadius: 8,
  },
  saveButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fee2e2',
    paddingVertical: 14,
    borderRadius: 8,
  },
  deleteButtonText: {
    color: '#ef4444',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
});