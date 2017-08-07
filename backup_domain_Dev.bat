@echo off

For /f "tokens=1-4 delims=/. " %%a in ('date /t') do (set mydate=%%c-%%b-%%d)
For /f "tokens=1-2 delims=/: " %%a in ('time /t') do (set mytime=%%a-%%b)

SET tmstmp=%mydate%_%mytime%
SET dir=D:\Backup
SET d_name=Dev
rem SET backup_file=%dir%\Informatica_%computername%_domain_backup-%d_name%-%tmstmp%
SET backup_file=%dir%\Informatica_%computername%_domain_backup-%d_name%-%tmstmp%

%INFA_HOME%\isp\bin\infasetup.bat BackupDomain -da dcn-nt-app26:1433 -du informatica-repos -dt mssqlserver -ds "Dinformatica" -bf %backup_file% -f -dn %d_name%
