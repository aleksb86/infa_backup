
Param (
    [string]$conf_path
)

<# Method loads config parameters from JSON file 
    to custom PS object #>
function Load-Conf($conf_path) {

    $json = New-Object psobject
    Add-Member -InputObject $json -MemberType NoteProperty -Name error -Value $null
    Add-Member -InputObject $json -MemberType NoteProperty -Name json_object -Value $null
    
    Try {
        [String] $json_str = Get-Content $conf_path -ErrorAction Stop
    } Catch {
        $json.error = "Error on reading config file! Details: $_."
    }
    
    Try {
        $json.json_object = ConvertFrom-Json $json_str -ErrorAction Stop
    } Catch {
        $json.error = "Error on converting from JSON config file to object! Details: $_."
    }
    
    return $json
}

<# Method for back up database  with given parameters #>
function Backup-Database($db_params) {
    
    #return $db_params.pass_file
    Try {
        # Get encrypted password string from given file:
        $enc_string = Get-content -Path $db_params.pass_file -ErrorAction Stop | ConvertTo-SecureString 
        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $db_params.user, $enc_string -ErrorAction Stop
        $pass = $cred.GetNetworkCredential().Password
        # Make a backup:
        Invoke-Sqlcmd -Username $db_params.user -Password $pass -InputFile $db_params.query_file -ErrorAction Stop -ServerInstance $db_params.instance
    } Catch {
        return $_
    }

    return 'Succeeded'
}

<# Fabric Method for create backup_resutl objects #>
function New-Backup_Result([String] $type, [String] $name, [String] $result) {
    $obj = New-Object psobject
    Add-Member -InputObject $obj -MemberType NoteProperty -Name type -Value $null
    Add-Member -InputObject $obj -MemberType NoteProperty -Name name -Value $null
    Add-Member -InputObject $obj -MemberType NoteProperty -Name result -Value $null
    Add-Member -InputObject $obj -MemberType NoteProperty -Name time -Value $null
    $obj.type = $type
    $obj.name = $name
    $obj.result = $result
    $obj.time = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
    return $obj
}


# main:

[String] $logfile = $null
$cwd = $PSScriptRoot
$conf = Load-Conf $conf_path
# List of backup objects results:
$backup_results = @()

Set-Location -Path $cwd

if ($conf.error -eq $null -and $conf.json_object -ne $null) {
    
    # Init log:
    $logfile = $conf.json_object.logfile
    $dt = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
    "INFO: start script. $dt" | Out-File $logfile
    
    # Backup database proccess:
    foreach ($db in $conf.json_object.dbs) {
        $dt = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
        $result = Backup-Database $db
        $name = $db.db_name
        if ($result -eq 'Succeeded') {
            "INFO: Back up database '$name' result: $result. $dt" | Out-File $logfile -Append
        } else {
            "ERROR: Back up database '$name' result: $result. $dt" | Out-File $logfile -Append
        }
            
        $backup_results += New-Backup_Result "database" $name $result
    }
    
    Set-Location -Path $cwd
    
    # Back up Infa domain:
    Try {
        $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
        $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

        # Check - is this process get started as 'Administrator'?
        if ($myWindowsPrincipal.IsInRole($adminRole)) {
            # This process started with Administrator privileges
            foreach ($dom in $conf.json_object.infa_domain) {
                $dt = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
                $result_d = Start-Process -FilePath $dom.script -Wait -PassThru -ErrorAction Stop
                $result = $result_d.ExitCode
                $status = if ($result_d.ExitCode -eq 0) { 'INFO:' } else {'ERROR:'}
                $name = $dom.name

                $backup_results += New-Backup_Result "domain" $name "Backing Up of Domain $name finished with Exit code = $result"
                "$status Backing Up of Domain $name finished with Exit code = $result. $dt" | Out-File $logfile -Append
            }
        } else {
            throw 'This Powershell process get started without Administrator privileges! ' 
                + 'Local Admin role needs to run script for back up Informatica domain.'
        }
        
    } Catch {
        $name = $dom.name
        $backup_results += New-Backup_Result "domain" $name "Error while backing up Domain $name. Details: $_"
        "ERROR: Error while backing up Domain $name. Details: $_ $dt" | Out-File $logfile -Append
    }    
    
    # Back up Infa repository (repositories):
    Try {
        foreach ($rep in $conf.json_object.infa_repository) {
            $result_r = Start-Process -FilePath $rep.script -Wait -PassThru -ErrorAction Stop
            
            $dt = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
            $name = $rep.name
            $result = $result_r.ExitCode
            $status = if ($result_r.ExitCode -eq 0) { 'INFO:' } else {'ERROR:'}

            $backup_results += New-Backup_Result "repository" $name "Backing Up of Repository $name finished with Exit code = $result"
            "$status Backing Up of Repository $name finished with Exit code = $result. $dt" | Out-File $logfile -Append
        }
    } Catch {
        $backup_results += New-Backup_Result "repository" $name "Error while backing up Repository $name. Details: $_"
        "$status Error while backing up Repository $name. Details: $_. $dt" | Out-File $logfile -Append
    }
    
    # Send mail with backing up results to admins:
    Try {
        $dt = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'
        $style = "<style>"
        $style = $style + "BODY{font-family: arial}"
        $style = $style + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
        $style = $style + "TH{border-width: 1px;padding: 1px;border-style: solid;border-color: black}"
        $style = $style + "TD{border-width: 1px;padding: 1px;border-style: solid;border-color: black;background-color:grey}"
        $style = $style + "</style>"
        $formatted = $backup_results | Select-Object type, name, result, time | ConvertTo-Html -Head $style | Out-String
        $fake_passwd = ConvertTo-SecureString -String 'password' -AsPlainText -Force
        $credential =  New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList 'fake_user', $fake_passwd
        
        Send-MailMessage -SmtpServer $conf.json_object.email.smtp `
            -Credential $credential `
            -From $conf.json_object.email.from `
            -To $conf.json_object.email.to `
            -Subject $conf.json_object.email.subject `
            -Body $formatted -BodyAsHtml -ErrorAction Stop
    } Catch {
        "ERROR: Send backup results email message failed! Details: $_. $dt" | Out-File $logfile -Append
    }
    
    "INFO: complete. $dt" | Out-File $logfile -Append

} else {
    $conf.error | Out-Host
    exit
}

