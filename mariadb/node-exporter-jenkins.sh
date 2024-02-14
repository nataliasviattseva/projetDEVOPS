#!/bin/bash

# Création du groupe et de l'utilisateur prometheus
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
apt install curl -y
# Téléchargement et installation de mysqld_exporter
latest_release_url=$(curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4)
wget -q https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.1/mysqld_exporter-0.15.1.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.15.1.linux-amd64.tar.gz
sudo mv mysqld_exporter-0.15.1.linux-amd64/mysqld_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter

# Vérification de la version de mysqld_exporter
mysqld_exporter --version

# Connexion à MySQL et création de l'utilisateur exporter
#mysql -u root -p'jenkins' <<EOF
#CREATE USER 'exporter'@'10.8.2.240' IDENTIFIED BY 'jenkins';
#GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';
#FLUSH PRIVILEGES;
#EXIT;
#EOF

# Création du fichier de configuration pour mysqld_exporter
sudo bash -c 'cat << EOF > /etc/.mysql_exporter.cnf
[client]
user=root
password=jenkins
EOF'

# Modification des permissions du fichier de configuration
sudo chown root:prometheus /etc/.mysql_exporter.cnf

# Création du service systemd pour mysqld_exporter
sudo bash -c 'cat << EOF > /etc/systemd/system/mysql_exporter.service
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=root
#Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf /etc/.mysql_exporter.cnf --collect.global_status --collect.info_schema.innodb_metrics --collect.auto_increment.columns --collect.info_schema.processlist --collect.binlog_size --collect.info_schema.tablestats --collect.global_variables --collect.info_schema.query_response_time --collect.info_schema.userstats --collect.info_schema.tables --collect.perf_schema.tablelocks --collect.perf_schema.file_events --collect.perf_schema.eventswaits --collect.perf_schema.indexiowaits --collect.perf_schema.tableiowaits --collect.slave_status --web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOF'

# Rechargement de systemd et démarrage du service mysqld_exporter
sudo systemctl daemon-reload
sudo systemctl enable mysql_exporter
sudo systemctl start mysql_exporter
