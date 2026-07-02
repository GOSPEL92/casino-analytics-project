@echo off
REM === Casino ETL Automation Script ===
sqlcmd -S DESKTOP-HRV6DMT\SQLEXPRESS -d CasinoAnalytics -E -i "C:\Data Project\CasinoAnalytics\Automation\04_Update_Automation.sql" -o "C:\Data Project\CasinoAnalytics\Automation\Logs\Casino_ETL_Output.txt"

echo [%date% %time%] Casino ETL script executed successfully >> "C:\Data Project\CasinoAnalytics\Automation\Logs\Casino_ETL_Output.txt"
pause
