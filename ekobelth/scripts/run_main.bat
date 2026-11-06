@echo off
cd "%~dp0.."
call .venv\Scripts\activate.bat
python -m backend.main_api