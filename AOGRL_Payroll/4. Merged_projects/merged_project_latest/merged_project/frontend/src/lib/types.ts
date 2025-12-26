export interface Employee {
  id: string;
  employeeId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  position: string;
  department: string;
  hireDate: string;
  basicSalary: number;
  allowances: number;
  status: 'active' | 'inactive';
  bankAccount?: string;
  nationalId: string;
  address: string;
}

export interface PayrollRecord {
  id: string;
  employeeId: string;
  month: string;
  year: number;
  basicSalary: number;
  allowances: number;
  overtimeHours: number;
  overtimeAmount: number;
  grossSalary: number;
  npfContribution: number;
  nsfContribution: number;
  incomeTax: number;
  totalDeductions: number;
  netSalary: number;
  createdAt: string;
  
  // Enhanced fields for detailed Mauritian payroll
  csgEmployee?: number;
  csgEmployer?: number;
  nsfEmployer?: number;
  levy?: number;
  prgfEmployee?: number;
  absenceDeduction?: number;
  latenessDeduction?: number;
  earlyDepartureDeduction?: number;
  overtimeWeekdayHours?: number;
  overtimeSundayHours?: number;
  overtimeSundayTripleHours?: number;
  overtimeWeekdayAmount?: number;
  overtimeSundayAmount?: number;
  overtimeSundayTripleAmount?: number;
  totalEmployerContributions?: number;
}

export interface CompanySettings {
  name: string;
  address: string;
  phone: string;
  email: string;
  logo?: string;
  npfRate: number;
  nsfRate: number;
  overtimeWeekdayRate: number;
  overtimeSundayRate: number;
  taxBrackets: TaxBracket[];
}

export interface TaxBracket {
  min: number;
  max: number;
  rate: number;
}

export interface Department {
  id: string;
  name: string;
  manager?: string;
}

export interface AttendanceData {
  absenceDays: number;
  latenessHours: number;
  earlyDepartureHours: number;
}

export interface OvertimeData {
  weekdayHours: number;
  sundayHours: number;
  sundayTripleHours: number;
}