/****************************************************************************************************

-- This script works with the following versions of SQL Server
		2008
		2008 R2
		2012
		2014
		2016

--This script will also work with a case sensitive collation

--This script will not work with SQL Server 2005, however individual portions will, run each script manually

--If it has been a long time since the last restart it might take awhile to run this script due
	to the error being very large

--Must be a member of the SysAdmin server role to run this script

****************************************************************************************************/

-- If the variable is set to 1, the SQL Error log will be included in the result set.  If you plan
-- on saving the results to file and then plan on emailing it, the inclusion of the error log could
-- make the file too big to email.

--It is recommended that if you are exporting the results to a file, export the error log to a separate file

		DECLARE @@IncludeErrorLog BIT

		-- set to 1 to include the error log, 0 to no include the error log
		SET @@IncludeErrorLog = 0

	--Reads the SQL server Error log
	-- @IncludeErrorLog = 1, include the error log
	-- @IncludeErrorLog = 0, do not include the log
	
		If @@IncludeErrorLog = 1
			BEGIN
				EXEC master.dbo.xp_readerrorlog
			END
				
/***************************************************************************************************/

		PRINT ''
		PRINT ''
		PRINT ''
		PRINT '*********************************************************************************'
		PRINT ''
		PRINT ''
		PRINT '       THE FOLLOWING DATA PROVIDES A HIGHLEVEL OVERVIEW OF THE SERVER BEING REVIEWED.'
		PRINT '       COMPLETED BY: ' + system_user
		PRINT '       COMPLETED ON: ' + CONVERT(VARCHAR(20),Getdate(), 101)
		PRINT ''
		PRINT ''
		PRINT '*********************************************************************************'
		PRINT ''
		PRINT ''

/***************************************************************************************************/
		
--Returns the installation date
		SET NOCOUNT ON

		SELECT TOP 1 'Server Install Date' AS 'Description', CONVERT(VARCHAR(30),@@SERVERNAME) AS 'ServerName', createdate AS [InstallDate], loginname
		FROM .[master].sys.syslogins
		WHERE loginname = 'NT SERVICE\MSSQLSERVER' OR loginname = 'NT AUTHORITY\SYSTEM'
		ORDER BY createdate DESC
		

/****************************************************************************************************/

--Last Restart Date for SQL Server service
	--SQL Server services
		DECLARE @SQLVersion6 VARCHAR(100)
		DECLARE @RTM1 VARCHAR(4)

		SELECT @SQLVersion6 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )
		SELECT @RTM1 = CONVERT(VARCHAR(20),SERVERPROPERTY ('productlevel'))  

			IF  LEFT(@SQLVersion6, 4) in (10.5, 11.0, 12.0, 13.0)
				BEGIN
					IF LEFT(@SQLVersion6, 4) = 10.5 AND @RTM1 = 'RTM'
							BEGIN						
								SELECT
									  'Service Restart Date' AS 'Status'
									,  sqlserver_start_time
								FROM sys.dm_os_sys_info
							END
					ELSE
							BEGIN
								SELECT  
									 'Service Restart Time' as 'Status'
									, ServiceName
									, Startup_type_desc
									, Status_desc
									, last_startup_time
									, service_account
									, filename
								FROM   sys.dm_server_services 
							END
				END
			ELSE
				BEGIN
						SELECT
						  'Service Restart Date' AS 'Status'
						,  sqlserver_start_time
					FROM sys.dm_os_sys_info
				END


/****************************************************************************************************/
--Last restart of the OS

		SELECT 'Last OS Reboot' AS 'Status'
				, DATEADD(SECOND, (ms_ticks/1000)*(-1), GETDATE()) AS 'Restart Date'
		FROM sys.dm_os_sys_info

/****************************************************************************************************/

--Returns start up parameter information
		DECLARE @SQLVersion7 VARCHAR(100)
		DECLARE @RTM VARCHAR(4)

		SELECT @SQLVersion7 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )
		SELECT @RTM = CONVERT(VARCHAR(20),SERVERPROPERTY ('productlevel'))  

			IF  LEFT(@SQLVersion7, 4) in (10.5, 11.0, 12.0, 13.0)
				BEGIN
						IF LEFT(@SQLVersion7, 4) = 10.5 AND @RTM = 'RTM'
							BEGIN						
								SELECT 'Unable to get Startup parameters due to version'
							END
						ELSE
							BEGIN
								SELECT 'Start Up Parameter Information',
									DSR.registry_key,
									DSR.value_name,
									DSR.value_data
								FROM sys.dm_server_registry AS DSR
								WHERE 
									DSR.registry_key LIKE N'%MSSQLServer\Parameters'
							END
				END
			ELSE
				BEGIN
					SELECT 'Unable to get Startup parameters due to version'
				END


/****************************************************************************************************/

--Get location of the SQL Server binary files



		DECLARE @path NVARCHAR(100)                 
        DECLARE @instance_name NVARCHAR(100)   
        DECLARE @instance_name1 NVARCHAR(100)
        DECLARE @system_instance_name NVARCHAR(100)          
		DECLARE @key NVARCHAR(1000)  
        SET @instance_name = COALESCE(CONVERT(NVARCHAR(100), SERVERPROPERTY('InstanceName')),'MSSQLSERVER');                        
		IF @instance_name!='MSSQLSERVER'                        
		SET @instance_name=@instance_name                       
	    SET @instance_name1= COALESCE(CONVERT(NVARCHAR(100), SERVERPROPERTY('InstanceName')),'MSSQLSERVER');                        
		IF @instance_name1!='MSSQLSERVER'                        
		SET @instance_name1='MSSQL$'+@instance_name1                        
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL', @instance_name, @system_instance_name output;                        
                  
		SET @key=N'SYSTEM\CurrentControlSet\Services\' +@instance_name1;                                              
		
        EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='ImagePath',@value=@path OUTPUT  

		 Select 'SQL Server EXE Path', @path as Binaries_Path

/****************************************************************************************************/

--Determines if the server is physical or virtual
		PRINT ''
		PRINT ''
		PRINT ''
		SET NOCOUNT ON
		DECLARE @SQLVersion4 VARCHAR(100)
		DECLARE @SQLPV NVARCHAR(3000)
		SELECT @SQLVersion4 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )

		IF  LEFT(@SQLVersion4, 2) in (11, 12, 13)
				BEGIN
					SET @SQLPV = 'SELECT CONVERT(VARCHAR(50),SERVERPROPERTY(''computernamephysicalnetbios'')) AS ServerName
									,dosi.virtual_machine_type_desc
									,Server_type = CASE 
											WHEN dosi.virtual_machine_type = 1
											THEN ''Virtual'' 
										ELSE ''Physical''
										END
					FROM master.sys.dm_os_sys_info dosi'
					EXECUTE sp_executesql @SQLPV
				END
		ELSE
			BEGIN
			    SELECT 'Cannot determine if Physical or Virtual, SQL Server 2008 or older'
			END


/****************************************************************************************************/

--Captures current version of SQL Server
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT @@version AS 'Version'

		SELECT CONVERT(VARCHAR(20),SERVERPROPERTY('productversion')) AS 'Version'
			 , CONVERT(VARCHAR(20),SERVERPROPERTY ('productlevel'))  AS 'ProductLevel'
			 , SERVERPROPERTY ('edition') AS 'Edition'

/****************************************************************************************************/
--Returns the trace flags that are enabled
		PRINT ' '
		PRINT '================================================================================================================================='
		
		SET NOCOUNT ON
		PRINT 'Trace Flag Status is below.  If no records, then there are not any trace flags enabled'
		PRINT ' '
		DBCC TRACESTATUS(-1);  

		PRINT ' '
		PRINT '================================================================================================================================='
		PRINT ' '
		
	
/****************************************************************************************************/

--Gets the authentication mode
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Authentication Mode' AS 'Setting', 
				CASE SERVERPROPERTY('IsIntegratedSecurityOnly')   
					WHEN 1 THEN 'Windows Authentication'   
					WHEN 0 THEN 'Windows and SQL Server Authentication'  
				END AS [Authentication Mode]  


/****************************************************************************************************/
--Gets Filestream share path

	SELECT SERVERPROPERTY ( 'FilestreamShareName' )  


/****************************************************************************************************/

--Gets the failed logins from the currently error log

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC sp_readerrorlog 0, 1, 'fail'
		
/****************************************************************************************************/

--Gets the error related entries from the currently error log

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC sp_readerrorlog 0, 1, 'error'  

/****************************************************************************************************/
--Checks to see if xp_cmdshell is enabled
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT	  Name
				, CASE WHEN value_in_use = 1 then 'Enable' ELSE 'Disabled' END AS 'Current Setting'
		FROM  sys.configurations 
		WHERE  name = N'xp_cmdshell' ; 

/****************************************************************************************************/

