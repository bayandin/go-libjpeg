#!/bin/bash -eux
#
# Helper script for working with fuzzit.dev
# https://github.com/fuzzitdev/example-go
#

## Build fuzzing targets
## go-fuzz doesn't support modules for now, so ensure we do everything
## in the old style GOPATH way
export GO111MODULE="off"

## Install go-fuzz
go get -u github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build

## download dependencies into ${GOPATH}
## -d : only download (don't install)f
## -v : verbose
## -u : use the latest version
## will be different if you use vendoring or a dependency manager
## like godep
#go get -d -v -u ./...
cd $GOPATH/src/github.com/bayandin/go-libjpeg

go-fuzz-build -libfuzzer -o jpeg-fuzz.a github.com/bayandin/go-libjpeg/jpeg

cp /tmp/libjpeg-turbo/lib64/*.so* ./
clang -ljpeg -L. -I/tmp/libjpeg-turbo/include -fsanitize=fuzzer,address jpeg-fuzz.a -o fuzzer

## Install fuzzit specific version for production or latest version for development :
# https://github.com/fuzzitdev/fuzzit/releases/latest/download/fuzzit_Linux_x86_64
wget -q -O fuzzit https://github.com/fuzzitdev/fuzzit/releases/download/v2.4.72/fuzzit_Linux_x86_64
chmod a+x fuzzit

## upload fuzz target for long fuzz testing on fuzzit.dev server or run locally for regression
tar -czf fuzzer.tar.gz fuzzer ./*.so* fuzzing.dict

TYPE="$1"
./fuzzit create job --type "${TYPE}" --args "-dict=fuzzing.dict" bayandin/go-libjpeg fuzzer.tar.gz
