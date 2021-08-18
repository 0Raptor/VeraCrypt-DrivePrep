#region preperation
#abort further execution on error
$ErrorActionPreference = "Stop"
#make sure the script was executed as admin
if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
            #flatten to single array
            '-File', $MyInvocation.MyCommand.Source, $args `
            | %{ $_ }
        ) `
        -Verb RunAs
    exit
}
$wd = $MyInvocation.MyCommand.Path
$wd = Split-Path $wd -Parent
#endregion

#region request user selections
cls
echo "USB-Drive-Encryption Preparation"
echo ""
#list all connected disks, so user can enter proper number
Get-Disk | Format-Table -Property Number, FriendlyName, Size, OperationalStatus
echo ""
echo "Select disk that will be used for encryption"
$disknum = Read-Host "Enter number of disk to repartition" #get disk to use
echo "Preselect VeraCrypt-Methode"
echo " - for additional information visit https://www.veracrypt.fr"
echo "  1. Create encrypted partition (recommended)"
echo "  2. Create encrypted container [an file that will be mounted as drive] (more simple)"
$mode = Read-Host "(1/2)" #how to prepare
echo "Select a drive letter where the new volume will be mounted. This letter MUST NOT be in use!"
$letter = Read-Host "Select unused drive letter" #where to mount
#endregion

#region delete partition(s)
echo ""
echo "(1) Removing old partitions..."
try {
    $oldps = Get-Partition -DiskNumber $disknum
} catch {
    echo "Unable to locate paritions on selected disks."
    $pc = Read-Host "Proceed? (y/n)"
    if ($pc -eq "N" -or $pc -eq "N") { exit }
}
foreach ($p in $oldps) {
	Remove-Partition -InputObject $p
}
#endregion

#region create new partition(s)
echo ""
echo "(2) Creating new partition(s) and filesystem(s)..."
if ($mode -eq 1) {
#region for encrypted partition
	New-Partition -DiskNumber $disknum -Size 68MB -DriveLetter $letter | Format-Volume -FileSystem FAT32
	New-Partition -DiskNumber $disknum -UseMaximumSize
#endregion
}
elseif ($mode -eq 2)
{
#region for encrypted container
	New-Partition -DiskNumber $disknum -UseMaximumSize -DriveLetter $letter | Format-Volume -FileSystem exFAT
#endregion
}
else {
	echo "Invalid method prelected!"
	Read-Host "[ENTER] to exit"
	exit
}
#endregion

#region copy files to new partition
echo ""
echo "(3) Copying installers..."
Expand-Archive -LiteralPath "${wd}\export\VeraCrypt-1.24-Installer.zip" -DestinationPath "${letter}:\"
if ($mode -eq 1) {
	Copy-Item "${wd}\export\README-Partitions.txt" "${letter}:\README.txt"
}
elseif ($mode -eq 2)
{
	Copy-Item "${wd}\export\README-File.txt" "${letter}:\README.txt"
}
#endregion

#region final output
echo ""
echo "Successfully prepared disk $disknum ($letter) for VeraCrypt."
echo " Keep in mind to use the SECOND partition when creating an entire encrypted partition."
echo "  -> The name may differ inside VeraCrypt - do not use the partition with an drive-letter"
echo ""
echo "You may open VeraCrypt now!"
echo ""
Read-Host "[ENTER] to exit"
exit
#endregion