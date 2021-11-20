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
    if ($pc -eq "N" -or $pc -eq "n") { exit }
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

#region automatic configuration with vera crypt
echo ""
echo "(4) [optional] Applying VeraCrypt..."
if ($mode -eq 2) #user selected encrypted container as option
{
    echo "This script can create the encrypted VeraCrypt-Container for you."
    $pc = Read-Host "Create container with script? (y/n)"
    if ($pc -eq "Y" -or $pc -eq "y") { 
        #use vercrypt cli to create an encrypted container
        #first collect information
        echo "Provide path to VeraCrypt-Execurtables-Directory (e.g. C:\Program Files\VeraCrypt) containing the executable 'VeraCrypt Format.exe'"
        $vcDir = Read-Host "VeraCrypt directory"
        echo "Select encryption options"
        echo " Encryption algorithm"
        echo "  1. AES (recommended)"
        echo "  2. Serpent"
        echo "  3. Twofish"
        echo "  4. AES(Twofish)"
        echo "  5. AES(Twofish(Serpent))"
        echo "  6. Serpent(AES)"
        echo "  7. Serpent(Twofish(AES))"
        echo "  8. Twofish(Serpent)"
        $encalgorithmNum = Read-Host "(1/2/.../8)"
        echo " Hash algorithm"
        echo "  1. sha256"
        echo "  2. sha512 (recommended)"
        echo "  3. whirlpool"
        echo "  4. ripemd160 "
        $hashalgorithmNum = Read-Host "(1/2/3/4)"
        echo " Password"
        $psw1 = Read-Host 'Enter' -AsSecureString
        $psw2 = Read-Host 'Reenter' -AsSecureString
        #turn securestring into strings and compare values to make sure inputs match
        while ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($psw1)) -ne [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($psw2))) {
            #if not force reentering
            Write-Warning " Inputs do not match!"
            $psw1 = Read-Host 'Enter' -AsSecureString
            $psw2 = Read-Host 'Reenter' -AsSecureString
        }


        #collect remaining information from system/ turn numbers into valid parametes
            #max container size
        $maxsize = (Get-PSDrive $letter).Free
            #get encryption algorithm
        switch ($encalgorithmNum)                         
        {                        
            1 {$encalgorithm = "AES"}                        
            2 {$encalgorithm = "Serpent"}                        
            3 {$encalgorithm = "Twofish"}                        
            4 {$encalgorithm = "AES(Twofish)"}
            5 {$encalgorithm = "AES(Twofish(Serpent))"}    
            6 {$encalgorithm = "Serpent(AES)"}    
            7 {$encalgorithm = "Serpent(Twofish(AES))"}    
            8 {$encalgorithm = "Twofish(Serpent)"}                            
            Default {
                Write-Error "Invalid input! Encryption algorithm can only be a number from 1 to 8."
                exit
            }                        
        }
            #get hash algorithm
        switch ($hashalgorithmNum)                         
        {                        
            1 {$hashalgorithm = "sha256"}                        
            2 {$hashalgorithm = "sha512"}                        
            3 {$hashalgorithm = "whirlpool"}                        
            4 {$hashalgorithm = "ripemd160"}                          
            Default {
                Write-Error "Invalid input! Hash algorithm can only be a number from 1 to 4."
                exit
            }                        
        } 
            #get psw
        $psw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($psw1))

        #execute veracrypt
        cd $vcDir
        & '.\VeraCrypt Format.exe' /create "{letter}:\data.hc" /size $maxsize /password "${psw}" /hash $hashalgorithm /encryption $encalgorithm /filesystem ExFAT
        $psw = "ashbsidfghuighudfbzgzidfzbgtreu7btguirszn" #'hide' psw

        #mount new container
        $pc = Read-Host "Mount new container? (y/n)"
        if ($pc -eq "Y" -or $pc -eq "y") {
            #mount the container at the next free drive letter without showing veracrypt and open explorer
            & '.\VeraCrypt.exe' /q /v "{letter}:\data.hc" /p "${psw}" /hash $hashalgorithm /e
        }
    }
        else {
        #region final output
        echo ""
        echo "Successfully prepared disk $disknum ($letter) for VeraCrypt."
        echo ""
        echo "You may open VeraCrypt now!"
        echo ""
        Read-Host "[ENTER] to exit"
        exit
        #endregion
    }
}
elseif ($mode -eq 1) #user selected a partition to encrypt
{
    echo "Sorry, currently this script isn't able to encrypt a partition with VeraCrypt automatically."
    echo " If you provide the path to the VeraCrypt-Executables it can open the configuration assistant for you."

    $pc = Read-Host "Show instructions and open VerCrypt? (y/n)"
    if ($pc -eq "Y" -or $pc -eq "y") {
        echo "Provide path to VeraCrypt-Execurtables-Directory (e.g. C:\Program Files\VeraCrypt) containing the executable 'VeraCrypt Format.exe'"
        $vcDir = Read-Host "VeraCrypt directory"
        
        #write instructions
        Write-Host "Follow these instructions in the new window\r\n" +
            " 1. Select 'Encrypt a non-system partition/drive' and hit next.\r\n'" +
            " 2. Normally you want to use a 'Standard VeraCrypr Volume'. In some cases a hidden volume may be helpful. --> Next\r\n" +
            " 3. Hit 'Select Device...' and select the partition WITHOUT a drive letter on the drive you want to encrypt. Press 'OK' and 'Next'\r\n" +
            " 4. Select 'Create encrypted volume and format it' since the partition was just created by this script. --> Next\r\n" +
            " 5. Select your prefered algorithms. You can use AES and SHA-512 if you do not have any other preferences. --> Next\r\n" +
            " 6. Confirm that the shown information are correct and hit 'Next'\r\n" +
            " 7. Enter your secret. Keyfiles and PIM can optionally be used to enhance the security. --> Next\r\n"
            " 8. Select ExFAT or NTFS (NTFS if you plan to use the drive only with Microsoft's Windows) as filesystem. Move your mouse randomly over the window to generate better random numbers. Hit 'Format' when the bar is full."

        #open tool
        cd $vcDir
        & '.\VeraCrypt Format.exe'
    }
    else {
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
    }
}
#endregion

 #region final output
echo ""
echo "Successfully prepared disk $disknum ($letter) with VeraCrypt."
echo " Have fun and stay safe!"
echo ""
Read-Host "[ENTER] to exit"
exit
#endregion