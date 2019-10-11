# sql-backup
Full SQL Database Dump

This script makes a FullBackup of a specified Microsoft SQL Database.
<br>
  - The last Backup (from yesterday) is renamed to <backupname>-01.bak. The yesterday's backup is therefore deleted.
  - Then the new backup is going to be done in the default SQL-Database Backup Path.
  - If the Backup runs without an error: file `succesful.txt` is being created
  - If the Backup fails: file `error.txt` is beeing created
 <br>
 You can integrate these two file in your monitoring software.
 <br>
 
 ## Usage
 
 Edit these parameters at the beginning of the script:
 
 - `$sqlinstance`
 - `$dbname`
 
 Start the script with the cmd-file.
