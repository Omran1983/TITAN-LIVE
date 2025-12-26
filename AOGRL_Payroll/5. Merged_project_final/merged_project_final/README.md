# Merged Payroll Platform

This repository combines the **HR and Payroll Platform** front‑end with the **Existing Payroll project**'s payslip generator.  The goal is to provide a unified codebase that allows you to run a modern web UI for managing employees and payroll alongside a server‑side script for generating professional payslips.

## Structure

```
merged_project/
├── build/                   # Compiled static assets from the front‑end (ready to deploy)
│   ├── assets/
│   ├── images/
│   └── index.html
├── frontend/                # React/Tailwind source code (shadcn UI) for the HR & Payroll portal
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── …
├── payslip-generator/       # Node script and HTML template for generating PDF payslips via Supabase
│   ├── bulk-payslips.mjs    # Generates bulk payslips from Supabase view `v_payslip_latest`
│   ├── payslip-pro.html     # Stand‑alone payslip viewer that fetches from Supabase RPC
│   ├── package.json
│   └── package-lock.json
├── legacy/
│   └── all_in_one_Payroll.html # The original vanilla JS demo app (for reference only)
└── README.md               # This file
├── mobile-app/             # Expo/React Native mobile app for on‑the‑go payroll management
│   ├── app/                # Expo Router screens (employee form, payroll details, etc.)
│   ├── components/         # Reusable React Native components
│   ├── constants/          # Default data (Mauritian deduction list and sample employees)
│   ├── hooks/              # Global store using Context + AsyncStorage
│   ├── types/              # TypeScript definitions for payroll entities
│   ├── assets/             # Icons and splash images
│   ├── package.json        # Dependencies for the mobile app
│   └── …
```

## How to use

1. **Front‑end (React):**  The `frontend/` directory contains a Vite + React + TypeScript project using shadcn/ui and Tailwind CSS.  Install dependencies and start the dev server:

   ```bash
   cd frontend
   pnpm install  # or npm install / yarn install
   pnpm dev      # starts the Vite dev server
   ```

   To build for production, run `pnpm build`.  The compiled output will be written to the `dist/` folder (already copied into `build/` for convenience).

2. **Payslip generator:**  The `payslip-generator/` folder contains a Node script (`bulk-payslips.mjs`) which uses Puppeteer and Supabase to generate PDF payslips from data in the view `v_payslip_latest`.  To run it you must supply environment variables `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (service‑role key) in your shell.  Then execute:

   ```bash
   cd payslip-generator
   node bulk-payslips.mjs
   ```

   Generated PDFs will be written to an `out/<YYYY-MM>` folder based on the payslip period.

3. **Mobile app:**  The `mobile-app/` directory contains an Expo/React Native application built with Expo Router.  It allows you to manage employees and payroll periods on mobile devices.  To run it in Expo Go or a simulator, install dependencies and start the dev server:

   ```bash
   cd mobile-app
   pnpm install  # or npm install / yarn install
   # To run on your device or simulator
   pnpm start
   ```

   This will launch the Expo development server.  Use the Expo Go app on your iOS/Android device, or run a simulator via the Expo CLI to preview the app.  The mobile app stores data locally using AsyncStorage.  For a production‑ready solution you should connect it to your Supabase backend (see next steps).


3. **Stand‑alone payslip viewer:**  The `payslip-pro.html` file is a self‑contained web page that allows an authorized HR user or employee to fetch and render a single payslip.  It relies on Supabase authentication; set your project URL and anon key in the script section at the top of the file before using.

4. **Legacy demo:**  The `legacy/all_in_one_Payroll.html` file is a vanilla JavaScript demo that shows basic employee and payroll calculations using local storage.  It is kept for historical reference and is **not** meant for production.

## Next steps

This merged repository does **not** include a backend or database schema.  To build a fully functional payroll SaaS you will need:

* A Supabase (or similar) project with tables for employees, attendance, pay runs, statutory rates, and a view `v_payslip_latest` for the bulk payslip script.
* Edge Functions or serverless API endpoints to perform payroll calculations, compute deductions (PAYE, CSG, NSF, NPF, Levy, PRGF), and expose data to the React front‑end.
* Integration with Mauritian banks (e.g. for salary transfers) and, optionally, with accounting platforms.  These integrations can be added later and are not required for the core payroll functionality.

* A unified backend for both web and mobile.  Currently the mobile app stores data locally in AsyncStorage; for production you should connect it to the same Supabase backend used by the web portal.  Expose REST or RPC endpoints for employees, payroll periods, calculations and payslip retrieval so both clients share the same data source.

This repository serves as a starting point for building those pieces.
