#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export EMPOWER_CHAIN_ID=circulus-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

# update
sudo apt update && sudo apt upgrade -y

# packages
apt install curl build-essential git wget jq make gcc tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# install go
source $HOME/.bash_profile
    if go version > /dev/null 2>&1
    then
        echo -e '\n\e[40m\e[92mSkipped Go installation\e[0m'
    else
        echo -e '\n\e[40m\e[92mStarting Go installation...\e[0m'
        ver="1.19" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version
    fi

# download binary
cd $HOME
git clone https://github.com/EmpowerPlastic/empowerchain
cd empowerchain/chain
git checkout v1.0.0-rc1
make install

# config
empowerd config chain-id $EMPOWER_CHAIN_ID
empowerd config keyring-backend test

# init
empowerd init $NODENAME --chain-id $EMPOWER_CHAIN_ID

# download genesis and addrbook
curl -s https://raw.githubusercontent.com/EmpowerPlastic/empowerchain/main/testnets/circulus-1/genesis.json > $HOME/.empowerchain/config/genesis.json
curl -s https://snapshots2-testnet.nodejumper.io/empower-testnet/addrbook.json > $HOME/.empowerchain/config/addrbook.json

# set minimum gas price
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.001umpwr\"/;" $HOME/.empowerchain/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="b897014f22e932e461e7fc98353a57d642dbe16e@empower-testnet.nodejumper.io:32656,0e56c10d30f4f16f5be4146bb905471ba99051df@86.48.17.208:15056,95ea7999e3ecd3fb7fd73fae70b3b29a6af24c8d@46.4.5.45:17456,1b4d9789c27befae430538d4364d012df61df896@65.109.82.112:2446,42e60e3b5784c1f670450376a095e221e4b0edc3@157.90.152.90:15056"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empowerchain/config/config.toml

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

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empowerchain/config/config.toml

# create service
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

# reset
empowerd tendermint unsafe-reset-all --home $HOME/.empowerchain --keep-addr-book 
curl https://snapshots2-testnet.nodejumper.io/empower-testnet/circulus-1_2023-06-07.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.empowerchain

# start service
sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd

break
;;

"Create Wallet")
empowerd keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
EMPOWER_WALLET_ADDRESS=$(empowerd keys show $WALLET -a)
EMPOWER_VALOPER_ADDRESS=$(empowerd keys show $WALLET --bech val -a)
echo 'export EMPOWER_WALLET_ADDRESS='${EMPOWER_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export EMPOWER_VALOPER_ADDRESS='${EMPOWER_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Create Validator")

empowerd tx staking create-validator \
--amount=1000000umpwr \
--pubkey=$(empowerd tendermint show-validator) \
--moniker $NODENAME \
--chain-id $EMPOWER_CHAIN_ID \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from $WALLET \
--gas-prices=0.1umpwr \
--gas-adjustment=1.5 \
--gas=auto \
-y
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
