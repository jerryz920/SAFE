#!/bin/bash

internal_ip=`hostname -i`
sed -i "/^listener.http.internal/ s:.*:listener.http.internal = 0.0.0.0\:8098:" /etc/riak/riak.conf
sed -i "/^listener.protobuf.internal/ s:.*:listener.protobuf.internal = 0.0.0.0\:8087:" /etc/riak/riak.conf
sed -i "/^nodename = / s:.*:nodename = riak@${internal_ip}:" /etc/riak/riak.conf

riak start
riak ping
# Initialize Riak with a SAFE bucket
if [[ x"$MASTER" != x ]]; then
  riak-admin cluster join riak-inner@$MASTER
else
  riak-admin bucket-type create safesets '{"props":{"n_val":3, "w":2, "r":2, "pw":0, "pr":0}}'
  riak-admin bucket-type activate safesets
  riak-admin bucket-type update safesets '{"props":{"allow_mult":false}}'

  # used for the trusted network -> UUID mapping
  riak-admin bucket-type create trustnet '{"props":{"n_val":3, "w":2, "r":2, "pw":0, "pr":0}}'
  riak-admin bucket-type activate trustnet
  riak-admin bucket-type update trustnet '{"props":{"allow_mult":false}}'

  sleep 10
  bash ~/test.sh
fi

/bin/bash
