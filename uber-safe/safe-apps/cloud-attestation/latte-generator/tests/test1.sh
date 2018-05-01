#!/bin/bash

SAFE_ADDR=http://localhost:7777
IAAS=152.3.145.38:444
IaaS=152.3.145.38:444

source ./functions


# configs
N=1
L=3

postLinkImageOwner $IaaS "vm-builder" "image-vm"
postVpcConfig2 $IaaS "vpc1" "secgroup" "tcp:0.0.0.0:2376" "secgroup" "tcp:0.0.0.0:8080"
create() {
for n in `seq 1 $N`; do
  echo "posting instance $n"
  postVMInstanceSet $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
  postInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
  postInstanceControl $IAAS $IAAS "vm$n"
done
}

time create


# endorse the source from "simulated instance" to simplify the test
postVMInstanceSet $IAAS "vm-builder" "image-builder" "128.105.104.122:1-65535" "192.167.1.0/24" $IaaS "vpc-builder"
postInstanceControl $IAAS $IAAS "vm-builder"
# create source for image-vm, image-spark, image-ctn, make image-builder the builder image
postEndorsement "vm-builder" "image-vm" "source" "github"



