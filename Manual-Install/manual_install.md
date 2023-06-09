# Manual node setup
If you want to setup fullnode manually follow the steps below

## Setting up vars
Here you have to put name of your moniker (validator) that will be visible in explorer
```
NODENAME=<YOUR_MONIKER_NAME>
```

Save and import variables into system
```
echo "export NODENAME=$NODENAME" >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export NIBIRU_CHAIN_ID=circulus-1" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## Update packages
```
sudo apt update && sudo apt upgrade -y
```

## Install dependencies
```
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y
```

## Install go
```
ver="1.20.3" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version
```

## Download and build binaries
```
cd $HOME
git clone https://github.com/EmpowerPlastic/empowerchain
cd empowerchain/chain
git checkout v1.0.0-rc2
make install
```

## Config app
```
empowerd config chain-id circulus-1
empowerd config keyring-backend test
```

## Init app
```
empowerd init $NODENAME --chain-id circulus-1
```

## Download genesis and addrbook
```
curl -s https://raw.githubusercontent.com/EmpowerPlastic/empowerchain/main/testnets/circulus-1/genesis.json > $HOME/.empowerchain/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/empower-testnet/addrbook.json > $HOME/.empowerchain/config/addrbook.json
```

## Set seeds and peers
```
SEEDS=""
PEERS="b897014f22e932e461e7fc98353a57d642dbe16e@empower-testnet.nodejumper.io:32656,0e56c10d30f4f16f5be4146bb905471ba99051df@86.48.17.208:15056,95ea7999e3ecd3fb7fd73fae70b3b29a6af24c8d@46.4.5.45:17456,1b4d9789c27befae430538d4364d012df61df896@65.109.82.112:2446,42e60e3b5784c1f670450376a095e221e4b0edc3@157.90.152.90:15056"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empowerchain/config/config.toml
```

## Config pruning
```
# disable indexing
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.empowerchain/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empowerchain/config/app.toml
sed -i "s/snapshot-interval *=.*/snapshot-interval = 0/g" $HOME/.empowerchain/config/app.toml
```

## Set minimum gas price and timeout commit
```
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.001umpwr\"/;" $HOME/.empowerchain/config/app.toml
```

## Enable prometheus
```
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empowerchain/config/config.toml
```

## Reset chain data
```
empowerd tendermint unsafe-reset-all
```

## Create service
```
sudo tee /etc/systemd/system/empowerd.service > /dev/null << EOF
[Unit]
Description=Empower Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which empowerd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF
```

## Register and start service
```
sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd && sudo journalctl -u empowerd -f -o cat
```
