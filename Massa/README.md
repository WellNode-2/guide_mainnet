# Upgrade
## Backup keys
```
sudo systemctl stop massad
rm -rf $HOME/backup
mkdir $HOME/backup
cp $HOME/massa/massa-node/config/node_privkey.key $HOME/backup/node_privkey.key_backup
cp -r $HOME/massa/massa-node/config/staking_wallets $HOME/backup/staking_wallets_backup
cp -r $HOME/massa/massa-client/wallets $HOME/backup/wallets_bakup
```

## Download and unzip software
```
cd $HOME
rm -rf $HOME/massa
wget https://github.com/massalabs/massa/releases/download/MAIN.2.5/massa_MAIN.2.5_release_linux.tar.gz
tar zxvf massa_MAIN.2.4_release_linux.tar.gz
rm massa_MAIN.2.4_release_linux.tar.gz
```

## Restore keys
```
cp $HOME/backup/node_privkey.key_backup $HOME/massa/massa-node/config/node_privkey.key
cp -r $HOME/backup/staking_wallets_backup $HOME/massa/massa-node/config/staking_wallets
cp -r $HOME/backup/wallets_bakup $HOME/massa/massa-client/wallets
```

## Config app
```
tee <<EOF >/dev/null $HOME/massa/massa-node/config/config.toml
[network]
routable_ip = "`wget -qO- eth0.me`"
EOF

sed -i.bak -e "s/retry_delay =.*/retry_delay = 10000/; " $HOME/massa/massa-node/base_config/config.toml
```

## Update Service file
```
sudo tee /etc/systemd/system/massad.service > /dev/null <<EOF
[Unit]
Description=Massa
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/massa/massa-node
ExecStart=$HOME/massa/massa-node/massa-node -a -p <--YOUR_PASSWORD-->
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

## Restart service
```
sudo systemctl daemon-reload && sudo systemctl enable massad
sudo systemctl restart massad && sudo journalctl -u massad -f
```
