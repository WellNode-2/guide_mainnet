Evmos mainnet (PebbleDB)
Chain ID: evmos_9001-2 | Latest Version Tag: v16.0.3 | Custom Port: 169

~~~bash
MONIKER="WellNode_guide"
~~~
~~~bash
sudo apt -q update
sudo apt -qy install curl git jq lz4 build-essential
sudo apt -qy upgrade
~~~
~~~bash
sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.20.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
~~~
~~~bash
# Clone project repository
cd $HOME
rm -rf evmos
git clone https://github.com/evmos/evmos.git
cd evmos
git checkout v16.0.3
~~~
~~~bash
go mod edit -replace github.com/tendermint/tm-db=github.com/notional-labs/tm-db@v0.6.8-pebble
go mod tidy
go mod edit -replace github.com/cometbft/cometbft-db=github.com/notional-labs/cometbft-db@pebble
go mod tidy
~~~
~~~bash
go install -ldflags "-w -s -X github.com/cosmos/cosmos-sdk/types.DBBackend=pebbledb \
 -X github.com/cosmos/cosmos-sdk/version.Version=$(git describe --tags)-pebbledb \
 -X github.com/cosmos/cosmos-sdk/version.Commit=$(git log -1 --format='%H')" -tags pebbledb ./...
~~~
~~~bash

 # Download
tee /etc/systemd/system/evmosd.service > /dev/null << EOF
[Unit]
Description=Evmos mainnet (PebbleDB) node service
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which evmosd) start --home $HOME/.evmosd
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable evmosd


# Set node configuration
evmosd config chain-id evmos_9001-2
evmosd config keyring-backend file
evmosd config node tcp://localhost:26657


evmosd init $MONIKER --chain-id evmos_9001-2


# Download genesis and addrbook
curl -Ls http://snapshots.stakevillage.net/snapshots/evmos_9001-2/genesis.json > $HOME/.evmosd/config/genesis.json
curl -Ls http://snapshots.stakevillage.net/snapshots/evmos_9001-2/addrbook.json > $HOME/.evmosd/config/addrbook.json

# Add seeds
sed -i 's/seeds = ""/seeds = "a56f27699b7e47ce79335509c0863bcfe6ae1347@rpc.evmos.nodestake.top:666"/' ~/.evmosd/config/config.toml

# Set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"25000000aevmos\"|" $HOME/.evmosd/config/app.toml

# prunning
pruning="custom"
pruning_keep_recent="50000"
pruning_keep_every="0"
pruning_interval="19"

sed -i "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.evmosd/config/app.toml
sed -i "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.evmosd/config/app.toml
sed -i "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.evmosd/config/app.toml
sed -i "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.evmosd/config/app.toml

# snapshots
sed -i 's/snapshot-interval *=.*/snapshot-interval = 0/' $HOME/.evmosd/config/app.toml

# set pebbledb
db_backend="pebbledb"
sed -i "s/^db_backend *=.*/db_backend = \"$db_backend\"/" $HOME/.evmosd/config/config.toml
sed -i "s/^app-db-backend *=.*/app-db-backend = \"$db_backend\"/" $HOME/.evmosd/config/app.toml


sudo systemctl start evmosd && sudo journalctl -u evmosd -f --no-hostname -o cat
~~~