--Returns information regarding the Service Broker

		SELECT 	'Service Broker Enabled for these databases' AS 'Status'
			, name
			, is_broker_enabled 
		FROM sys.databases
		WHERE is_broker_enabled = 1

		SELECT 'Service Broker Queues' AS 'Status'
				, name
				, object_id
				, modify_date
		FROM sys.service_queues

		SELECT    'Messages in the Queues' AS 'Status'
				, p.object_id
				, p.rows
		FROM sys.objects AS o
				INNER JOIN sys.partitions AS p 
					ON p.object_id = o.object_id
				INNER JOIN sys.objects AS q 
					ON o.parent_object_id = q.object_id
		WHERE p.index_id = 1

		SELECT 'Active SPIDS using the queues' AS 'Status'
				, * 
		FROM sys.dm_broker_activated_tasks


/****************************************************************************************************/

--Checks to see if the Resource Govenor is enabled
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion2 VARCHAR(100)

		SELECT @SQLVersion2 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )

			IF  LEFT(@SQLVersion2, 2) in (11, 12)
				BEGIN
					SELECT 'Resource Govenor' AS 'Setting'
							, Case WHEN is_enabled = 1 then 'Enable' ELSE 'Disabled' END
					FROM sys.resource_governor_configuration 
				END

/****************************************************************************************************/

--Checks to see if there are any Server triggers
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion3 VARCHAR(100)

		SELECT @SQLVersion3 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )

			IF  LEFT(@SQLVersion3, 2) in (11, 12)
				BEGIN
					SELECT 'Server Triggers' AS 'Setting'
							, CONVERT(VARCHAR(50),name) as 'Server Trigger Name' 
					FROM sys.server_triggers
				END

		IF @@Rowcount = 0
			BEGIN
				Select 'No server Triggers found' AS 'Status'
			END

/****************************************************************************************************/

--Checks to see if there are any Server trigger evebts
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion5 VARCHAR(100)

		SELECT @SQLVersion5 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )

			IF  LEFT(@SQLVersion5, 2) in (11, 12)
				BEGIN
					SELECT 'Server Trigger Events'  AS 'Setting', * 
					FROM sys.server_trigger_events
				END
		IF @@Rowcount = 0
			BEGIN
				Select 'No server Trigger events found' AS 'Status'
			END

/****************************************************************************************************/

--Is Replication enabled
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT    'Replication Status'  AS 'Setting'
				, CONVERT(VARCHAR(50),name) as [Database name]
				, CASE is_published WHEN 0 THEN 'No' ELSE 'Yes' END AS [Is Published]
				, CASE is_merge_published WHEN 0 THEN 'No' ELSE 'Yes' END AS [Is Merge Published]
				, CASE is_distributor WHEN 0 THEN 'No' ELSE 'Yes' END AS [Is Distributor]
				, CASE is_subscribed WHEN 0 THEN 'No' ELSE 'Yes' END AS [Is Subscribed] 
		FROM sys.databases 
		WHERE database_id > 4

/****************************************************************************************************/

