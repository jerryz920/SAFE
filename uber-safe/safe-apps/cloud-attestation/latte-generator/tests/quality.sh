#!/bin/bash

SAFE_ADDR=http://localhost:19851
IAAS=152.3.145.38:444
IaaS=152.3.145.38:444

source ./functions
source ./manual-functions


# configs
N=50
L=3
BUILDER="128.105.104.122:1-65535"

# endorse the source from "simulated instance" to simplify the test
postVMInstance $IAAS "vm-builder" "image-builder" "128.105.104.122:1-65535" "192.168.1.0/24" "vpc-builder" "noauth:vm"
postVMInstance $IAAS "vm-scanner" "image-scanner" "128.105.104.123:1-65535" "192.168.2.0/24" "vpc-scanner" "noauth:docker"
#postLinkImageOwner $IaaS "$BUILDER" "image-vm"
#postEndorsement "$BUILDER" "image-vm" "source" "https://github.com/jerryz920/boot2docker"
#postEndorsement "$BUILDER" "image-ctn" "source" "https://github.com/apache/spark"
#postEndorsement "$BUILDER" "image-spark" "source" "https://github.com/intel/hibench"

postEndorsementLink "noauth:vm" "vm-builder" "image-vm"
postEndorsementLink "noauth:docker" "vm-builder" "image-ctn"
postEndorsementLink "noauth:docker" "vm-scanner" "image-ctn"
postEndorsement "vm-builder" "image-vm" "source" "https://github.com/jerryz920/boot2docker.git#dev"
postEndorsement "vm-builder" "image-ctn" "source" "https://github.com/docker/ubuntu.git#xenial"
postEndorsement "vm-builder" "image-scanner" "source" "https://github.com/arminc/clair-scanner.git#master"

for n in `cat cve.out`; do
  m=`bash -c "echo $n"`
  postEndorsement "vm-scanner" "image-cnt" "cve" $m
done

create() {
  for n in `seq 1 $N`; do
    echo "posting instance $n"
    postVMInstance $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" "vpc1" "noauth:vm"
    postInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
    #  postInstanceControl $IAAS $IAAS "vm$n"
    if [ $L -le 1 ]; then
      continue;
    fi
    for m in `seq 1 50`; do
      postInstance "192.168.0.$n:1-65535" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" "noauth:docker"
      postInstanceConfig5 "192.168.0.$n:1-65535" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
    done
  done
}

time create

checkCodeQuality "noauth:codeworker" 192.168.1.2:3000








#postLinkImageOwner "$IaaS" "$BUILDER" "image-ctn"
#postLinkImageOwner "$IaaS" "$BUILDER" "image-spark"
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
	    lazyDeleteInstance "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" 
	    #delInstanceConfig5 "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
	    #delInstance "192.168.$n.$m:1-65535" "vm$n-ctn$m-spark$l" "image-spark" "192.168.$n.$m:32000-65535" 
	  echo -n
	  done
	  lazyDeleteInstance "vm$n" "vm$n-ctn$m" 
	  #delInstanceConfig5 "192.168.0.$n:1-65535" "vm$n-ctn$m" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4" "c5" "v5"
	  #delInstance "192.168.0.$n:1-65535" "vm$n-ctn$m" "image-ctn" "192.168.$n.$m:1-65535" 
	fi
      done
    fi
    lazyDeleteInstance $IAAS "vm$n" 
    #delInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
    #delVMInstance $IAAS "vm$n" "image-vm" "192.168.0.$n:1-65535" "192.168.$n.0/24" "vpc1"
    #delInstanceConfig4 $IaaS "vm$n" "c1" "v1" "c2" "v2" "c3" "v3" "c4" "v4"
  done
}

#time remove #>/dev/null 2>&1
