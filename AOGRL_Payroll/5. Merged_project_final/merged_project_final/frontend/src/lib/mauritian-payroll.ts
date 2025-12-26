import { Employee, PayrollRecord, CompanySettings, TaxBracket } from './types';

// Enhanced Mauritian Labor Law Payroll Calculations
export class MauritianPayroll {
  private settings: CompanySettings;

  constructor(settings: CompanySettings) {
    this.settings = settings;
  }

  calculatePayroll(
    employee: Employee, 
    overtimeWeekdayHours: number = 0,
    overtimeSundayHours: number = 0,
    overtimeSundayTripleHours: number = 0,
    absenceDays: number = 0,
    latenessHours: number = 0,
    earlyDepartureHours: number = 0
  ): Omit<PayrollRecord, 'id' | 'createdAt'> {
    const currentDate = new Date();
    const month = currentDate.toLocaleString('default', { month: 'long' });
    const year = currentDate.getFullYear();

    // Basic calculations
    const basicSalary = employee.basicSalary;
    const allowances = employee.allowances;
    
    // Overtime calculations
    const hourlyRate = basicSalary / (22 * 8); // Assuming 22 working days, 8 hours per day
    // Use dynamic overtime multipliers from settings
    const overtimeWeekdayAmount = overtimeWeekdayHours * hourlyRate * this.settings.overtimeWeekdayRate;
    const overtimeSundayAmount = overtimeSundayHours * hourlyRate * this.settings.overtimeSundayRate;
    const overtimeSundayTripleAmount = overtimeSundayTripleHours * hourlyRate * this.settings.overtimeSundayTripleRate;
    const totalOvertimeAmount = overtimeWeekdayAmount + overtimeSundayAmount + overtimeSundayTripleAmount;
    
    // Deductions for absence, lateness, early departure
    const absenceDeduction = (basicSalary / 22) * absenceDays; // Daily rate * absence days
    const latenessDeduction = hourlyRate * latenessHours;
    const earlyDepartureDeduction = hourlyRate * earlyDepartureHours;
    const attendanceDeductions = absenceDeduction + latenessDeduction + earlyDepartureDeduction;
    
    const grossSalary = basicSalary + allowances + totalOvertimeAmount - attendanceDeductions;

    // Statutory deductions - Employee contributions
    const csgEmployee = this.calculateCSGEmployee(grossSalary);
    const nsfEmployee = this.calculateNSFEmployee(grossSalary);
    const npfEmployee = this.calculateNPFEmployee(grossSalary);
    const paye = this.calculatePAYE(grossSalary);
    const levy = this.calculateLevy(grossSalary);
    const prgfEmployee = this.calculatePRGFEmployee(grossSalary);

    const totalEmployeeDeductions = csgEmployee + nsfEmployee + npfEmployee + paye + levy + prgfEmployee;
    const netSalary = grossSalary - totalEmployeeDeductions;

    // Employer contributions (for information/reporting)
    const csgEmployer = this.calculateCSGEmployer(grossSalary);
    const nsfEmployer = this.calculateNSFEmployer(grossSalary);
    // National Pension Fund employer portion
    const npfEmployer = grossSalary * this.settings.npfEmployerRate;
    // Sum of employer contributions (excluding PRGF and levy which are recorded separately)
    const totalEmployerContributions = csgEmployer + nsfEmployer + npfEmployer;

    return {
      employeeId: employee.id,
      month,
      year,
      basicSalary,
      allowances,
      overtimeHours: overtimeWeekdayHours + overtimeSundayHours + overtimeSundayTripleHours,
      overtimeAmount: totalOvertimeAmount,
      grossSalary,
      npfContribution: npfEmployee,
      nsfContribution: nsfEmployee,
      incomeTax: paye,
      totalDeductions: totalEmployeeDeductions,
      netSalary,
      // Additional fields for detailed breakdown
      csgEmployee,
      csgEmployer,
      nsfEmployer,
      levy,
      prgfEmployee,
      absenceDeduction,
      latenessDeduction,
      earlyDepartureDeduction,
      overtimeWeekdayHours,
      overtimeSundayHours,
      overtimeSundayTripleHours,
      overtimeWeekdayAmount,
      overtimeSundayAmount,
      overtimeSundayTripleAmount,
      totalEmployerContributions
    };
  }

