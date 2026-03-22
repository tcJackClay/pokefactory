@echo off
chcp 65001 >nul
echo Committing all changes...
git add -A
echo Enter commit message:
set /p commit_msg=
git commit -m "%commit_msg%"
echo.
echo Pushing to codexcode branch...
git push -u origin codexcode
echo Done!
pause
