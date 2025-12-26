Get-ChildItem "$env:AZ_HOME\bridge\file-queue" -Filter *.json | Sort LastWriteTime -Desc | Select -First 1
