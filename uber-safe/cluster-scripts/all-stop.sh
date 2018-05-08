#!/bin/bash

ssh riak1 "docker rm -f riak-master;"

for n in 2 3; do
ssh -t riak$n "docker rm -f riak$n;"
done
