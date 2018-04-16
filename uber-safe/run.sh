#!/bin/bash

script=`readlink -f $0`
workdir=`dirname $script`

sbt "project safe-server" "run -f $workdir/safe-apps/cloud-attestation/latte.slang  -r safeService  -kd   src/main/resources/multi-principal-keys/"
