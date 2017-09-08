package sdx.core;

import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Consumes;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;

import sdx.utils.Exec;

import java.util.ArrayList;

/**
 * Root resource (exposed at "myresource" path)
 */
@Path("sdx")
public class RestService {
	
	  final static Logger logger = Logger.getLogger(Exec.class);	


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
      String[] res=SdxManager.stitchRequest(sr.sdxslice,sr.sdxnode, sr.ckeyhash, sr.cslice, sr.creservid, sr.secret);
      return new StitchResult(res[0],res[1]);
    }

    @POST
    @Path("/stitchcommunion")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public StitchResult stitchRequest(StitchCommunion sr){
      logger.debug("got communion stitch request: \n"+sr.toString());
      String[] res=SdxManager.stitchCommunion(sr.sdxslice, sr.sdxnode, sr.ckeyhash, sr.stitchport, sr.vlan,sr.gateway, sr.ip);
      return new StitchResult("","");
    }

    @POST
    @Path("/notifyprefix")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.TEXT_PLAIN)
    public String stitchRequest(PrefixNotification pn){
      logger.debug("got sittch request");
      String res=SdxManager.notifyPrefix(pn.dest, pn.gateway, pn.router, pn.customer);
      return res;
    }
}

class StitchCommunion{
  public  String sdxslice;
  public  String sdxnode;
  public  String ckeyhash;
  public  String stitchport;
  public  String vlan;
  public  String gateway;
  public String ip;

  public StitchCommunion(){}

  public StitchCommunion(String sdxslice, String sdxnode,String ckeyhash,String stitchport, String vlan, String gateway,String ip){
    this.sdxslice=sdxslice;
    this.sdxnode=sdxnode;
    this.ckeyhash=ckeyhash;
    this.stitchport=stitchport;
    this.vlan=vlan;
    this.gateway=gateway;
    this.ip=ip;
  }

  public String toString(){
    return "{\"sdxslice\": "+sdxslice+", \"sdxnode\": "+sdxnode+", \"ckeyhash\":"+ckeyhash+", \"stitchport\":"+stitchport+", \"vlan\":"+vlan+"\"gateway\":"+gateway+"}";
  }
}

class StitchRequest{
  public  String sdxslice;
  public  String sdxnode;
  //customer Safe key hash
  public  String ckeyhash;
  public  String cslice;
  public  String creservid;
  public  String secret;

  public StitchRequest(){}

  public StitchRequest(String sdxslice, String sdxnode,String ckeyhash, String cslice, String creserveid, String secret){
    this.sdxslice=sdxslice;
    this.sdxnode=sdxnode;
    this.ckeyhash=ckeyhash;
    this.cslice=cslice;
    this.creservid=creservid;
    this.secret=secret;
  }
}

class PrefixNotification{
  public String dest;
  public String gateway;
  public String router;
  public String customer;
  public PrefixNotification(){}
  public PrefixNotification(String dest, String gateway, String router, String customer){
    this.dest=dest;
    this.gateway=gateway;
    this.router=router;
    this.customer=customer;
  }
}

class StitchResult{
  public boolean result;
  public String gateway;
  public String ip;
  public StitchResult(){}
  public StitchResult(String gw, String ip){
    this.gateway=gw;
    this.ip=ip;
    if(gateway!=null && ip !=null)
      result=true;
    else
      result=false;
  }
}

