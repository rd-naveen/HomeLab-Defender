# HomeLab-Defender

## HomeLab-Defender\install_and_configure_mDNS.sh
** This script will install the Avahi dameon for providing mDns capabilities and resolutions for the devices.


## HomeLab-Defender\Hyper-V-Lab.ps1
** This script will do the following checks and perform actions
1. Check if Hyper-v features are installed in the windows system or not
2. Show the available RAM and Disk spaces to use
3. Create a new private virtual hyper-v switch (Corp LAN) and enable NIDS features
4. Image (ISO) files will be automatically recognized from the given directory(string match)
    NOTE: Files need to be downloaded separtely, 
5. Create new Virtual machines with Custom Name, RAM Size (start, max), Dynamic RAM allocation, Create 2 interfaces, and other settings. 
    NOTE:  By DEFAULT it will create 4 new virtual machiens (Ubuntu, Kali, windows11, and AD 20xx), but can be modified to create more or less number of VMs
6. Enable Secure Boot and TPM for windows based machiens, and disable them for linux based machines
7. Enabled Port mirroring for devices (source) connected to the Corp LAN, and Set the ubuntu-sensor as a destination port. [Not Tested Yet]

Completed Items:
[X] Suricata
[X] Install zeek
[X] Apache2 WebServer
[X] Install mod security
[X] Email Server (listmon)
[x] Install Opensearch with security analytics

TODO:
[ ] Bash script to configure the below on ubuntu-server
    [ ] Configure Self signed SSL certificate in Apache2 Server
    [ ] Configure Virtual Host in Apache2 Server
        [ ] Configure SSL certificate for each virtual hosts
        [ ] Host wiki software in the virtual host in the same port.
    [ ] Wauzh Servers (XDR)
    [ ] FreeNas/OpenNAS solution


[ ] Secure the Ubuntu_sensor


[ ] Powershell script to configure the below
    [ ] Windows Ad, CS, DNS, DHCP @Active directory Server
    [ ] Network Gateway (to forward traffic from local network to internet)
    [ ] Network Authentication

[ ] Create a another network between AD internet adapter and Firewall Device, 
    [ ] Sophs home firewall
    

[ ] Windows 11 System
    [ ] Install sysmon
    [ ] WDAC
    [ ] forwards system events to opensearch
     