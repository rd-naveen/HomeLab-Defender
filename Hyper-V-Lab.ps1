function Test-Hypervcapacity {
    #View disk space and Available RAM	
    $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1024 / 1024
    Write-Host "Total Ram Available $totalRam"

    Write-Host "available Disks and Spaces"
    Get-PSDrive | Where-Object -Property Name -Match "^\w$"
}

function Get-RandVMName {
    param (
        $category
    )
    $name_ = $category + "_" + (Get-Date).ToString("yyyyMMddhhmmss")
    return $name_
}


function Test-HypervFeatures {

    param (
        $feature_name
    )

    $hyperv = Get-WindowsOptionalFeature -FeatureName $feature_name -Online
    if ($hyperv.State -eq "Enabled") {
        Write-Host "$feature_name Feature enabled"
    }
    else {
        Write-Host "$feature_name Feature not enabled"
        Read-Host "press any keys to close this window" 
        Exit	
    }
}

function CreateAndConfigureVM {
    param (
        $VmName,
        $Category,
        $IsoFileLocation,
        $InterfaceCount,
        $RamSize,
        $StorageSize
    )
    # Define the iso file locations and VM files location
    $virtual_harddisk_location = "D:\VMs"
    
    # Define the interface and LAN names
    $corp_switch_name = "Corp LAN (internal)"
    $corp_interface_name = "Corp Interface"
    $default_switch_name = "Default Switch"
    $default_interface_name = "Default Interface"

    write-host "Creating "+ $VmName + "Virtual Machine"
    $vm_name = $VmName
    
    $virtual_hdd_loc = $virtual_harddisk_location+"\"+$vm_name
    
    mkdir $virtual_hdd_loc 

    New-VM -Name $vm_name -MemoryStartupBytes $RamSize -NewVHDPath $virtual_hdd_loc\$vm_name.vhdx -NewVHDSizeBytes $StorageSize  -Generation 2 

    write-host $VmName + ": Renaming default interface name"
    # #By default we'll have one network adapter, we are going to rename it and connect it to networks
    if ($vm_name -eq "Lab-Ubuntu-Sensor"){
        Rename-VMNetworkAdapter -VMName $vm_name -Name "Network Adapter" -NewName "Monitor"
        Connect-VMNetworkAdapter -VMName $vm_name -SwitchName $corp_switch_name -Name "Monitor"
        Set-VMNetworkAdapter -PortMirroring Destination -VMName $vm_name -Name "Monitor"
    }
    else{
        Rename-VMNetworkAdapter -VMName $vm_name -Name "Network Adapter" -NewName $corp_interface_name
        Connect-VMNetworkAdapter -VMName $vm_name -SwitchName $corp_switch_name -Name $corp_interface_name
        Set-VMNetworkAdapter -PortMirroring Source -VMName $vm_name -Name "Monitor"
    }
    
    
    if ( $InterfaceCount -eq "2"){
        write-host $VmName + ": Adding secondary interface "
         #creating internet facing interface and connect it to the default switch
         Add-VMNetworkAdapter -VMName $vm_name -Name $default_interface_name -SwitchName $default_switch_name
         Connect-VMNetworkAdapter -VMName $vm_name -switchname $default_switch_name -Name $default_interface_name
    }

    write-host $VmName + ": Attaching "+$IsoFileLocation
    Add-VMDvdDrive -VMName $vm_name -Path $IsoFileLocation

    Write-Host $VmName + ": Setting CPU count and Max Ram Size "
    Set-VM $vm_name -MemoryMaximumBytes $RamSize -ProcessorCount 2 -DynamicMemory
    $dvd = Get-VMDvdDrive -VMName $vm_name

    if ($category -eq "windows"){
            write-host $VmName + ": Enabling Secure Boot for "+ $Category
            #for windows based VMs we need to execute the below 3 commands, for linux, we just need to turn off the secureboot only. 
            Set-VMFirmware $vm_name -EnableSecureBoot on -FirstBootDevice $dvd

            Set-VMKeyProtector -VMName $vm_name -NewLocalKeyProtector
            Enable-VMTPM -VMName $vm_name
    }
    else{
        write-host $VmName + ": Disabling Secure Boot for "+ $Category
        Set-VMFirmware $vm_name -EnableSecureBoot Off -FirstBootDevice $dvd
    }
}

#check if hyper-v feature is enabled or not
Test-HypervFeatures -feature_name "Microsoft-Hyper-V-Management-PowerShell"
Test-HypervFeatures -feature_name "Microsoft-Hyper-V-All"

#check hyper-v device capacity
Test-Hypervcapacity

$corp_switch_name = "Corp LAN (internal)"

if ((Get-VMSwitch|Where-Object -Property Name  -Like $corp_switch_name).count){
    Write-Host $corp_switch_name+" Already available."
    Read-Host "please delete the old one and re-run the script"
    exit
}

#create a virtual network

New-VMSwitch -name $corp_switch_name -SwitchType Private
Enable-VMSwitchExtension -VMSwitchName $corp_switch_name -Name "Microsoft NDIS Capture"


#collect the iso images for VMs
$iso_image_dir = "E:\OS Images\"
$iso_files = Get-ChildItem $iso_image_dir | Where-Object -Property Extension -EQ .iso | Select-Object Extension, FullName, @{L = 'Length(Gbs)'; E = { [Math]::Round($_.Length / 1024 / 1024 / 1024, 2) } }
    
$win11_iso = ($iso_files | Where-Object -Property FullName -Match "CLIENTENTERPRISEEVAL").FullName
$ubuntu_iso = ($iso_files | Where-Object -Property FullName -Match "ubuntu").FullName
$winAd20xx_iso = ($iso_files | Where-Object -Property FullName -Match "SERVER_").FullName    
$kalilinux_iso = ($iso_files | Where-Object -Property FullName -Match "kali-linux").FullName

Write-Host $win11_iso
Write-Host $ubuntu_iso
Write-Host $winAd20xx_iso
Write-Host $kalilinux_iso

$gb_4 = 4*1024*1024*1024
$gb_80 = 80*1024*1024*1024

CreateAndConfigureVM -VmName "Lab-Win11"  -category "windows"  -IsoFileLocation $win11_iso   -InterfaceCount "2"  -RamSize $gb_4   -StorageSize $gb_80  
createandconfigurevm -vmname "Lab-AD20xx"  -category "windows"  -isofilelocation $winad20xx_iso   -interfacecount "2"  -ramsize $gb_4   -storagesize $gb_80  
createandconfigurevm -vmname "Lab-Kali-Linux"   -category "linux"   -isofilelocation $kalilinux_iso    -interfacecount "2"   -ramsize $gb_4    -storagesize $gb_80  
createandconfigurevm -vmname "Lab-Ubuntu-Sensor"  -category "linux"  -isofilelocation $ubuntu_iso   -interfacecount "2"  -ramsize $gb_4   -storagesize $gb_80 


# TODO:
    # [-] make the ubuntu server to listen all the traffic comming and going from all VMs, inside the Corp Lan network.
    # [-] Make a snapshot of all the VMs with basic configurations