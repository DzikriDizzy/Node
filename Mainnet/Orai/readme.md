

### How To Install Full Node ORAI MAINNET
## Setting up vars
Your Nodename (validator) that will shows in explorer
```
NODENAME=<Your_Nodename_Moniker>
ORAI_PORT=33
```

Save variables to system
```
echo "export NODENAME=$NODENAME" >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export ORAI_CHAIN_ID=Oraichain" >> $HOME/.bash_profile
echo "export ORAI_PORT=${ORAI_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## Update packages
```
sudo apt update && sudo apt upgrade -y
```

## Install dependencies
```
sudo apt install curl build-essential git wget jq make gcc tmux net-tools ccze -y
```

## Install go
```
if ! [ -x "$(command -v go)" ]; then
  ver="1.19.4"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi
```

## Download and build binaries
```
cd $HOME && rm -rf orai
git clone https://github.com/oraichain/orai.git && cd orai
git checkout v0.41.2
go get ./...
make build VERSION=0.41.2
sudo mv ./build/oraid /root/go/bin
```

## Config app
```
oraid init $NODENAME --chain-id $ORAI_CHAIN_ID --home "$HOME/root/.oraid"

```
## set custom ports
```
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${ORAI_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${ORAI_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${ORAI_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${ORAI_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${ORAI_PORT}660\"%" $HOME/.oraid/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${ORAI_PORT}317\"%; s%^address = \":8080\"%address = \":${ORAI_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${ORAI_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${ORAI_PORT}091\"%" $HOME/.oraid/config/app.toml
```

## Init app
```
-
```

### Download configuration
```
cd $HOME
curl -Ls https://raw.githubusercontent.com/konsortech/Node/main/Mainnet/Orai/genesis.json  > $HOME/.oraid/config/genesis.json
curl -Ls https://raw.githubusercontent.com/konsortech/Node/main/Mainnet/Orai/addrbook.json > $HOME/.oraid/config/addrbook.json
```

## Download Snapshot 
```
sudo systemctl stop lumenxd
cp $HOME/.oraid/data/priv_validator_state.json $HOME/.oraid/priv_validator_state.json.backup
rm -rf $HOME/.oraid/data


curl https://snapshots.synergynodes.com/oraichain/oraichain_10712788.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.oraid
mv $HOME/.oraid/priv_validator_state.json.backup $HOME/.oraid/data/priv_validator_state.json

sudo systemctl restart lumenxd && journalctl -u lumenxd -f --no-hostname -o cat
```

## Set seeds and peers
```
sed -E -i 's/seeds = \".*\"/seeds = \"4d0f2d042405abbcac5193206642e1456fe89963@3.134.19.98:26656,24631e98a167492fd4c92c582cee5fd6fcd8ad59@162.55.253.58:26656,bf083c57ed53a53ccd31dc160d69063c73b340e9@3.17.175.62:26656,35c1f999d67de56736b412a1325370a8e2fdb34a@5.189.169.99:26656,5ad3b29bf56b9ba95c67f282aa281b6f0903e921@64.225.53.108:26656,d091cabe3584cb32043cc0c9199b0c7a5b68ddcb@seed.orai.synergynodes.com:26656\"/' $HOME/.oraid/config/config.toml


```

## Disable indexing
```
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.oraid/config/config.toml
```

## Config pruning
```
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.oraid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.oraid/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.oraid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.oraid/config/app.toml
```

## Set minimum gas price
```
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.025orai\"|" $HOME/.oraid/config/app.toml

```

## Create service
```
sudo tee /etc/systemd/system/oraid.service > /dev/null <<EOF
[Unit]
Description=Orai Network Node
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which oraid) start --home /root/.oraid
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
```

## Register and start service
```
sudo systemctl daemon-reload
sudo systemctl enable oraid
sudo systemctl restart oraid && sudo journalctl -u oraid -f -o cat
```
