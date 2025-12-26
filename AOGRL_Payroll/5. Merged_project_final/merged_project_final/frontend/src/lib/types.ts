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
  /**
   * Employee portion of the National Pension Fund rate (e.g. 0.06 for 6%).
   * The employer portion should be stored separately in npfEmployerRate.
   */
  npfEmployeeRate: number;
  /**
   * Employer portion of the National Pension Fund rate (e.g. 0.03 for 3%).
   */
  npfEmployerRate: number;
  /**
   * Employee portion of the National Savings Fund rate (e.g. 0.01 for 1%).
   */
  nsfEmployeeRate: number;
  /**
   * Employer portion of the National Savings Fund rate (e.g. 0.025 for 2.5%).
   */
  nsfEmployerRate: number;
  /**
   * Overtime rate multiplier for weekday overtime (e.g. 1.5 = 150%).
   */
  overtimeWeekdayRate: number;
  /**
   * Overtime rate multiplier for work performed on Sundays and public holidays (e.g. 2.0 = 200%).
   */
  overtimeSundayRate: number;
  /**
   * Overtime rate multiplier for special cases (e.g. triple time on Sundays/holidays).
   */
  overtimeSundayTripleRate: number;
  /**
   * Lower CSG rate for employees (e.g. 0.015 for 1.5%).
   */
  csgEmployeeLowerRate: number;
  /**
   * Higher CSG rate for employees (e.g. 0.03 for 3%).
   */
  csgEmployeeHigherRate: number;
  /**
   * Lower CSG rate for employers (e.g. 0.03 for 3%).
   */
  csgEmployerLowerRate: number;
  /**
   * Higher CSG rate for employers (e.g. 0.06 for 6%).
   */
  csgEmployerHigherRate: number;
  /**
   * Income threshold at which the higher CSG rates apply (e.g. 50000 MUR).
   */
  csgThreshold: number;
  /**
   * Levy rate applied to gross salary (e.g. 0.015 for 1.5%).
   */
  levyRate: number;
  /**
   * PRGF rate applied to gross salary (e.g. 0.045 for 4.5%).
   */
  prgfRate: number;
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