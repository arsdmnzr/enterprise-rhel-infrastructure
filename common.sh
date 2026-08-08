#!/bin/bash


sudo dnf clean all
sudo dnf update -y

echo "Setting Hostname....."
read -p "Enter hostname: " host
sudo hostnamectl set-hostname $host
echo "Now Hostname Name is: "$(hostname)

sudo nmcli con show
ip a
echo "Setting Static IP..."
read -p "Enter ifname ip, gateway and dns: " ifname ip gateway dns
sudo nmcli con mod $ifname ipv4.addresses $ip/24 ipv4.gateway $gateway ipv4.dns $dns ipv4.method manual
sudo nmcli con up ens33
ip a
ip route

echo "Setting Selinux Enforcing Mode..."
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
grep "SELINUX=enforcing" /etc/selinux/config

echo "Checking Firewall...."
if rpm -q firewalld >/dev/null 2>&1; then echo "Firewall Already Installed"; else sudo dnf install firewalld; fi
sudo systemctl enable --now  firewalld
echo "firewall is: $(sudo systemctl is-active firewalld) and $(sudo systemctl is-enabled firewalld)"


echo "Checking Chrony Services.."
if rpm -q chrony >/dev/null 2>&1; then echo "chrony already installed"; else sudo dnf install -y chrony; fi
sudo systemctl enable --now chronyd
echo "chronyd is: "$(sudo systemctl is-active chronyd) "and " $(sudo systemctl is-enabled chronyd)
echo "Setting up time-zone to Asia/Kolkata"
sudo timedatectl set-timezone Asia/Kolkata
sudo systemctl restart chronyd
timedatectl

echo "centralized loging setup..."
if ! rpm -q rsyslog &>/dev/null; then
sudo dnf install -y rsyslog
fi
echo "*.* @@192.168.170.10:514" | sudo tee /etc/rsyslog.d/forward.conf
sudo systemctl enable --now rsyslog
sudo systemctl restart rsyslog


echo "node_exporter installing....."
sudo tar -xvzf node*  -C /tmp
sudo useradd -M -s /sbin/nologin node_exporter
sudo cp /tmp/node*/node* /usr/local/bin/
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOF

[Unit]
Description= node
Wants=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload
sudo systemctl enable --now node_exporter
echo "node_exporter is $(sudo systemctl is-active node_exporter) and $(sudo systemctl is-enabled node_exporter)"
