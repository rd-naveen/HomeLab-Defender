#!/bin/bash
monitoring_interface="eth1"
servername=`hostname`
read -p "Enter fullname: "  user_password_opensearch

echo "Set the sudo root password"
sudo passwd root
echo "Password for the root account is set"

echo "[+]Updating the apt respository and system packages"
sudo apt update -y
sudo apt upgrade -y

echo "[Apache2] Installing Apache2 (Web Server)" 
sudo apt install apache2 apache2-utils -y
sudo apt install jq -y

# -------///-------

echo "[ModSecurity] Installing ModSecurity WAF" 
sudo apt install libapache2-mod-security2 -y
sudo a2enmod security2
sudo systemctl restart apache2
# test the running status
# sudo systemctl status apache2

echo "[ModSecurity] Configuring Mod Security"

sudo mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
# SecRuleEngine On  // we already have DetectionOnly -> don't block only record/log
sudo sed -i -e "s/SecRuleEngine DetectionOnly/SecRuleEngine On/g" /etc/modsecurity/modsecurity.conf
sudo sed -i -e "s/SecAuditLogParts ABDEFHIJZ/SecAuditLogParts ABCEFHJKZ/g" /etc/modsecurity/modsecurity.conf
sudo systemctl restart apache2

echo "[ModSecurity] Install the OWASP Core Rule Set"

# please check for the latest version
wget https://github.com/coreruleset/coreruleset/releases/download/v4.10.0/coreruleset-4.10.0-minimal.tar.gz
tar xvf coreruleset-*
sudo mkdir /etc/apache2/modsecurity-crs/
sudo mv coreruleset-4.10.0/ /etc/apache2/modsecurity-crs

sudo sed -i '/<\/IfModule>/i \
    IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-4.10.0/crs-setup.conf \
    IncludeOptional /etc/apache2/modsecurity-crs/coreruleset-4.10.0/rules/*.conf' /etc/apache2/mods-enabled/security2.conf

# and disable below two lines
sudo sed -i -e "s/IncludeOptional \/usr\/share\/modsecurity-crs/#IncludeOptional \/usr\/share\/modsecurity-crs/g" /etc/apache2/mods-enabled/security2.conf
sudo sed -i -e "s/IncludeOptional \/etc\/modsecurity\//#IncludeOptional \/etc\/modsecurity\//g" /etc/apache2/mods-enabled/security2.conf

sudo systemctl restart apache2

# Testing 
curl http://localhost/index.html?exec=/bin/bash  | grep "403 Forbidden"

echo "[ModSecurity] Installation finsihed" 


# -------///-------

echo "[Suricata] Installation Started"
sudo add-apt-repository ppa:oisf/suricata-stable
sudo apt install suricata -y
sudo service suricata start

echo "[Suricata] Suricata first time setup"
sudo sed -i -e "s/community-id: false/community-id: true/g" /etc/suricata/suricata.yaml
sudo sed -i -e "s/- interface: eth0/- interface: $monitoring_interface/g" /etc/suricata/suricata.yaml
sudo sed -i -e "s/- rule-reload: true/- rule-reload: true/g" /etc/suricata/suricata.yaml
sudo bash -c "sudo printf '\ndetect-engine:\n  - rule-reload: true\n' >> /etc/suricata/suricata.yaml"


echo "[Suricata] Updating suricata rules"
sudo suricata-update

echo "[Suricata] Enabling free rules"
free_sources=(
"abuse.ch/feodotracker"
"abuse.ch/sslbl-blacklist"
"abuse.ch/sslbl-c2"
"abuse.ch/sslbl-ja3"
"abuse.ch/urlhaus"
"aleksibovellan/nmap"
"et/open"
"etnetera/aggressive"
"oisf/trafficid"
"pawpatrules"
"stamus/lateral"
"tgreen/hunting"
)
for i in "${free_sources[@]}"; do
    echo "[Suricata] Enabling rules from $i"
    sudo suricata-update enable-source $i
done


echo "[Suricata] Validating suricata configuration"
sudo suricata -T -c /etc/suricata/suricata.yaml -v

echo "[Suricata] Restarting suricata service"
sudo service suricata restart

# TODO
# echo "[+] Testing suricata rules"
# curl http://testmynids.org/uid/index.html


# Output
# uid=0(root) gid=0(root) groups=0(root)

# view the logs
# grep 2100498 /var/log/suricata/fast.log

# or
# jq 'select(.alert .signature_id==2100498)' /var/log/suricata/eve.json


echo "[Suricata] Installation finished"

# -------///-------

echo "[listmonk] Installation started for Mail server"

echo "[postgresql] Installing started"

sudo apt install postgresql postgresql-contrib -y

echo "[postgresql] Installation finished"

echo "[listmonk] Configuring postgres database"
sudo -u postgres  psql -c "create database listmonk"
sudo -u postgres  psql -c "create user listmonk with encrypted password 'listmonk0101'"
sudo -u postgres  psql -c "grant all privileges on database listmonk to listmonk"
sudo -u postgres  psql -c "grant all on SCHEMA  public to listmonk"
sudo -u postgres  psql -c "ALTER DATABASE listmonk OWNER TO listmonk"

