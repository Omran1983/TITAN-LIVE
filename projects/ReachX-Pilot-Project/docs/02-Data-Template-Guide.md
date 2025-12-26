# ReachX Pilot â€“ Data Template Guide

To connect your data to the ReachX cockpit, we use simple Excel/CSV templates.  
You can copy/paste from your existing spreadsheets into these columns.

The templates live in: `client-assets/`

- `ReachX-Workers-Template.csv`
- `ReachX-Employers-Template.csv`
- `ReachX-Dormitories-Template.csv`

You can work in Excel or Google Sheets and then export as CSV.

---

## 1. Workers Template

**File:** `ReachX-Workers-Template.csv`

**Suggested columns:**

- `worker_id`  
  Optional. If you already use internal worker IDs, keep them here. If not, you can leave this blank.

- `full_name`  
  The workerâ€™s full name.

- `passport_number` (optional)  
  If you track passport numbers.

- `nationality`  
  Country of nationality, e.g. India, Bangladesh, Nepal, etc.

- `employer_name`  
  The employer that currently has this worker. This should match `employer_name` in the Employers file.

- `dormitory_name`  
  The dormitory where the worker is staying, if applicable. This should match `dormitory_name` in the Dormitories file.

- `country`  
  Country where the worker is currently deployed.

- `city`  
  City or region where the worker is currently deployed.

- `status`  
  Free text or simple statuses like: Active / On Leave / Returned / Pending / Terminated.

> Notes:
> - `employer_name` and `dormitory_name` act as links to the other templates.
> - If you do not track dormitories yet, this column can be left blank.

---

## 2. Employers Template

**File:** `ReachX-Employers-Template.csv`

**Suggested columns:**

- `employer_name`  
  The official or commonly used name of the employer. This is the key that links workers to employers.

- `country`  
  Country where this employer is based.

- `city`  
  City where this employer mainly operates or where most workers are deployed.

- `sector`  
  Example: Hospitality / Construction / Security / Cleaning / Retail, etc.

- `contact_person`  
  The main person you coordinate with (HR manager, operations manager, etc.).

- `contact_phone`  
  Phone or mobile number.

- `contact_email`  
  Email address for formal communication.

> If you use internal codes for employers, you can add an extra column such as `employer_code`.

---

## 3. Dormitories Template

**File:** `ReachX-Dormitories-Template.csv`

**Suggested columns:**

- `dormitory_name`  
  The name or code you use to identify this accommodation.

- `address`  
  Address or basic location description.

- `city`  
  City where this dormitory is located.

- `country`  
  Country.

- `capacity`  
  Total number of beds/places available.

- `current_occupancy`  
  Current number of workers staying there (optional at start; can be tracked over time).

> If you do not manage dormitories, this file can be empty for now. The dashboard will still work for workers and employers.

---

## 4. How to share the files

1. Fill in the templates in Excel or Google Sheets.
2. Save each sheet as **CSV** (Comma-Separated Values).
3. Send the files via the agreed secure channel:
   - Encrypted email, or
   - A protected shared folder, or
   - Any other method you are comfortable with.
4. We will confirm once your data has been loaded into ReachX and appears on the dashboard.

If your current structure is very different, we can adjust the mapping together during the pilot setup.
