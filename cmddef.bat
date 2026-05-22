@echo off
set "name=%~1"
set "cmd=%~2"
set "arg=%~3"
set "ver=1.3"
set "realpath=%~dp0"

if exist "%realpath%cmddef_tmp.bat" (
	echo Cmddef updated successfully!
	del cmddef_tmp.bat
)

if "%name%"=="" goto usage
if "%name%"=="/?" goto usage
if "%name%"=="/f" goto folder
if "%name%"=="/u" goto download
if "%name%"=="/v" goto update
if "%name%"=="/d" goto delete
if "%name%"=="/l" goto list

set "no_echo=0"
set "no_args=0"
set "start_pause=0"
set "end_pause=0"
set "use_notepad=0"
set "timeout=0"
set "start_message=0"
set "end_message=0"
set "one_session=0"

:: Сдвигаем очередь аргументов на 2 (убираем name и cmd)
shift
shift

:parse_args
:: Если аргументов больше нет — выходим из цикла
if "%~1"=="" goto start_work

:: Проверяем флаги (теперь они могут быть в любом порядке)
if "%~1"=="-e" set "no_echo=1"
if "%~1"=="-a" set "no_args=1"
if "%~1"=="-p" set "start_pause=1"
if "%~1"=="-P" set "end_pause=1"
if "%~1"=="-n" set "use_notepad=1"
if "%~1"=="-s" set "one_session=1"
if "%~1"=="-t" (
	set "timeout=%~2"
	shift
)
if "%~1"=="-m" (
	set "start_message=%~2"
	shift
)
if "%~1"=="-M" (
	set "end_message=%~2"
	shift
)
if "%~1"=="-f" (
	set "realpath=%~2"
	shift
)

:: Переходим к следующему аргументу
shift
goto :parse_args
:start_work

set "realname=%realpath%%name%.bat"

if /i "%name%" == "cmddef" (
	set "error=Cannot overwrite cmddef!"
	goto error_h
)

if "%one_session%" == "1" (
	doskey "%name%=%cmd%"
	echo Created alias "%name%=%cmd%" for this session only
	goto eof
)

:: Используем скобки и перенос >, чтобы избежать проблем со спецсимволами
(
	if "%no_echo%" == "0" (
		echo @echo off
	)
	if "%start_pause%" == "1" (
		echo pause
	)
	if "%timeout%" NEQ "0" (
		echo timeout /t %timeout%
	)
	if "%start_message%" NEQ "0" (
		echo echo %start_message%
	)
	if "%no_args%" == "1" (
		echo %cmd%
	)else (
		echo %cmd% %%*
	)
	echo rem made by Dar cmddef version %ver%
	if "%end_message%" NEQ "0" (
		echo echo %end_message%
	)
	if "%end_pause%" == "1" (
		echo pause
	)
) > "%realname%"

if "%use_notepad%" == "1" call notepad "%realname%"
if exist "%realname%" (
	echo Created: %realname%
) else (
	echo Cannot create alias: %realname%
)
goto eof

:usage
echo -----Dar-Cmddef-Version-%ver%-----
echo Usage:
echo cmddef /?                 - help
echo cmddef /f                 - open alias folder
echo cmddef /u                 - download alias from github
echo cmddef /v                 - update cmddef from github
echo cmddef /l                 - list of aliases
echo cmddef /d alias           - delete alias
echo cmddef "alias" "command"  - create alias:
echo -e - no hiding commands
echo -a - no arguments
echo -p - add pause to start
echo -P - add pause to end
echo -n - open alias in notepad
echo -f - create in other folder
echo -m - add a message to start
echo -M - add a message to end
echo -s - create for this session only

goto eof

:delete
set "realname=%realpath%%cmd%.bat"
if /i "%cmd%" == "cmddef" (
	set "error=Cannot delete cmddef!"
	goto error_h
) else (
	if exist "%realname%" (
		del "%realname%" /q >nul || goto error_h
		echo Deleted: %realname%
	) else (
		set "error=Cannot find alias %realname%"
		goto error_h
	)
)
goto eof

:download
:: %cmd% тут будет именем алиаса, который хотим скачать
:: Собираем ссылку по кусочкам
set "base_url=https://raw.githubusercontent.com"
set "repo_name=cersat/my-aliases"
set "branch=main"

:: Итоговая склейка (имя файла берем из %cmd%)
set "full_url=%base_url%/%repo_name%/%branch%/files/%cmd%.bat"
echo Downloading %cmd% from GitHub...

:: Используем встроенный curl
powershell -Command "Invoke-WebRequest -Uri '%full_url%' -OutFile '%realpath%%cmd%.bat'"
rem curl -4 -f "%full_url%" -o "%realpath%%cmd%.bat"

if %errorlevel% equ 0 (
    echo Successfully installed: %cmd%
) else (
    set "error=Could not find alias "%cmd%" on GitHub."
	goto error_h
)
goto eof

:update
:: %cmd% тут будет именем алиаса, который хотим скачать
:: Собираем ссылку по кусочкам
set "base_url=https://raw.githubusercontent.com"
set "repo_name=cersat/my-aliases"
set "branch=main"

:: Итоговая склейка (имя файла берем из %cmd%)
set "full_url=%base_url%/%repo_name%/%branch%/cmddef.bat"
echo Installing new version of Cmddef from GitHub...

:: Используем встроенный curl
powershell -Command "Invoke-WebRequest -Uri '%full_url%' -OutFile '%realpath%cmddef_tmp.bat'"
echo Downloaded new version...

if exist "%realpath%cmddef_tmp.bat" (
    :: Вместо сложных скобок — просто одна команда запуска обновления в фоне
    start /b cmd /c "timeout /t 1 /nobreak >nul & move /y "%realpath%cmddef_tmp.bat" "%realpath%cmddef.bat" & exit /b"
    goto eof
)
set "error=Cannot found new cmddef version"
goto error_h

:list
for /f "delims=" %%i in ('dir /b "%realpath%" ^| findstr /i /v "cmddef.bat"') do (
    echo %%~ni
)
goto eof

:folder
explorer %realpath%
goto eof

:error_h
if defined error (
	echo [error] %error%
) else (
	echo [error] Unknown error!
)
goto eof

:eof
set "error="
set "realname="
set "realpath="
set "name="
set "cmd="
set "arg="
set "ver="
set "use_notepad="
set "start_pause="
set "end_pause="
set "timeout="
set "start_message="
set "end_message="
set "no_echo="
set "no_args="
set "full_url="
set "repo_name="
set "one_session="