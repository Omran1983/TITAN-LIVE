import createContextHook from '@nkzw/create-context-hook';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState, useEffect, useMemo } from 'react';
import { Employee, PayrollPeriod, PayrollEntry, PayrollSettings, Deduction } from '@/types/payroll';
import { initialEmployees, defaultDeductions } from '@/constants/payroll-data';

const STORAGE_KEYS = {
  EMPLOYEES: 'payroll_employees',
  PAYROLL_PERIODS: 'payroll_periods',
  PAYROLL_ENTRIES: 'payroll_entries',
  SETTINGS: 'payroll_settings',
  DEDUCTIONS: 'payroll_deductions',
};

export const [PayrollProvider, usePayroll] = createContextHook(() => {
  const queryClient = useQueryClient();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [payrollPeriods, setPayrollPeriods] = useState<PayrollPeriod[]>([]);
  const [payrollEntries, setPayrollEntries] = useState<PayrollEntry[]>([]);
  const [deductions, setDeductions] = useState<Deduction[]>(defaultDeductions);
  const [settings, setSettings] = useState<PayrollSettings>({
    payFrequency: 'bi-weekly',
    overtimeRate: 1.5,
    standardHours: 40,
    defaultDeductions: defaultDeductions,
  });

  // Load data from AsyncStorage
  const employeesQuery = useQuery({
    queryKey: ['employees'],
    queryFn: async () => {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.EMPLOYEES);
      return stored ? JSON.parse(stored) : initialEmployees;
    },
  });

  const payrollPeriodsQuery = useQuery({
    queryKey: ['payrollPeriods'],
    queryFn: async () => {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.PAYROLL_PERIODS);
      return stored ? JSON.parse(stored) : [];
    },
  });

  const payrollEntriesQuery = useQuery({
    queryKey: ['payrollEntries'],
    queryFn: async () => {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.PAYROLL_ENTRIES);
      return stored ? JSON.parse(stored) : [];
    },
  });

  const settingsQuery = useQuery({
    queryKey: ['settings'],
    queryFn: async () => {
      const stored = await AsyncStorage.getItem(STORAGE_KEYS.SETTINGS);
      return stored ? JSON.parse(stored) : {
        payFrequency: 'bi-weekly',
        overtimeRate: 1.5,
        standardHours: 40,
        defaultDeductions: defaultDeductions,
      };
    },
  });

  useEffect(() => {
    if (employeesQuery.data) setEmployees(employeesQuery.data);
  }, [employeesQuery.data]);

  useEffect(() => {
    if (payrollPeriodsQuery.data) setPayrollPeriods(payrollPeriodsQuery.data);
  }, [payrollPeriodsQuery.data]);

  useEffect(() => {
    if (payrollEntriesQuery.data) setPayrollEntries(payrollEntriesQuery.data);
  }, [payrollEntriesQuery.data]);

  useEffect(() => {
    if (settingsQuery.data) setSettings(settingsQuery.data);
  }, [settingsQuery.data]);

  // Mutations
  const saveEmployeesMutation = useMutation({
    mutationFn: async (data: Employee[]) => {
      await AsyncStorage.setItem(STORAGE_KEYS.EMPLOYEES, JSON.stringify(data));
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });

  const savePayrollPeriodsMutation = useMutation({
    mutationFn: async (data: PayrollPeriod[]) => {
      await AsyncStorage.setItem(STORAGE_KEYS.PAYROLL_PERIODS, JSON.stringify(data));
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payrollPeriods'] });
    },
  });

  const savePayrollEntriesMutation = useMutation({
    mutationFn: async (data: PayrollEntry[]) => {
      await AsyncStorage.setItem(STORAGE_KEYS.PAYROLL_ENTRIES, JSON.stringify(data));
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payrollEntries'] });
    },
  });

  // Employee management
  const addEmployee = (employee: Omit<Employee, 'id'>) => {
    const newEmployee = { ...employee, id: Date.now().toString() };
    const updated = [...employees, newEmployee];
    setEmployees(updated);
    saveEmployeesMutation.mutate(updated);
    return newEmployee;
  };

  const updateEmployee = (id: string, updates: Partial<Employee>) => {
    const updated = employees.map(emp => 
      emp.id === id ? { ...emp, ...updates } : emp
    );
    setEmployees(updated);
    saveEmployeesMutation.mutate(updated);
  };

  const deleteEmployee = (id: string) => {
    const updated = employees.filter(emp => emp.id !== id);
    setEmployees(updated);
    saveEmployeesMutation.mutate(updated);
  };

  // Payroll processing
  const calculatePayrollEntry = (employee: Employee, hoursWorked: number): PayrollEntry => {
    let grossPay = 0;
    let regularHours = hoursWorked;
    let overtimeHours = 0;

    if (employee.payType === 'hourly') {
      if (hoursWorked > settings.standardHours) {
        regularHours = settings.standardHours;
        overtimeHours = hoursWorked - settings.standardHours;
        grossPay = (regularHours * employee.payRate) + (overtimeHours * employee.payRate * settings.overtimeRate);
      } else {
        grossPay = hoursWorked * employee.payRate;
      }
    } else {
      // Salary - calculate based on pay frequency
      const weeksPerYear = 52;
      let divisor = weeksPerYear;
      switch (settings.payFrequency) {
        case 'weekly':
          divisor = weeksPerYear;
          break;
        case 'bi-weekly':
          divisor = weeksPerYear / 2;
          break;
        case 'semi-monthly':
          divisor = 24;
          break;
        case 'monthly':
          divisor = 12;
          break;
      }
      grossPay = employee.payRate / divisor;
    }

    // Calculate deductions
    const calculatedDeductions = deductions.map(deduction => ({
      deductionId: deduction.id,
      amount: deduction.type === 'percentage' 
        ? (grossPay * deduction.amount / 100)
        : deduction.amount
    }));

    const totalDeductions = calculatedDeductions.reduce((sum, d) => sum + d.amount, 0);
    const netPay = grossPay - totalDeductions;

    return {
      id: Date.now().toString(),
      payrollPeriodId: '',
      employeeId: employee.id,
      hoursWorked,
      regularHours,
      overtimeHours,
      grossPay,
      deductions: calculatedDeductions,
      netPay,
      status: 'pending',
    };
  };

  const createPayrollPeriod = (startDate: string, endDate: string) => {
    const activeEmployees = employees.filter(emp => emp.status === 'active');
    const entries: PayrollEntry[] = activeEmployees.map(employee => {
      const hoursWorked = employee.payType === 'hourly' 
        ? (employee.hoursPerWeek || 40)
        : settings.standardHours;
      return calculatePayrollEntry(employee, hoursWorked);
    });

    const totalGross = entries.reduce((sum, e) => sum + e.grossPay, 0);
    const totalDeductions = entries.reduce((sum, e) => 
      sum + e.deductions.reduce((dSum, d) => dSum + d.amount, 0), 0
    );
    const totalNet = entries.reduce((sum, e) => sum + e.netPay, 0);

    const period: PayrollPeriod = {
      id: Date.now().toString(),
      startDate,
      endDate,
      status: 'draft',
      totalGross,
      totalDeductions,
      totalNet,
      employeeCount: activeEmployees.length,
    };

    const updatedPeriods = [...payrollPeriods, period];
    setPayrollPeriods(updatedPeriods);
    savePayrollPeriodsMutation.mutate(updatedPeriods);

    // Save entries with period ID
    const entriesWithPeriodId = entries.map(e => ({ ...e, payrollPeriodId: period.id }));
    const updatedEntries = [...payrollEntries, ...entriesWithPeriodId];
    setPayrollEntries(updatedEntries);
    savePayrollEntriesMutation.mutate(updatedEntries);

    return period;
  };

  const processPayroll = (periodId: string) => {
    const updatedPeriods = payrollPeriods.map(period =>
      period.id === periodId 
        ? { ...period, status: 'processed' as const, processedDate: new Date().toISOString() }
        : period
    );
    setPayrollPeriods(updatedPeriods);
    savePayrollPeriodsMutation.mutate(updatedPeriods);

    const updatedEntries = payrollEntries.map(entry =>
      entry.payrollPeriodId === periodId
        ? { ...entry, status: 'approved' as const }
        : entry
    );
    setPayrollEntries(updatedEntries);
    savePayrollEntriesMutation.mutate(updatedEntries);
  };

  // Computed values
  const activeEmployees = useMemo(() => 
    employees.filter(emp => emp.status === 'active'),
    [employees]
  );

  const totalPayrollCost = useMemo(() => {
    const currentPeriod = payrollPeriods[payrollPeriods.length - 1];
    return currentPeriod?.totalGross || 0;
  }, [payrollPeriods]);

  const isLoading = employeesQuery.isLoading || payrollPeriodsQuery.isLoading || 
                    payrollEntriesQuery.isLoading || settingsQuery.isLoading;

  return {
    employees,
    payrollPeriods,
    payrollEntries,
    settings,
    deductions,
    activeEmployees,
    totalPayrollCost,
    isLoading,
    addEmployee,
    updateEmployee,
    deleteEmployee,
    createPayrollPeriod,
    processPayroll,
    calculatePayrollEntry,
  };
});

