import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Calculator, Play, Download, Eye } from 'lucide-react';
import { Employee, PayrollRecord } from '@/lib/types';
import { LocalStorage } from '@/lib/storage';
import { MauritianPayroll } from '@/lib/mauritian-payroll';
import { ExcelUtils } from '@/lib/excel-utils';

export default function Payroll() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [isProcessing, setIsProcessing] = useState(false);
  const [overtimeData, setOvertimeData] = useState<Record<string, number>>({});
  const [isOvertimeDialogOpen, setIsOvertimeDialogOpen] = useState(false);

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  useEffect(() => {
    loadData();
  }, []);

  const loadData = () => {
    setEmployees(LocalStorage.getEmployees().filter(emp => emp.status === 'active'));
    setPayrollRecords(LocalStorage.getPayrollRecords());
  };

  const handleProcessPayroll = async () => {
    setIsProcessing(true);
    
    try {
      const settings = LocalStorage.getSettings();
      const payrollCalculator = new MauritianPayroll(settings);
      const monthName = months[selectedMonth];
      
      // Check if payroll already exists for this month/year
      const existingPayroll = payrollRecords.filter(
        record => record.month === monthName && record.year === selectedYear
      );
      
      if (existingPayroll.length > 0) {
        toast.error('Payroll already processed for this month');
        setIsProcessing(false);
        return;
      }

      const newPayrollRecords: PayrollRecord[] = [];

      for (const employee of employees) {
        const overtimeHours = overtimeData[employee.id] || 0;
        const payrollData = payrollCalculator.calculatePayroll(employee, overtimeHours);
        
        const record: PayrollRecord = {
          id: `payroll_${employee.id}_${selectedMonth}_${selectedYear}`,
          ...payrollData,
          month: monthName,
          year: selectedYear,
          createdAt: new Date().toISOString()
        };
        
        newPayrollRecords.push(record);
      }

      const updatedRecords = [...payrollRecords, ...newPayrollRecords];
      LocalStorage.savePayrollRecords(updatedRecords);
      setPayrollRecords(updatedRecords);
      
      toast.success(`Payroll processed for ${employees.length} employees`);
      setOvertimeData({});
      setIsOvertimeDialogOpen(false);
    } catch (error) {
      toast.error('Failed to process payroll');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleExportPayroll = () => {
    const monthName = months[selectedMonth];
    const filteredRecords = payrollRecords.filter(
      record => record.month === monthName && record.year === selectedYear
    );
    
    if (filteredRecords.length === 0) {
      toast.error('No payroll data found for selected period');
      return;
    }
    
    ExcelUtils.exportPayroll(filteredRecords);
    toast.success('Payroll exported successfully');
  };

  const currentMonthPayroll = payrollRecords.filter(
    record => record.month === months[selectedMonth] && record.year === selectedYear
  );

  const totalGrossSalary = currentMonthPayroll.reduce((sum, record) => sum + record.grossSalary, 0);
  const totalDeductions = currentMonthPayroll.reduce((sum, record) => sum + record.totalDeductions, 0);
  const totalNetSalary = currentMonthPayroll.reduce((sum, record) => sum + record.netSalary, 0);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Payroll</h1>
          <p className="text-muted-foreground">Process monthly payroll with Mauritian labor law compliance</p>
        </div>
        <div className="flex space-x-2">
          <Button onClick={handleExportPayroll} variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Dialog open={isOvertimeDialogOpen} onOpenChange={setIsOvertimeDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Play className="h-4 w-4 mr-2" />
                Process Payroll
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>Process Payroll - {months[selectedMonth]} {selectedYear}</DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label>Month</Label>
                    <Select value={selectedMonth.toString()} onValueChange={(value) => setSelectedMonth(Number(value))}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {months.map((month, index) => (
                          <SelectItem key={index} value={index.toString()}>
                            {month}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div>
                    <Label>Year</Label>
                    <Select value={selectedYear.toString()} onValueChange={(value) => setSelectedYear(Number(value))}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {[2024, 2025, 2026].map((year) => (
                          <SelectItem key={year} value={year.toString()}>
                            {year}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                
                <div>
                  <h3 className="text-lg font-semibold mb-2">Overtime Hours</h3>
                  <div className="space-y-2 max-h-60 overflow-y-auto">
                    {employees.map((employee) => (
                      <div key={employee.id} className="flex items-center justify-between p-2 border rounded">
                        <span className="font-medium">
                          {employee.firstName} {employee.lastName} ({employee.employeeId})
                        </span>
                        <div className="flex items-center space-x-2">
                          <Label htmlFor={`overtime-${employee.id}`}>Hours:</Label>
                          <Input
                            id={`overtime-${employee.id}`}
                            type="number"
                            min="0"
                            step="0.5"
                            className="w-20"
                            value={overtimeData[employee.id] || 0}
                            onChange={(e) => setOvertimeData({
                              ...overtimeData,
                              [employee.id]: Number(e.target.value)
                            })}
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
                
                <div className="flex justify-end space-x-2">
                  <Button variant="outline" onClick={() => setIsOvertimeDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button onClick={handleProcessPayroll} disabled={isProcessing}>
                    {isProcessing ? 'Processing...' : 'Process Payroll'}
                  </Button>
                </div>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Employees</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{currentMonthPayroll.length}</div>
            <p className="text-xs text-muted-foreground">
              Processed for {months[selectedMonth]}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Gross Salary</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">Rs {totalGrossSalary.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              Total before deductions
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Deductions</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">Rs {totalDeductions.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              NPF, NSF, Tax
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Net Salary</CardTitle>
            <Calculator className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">Rs {totalNetSalary.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              Total payout
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Payroll Records */}
      <Card>
        <CardHeader>
          <CardTitle>Payroll Records - {months[selectedMonth]} {selectedYear}</CardTitle>
        </CardHeader>
        <CardContent>
          {currentMonthPayroll.length > 0 ? (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Basic Salary</TableHead>
                  <TableHead>Allowances</TableHead>
                  <TableHead>Overtime</TableHead>
                  <TableHead>Gross</TableHead>
                  <TableHead>Deductions</TableHead>
                  <TableHead>Net Salary</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {currentMonthPayroll.map((record) => {
                  const employee = employees.find(emp => emp.id === record.employeeId);
                  return (
                    <TableRow key={record.id}>
                      <TableCell className="font-medium">
                        {employee ? `${employee.firstName} ${employee.lastName}` : 'Unknown'}
                      </TableCell>
                      <TableCell>Rs {record.basicSalary.toLocaleString()}</TableCell>
                      <TableCell>Rs {record.allowances.toLocaleString()}</TableCell>
                      <TableCell>
                        {record.overtimeHours}h (Rs {record.overtimeAmount.toLocaleString()})
                      </TableCell>
                      <TableCell>Rs {record.grossSalary.toLocaleString()}</TableCell>
                      <TableCell>Rs {record.totalDeductions.toLocaleString()}</TableCell>
                      <TableCell className="font-bold">Rs {record.netSalary.toLocaleString()}</TableCell>
                      <TableCell>
                        <Badge variant="default">Processed</Badge>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              No payroll records found for {months[selectedMonth]} {selectedYear}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}