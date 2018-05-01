#!/bin/bash

case $1 in 
  start)
    echo "starting riak"
    docker run -t --rm -d -p 8098:8098 --security-opt seccomp:unconfined  --name riak riak-img
    ;;
  restart) 
    echo "stopping riak"
    docker rm -f riak
    echo "starting riak"
    docker run -t --rm -d -p 8098:8098 --security-opt seccomp:unconfined  --name riak riak-img
    ;;
  stop) 
    echo "stopping riak"
    docker rm -f riak
    ;;
  *) echo "unknown command";;
esac
