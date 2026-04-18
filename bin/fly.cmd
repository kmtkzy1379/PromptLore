@echo off
set "FLYEXE=%USERPROFILE%\.fly\bin\fly.exe"
if not exist "%FLYEXE%" (
  echo Fly CLI not found at %FLYEXE%
  echo Install: https://fly.io/docs/hands-on/install-flyctl/
  exit /b 1
)
"%FLYEXE%" %*
