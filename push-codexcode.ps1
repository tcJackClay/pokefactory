# Commit and push to codexcode branch
Write-Host "Committing all changes..." -ForegroundColor Cyan
git add -A
$commit_msg = Read-Host "Enter commit message"
git commit -m "$commit_msg"
Write-Host ""
Write-Host "Pushing to codexcode branch..." -ForegroundColor Cyan
git push -u origin codexcode
Write-Host "Done!" -ForegroundColor Green
