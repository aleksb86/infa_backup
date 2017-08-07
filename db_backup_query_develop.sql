declare @current_date as varchar(10)
declare @backup_filepath as nvarchar(250)
select @current_date = CONVERT(VARCHAR(10), GETDATE(), 105)
select @backup_filepath = N'D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\dcn-nt-app26_DEVELOP_' + @current_date + '_DB'
BACKUP DATABASE [develop] TO  DISK = @backup_filepath  WITH NOFORMAT, NOINIT,  NAME = N'develop-Full-backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'develop' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'develop' )
if @backupSetId is null begin raiserror(N'Ошибка верификации. Сведения о резервном копировании для базы данных "develop" не найдены.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = @backup_filepath WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND