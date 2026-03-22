@echo off
chcp 65001 >nul
echo Pulling codexcode branch from remote...
git fetch origin codexcode
git checkout -B codexcode origin/codexcode
echo Done!
pause
