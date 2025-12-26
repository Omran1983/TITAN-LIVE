import * as XLSX from 'xlsx';
import { Employee, PayrollRecord } from './types';

export class ExcelUtils {
  static exportEmployees(employees: Employee[]): void {
    const worksheet = XLSX.utils.json_to_sheet(employees);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Employees');
    
    const fileName = `employees_${new Date().toISOString().split('T')[0]}.xlsx`;
    XLSX.writeFile(workbook, fileName);
  }

  static exportPayroll(payrollRecords: PayrollRecord[]): void {
    const worksheet = XLSX.utils.json_to_sheet(payrollRecords);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Payroll');
    
    const fileName = `payroll_${new Date().toISOString().split('T')[0]}.xlsx`;
    XLSX.writeFile(workbook, fileName);
  }

  static async importEmployees(file: File): Promise<Employee[]> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e) => {
        try {
          const data = new Uint8Array(e.target?.result as ArrayBuffer);
          const workbook = XLSX.read(data, { type: 'array' });
          const sheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[sheetName];
          const jsonData = XLSX.utils.sheet_to_json(worksheet);
          
          const employees: Employee[] = jsonData.map((row: Record<string, unknown>, index) => ({
            id: (row.id as string) || `emp_${Date.now()}_${index}`,
            employeeId: (row.employeeId as string) || `EMP${String(index + 1).padStart(3, '0')}`,
            firstName: (row.firstName as string) || '',
            lastName: (row.lastName as string) || '',
            email: (row.email as string) || '',
            phone: (row.phone as string) || '',
            position: (row.position as string) || '',
            department: (row.department as string) || '',
            hireDate: (row.hireDate as string) || new Date().toISOString().split('T')[0],
            basicSalary: Number(row.basicSalary) || 0,
            allowances: Number(row.allowances) || 0,
            status: (row.status as string) === 'inactive' ? 'inactive' : 'active',
            bankAccount: (row.bankAccount as string) || '',
            nationalId: (row.nationalId as string) || '',
            address: (row.address as string) || ''
          }));
          
          resolve(employees);
        } catch (error) {
          reject(error);
        }
      };
      
      reader.onerror = () => reject(new Error('Failed to read file'));
      reader.readAsArrayBuffer(file);
    });
  }

  static downloadTemplate(): void {
    const template = [
      {
        employeeId: 'EMP001',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@company.mu',
        phone: '+230 xxx xxxx',
        position: 'Software Developer',
        department: 'IT',
        hireDate: '2024-01-01',
        basicSalary: 35000,
        allowances: 5000,
        status: 'active',
        bankAccount: '1234567890',
        nationalId: 'A1234567890123',
        address: 'Port Louis, Mauritius'
      }
    ];

    const worksheet = XLSX.utils.json_to_sheet(template);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Employee Template');
    
    XLSX.writeFile(workbook, 'employee_import_template.xlsx');
  }
}