import { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { Settings as SettingsIcon, Building2, Calculator, Users, Plus, Trash2 } from 'lucide-react';
import { CompanySettings, Department, TaxBracket } from '@/lib/types';
import { LocalStorage } from '@/lib/storage';

export default function Settings() {
  const [settings, setSettings] = useState<CompanySettings>(LocalStorage.getSettings());
  const [departments, setDepartments] = useState<Department[]>(LocalStorage.getDepartments());
  const [newDepartment, setNewDepartment] = useState('');

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = () => {
    setSettings(LocalStorage.getSettings());
    setDepartments(LocalStorage.getDepartments());
  };

  const handleSaveSettings = () => {
    LocalStorage.saveSettings(settings);
    toast.success('Settings saved successfully');
  };

  const handleSaveDepartments = () => {
    LocalStorage.saveDepartments(departments);
    toast.success('Departments updated successfully');
  };

  const handleAddDepartment = () => {
    if (!newDepartment.trim()) {
      toast.error('Please enter department name');
      return;
    }

    const newDept: Department = {
      id: `dept_${Date.now()}`,
      name: newDepartment.trim()
    };

    setDepartments([...departments, newDept]);
    setNewDepartment('');
  };

  const handleDeleteDepartment = (id: string) => {
    setDepartments(departments.filter(dept => dept.id !== id));
  };

  const handleTaxBracketChange = (index: number, field: keyof TaxBracket, value: number) => {
    const newTaxBrackets = [...settings.taxBrackets];
    newTaxBrackets[index] = { ...newTaxBrackets[index], [field]: value };
    setSettings({ ...settings, taxBrackets: newTaxBrackets });
  };

  const handleAddTaxBracket = () => {
    const newBracket: TaxBracket = { min: 0, max: 0, rate: 0 };
    setSettings({ ...settings, taxBrackets: [...settings.taxBrackets, newBracket] });
  };

  const handleDeleteTaxBracket = (index: number) => {
    const newTaxBrackets = settings.taxBrackets.filter((_, i) => i !== index);
    setSettings({ ...settings, taxBrackets: newTaxBrackets });
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">Configure your HR system and company details</p>
      </div>

      {/* Company Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Building2 className="h-5 w-5" />
            <span>Company Information</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="companyName">Company Name</Label>
              <Input
                id="companyName"
                value={settings.name}
                onChange={(e) => setSettings({ ...settings, name: e.target.value })}
              />
            </div>
            <div>
              <Label htmlFor="companyEmail">Email</Label>
              <Input
                id="companyEmail"
                type="email"
                value={settings.email}
                onChange={(e) => setSettings({ ...settings, email: e.target.value })}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="companyPhone">Phone</Label>
              <Input
                id="companyPhone"
                value={settings.phone}
                onChange={(e) => setSettings({ ...settings, phone: e.target.value })}
              />
            </div>
            <div>
              <Label htmlFor="companyLogo">Logo URL</Label>
              <Input
                id="companyLogo"
                value={settings.logo || ''}
                onChange={(e) => setSettings({ ...settings, logo: e.target.value })}
                placeholder="https://example.com/logo.png"
              />
            </div>
          </div>
          <div>
            <Label htmlFor="companyAddress">Address</Label>
            <Textarea
              id="companyAddress"
              value={settings.address}
              onChange={(e) => setSettings({ ...settings, address: e.target.value })}
              rows={3}
            />
          </div>
          <Button onClick={handleSaveSettings}>Save Company Information</Button>
        </CardContent>
      </Card>

      {/* Payroll Settings */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Calculator className="h-5 w-5" />
            <span>Payroll Settings</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="npfRate">NPF Rate (%)</Label>
              <Input
                id="npfRate"
                type="number"
                step="0.01"
                min="0"
                max="100"
                value={settings.npfRate * 100}
                onChange={(e) => setSettings({ ...settings, npfRate: Number(e.target.value) / 100 })}
              />
              <p className="text-xs text-muted-foreground">National Pension Fund contribution rate</p>
            </div>
            <div>
              <Label htmlFor="nsfRate">NSF Rate (%)</Label>
              <Input
                id="nsfRate"
                type="number"
                step="0.01"
                min="0"
                max="100"
                value={settings.nsfRate * 100}
                onChange={(e) => setSettings({ ...settings, nsfRate: Number(e.target.value) / 100 })}
              />
              <p className="text-xs text-muted-foreground">National Savings Fund contribution rate</p>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label htmlFor="overtimeWeekday">Weekday Overtime Rate</Label>
              <Input
                id="overtimeWeekday"
                type="number"
                step="0.1"
                min="1"
                value={settings.overtimeWeekdayRate}
                onChange={(e) => setSettings({ ...settings, overtimeWeekdayRate: Number(e.target.value) })}
              />
              <p className="text-xs text-muted-foreground">Multiplier for weekday overtime (e.g., 1.5 = 150%)</p>
            </div>
            <div>
              <Label htmlFor="overtimeSunday">Sunday/Holiday Overtime Rate</Label>
              <Input
                id="overtimeSunday"
                type="number"
                step="0.1"
                min="1"
                value={settings.overtimeSundayRate}
                onChange={(e) => setSettings({ ...settings, overtimeSundayRate: Number(e.target.value) })}
              />
              <p className="text-xs text-muted-foreground">Multiplier for Sunday/holiday overtime (e.g., 2.0 = 200%)</p>
            </div>
          </div>
          <Button onClick={handleSaveSettings}>Save Payroll Settings</Button>
        </CardContent>
      </Card>

      {/* Tax Brackets */}
      <Card>
        <CardHeader>
          <CardTitle>Income Tax Brackets</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {settings.taxBrackets.map((bracket, index) => (
            <div key={index} className="grid grid-cols-4 gap-4 items-center p-4 border rounded">
              <div>
                <Label>Min Amount (Rs)</Label>
                <Input
                  type="number"
                  value={bracket.min}
                  onChange={(e) => handleTaxBracketChange(index, 'min', Number(e.target.value))}
                />
              </div>
              <div>
                <Label>Max Amount (Rs)</Label>
                <Input
                  type="number"
                  value={bracket.max === Infinity ? '' : bracket.max}
                  onChange={(e) => handleTaxBracketChange(index, 'max', e.target.value ? Number(e.target.value) : Infinity)}
                  placeholder="Leave empty for no limit"
                />
              </div>
              <div>
                <Label>Tax Rate (%)</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  max="100"
                  value={bracket.rate * 100}
                  onChange={(e) => handleTaxBracketChange(index, 'rate', Number(e.target.value) / 100)}
                />
              </div>
              <div className="flex justify-end">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDeleteTaxBracket(index)}
                  disabled={settings.taxBrackets.length <= 1}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          ))}
          <div className="flex space-x-2">
            <Button variant="outline" onClick={handleAddTaxBracket}>
              <Plus className="h-4 w-4 mr-2" />
              Add Tax Bracket
            </Button>
            <Button onClick={handleSaveSettings}>Save Tax Settings</Button>
          </div>
        </CardContent>
      </Card>

      {/* Departments */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <Users className="h-5 w-5" />
            <span>Departments</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex space-x-2">
            <Input
              placeholder="Department name"
              value={newDepartment}
              onChange={(e) => setNewDepartment(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleAddDepartment()}
            />
            <Button onClick={handleAddDepartment}>
              <Plus className="h-4 w-4 mr-2" />
              Add
            </Button>
          </div>
          <div className="space-y-2">
            {departments.map((department) => (
              <div key={department.id} className="flex items-center justify-between p-3 border rounded">
                <span className="font-medium">{department.name}</span>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDeleteDepartment(department.id)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
          <Button onClick={handleSaveDepartments}>Save Departments</Button>
        </CardContent>
      </Card>
    </div>
  );
}