--Gets the accounts the service run under

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE   @REGISTRYPATH			VARCHAR(200)
				, @NAMEDINSTANCEIND		CHAR(1)
				, @INSTANCENAME			VARCHAR(128)
				, @SQLSERVERSVCACCOUNT	VARCHAR(128)
				, @SQLAGENTSVCACCOUNT	VARCHAR(128)
				, @DTCSVCACCOUNT		VARCHAR(128)
				, @OLAPSTARTUP			VARCHAR(128)
				, @SQLSERVERSTARTUP		VARCHAR(128)
				, @SQLAGENTSTARTUP		VARCHAR(128)
				, @DTCSTARTUP			VARCHAR(128)
				, @OLAPSVCACCOUNT		VARCHAR(128)
				, @SSRSSVCACCOUNT		VARCHAR(128)
				, @SSRSTARTUP			VARCHAR(128)
 
		CREATE TABLE #SERVICEACCOUNTS (VALUE VARCHAR(50), DATA VARCHAR(50))

		IF @@SERVERNAME IS NULL
			OR (CHARINDEX('\',@@SERVERNAME)=0)
		SET @NAMEDINSTANCEIND = 'N'
		ELSE
		BEGIN
		SET @NAMEDINSTANCEIND = 'Y'
		SET @INSTANCENAME = RIGHT( @@SERVERNAME , LEN(@@SERVERNAME) - CHARINDEX('\',@@SERVERNAME))
		END
 
		-- SQL SERVER
		SET @REGISTRYPATH = 'SYSTEM\CURRENTCONTROLSET\SERVICES\'
		IF @NAMEDINSTANCEIND = 'N'
			SET @REGISTRYPATH = @REGISTRYPATH + 'MSSQLSERVER'
		ELSE
			SET @REGISTRYPATH = @REGISTRYPATH + 'MSSQL$' + @INSTANCENAME
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'OBJECTNAME'
		SELECT @SQLSERVERSVCACCOUNT = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'START'
		SELECT @SQLSERVERSTARTUP = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
 
		-- SQL AGENT
		SET @REGISTRYPATH = 'SYSTEM\CURRENTCONTROLSET\SERVICES\'
		IF @NAMEDINSTANCEIND = 'N'
			SET @REGISTRYPATH = @REGISTRYPATH + 'SQLSERVERAGENT'
		ELSE
			SET @REGISTRYPATH = @REGISTRYPATH + 'SQLAGENT$' + @INSTANCENAME
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'OBJECTNAME'
		SELECT @SQLAGENTSVCACCOUNT = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'START'
		SELECT @SQLAGENTSTARTUP = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
 
		-- SSIS
		SET @REGISTRYPATH = 'SYSTEM\CURRENTCONTROLSET\SERVICES\MSDTSserver100' 
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'OBJECTNAME'
		SELECT @DTCSVCACCOUNT = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'START'
		SELECT @DTCSTARTUP = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
 
		--SSAS
 
		SET @REGISTRYPATH = 'SYSTEM\CURRENTCONTROLSET\SERVICES\MSSQLSERVEROLAPSERVICE'
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'OBJECTNAME'
		SELECT @OLAPSVCACCOUNT = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'START'
		SELECT @OLAPSTARTUP = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
 
		--SSRS
 
		SET @REGISTRYPATH = 'SYSTEM\CURRENTCONTROLSET\SERVICES\REPORTSERVER'
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'OBJECTNAME'
		SELECT @SSRSSVCACCOUNT = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
		INSERT #SERVICEACCOUNTS
			EXEC master..xp_regread 'HKEY_LOCAL_MACHINE' , @REGISTRYPATH,'START'
		SELECT @SSRSTARTUP = DATA FROM #SERVICEACCOUNTS
		DELETE FROM #SERVICEACCOUNTS
 

 
		SELECT 'Installed Services for the Instance'  AS 'Setting'
				, CONVERT(VARCHAR(50),CAST( SERVERPROPERTY ('SERVERNAME') AS NVARCHAR(128))) AS SERVERNAME
				, CONVERT(VARCHAR(50),COALESCE ( CAST( SERVERPROPERTY ('INSTANCENAME') AS NVARCHAR(128) ) , 'DEFAULT')) AS INSTANCE
				, CONVERT(VARCHAR(50),@SQLSERVERSVCACCOUNT) AS [SQL SERVER ACCOUNT]
				, CONVERT(VARCHAR(50),@SQLAGENTSVCACCOUNT) AS [SQL AGENT ACCOUNT]
				, CONVERT(VARCHAR(50),@DTCSVCACCOUNT) AS [SSIS]
				, CONVERT(VARCHAR(50),@OLAPSVCACCOUNT) AS [SSAS]
				, CONVERT(VARCHAR(50),@SSRSSVCACCOUNT) AS [SSRS]
		DROP TABLE #SERVICEACCOUNTS

/****************************************************************************************************/

--Gets the Domain the server is in
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC master.dbo.xp_loginconfig 'Default Domain'

/*****************************************************************************************************/

--Returns the names of all instances on the server and Port number

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''

		DECLARE @CurrID INT, @ExistValue INT, @MaxID INT, @SQL NVARCHAR(1000)
		DECLARE @TCPPorts TABLE (PortType NVARCHAR(180), Port INT)
		DECLARE @SQLInstances TABLE (InstanceID INT IDENTITY(1, 1) not null PRIMARY KEY,
									 InstName NVARCHAR(180),
									 Folder NVARCHAR(50),
									 StaticPort INT null,
									 DynamicPort INT null,
									 Platform INT null);
		DECLARE @Plat TABLE (Id INT,Name VARCHAR(180),InternalValue VARCHAR(50), Charactervalue VARCHAR (50))
		DECLARE @Platform VARCHAR(100)
		INSERT INTO @Plat EXEC xp_msver platform
		SELECT @Platform = (SELECT 1 FROM @Plat WHERE Charactervalue LIKE '%86%')
		IF @Platform IS NULL 
			BEGIN 
				INSERT INTO @SQLInstances (InstName, Folder)
				EXEC xp_regenumvalues N'HKEY_LOCAL_MACHINE',
											 N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL';
				UPDATE @SQLInstances SET Platform=64 
			END
		ELSE
			BEGIN
				INSERT INTO @SQLInstances (InstName, Folder)
				EXEC xp_regenumvalues N'HKEY_LOCAL_MACHINE',
											 N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL';
				UPDATE @SQLInstances SET Platform=32
			END   
		DECLARE @Keyexist TABLE (Keyexist INT)
		INSERT INTO @Keyexist
		EXEC xp_regread'HKEY_LOCAL_MACHINE',
									  N'SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL';
		SELECT @ExistValue= Keyexist FROM @Keyexist
		If @ExistValue=1
		INSERT INTO @SQLInstances (InstName, Folder)
		EXEC xp_regenumvalues N'HKEY_LOCAL_MACHINE',
									  N'SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL';
		UPDATE @SQLInstances SET Platform =32 WHERE Platform IS NULL
		SELECT @MaxID = MAX(InstanceID), @CurrID = 1
		FROM @SQLInstances
		WHILE @CurrID <= @MaxID
		  BEGIN
			  DELETE FROM @TCPPorts
			  SELECT @SQL = 'Exec xp_instance_regread N''HKEY_LOCAL_MACHINe'',
									  N''SOFTWARE\Microsoft\\Microsoft SQL Server\' + Folder + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'',
									  N''TCPDynamicPorts'''
			  FROM @SQLInstances
			  WHERE InstanceID = @CurrID
			  INSERT INTO @TCPPorts
			  EXEC sp_executesql @SQL
			  SELECT @SQL = 'Exec xp_instance_regread N''HKEY_LOCAL_MACHINE'',
									  N''SOFTWARE\Microsoft\\Microsoft SQL Server\' + Folder + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'',
									  N''TCPPort'''
			  FROM @SQLInstances
			  WHERE InstanceID = @CurrID
			  INSERT INTO @TCPPorts
			  EXEC sp_executesql @SQL
			  SELECT @SQL = 'Exec xp_instance_regread N''HKEY_LOCAL_MACHINE'',
									  N''SOFTWARE\Wow6432Node\Microsoft\\Microsoft SQL Server\' + Folder + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'',
									  N''TCPDynamicPorts'''
			  FROM @SQLInstances
			  WHERE InstanceID = @CurrID
			  INSERT INTO @TCPPorts
			  EXEC sp_executesql @SQL
			  SELECT @SQL = 'Exec xp_instance_regread N''HKEY_LOCAL_MACHINE'',
									  N''SOFTWARE\Wow6432Node\Microsoft\\Microsoft SQL Server\' + Folder + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'',
									  N''TCPPort'''
			  FROM @SQLInstances
			  WHERE InstanceID = @CurrID
			  INSERT INTO @TCPPorts
			  EXEC sp_executesql @SQL
			  UPDATE SI
			  SET StaticPort = P.Port,
					DynamicPort = DP.Port
			  FROM @SQLInstances SI
			  INNER JOIN @TCPPorts DP ON DP.PortType = 'TCPDynamicPorts'
			  INNER JOIN @TCPPorts P ON P.PortType = 'TCPPort'
			  WHERE InstanceID = @CurrID;
			  SET @CurrID = @CurrID + 1
		  END

		SELECT 'Instances Installed' AS 'Setting'
					, CONVERT(VARCHAR(50),SERVERPROPERTY('ComputerNamePhysicalNetBIOS')) AS ServerName
					, CONVERT(VARCHAR(50),InstName) AS 'Instance Name'
					, StaticPort
					, DynamicPort
					, Platform
		FROM @SQLInstances


		SET NOCOUNT OFF

/****************************************************************************************************/

--Information about the Databases
		SET NOCOUNT ON

		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Database Info - Collation'  AS 'Setting'
				, Name
				, collation_name

		FROM sys.databases


		SET NOCOUNT ON

		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Database Info - Settings'  AS 'Setting'
				, CONVERT(VARCHAR(50),Name) AS 'Name'
				, recovery_model_desc
				, page_verify_option_desc
		FROM sys.databases

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Database Info - Access'  AS 'Setting'
				, CONVERT(VARCHAR(50),Name) AS 'Name'
				, user_access_desc
				, is_read_only
		FROM sys.databases

/*****************************************************************************************************/

--Checks to see if there are any database snapshots
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 
			 'Database Snapshots'  AS 'Setting'
			, Name
		FROM sys.databases 
		WHERE source_database_id IS NOT NULL
		IF @@Rowcount = 0
				BEGIN
					Select 'No databases snapshots were found' AS 'Status'
				END

/*****************************************************************************************************/

-- Returns file information for each database
		SET NOCOUNT ON

		PRINT ''
		PRINT ''
		PRINT ''
		CREATE TABLE #DBInfo
				( DBBame VARCHAR(128)
				, FileName VARCHAR(500))

		SET NOCOUNT ON	
		EXECUTE master.sys.sp_MSforeachdb 'USE [?] INSERT INTO #DBInfo SELECT       
			  name
			, filename
				FROM dbo.sysfiles a '

		SELECT 'DB File Information - Location'  AS 'Setting'
				, CONVERT(VARCHAR(50),DBBame) AS 'Name'
				, FileName 
		FROM #DBInfo

		DROP TABLE #DBInfo


/*****************************************************************************************************/

-- Returns file information for each database
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		CREATE TABLE #DBInfo1
				( DBBame VARCHAR(50)
				, FileSizeMB DECIMAL(32,2)
				, SpaceUsedMB DECIMAL(32,2)
				, FreeSpaceMB DECIMAL(32,2))

		
		EXECUTE master.sys.sp_MSforeachdb 'USE [?] INSERT INTO #DBInfo1 SELECT       
			  name
			, CONVERT(DECIMAL(12,2),ROUND(a.size/128.000,2)) AS FileSizeMB    
			, CONVERT(DECIMAL(12,2),ROUND(FILEPROPERTY(a.name,''SpaceUsed'')/128.000,2)) AS SpaceUsedMB     
			, CONVERT(DECIMAL(12,2),ROUND((a.size-FILEPROPERTY(a.name,''SpaceUsed''))/128.000,2)) AS FreeSpaceMB 
				FROM dbo.sysfiles a '

		SELECT 'DB File Information - Size'  AS 'Setting', *
				 
		FROM #DBInfo1

		DROP TABLE #DBInfo1


/****************************************************************************************************/
--Used to capture information regarding the database files
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Database File Information - State Description and Max Size'  AS 'Setting'
			, CONVERT(VARCHAR(50),name) AS 'Name'
			, CONVERT(VARCHAR(50),State_desc) AS 'State Description'
			, max_size -- -1 means unlimited or until drive is full
			, growth
		FROM master.sys.master_files


/****************************************************************************************************/

--Used to capture information regarding the databases
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Database Information - Statistics Information'  AS 'Setting'
			 , CONVERT(VARCHAR(50),a.name) AS 'Name'
			 , a.Create_date
			 , a.compatibility_level
			 , a.is_auto_create_stats_on
			 , a.is_auto_update_stats_on
			 , b.name AS 'DBOwner' 
		FROM sys.databases a
				INNER JOIN  sys.syslogins b
					ON a.owner_sid = b.sid

/****************************************************************************************************/
--Checks to see if the Auto Close database setting is set to off
			SET NOCOUNT ON
			PRINT ''
			PRINT ''
			PRINT ''
			SELECT 'Is Auto Close Set'  AS 'Setting'
					, CONVERT(VARCHAR(50),name) AS 'Name'
			FROM sys.databases
			WHERE is_auto_close_on = 1
			
			IF @@Rowcount = 0
				BEGIN
					Select 'No databases are set to AutoClose' AS 'Status'
				END

/*************************************************************************************************/

--Gets filegroup information for each database
		SET NOCOUNT ON

		PRINT ''
		PRINT ''
		PRINT ''
		CREATE TABLE  #fg  (  DBName varchar(128)
							, name sysname
							, IsDefault BIT
							, IsReadOnly Bit) 
		EXEC  master.sys.sp_MSforeachdb  ' 
			    use [?] 
				insert into #fg select db_name() ,name, is_default, is_read_only from sys.filegroups  ' 
		 SELECT  'DB Filegroup Information' AS 'Setting'
					, CONVERT(VARCHAR(50),DBName) AS 'DBName'
					, CONVERT(VARCHAR(50),name) AS 'Name'
					, IsDefault
					, IsReadOnly
		 FROM  #fg 

		 Select * from #fg

		 DROP TABLE  #fg   

/*************************************************************************************************/
--Check to see if Change Data Capture is enabled for any databases
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT  'Change Data Capture Enabled'  AS 'Setting'
				, name
				, database_id
				, is_cdc_enabled 
		FROM sys.databases
		WHERE is_cdc_enabled = 1

		IF @@Rowcount = 0
			BEGIN
				Select 'Change Data Capture is not enabled for any database' AS 'Status'
			END

/************************************************************************************************/

--Checks to see if there have been and Change Data Capture errors in the past 30 days
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
			SELECT 'Change Data Capture Errors' AS 'Setting'
					, entry_time  
					, error_number 
					, error_severity 
					, error_state 
					, error_message 
			FROM sys.dm_cdc_errors 
			WHERE CONVERT(varchar(10),  Entry_Time, 101) > CONVERT(varchar(10), DATEADD(day, -30,  GETDATE()), 101)
			IF @@Rowcount = 0
				BEGIN
					Select 'No Change Data Capture Errors were found, confirm CDC is enabled' AS 'Status'
				END

/************************************************************************************************/

--Checks to see if any databases are enabled for Change Tracking
			SET NOCOUNT ON
			PRINT ''
			PRINT ''
			PRINT ''
			SELECT   
					  'Change Tracking'  AS 'Setting'
					, d.name
					,c.* 
			FROM sys.change_tracking_databases c
				INNER JOIN sys.databases d
					ON c.database_id = d.database_id
							IF @@Rowcount = 0
			BEGIN
				Select 'Change Tracking is not enabled for any database' AS 'Status'
			END

/*************************************************************************************************/

--Returns any databases restored recently, Past 30 days
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Restored Databases Past 30 Days'  AS 'Setting'
				, CONVERT(VARCHAR(50),[rs].[destination_database_name]) AS 'Destination DB Name'
				, [rs].[restore_date] 
				, [bs].[backup_start_date] 
				,[bs].[backup_finish_date] 
				,[bs].[database_name] AS [source_database_name]
		FROM msdb.dbo.restorehistory rs
				INNER JOIN msdb.dbo.backupset bs
						ON [rs].[backup_set_id] = [bs].[backup_set_id]
				INNER JOIN msdb.dbo.backupmediafamily bmf 
						ON [bs].[media_set_id] = [bmf].[media_set_id] 
		WHERE bs.backup_finish_date > GETDATE() - 30
		ORDER BY [rs].[restore_date] DESC
		IF @@Rowcount = 0
			BEGIN
				Select 'No databases have been restored in past 30 days' AS 'Status'
			END

/****************************************************************************************************/

--Free Log space for all databases
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DBCC SQLPERF(LOGSPACE);

/****************************************************************************************************/

--Capture most required information about the databases
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT   'Database Information - General Settings and LastBackup Info'  AS 'Setting'
				 ,database_id,
				 CONVERT(VARCHAR(25), DB.name) AS dbName,
				 CONVERT(VARCHAR(10), DATABASEPROPERTYEX(name, 'status')) AS [Status],
				 recovery_model_desc AS [Recovery model],
				 ISNULL((SELECT TOP 1
				 CASE type WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction log' END + ' – ' +
				 LTRIM(ISNULL(STR(ABS(DATEDIFF(DAY, GETDATE(),backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
				 CONVERT(VARCHAR(20), backup_start_date, 101) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
				 CONVERT(VARCHAR(20), backup_finish_date, 101) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
				 ' (' + CAST(DATEDIFF(second, BK.backup_start_date,
				 BK.backup_finish_date) AS VARCHAR(4)) + ' '
				 + 'seconds)'
		 FROM msdb..backupset BK WHERE BK.database_name = DB.name ORDER BY backup_set_id DESC),'-') AS [Last backup],
			 CASE WHEN is_fulltext_enabled = 1 THEN 'Fulltext enabled' ELSE '' END AS [fulltext],
	
									CASE WHEN is_in_standby = 1 THEN 'standby' ELSE '' END AS [standby],
										CASE WHEN is_cleanly_shutdown = 1 THEN 'cleanly shutdown' ELSE '' END AS [cleanly shutdown]
		 FROM sys.databases DB
		 ORDER BY dbName, [Last backup] DESC, NAME

/****************************************************************************************************/

--Gets the last DBCC CheckDB on each database
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		CREATE TABLE #temp (
			   Id INT IDENTITY(1,1), 
			   ParentObject VARCHAR(255),
			   [Object] VARCHAR(255),
			   Field VARCHAR(255),
			   [Value] VARCHAR(255)
		)

		INSERT INTO #temp
				EXECUTE master.sys.sp_MSforeachdb'DBCC DBINFO ( ''?'') WITH TABLERESULTS'
		PRINT ' '
		PRINT ''
		PRINT ' '
		;WITH CHECKDB1 AS
		(
			SELECT [Value],ROW_NUMBER() OVER (ORDER BY Id) AS rn1 FROM #temp WHERE Field IN ('dbi_dbname'))
			,CHECKDB2 AS ( SELECT [Value], ROW_NUMBER() OVER (ORDER BY Id) AS rn2 FROM #temp WHERE Field IN ('dbi_dbccLastKnownGood')
		)      
		SELECT CHECKDB1.Value + ' - Date of Last Execution:  ' + CHECKDB2.Value AS 'DatabaseName - Date of last CheckDB in Next Column'
		FROM CHECKDB1 JOIN CHECKDB2
		ON rn1 =rn2

		DROP TABLE #temp


/****************************************************************************************************/

--Returns open transaction

			SELECT 'Open Transactions',
				[s_tst].[session_id],
				[s_es].[login_name] AS [Login Name],
				DB_NAME (s_tdt.database_id) AS [Database],
				[s_tdt].[database_transaction_begin_time] AS [Begin Time],
				[s_tdt].[database_transaction_log_bytes_used] AS [Log Bytes],
				[s_tdt].[database_transaction_log_bytes_reserved] AS [Log Rsvd],
				[s_est].text AS [Last T-SQL Text],
				[s_eqp].[query_plan] AS [Last Plan]
			FROM sys.dm_tran_database_transactions [s_tdt]
				INNER JOIN sys.dm_tran_session_transactions [s_tst]
					ON [s_tst].[transaction_id] = [s_tdt].[transaction_id]
				INNER JOIN sys.[dm_exec_sessions] [s_es]
					ON [s_es].[session_id] = [s_tst].[session_id]
				INNER JOIN sys.dm_exec_connections [s_ec]
					ON [s_ec].[session_id] = [s_tst].[session_id]
				LEFT OUTER JOIN sys.dm_exec_requests [s_er]
					ON [s_er].[session_id] = [s_tst].[session_id]
				CROSS APPLY sys.dm_exec_sql_text ([s_ec].[most_recent_sql_handle]) AS [s_est]
				OUTER APPLY sys.dm_exec_query_plan ([s_er].[plan_handle]) AS [s_eqp]
			ORDER BY
				[Begin Time] ASC;
			GO


/****************************************************************************************************/

--Returns information about custom error messages
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Custom Error messages'  AS 'Setting', * 
		FROM master.dbo.sysmessages
		WHERE Error > 50000

		IF @@Rowcount = 0
			BEGIN
				Select 'No custom messages were found' AS 'Status'
			END



/****************************************************************************************************/

--Get Operator information

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Operator Info'  AS 'Setting'
				, * 
		FROM msdb.dbo.sysoperators
		If @@Rowcount = 0
			BEGIN
				Select 'No Operators found' AS 'Status'
			END

/*********************************************************************************************/
--Mail Profile information

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC msdb.dbo.sysmail_help_configure_sp;

		EXEC msdb.dbo.sysmail_help_account_sp;
			If @@Rowcount = 0
				BEGIN
					Select 'No mail account found' AS 'Status'
				END
			
		EXEC msdb.dbo.sysmail_help_profile_sp;
			If @@Rowcount = 0
				BEGIN
					Select 'No mail profile found' AS 'Status'
				END
		EXEC msdb.dbo.sysmail_help_profileaccount_sp;
		EXEC msdb.dbo.sysmail_help_principalprofile_sp;

/****************************************************************************************************/

--Returns SQL Account security settings
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'SQL Account Settings'  AS 'Setting'
				, CONVERT(VARCHAR(50),name) AS 'Name'
				, is_policy_checked
				, is_expiration_checked
				, is_disabled
		FROM master.[sys].[sql_logins]

/****************************************************************************************************/

--Get server role members
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT sys.server_role_members.role_principal_id
				, CONVERT(VARCHAR(50),role.name) AS RoleName
				, sys.server_role_members.member_principal_id
				, member.name AS MemberName  
		FROM sys.server_role_members  
			JOIN sys.server_principals AS role  
				ON sys.server_role_members.role_principal_id = role.principal_id  
			JOIN sys.server_principals AS member  
				ON sys.server_role_members.member_principal_id = member.principal_id;

/****************************************************************************************************/

--Get server role, fixed and custom
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Server Roles' AS 'Setting'
				, CONVERT(VARCHAR(50),name) AS 'Name'
		FROM sys.server_principals 
		WHERE type = 'R' ;  

/****************************************************************************************************/

--Lists all the members of the server roles
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC master..sp_helpsrvrolemember


/****************************************************************************************************/

		--Returns the members of the Database roles for all databases
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @name sysname,@sql1 nvarchar(4000),@maxlen1 smallint,@maxlen2 smallint,@maxlen3 smallint



		CREATE TABLE #tmpTable 
		(
		 DBName sysname NOT NULL ,
		 UserName sysname NOT NULL,
		 RoleName sysname NOT NULL
		)

		DECLARE c1 CURSOR for 
		 SELECT name FROM master.sys.databases where state_desc <> 'Offline'

		OPEN c1
		FETCH c1 INTO @name
		WHILE @@FETCH_STATUS >= 0
		BEGIN
		 SELECT @sql1 = 
						 'INSERT INTO #tmpTable
						 SELECT N'''+ @name + ''', a.name, c.name
						 FROM [' + @name + '].sys.database_principals a 
						 JOIN [' + @name + '].sys.database_role_members b ON b.member_principal_id = a.principal_id
						 JOIN [' + @name + '].sys.database_principals c ON c.principal_id = b.role_principal_id
						 WHERE a.name != ''dbo'''
		 EXECUTE (@sql1)
		 FETCH c1 INTO @name
		END
		CLOSE c1
		DEALLOCATE c1

		SELECT @maxlen1 = (MAX(LEN(COALESCE(DBName, 'NULL'))) + 2)
		FROM #tmpTable

		SELECT @maxlen2 = (MAX(LEN(COALESCE(UserName, 'NULL'))) + 2)
		FROM #tmpTable

		SELECT @maxlen3 = (MAX(LEN(COALESCE(RoleName, 'NULL'))) + 2)
		FROM #tmpTable

		SET @sql1 = 'SELECT ''Database Role Members'', LEFT(DBName, ' + LTRIM(STR(@maxlen1)) + ') AS ''DB Name'', '
		SET @sql1 = @sql1 + 'LEFT(UserName, ' + LTRIM(STR(@maxlen2)) + ') AS ''User Name'', '
		SET @sql1 = @sql1 + 'LEFT(RoleName, ' + LTRIM(STR(@maxlen3)) + ') AS ''Role Name'' '
		SET @sql1 = @sql1 + 'FROM #tmpTable '
		SET @sql1 = @sql1 + 'ORDER BY DBName, UserName'
		EXEC(@sql1)

		DROP TABLE #tmpTable

/****************************************************************************************************/

--Returns all databases users
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @DB_USers TABLE
		(TypeOfAudit VARCHAR(50), DBName sysname, UserName sysname null, LoginType sysname, AssociatedRole varchar(max))
 
		INSERT @DB_USers
		EXEC sp_MSforeachdb
 
				'
				use [?]
				SELECT ''Database User Audit'',
					''?'' AS DB_Name,
				case prin.name when ''dbo'' then prin.name + '' (''+ (select SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
				prin.type_desc AS LoginType,
				isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole 
				FROM sys.database_principals prin
				LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
				WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
				prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'''
 
		SELECT
			  TypeOfAudit  AS 'Setting'
			, CONVERT(VARCHAR(50),DBName) AS 'DBName'
			, CONVERT(VARCHAR(50),UserName) AS 'User Name'
			, CONVERT(VARCHAR(50),LoginType) as 'Login Type'
			,
				STUFF(
				(
				SELECT ',' + CONVERT(VARCHAR(500),AssociatedRole)
		FROM @DB_USers user2
		WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName
 
		FOR XML PATH('')
		)
		,1,1,'') AS Permissions_user
		FROM @DB_USers user1
		GROUP BY TypeOfAudit, DBName,UserName ,LoginType 
		ORDER BY DBName,UserName


/****************************************************************************************************/

--Returns the server level permissions, other than Connect SQL
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Server Level Permissions'  AS 'Setting'
					, [srvprin].[name] [server_principal]
					, [srvprin].[type_desc] [principal_type]
					, [srvperm].[permission_name]
					, [srvperm].[state_desc]  
		FROM master.[sys].[server_permissions] srvperm 
				INNER JOIN master.[sys].[server_principals] srvprin 
						ON [srvperm].[grantee_principal_id] = [srvprin].[principal_id] 
		WHERE [srvprin].[type] IN ('S', 'U', 'G') 
				AND [srvperm].[permission_name] <> 'CONNECT SQL'
		ORDER BY [server_principal], [permission_name]


/****************************************************************************************************/

--Account Password Issues
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		 SELECT   'Password Audit'  AS 'Setting', l.name
						, l.create_date
						, l.modify_date
						,'Type 1'
		FROM master.sys.sql_logins l
		WHERE PWDCOMPARE(name,password_hash)=1
		UNION ALL
		SELECT    'Password Audit'  AS 'Setting', l.name
						, l.create_date
						, l.modify_date
						, 'Type 2'
		FROM master.sys.sql_logins l
		WHERE PWDCOMPARE('',password_hash)=1
		If @@Rowcount = 0
			BEGIN
				Select 'All SQL Pass the Password check' AS 'Status'
			END

/****************************************************************************************************/

--Gets credential Info
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Credential Info'  AS 'Setting'
				, Name
				, credential_identity  
		FROM master.sys.credentials
		IF @@Rowcount = 0
			BEGIN
				SELECT 'No Credentials found' AS 'Status'
			END

/****************************************************************************************************/

--SA account audit
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'SA Account Audit'  AS 'Setting', l.name
				, CASE WHEN l.name = 'sa' THEN 'NO' ELSE 'YES' END as Renamed
				, CASE WHEN s.is_policy_checked = 0 THEN 'NO' ELSE 'YES' END AS 'is_policy_checked'
				, CASE WHEN s.is_expiration_checked = 0 THEN 'NO' ELSE 'YES' END AS 'is_expiration_checked'
				, CASE WHEN  l.is_disabled = 0 THEN 'NO' ELSE 'YES' END AS 'is_disabled'
				, l.Modify_date
		FROM master.sys.server_principals AS l
			LEFT OUTER JOIN master.sys.sql_logins AS s ON s.principal_id = l.principal_id
		WHERE l.sid = 0x01

/****************************************************************************************************/

--Checks to see if any jobs are set to autodelete, copy the query that returns a record
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'AutoDeleteJobs'  AS 'Setting'
				, name
		FROM msdb.dbo.sysjobs
		WHERE delete_level > 0
		IF @@Rowcount = 0
			BEGIN
				SELECT 'No Auto Delete jobs found' AS 'Status'
			END

/****************************************************************************************************/

--Returns Proxy information and what jobs use them
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Proxy Info'  AS 'Setting'
				, p.proxy_id
				, p.name
				, p.credential_id
				, c.credential_identity
				, js.step_id
				, js.step_name
				, j.name  
		FROM msdb.dbo.sysproxies p
				INNER JOIN master.sys.credentials c 
					ON p.credential_id = c.credential_id
				LEFT OUTER JOIN msdb.dbo.sysjobsteps js 
					ON p.proxy_id = js.proxy_id
				LEFT OUTER JOIN msdb.dbo.sysjobs j 
					ON js.job_id = j.job_id
		IF @@Rowcount = 0
			BEGIN
				Select 'No Proxies Found' AS 'Status'
			END

/****************************************************************************************************/

--Returns Linked Server Information
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 
			 'LinkedServerInfo'  AS 'Setting',  a.name
			, a.product
			, a.data_source
			, a.modify_date
			, b.remote_name
			, b.uses_self_credential
			, c.name
			, c.default_database_name
		FROM master.sys.servers a
				LEFT OUTER JOIN master.sys.linked_logins b 
					ON b.server_id = a.server_id
				LEFT OUTER JOIN master.sys.server_principals c 
					ON c.principal_id = b.local_principal_id
		IF @@Rowcount = 0
			BEGIN
				Select 'No Linked Server Found' AS 'Status'
			END

/****************************************************************************************************/
--Returns Linked Server provider settings

		EXEC sp_MSset_oledb_prop


/****************************************************************************************************/
--Returns the provider each Linked server is using

		SELECT    'Linked Server Providers' AS 'Status'
				, srvname
				, providername 
		FROM sysservers


		IF @@Rowcount = 0
			BEGIN
				Select 'No linked servers found' AS 'Status'
			END

/****************************************************************************************************/

--Returns the count of how many linked servers are using each provider

		SELECT	 'Linked Server Provider Counts' AS 'Status'
				, providername
				, COUNT(*) AS 'NumberOfServers'
		FROM sysservers
		GROUP BY providername

		IF @@Rowcount = 0
			BEGIN
				Select 'No linked servers are using providers' AS 'Status'
			END

/****************************************************************************************************/

--Backup compressions server setting
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT  'Backup Compression Default is not set' AS 'Setting'
				, Value
		FROM [master].sys.configurations 
		WHERE Name = 'backup compression default'  
				AND Value = 0
		IF @@Rowcount = 0
			BEGIN
				Select 'Backup Compression Default is set' AS 'Status'
			END

/****************************************************************************************************/
--Gets Agent Job History retention settings
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		CREATE TABLE #JobHistoryInfo
			(ServerName NVARCHAR(128)
			, MaxRows INT
			, MaxPerJob INT)

		DECLARE @jobhistory_max_rows INT = Null
		DECLARE @jobhistory_max_rows_per_job INT = Null
		DECLARE @server VARCHAR(50)
  
		EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                        N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                        N'JobHistoryMaxRows',
                                         @jobhistory_max_rows  OUTPUT,
                                        N'no_output'

		EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                        N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                        N'JobHistoryMaxRowsPerJob',
                                         @jobhistory_max_rows_per_job  OUTPUT,
                                        N'no_output'

		SELECT @server = CONVERT(sysname, SERVERPROPERTY('servername'))

		INSERT INTO #JobHistoryInfo(ServerName, MaxRows, MaxPerJob) 
				VALUES ('Agent Job History Settings' , @jobhistory_max_rows, @jobhistory_max_rows_per_job)
			
		SELECT * FROM #JobHistoryInfo

		DROP TABLE #JobHistoryInfo
/****************************************************************************************************/

--Alert Information
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Alert Information'  AS 'Setting'
				, [name] AS [AlertName]
				, [event_source] AS [EventSource]
				, [message_id] AS [MessageID] 
				, [severity] AS [Enabled]
				, [has_notification] AS	[HasNotification]
				, [delay_between_responses] AS [DelayBetweenResponses]
				, [occurrence_count] AS [OccuranceCount] 
				, [last_occurrence_date] AS [LastOccuranceDate]
				, [last_occurrence_time] AS [LastOccuranceTime]
		FROM [msdb].[dbo].[sysalerts] ORDER BY AlertName



/****************************************************************************************************/

--Get Activity By Hour, past 8 weeks
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Activity by Hour'  AS 'Setting',
			   @@servername AS 'Server', 
			   a.database_name,
			   DATEPART(HOUR,a.backup_start_date) AS 'Hour',
			   convert(int,AVG(CASE WHEN charindex('Monday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End))  as 'Mon_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Tuesday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Tue_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Wednesday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Wed_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Thursday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Thu_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Friday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Fri_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Saturday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Sat_size(MB)',
			   convert(int,AVG(CASE WHEN charindex('Sunday',datename(weekday,a.backup_start_date)) > 0 then ceiling(a.backup_size/1000000.00) End)) as 'Sun_size(MB)'
			   ,MIN(a.backup_start_date ) as 'From:'
			   ,MAX(a.backup_start_date ) as 'To:'
			   ,COUNT(*)
		FROM msdb.dbo.backupset a (NOLOCK)
		WHERE a.type = 'L' --log backups
			AND a.backup_start_date 
				BETWEEN DATEADD(WEEK, DATEDIFF(WEEK,0,GETDATE())-8 ,0) AND GETDATE() --8 WEEKs back
		GROUP BY a.database_name, 
		  DATEPART(HOUR,a.backup_start_date)
		ORDER BY a.database_name, 
		  DATEPART(HOUR,a.backup_start_date)

		IF @@Rowcount = 0
			BEGIN
				Select 'No Transaction Log backups are taking place' AS 'Status'
			END


/****************************************************************************************************/
--Get Job owners

		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT        'Job Owner Information'  AS 'Setting'
					, a.name
					, CASE WHEN a.enabled = 1 
							THEN 'Enabled' ELSE 'Disabled' END AS 'JobStatus'
					, @@SERVERNAME AS 'ServerName'
					, SUSER_SNAME(a.owner_sid) AS 'Owner'
		FROM msdb.dbo.sysjobs a  




/****************************************************************************************************/


--Captures information regarding the server
--Only for SQL Server 2008 R2 or older
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion VARCHAR(100)
		DECLARE @SQLCPU NCHAR(1000)

		SELECT @SQLVersion = CONVERT(varchar(100),SERVERPROPERTY('productversion') )
		
		IF LEFT(@SQLVersion, 1) = 9 or LEFT(@SQLVersion, 2) = 10
			BEGIN
				SET @SQLCPU = 	'SELECT ''CPU and Memory Info''
											, cpu_count AS [Logical CPU Count]
											, hyperthread_ratio AS Hyperthread_Ratio
											, cpu_count/hyperthread_ratio AS Physical_CPU_Count
											, physical_memory_in_bytes/1048576 AS Physical_Memory_in_MB
											, virtual_memory_in_bytes/1048576 AS virtual_Memory_in_MB
								 FROM sys.dm_os_sys_info'
			END
		ELSE
			BEGIN
				 --SQL Server 2012 or greater
				 SET @SQLCPU = 'SELECT ''CPU and Memory Info''
											, cpu_count AS [Logical CPU Count]
											, hyperthread_ratio AS Hyperthread_Ratio
											, cpu_count/hyperthread_ratio AS Physical_CPU_Count
											, physical_memory_KB/1048576 AS Physical_Memory_in_MB
											, virtual_memory_KB/1048576 AS virtual_Memory_in_MB
								FROM sys.dm_os_sys_info'
			END

		EXEC(@SQLCPU)

/****************************************************************************************************/

 --Review configuration settings
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		Select 'Configuration Settings'  AS 'Setting'
					, CONVERT(VARCHAR(60), name) AS 'Name'
					, value
					, description
		FROM sys.configurations


/*****************************************************************************************************/
--Database Autocreate and AutoUpdate Statistics
			SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
			SELECT   'Stats Info for databases'  AS 'Setting'
				    , name, is_auto_create_stats_on AS [IsAutoCreateStatsOn]
				    , is_auto_update_stats_on AS [IsAutoUpdateStatsOn]
			FROM [master].sys.databases
			WHERE is_auto_create_stats_on = 0 
					OR is_auto_update_stats_on = 0
			If @@Rowcount = 0
				BEGIN
					Select 'Auto Statistics Settings check passed' AS 'Status'
				END

/****************************************************************************************************/

--Duration of backups
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT TOP 100
			 'Backup Duration and information'  AS 'Setting',
			 s.database_name,
			 m.physical_device_name,
			 CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB' AS bkSize,
			 CAST(DATEDIFF(second, s.backup_start_date,
			 s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,
			 s.backup_start_date,
			 s.backup_finish_date,
			 CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn,
			 CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn,
			 CASE s.[type]
			 WHEN 'D' THEN 'Full'
			 WHEN 'I' THEN 'Differential'
			 WHEN 'L' THEN 'Transaction Log'
			 END AS BackupType,
			 s.server_name,
			 s.recovery_model
		 FROM msdb.dbo.backupset s
			INNER JOIN msdb.dbo.backupmediafamily m ON s.media_set_id = m.media_set_id
		 ORDER BY backup_start_date DESC, backup_finish_date
		 GO

/****************************************************************************************************/

--Run only if requested, for each database
  --Find the most executed stored procedure(s).
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 	  'Most Executed Stored Procs'  AS 'Setting'
				 , CONVERT(VARCHAR(60),DB_NAME(SQTX.DBID)) AS [DBNAME] 
				 , CONVERT(VARCHAR(60),OBJECT_SCHEMA_NAME(SQTX.OBJECTID,DBID)) AS [SCHEMA]
				 , CONVERT(VARCHAR(60),OBJECT_NAME(SQTX.OBJECTID,DBID)) AS [STORED PROC]  
				 , MAX(CPLAN.USECOUNTS)  [EXEC COUNT]     
		FROM	 sys.dm_exec_cached_plans  CPLAN  
						CROSS APPLY sys.dm_exec_sql_text(CPLAN.PLAN_HANDLE) SQTX  
		WHERE	 DB_NAME(SQTX.DBID) IS NOT NULL AND CPLAN.OBJTYPE = 'PROC' 
		GROUP BY CPLAN.PLAN_HANDLE 
					,DB_NAME(SQTX.DBID) 
						,OBJECT_SCHEMA_NAME(OBJECTID,SQTX.DBID)  
							,OBJECT_NAME(OBJECTID,SQTX.DBID)  
		ORDER BY MAX(CPLAN.USECOUNTS) DESC 

/****************************************************************************************************/

--Jobs that have failed in past 5 Days
		SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT DISTINCT   b.server
						, a.name 'Job_Name' 
						, b.step_id 
						, ' Jobs run_status :'+ CONVERT(CHAR(2), b.run_status) +' ,' + b.message AS message
						, b.run_date,b.run_time
						, b.run_duration 
		 FROM msdb.dbo.sysjobs a 
			INNER JOIN msdb.dbo.sysjobhistory b 
				ON a.job_id = b.job_id 
			INNER JOIN msdb.dbo.sysjobsteps D 
				ON a.job_id = D.job_id 
		 WHERE b.run_status IN(1,0) 
			AND D.last_run_date <> 0 
				AND D.last_run_time <> 0 
					AND (message LIKE '%(10) without succeeding%' OR message LIKE '%failed%') 
						AND message NOT LIKE '%The step succeeded%' 
							AND b.instance_id IN ( SELECT MAX(instance_id) 
												   FROM msdb.dbo.sysjobhistory C 
												   WHERE C.job_id=a.job_id 
												   GROUP BY run_date, step_id ) 
								AND b.run_date >= CONVERT(CHAR(10),GETDATE()-5,112)
		 If @@Rowcount = 0
				BEGIN
					Select 'No Jobs have failed in past 5 days' AS 'Status'
				END
/****************************************************************************************************/

--Job Step Information
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Job Step Information'  AS 'Setting'
			, [sJOB].[name] AS [JobName]
			, [sJSTP].[step_name] AS [StepName]
			, CASE [sJSTP].[subsystem]
				WHEN 'ActiveScripting' THEN 'ActiveX Script'
				WHEN 'CmdExec' THEN 'Operating system (CmdExec)'
				WHEN 'PowerShell' THEN 'PowerShell'
				WHEN 'Distribution' THEN 'Replication Distributor'
				WHEN 'Merge' THEN 'Replication Merge'
				WHEN 'QueueReader' THEN 'Replication Queue Reader'
				WHEN 'Snapshot' THEN 'Replication Snapshot'
				WHEN 'LogReader' THEN 'Replication Transaction-Log Reader'
				WHEN 'ANALYSISCOMMAND' THEN 'SQL Server Analysis Services Command'
				WHEN 'ANALYSISQUERY' THEN 'SQL Server Analysis Services Query'
				WHEN 'SSIS' THEN 'SQL Server Integration Services Package'
				WHEN 'TSQL' THEN 'Transact-SQL script (T-SQL)'
				ELSE sJSTP.subsystem
			  END AS [StepType]
			, [sPROX].[name] AS [RunAs]
			, [sJSTP].[database_name] AS [Database]
			, CASE [sJSTP].[on_success_action]
				WHEN 1 THEN 'Quit the job reporting success'
				WHEN 2 THEN 'Quit the job reporting failure'
				WHEN 3 THEN 'Go to the next step'
				WHEN 4 THEN 'Go to Step: ' 
							+ QUOTENAME(CAST([sJSTP].[on_success_step_id] AS VARCHAR(3))) 
							+ ' ' 
							+ [sOSSTP].[step_name]
			  END AS [OnSuccessAction]
			, [sJSTP].[retry_attempts] AS [RetryAttempts]
			, [sJSTP].[retry_interval] AS [RetryInterval (Minutes)]
			, CASE [sJSTP].[on_fail_action]
				WHEN 1 THEN 'Quit the job reporting success'
				WHEN 2 THEN 'Quit the job reporting failure'
				WHEN 3 THEN 'Go to the next step'
				WHEN 4 THEN 'Go to Step: ' 
							+ QUOTENAME(CAST([sJSTP].[on_fail_step_id] AS VARCHAR(3))) 
							+ ' ' 
							+ [sOFSTP].[step_name]
			  END AS [OnFailureAction]
		FROM
			[msdb].[dbo].[sysjobsteps] AS [sJSTP]
			INNER JOIN [msdb].[dbo].[sysjobs] AS [sJOB]
				ON [sJSTP].[job_id] = [sJOB].[job_id]
			LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOSSTP]
				ON [sJSTP].[job_id] = [sOSSTP].[job_id]
				AND [sJSTP].[on_success_step_id] = [sOSSTP].[step_id]
			LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOFSTP]
				ON [sJSTP].[job_id] = [sOFSTP].[job_id]
				AND [sJSTP].[on_fail_step_id] = [sOFSTP].[step_id]
			LEFT JOIN [msdb].[dbo].[sysproxies] AS [sPROX]
				ON [sJSTP].[proxy_id] = [sPROX].[proxy_id]
		--ORDER BY [JobName], [StepNo]

/****************************************************************************************************/

--Find embedded email addresses in job steps
		PRINT ''
		PRINT ''
		PRINT ''
		USE [msdb]
		GO
		SELECT	'Email Addresses in Job Steps'  AS 'Setting',
			s.srvname,
			j.name,
			js.step_id,
			j.enabled 
		FROM	msdb.dbo.sysjobs j
		JOIN	msdb.dbo.sysjobsteps js
			ON	js.job_id = j.job_id 
		JOIN	master.dbo.sysservers s
			ON	s.srvid = j.originating_server_id
		WHERE	js.command LIKE N'%@%'


		If @@Rowcount = 0
			BEGIN
				Select 'No email address found in Job Steps' AS 'Status'
			END



/****************************************************************************************************/

--Finds any active transactions for the active database
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT 'Active Transactions'  AS 'Setting', * 
		FROM sys.dm_tran_session_transactions 




/****************************************************************************************************/

--Information regarding the max number of error log files
		PRINT ''
		PRINT ''
		PRINT ''
		USE master
		go
		DECLARE @HkeyLocal NVARCHAR(18)
		DECLARE @MSSqlServerRegPath NVARCHAR(31)
		DECLARE @InstanceRegPath SYSNAME

		SELECT @HkeyLocal=N'HKEY_LOCAL_MACHINE'
		SELECT @MSSqlServerRegPath=N'SOFTWARE\Microsoft\MSSQLServer'
		SELECT @InstanceRegPath=@MSSqlServerRegPath + N'\MSSQLServer'
		DECLARE @NumErrorLogs INT
		EXEC master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'NumErrorLogs', @NumErrorLogs OUTPUT
		SELECT 'Error File Number Configuration', ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles]

/****************************************************************************************************/

--Information about SSIS packages that are installed in the MSDB database
		PRINT ''
		PRINT ''
		PRINT ''
SET NOCOUNT ON
		;WITH ChildFolders
		AS
		(
			SELECT PARENT.parentfolderid
					, PARENT.folderid
					, PARENT.foldername
					, CAST('' AS sysname) AS RootFolder
					, CAST(PARENT.foldername AS VARCHAR(MAX)) AS FullPath
					, 0 AS Lvl
			FROM msdb.dbo.sysssispackagefolders PARENT
			WHERE PARENT.parentfolderid IS NULL
			UNION ALL
			SELECT CHILD.parentfolderid
					, CHILD.folderid
					, CHILD.foldername
					, CASE ChildFolders.Lvl
						WHEN 0 THEN CHILD.foldername
							ELSE ChildFolders.RootFolder
						END AS RootFolder
					, CAST(ChildFolders.FullPath + '/' + CHILD.foldername AS VARCHAR(MAX)) as FullPath
					, ChildFolders.Lvl + 1 AS Lvl
			FROM msdb.dbo.sysssispackagefolders CHILD
				INNER JOIN ChildFolders ON ChildFolders.folderid = CHILD.parentfolderid
		)
		SELECT 'SSIS package info'  AS 'Setting'
		 , F.RootFolder
		 , F.FullPath
		 , P.name as PackageName
		 , P.description as PackageDescription
		FROM ChildFolders F
			INNER JOIN msdb.dbo.sysssispackages P 
				ON P.folderid = F.folderid
		ORDER BY F.FullPath ASC
					, P.name ASC;
		If @@Rowcount = 0
			BEGIN
				Select 'No Maintenence Plans found' AS 'Status'
			END

/****************************************************************************************************/

--Returns information about Maintenence Plans on the server
SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @weekDay TABLE 
		(
			  mask      INT
			, maskValue VARCHAR(32)
		);

		INSERT INTO @weekDay
			SELECT 1, 'Sunday'  
				UNION ALL
			SELECT 2, 'Monday'  
				UNION ALL
			SELECT 4, 'Tuesday' 
				UNION ALL
			SELECT 8, 'Wednesday'  
				UNION ALL
			SELECT 16, 'Thursday'  
				UNION ALL
			SELECT 32, 'Friday'  
				UNION ALL
			SELECT 64, 'Saturday';

		WITH myCTE
		AS (
			SELECT	  sched.name AS 'scheduleName'
					, sched.schedule_id
					, jobsched.job_id
					, Case 
						WHEN sched.freq_type = 1 
							THEN 'Once' 
						WHEN sched.freq_type = 4 And sched.freq_interval = 1 
							THEN 'Daily'
						WHEN sched.freq_type = 4 
							THEN 'Every ' + CAST(sched.freq_interval AS VARCHAR(5)) + ' days'
						WHEN sched.freq_type = 8 
							THEN REPLACE( REPLACE( REPLACE(( 
								SELECT maskValue 
								FROM @weekDay As x 
								WHERE sched.freq_interval & x.mask <> 0 
								ORDER BY mask FOR XML RAW)
						, '"/><row maskValue="', ', '), '<row maskValue="', ''), '"/>', '') 
							+ CASE WHEN sched.freq_recurrence_factor <> 0 
								AND sched.freq_recurrence_factor = 1 
						THEN '; weekly' 
					WHEN sched.freq_recurrence_factor <> 0 
					THEN '; every ' 
					+ CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' weeks' 
				END
				WHEN sched.freq_type = 16 
					THEN 'On day ' 
					+ CAST(sched.freq_interval AS VARCHAR(10)) + ' of every '
					+ CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' months' 
				WHEN sched.freq_type = 32 
					THEN CASE 
					WHEN sched.freq_relative_interval = 1 
						THEN 'First'
					WHEN sched.freq_relative_interval = 2 
						THEN 'Second'
					WHEN sched.freq_relative_interval = 4 
						THEN 'Third'
					WHEN sched.freq_relative_interval = 8 
						THEN 'Fourth'
					WHEN sched.freq_relative_interval = 16 
						THEN 'Last'
			END + 
			CASE 
				WHEN sched.freq_interval = 1 
					THEN ' Sunday'
				WHEN sched.freq_interval = 2 
					THEN ' Monday'
				WHEN sched.freq_interval = 3 
					THEN ' Tuesday'
				WHEN sched.freq_interval = 4 
					THEN ' Wednesday'
				WHEN sched.freq_interval = 5 
					THEN ' Thursday'
				WHEN sched.freq_interval = 6 
					THEN ' Friday'
				WHEN sched.freq_interval = 7 
					THEN ' Saturday'
				WHEN sched.freq_interval = 8 
					THEN ' Day'
				WHEN sched.freq_interval = 9 
					THEN ' Weekday'
				WHEN sched.freq_interval = 10 
					THEN ' Weekend'
			END
			+ 
			CASE 
				WHEN sched.freq_recurrence_factor <> 0 
						AND sched.freq_recurrence_factor = 1 
					THEN '; monthly'
				WHEN sched.freq_recurrence_factor <> 0 
					THEN '; every ' 
			+ CAST(sched.freq_recurrence_factor AS VARCHAR(10)) + ' MONTHS' 
			END
			WHEN sched.freq_type = 64 
				THEN 'StartUp'
			WHEN sched.freq_type = 128 
				THEN 'Idle'
			 END AS 'frequency'
			, ISNULL('Every ' + CAST(sched.freq_subday_interval AS VARCHAR(10)) + 
			CASE 
				WHEN sched.freq_subday_type = 2 
					THEN ' seconds'
				WHEN sched.freq_subday_type = 4 
					THEN ' minutes'
				WHEN sched.freq_subday_type = 8 
					THEN ' hours'
			END, 'Once') AS 'subFrequency'
			, REPLICATE('0', 6 - LEN(sched.active_start_time)) 
				+ CAST(sched.active_start_time AS VARCHAR(6)) AS 'startTime'
			, REPLICATE('0', 6 - LEN(sched.active_end_time)) 
				+ CAST(sched.active_end_time AS VARCHAR(6)) AS 'endTime'
			, Replicate('0', 6 - Len(jobsched.next_run_time)) 
				+ CAST(jobsched.next_run_time AS VARCHAR(6)) AS 'nextRunTime'
			, CAST(jobsched.next_run_date AS CHAR(8)) AS 'nextRunDate'
			FROM msdb.dbo.sysschedules AS sched
				JOIN msdb.dbo.sysjobschedules AS jobsched
					ON sched.schedule_id = jobsched.schedule_id
		
		)
		SELECT DISTINCT 'Maintenence Plan Info'  AS 'Setting'
		, p.name AS 'Maintenance_Plan'
		, p.[owner] AS 'Plan_Owner'
		, sp.subplan_name AS 'Subplan_Name'
		, smpld.line3 AS 'Database_Names'
		, job.name AS 'Job_Name'
		, sched.frequency AS 'Schedule_Frequency'
		, sched.subFrequency AS 'Schedule_Subfrequency'
		, SUBSTRING(sched.startTime, 1, 2) + ':' 
			+ SUBSTRING(sched.startTime, 3, 2) + ' - ' 
			+ SUBSTRING(sched.endTime, 1, 2) + ':' 
			+ SUBSTRING(sched.endTime, 3, 2) 
			AS 'Schedule_Time' -- HH:MM
		, SUBSTRING(sched.nextRunDate, 1, 4) + '/' 
			+ SUBSTRING(sched.nextRunDate, 5, 2) + '/' 
			+ SUBSTRING(sched.nextRunDate, 7, 2) + ' ' 
			+ SUBSTRING(sched.nextRunTime, 1, 2) + ':' 
			+ SUBSTRING(sched.nextRunTime, 3, 2) 
			AS 'Next_Run_Date'
		FROM msdb.dbo.sysjobs AS job
			JOIN myCTE AS sched
				ON job.job_id = sched.job_id
			JOIN  msdb.dbo.sysmaintplan_subplans sp
				ON sp.job_id = job.job_id
			INNER JOIN msdb.dbo.sysmaintplan_plans p
				ON p.id = sp.plan_id
			JOIN msdb.dbo.sysjobschedules sjs
				ON job.job_id = sjs.job_id
			INNER JOIN msdb.dbo.sysschedules ss
				ON sjs.schedule_id = ss.schedule_id 
			JOIN msdb.dbo.sysmaintplan_log smpl
				ON p.id = smpl.plan_id 
					AND sp.subplan_id =smpl.subplan_id
			JOIN msdb.dbo.sysmaintplan_logdetail smpld
				ON smpl.task_detail_id=smpld.task_detail_id 

		ORDER BY Next_Run_Date;



/****************************************************************************************************/

--Get extended events information
SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion VARCHAR(100)

		SELECT @SQLVersion = CONVERT(varchar(100),SERVERPROPERTY('productversion') )
		
		IF LEFT(@SQLVersion, 1) <> 9
		BEGIN

				SELECT 'EE Sessions'  AS 'Setting', * FROM sys.dm_xe_sessions

					If @@Rowcount = 0
					BEGIN
						Select 'No Extended Events Sessions were found' AS 'Status'
					END

				SELECT 'EE targets'  AS 'Setting', * FROM sys.dm_xe_session_targets

					If @@Rowcount = 0
					BEGIN
						Select 'No Extended Events targets were found' AS 'Status'
					END

				SELECT 'EE Session Events'  AS 'Setting', * FROM sys.dm_xe_session_events

					If @@Rowcount = 0
					BEGIN
						Select 'No Extended Events Events were found' AS 'Status'
					END

				--SELECT 'EE Objects', * FROM sys.dm_xe_objects
				--	If @@Rowcount = 0
				--	BEGIN
				--		Select 'No Extended Events objects were found' AS 'Status'
				--	END
		END

/****************************************************************************************************/

--Returns information about SQL Audit
SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion1 VARCHAR(100)

		SELECT @SQLVersion1 = CONVERT(varchar(100),SERVERPROPERTY('productversion') )
		
		IF LEFT(@SQLVersion1, 1) <> 9
			BEGIN

				SELECT 'Server Audit Specifications'  AS 'Setting', * FROM master.sys.server_audit_specification_details
						If @@Rowcount = 0
						BEGIN
							Select 'No Server Audit Specifications were found' AS 'Status'
						END

				SELECT 'Server Audit', name,  type_desc, on_failure_desc FROM sys.server_audits
						If @@Rowcount = 0
						BEGIN
							Select 'No Server Audits were found' AS 'Status'
						END


				SELECT 'Database_audit_specification_details' AS 'Setting'
						, d.name
						, d.create_date
						, ad.audit_action_name
						, ad.major_id
				FROM sys.database_audit_specifications d
					INNER JOIN sys.database_audit_specification_details ad
						ON d.database_specification_id = ad.database_specification_id
					
					If @@Rowcount = 0
						BEGIN
							Select 'No Database Audit specifications were found' AS 'Status'
						END
			END

/****************************************************************************************************/

--Checks to see if AlwaysOn is enabled
SET NOCOUNT ON
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SQLVersion2 VARCHAR(100)

		SELECT @SQLVersion2 = CONVERT(VARCHAR(100),SERVERPROPERTY('productversion') )

			IF  LEFT(@SQLVersion2, 2) in (11, 12)
				BEGIN
					SELECT 'AlwaysOn Cluster Check'  AS 'Setting', * 
					FROM sys.dm_hadr_cluster
				END
			If @@Rowcount = 0
						BEGIN
							Select 'AlwaysOn is not enabled' AS 'Status'
						END

/****************************************************************************************************/

--Checks to see if the server is part of a cluster, if so returns Active and Passive Node names
		PRINT ''
		PRINT ''
		PRINT ''
		GO
		WITH ClusterActiveNode AS 
			(
					  SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS ClusterNodeName
					, Cast('Active' AS VARCHAR(10)) AS Active
					),
			ClusterNodes AS 
			(

						SELECT NodeName FROM sys.dm_os_cluster_nodes
			)

			SELECT @@ServerName 'Server or ClusterName'
					, b.NodeName AS 'ClusterNodeName'
					, ISNULL(Active,'Passive') AS NodeStatus 
			FROM ClusterNodes AS b 
					LEFT JOIN ClusterActiveNode AS a
			              ON a.ClusterNodeName = b.NodeName 

		 	If @@Rowcount = 0
						BEGIN
							SELECT 'Server is not part of Cluster' AS 'Status'
						END
/****************************************************************************************************/

--Checks to see if Reporting Services is installed
		PRINT ''
		PRINT ''
		PRINT ''
		DECLARE @SSRS BIT
		SELECT Name 
		FROM sys.databases 
		WHERE name LIKE 'ReportServer%'
	 	IF @@Rowcount > 0
						BEGIN
							SET @SSRS = 1
							SELECT 'Reporting Services is installed'   AS 'Status'
						END
		ELSE
						BEGIN
							SELECT 'Reporting Services is not installed or the database has been renamed' AS 'Status'
						END
		IF @SSRS = 1
				BEGIN
					 SELECT 'SSRS Subscription Jobs'  AS 'Setting'
							, name
							, description
					 FROM msdb.dbo.sysjobs
					 WHERE description LIKE 'This job is owned by a report server process%'
					 IF @@Rowcount > 0
						BEGIN
							SELECT 'Reporting Services Subsciption Jobs found' AS 'Status'
						END
				END
					
/****************************************************************************************************/
--Information about current SPIDS
		PRINT ''
		PRINT ''
		PRINT ''
		EXEC sp_who2

/****************************************************************************************************/

--Capture current performance counters
		PRINT ''
		PRINT ''
		PRINT ''
		SELECT * 
		FROM sys.dm_os_performance_counters 
		WHERE counter_name IN ('Page life expectancy', 'Lock Timeouts/sec', 'Number of Deadlocks/sec'
									, 'Log Growths', 'Active Transactions', 'Commit table entries'
									, 'Failed leaf page cookie', 'Failed leaf page cookie')


/****************************************************************************************************/

