@echo off
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not in PATH.
  echo Install Flutter, reopen VS Code, then run this file again.
  pause
  exit /b 1
)
flutter pub get
if errorlevel 1 pause & exit /b 1
flutter analyze
if errorlevel 1 pause & exit /b 1
flutter test
pause
