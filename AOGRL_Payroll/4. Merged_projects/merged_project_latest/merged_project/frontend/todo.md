# Employee Management & Payroll System - MVP Todo

## Core Features to Implement:

### 1. Main Dashboard (src/pages/Dashboard.tsx)
- Overview cards: Total employees, pending payroll, recent activities
- Quick actions: Add employee, run payroll, generate reports
- Navigation to different modules

### 2. Employee Management (src/pages/Employees.tsx)
- Employee list with search and filters
- Add/Edit employee form with personal details, job info, salary
- Employee profile view
- Excel import/export functionality

### 3. Payroll System (src/pages/Payroll.tsx)
- Payroll calculation based on Mauritian labor law
- Monthly payroll processing
- Overtime calculations
- Deductions (NPF, NSF, Income Tax)
- Payroll history

### 4. Payslip Generation (src/pages/Payslips.tsx)
- Generate individual payslips
- Bulk payslip generation
- Download/Print payslips
- Email payslips to employees

### 5. Settings (src/pages/Settings.tsx)
- Company details and logo upload
- Organizational hierarchy setup
- Salary structures configuration
- Overtime rules and rates
- Tax and deduction settings

### 6. Data Management
- Local storage for MVP (can be upgraded to Supabase later)
- Excel import/export utilities
- Data validation and error handling

## Files to Create:

1. **src/pages/Dashboard.tsx** - Main dashboard
2. **src/pages/Employees.tsx** - Employee management
3. **src/pages/Payroll.tsx** - Payroll processing
4. **src/pages/Payslips.tsx** - Payslip generation
5. **src/pages/Settings.tsx** - System settings
6. **src/components/Layout.tsx** - Main layout with navigation
7. **src/lib/mauritian-payroll.ts** - Mauritian labor law calculations
8. **src/lib/excel-utils.ts** - Excel import/export utilities

## Mauritian Labor Law Considerations:
- Basic salary calculations
- Overtime rates (1.5x for weekdays, 2x for Sundays/holidays)
- NPF (National Pension Fund) contributions
- NSF (National Savings Fund) contributions
- Income tax calculations
- Annual bonus (13th month)
- Leave calculations

## Technical Stack:
- React + TypeScript
- Shadcn/UI components
- Tailwind CSS
- Local storage for data persistence
- Excel import/export libraries