<#
config file for backup-ftp.ps1
#>

$ftp_server = "ftp.server.name"
$ftp_username = "my_username"
$ftp_password = "my_passwort"
$ftp_folder = "/subfolder/on/server"
$local_mirror = "C:\local\folder"


$logpath = "$scriptpath\logs"
$logname = "backup-ftp"
$logdays = 21

$autoupdate = 1