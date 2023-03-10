#!/bin/bash
./stop.sh
./build.sh
CHAINID=32382
PATH_TO_CONFIG=$PWD
echo $PATH_TO_CONFIG
PATH_TO_DATADIR=$PATH_TO_CONFIG/prysm-data
PATH_TO_DATADIR2=$PATH_TO_CONFIG/prysm-data2
PATH_TO_GETH=$PATH_TO_CONFIG/geth-data
rm -rf $PATH_TO_DATADIR $PATH_TO_DATADIR2 $PATH_TO_GETH
mkdir $PATH_TO_GETH
mkdir $PATH_TO_GETH/keystore
mkdir $PATH_TO_DATADIR
mkdir $PATH_TO_DATADIR2
echo '{"address":"123463a4b065722e99115d6c222f267d9cabb524","crypto":{"cipher":"aes-128-ctr","ciphertext":"93b90389b855889b9f91c89fd15b9bd2ae95b06fe8e2314009fc88859fc6fde9","cipherparams":{"iv":"9dc2eff7967505f0e6a40264d1511742"},"kdf":"scrypt","kdfparams":{"dklen":32,"n":262144,"p":1,"r":8,"salt":"c07503bb1b66083c37527cd8f06f8c7c1443d4c724767f625743bd47ae6179a4"},"mac":"6d359be5d6c432d5bbb859484009a4bf1bd71b76e89420c380bd0593ce25a817"},"id":"622df904-0bb1-4236-b254-f1b8dfdff1ec","version":3}' > $PATH_TO_GETH/keystore/UTC--2022-08-19T17-38-31.257380510Z--123463a4b065722e99115d6c222f267d9cabb524

GENESIS=$(($(date +%s) + 60)) # 120s until genesis, feel free to increase this to give you more time to everything
# The following are configureable too but you have to make sure they align.
# Take SECONDS_PER_SLOT * SLOTS_PER_EPOCH * CAPELLA_FORK_EPOCH for SHANGHAI
# Take SECONDS_PER_SLOT * SLOTS_PER_EPOCH * EIP4844_FORK_EPOCH for CANCUN
SHANGHAI=$(($GENESIS + 4*4*4))
CANCUN=$(($GENESIS + 4*4*5))
sed -i -e 's/"shanghaiTime":[^,]*,/\"shanghaiTime\":'$SHANGHAI',/' $PATH_TO_CONFIG/genesis.json
sed -i -e 's/"shardingForkTime":[^,]*,/\"shardingForkTime\":'$CANCUN',/' $PATH_TO_CONFIG/genesis.json

# REPLACE IN GENESIS CONFIG
sed -i -e 's/"eip4895TransitionTimestamp":[^,]*,/\"eip4895TransitionTimestamp\":'$SHANGHAI',/' $PATH_TO_CONFIG/spec.json
sed -i -e 's/"eip3855TransitionTimestamp":[^,]*,/\"eip4895TransitionTimestamp\":'$SHANGHAI',/' $PATH_TO_CONFIG/spec.json
sed -i -e 's/"eip3651TransitionTimestamp":[^,]*,/\"eip4895TransitionTimestamp\":'$SHANGHAI',/' $PATH_TO_CONFIG/spec.json
sed -i -e 's/"eip3860TransitionTimestamp":[^,]*,/\"eip4895TransitionTimestamp\":'$SHANGHAI',/' $PATH_TO_CONFIG/spec.json
sed -i -e 's/"eip4844TransitionTimestamp":[^,]*,/\"eip4844TransitionTimestamp\":'$CANCUN',/' $PATH_TO_CONFIG/spec.json
ELPORT=8551


cd $PATH_TO_CONFIG/prysm
bazel run //cmd/prysmctl -- testnet generate-genesis --num-validators=512 --output-ssz=$PATH_TO_DATADIR/genesis.ssz --chain-config-file=$PATH_TO_CONFIG/config.yml --genesis-time=$GENESIS
bazel run //cmd/beacon-chain -- \
    --datadir=$PATH_TO_DATADIR \
	--min-sync-peers=0 \
        --force-clear-db \
	--interop-genesis-state=$PATH_TO_DATADIR/genesis.ssz \
	--interop-eth1data-votes \
	--bootstrap-node= \
	--chain-config-file=$PATH_TO_CONFIG/config.yml \
	--chain-id=$CHAINID \
	--accept-terms-of-use \
	--jwt-secret=$PATH_TO_CONFIG/jwtsecret.txt \
	--suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
	--verbosity debug > $PATH_TO_CONFIG/beacon.log 2>&1 & 

PEER=$(curl --retry 10 --retry-connrefused --retry-delay 0 --fail http://localhost:3500/eth/v1/node/identity | jq '.data.enr' | tr -d '"' | tr -d '=')
bazel run //cmd/beacon-chain -- \
    --execution-endpoint="http://localhost:$ELPORT" \
    --datadir=$PATH_TO_DATADIR2 \
	--force-clear-db \
    --bootstrap-node="$PEER" \
	--rpc-port 4001 \
	--grpc-gateway-port 3501 \
    --p2p-tcp-port 13001 \
    --p2p-udp-port 12001 \
	--interop-genesis-state=$PATH_TO_DATADIR/genesis.ssz \
	--interop-eth1data-votes \
	--chain-config-file=$PATH_TO_CONFIG/config.yml \
	--chain-id=$CHAINID \
	--accept-terms-of-use \
	--jwt-secret=$PATH_TO_CONFIG/jwtsecret.txt \
	--suggested-fee-recipient=0x123463a4b065722e99115d6c222f267d9cabb524 \
	--verbosity debug > $PATH_TO_CONFIG/beacon2.log 2>&1 & 

bazel run //cmd/validator -- \
    --datadir=$PATH_TO_DATADIR \
	--accept-terms-of-use \
	--interop-num-validators=512 \
	--interop-start-index=0 \
	--chain-config-file=$PATH_TO_CONFIG/config.yml > $PATH_TO_CONFIG/validator.log 2>&1 &

cd $PATH_TO_CONFIG/geth
./build/bin/geth --datadir $PATH_TO_GETH init $PATH_TO_CONFIG/genesis.json

sleep 3 && ./build/bin/geth --http \
	--datadir=$PATH_TO_GETH \
	--nodiscover \
	--syncmode=full \
	--allow-insecure-unlock \
	--mine \
	--nodekeyhex=1337beef1337beef1337beef1337beef1337beef1337beef1337beef1337beef \
	--verbosity 5\
	--unlock 0x123463a4b065722e99115d6c222f267d9cabb524 --password $PATH_TO_CONFIG/very_secret_password.txt \
    --authrpc.jwtsecret=$PATH_TO_CONFIG/jwtsecret.txt > $PATH_TO_CONFIG/geth.log 2>&1 &


cd $PATH_TO_CONFIG/nethermind


