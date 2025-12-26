import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { FileText, Download, Eye, Mail, Printer } from 'lucide-react';
import { Employee, PayrollRecord } from '@/lib/types';
import { LocalStorage } from '@/lib/storage';
import { MauritianPayroll } from '@/lib/mauritian-payroll';

export default function Payslips() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [payrollRecords, setPayrollRecords] = useState<PayrollRecord[]>([]);
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [selectedPayslip, setSelectedPayslip] = useState<{ employee: Employee; record: PayrollRecord } | null>(null);
  const [isPreviewOpen, setIsPreviewOpen] = useState(false);

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  useEffect(() => {
    loadData();
  }, []);

  const loadData = () => {
    setEmployees(LocalStorage.getEmployees());
    setPayrollRecords(LocalStorage.getPayrollRecords());
  };

  const currentMonthPayroll = payrollRecords.filter(
    record => record.month === months[selectedMonth] && record.year === selectedYear
  );

  const handlePreviewPayslip = (employeeId: string) => {
    const employee = employees.find(emp => emp.id === employeeId);
    const record = currentMonthPayroll.find(rec => rec.employeeId === employeeId);
    
    if (employee && record) {
      setSelectedPayslip({ employee, record });
      setIsPreviewOpen(true);
    }
  };

  const handleDownloadPayslip = (employeeId: string) => {
    const employee = employees.find(emp => emp.id === employeeId);
    const record = currentMonthPayroll.find(rec => rec.employeeId === employeeId);
    
    if (employee && record) {
      const settings = LocalStorage.getSettings();
      const payrollCalculator = new MauritianPayroll(settings);
      const payslipContent = payrollCalculator.generatePayslip(employee, record);
      
      const blob = new Blob([payslipContent], { type: 'text/plain' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `payslip_${employee.employeeId}_${record.month}_${record.year}.txt`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      
      toast.success('Payslip downloaded successfully');
    }
  };

  const handleDownloadAllPayslips = () => {
    if (currentMonthPayroll.length === 0) {
      toast.error('No payslips found for selected period');
      return;
    }

    const settings = LocalStorage.getSettings();
    const payrollCalculator = new MauritianPayroll(settings);
    
    currentMonthPayroll.forEach((record) => {
      const employee = employees.find(emp => emp.id === record.employeeId);
      if (employee) {
        const payslipContent = payrollCalculator.generatePayslip(employee, record);
        const blob = new Blob([payslipContent], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `payslip_${employee.employeeId}_${record.month}_${record.year}.txt`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    });
    
    toast.success(`${currentMonthPayroll.length} payslips downloaded successfully`);
  };

  const handlePrintPayslip = () => {
    if (selectedPayslip) {
      const settings = LocalStorage.getSettings();
      const payrollCalculator = new MauritianPayroll(settings);
      const payslipContent = payrollCalculator.generatePayslip(selectedPayslip.employee, selectedPayslip.record);
      
      const printWindow = window.open('', '_blank');
      if (printWindow) {
        printWindow.document.write(`
          <html>
            <head>
              <title>Payslip - ${selectedPayslip.employee.firstName} ${selectedPayslip.employee.lastName}</title>
              <style>
                body { font-family: monospace; white-space: pre-wrap; margin: 20px; }
                @media print { body { margin: 0; } }
              </style>
            </head>
            <body>${payslipContent}</body>
          </html>
        `);
        printWindow.document.close();
        printWindow.print();
      }
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Payslips</h1>
          <p className="text-muted-foreground">Generate and manage employee payslips</p>
        </div>
        <div className="flex space-x-2">
          <Button onClick={handleDownloadAllPayslips} variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Download All
          </Button>
        </div>
      </div>

      {/* Period Selection */}
      <Card>
        <CardHeader>
          <CardTitle>Select Period</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-4 max-w-md">
            <div>
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
        </CardContent>
      </Card>

      {/* Payslips List */}
      <Card>
        <CardHeader>
          <CardTitle>Payslips - {months[selectedMonth]} {selectedYear}</CardTitle>
        </CardHeader>
        <CardContent>
          {currentMonthPayroll.length > 0 ? (
            <div className="grid gap-4">
              {currentMonthPayroll.map((record) => {
                const employee = employees.find(emp => emp.id === record.employeeId);
                if (!employee) return null;

                return (
                  <div key={record.id} className="flex items-center justify-between p-4 border rounded-lg">
                    <div className="flex items-center space-x-4">
                      <FileText className="h-8 w-8 text-primary" />
                      <div>
                        <h3 className="font-semibold">
                          {employee.firstName} {employee.lastName}
                        </h3>
                        <p className="text-sm text-muted-foreground">
                          {employee.employeeId} • {employee.position}
                        </p>
                        <p className="text-sm font-medium">
                          Net Salary: Rs {record.netSalary.toLocaleString()}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Badge variant="default">Generated</Badge>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handlePreviewPayslip(employee.id)}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleDownloadPayslip(employee.id)}
                      >
                        <Download className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="text-center py-8 text-muted-foreground">
              <FileText className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No payslips found for {months[selectedMonth]} {selectedYear}</p>
              <p className="text-sm">Process payroll first to generate payslips</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Payslip Preview Dialog */}
      <Dialog open={isPreviewOpen} onOpenChange={setIsPreviewOpen}>
        <DialogContent className="max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              Payslip Preview - {selectedPayslip?.employee.firstName} {selectedPayslip?.employee.lastName}
            </DialogTitle>
          </DialogHeader>
          {selectedPayslip && (
            <div className="space-y-4">
              <div className="bg-muted p-4 rounded-lg">
                <pre className="text-sm whitespace-pre-wrap font-mono">
                  {(() => {
                    const settings = LocalStorage.getSettings();
                    const payrollCalculator = new MauritianPayroll(settings);
                    return payrollCalculator.generatePayslip(selectedPayslip.employee, selectedPayslip.record);
                  })()}
                </pre>
              </div>
              <div className="flex justify-end space-x-2">
                <Button variant="outline" onClick={handlePrintPayslip}>
                  <Printer className="h-4 w-4 mr-2" />
                  Print
                </Button>
                <Button onClick={() => handleDownloadPayslip(selectedPayslip.employee.id)}>
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}