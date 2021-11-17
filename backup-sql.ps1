<#
    description:
        Make full backup of Microsoft SQL Server

    author: flo.alt@fa-netz.de
    version: 0.91
#>


$sqlinstance = "MYSERVER\MSSQLSERVER"
$dbname = @(
    "database_one"
    "database_two"
    "database_three"
)



### script start here

$script:errorcount = 0

# get the backup destination path

$dbpath = (Get-SqlDatabase -ServerInstance $sqlinstance -Name $dbname[0]).PrimaryFilePath
$bakpath = $dbpath.replace("DATA","Backup")
echo "Last backup logfile:" > "$bakpath\last-backup.log"

foreach ($db in $dbname) {

    # delete old backup
    del $bakpath\$db-01.bak
    ren $bakpath\$db.bak $bakpath\$db-01.bak

    # perform the database backup

    $now = (Get-Date -Format dd.MM.yyy-HH:mm:ss)
    Backup-SqlDatabase -ServerInstance $sqlinstance -Database $db -BackupAction Database

    # check if error
    if ($? -eq "True") {
        echo "OK: $now - $db" >> "$bakpath\last-backup.log"
        }
    else {
        echo "FAIL: $now - $db" >> "$bakpath\last-backup.log"
        echo "FAIL: $now - $db" >> "$bakpath\last-failure.log"
        $script:errorcount++
        }
}

# check total errors:

if ($script:errorcount -eq 0) {
    $now = (Get-Date -Format dd.MM.yyy-HH:mm:ss)
    echo "$now - Backup of all Databases successfully finished" > "$bakpath\last-succesful.log"
    echo $dbname >> "$bakpath\last-succesful.log"
}
