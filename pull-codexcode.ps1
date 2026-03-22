# Pull codexcode branch from remote
Write-Host "Pulling codexcode branch from remote..." -ForegroundColor Cyan
git fetch origin codexcode
git checkout -B codexcode origin/codexcode
Write-Host "Done!" -ForegroundColor Green
