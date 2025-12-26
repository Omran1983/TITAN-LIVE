import { Employee, Deduction, PayrollPeriod, PayrollEntry } from '@/types/payroll';

export const initialEmployees: Employee[] = [
  {
    id: '1',
    firstName: 'John',
    lastName: 'Smith',
    email: 'john.smith@company.com',
    phone: '(555) 123-4567',
    department: 'Engineering',
    position: 'Senior Developer',
    hireDate: '2022-03-15',
    employmentType: 'full-time',
    payType: 'salary',
    payRate: 120000,
    status: 'active',
  },
  {
    id: '2',
    firstName: 'Sarah',
    lastName: 'Johnson',
    email: 'sarah.johnson@company.com',
    phone: '(555) 234-5678',
    department: 'Marketing',
    position: 'Marketing Manager',
    hireDate: '2021-06-01',
    employmentType: 'full-time',
    payType: 'salary',
    payRate: 95000,
    status: 'active',
  },
  {
    id: '3',
    firstName: 'Mike',
    lastName: 'Williams',
    email: 'mike.williams@company.com',
    phone: '(555) 345-6789',
    department: 'Sales',
    position: 'Sales Representative',
    hireDate: '2023-01-10',
    employmentType: 'full-time',
    payType: 'hourly',
    payRate: 35,
    hoursPerWeek: 40,
    status: 'active',
  },
  {
    id: '4',
    firstName: 'Emily',
    lastName: 'Brown',
    email: 'emily.brown@company.com',
    phone: '(555) 456-7890',
    department: 'HR',
    position: 'HR Specialist',
    hireDate: '2022-09-20',
    employmentType: 'full-time',
    payType: 'salary',
    payRate: 65000,
    status: 'active',
  },
  {
    id: '5',
    firstName: 'David',
    lastName: 'Davis',
    email: 'david.davis@company.com',
    phone: '(555) 567-8901',
    department: 'Engineering',
    position: 'Junior Developer',
    hireDate: '2023-07-01',
    employmentType: 'part-time',
    payType: 'hourly',
    payRate: 25,
    hoursPerWeek: 20,
    status: 'active',
  },
];

/**
 * Default deduction list customised for Mauritian payroll.
 *
 * Note: In Mauritius, employees contribute towards the Contribution Sociale Généralisée (CSG) and
 * the National Savings Fund (NSF), while PAYE (Pay As You Earn) tax is progressive.  These
 * amounts are approximated here as fixed percentages for demonstration.  Adjust the rates and
 * logic as needed based on current legislation and income thresholds.
 */
export const defaultDeductions: Deduction[] = [
  // Employee contributions: CSG can be 1.5% for lower earnings and 3% for higher earnings.  NSF is fixed at 1%.
  // PAYE is left as a placeholder percentage (approx. 10%) until a progressive tax engine is implemented.
  {
    id: 'csg-emp-1.5',
    name: 'CSG (Emp 1.5%)',
    type: 'percentage',
    amount: 1.5,
    category: 'tax',
  },
  {
    id: 'csg-emp-3',
    name: 'CSG (Emp 3%)',
    type: 'percentage',
    amount: 3,
    category: 'tax',
  },
  {
    id: 'nsf-emp',
    name: 'NSF (Employee 1%)',
    type: 'percentage',
    amount: 1,
    category: 'tax',
  },
  {
    id: 'paye',
    name: 'PAYE (placeholder)',
    type: 'percentage',
    amount: 10,
    category: 'tax',
  },
  {
    id: 'levy',
    name: 'Levy (1.5%)',
    type: 'percentage',
    amount: 1.5,
    category: 'tax',
  },
  {
    id: 'prgf-emp',
    name: 'PRGF (4.5%, employer)',
    type: 'percentage',
    amount: 4.5,
    category: 'tax',
  },
  {
    id: 'npf-total',
    name: 'NPF (Total 9%)',
    type: 'percentage',
    amount: 9,
    category: 'tax',
  },
];

export const departments = [
  'Engineering',
  'Marketing',
  'Sales',
  'HR',
  'Finance',
  'Operations',
  'Customer Service',
];

export const positions = [
  'CEO',
  'CTO',
  'CFO',
  'Senior Developer',
  'Junior Developer',
  'Marketing Manager',
  'Sales Representative',
  'HR Specialist',
  'Accountant',
  'Operations Manager',
];