#!/bin/bash

for n in 1 2 3 4; do
  ssh riak$n "cd /openstack/safe/; git pull origin latte; cd uber-safe/dockerfiles/riak; docker build -t riak .; cd ../safe; "
  #docker build -t safe .;"
done
