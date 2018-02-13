package sdx.core;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Consumes;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import org.apache.log4j.Logger;

/**
 * Root resource (exposed at "myresource" path)
 */
@Path("sdx")
public class RestService {

	  final static Logger logger = Logger.getLogger(RestService.class);	


    /** 
     * Method handling HTTP GET requests. The returned object will be sent
     * to the client as "text/plain" media type.
     *
     * @return String that will be returned as a text/plain response.
     */
    //Test API
    @GET
    @Produces(MediaType.TEXT_PLAIN)
    public String getIt() {
        return "Got it!";
    }

    //Test API
    @GET
    @Path("/sr")
    @Produces(MediaType.APPLICATION_JSON)
    public StitchRequest getJson() {
      logger.debug("json get");

        return new StitchRequest("1","2","3","4","5","6");
    }

    @POST
    @Path("/stitchrequest")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public StitchResult stitchRequest(StitchRequest sr){
      logger.debug("got sittch request");
      try {
        String[] res = SdxServer.sdxManager.stitchRequest(sr.sdxslice, sr.sdxsite, sr.ckeyhash, sr
            .cslice,
          sr.creservid, sr.secret,sr.sdxnode);
        return new StitchResult(res[0], res[1]);
      }catch (Exception e){
        e.printStackTrace();
        return new StitchResult(null,null);
      }
    }

  @POST
  @Path("/connectionrequest")
  @Consumes(MediaType.APPLICATION_JSON)
  @Produces(MediaType.TEXT_PLAIN)
  public String connectionRequest(ConnectionRequest sr){
    logger.debug("got link request between "+sr.self_prefix+" and "+sr.target_prefix);
    System.out.println("got link request between "+sr.self_prefix+" and "+sr.target_prefix);
    try {
      String res = SdxServer.sdxManager.connectionRequest(sr.ckeyhash,sr.self_prefix,sr
        .target_prefix,sr
        .bandwidth);
      return res;
    }catch (Exception e){
      e.printStackTrace();
      return e.getMessage();
    }
  }

    @POST
    @Path("/stitchchameleon")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.TEXT_PLAIN)
    public String stitchRequest(StitchChameleon sr){
      logger.debug("got chameleon stitch request: \n"+sr.toString());
      System.out.println(String.format("got chameleon stitch request from %s", sr.ckeyhash));
      String res=SdxServer.sdxManager.stitchChameleon(sr.sdxslice, sr.sdxnode, sr.ckeyhash, sr
          .stitchport,
        sr.vlan,sr.gateway, sr.ip);
      //return new StitchResult("ha","ha");
      return res;
    }

    @POST
    @Path("/notifyprefix")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.TEXT_PLAIN)
    public String stitchRequest(PrefixNotification pn){
      logger.debug("got notifyprefix");
      String res=SdxServer.sdxManager.notifyPrefix(pn.dest, pn.gateway,  pn.customer);
      logger.debug(res);
      System.out.println(res);
      return res;
    }
}

class StitchChameleon {
  public String sdxslice;
  public String sdxnode;
  public String ckeyhash;
  public String stitchport;
  public String vlan;
  public String gateway;
  public String ip;

  public StitchChameleon() {
  }

  public StitchChameleon(String sdxslice, String sdxnode, String ckeyhash, String stitchport, String vlan, String gateway, String ip) {
    this.sdxslice = sdxslice;
    this.sdxnode = sdxnode;
    this.ckeyhash = ckeyhash;
    this.stitchport = stitchport;
    this.vlan = vlan;
    this.gateway = gateway;
    this.ip = ip;
  }

  public String toString() {
    return "{\"sdxslice\": " + sdxslice + ", \"sdxnode\": " + sdxnode + ", \"ckeyhash\":" + ckeyhash + ", \"stitchport\":" + stitchport + ", \"vlan\":" + vlan + "\"gateway\":" + gateway + "}";
  }
}

class StitchRequest{
  public  String sdxslice;
  public  String sdxsite;
  //customer Safe key hash
  public  String ckeyhash;
  public  String cslice;
  public  String creservid;
  public String sdxnode;

  public  String secret;

  public StitchRequest(){}

  public StitchRequest(String sdxslice, String sdxsite,String ckeyhash, String cslice, String creserveid, String secret){
    this.sdxslice=sdxslice;
    this.sdxsite=sdxsite;
    this.ckeyhash=ckeyhash;
    this.cslice=cslice;
    this.creservid=creservid;
    this.secret=secret;
    this.sdxnode=null;
  }
  public StitchRequest(String sdxslice, String sdxsite,String ckeyhash, String cslice, String creserveid, String secret,String sdxnode){
    this.sdxslice=sdxslice;
    this.sdxsite=sdxsite;
    this.ckeyhash=ckeyhash;
    this.cslice=cslice;
    this.creservid=creservid;
    this.secret=secret;
    this.sdxnode=sdxnode;
  }
}

class ConnectionRequest{
  public  String ckeyhash;
  public String self_prefix;
  public String target_prefix;
  public long bandwidth;

  public ConnectionRequest(){}

  public ConnectionRequest(String self_prefix, String target_prefix){
    this.self_prefix=self_prefix;
    this.target_prefix=target_prefix;
    this.bandwidth=0;
  }

  public ConnectionRequest(String self_prefix, String target_prefix,long bandwidth){
    this.self_prefix=self_prefix;
    this.target_prefix=target_prefix;
    this.bandwidth=bandwidth;
  }

}

class PrefixNotification{
  public String dest;
  public String gateway;
  public String customer;
  public PrefixNotification(){}
  public PrefixNotification(String dest, String gateway, String customer){
    this.dest=dest;
    this.gateway=gateway;
    this.customer=customer;
  }
}

class StitchResult {
  public boolean result;
  public String gateway;
  public String ip;

  public StitchResult() {
  }

  public StitchResult(String gw, String ip) {
    this.gateway = gw;
    this.ip = ip;
    if (gateway != null && ip != null)
      result = true;
    else
      result = false;
  }
}

