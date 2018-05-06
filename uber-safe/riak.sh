#!/bin/bash


USE_VOLUME=1

if [ $USE_VOLUME -eq 1 ]; then
  VOL_NAME=data
docker volume create $VOL_NAME
else
  VOL_NAME=/data
mkdir -p /data/ring
fi



case $1 in 
  restart) 
    echo "stopping riak"
    docker rm -f riak
    echo "starting riak"
    docker run -t --rm -d -v $VOL_NAME:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
  stop) 
    echo "stopping riak"
    docker rm -f riak
    ;;
  clean)
    echo "cleaning riak data"
    docker exec -it riak riak stop
    docker rm -f riak
    if [ $USE_VOLUME -eq 1 ]; then
      docker volume rm -f $VOL_NAME
    else
      rm -rf $VOL_NAME/riak/*
      mkdir -p $VOL_NAME/ring
    fi
    ;;
  full-restart)
    echo "cleaning current riak data and restart"
    docker rm -f riak
    if [ $USE_VOLUME -eq 1 ]; then
      docker volume rm -f $VOL_NAME
      docker volume create $VOL_NAME
    else
      rm -rf $VOL_NAME/riak/*
      mkdir -p $VOL_NAME/ring
    fi
    echo "starting riak"
    docker run -t --rm -d -v $VOL_NAME:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;

  *)
    echo "starting riak"
    docker run -t --rm -d -v $VOL_NAME:/var/lib/riak/:rw -p 8098:8098 -p 8087:8087 --hostname=riak --name riak riak
    docker network connect devnet riak
    ;;
esac
