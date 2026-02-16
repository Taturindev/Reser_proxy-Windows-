@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion
title "Full Proxy & Network Reset"

echo =========================================================
echo          FULL PROXY AND NETWORK RESET
echo =========================================================
echo.

:: Check for administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Script is not running as administrator.
    echo Some operations will be skipped.
    echo For complete reset, restart the script as administrator.
    echo.
    set "ADMIN=0"
) else (
    echo [OK] Administrator rights obtained.
    set "ADMIN=1"
)

:: ---------------------------------------------------------
:: 1. Clear current user registry (proxy settings)
:: ---------------------------------------------------------
echo.
echo --- Cleaning user registry (proxy) ---
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
if %errorlevel% equ 0 ( echo   + ProxyServer removed ) else ( echo   - ProxyServer not found )

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
if %errorlevel% equ 0 ( echo   + AutoConfigURL removed ) else ( echo   - AutoConfigURL not found )

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
if %errorlevel% equ 0 ( echo   + ProxyEnable set to 0 ) else ( echo   [ERROR] Failed to change ProxyEnable )

:: ---------------------------------------------------------
:: 2. Reset WinHTTP proxy (requires admin)
:: ---------------------------------------------------------
echo.
echo --- Resetting WinHTTP proxy ---
if !ADMIN!==1 (
    netsh winhttp reset proxy >nul 2>&1
    if %errorlevel% equ 0 ( echo   + WinHTTP proxy reset ) else ( echo   - Failed to reset WinHTTP )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 3. Clear environment variables
:: ---------------------------------------------------------
echo.
echo --- Clearing environment variables ---
set http_proxy=
set https_proxy=
echo   + http_proxy and https_proxy cleared (current session)

:: ---------------------------------------------------------
:: 4. Flush DNS cache
:: ---------------------------------------------------------
ipconfig /flushdns >nul 2>&1
if %errorlevel% equ 0 ( echo   + DNS cache flushed ) else ( echo   - Failed to flush DNS )

:: ---------------------------------------------------------
:: 5. Reset Winsock (requires admin)
:: ---------------------------------------------------------
echo.
echo --- Resetting Winsock ---
if !ADMIN!==1 (
    netsh winsock reset >nul 2>&1
    if %errorlevel% equ 0 ( echo   + Winsock reset successfully ) else ( echo   - Failed to reset Winsock )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 6. Reset TCP/IP stack (requires admin)
:: ---------------------------------------------------------
echo.
echo --- Resetting TCP/IP stack ---
if !ADMIN!==1 (
    netsh int ip reset >nul 2>&1
    if %errorlevel% equ 0 ( echo   + TCP/IP stack reset ) else ( echo   - Failed to reset TCP/IP )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 7. Clear ARP cache (requires admin)
:: ---------------------------------------------------------
echo.
echo --- Clearing ARP cache ---
if !ADMIN!==1 (
    arp -d * >nul 2>&1
    if %errorlevel% equ 0 ( echo   + ARP cache cleared ) else ( echo   - Failed to clear ARP )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 8. Clear NetBIOS cache (requires admin)
:: ---------------------------------------------------------
echo.
echo --- Clearing NetBIOS cache ---
if !ADMIN!==1 (
    nbtstat -R >nul 2>&1
    if %errorlevel% equ 0 ( echo   + NetBIOS cache cleared ) else ( echo   - Failed to clear NetBIOS )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 9. Renew IP address (optional, with confirmation)
:: ---------------------------------------------------------
echo.
echo --- Renew IP address (DHCP) ---
if !ADMIN!==1 (
    set /p renew="Run ipconfig /release and /renew? This will temporarily disconnect the network. (y/N): "
    if /i "!renew!"=="y" (
        echo   Releasing IP...
        ipconfig /release >nul 2>&1
        echo   Renewing IP...
        ipconfig /renew >nul 2>&1
        echo   + IP address renewed.
    ) else (
        echo   - Skipped.
    )
) else (
    echo   - Skipped (requires admin rights)
)

:: ---------------------------------------------------------
:: 10. Ask for reboot
:: ---------------------------------------------------------
echo.
echo --- Finishing ---
set /p reboot="Reboot computer now? (y/N): "
if /i "!reboot!"=="y" (
    if !ADMIN!==1 (
        echo Rebooting in 10 seconds. Save your work!
        shutdown /r /t 10 /c "RemoverProxy: reboot to apply network settings."
    ) else (
        echo Cannot reboot: administrator rights required.
        echo Please reboot manually.
    )
) else (
    echo Reboot canceled. It is recommended to reboot manually.
)

:: ---------------------------------------------------------
:: Done
:: ---------------------------------------------------------
echo.
echo =========================================================
echo DONE! Proxy and network settings have been reset.
echo =========================================================
echo.
pause