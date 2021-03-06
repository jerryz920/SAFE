---------------SAFE-SDX-----------------------------
To run the SDX demo, first we creat a SDX slice and two customer slices on exogeni.

[1] Run riak-server
    Launch a riak server with code and instructions in SAFE-Riak-Server

Configuration: set variables in "SAFE/configure" and run it. It will generate configuration files for sdx, alice and bob and put them in their config directory

  [2] Create a SDX slice
  a) $cd SDX-Simple
  b) Edit configuration file for sdx slice "config/sdx.conf"
  c) build
     $./scripts/build.sh
  d) create SDX slice
     $./scritps/createslice.sh -c config/sdx.conf

  [3] Create two customer slices
  a) $cd SDX-Client-ExoGENI
  b) Edit configuration files for alice and bob, "config/alice.conf" and "config/bob.conf" 
  c) build
     $./scripts/build.sh
  d) create alice slice and bob slice
     $./scripts/createslice.sh -c config/alice.conf
     $./scripts/createslice.sh -c config/bob.conf

     Then we can run ahab controllers for sdx, alice and bob. 
 [4] Run sdx server controller, configure the address and port number that sdx server will listen on ("config.serverurl").
     $./scripts/sdxserver.sh -c config/sdx.conf

 [5] Configure the address of SDX server controller ("config.sdxserver") in configuration files and run controller for alice and bob, 
     $./scripts/sdxclient.sh -c config/alice.conf
     $./scripts/sdxclient.sh -c config/bob.conf

 [6]. post SAFE identity sets, make SAFE statements to state the stitching and traffic policies, allocation of IP prefixes and stitching requests.
    $ cd safe-scripts 
    
    Edit the SAFESERVER ip address to your safe server IP address in idset.sh, post.sh and updatess.sh, and run following scripts to make posts to safesets. Messages with a token in each message are expected.
    $ ./trustedparty.sh
    $ ./sdx.sh
    $ ./alice.sh
    $ ./bob.sh

  7. alice stitch CNode0 to sdx/c0, in alice's controller, run:
    $>stitch CNode0 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c0]
    bob stitch CNode0 to sdx/c3, in bob's controller run:
    $>stitch CNode [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3]
    
    OR the following commands are equivalent:
    ./scripts/sdxclient.sh -c config/alice.conf -e "stitch CNode0 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c0]"
    ./scripts/sdxclient.sh -c config/bob.conf -e "stitch CNode0 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3]"

  8. route
    alice tells sdx controller its address space
    $>route 192.168.10.1/24 192.168.33.2 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c0]
    bob tells sdx controller its address space
    $>route 192.168.20.1/24 192.168.34.2 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3]
    
    OR the following commands are equivalent:
    ./scripts/sdxclient.sh -c config/alice.conf -e "route 192.168.10.1/24 192.168.33.2 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c0]"
    ./scripts/sdxclient.sh -c config/bob.conf -e "route 192.168.20.1/24 192.168.34.2 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3]"

  9. [OPTIONAL]
    For sdx demo, I added scripts to automatically configure the routing table with quagga in client slice. These scripts depends on the IP addresses assigned to client slice, the topology of client slice, which node in client slice is stitched to sdx slice, and the gateway in sdx slice.
    
    Setup routing in client side:
    An example command of adding an entry to the routing table is as follows, this only supports dest IP address with /32 netmask
    Another way to do this is using Quagga with zebra enabled, and add routing entries in zebra.conf, dest ip with any netmask is supported
    
    In the demo, to enable communication between CNode1 in alice and CNode1 in bob, the commands are:
    CNode1-alice$ ip route add 192.168.20.2/32 via 192.168.10.1
    CNode0-alice$ ip route add 192.168.20.2/32 via 192.168.33.1
    CNode1-bob$  ip route add 192.168.10.2/32 via 192.168.20.1
    CNode0-bob$ ip route add 192.168.10.2/32 via 192.168.34.1

  10. Delete a slice
    We can delete a slice with command: ./scripts/createslice.sh -c configFile -d
    For exmaple: ./scripts/createslice.sh -c config/alice.conf -d


    ============Stitching External Sites (Chameleon, Duke, ESNet...) to Exogeni=============

[1] Run riak-server
    Launch a riak server with code and instructions in SAFE-Riak-Server

Configuration: set variables in "SAFE/configure" and run it. It will generate configuration files for sdx, alice and bob and put them in their config directory

[2] Create a SDX slice
  a) $cd SDX-Simple
  b) Edit configuration file for sdx slice "config/sdx.conf"
  c) build
     $./scripts/build.sh
  d) create SDX slice
     $./scritps/createslice.sh -c config/sdx.conf

[3] Run sdx server controller, configure the address and port number that sdx server will listen on ("config.serverurl").
     $./scripts/sdxserver.sh -c config/sdx.conf
     
     NOTE: when running HTTP server on ExoGENI, use serverurl=0.0.0.0:8080.

[4] post SAFE identity sets, make SAFE statements to state the stitching and traffic policies, allocation of IP prefixes and stitching requests.
    $ cd safe-scripts 
    $ ./trustedparty.sh SAFEServerIP
    $ ./sdx.sh SAFEServerIP
    $ ./carrot.sh SAFEServerIP

[5] Specify the ip address of safe server for Chameleon controller in SDX-Client-StitchPort/config/carrot.conf
    Configure the address of SDX server controller ("config.sdxserver") in SDX-Client-StitchPort/config/carrot.conf 

[6] Stitching Chameleon Node to  SDX slice
    1) First, create a Chameleon node, using vlan tag "3298"
    2) For Chameleon slice, we need another safe server for it (In this demo, we use the SAFE server in SDX slice for everything, therefore, this step is skipped). 
    3) Build chameleon controller:
       a) ./scripts/build.sh
       b) $ ./scripts/run.sh -c config/carol.conf
        >stitch http://geni-orca.renci.org/owl/ion.rdf#AL2S/Chameleon/Cisco/6509/GigabitEthernet/1/1 3298 [SDX_SLICE_NAME, e.g., sdx] c3 [Cameleon_Node_IP] 10.32.98.200/24
        OR
        $./scripts/run.sh -c config/carol.conf -e "stitch http://geni-orca.renci.org/owl/ion.rdf#AL2S/Chameleon/Cisco/6509/GigabitEthernet/1/1 3298 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3] 10.32.98.204 10.32.98.200/24"

[7] When stitching a chameleon node to exogeni node, we know the ip address of the chameleon node, say "10.32.98.204". 
    In the stitching request, we tell the sdx controller what IP address it should use for the new interface on c3 to the stitchport, we can specify any address in the same subnet as the chameleon node, say "10.32.98.200"
        The topology is like this:
        c0-c1-c2-c3 (10.32.98.200/24)----stitchport----(10.32.98.204/24)ChameleonNode
        Note that in sdx server, we use SDN controller to configure the ip address. The ip address is not configured for the physical interface, so we can't ping from exogeni node to chameleon node. But we can ping from the Chameleon node to the exogeni node.

      a) Chameleon slice advertises its ip prefixes in the same way as ExoGENI slice does
        $./scripts/run.sh -c config/carol.conf -e "route 10.32.98.1/24 10.32.98.204 [SDX_SLICE_NAME, e.g., sdx] [STITCH_POINT, e.g., c3]"
      b) Chameleon node set up routing table when it wants to talk with exogeni slices in different subnets

NOTE: Now we have "-n" option for sdx server and both clients, which can be used to DISABLE SAFE AUTHORIZATION



