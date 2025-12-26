import { Employee, PayrollRecord, CompanySettings, TaxBracket } from './types';

// Mauritian Labor Law Payroll Calculations
export class MauritianPayroll {
  private settings: CompanySettings;

  constructor(settings: CompanySettings) {
    this.settings = settings;
  }

  calculatePayroll(employee: Employee, overtimeHours: number = 0): Omit<PayrollRecord, 'id' | 'createdAt'> {
    const currentDate = new Date();
    const month = currentDate.toLocaleString('default', { month: 'long' });
    const year = currentDate.getFullYear();

    // Basic calculations
    const basicSalary = employee.basicSalary;
    const allowances = employee.allowances;
    
    // Overtime calculations (Mauritian law: 1.5x weekdays, 2x Sundays/holidays)
    const hourlyRate = basicSalary / (22 * 8); // Assuming 22 working days, 8 hours per day
    const overtimeAmount = overtimeHours * hourlyRate * this.settings.overtimeWeekdayRate;
    
    const grossSalary = basicSalary + allowances + overtimeAmount;

    // Statutory deductions
    const npfContribution = this.calculateNPF(grossSalary);
    const nsfContribution = this.calculateNSF(grossSalary);
    const incomeTax = this.calculateIncomeTax(grossSalary);

    const totalDeductions = npfContribution + nsfContribution + incomeTax;
    const netSalary = grossSalary - totalDeductions;

    return {
      employeeId: employee.id,
      month,
      year,
      basicSalary,
      allowances,
      overtimeHours,
      overtimeAmount,
      grossSalary,
      npfContribution,
      nsfContribution,
      incomeTax,
      totalDeductions,
      netSalary
    };
  }

  private calculateNPF(grossSalary: number): number {
    // NPF: 6% employee contribution (capped at certain amount)
    const maxContribution = 1500; // Example cap
    return Math.min(grossSalary * this.settings.npfRate, maxContribution);
  }

  private calculateNSF(grossSalary: number): number {
    // NSF: 2.5% employee contribution
    return grossSalary * this.settings.nsfRate;
  }

  private calculateIncomeTax(grossSalary: number): number {
    // Simplified Mauritian income tax calculation
    const annualSalary = grossSalary * 12;
    let tax = 0;

    for (const bracket of this.settings.taxBrackets) {
      if (annualSalary > bracket.min) {
        const taxableAmount = Math.min(annualSalary - bracket.min, bracket.max - bracket.min);
        tax += taxableAmount * bracket.rate;
      }
    }

    return tax / 12; // Monthly tax
  }

  generatePayslip(employee: Employee, payrollRecord: PayrollRecord): string {
    return `
PAYSLIP - ${payrollRecord.month} ${payrollRecord.year}
=====================================
Company: ${this.settings.name}
Employee: ${employee.firstName} ${employee.lastName}
Employee ID: ${employee.employeeId}
Position: ${employee.position}

EARNINGS:
Basic Salary: Rs ${payrollRecord.basicSalary.toFixed(2)}
Allowances: Rs ${payrollRecord.allowances.toFixed(2)}
Overtime (${payrollRecord.overtimeHours}h): Rs ${payrollRecord.overtimeAmount.toFixed(2)}
Gross Salary: Rs ${payrollRecord.grossSalary.toFixed(2)}

DEDUCTIONS:
NPF Contribution: Rs ${payrollRecord.npfContribution.toFixed(2)}
NSF Contribution: Rs ${payrollRecord.nsfContribution.toFixed(2)}
Income Tax: Rs ${payrollRecord.incomeTax.toFixed(2)}
Total Deductions: Rs ${payrollRecord.totalDeductions.toFixed(2)}

NET SALARY: Rs ${payrollRecord.netSalary.toFixed(2)}
=====================================
    `;
  }
}

// Default Mauritian settings
export const defaultMauritianSettings: CompanySettings = {
  name: 'Your Company Name',
  address: 'Port Louis, Mauritius',
  phone: '+230 xxx xxxx',
  email: 'hr@company.mu',
  npfRate: 0.06,
  nsfRate: 0.025,
  overtimeWeekdayRate: 1.5,
  overtimeSundayRate: 2.0,
  taxBrackets: [
    { min: 0, max: 325000, rate: 0 },
    { min: 325000, max: 415000, rate: 0.15 },
    { min: 415000, max: 525000, rate: 0.20 },
    { min: 525000, max: Infinity, rate: 0.25 }
  ]
};