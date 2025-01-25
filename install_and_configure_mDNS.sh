#!/bin/bash

echo "Updating the apt respository and system packages"
sudo apt update -y
sudo apt upgrade -y

sudo apt install net-tools -y
echo "Installing avahi-daemon package"
sudo apt install avahi-daemon -y

echo "Configuring intefaces to respond mDNS message"
interface_files=`ls /run/systemd/network`
for interface_file in "${interface_files[@]}"
do
        echo "Found $interface_file, Creating networkplan at $net_plan_file_path"

        net_plan_file_path="/etc/systemd/network/$interface_file.d"
        sudo mkdir $net_plan_file_path
        sudo bash -c "sudo printf '[Network]\nMulticastDNS=yes\n' >> $net_plan_file_path/override.conf"

done


echo "Configuring resolved.conf to respond mDNS messages"
sudo sed -i -e "s/#MulticastDNS=no/MulticastDNS=yes/g" /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved