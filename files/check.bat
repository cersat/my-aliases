@echo off
set "name=%~1"
:: 1. Проверяем, существует ли файл (внешняя команда)
where "%name%" >nul 2>nul
if %errorlevel%==0 (
    echo This is external command
    exit /b
)

:: 2. Проверяем через help, но с защитой от "ложных срабатываний"
help "%name%" 2>nul | findstr /b /i /c:"%name% " >nul
if %errorlevel%==0 (
    echo This is built-in Windows command
) else (
    echo This name is free
)
rem made by Dar cmddef version 1.1