  private calculateCSGEmployee(grossSalary: number): number {
    // Calculate the employee CSG using dynamic rates and threshold from settings.
    const threshold = this.settings.csgThreshold;
    const lowerRate = this.settings.csgEmployeeLowerRate;
    const higherRate = this.settings.csgEmployeeHigherRate;
    if (grossSalary <= threshold) {
      return grossSalary * lowerRate;
    } else {
      return threshold * lowerRate + (grossSalary - threshold) * higherRate;
    }
  }

  private calculateCSGEmployer(grossSalary: number): number {
    // Employer CSG contribution using dynamic rates and threshold from settings
    const threshold = this.settings.csgThreshold;
    const lowerRate = this.settings.csgEmployerLowerRate;
    const higherRate = this.settings.csgEmployerHigherRate;
    if (grossSalary <= threshold) {
      return grossSalary * lowerRate;
    } else {
      return threshold * lowerRate + (grossSalary - threshold) * higherRate;
    }
  }

  private calculateNSFEmployee(grossSalary: number): number {
    // National Savings Fund: employee portion from settings
    return grossSalary * this.settings.nsfEmployeeRate;
  }

  private calculateNSFEmployer(grossSalary: number): number {
    // National Savings Fund: employer portion from settings
    return grossSalary * this.settings.nsfEmployerRate;
  }

  private calculateNPFEmployee(grossSalary: number): number {
    // National Pension Fund: employee portion from settings
    return grossSalary * this.settings.npfEmployeeRate;
  }

