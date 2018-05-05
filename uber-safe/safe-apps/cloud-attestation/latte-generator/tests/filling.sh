#!/bin/bash

SAFE_ADDR=http://localhost:19851
IAAS=152.3.145.38:444
IaaS=152.3.145.38:444

source ./functions
source ./manual-functions


# configs
N=1
L=3
BUILDER="128.105.104.122:1-65535"

# endorse the source from "simulated instance" to simplify the test
postVMInstance $IAAS "vm-builder" "image-builder" "128.105.104.122:1-65535" "192.168.1.0/24" $IaaS "vpc-builder"
postLinkImageOwner $IaaS "$BUILDER" "image-vm"
postEndorsement "$BUILDER" "image-vm" "source" "https://github.com/jerryz920/boot2docker"
postEndorsement "$BUILDER" "image-ctn" "source" "https://github.com/apache/spark"
postEndorsement "$BUILDER" "image-spark" "source" "https://github.com/intel/hibench"
create() {
  for n in `seq 1 $N`; do
    echo "posting instance $n"
    postVMInstance $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
    postInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
    #  postInstanceControl $IAAS $IAAS "vm$n"
    if [ $L -le 1 ]; then
      continue;
    fi
    for m in `seq 1 5`; do
      postInstance "192.168.0.$n:1-65535" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "192.168.0.1:1000"
      postInstanceConfig5 "192.168.0.$n:1-65535" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
      #    postInstanceControl $IAAS "vm$n" "vm$n-ctn$m"
      if [ $L -le 2 ]; then
	continue;
      fi
      for l in `seq 1 5`; do
	postInstance "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "image-spark" "192.168.$n.$m:32000-65535" "192.168.1.1:1000"
	postInstanceConfig5 "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
	#      postInstanceControl $IAAS "vm$n-ctn$m" "vm$n-spark$l"
      done
    done
  done
}

time create
postLinkImageOwner "$IaaS" "$BUILDER" "image-ctn"
postLinkImageOwner "$IaaS" "$BUILDER" "image-spark"
#
#
## create source for image-vm, image-spark, image-ctn, make image-builder the builder image
#
#
#
remove() {
  for n in `seq 1 $N`; do
    echo "deleting instance $n"
    if [ $L -gt 1 ]; then
      for m in `seq 1 5`; do
	if [ $L -gt 2 ]; then
	  for l in `seq 1 5`; do
	    #lazyDeleteInstance "192.168.$n.$m:1-65535" "vm$n-spark$l" "image-spark" "192.168.$n.$m:32000-65535" "192.168.1.1:1000"
	    delInstanceConfig5 "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
	    delInstance "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "image-spark" "192.168.$n.$m:32000-65535" "$IaaS"
	  echo -n
	  done
	  #lazyDeleteInstance "192.168.0.$n:1-65535" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "192.168.0.1:1000"
	  delInstanceConfig5 "192.168.0.$n:1-65535" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
	  delInstance "192.168.0.$n:1-65535" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "$IaaS"
	fi
      done
    fi
    #lazyDeleteInstance $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
    #delInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
    delVMInstance $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" $IaaS "vpc1"
    delInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
  done
}

#time remove #>/dev/null 2>&1