export function useEmployeeById(id: string) {
  const { employees } = usePayroll();
  return employees.find(emp => emp.id === id);
}

export function usePayrollEntriesByPeriod(periodId: string) {
  const { payrollEntries } = usePayroll();
  return payrollEntries.filter(entry => entry.payrollPeriodId === periodId);
}

export function usePayrollStats() {
  const { employees, payrollPeriods, payrollEntries } = usePayroll();
  
  return useMemo(() => {
    const totalEmployees = employees.length;
    const activeEmployees = employees.filter(e => e.status === 'active').length;
    const totalPeriods = payrollPeriods.length;
    const lastPeriod = payrollPeriods[payrollPeriods.length - 1];
    
    const ytdGross = payrollPeriods
      .filter(p => new Date(p.startDate).getFullYear() === new Date().getFullYear())
      .reduce((sum, p) => sum + p.totalGross, 0);
    
    const ytdNet = payrollPeriods
      .filter(p => new Date(p.startDate).getFullYear() === new Date().getFullYear())
      .reduce((sum, p) => sum + p.totalNet, 0);

    return {
      totalEmployees,
      activeEmployees,
      totalPeriods,
      lastPayrollDate: lastPeriod?.endDate,
      ytdGross,
      ytdNet,
      avgSalary: activeEmployees > 0 ? ytdGross / activeEmployees : 0,
    };
  }, [employees, payrollPeriods, payrollEntries]);
}