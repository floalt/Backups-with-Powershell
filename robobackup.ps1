<#
    description:
        Backup a whole folder via robocopy to a smb share

    author: flo.alt@fa-netz.de
    version: 0.1

#>


$backup_from = "path/to/folder"
$backup_to = "path/to/folder"

$exclude_dir = @(
    '"path/to/exclude"'
    '"another/path/to/exclude"'
)


$smb_lw = "T:"
$smb_share = "\\server\share"
$smb_user = "DOMAIN\user"
$smb_pass = "mysecretpassword"


$logpath = "path/to/logfolder"
$logname = "robobackup"
$logdays = "10"     # number of days to keep logfiles


# ------------------------- FUNCTIONS ------------------------- #


function errorcheck {

    <#
    usage:
        $yeah = "OK: everything went allright"
        $shit = "ERROR: this didnt work"
        [do someting complicated]; errorcheck
    #>

    if ($?) {
        $yeah >> $log_tempfile
    } else {
        $shit >> $log_tempfile
        $script:errorcount = $script:errorcount + 1
    }
}


function failcheck {

    if ($?) {
        $yeah >> $log_tempfile
    } else {
        $shit >> $log_tempfile
        $script:errorcount = $script:errorcount + 1
        "FAIL: This is a fatal error. It is better to stop here!" >> $log_tempfile
        
        fail-rollback
        end-logfile
        exit 1
    }
}


function start-logfile {

    <#
    starting a logifile in a central $logpath
    if no errors, you get $log_okfile, otherwise $log_errorfile
    #>

    if (!(test-path $logpath)) {mkdir $logpath}
    $script:log_tempfile =  $logpath + "\" + $logname + "_log_tempfile" + ".log"
    $script:log_okfile = $logpath + "\" + "lastbackup" + "_ok" + ".log"
    $script:log_errorfile = $logpath + "\" + "lastbackup" + "_fail" + ".log"
    $script:log_today = $logpath + "\" + $logname + "-" + $(Get-Date -Format yyyyMMdd-HHmmss) + ".log"
    $script:log_robocopy = $logpath + "\" + "robocopy-" + $(Get-Date -Format yyyyMMdd-HHmmss) + ".log"
    "Beginning: $(Get-Date -Format yyyy-MM-dd_HH:mm:ss)" >> $log_tempfile
}



function end-logfile {

    <#
    finnishing logfile
    if no errors, you get $log_okfile, otherwise $log_errorfile
    #>

    "End: $(Get-Date -Format yyyy-MM-dd_HH:mm:ss)" >> $log_tempfile
    if ($log_today) {cp $log_tempfile $log_today}
    if ($errorcount -eq 0) {
        mv $log_tempfile $log_okfile -Force
    } else {
        mv $log_tempfile $log_errorfile -Force
    }
}


function connect-smb {

    if (!(test-path $backup_to)) {
        $yeah = "OK: SMB share connected"
        $shit = "FAIL: Cannot connect to SMB Share"
        net use $smb_lw $smb_share /user:$smb_user $smb_pass; failcheck
    }
}


function disconnect-smb {

    $yeah = "OK: SMB share disconnected"
    $shit = "ERROR: Cannot disconnect SMB share"
    if (test-path $smb_lw) {net use $smb_lw /delete /yes; errorcheck}
}


function fail-rollback {disconnect-smb}


function del-logfiles {

    [int]$Daysback = "-" + $logdays

    $CurrentDate = Get-Date
    $DatetoDelete = $CurrentDate.AddDays($Daysback)
    Get-ChildItem $logpath | Where-Object { ($_.Extension -eq ".log") -and ($_.LastWriteTime -lt $DatetoDelete) } | Remove-Item

}

# ----------------------- END FUNCTIONS ----------------------- #


## first steps

    $errorcount = 0
    start-logfile
    connect-smb


## do the backup

    $xd = [string]$exclude_dir

    robocopy $backup_from $backup_to /mir /xd $xd /r:0 /w:0 /tee /log:$log_robocopy /np /nfl /ns /nc /ndl
    
    if ($LASTEXITCODE -lt 9) {
        "OK: Robocopy Backup finished successfully" >> $log_tempfile
        "INFO: Robocopy Exit Code: $LASTEXITCODE" >> $log_tempfile
    } else {
        "ERROR: Robocopy Backup finished with one or more errors." >> $log_tempfile
        "ERROR: Robocopy Exit Code: $LASTEXITCODE." >> $log_tempfile
        "INFO: Please check $log_robocopy for more information." >> $log_tempfile
        $script:errorcount = $script:errorcount + 1
    }



## last steps
    
    disconnect-smb
    end-logfile
    del-logfiles
