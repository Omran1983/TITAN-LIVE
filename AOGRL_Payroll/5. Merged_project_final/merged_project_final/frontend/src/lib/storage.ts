import { Employee, PayrollRecord, CompanySettings, Department } from './types';
import { defaultMauritianSettings } from './mauritian-payroll';

const STORAGE_KEYS = {
  EMPLOYEES: 'hr_employees',
  PAYROLL: 'hr_payroll',
  SETTINGS: 'hr_settings',
  DEPARTMENTS: 'hr_departments'
};

export class LocalStorage {
  static getEmployees(): Employee[] {
    const data = localStorage.getItem(STORAGE_KEYS.EMPLOYEES);
    return data ? JSON.parse(data) : [];
  }

  static saveEmployees(employees: Employee[]): void {
    localStorage.setItem(STORAGE_KEYS.EMPLOYEES, JSON.stringify(employees));
  }

  static getPayrollRecords(): PayrollRecord[] {
    const data = localStorage.getItem(STORAGE_KEYS.PAYROLL);
    return data ? JSON.parse(data) : [];
  }

  static savePayrollRecords(records: PayrollRecord[]): void {
    localStorage.setItem(STORAGE_KEYS.PAYROLL, JSON.stringify(records));
  }

  static getSettings(): CompanySettings {
    const data = localStorage.getItem(STORAGE_KEYS.SETTINGS);
    return data ? JSON.parse(data) : defaultMauritianSettings;
  }

  static saveSettings(settings: CompanySettings): void {
    localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(settings));
  }

  static getDepartments(): Department[] {
    const data = localStorage.getItem(STORAGE_KEYS.DEPARTMENTS);
    return data ? JSON.parse(data) : [
      { id: '1', name: 'Human Resources' },
      { id: '2', name: 'Information Technology' },
      { id: '3', name: 'Finance' },
      { id: '4', name: 'Operations' },
      { id: '5', name: 'Marketing' }
    ];
  }

  static saveDepartments(departments: Department[]): void {
    localStorage.setItem(STORAGE_KEYS.DEPARTMENTS, JSON.stringify(departments));
  }
}