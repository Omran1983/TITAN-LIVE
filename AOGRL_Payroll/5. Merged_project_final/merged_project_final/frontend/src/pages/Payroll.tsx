import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { toast } from 'sonner';
import { Calculator, Play, Download } from 'lucide-react';
import { Employee, PayrollRecord, OvertimeData, AttendanceData } from '@/lib/types';
import { LocalStorage } from '@/lib/storage';
import { MauritianPayroll } from '@/lib/mauritian-payroll';
import { ExcelUtils } from '@/lib/excel-utils';

export default function Payroll() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [isProcessing, setIsProcessing] = useState(false);
  const [overtimeData, setOvertimeData] = useState<Record<string, OvertimeData>>({});
  const [attendanceData, setAttendanceData] = useState<Record<string, AttendanceData>>({});
  const [isPayrollDialogOpen, setIsPayrollDialogOpen] = useState(false);

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
        const overtime = overtimeData[employee.id] || { weekdayHours: 0, sundayHours: 0, sundayTripleHours: 0 };
        const attendance = attendanceData[employee.id] || { absenceDays: 0, latenessHours: 0, earlyDepartureHours: 0 };
        
        const payrollData = payrollCalculator.calculatePayroll(
          employee,
          overtime.weekdayHours,
          overtime.sundayHours,
          overtime.sundayTripleHours,
          attendance.absenceDays,
          attendance.latenessHours,
          attendance.earlyDepartureHours
        );
        
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
      
      toast.success(`Enhanced payroll processed for ${employees.length} employees`);
      setOvertimeData({});
      setAttendanceData({});
      setIsPayrollDialogOpen(false);
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

  const updateOvertimeData = (employeeId: string, field: keyof OvertimeData, value: number) => {
    setOvertimeData(prev => ({
      ...prev,
      [employeeId]: {
        ...prev[employeeId] || { weekdayHours: 0, sundayHours: 0, sundayTripleHours: 0 },
        [field]: value
      }
    }));
  };

  const updateAttendanceData = (employeeId: string, field: keyof AttendanceData, value: number) => {
    setAttendanceData(prev => ({
      ...prev,
      [employeeId]: {
        ...prev[employeeId] || { absenceDays: 0, latenessHours: 0, earlyDepartureHours: 0 },
        [field]: value
      }
    }));
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
          <h1 className="text-3xl font-bold tracking-tight">Enhanced Payroll</h1>
          <p className="text-muted-foreground">Complete Mauritian labor law compliance with all deductions</p>
        </div>
        <div className="flex space-x-2">
          <Button onClick={handleExportPayroll} variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
          <Dialog open={isPayrollDialogOpen} onOpenChange={setIsPayrollDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Play className="h-4 w-4 mr-2" />
                Process Enhanced Payroll
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>Process Enhanced Payroll - {months[selectedMonth]} {selectedYear}</DialogTitle>
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
                
                <Tabs defaultValue="overtime" className="w-full">
                  <TabsList className="grid w-full grid-cols-2">
                    <TabsTrigger value="overtime">Overtime</TabsTrigger>
                    <TabsTrigger value="attendance">Attendance</TabsTrigger>
                  </TabsList>
                  
                  <TabsContent value="overtime" className="space-y-4">
                    <h3 className="text-lg font-semibold">Overtime Hours</h3>
                    <div className="space-y-3 max-h-96 overflow-y-auto">
                      {employees.map((employee) => (
                        <div key={employee.id} className="p-4 border rounded-lg">
                          <div className="font-medium mb-2">
                            {employee.firstName} {employee.lastName} ({employee.employeeId})
                          </div>
                          <div className="grid grid-cols-3 gap-4">
                            <div>
                              <Label className="text-xs">Weekday (1.5x)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.5"
                                value={overtimeData[employee.id]?.weekdayHours || 0}
                                onChange={(e) => updateOvertimeData(employee.id, 'weekdayHours', Number(e.target.value))}
                              />
                            </div>
                            <div>
                              <Label className="text-xs">Sunday (2.0x)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.5"
                                value={overtimeData[employee.id]?.sundayHours || 0}
                                onChange={(e) => updateOvertimeData(employee.id, 'sundayHours', Number(e.target.value))}
                              />
                            </div>
                            <div>
                              <Label className="text-xs">Sunday (3.0x)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.5"
                                value={overtimeData[employee.id]?.sundayTripleHours || 0}
                                onChange={(e) => updateOvertimeData(employee.id, 'sundayTripleHours', Number(e.target.value))}
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </TabsContent>
                  
                  <TabsContent value="attendance" className="space-y-4">
                    <h3 className="text-lg font-semibold">Attendance Deductions</h3>
                    <div className="space-y-3 max-h-96 overflow-y-auto">
                      {employees.map((employee) => (
                        <div key={employee.id} className="p-4 border rounded-lg">
                          <div className="font-medium mb-2">
                            {employee.firstName} {employee.lastName} ({employee.employeeId})
                          </div>
                          <div className="grid grid-cols-3 gap-4">
                            <div>
                              <Label className="text-xs">Absence (Days)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.5"
                                value={attendanceData[employee.id]?.absenceDays || 0}
                                onChange={(e) => updateAttendanceData(employee.id, 'absenceDays', Number(e.target.value))}
                              />
                            </div>
                            <div>
                              <Label className="text-xs">Lateness (Hours)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.25"
                                value={attendanceData[employee.id]?.latenessHours || 0}
                                onChange={(e) => updateAttendanceData(employee.id, 'latenessHours', Number(e.target.value))}
                              />
                            </div>
                            <div>
                              <Label className="text-xs">Early Departure (Hours)</Label>
                              <Input
                                type="number"
                                min="0"
                                step="0.25"
                                value={attendanceData[employee.id]?.earlyDepartureHours || 0}
                                onChange={(e) => updateAttendanceData(employee.id, 'earlyDepartureHours', Number(e.target.value))}
                              />
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </TabsContent>
                </Tabs>
                
                <div className="flex justify-end space-x-2 pt-4 border-t">
                  <Button variant="outline" onClick={() => setIsPayrollDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button onClick={handleProcessPayroll} disabled={isProcessing}>
                    {isProcessing ? 'Processing...' : 'Process Enhanced Payroll'}
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
              CSG, NSF, NPF, PAYE, Levy, PRGF
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

      {/* Enhanced Payroll Records */}
      <Card>
        <CardHeader>
          <CardTitle>Enhanced Payroll Records - {months[selectedMonth]} {selectedYear}</CardTitle>
        </CardHeader>
        <CardContent>
          {currentMonthPayroll.length > 0 ? (
            <div className="overflow-x-auto">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Employee</TableHead>
                    <TableHead>Basic</TableHead>
                    <TableHead>Overtime</TableHead>
                    <TableHead>Gross</TableHead>
                    <TableHead>CSG</TableHead>
                    <TableHead>NSF</TableHead>
                    <TableHead>NPF</TableHead>
                    <TableHead>PAYE</TableHead>
                    <TableHead>Levy</TableHead>
                    <TableHead>PRGF</TableHead>
                    <TableHead>Net</TableHead>
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
                        <TableCell>
                          {record.overtimeHours}h<br />
                          <span className="text-xs text-muted-foreground">
                            Rs {record.overtimeAmount.toLocaleString()}
                          </span>
                        </TableCell>
                        <TableCell>Rs {record.grossSalary.toLocaleString()}</TableCell>
                        <TableCell>Rs {(record.csgEmployee || 0).toLocaleString()}</TableCell>
                        <TableCell>Rs {record.nsfContribution.toLocaleString()}</TableCell>
                        <TableCell>Rs {record.npfContribution.toLocaleString()}</TableCell>
                        <TableCell>Rs {record.incomeTax.toLocaleString()}</TableCell>
                        <TableCell>Rs {(record.levy || 0).toLocaleString()}</TableCell>
                        <TableCell>Rs {(record.prgfEmployee || 0).toLocaleString()}</TableCell>
                        <TableCell className="font-bold">Rs {record.netSalary.toLocaleString()}</TableCell>
                        <TableCell>
                          <Badge variant="default">Processed</Badge>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
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