@echo off
cd /d %~dp0

docker run --add-host="host.docker.internal:host-gateway" --gpus all --rm -it -p 8887:8888 -p 2223:22 -v C:\home_win\jupyter:/home/ssone/jupyter wm_win_img /bin/bash

cmd /k
