param()

# 1) Load Supabase config/env
. "F:\ReachX-AI\scripts\Load-ReachXSupabase.ps1"

# 2) Publish workers from CSV -> Supabase
& "F:\ReachX-AI\scripts\Publish-ReachXWorkersToSupabase.ps1"

# 3) Show snapshot
& "F:\ReachX-AI\scripts\Get-ReachXWorkersSnapshot.ps1"
