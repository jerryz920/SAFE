
source env.sh
# on first node
for n in $WORKER; do
  ssh -tt $n '
  sudo apt-get remove -y docker docker-engine docker.io
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  sudo apt-get update -y
  sudo apt-get install -y docker-ce'

  ssh -tt controller scp -r /openstack/safe $n:/openstack/
  ssh $n 'cd /openstack/safe/uber-safe/dockerfiles/riak; docker build -t riak .' >/tmp/riak-buildlog-$n 2>&1 &
done

for n in `jobs -p`; do
  wait $n
done


# setting up swarm for simplicity
# /etc/hosts already have MASTER name
myip=`grep $MASTER /etc/hosts | awk '{print $1}' | head -n 1`
ssh -tt $MASTER "docker swarm init --advertise $myip"
ssh -tt $MASTER docker swarm join-token worker | grep -v "add a worker to" > /tmp/tmp.sh
for n in $WORKER; do
  scp /tmp/tmp.sh $n:/tmp
  ssh -tt $n 'bash /tmp/tmp.sh; rm -f /tmp/tmp.sh'
done
rm -f /tmp/tmp.sh

ssh -tt $MASTER docker network create -d overlay --attachable riaknet




