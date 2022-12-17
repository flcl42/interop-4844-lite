# Ids and settings
chainid is 32382

networkid is 1

geth is enode://2a776ec66730fc7598b6875e8eaf3b781a2b62a8b8d7427dd0d2b71dcfbe8da5cb9c5f7f67905ffc2f2aa67d03cd5d877ddfcd38fba3b7f03546ce51d6daa6c4@127.0.0.1:30303?discport=0

SECONDS_PER_SLOT: 4

SLOTS_PER_EPOCH: 4

"clique.period": 3,

# Requires
bazel sed curl

# How to run

The script resets on restart and kills all geth/beacon/validator!
To run or restart from scratch:
```
run.sh
```

To shutdown:
```
stop.sh
```

Simple run just starts geth and 2 prysm.
To run an additional execution client (like Nethermind):
- change ports to be different from 8545/8551 used by geth
- set proper replacement, see "# REPLACE IN GENESIS CONFIG" in run.sh
- set ELPORT pointing JsonRPC endpoint for EL <-> CL communication(I set to 8552), initially it points to the same geth
- start it only when run.sh finishes, which means that Geth and 2 Prysms have started 

It runs to 0x9 block, waits a bit and merges

# Send blobs
To send blobs - use upload/main.go from the interop repo, go.mod with patch
```
diff --git a/go.mod b/go.mod
index de676b7..865f68f 100644
--- a/go.mod
+++ b/go.mod
@@ -146,7 +146,7 @@ require (
        github.com/prometheus/procfs v0.7.3 // indirect
        github.com/prometheus/prom2json v1.3.0 // indirect
        github.com/prometheus/tsdb v0.10.0 // indirect
-       github.com/protolambda/go-kzg v0.0.0-20221122014024-bb3fa3695412 // indirect
+       github.com/protolambda/go-kzg v0.0.0-20221129234330-612948a21fb0 // indirect
        github.com/prysmaticlabs/fastssz v0.0.0-20220628121656-93dfe28febab // indirect
        github.com/prysmaticlabs/go-bitfield v0.0.0-20210809151128-385d8c5e3fb7 // indirect
        github.com/prysmaticlabs/gohashtree v0.0.2-alpha // indirect
```

privatekey is 2e0834786285daccd064ca17f1654f67b4aef298acbb82cef9ec422fb4975622 for addr 0x123463a4B065722E99115D6c222f267d9cABb524

### Nethermind
is not here yet in full, ping me I push the branch 