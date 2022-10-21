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
echo "export EMPOWER_CHAIN_ID=altruistic-1" >> $HOME/.bash_profile
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
git clone https://github.com/empowerchain/empowerchain
cd empowerchain/chain
make install

# config
empowerd config chain-id $EMPOWER_CHAIN_ID
empowerd config keyring-backend test

# init
empowerd init $NODENAME --chain-id $EMPOWER_CHAIN_ID

# download genesis and addrbook
wget -O $HOME/.empowerchain/config/genesis.json "https://raw.githubusercontent.com/empowerchain/empowerchain/main/testnets/altruistic-1/genesis.json"
curl -s https://snapshots2-testnet.nodejumper.io/empower-testnet/addrbook.json > $HOME/.empowerchain/config/addrbook.json

# set minimum gas price
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0umpwr\"/;" ~/.empowerchain/config/app.toml

# set peers and seeds
PEERS="ca8b9d5fecd3258cb8bb4164017114898cd63ad5@empower-testnet.nodejumper.io:31656,6dae9286b4ef23151148922befc0f32a00cc1ec4@65.21.134.202:26656,ab4b4331d161cf0e98d3244e30225e4f38ac8d2f@65.109.28.177:44656,d9307a7ba665a54e65f4fa5dbb5401448e1c3456@65.109.30.117:30656,46b552c62df0523a2bfff285eb384e4b197484aa@65.21.133.125:33656,408980a63332b230a90ad549e93162dab303836f@65.108.225.158:17456,605b175a3cf6f71d454840baef08d0e81d94935f@65.108.52.192:46656,86669cd5e5914f862578d43de483f49e93d396b1@51.83.35.129:26656,b405572f7bf70f681d1e82f196e1399bf90a9d8a@138.201.197.163:26656,c5d44acd2f0ee122352d2f8154d9b29aeb9bf0ec@159.69.65.97:36656,2b3da30140b57d64a57a25485c237f9c7c3c3324@194.163.136.90:26656,8abceaabc650d81a751e40382f80af6c98ba466f@185.239.209.180:35656,333de3fc2eba7eead24e0c5f53d665662b2ba001@35.187.86.119:26656,b5df76282e8704d253012688613d4eb725d3cb12@77.37.176.99:56656,8498049b61177a53b3f0e6b8f7c4a574251a2bbb@149.102.157.96:36656,56d05d4ae0e1440ad7c68e52cc841c424d59badd@96.234.160.22:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.empowerchain/config/config.toml
SEEDS=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.empowerchain/config/config.toml

# config pruning
pruning="custom" && \
pruning_keep_recent="100" && \
pruning_keep_every="0" && \
pruning_interval="50" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empowerchain/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empowerchain/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empowerchain/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empowerchain/config/app.toml

# reset
empowerd unsafe-reset-all --home $HOME/.empowerchain

# create service
sudo tee /etc/systemd/system/empowerd.service > /dev/null <<EOF
[Unit]
Description=empowerd
After=network-online.target

[Service]
User=$USER
ExecStart=$(which empowerd) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
systemctl daemon-reload && \
systemctl enable empowerd && \
systemctl restart empowerd && journalctl -u empowerd -f -o cat

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
  --amount 1000000umpwr \
  --from $WALLET \
  --commission-max-change-rate 0.1 \
  --commission-max-rate 0.2 \
  --commission-rate 0.05 \
  --min-self-delegation "1000000" \
  --pubkey  $(empowerd tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $EMPOWER_CHAIN_ID
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
