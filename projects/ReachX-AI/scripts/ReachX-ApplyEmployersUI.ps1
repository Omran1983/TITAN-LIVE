param(
    [string]$ProjectRoot = "F:\ReachX-AI\infra\ReachX-Workers-UI-v1"
)

Write-Host "=== ReachX Employers UI Auto-Wire ===" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"

if (-not (Test-Path $ProjectRoot)) {
    Write-Error "Project root not found: $ProjectRoot"
    exit 1
}

Set-Location $ProjectRoot

# 1) Find Supabase client file
Write-Host "Scanning for Supabase client..." -ForegroundColor Yellow

$supabaseCandidate = Get-ChildItem -Path "src" -Recurse -Include *.js,*.jsx,*.ts,*.tsx -ErrorAction SilentlyContinue |
    Where-Object {
        Select-String -Path $_.FullName -Pattern 'export const supabase' -Quiet -ErrorAction SilentlyContinue
    } |
    Select-Object -First 1

if (-not $supabaseCandidate) {
    $supabaseCandidate = Get-ChildItem -Path "src" -Recurse -Include *.js,*.jsx,*.ts,*.tsx -ErrorAction SilentlyContinue |
        Where-Object {
            Select-String -Path $_.FullName -Pattern 'createClient\(' -Quiet -ErrorAction SilentlyContinue
        } |
        Select-Object -First 1
}

