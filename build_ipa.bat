@echo off
REM Скрипт для сборки IPA на Windows (требует macOS/Xcode)
REM Этот скрипт предназначен для запуска на macOS через SSH или аналогично

echo.
echo ========================================
echo   Сборка IPA для iOS приложения
echo ========================================
echo.
echo ВАЖНО: Этот скрипт должен выполняться на macOS с установленным Xcode
echo.
echo Для сборки IPA на Windows вам нужно:
echo 1. Использовать macOS виртуальную машину
echo 2. Использовать удаленный Mac
echo 3. Использовать облачный сервис (например, MacStadium, AWS Mac instances)
echo.
echo Альтернатива: Используйте Xcode напрямую на macOS
echo.
pause

REM Если у вас есть доступ к macOS через SSH, используйте:
REM ssh user@mac-server "cd /path/to/project && ./build_ipa.sh"
