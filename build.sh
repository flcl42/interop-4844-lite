#!/bin/bash
cd prysm
bazel build //cmd/prysmctl
bazel build //cmd/beacon-chain
bazel build //cmd/validator
cd ../
cd geth
make geth
cd ../
cd nethermind/src/Nethermind
dotnet build Nethermind.sln
cd ../../../