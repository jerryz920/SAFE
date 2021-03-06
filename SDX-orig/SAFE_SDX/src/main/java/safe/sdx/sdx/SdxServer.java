package safe.sdx.sdx;

import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.Properties;
import java.util.concurrent.locks.ReentrantLock;

import org.apache.log4j.ConsoleAppender;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.SimpleLayout;
import org.apache.commons.cli.*;
import org.apache.commons.cli.DefaultParser;

import org.renci.ahab.libndl.LIBNDL;
import org.renci.ahab.libndl.Slice;
import org.renci.ahab.libndl.SliceGraph;
import org.renci.ahab.libndl.extras.PriorityNetwork;
import org.renci.ahab.libndl.resources.common.ModelResource;
import org.renci.ahab.libndl.resources.request.BroadcastNetwork;
import org.renci.ahab.libndl.resources.request.ComputeNode;
import org.renci.ahab.libndl.resources.request.Interface;
import org.renci.ahab.libndl.resources.request.InterfaceNode2Net;
import org.renci.ahab.libndl.resources.request.Network;
import org.renci.ahab.libndl.resources.request.Node;
import org.renci.ahab.libndl.resources.request.StitchPort;
import org.renci.ahab.libndl.resources.request.StorageNode;
import org.renci.ahab.libtransport.ISliceTransportAPIv1;
import org.renci.ahab.libtransport.ITransportProxyFactory;
import org.renci.ahab.libtransport.JKSTransportContext;
import org.renci.ahab.libtransport.PEMTransportContext;
import org.renci.ahab.libtransport.SSHAccessToken;
import org.renci.ahab.libtransport.SliceAccessContext;
import org.renci.ahab.libtransport.TransportContext;
import org.renci.ahab.libtransport.util.ContextTransportException;
import org.renci.ahab.libtransport.util.SSHAccessTokenFileFactory;
import org.renci.ahab.libtransport.util.TransportException;
import org.renci.ahab.libtransport.util.UtilTransportException;
import org.renci.ahab.libtransport.xmlrpc.XMLRPCProxyFactory;
import org.renci.ahab.ndllib.transport.OrcaSMXMLRPCProxy;

import safe.sdx.utils.Exec;
import safe.sdx.utils.SafePost;

import java.rmi.RMISecurityManager;
import java.rmi.Naming;
import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;

import java.net.MalformedURLException;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;

/*

 * @author geni-orca
 * @author Yuanjun Yao, yjyao@cs.duke.edu
 * This is the server for carrier slice. It's run by the carrier_slice owner to do the following things
 * 1. Load carriers slice information from exogeniSM, compute the topology
 * 2. Public: Take stitch request from customer slice
 *    Input: Request(carrier_slicename, nodename/sitename,customer_auth_information)
 *    Output: yes or no
 *    Question: Shall carrier slice perform the stitching directly
 * 3. Private: Authorize stitching request:
 *    Call SAFE to authorize the request
 *
 * 4. Private Perform slice stitch
 *    Create a link for stitching
 *
 * 5. Get the connectivity list from SAFE
 *
 * 6. Call SDN controller to install the rules
 */

public class SdxServer extends Sdx implements ServiceAPI {
  public SdxServer()throws RemoteException{}

  private static RoutingManager routingmanager=new RoutingManager();
  private static HashMap<String, Link> links=new HashMap<String, Link>();
  private static String IPPrefix="192.168.";
  private static String mask="/24";
  private static String SDNController;
  private static String OVSController;
  private static String scriptsdir;
  private final ReentrantLock lock=new ReentrantLock();
  //private static String type;
  private static ArrayList<String[]> advertisements=new ArrayList<String[]>();

  private void addEntry_HashList(HashMap<String,ArrayList<String>>  map,String key, String entry){
    if(map.containsKey(key)){
      ArrayList<String> l=map.get(key);
      l.add(entry);
    }
    else{
      ArrayList<String> l=new ArrayList<String>();
      l.add(entry);
      map.put(key,l);
    }
  }

  private ArrayList<String[]> getAllElments_HashList(HashMap<String,ArrayList<String>>  map){
    ArrayList<String[]> res=new ArrayList<String[]>();
    for(String key:map.keySet()){
        for(String ip:map.get(key)){
          String[] pair=new String[2];
          pair[0]=key;
          pair[1]=ip;
          res.add(pair);
        }
    }
    return res;
  }

