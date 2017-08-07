@echo off

For /f "tokens=1-4 delims=/. " %%a in ('date /t') do (set mydate=%%c-%%b-%%d)
For /f "tokens=1-2 delims=/: " %%a in ('time /t') do (set mytime=%%a-%%b)

SET tmstmp=%mydate%_%mytime%
SET dir=D:\Backup
SET repos_name=RS_DWH
SET backup_file=%dir%\Informatica_%computername%_repository_backup-%repos_name%-%tmstmp%.rep
%INFA_HOME%\server\bin\pmrep.exe connect -r %repos_name% -n %PMUSER% -X PMPASSWORD -d DEV
%INFA_HOME%\server\bin\pmrep.exe backup -f -o %backup_file%