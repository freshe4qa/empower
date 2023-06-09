<p align="center">
  <img height="100" height="auto" src="https://github.com/freshe4qa/empower/assets/85982863/a15dbe95-42c0-4b22-afc6-ef9facf2042c)">
</p>

# Empower Testnet — circulus-1

Official documentation:
>- [Validator setup instructions](https://docs.empowerchain.io/testnet/overview)

Explorer:
>- [https://empower.explorers.guru](https://empower.explorers.guru)

### Minimum Hardware Requirements
 - 4x CPUs; the faster clock speed the better
 - 8GB RAM
 - 100GB of storage (SSD or NVME)

## Set up your nibiru fullnode
```
wget https://raw.githubusercontent.com/freshe4qa/empower/main/empower.sh && chmod +x empower.sh && ./empower.sh
```

## Post installation

When installation is finished please load variables into system
```
source $HOME/.bash_profile
```

Synchronization status:
```
empowerd status 2>&1 | jq .SyncInfo
```

### Create wallet
To create new wallet you can use command below. Don’t forget to save the mnemonic
```
empowerd keys add $WALLET
```

Recover your wallet using seed phrase
```
empowerd keys add $WALLET --recover
```

To get current list of wallets
```
empowerd keys list
```

## Usefull commands
### Service management
Check logs
```
journalctl -fu empowerd -o cat
```

Start service
```
sudo systemctl start empowerd
```

Stop service
```
sudo systemctl stop empowerd
```

Restart service
```
sudo systemctl restart empowerd
```

### Node info
Synchronization info
```
empowerd status 2>&1 | jq .SyncInfo
```

Validator info
```
empowerd status 2>&1 | jq .ValidatorInfo
```

Node info
```
empowerd status 2>&1 | jq .NodeInfo
```

Show node id
```
empowerd tendermint show-node-id
```

### Wallet operations
List of wallets
```
empowerd keys list
```

Recover wallet
```
empowerd keys add $WALLET --recover
```

Delete wallet
```
empowerd keys delete $WALLET
```

Get wallet balance
```
empowerd query bank balances $EMPOWER_WALLET_ADDRESS
```

Transfer funds
```
empowerd tx bank send $EMPOWER_WALLET_ADDRESS <TO_EMPOWER_WALLET_ADDRESS> 10000000umpwr
```

### Voting
```
empowerd tx gov vote 1 yes --from $WALLET --chain-id=$EMPOWER_CHAIN_ID
```

### Staking, Delegation and Rewards
Delegate stake
```
empowerd tx staking delegate $EMPOWER_VALOPER_ADDRESS 10000000umpwr --from=$WALLET --chain-id=$EMPOWER_CHAIN_ID --gas=auto
```

Redelegate stake from validator to another validator
```
empowerd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 10000000umpwr --from=$WALLET --chain-id=$EMPOWER_CHAIN_ID --gas=auto
```

Withdraw all rewards
```
empowerd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$EMPOWER_CHAIN_ID --gas=auto
```

Withdraw rewards with commision
```
empowerd tx distribution withdraw-rewards $EMPOWER_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$EMPOWER_CHAIN_ID
```

Unjail validator
```
empowerd tx slashing unjail \
  --broadcast-mode=block \
  --from=$WALLET \
  --chain-id=$EMPOWER_CHAIN_ID \
  --gas=auto
```
