#!/bin/bash

sudo dnf install -y mariadb-server mariadb
rpm -qa | grep mariadb
sudo systemctl enable --now mariadb
