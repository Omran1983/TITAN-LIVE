@echo off
echo Setting up TITAN Bridge Environment Variables...

:: TELEGRAM (Received)
setx TELEGRAM_BOT_TOKEN "8284941437:AAElTu-RcyN3dNv5jcrhJpknRgz4_akuPeI"

:: CONFIG
setx RUNNER_AGENT_ID "runner_win"
setx POLL_SECONDS "2"

:: SUPABASE (MISSING - Please Edit)
setx SUPABASE_URL "https://abkprecmhitqmmlzxfad.supabase.co"
setx SUPABASE_SERVICE_ROLE_KEY "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"

echo.
echo ---------------------------------------------------
echo Environment variables set (User scope).
echo PLEASE MANUALLY EDIT THIS FILE TO ADD SUPABASE KEYS!
echo Then restart your terminal for changes to seek.
echo ---------------------------------------------------
pause
