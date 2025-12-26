import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Users, Calculator, FileText, TrendingUp, Plus, Play } from 'lucide-react';
import { Link } from 'react-router-dom';
import { LocalStorage } from '@/lib/storage';
import { Employee, PayrollRecord } from '@/lib/types';

export default function Dashboard() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>([]);

  useEffect(() => {
    setEmployees(LocalStorage.getEmployees());
    setPayrollRecords(LocalStorage.getPayrollRecords());
  }, []);

  const activeEmployees = employees.filter(emp => emp.status === 'active').length;
  const currentMonth = new Date().toLocaleString('default', { month: 'long' });
  const currentYear = new Date().getFullYear();
  const currentMonthPayroll = payrollRecords.filter(
    record => record.month === currentMonth && record.year === currentYear
  ).length;

  const totalPayrollAmount = payrollRecords
    .filter(record => record.month === currentMonth && record.year === currentYear)
    .reduce((sum, record) => sum + record.netSalary, 0);

  const recentActivities = [
    { action: 'New employee added', time: '2 hours ago', type: 'employee' },
    { action: 'Payroll processed', time: '1 day ago', type: 'payroll' },
    { action: 'Settings updated', time: '3 days ago', type: 'settings' },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Welcome to your HR and Payroll Management System
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Employees</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{activeEmployees}</div>
            <p className="text-xs text-muted-foreground">
              Active employees
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Month's Payroll</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{currentMonthPayroll}</div>
            <p className="text-xs text-muted-foreground">
              Processed for {currentMonth}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Payout</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">Rs {totalPayrollAmount.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              For {currentMonth} {currentYear}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Payslips Generated</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{currentMonthPayroll}</div>
            <p className="text-xs text-muted-foreground">
              This month
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <Link to="/employees">
              <Button className="w-full h-20 flex flex-col space-y-2" variant="outline">
                <Plus className="h-6 w-6" />
                <span>Add Employee</span>
              </Button>
            </Link>
            <Link to="/payroll">
              <Button className="w-full h-20 flex flex-col space-y-2" variant="outline">
                <Play className="h-6 w-6" />
                <span>Run Payroll</span>
              </Button>
            </Link>
            <Link to="/payslips">
              <Button className="w-full h-20 flex flex-col space-y-2" variant="outline">
                <FileText className="h-6 w-6" />
                <span>Generate Payslips</span>
              </Button>
            </Link>
          </div>
        </CardContent>
      </Card>

      {/* Recent Activities */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Activities</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {recentActivities.map((activity, index) => (
              <div key={index} className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-primary rounded-full"></div>
                  <span className="text-sm">{activity.action}</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Badge variant="secondary" className="text-xs">
                    {activity.type}
                  </Badge>
                  <span className="text-xs text-muted-foreground">{activity.time}</span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}