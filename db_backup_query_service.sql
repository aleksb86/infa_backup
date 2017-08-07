declare @current_date as varchar(10)
declare @backup_filepath as nvarchar(250)
select @current_date = CONVERT(VARCHAR(10), GETDATE(), 105)
select @backup_filepath = N'D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Backup\mssql02_service_' + @current_date + '_DB'
BACKUP DATABASE [service] TO  DISK = @backup_filepath WITH NOFORMAT, NOINIT,  NAME = N'service-Полная База данных Резервное копирование', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
