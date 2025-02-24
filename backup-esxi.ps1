<#
description:

    Backup ESXi Host configuration
    upload to Nextcloud file drop share

#>



#### set the config ####

# ESXi Host config 
    $ipadress = "192.168.104.211"
    $esxiuser = "vmadmin"
    $esxipass = "VTL7Zj5aKzoyQJsC56"
    $backup_path = "c:\esxibackup"

# Nextcloud Upload
    
    $NextcloudUrl = "https://cloud.fa-netz.de/remote.php/dav/files/uploader/Shared-to-me/ESXi-Host"
    $Username = "uploader"
    $Password = "thisisverysecret"

#### functions ####

function errorcheck {

    if (!$errchk) {
        write-host $yeah -F Green
    } else {
        write-host $shit -F Red
        $script:errorcount++
    }

    $errchk = $null
}





#### and here is the script ####

$script:errorcount = 0


## ESXi config Backup

    # connect
    Connect-VIServer -Server $ipadress -User $esxiuser -Password $esxipass -SaveCredentials

    # backup
        $yeah = "OK: Backup successfully done"
        $shit = "ERROR: Backup failed"
    $backup_done = Get-VMHostFirmware -VMHost $ipadress -BackupConfiguration -DestinationPath $backup_path -ErrorVariable errchk; errorcheck
    
    # disconnect
    Disconnect-VIServer -Confirm:$False

## Manage backup files

    # rename
    $new_backup = (($backup_done.Data).BaseName + "-" + (Get-Date -Format yyyyMMdd) + ".tgz")
    Rename-Item $backup_done.Data $new_backup

    # keep old backups (keep last 3)
    $files_to_delete = Get-ChildItem $backup_path | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3
    foreach ($file in $files_to_delete) {Remove-Item $file.FullName -Force}

## Upload to Nextcloud

    # Enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # preparing
    $Item = Get-Item $backup_path\$new_backup
    $Creds = ConvertTo-SecureString "$Username`:$Password" -AsPlainText -Force
    $Headers = @{
        Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))
    }
    $webdav = "$($NextcloudUrl)/$($Item.Name)"
    
    #upload
        $yeah = "OK: Upload to Nextcloud"
        $shit = "ERROR: Upload failed"
    Invoke-RestMethod -Uri $webdav -InFile $Item.Fullname -Headers $Headers -Method Put -ErrorVariable errchk; errorcheck

## Monitoring

    if ($script:errorcount -eq 0) {
        Get-Date -Format yyyy-MM-dd_HH-mm-ss > $backup_path\last_successful.txt
    }
