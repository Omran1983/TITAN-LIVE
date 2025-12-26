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