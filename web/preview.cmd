@echo off
cd /d "%~dp0"
echo Open http://127.0.0.1:4265 in your browser. Press Ctrl+C to stop.
python -m http.server 4265 --bind 127.0.0.1
pause
