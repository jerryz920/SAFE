package test;
import java.util.ArrayList;
import client.exogeni.SdxExogeniClientManager;
import client.stitchport.SdxStitchPortClient;
import client.stitchport.SdxStitchPortClientManager;
import sdx.core.SdxServer;
import client.exogeni.ClientSlice;

public class TestMain {
  /*
  static String state = "fl";
  static String site1 = "ufl";
  static String site2 = "unf";
  */
  //name of sdx slice
  static String[] arg1 = {"-c", "config/sdx.conf"};
  static String[] clientarg1 = {"-c", "client-config/c1.conf"};
  static String[] clientarg2 = {"-c", "client-config/c2.conf"};
  static String[] clientarg3 = {"-c", "client-config/c3.conf"};
  static String[] clientarg4 = {"-c", "client-config/c4.conf"};
  static boolean newSlice = true;
  static boolean stitch = true;

  public static void main(String[] args){
    multiSliceTest();
    System.exit(0);
  }


  public static void multiSliceTest(){
    if(newSlice) {
      deleteSlice();
      createTestSliceParrallel();
    }
    test();
  }

  public static void test(){
    /*
    In this function, we create ahab controller for sdx slice and client slices.
    We execute command in client controller to request network stitching to sdx slice,
    advertise the ip prefix, and request for network connection
     */
    // Start Sdx Server
    SdxServer.run(arg1);
    String sdx = SdxServer.sdxManager.getSliceName();
    SdxExogeniClientManager client1 = new SdxExogeniClientManager(clientarg1);
    SdxExogeniClientManager client2 = new SdxExogeniClientManager(clientarg2);
    SdxExogeniClientManager client3 = new SdxExogeniClientManager(clientarg3);
    SdxExogeniClientManager client4 = new SdxExogeniClientManager(clientarg4);

    if(stitch) {
      System.out.println("c1 stitches to SDX");
      client1.processCmd("stitch CNode0 " + sdx + " c0");
      System.out.println("c2 stitches to SDX");
      client2.processCmd("stitch CNode0 " + sdx + " c1");
      System.out.println("c3 stitches to SDX");
      client3.processCmd("stitch CNode0 " + sdx + " c0");
      System.out.println("c4 stitches to SDX");
      client4.processCmd("stitch CNode0 " + sdx + " c1");
    }

    // client slice advertise their prefix
    client1.processCmd("route 192.168.10.1/24 192.168.131.2");
    client2.processCmd("route 192.168.20.1/24 192.168.132.2");
    client3.processCmd("route 192.168.30.1/24 192.168.133.2");
    client4.processCmd("route 192.168.40.1/24 192.168.134.2");

    // Client request for connection between prefixes
    client3.processCmd("link 192.168.30.1/24 192.168.40.1/24");
    client1.processCmd("link 192.168.10.1/24 192.168.20.1/24");
    /*
    SdxServer.sdxManager.removePath("192.168.30.1/24", "192.168.40.1/24");
    client1.processCmd("link 192.168.30.1/24 192.168.40.1/24 10000");
    */

    SdxServer.sdxManager.setMirror(SdxServer.sdxManager.getDPID("c0"), "192.168.30.1/24",
      "192.168.40.1/24", 400000000);

    SdxServer.sdxManager.setMirror(SdxServer.sdxManager.getDPID("c0"), "192.168.10.1/24",
      "192.168.20.1/24", 400000000);

    // Stop Sdx server and exit
  }


  public static void deleteSlice(){
    TestSlice ts = new TestSlice(arg1);
    ClientSlice s1 =  new ClientSlice(clientarg1);
    ClientSlice s2 = new ClientSlice(clientarg2);
    ClientSlice s3 =  new ClientSlice(clientarg3);
    ClientSlice s4 = new ClientSlice(clientarg4);
    //ClientSlice s6 = new ClientSlice(clientarg6);
    ts.delete();
    s1.delete();
    s2.delete();
    s3.delete();
    s4.delete();
    //s6.delete();
  }

  public static void createTestSliceParrallel(){
    ArrayList<Thread> tlist = new ArrayList<Thread>();
    Thread thread1 = new Thread() {
      @Override
      public void run() {
        TestSlice ts = new TestSlice(arg1);
        ts.run(arg1);
      }
    };
    thread1.start();
    tlist.add(thread1);
    SdxServer.sdxManager.sleep(10);

    String[][] args = {clientarg1, clientarg2, clientarg3, clientarg4};
    for(int i = 0 ; i< 4; i++) {
      final String[] arg = args[i];
      Thread thread2 = new Thread() {
        @Override
        public void run() {
          ClientSlice s1 = new ClientSlice(arg);
          s1.run();
        }
      };
      thread2.start();
      tlist.add(thread2);
      SdxServer.sdxManager.sleep(10);
    }

    try {
      for (Thread t : tlist) {
        t.join();
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    System.out.println("Finished create vSDX slice and client slices");
  }
}
