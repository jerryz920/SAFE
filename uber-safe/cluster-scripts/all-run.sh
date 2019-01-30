#!/bin/bash

VOLNAME=/openstack/node/sdc1/riak/

for n in 1 2 3; do
ssh riak$n "mkdir -p $VOLNAME"
done

ssh riak1 docker run -v $VOLNAME:/var/lib/riak/ -dt --rm --network riaknet -p 8098:8098 -p 8087:8087 --hostname riak-master --name riak-master riak
echo "Master node name is: "
ssh -t riak1 docker run -it riak-master cat /etc/riak/riak.conf | grep node
MASTER="riak-master@`ssh riak1 docker inspect riak-master --format {{.NetworkSettings.Networks.riaknet.IPAddress}}`"
echo master is $MASTER 

echo "waiting for master to initialize"
sleep 10
for n in 2 3; do
ssh riak$n docker run -v $VOLNAME:/var/lib/riak/ -dt --rm --network riaknet -p 8098:8098 -p 8087:8087 -e MASTER=$MASTER --hostname riak$n --name riak$n riak
done
echo "waiting for other nodes to join"
for n in 2 3; do
ssh riak$n docker logs riak$n
done

sleep 15
ssh -tt riak1 docker exec -it riak-master riak-admin cluster plan
ssh -tt riak1 docker exec -it riak-master riak-admin cluster commit

