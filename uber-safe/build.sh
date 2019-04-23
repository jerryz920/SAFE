#!/bin/bash
script=`readlink -f $0`
workdir=`dirname $script`
RIAK_IP=${RIAK_IP:-riak}
guard="image-builder"


cd $workdir/safe-apps/cloud-attestation/latte-generator
python3 main.py -b $guard -e endorsements/*.json -g guards/*.json -s tests/functions > latte.slang
cd $workdir
sed -i "/.*url = \"http/ s:.*:    url = \"http\://${RIAK_IP}\:8098/types/safesets/buckets/safe/keys\":" safe-server/src/main/resources/application.conf


sbt "project safe-server" "run -f $workdir/safe-apps/cloud-attestation/latte-generator/latte.slang  -r safeService  -kd   src/main/resources/multi-principal-keys/" &

echo $! > $workdir/safe.pid
#different is we kill the command after 150second
sleep 250
kill %1
echo "after build!"

