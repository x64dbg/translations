@echo off

echo Uploading English sources to Crowdin...
java -jar crowdin-cli.jar upload sources --no-colors --no-progress
if not %ERRORLEVEL%==0 (
    exit /b 1
)

echo Downloading translations from Crowdin...
rmdir /S /Q translations >nul 2>&1
java -jar crowdin-cli.jar download --no-colors --no-progress
if not %ERRORLEVEL%==0 (
    exit /b 1
)

echo Checking translations...
TranslationChecker.exe translations > TranslationChecker.log 2>&1
set CHECKER_ERRORLEVEL=%ERRORLEVEL%
type TranslationChecker.log

echo Generating Qt translations...
for %%f in (translations\*.ts) do (
    lrelease -nounfinished %%f
)
exit /b %CHECKER_ERRORLEVEL%