  private calculatePAYE(grossSalary: number): number {
    // PAYE (Pay As You Earn) - Income Tax
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

  private calculateLevy(grossSalary: number): number {
    // HRDC levy from settings
    return grossSalary * this.settings.levyRate;
  }

  private calculatePRGFEmployee(grossSalary: number): number {
    // PRGF contribution from settings. Note: In Mauritius, PRGF is typically an employer-only cost,
    // but this method provides flexibility to apply it to employees if needed.
    return grossSalary * this.settings.prgfRate;
  }

  generateDetailedPayslip(employee: Employee, payrollRecord: PayrollRecord): string {
    // Helper to format rate as a percentage string (e.g. 0.015 -> 1.5%)
    const pct = (v: number) => `${(v * 100).toFixed(1)}%`;
    return `
DETAILED PAYSLIP - ${payrollRecord.month} ${payrollRecord.year}
=========================================================
Company: ${this.settings.name}
Address: ${this.settings.address}
Phone: ${this.settings.phone}

EMPLOYEE DETAILS:
Name: ${employee.firstName} ${employee.lastName}
Employee ID: ${employee.employeeId}
Position: ${employee.position}
Department: ${employee.department}
National ID: ${employee.nationalId}

EARNINGS:
Basic Salary: Rs ${payrollRecord.basicSalary.toFixed(2)}
Allowances: Rs ${payrollRecord.allowances.toFixed(2)}

OVERTIME:
Weekday Overtime (${payrollRecord.overtimeWeekdayHours || 0}h @ ${this.settings.overtimeWeekdayRate.toFixed(1)}x): Rs ${(payrollRecord.overtimeWeekdayAmount || 0).toFixed(2)}
Sunday Overtime (${payrollRecord.overtimeSundayHours || 0}h @ ${this.settings.overtimeSundayRate.toFixed(1)}x): Rs ${(payrollRecord.overtimeSundayAmount || 0).toFixed(2)}
Sunday Overtime (${payrollRecord.overtimeSundayTripleHours || 0}h @ ${this.settings.overtimeSundayTripleRate.toFixed(1)}x): Rs ${(payrollRecord.overtimeSundayTripleAmount || 0).toFixed(2)}
Total Overtime: Rs ${payrollRecord.overtimeAmount.toFixed(2)}

ATTENDANCE DEDUCTIONS:
Absence Deduction: Rs ${(payrollRecord.absenceDeduction || 0).toFixed(2)}
Lateness Deduction: Rs ${(payrollRecord.latenessDeduction || 0).toFixed(2)}
Early Departure Deduction: Rs ${(payrollRecord.earlyDepartureDeduction || 0).toFixed(2)}

GROSS SALARY: Rs ${payrollRecord.grossSalary.toFixed(2)}

EMPLOYEE DEDUCTIONS:
CSG (${pct(this.settings.csgEmployeeLowerRate)}/${pct(this.settings.csgEmployeeHigherRate)}): Rs ${(payrollRecord.csgEmployee || 0).toFixed(2)}
NSF (${pct(this.settings.nsfEmployeeRate)}): Rs ${payrollRecord.nsfContribution.toFixed(2)}
NPF (${pct(this.settings.npfEmployeeRate)}): Rs ${payrollRecord.npfContribution.toFixed(2)}
PAYE (Income Tax): Rs ${payrollRecord.incomeTax.toFixed(2)}
Levy (${pct(this.settings.levyRate)}): Rs ${(payrollRecord.levy || 0).toFixed(2)}
PRGF (${pct(this.settings.prgfRate)}): Rs ${(payrollRecord.prgfEmployee || 0).toFixed(2)}
Total Employee Deductions: Rs ${payrollRecord.totalDeductions.toFixed(2)}

NET SALARY: Rs ${payrollRecord.netSalary.toFixed(2)}

EMPLOYER CONTRIBUTIONS (For Information):
CSG Employer (${pct(this.settings.csgEmployerLowerRate)}/${pct(this.settings.csgEmployerHigherRate)}): Rs ${(payrollRecord.csgEmployer || 0).toFixed(2)}
NSF Employer (${pct(this.settings.nsfEmployerRate)}): Rs ${(payrollRecord.nsfEmployer || 0).toFixed(2)}
NPF Employer (${pct(this.settings.npfEmployerRate)}): Rs ${(payrollRecord.grossSalary * this.settings.npfEmployerRate).toFixed(2)}
Total Employer Contributions: Rs ${((payrollRecord.totalEmployerContributions || 0) + payrollRecord.grossSalary * this.settings.npfEmployerRate).toFixed(2)}

CONTRIBUTION TOTALS:
Total CSG: Rs ${((payrollRecord.csgEmployee || 0) + (payrollRecord.csgEmployer || 0)).toFixed(2)}
Total NSF: Rs ${(payrollRecord.nsfContribution + (payrollRecord.nsfEmployer || 0)).toFixed(2)}
Total NPF: Rs ${(payrollRecord.npfContribution + payrollRecord.grossSalary * this.settings.npfEmployerRate).toFixed(2)}

=========================================================
Generated on: ${new Date().toLocaleDateString()}
    `;
  }

  // Keep the old method for backward compatibility
  generatePayslip(employee: Employee, payrollRecord: PayrollRecord): string {
    return this.generateDetailedPayslip(employee, payrollRecord);
  }
}

// Updated default Mauritian settings
export const defaultMauritianSettings: CompanySettings = {
  name: 'Your Company Name',
  address: 'Port Louis, Mauritius',
  phone: '+230 xxx xxxx',
  email: 'hr@company.mu',
  // National Pension Fund: split into employee (6%) and employer (3%) portions
  npfEmployeeRate: 0.06,
  npfEmployerRate: 0.03,
  // National Savings Fund: split into employee (1%) and employer (2.5%) portions
  nsfEmployeeRate: 0.01,
  nsfEmployerRate: 0.025,
  // Overtime multipliers
  overtimeWeekdayRate: 1.5,
  overtimeSundayRate: 2.0,
  overtimeSundayTripleRate: 3.0,
  // CSG rates: lower and higher for both employee and employer
  csgEmployeeLowerRate: 0.015,
  csgEmployeeHigherRate: 0.03,
  csgEmployerLowerRate: 0.03,
  csgEmployerHigherRate: 0.06,
  csgThreshold: 50000,
  // Levy and PRGF
  levyRate: 0.015,
  prgfRate: 0.045,
  taxBrackets: [
    { min: 0, max: 325000, rate: 0 },
    { min: 325000, max: 415000, rate: 0.15 },
    { min: 415000, max: 525000, rate: 0.20 },
    { min: 525000, max: Infinity, rate: 0.25 }
  ]
};