if ($supabaseCandidate) {
    Write-Host "Found Supabase client: $($supabaseCandidate.FullName)" -ForegroundColor Green

    $employersSectionPath = Join-Path $ProjectRoot "src\components\employers\EmployersSection.jsx"
    $projectRootResolved  = (Resolve-Path $ProjectRoot).ToString()
    $clientResolved       = (Resolve-Path $supabaseCandidate.FullName).ToString()

    $clientRelToRoot = $clientResolved.Substring($projectRootResolved.Length).TrimStart('\','/')
    if ($clientRelToRoot -like "src*") {
        $subPath = $clientRelToRoot.Substring(3)
    } else {
        $subPath = $clientRelToRoot
    }

    $subPathNoExt = [System.IO.Path]::ChangeExtension($subPath, $null)
    $subPathNoExt = $subPathNoExt -replace '\\','/'

    $supabaseImportPath = "../.." + $subPathNoExt
}
else {
    Write-Warning "Could not automatically find Supabase client; defaulting import to ../../supabaseClient"
    $supabaseImportPath = "../../supabaseClient"
}

Write-Host "Supabase import path inside EmployersSection.jsx: $supabaseImportPath" -ForegroundColor Yellow

$employersDirFull = Join-Path $ProjectRoot "src\components\employers"
if (-not (Test-Path $employersDirFull)) {
    Write-Host "Creating employers components directory: $employersDirFull" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $employersDirFull -Force | Out-Null
}

$employersSectionPath = Join-Path $employersDirFull "EmployersSection.jsx"

$sectionContent = @'
import React, { useEffect, useState } from 'react';
import { EmployersTable } from './EmployersTable';
import { supabase } from '__SUPABASE_IMPORT__';

export function EmployersSection() {
  const [employers, setEmployers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  const loadEmployers = async () => {
    setLoading(true);
    setError(null);
    try {
      const { data, error } = await supabase
        .from('reachx_employers')
        .select(
          `
          id,
          name,
          country,
          contact_name,
          email,
          phone,
          primary_agent_name
        `
        )
        .order('name', { ascending: true });

      if (error) throw error;

      const mapped = (data || []).map((e) => ({
        employer_id: e.id,
        employer_name: e.name,
        country: e.country,
        contact_name: e.contact_name,
        email: e.email,
        phone: e.phone,
        primary_agent_name: e.primary_agent_name,
        open_requests: e.open_requests || 0,
        total_requests: e.total_requests || 0,
        workers_requested: e.workers_requested || 0,
        workers_fulfilled: e.workers_fulfilled || 0,
        workers_in_pool: e.workers_in_pool || 0,
        active_assignments: e.active_assignments || 0,
      }));

      setEmployers(mapped);
    } catch (err) {
      console.error('Error loading employers:', err);
      setError(err.message || 'Failed to load employers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadEmployers();
  }, []);

  const handleAddEmployer = async () => {
    const name = window.prompt('Employer name?');
    if (!name) return;

    const country = window.prompt('Country (e.g. MU)?') || null;
    const contactName = window.prompt('Contact person name?') || null;
    const email = window.prompt('Email address?') || null;
    const phone = window.prompt('Phone number?') || null;

    setSaving(true);
    setError(null);
    try {
      const { error } = await supabase.from('reachx_employers').insert([
        {
          name,
          country,
          contact_name: contactName,
          email,
          phone,
        },
      ]);

      if (error) throw error;
      await loadEmployers();
    } catch (err) {
      console.error('Error adding employer:', err);
      window.alert('Error adding employer: ' + (err.message || err));
      setError(err.message || 'Error adding employer');
    } finally {
      setSaving(false);
    }
  };

  const handleEditEmployers = async (ids) => {
    if (!ids || ids.length === 0) return;

    const first = employers.find((e) => e.employer_id === ids[0]);
    if (!first) {
      window.alert('Could not find selected employer(s) in local state.');
      return;
    }

    const newContactName = window.prompt(
      `Contact person name (leave blank to keep existing)\nCurrent: ${first.contact_name || '—'}`
    );
    const newEmail = window.prompt(
      `Email (leave blank to keep existing)\nCurrent: ${first.email || '—'}`
    );
    const newPhone = window.prompt(
      `Phone (leave blank to keep existing)\nCurrent: ${first.phone || '—'}`
    );
    const newCountry = window.prompt(
      `Country (leave blank to keep existing)\nCurrent: ${first.country || '—'}`
    );
    const newAgent = window.prompt(
      `Primary agent (leave blank to keep existing)\nCurrent: ${first.primary_agent_name || '—'}`
    );

    if (
      newContactName === null &&
      newEmail === null &&
      newPhone === null &&
      newCountry === null &&
      newAgent === null
    ) {
      return;
    }

    if (
      !window.confirm(
        `Apply these changes to ${ids.length} employer(s)?\n(Blank fields will keep existing values.)`
      )
    ) {
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const update = {};
      if (newContactName !== null && newContactName !== '') {
        update.contact_name = newContactName;
      }
      if (newEmail !== null && newEmail !== '') {
        update.email = newEmail;
      }
      if (newPhone !== null && newPhone !== '') {
        update.phone = newPhone;
      }
      if (newCountry !== null && newCountry !== '') {
        update.country = newCountry;
      }
      if (newAgent !== null && newAgent !== '') {
        update.primary_agent_name = newAgent;
      }

      if (Object.keys(update).length === 0) {
        setSaving(false);
        return;
      }

      const { error } = await supabase
        .from('reachx_employers')
        .update(update)
        .in('id', ids);

      if (error) throw error;

      await loadEmployers();
    } catch (err) {
      console.error('Error updating employers:', err);
      window.alert('Error updating employers: ' + (err.message || err));
      setError(err.message || 'Error updating employers');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteEmployers = async (ids) => {
    if (!ids || ids.length === 0) return;

    if (
      !window.confirm(
        `Are you sure you want to delete ${ids.length} employer(s)? This cannot be undone.`
      )
    ) {
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const { error } = await supabase
        .from('reachx_employers')
        .delete()
        .in('id', ids);

      if (error) throw error;
      await loadEmployers();
    } catch (err) {
      console.error('Error deleting employers:', err);
      window.alert('Error deleting employers: ' + (err.message || err));
      setError(err.message || 'Error deleting employers');
    } finally {
      setSaving(false);
    }
  };

  return (
    <section>
      <div style={{ marginBottom: 8 }}>
        {saving && (
          <span style={{ fontSize: 12, color: '#2563eb', marginRight: 12 }}>
            Saving changes…
          </span>
        )}
        {error && (
          <span style={{ fontSize: 12, color: '#b91c1c' }}>
            Error: {error}
          </span>
        )}
      </div>

      <EmployersTable
        employers={employers}
        loading={loading || saving}
        onAdd={handleAddEmployer}
        onEditSelected={handleEditEmployers}
        onDeleteSelected={handleDeleteEmployers}
      />
    </section>
  );
}
'@

$sectionContent = $sectionContent.Replace('__SUPABASE_IMPORT__', $supabaseImportPath)

Write-Host "Writing EmployersSection.jsx -> $employersSectionPath" -ForegroundColor Yellow
Set-Content -Path $employersSectionPath -Value $sectionContent -Encoding UTF8

Write-Host "=== Done. Now run your UI dev server ===" -ForegroundColor Green
Write-Host "cd `"$ProjectRoot`"; npm run dev"
