<#

    description: Copies (sync) files from FTP server to local folder

    author: flo.alt@fa-netz.de
    https://github.com/floalt/Software-Deployment/tree/main/update-anything
    version: 0.61

#>



## getting script name & path and reading variables from config file:

    $scriptpath = (Split-Path -parent $PSCommandPath)
    #$scriptpath = "C:\scripts"
    $scriptsrc = "https://raw.githubusercontent.com/floalt/Backups-with-Powershell/master/backup-ftp.ps1"
    $scriptname = $MyInvocation.MyCommand.Name
    #$scriptname = "backup-ftp.ps1"
    $scriptfullpath = $scriptpath + "\" + $scriptname

    . $scriptpath\backup-ftp.config.ps1



## ---- functions ---- ##


function start-logfile {

    if (!(test-path $logpath)) {mkdir $logpath}
    $script:log_tempfile =  $logpath + "\" + $logname + "_log_tempfile" + ".log"
    $script:log_okfile = $logpath + "\" + $logname + "_ok" + ".log"
    $script:log_errorfile = $logpath + "\" + $logname + "_fail" + ".log"
    $script:log_today = $logpath + "\" + $logname + "-" + $(Get-Date -Format yyyyMMdd-HHmmss) + ".log"
    "Beginning: $(Get-Date -Format yyyy-MM-dd_HH:mm:ss)" >> $log_tempfile
}


function close-logfile {

    "End: $(Get-Date -Format yyyy-MM-dd_HH:mm:ss)" >> $log_tempfile
    if ($log_today) {cp $log_tempfile $log_today}
    if ($errorcount -eq 0) {
        mv $log_tempfile $log_okfile -Force
    } else {
        mv $log_tempfile $log_errorfile -Force
    }
}


function remove-logfiles {

    [int]$Daysback = "-" + $logdays

    $CurrentDate = Get-Date
    $DatetoDelete = $CurrentDate.AddDays($Daysback)
    Get-ChildItem $logpath | Where-Object { ($_.Extension -eq ".log") -and ($_.LastWriteTime -lt $DatetoDelete) } | Remove-Item
}


function errorcheck {

    if (!$errchk) {
        $yeah >> $log_tempfile
    } else {
        $shit >> $log_tempfile
        $script:errorcount = $script:errorcount + 1
    }

    $errchk = $null
}

function start-scriptupdate {

    if ($autoupdate -eq 1) {
        $yeah="OK: Self-Update of this script successful"
        $shit="FAIL: Self-Update of this script failed"
        Invoke-WebRequest -Uri $scriptsrc -OutFile $scriptfullpath -ErrorVariable errchk; errorcheck
    }
}



## ---- here is the script ---- ##

$errorcount = 0
$local_mirror_t = $local_mirror + "\this-month"
$local_mirror_l = $local_mirror + "\last-month"

start-logfile

# begin a new month

    if ((Get-Date).day -eq 2) {
        if (Test-Path $local_mirror_l) {Remove-Item -Path $local_mirror_l -Recurse -Force}
        Rename-Item $local_mirror_t $local_mirror_l
        mkdir $local_mirror_t
    }

# Module WinSCP is needed
    if (-not (Get-Module -Name WinSCP -ListAvailable)) {
        # Module is not installed, so install it in machine-wide context
        Install-Module -Name WinSCP -Scope AllUsers -Force
    }

    Import-Module WinSCP

# Create session
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::sftp
        HostName = $ftp_server
        UserName = $ftp_username
        Password = $ftp_password
        GiveUpSecurityAndAcceptAnySshHostKey = $true
    }

    $session = New-Object WinSCP.Session

try {
    # connect to FTP server
    $session.Open($sessionOptions)

    # create synchronization option object
    $synchronizationOptions = New-Object WinSCP.SynchronizationMode

    # do sync (remote -> local)
    $synchronizationResult = $session.SynchronizeDirectories(
        [WinSCP.SynchronizationMode]::Local,
        $local_mirror_t,
        $ftp_folder,
        $False, $False, [WinSCP.SynchronizationCriteria]::Time
    )

    # count files:
        $synchronizationResult.Downloads.FileName >> $log_tempfile
    "OK: Recieved $($synchronizationResult.Downloads.Count) files." >> $log_tempfile


    # close session
    $session.Dispose()

} catch {

    "ERROR: $($_.Exception.Message)" >> $log_tempfile
    $errorcount = 1

} finally {

    # close session if still open
    if ($session.SessionLogPath -ne $null) {
        $session.Dispose()
    }

    start-scriptupdate
    close-logfile
    remove-logfiles
}