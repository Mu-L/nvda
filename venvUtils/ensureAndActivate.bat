@echo off
rem this script ensures the NVDA build system Python virtual environment is created and up to date,
rem and then activates it.
rem This is an internal script and should not be used directly.
set hereOrig=%~dp0
set here=%hereOrig%
if #%hereOrig:~-1%# == #\# set here=%hereOrig:~0,-1%
set scriptsDir=%here%
set venvLocation=%here%\..\.venv

rem Ensure the environment is created and up to date
rem Check for an environment variable telling us the target architecture
rem If not defined, use the system architecture by getting it from WMI
rem do this locally so the resultant variable is not exported
setlocal
if not defined NVDATargetArch (
	for /f "tokens=2 delims==-" %%a in (
		'wmic os get osarchitecture /VALUE'
	) do (
		set NVDATargetArch=%%a
	)
)
if %NVDATargetArch%==32 goto makeVenv
if %NVDATargetArch%==64 goto makeVenv
rem The target architecture is neither 32- or 64-bit
echo Target architecture "%NVDATargetArch%" not recognised.
echo Ensure this script is running on a 32-bit or 64-bit operating system,
echo and, if set, %%NVDATargetArch%% is either 32 or 64.
goto :EOF

:makeVenv
rem Version of Python we're building against
set NVDAPythonVersion=3.11
for /f "delims=" %%a in ('py -%NVDAPythonVersion%-%NVDATargetArch% -VV') do set pyVersionInUse=%%a
echo Using %pyVersionInUse%
py -%NVDAPythonVersion%-%NVDATargetArch% "%scriptsDir%\ensureVenv.py"
if ERRORLEVEL 1 goto :EOF
endlocal

rem Set the necessary environment variables to have Python use this virtual environment.
rem This should set all the necessary environment variables that the standard .venv\scripts\activate.bat does
rem Except that we set VIRTUAL_ENV to a path relative to this script,
rem rather than it being hard-coded to where the virtual environment was first created.

rem unset the PYTHONHOME variable so as to ensure that Python does not use a customized Python standard library.
set PYTHONHOME=
rem set the VIRTUAL_ENV variable instructing Python to use a virtual environment
rem py.exe will honor VIRTUAL_ENV and launch the python.exe that it finds in %VIRTUAL_ENV%\scripts.
rem %VIRTUAL_ENV%\scripts\python.exe will find pyvenv.cfg in its parent directory,
rem which is actually what then causes Python to use the site-packages found in this virtual environment.
set VIRTUAL_ENV=%venvLocation%
rem Add the virtual environment's scripts directory to the path
set PATH=%VIRTUAL_ENV%\scripts;%PATH%
rem Set an NVDA-specific variable to identify this official NVDA virtual environment from other 3rd party ones
set NVDA_VENV=%VIRTUAL_ENV%
rem mention the environment in the prompt to make it obbvious it is active
rem just in case this script is executed outside of a local block and not cleaned up.
set PROMPT=[NVDA Venv] %PROMPT%