echo "[listmonk] Installing Listmonk"
echo "[listmonk] Downloading binary files from github"
wget https://github.com/knadh/listmonk/releases/download/v4.1.0/listmonk_4.1.0_linux_amd64.tar.gz
tar -zxvf listmonk_*
./listmonk --new-config

echo "[listmonk] Configuring Listmonk"
sed -i -e "s/address = \"localhost:9000\"/address = \"0.0.0.0:8080\"/g" config.toml
sed -i -e "s/password = \"listmonk\"/password = \"listmonk0101\"/g" config.toml

./listmonk --install

sudo mkdir /etc/listmonk/
sudo mv config.toml /etc/listmonk/
sudo mv listmonk /usr/bin/

echo "[listmonk] Downloading basic service configuration file"
wget https://raw.githubusercontent.com/knadh/listmonk/refs/heads/master/listmonk%40.service -O listmonk.service
sudo mv listmonk.service /etc/systemd/system/listmonk.service

sudo sed -i -e "s/\/etc\/listmonk\/%i.toml/\/etc\/listmonk\/config.toml/g" /etc/systemd/system/listmonk.service
sudo sed -i -e "s/SystemCallFilter=/# SystemCallFilter=/g" /etc/systemd/system/listmonk.service

sudo systemctl daemon-reload
sudo systemctl enable listmonk.service
sudo systemctl start listmonk.service
sudo systemctl status listmonk.service

echo "[listmonk] Installation finished"

# -------///-------

echo "[Zeek] Installation Started finished"
sudo apt-get install cmake make gcc g++ flex libfl-dev bison libpcap-dev libssl-dev python3 python3-dev swig zlib1g-dev -y


echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_24.04/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
sudo apt update
sudo apt install zeek


echo "[Zeek] Configuration Started"
export PATH=/opt/zeek/bin:$PATH
sudo sed -i -e "s/interface=eth0/interface=$monitoring_interface/g" /opt/zeek/etc/node.cfg
# TODO: network configuration

sudo -u root ./zeekctl check
sudo -u root ./zeekctl deploy
sudo -u root ./zeekctl status

echo "[Zeek] Installation finished"
echo "[Zeek] View the logs in"

sudo ls /opt/zeek/logs/current/ -lh

# -------///-------
echo "[OpenSearch] Installing OpenSearch"

echo "[OpenSearch] Downloading OpenSearch"
sudo apt-get -y install lsb-release ca-certificates curl gnupg2
curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-2.x.list
sudo apt-get update

sudo env OPENSEARCH_INITIAL_ADMIN_PASSWORD=$user_password_opensearch apt-get install opensearch

sudo systemctl enable opensearch
sudo systemctl start opensearch
sudo systemctl status opensearch

echo "[OpenSearch] Configuring OpenSearch"
sudo sed -i -e "s/#network.host: 192.168.0.1/network.host: 0.0.0.0/g" /etc/opensearch/opensearch.yml
sudo sed -i -e "s/#discovery.seed_hosts: [\"host1", "host2\"]/discovery.seed_hosts: [\"127.0.0.1\"]/g" /etc/opensearch/opensearch.yml

echo "[OpenSearch] Testing OpenSearch"
curl -X GET https://localhost:9200 -u 'admin:$user_password_opensearch' --insecure

curl -X GET https://localhost:9200/_cat/plugins?v -u 'admin:$user_password_opensearch' --insecure

# # discovery.type: single-node
# # plugins.security.disabled: false

# sudo vi /etc/opensearch/jvm.options
# Default 1gb
# -Xms4g
# -Xmx4g

sudo systemctl enable opensearch.service
sudo systemctl restart opensearch
sudo systemctl status opensearch
# if not successfull or some configuration issues, we'll see "OpenSearch Security not ini"

echo "[OpenSearch] Installation Finished"

echo "[OpenSearch-Dashboard] Installation started"
echo "[OpenSearch-Dashboard] Downloading Opensearch Dashboard"

echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/2.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-dashboards-2.x.list
sudo apt-get update
sudo apt-get install opensearch-dashboards -y


echo "[OpenSearch-Dashboard] Configuring Opensearch Dashboard"
sudo sed -i -e "s/# server.host: \"localhost\"/server.host: 0.0.0.0/g" /etc/opensearch-dashboards/opensearch_dashboards.yml
sudo sed -i -e "s/# server.name: \"your-hostname\"/server.name: \"$servername\"/g" /etc/opensearch-dashboards/opensearch_dashboards.yml


sudo systemctl enable opensearch-dashboards
sudo systemctl start opensearch-dashboards
# sudo systemctl status opensearch-dashboards

# default user: admin and passwrod:opensearch user password 
echo "Please login into opensearch dashboard using $user_password_opensearch  
echo "[OpenSearch-Dashboard] Installation Finished"