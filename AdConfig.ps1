# - Get the system details: 
Get-ComputerInfo |Select-Object OsProductType,OsArchitecture,CsSystemFamily,CsNetworkAdapters, CsDomainRole, CsDomain

# Disk, RAM, OS installed Version, Build etc.
# - Rename the server

$os_name = (Get-ComputerInfo | Select-Object OsName)
$os_version = $os_name.OsName -replace "[^0-9]" , ''
$new_hostname = "WinSvr" + $os_version + "AD"
$current_hostname = hostname
if ($current_hostname -ne $new_hostname) {
Rename-Computer $new_hostname
Write-host "Need to restart the system, before continuing,"
exit
}
else {
Write-host "Hostnames are same, continuing"
}

#Set time zone: 
Write-host "use below command to find the timezone, default it will use the India Standard time"
#Get-TimeZone -ListAvailable 
Set-TimeZone -id "India Standard Time"

#install active directory roles
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
$domain_name="defender.local"
Install-ADDSForest -DomainName $domain_name -InstallDNS

# - Check how many interfaces are there
(Get-NetAdapter).count
$interfaces_ = Get-NetIPAddress | Where-Object -Property InterfaceAlias -match Ethernet* | Where-Object -Property AddressFamily -eq IPv4

# - decide which one is cop and which one is internet facing
# assuming, we have connected the WAN adapter to default swith ( and assigned IP address through DHCP)
$lan_interface = $interfaces_| Where-Object -Property SuffixOrigin -eq Link
$wan_interface = $interfaces_| Where-Object -Property SuffixOrigin -eq Dhcp
Write-host "Wan Interface Count "+$wan_interface.Count
Write-host "Lan Interface Count "+$lan_interface.Count

$choice=Read-Host "Do you want to swap: Y or N"	

if ($choice -eq "Y")
{
	$temp_ = $wan_interface
	$wan_interface = $lan_interface
	$lan_interface = $temp_
}



#join this machine to this AD
$domain_name="defender.local"


Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Import-Module ADDSDeployment
Install-ADDSForest -DomainName $domain_name -InstallDNS
# - install dns
Install-WindowsFeature -Name DNS -IncludeManagementTools
configure dns servers, 
# dns server name, 
# forwarders, 
	(Get-DnsServerForwarder).IPAddress.Count
	Add-DnsServerForwarder -IPAddress 8.8.8.8
	Add-DnsServerForwarder -IPAddress 1.1.1.1

	(Get-DnsServerForwarder).IPAddress
# set which interface it should listen

# - install dhcp
Install-WindowsFeature DHCP -IncludeManagementTools
$server_name = hostname
$dhcp_server_name = $server_name+"."+$domain_name

Add-DhcpServerv4Scope -Name "Corp LAN" -StartRange 10.10.10.100 -EndRange 10.10.10.200 -SubnetMask 255.255.255.0

# - install gateway to forward the local traffic to internet
# - Create dummy users with basic passwords
# - install CS
# - Create OUs and put some devices there
# - Create a GPO to change the background of the windows devices, at admin OU
# - Create admin and standard user groups.

# -Get system details
# 	- Installed features, 
# 	- Number of users, 
# 		Get-ComputerInfo |select OsNumberOfUsers
# 	- Number of active users, (if we don't see any one logging for the more than 7 days, notifiy admin)
# 	- Password hash analysis of existing users to detect weak passwords

