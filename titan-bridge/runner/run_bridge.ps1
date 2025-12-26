$env:SUPABASE_URL = "https://abkprecmhitqmmlzxfad.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"
$env:TELEGRAM_BOT_TOKEN = "8284941437:AAElTu-RcyN3dNv5jcrhJpknRgz4_akuPeI"
$env:RUNNER_AGENT_ID = "runner_win"
$env:POLL_SECONDS = "2"

Write-Host "Starting TITAN Bridge Runner..."
python runner.py
