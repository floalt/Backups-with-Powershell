# Backup einer SQL-Datenbank
# author flo.alt@fa-netz.de
# ver 0.81

### setup your parameters here:

param(
$sqlinstance = "<servername\sql-instance>",
$dbname = "<name of the database>"
)

### script start here

# get the backup destination path
$dbpath = (Get-SqlDatabase -ServerInstance $sqlinstance -Name $dbname).PrimaryFilePath
$bakpath = $dbpath.replace("DATA","Backup")

# delete old backup
del $bakpath\$dbname-01.bak
ren $bakpath\$dbname.bak $bakpath\$dbname-01.bak

# perform the database backup
Backup-SqlDatabase -ServerInstance $sqlinstance -Database $dbname -BackupAction Database

# check if error
if ($? -eq "True") {
    echo "Last backup succesful:" (Get-Date -Format dd.MM.yyy-HH:mm:ss) > "$bakpath\succesful.txt"
    }
else {
    echo "Last backup fails:" (Get-Date -Format dd.MM.yyy-HH:mm:ss) > "$bakpath\error.txt"
    }
