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
    const overtimeWeekdayAmount = overtimeWeekdayHours * hourlyRate * 1.5; // 1.5x weekdays
    const overtimeSundayAmount = overtimeSundayHours * hourlyRate * 2.0; // 2.0x Sunday
    const overtimeSundayTripleAmount = overtimeSundayTripleHours * hourlyRate * 3.0; // 3.0x Sunday
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
    const totalEmployerContributions = csgEmployer + nsfEmployer;

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
    // CSG Employee: 1.5% (up to certain threshold) then 3%
    const threshold = 50000; // Example threshold
    if (grossSalary <= threshold) {
      return grossSalary * 0.015; // 1.5%
    } else {
      return threshold * 0.015 + (grossSalary - threshold) * 0.03; // 1.5% + 3%
    }
  }

  private calculateCSGEmployer(grossSalary: number): number {
    // CSG Employer: 3% (up to certain threshold) then 6%
    const threshold = 50000; // Example threshold
    if (grossSalary <= threshold) {
      return grossSalary * 0.03; // 3%
    } else {
      return threshold * 0.03 + (grossSalary - threshold) * 0.06; // 3% + 6%
    }
  }

  private calculateNSFEmployee(grossSalary: number): number {
    // NSF Employee: 1%
    return grossSalary * 0.01;
  }

  private calculateNSFEmployer(grossSalary: number): number {
    // NSF Employer: 2.5%
    return grossSalary * 0.025;
  }

  private calculateNPFEmployee(grossSalary: number): number {
    // NPF Employee: 9% (total contribution, but employee pays portion)
    // Assuming employee pays 6% and employer pays 3% to make total 9%
    return grossSalary * 0.06;
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
    // Levy: 1.5%
    return grossSalary * 0.015;
  }

  private calculatePRGFEmployee(grossSalary: number): number {
    // PRGF Employee: 4.5%
    return grossSalary * 0.045;
  }

  generateDetailedPayslip(employee: Employee, payrollRecord: PayrollRecord): string {
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
Weekday Overtime (${payrollRecord.overtimeWeekdayHours || 0}h @ 1.5x): Rs ${(payrollRecord.overtimeWeekdayAmount || 0).toFixed(2)}
Sunday Overtime (${payrollRecord.overtimeSundayHours || 0}h @ 2.0x): Rs ${(payrollRecord.overtimeSundayAmount || 0).toFixed(2)}
Sunday Overtime (${payrollRecord.overtimeSundayTripleHours || 0}h @ 3.0x): Rs ${(payrollRecord.overtimeSundayTripleAmount || 0).toFixed(2)}
Total Overtime: Rs ${payrollRecord.overtimeAmount.toFixed(2)}

ATTENDANCE DEDUCTIONS:
Absence Deduction: Rs ${(payrollRecord.absenceDeduction || 0).toFixed(2)}
Lateness Deduction: Rs ${(payrollRecord.latenessDeduction || 0).toFixed(2)}
Early Departure Deduction: Rs ${(payrollRecord.earlyDepartureDeduction || 0).toFixed(2)}

GROSS SALARY: Rs ${payrollRecord.grossSalary.toFixed(2)}

EMPLOYEE DEDUCTIONS:
CSG (1.5%/3%): Rs ${(payrollRecord.csgEmployee || 0).toFixed(2)}
NSF (1%): Rs ${payrollRecord.nsfContribution.toFixed(2)}
NPF (6%): Rs ${payrollRecord.npfContribution.toFixed(2)}
PAYE (Income Tax): Rs ${payrollRecord.incomeTax.toFixed(2)}
Levy (1.5%): Rs ${(payrollRecord.levy || 0).toFixed(2)}
PRGF (4.5%): Rs ${(payrollRecord.prgfEmployee || 0).toFixed(2)}
Total Employee Deductions: Rs ${payrollRecord.totalDeductions.toFixed(2)}

NET SALARY: Rs ${payrollRecord.netSalary.toFixed(2)}

EMPLOYER CONTRIBUTIONS (For Information):
CSG Employer (3%/6%): Rs ${(payrollRecord.csgEmployer || 0).toFixed(2)}
NSF Employer (2.5%): Rs ${(payrollRecord.nsfEmployer || 0).toFixed(2)}
NPF Employer (3%): Rs ${(payrollRecord.grossSalary * 0.03).toFixed(2)}
Total Employer Contributions: Rs ${((payrollRecord.totalEmployerContributions || 0) + payrollRecord.grossSalary * 0.03).toFixed(2)}

CONTRIBUTION TOTALS:
Total CSG: Rs ${((payrollRecord.csgEmployee || 0) + (payrollRecord.csgEmployer || 0)).toFixed(2)}
Total NSF: Rs ${(payrollRecord.nsfContribution + (payrollRecord.nsfEmployer || 0)).toFixed(2)}
Total NPF: Rs ${(payrollRecord.npfContribution + payrollRecord.grossSalary * 0.03).toFixed(2)}

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
  npfRate: 0.06, // Employee portion of NPF
  nsfRate: 0.01, // Employee NSF rate
  overtimeWeekdayRate: 1.5,
  overtimeSundayRate: 2.0,
  taxBrackets: [
    { min: 0, max: 325000, rate: 0 },
    { min: 325000, max: 415000, rate: 0.15 },
    { min: 415000, max: 525000, rate: 0.20 },
    { min: 525000, max: Infinity, rate: 0.25 }
  ]
};