# sql-backup
Full SQL Database Dump

This script performs a FullBackup of the specified Microsoft SQL Databases.
<br>
  - The last Backup (from yesterday) is renamed to <backupname>-01.bak. The yesterday's backup is therefore deleted.
  - Then the new backup is going to be done in the default SQL-Database Backup Path.
  - the Backup Log File: last-backup.log (is being overwritten every time)
  - if a Backup fails: a line in last-failure.log ist added
  - if no Backup fails: last-succesful.log is createt
 <br>
 You can integrate that file(s) in your monitoring software.
 <br>

 ## Usage

 Edit these parameters at the beginning of the script:

 - `$sqlinstance`
 - `$dbname`

 Start the script with the cmd-file.
