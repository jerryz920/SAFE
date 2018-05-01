#!/bin/bash

SAFE_ADDR=http://localhost:7777
IAAS=152.3.145.38:444
IaaS=152.3.145.38:444

source ./functions


# configs
N=100
L=3


postLinkImageOwner $IaaS "vm-builder" "image-vm"
postLinkImageOwner "vm1" "vm-builder" "image-ctn"
postLinkImageOwner "ctn1" "vm-builder" "image-spark"
create() {
for n in `seq 1 $N`; do
  echo "posting instance $n"
  postVMInstanceSet $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
  postInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
  postInstanceControl $IAAS $IAAS "vm$n"
  if [ $L -le 1 ]; then
    continue;
  fi
  for m in `seq 1 50`; do
    postInstanceSet "vm$n" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "vm1"
    postInstanceConfig5 "vm$n" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
    postInstanceControl $IAAS "vm$n" "vm$n-ctn$m"
    if [ $L -le 2 ]; then
      continue;
    fi
    postLinkImageOwner $IaaS "vm-builder" "image-vm"
    for l in `seq 1 5`; do
      postInstanceSet "vm$n-spark$l" "image-spark" "192.168.$n.$m:32000-65535" "ctn1"
      postInstanceConfig5 "vm$n-ctn$m" "vm$n-spark$l" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
      postInstanceControl $IAAS "vm$n-ctn$m" "vm$n-spark$l"
    done
  done
done
}

time create >/dev/null 2>&1


# endorse the source from "simulated instance" to simplify the test
postVMInstanceSet $IAAS "vm$n" "image-builder" "128.105.104.122:1-65535" "192.168.1.0/24" $IaaS "vpc-builder"
# create source for image-vm, image-spark, image-ctn, make image-builder the builder image



remove() {
for n in `seq 1 $N`; do
  echo "deleting instance $n"
  delVMInstanceSet $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
  delInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
  delInstanceControl $IAAS $IAAS "vm$n"
  if [ $L -le 1 ]; then
    continue;
  fi
  for m in `seq 1 50`; do
    delInstanceSet "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "vm1"
    delInstanceConfig5 "vm$n" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
    delInstanceControl $IAAS "vm$n" "vm$n-ctn$m"
    if [ $L -le 2 ]; then
      continue;
    fi
    for l in `seq 1 5`; do
      delInstanceSet "vm$n-spark$l" "image-spark" "192.168.$n.$m:32000-65535" "ctn1"
      delInstanceConfig5 "vm$n-ctn$m" "vm$n-spark$l" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
      delInstanceControl $IAAS "vm$n" "vm$n-ctn$m"
    done
  done
done
}

time remove >/dev/null 2>&1
