#!/bin/bash

case $1 in 
  restart) 
    echo "stopping safe"
    docker rm -f safe
    echo "starting safe"
    docker create -t --rm -d -p 7777:7777 --hostname=safe -e safe_IP=riak --name safe safe
    docker network connect devnet safe
    docker start safe
    ;;
  stop) 
    echo "stopping safe"
    docker rm -f safe
    ;;
  *)
    echo "starting safe"
    docker create -t --rm -d -p 7777:7777 --hostname=safe -e RIAK_IP=riak --name safe safe
    docker network connect devnet safe
    docker start safe
    ;;
esac
