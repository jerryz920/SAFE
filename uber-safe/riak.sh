#!/bin/bash


mkdir -p /data/ring


case $1 in 
  restart) 
    echo "stopping riak"
    docker rm -f riak
    echo "starting riak"
    docker run -t --rm -d -v /data:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
  stop) 
    echo "stopping riak"
    docker rm -f riak
    ;;
  clean)
    echo "cleaning riak data"
    docker rm -f riak
    rm -rf /data/*
    mkdir /data/ring
    ;;
  full-restart)
    echo "cleaning current riak data and restart"
    docker rm -f riak
    rm -rf /data/*
    mkdir /data/ring
    echo "starting riak"
    docker run -t --rm -d -v /data:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;

  *)
    echo "starting riak"
    docker run -t --rm -d -v /data:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
esac
