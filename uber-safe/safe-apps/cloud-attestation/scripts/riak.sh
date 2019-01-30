#!/bin/bash

case $1 in 
  restart) 
    echo "stopping riak"
    docker rm -f riak
    echo "starting riak"
    docker run -t --rm -d -p 8098:8098 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
  stop) 
    echo "stopping riak"
    docker rm -f riak
    ;;
  *)
    echo "starting riak"
    docker run -t --rm -d -p 8098:8098 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
esac
