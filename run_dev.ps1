# Launch Admin API
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd adminpanel/api; npm run start:dev" -WorkingDirectory $PSScriptRoot

# Launch Admin Web
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd adminpanel/web; npm run dev" -WorkingDirectory $PSScriptRoot

# Launch Flutter Application
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd application; D:\flutter\bin\flutter.bat run -d chrome" -WorkingDirectory $PSScriptRoot

Write-Host "Launched Admin API, Admin Web, and Flutter App in separate windows!" -ForegroundColor Green