  private static  void computeIP(String prefix){
    String[] ip_mask=prefix.split("/");
    String[] ip_segs=ip_mask[0].split("\\.");
    IPPrefix=ip_segs[0]+"."+ip_segs[1]+".";
    curip=Integer.valueOf(ip_segs[2]);
  }
	
	public static void main(String [] args){
    
		System.out.println("Carrier Slice server with Service API: START");
    CommandLine cmd=parseCmd(args);
		String configfilepath=cmd.getOptionValue("config");
    SdxConfig sdxconfig=readConfig(configfilepath);
    IPPrefix=sdxconfig.ipprefix;
    scriptsdir=sdxconfig.scriptsdir;

    //type=sdxconfig.type;
    computeIP(IPPrefix);
		sliceProxy = SdxServer.getSliceProxy(pemLocation,keyLocation, controllerUrl);		
		//SSH context
		sctx = new SliceAccessContext<>();
		try {
			SSHAccessTokenFileFactory fac;
			fac = new SSHAccessTokenFileFactory(sshkey+".pub", false);
			SSHAccessToken t = fac.getPopulatedToken();			
			sctx.addToken("root", "root", t);
			sctx.addToken("root", t);
		} catch (UtilTransportException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    Slice keyhashslice = null;
    try {
      keyhashslice = Slice.loadManifestFile(sliceProxy, sliceName);
      ComputeNode safe=(ComputeNode)keyhashslice.getResourceByName("safe-server");
      safeserver=safe.getManagementIP()+":7777";
    } catch (ContextTransportException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    } catch (TransportException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
    //SDNControllerIP="152.3.136.36";
    SDNControllerIP=((ComputeNode)keyhashslice.getResourceByName("plexuscontroller")).getManagementIP();
    SDNController=SDNControllerIP+":8080";
    OVSController=SDNControllerIP+":6633";
    configRouting(keyhashslice,OVSController,SDNController,"(c\\d+)");

    try
    {
      SdxServer obj = new SdxServer(); 
      // Bind this object instance to the name "HelloServer" 
      Naming.rebind("ServiceServer_"+sliceName, obj); 
    }
    catch (Exception e)
    {
      System.out.println("HelloImpl err: " + e.getMessage()); 
      e.printStackTrace(); 
    }
	}

  public void notifyPrefix(String dest, String gateway, String router,String customer_) throws RemoteException{
    System.out.println("received notification for ip prefix"+dest);
    System.setProperty("java.security.policy",javasecuritypolicy);
    for(String[]pair:advertisements){
      if(authorizePrefix(pair[0],pair[1],customer_,dest)){
        routingmanager.configurePath(dest,router,pair[1],pair[3],gateway,SDNController);
        routingmanager.configurePath(pair[1],pair[3],dest,router,pair[2],SDNController);
      }
    }
    String[] newpair=new String[4];
    newpair[0]=customer_;
    newpair[1]=dest;
    newpair[2]=gateway;
    newpair[3]=router;
    advertisements.add(newpair);
  }

  private boolean authorizePrefix(String srchash, String srcip, String dsthash, String dstip){
    String[] othervalues=new String[4];
    othervalues[0]=srchash;
    othervalues[1]=dsthash;
    othervalues[2]=srcip;
    othervalues[3]=dstip;
    String message=SafePost.postSafeStatements(safeserver,"connectivity",keyhash,othervalues);
    if(message !=null && message.contains("Unsatisfied")){
      return false;
    }
    else
      return true;
  }

  public String stitchRequest(String carrierName,String nodeName, String customer_,String customerName, String ResrvID,String secret) {
    String res="";
    System.out.println("new request for"+carrierName +" and "+nodeName+pemLocation+keyLocation); 
    if(authorizeStitchRequest(customer_,customerName,ResrvID, keyhash,carrierName, nodeName)){
      Slice s1 = null;
      ISliceTransportAPIv1 sliceProxy = SdxServer.getSliceProxy(pemLocation,keyLocation, controllerUrl);		
      try {
        s1 = Slice.loadManifestFile(sliceProxy, carrierName);
      } catch (ContextTransportException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      } catch (TransportException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }
      ComputeNode node = (ComputeNode) s1.getResourceByName(nodeName);
      int interfaceNum=routingmanager.getRouter(nodeName).getInterfaceNum();
      lock.lock();
      String stitchname;
      int ip_to_use=curip;
      try{
        stitchname="stitch_"+nodeName+"_"+curip;
        curip++;
      }finally{
        lock.unlock();
      }
      Network net=s1.addBroadcastLink(stitchname);
      InterfaceNode2Net ifaceNode0 = (InterfaceNode2Net) net.stitch(node);
      ifaceNode0.setIpAddress("192.168.1.1");
      ifaceNode0.setNetmask("255.255.255.0");
      s1.commit();

      int N=0;
      net=(Network)s1.getResourceByName(stitchname);
      while(net.getState() != "Active" &&N<10){
        try {
          s1 = Slice.loadManifestFile(sliceProxy, carrierName);
        } catch (ContextTransportException e) {
          // TODO Auto-generated catch block
          e.printStackTrace();
        } catch (TransportException e) {
          // TODO Auto-generated catch block
          e.printStackTrace();
        }
        net=(Network)s1.getResourceByName(stitchname);
        for(Network l:s1.getBroadcastLinks()){
          System.out.println("Resource: " + l.getName() + ", state: "  + l.getState());
        }
        System.out.println(((Network)s1.getResourceByName(stitchname)).getState());
        sleep(5);
        N++;
      }
      sleep(10);
      Exec.sshExec("root",node.getManagementIP(),"/bin/bash ~/ovsbridge.sh "+OVSController,sshkey);
      routingmanager.replayCmds(routingmanager.getDPID(nodeName));
      Exec.sshExec("root",node.getManagementIP(),"ifconfig;ovs-vsctl list port",sshkey);
      String net1_stitching_GUID = net.getStitchingGUID();
      System.out.println("net1_stitching_GUID: " + net1_stitching_GUID);
      Link link=new Link();
      link.setName(stitchname);
      link.addNode(nodeName);
      link.setIP(IPPrefix+String.valueOf(ip_to_use));
      link.setMask(mask);
      links.put(stitchname,link);
      routingmanager.newLink(link.getIP(1), link.nodea, SDNController);
      String gw = link.getIP(1);
      String ip=link.getIP(2);
      stitch(customerName,ResrvID,carrierName,net1_stitching_GUID,secret,ip);
      res=res+gw+"_"+ip;
      routingmanager.configurePath(ip,nodeName,ip.split("/")[0],SDNController);
    }
    return res;
  }

	public static void stitch(String carrierName, String RID,String customerName, String CID,String secret,String newip){	
		System.out.println("ndllib TestDriver: START");
		//Main Example Code
    Long t1 = System.currentTimeMillis();
		try {
			//s2
			Properties p = new Properties();
			p.setProperty("ip", newip);
			sliceProxy.performSliceStitch(customerName, CID, carrierName, RID, secret, p);
		} catch (TransportException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    Long t2 = System.currentTimeMillis();
    System.out.println("Finished Stitching, set ip address of the new interface to "+newip+"  time elapsed: "+String.valueOf(t2-t1)+"\n");
    System.out.println("finished sending reconfiguration command");
	}

  public static boolean authorizeStitchRequest(String customer_,String customerName,String ReservID,String keyhash,String slicename, String nodename){
		/** Post to remote safesets using apache httpclient */
    String[] othervalues=new String[5];
    othervalues[0]=customer_;
    othervalues[1]=customerName;
    othervalues[2]=ReservID;
    othervalues[3]=slicename;
    othervalues[4]=nodename;
    String message=SafePost.postSafeStatements(safeserver,"verifyStitch",keyhash,othervalues);
    if(message ==null || message.contains("Unsatisfied")){
      return false;
    }
    else
      return true;
  }



  private static void restartPlexus(String plexusip){
    System.out.println("Restarting Plexus Controller");
    String script="docker exec -d plexus /bin/bash -c  \"cd /root/plexus/plexus;pkill ryu-manager;ryu-manager app.py |tee log\"\n";
    System.out.println(sshkey);
    System.out.println(plexusip);
    Exec.sshExec("root",plexusip,script,sshkey);
  }

  public static void configRouting(Slice s,String ovscontroller, String httpcontroller, String routerpattern){
    System.out.println("Configurating Routing");
    restartPlexus(SDNControllerIP);
    sleep(5);
    runCmdSlice(s,"/bin/bash ~/ovsbridge.sh "+ovscontroller,sshkey,"(c\\d+)");
    System.setProperty("java.security.policy",javasecuritypolicy);
    try{
      Pattern pattern = Pattern.compile(routerpattern);
      for(ComputeNode node : s.getComputeNodes()){
        Matcher matcher = pattern.matcher(node.getName());
        if (!matcher.find())
        {
          continue;
        }
        String mip= node.getManagementIP();
        System.out.println(node.getName()+" "+mip);
        Exec.sshExec("root",mip,"/bin/bash ~/ovsbridge.sh "+ ovscontroller,sshkey).split(" ");
        String[] result=Exec.sshExec("root",mip,"/bin/bash ~/dpid.sh",sshkey).split(" ");
        try{
          System.out.println("Get router info "+result[0]+" "+result[1]);
          routingmanager.newRouter(node.getName(),result[1],Integer.valueOf(result[0]));
        }catch(Exception e){
          e.printStackTrace();
        }
      }
      System.out.println("setting up links)");
      HashSet<Integer> usedip=new HashSet<Integer>();
      for(Interface i: s.getInterfaces()){
        InterfaceNode2Net inode2net=(InterfaceNode2Net)i;
        Link link=links.get(inode2net.getLink().toString());
        if(link==null){
          link=new Link();
          link.setName(inode2net.getLink().toString());
          link.addNode(inode2net.getNode().toString());
          if(link.linkname.contains("stitch")){
            String[] parts=link.linkname.split("_");
            String ip=parts[2];
            link.setIP(IPPrefix+ip);
            link.setMask(mask);
            usedip.add(Integer.valueOf(parts[2]));
          }
        }
        else{
          link.addNode(inode2net.getNode().toString());
        }
        links.put(inode2net.getLink().toString(),link);
        //System.out.println(inode2net.getNode()+" "+inode2net.getLink());
      }

      Set keyset=links.keySet();
      //System.out.println(keyset);
      System.out.println("Wait until all ovs bridges have connected to SDN controller");

      boolean flag=true;
      while(flag){
        flag=false;
        for(ComputeNode node : s.getComputeNodes()){
          Matcher matcher = pattern.matcher(node.getName());
          if (!matcher.find())
          {
            continue;
          }
          String mip= node.getManagementIP();
          String result=Exec.sshExec("root",mip,"ovs-vsctl show",sshkey);
          if(result.contains("is_connected: true")){
            System.out.println(node.getName() +" connected");
          }
          else{
            System.out.println(node.getName() +" not connected");
            flag=true;
          }
        }
      }

      for(Object k: keyset){
        Link link=links.get((String)k);
        if(!((String)k).contains("stitch")){
          while(usedip.contains(curip)){
            curip++;
          }
          link.setIP(IPPrefix+String.valueOf(curip));
          link.setMask(mask);
          curip++;
        }
        String param="";
        if(link.nodeb!=""){
          //System.out.println(link.nodea+":"+link.getIP(1)+" "+link.nodeb+":"+link.getIP(2));
          routingmanager.newLink(link.getIP(1), link.nodea, link.getIP(2), link.nodeb, httpcontroller);
        }
        else{
          //System.out.println(link.nodea+" gateway address:"+link.getIP(1));
          routingmanager.newLink(link.getIP(1), link.nodea, httpcontroller);
        }
      }
    }catch(Exception e){
      e.printStackTrace();
    }
  }

	

	public static void undoStitch(String carrierName, String customerName, String netName, String nodeName){	
		System.out.println("ndllib TestDriver: START");
		
		//Main Example Code
		
		Slice s1 = null;
		Slice s2 = null;
		
		try {
			s1 = Slice.loadManifestFile(sliceProxy, carrierName);
			s2 = Slice.loadManifestFile(sliceProxy, customerName);
		} catch (ContextTransportException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (TransportException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
    }
				
		Network net1 = (Network) s1.getResourceByName(netName);
		String net1_stitching_GUID = net1.getStitchingGUID();
		
		ComputeNode node0_s2 = (ComputeNode) s2.getResourceByName(nodeName);
		String node0_s2_stitching_GUID = node0_s2.getStitchingGUID();
		
		System.out.println("net1_stitching_GUID: " + net1_stitching_GUID);
		System.out.println("node0_s2_stitching_GUID: " + node0_s2_stitching_GUID);
    Long t1 = System.currentTimeMillis();
			
		try {
			//s1
			//sliceProxy.permitSliceStitch(carrierName, net1_stitching_GUID, "stitchSecret");
			//s2
			sliceProxy.undoSliceStitch(customerName, node0_s2_stitching_GUID, carrierName, net1_stitching_GUID);
		} catch (TransportException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    Long t2 = System.currentTimeMillis();
    System.out.println("Finished UnStitching, time elapsed: "+String.valueOf(t2-t1)+"\n");
	}
}

