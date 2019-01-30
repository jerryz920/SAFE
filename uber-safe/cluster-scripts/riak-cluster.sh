
source env.sh



# starting the riak container
ssh $MASTER docker run -dt --rm --network riaknet -p 8099:8098 -p 8087:8087 --hostname riak1 --name riak1 riak

i=2
for n in $WORKER; do
  ssh -tt $WORKER docker run -dt --rm --network riaknet -e MASTER=riak1 -p 8099:8098 -p 8087:8087 --hostname riak$i --name riak$i riak
  i=$((i+1))
done
ssh $MASTER docker exec -it riak1 riak-admin cluster plan
ssh $MASTER docker exec -it riak1 riak-admin cluster commit
echo "waiting for cluster to be ready"
sleep 30
ssh $MASTER docker exec -it riak1 riak-admin cluster status











