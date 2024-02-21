@echo off
cd /d %~dp0

echo docker build

docker build -t wm11_win_img .

pause
echo

# cmd /k