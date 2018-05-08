#!/bin/bash

ssh riak1 "docker rm -f riak-master; rm -rf /openstack/node/sdc1/riak/*"

for n in 2 3; do
ssh -t riak$n "docker rm -f riak$n; rm -rf /openstack/node/sdc1/riak/*"
done
