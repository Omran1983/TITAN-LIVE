export interface Employee {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  department: string;
  position: string;
  hireDate: string;
  employmentType: 'full-time' | 'part-time' | 'contractor';
  payType: 'salary' | 'hourly';
  payRate: number;
  hoursPerWeek?: number;
  status: 'active' | 'inactive';
  avatar?: string;
}

export interface Deduction {
  id: string;
  name: string;
  type: 'percentage' | 'fixed';
  amount: number;
  category: 'tax' | 'insurance' | 'retirement' | 'other';
}

export interface PayrollPeriod {
  id: string;
  startDate: string;
  endDate: string;
  status: 'draft' | 'processed' | 'paid';
  totalGross: number;
  totalDeductions: number;
  totalNet: number;
  employeeCount: number;
  processedDate?: string;
  paidDate?: string;
}

export interface PayrollEntry {
  id: string;
  payrollPeriodId: string;
  employeeId: string;
  hoursWorked: number;
  regularHours: number;
  overtimeHours: number;
  grossPay: number;
  deductions: {
    deductionId: string;
    amount: number;
  }[];
  netPay: number;
  status: 'pending' | 'approved' | 'paid';
}

export interface PayrollSettings {
  payFrequency: 'weekly' | 'bi-weekly' | 'semi-monthly' | 'monthly';
  overtimeRate: number;
  standardHours: number;
  defaultDeductions: Deduction[];
}