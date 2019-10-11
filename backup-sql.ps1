# Backup einer SQL-Datenbank
# author flo.alt@fa-netz.de
# ver 0.8

param(
$sqlinstance = "<servername\sql-instance>",
$dbname = "<name of the database>"
)

$dbpath = (Get-SqlDatabase -ServerInstance SERV-APP\SQLEXPRESSTIDE -Name TIDE).PrimaryFilePath
$bakpath = $dbpath.replace("DATA","Backup")

del $bakpath\$dbname-01.bak
ren $bakpath\$dbname.bak $bakpath\$dbname-01.bak

Backup-SqlDatabase -ServerInstance $sqlinstance -Database $dbname -BackupAction Database

if ($? -eq "True") {
    echo "Last sucessful backup:" (Get-Date -Format dd.MM.yyy-hh:mm:ss) > "$bakpath\succesful.txt"
    }
else {
    echo "Last failure backup:" (Get-Date -Format dd.MM.yyy-hh:mm:ss) > "$bakpath\error.txt"
    }
