
//////////////////////////////////////////////////////
// Enviroments
//////////////////////////////////////////////////////
// Envs from Latte default
defenv IaaS() :- "152.3.145.38:444".
defenv IaaSGid() :- "0".
defenv PropertySource() :- "source".
defenv PropertyBuilder() :- "builder".
defenv PropertyAttester() :- "attester".
defenv PropertyNossh() :- "nossh".
defenv PropertyDns() :- "dns".
defenv PropertyVpcId() :- "vpcid".
defenv PropertyPackage() :- "package".
defenv PropertyPackageVersion() :- "packageVersion".
defenv PropertyPackageSource() :- "packageSource".
// Envs from external endorsements: pageRankSourceSet
defenv PageRankJobSource() :- "https://github.com/intel/hibench.git".
defenv PageRankSourceEndorser() :- "0x12345678".
// Envs from external endorsements: attesterSet
defenv SparkSource() :- "https://github.com/apache/spark.git#dev".
// Envs from external endorsements: tapconSet
defenv TapConSource() :- "https://github.com/jerryz920/boot2docker.git#dev".
defenv TapConDockerSource() :- "https://github.com/jerryz920/docker.git#dev".
defenv TapConLinuxSource() :- "https://github.com/jerryz920/linux.git#tapcon-v4.4.39".
// Envs from external endorsements: MembershipGuardRuleSet
defenv MasterSource() :- "https://github.com/apache/spark.git#dev".
defenv JoinerGuard() :- "joinguardtext".
defenv WorkerSource() :- "https://github.com/apache/spark.git#dev".
defenv OwnerGuard() :- "ownerguardtext".

//////////////////////////////////////////////////////
// Rulesets
//////////////////////////////////////////////////////
// Rulesets of Latte library

defcon consTrustWallet() :-
  ?Auxlabel0 := label("endorsements/$PageRankJobSource"),
  ?Auxlabel1 := label("endorsements/$SparkSource"),
  ?Auxlabel2 := label("endorsements/$TapConSource"),
  {
    label("trustWallet").
    trustedCloudProvider($IaaS).
    trustedCloudProvider($IaaSGid).
    tapconImageSource("https://github.com/jerryz920/boot2docker.git#dev").
    tapconDaemonSource("https://github.com/jerryz920/docker.git#tapcon").
    tapconKernelSource("https://github.com/jerryz920/linux.git#tapcon-v4.4").
    approvedDns("8.8.8.8").
    builderImage("2d9307d7-d30b-496e-952f-c4b6c5590bbe").
    builderSource("https://github.com/jerryz920/boot2docker.git#dev").
    buildsFrom("2d9307d7-d30b-496e-952f-c4b6c5590bbe","https://github.com/jerryz920/boot2docker.git#dev").
    link($Auxlabel0).
    link($Auxlabel1).
    link($Auxlabel2).
  }.

definit consTrustWallet().

defcon consLibraryRules() :-
  {
    label("libraryRules").

    hasConfig(Instance, ConfName, ConfValue) :-
      H : config(Instance, ConfName, ConfValue),
      attester(H).

    launches(Instance, Image) :-
      H : runs(Instance, Image),
      attester(H).

    attester(Instance) :-
      checkProperty(Instance, $PropertyAttester, 1).

    attester(Instance) :-
      trustedCloudProvider(Instance).

    builder(Instance) :-
      checkProperty(Instance, $PropertyBuilder, 1).

    builder(Instance) :-
      launches(Instance, Image),
      builderImage(Image).

    builder(Instance) :-
      launches(Instance, Image),
      buildsFrom(Image, Source),
      builderSource(Source).

    buildsFrom(Image, Source) :-
      B : endorse(Image, $PropertySource, Source),
      builder(B).

    packageBuildsFrom(Image, Package, Source) :-
      packageSource(Image, Package, Source).

    packageBuildsFrom(Image, Package, Source) :-
      buildsFrom(Image, ISource),
      packageSource(ISource, Package, Source).

    imageProperty(Image, Property, Value) :-
      endorse(Image, Property, Value).

    imageProperty(Image, Property, Value) :-
      buildsFrom(Image, Source),
      endorse(Source, Property, Value).

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      endorse(Image, Property, Value).

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      buildsFrom(Image, Source),
      endorse(Source, Property, Value).

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      parameterizedEndorse(Image, Property, ConfName),
      hasConfig(Instance, ConfName, Value).

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      buildsFrom(Image, Source),
      parameterizedEndorse(Source, Property, ConfName),
      hasConfig(Instance, ConfName, Value).

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      endorseIfEqual(Image, Key, Expected, Property, Value),
      hasConfig(Instance, Key, Real),
      Real = Expected.

    checkProperty(Instance, Property, Value) :-
      launches(Instance, Image),
      buildsFrom(Image, Source),
      endorseIfEqual(Source, Key, Expected, Property, Value),
      hasConfig(Instance, Key, Real),
      Real = Expected.

    sourceCheck(Instance, Package, Source) :-
      launches(Instance, Image),
      packageBuildsFrom(Image, Package, Source).

    sourceCheck(Instance, Package, Source) :-
      launches(Instance, Image),
      buildsFrom(Image, ISource),
      packageBuildsFrom(ISource, Package, Source).

    versionCheck(Instance, Package, Version) :-
      launches(Instance, Image),
      packageVersion(Image, Package, Source).

    versionCheck(Instance, Package, Version) :-
      launches(Instance, Image),
      buildsFrom(Image, ISource),
      packageVersion(ISource, Package, Source).

    memberCheck(Instance, Cluster, Master) :-
      Master : member(Cluster, Instance),
      Instance : join(Cluster, Master).

    memberCheck(Instance, Cluster, Master) :-
      Master : member(Cluster, Instance),
      trustedCloudProvider(Master).

    connection(Instance, Package, Ep) :-
      launches(Instance, Image),
      parameterizedConnection(Image, Package, ConfKey),
      hasConfig(Instance, ConfKey, Ep).

    connection(Instance, Package, Ep) :-
      launches(Instance, Image),
      buildsFrom(Image, Source),
      parameterizedConnection(Source, Package, ConfKey),
      hasConfig(Instance, ConfKey, Ep).
  }.

definit consLibraryRules().
// Rulesets of external endorsements: pageRankSourceSet

defcon consPageRankSourceSet() :-
  {
    label("endorsements/$PageRankJobSource").
    parameterizedEndorse($PageRankJobSource, "inFile", "cmdArg1").
    parameterizedEndorse($PageRankJobSource, "outFile", "cmdArg2").
    parameterizedColumnUsed($PageRankJobSource, "cmdArg1", "url").
    parameterizedColumnUsed($PageRankJobSource, "cmdArg1", "neighbor").
    parameterizedColumnAggregated($PageRankJobSource, "cmdArg1", "url", "count").
    endorse($PageRankJobSource, "stateless", 1).
    parameterizedOutputGuard($PageRankJobSource, "cmdArg2", "outputGuard").

    columnUsed(Instance, InFileName, ColName) :-
      parameterizedColumnUsed($PageRankJobSource, InFileArg, ColNameArg),
      launches(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, InFileArg, InFileName),
      hasConfig(Instance, ColNameArg, ColName).

    columnAggregated(Instance, InFileName, ColName, OpText) :-
      parameterizedColumnAggregated($PageRankJobSource, InFileArg, ColNameArg, OpText),
      launches(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, InFileArg, InFileName),
      hasConfig(Instance, ColNameArg, ColName).

    runsOutputGuard(Instance, OutFileName, GuardText) :-
      parameterizedOutputGuard($PageRankJobSource, OutFileArg, GuardConfName),
      launches(Instance, Image),
      buildsFrom(Image, $PageRankJobSource),
      hasConfig(Instance, OutFileArg, OutFileName),
      hasConfig(Instance, GuardConfName, GuardText).
  }.

definit consPageRankSourceSet().
// Rulesets of external endorsements: attesterSet

defcon consAttesterSet() :-
  {
    label("endorsements/$SparkSource").
    endorse($SparkSource, "attester", 1).
  }.

definit consAttesterSet().
// Rulesets of external endorsements: tapconSet

defcon consTapconSet() :-
  {
    label("endorsements/$TapConSource").
    kernelBuildConfig($TapConSource, "namespace", 1).
    kernelBuildConfig($TapConSource, "selinux", 1).
    kernelBuildConfig($TapConSource, "seccomp", 1).
    kernelBuildConfig($TapConSource, "apparmor", 1).
    kernelBuildConfig($TapConSource, "portext", 1).
    endorse($TapConSource, $PropertyNossh, 1).
    endorse($TapConSource, $PropertyDns, "8.8.8.8").
    endorse($TapConSource, $PropertyPackage, "docker").
    endorse($TapConSource, $PropertyPackage, "dhcpcd").
    endorse($TapConSource, $PropertyPackage, "syslog").
    endorse($TapConSource, $PropertyPackage, "libc").
    packageSource($TapConSource, "linux", $TapConLinuxSource).
    packageSource($TapConSource, "docker", $TapConDockerSource).
    packageVersion($TapConSource, "linux", "4.4.39").
    packageVersion($TapConSource, "syslog", "3.9.1").
    packageVersion($TapConSource, "dhcpcd", "7.0.1").
    packageVersion($TapConSource, "libc", "2.6.0").
    parameterizedConnection($TapConSource, "docker", "imageRepo").
    endorse($TapConSource, "attester", 1).
  }.

definit consTapconSet().
// Rulesets of external endorsements: MembershipGuardRuleSet

defcon consMembershipGuardRuleSet() :-
  {
    label("MembershipGuardRuleSet").
    trustedMasterSource($MasterSource).
    trustedWorkerSource($WorkerSource).
    trustedOwnerGuard($OwnerGuard).
    trustedJoinerGuard($JoinerGuard).

    trustedCluster(Instance) :-
      launches(Instance, ImageW),
      buildsFrom(ImageW, SourceW),
      trustedWorkerSource(SourceW),
      Instance : join(ClusterID, Master),
      Master : member(ClusterID, Instance),
      masterRunsSource(Master).

    masterRunsSource(Master) :-
      Master : cluster(ClusterID, GuardO, GuardJ),
      trustedOwnerGuard(GuardO),
      trustedJoinerGuard(GuardJ),
      launches(Master, Image),
      buildsFrom(Image, Source),
      trustedMasterSource(Source).
  }.

definit consMembershipGuardRuleSet().

//////////////////////////////////////////////////////
// Interfaces for attestations
//////////////////////////////////////////////////////

defcon consInstance(?Instance,?Image,?TrustHub) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  ?HubSet := label(?TrustHub, "trusthub"),
  {
    link($HostSet).
    link($HubSet).
    runs($Instance, $Image).
    label("instance/$Instance").
  }.

defcon dtorInstance(?Instance,?Image,?TrustHub) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  ?HubSet := label(?TrustHub, "trusthub"),
  {
    link($HostSet)~
    link($HubSet)~
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstance(?Instance,?Image,?TrustHub) :- [ consInstance(?Instance,?Image,?TrustHub) ].
defpost delInstance(?Instance,?Image,?TrustHub) :- [ dtorInstance(?Instance,?Image,?TrustHub) ].


defcon consVMInstance(?Instance,?Image,?Vpc,?TrustHub) :-
  ?VpcSet := label("vpc/?Vpc"),
  ?HubSet := label(?TrustHub, "trusthub"),
  {
    link($VpcSet).
    link($HubSet).
    root("$IaaS").
    config($Instance,$PropertyVpcId, $Vpc).
    runs($Instance, $Image).
    label("instance/$Instance").
  }.

defcon dtorVMInstance(?Instance,?Image,?Vpc,?TrustHub) :-
  ?VpcSet := label("vpc/?Vpc"),
  ?HubSet := label(?TrustHub, "trusthub"),
  {
    link($VpcSet)~
    link($HubSet)~
    root("$IaaS")~
    config($Instance,$PropertyVpcId, $Vpc)~
    runs($Instance, $Image)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postVMInstance(?Instance,?Image,?Vpc,?TrustHub) :- [ consVMInstance(?Instance,?Image,?Vpc,?TrustHub) ].
defpost delVMInstance(?Instance,?Image,?Vpc,?TrustHub) :- [ dtorVMInstance(?Instance,?Image,?Vpc,?TrustHub) ].


defcon consVpcConfig1(?Vpc,?Config1,?Value1) :-
  {
    config($Vpc, $Config1, $Value1).
    label("vpc/$Vpc").
  }.

defcon dtorVpcConfig1(?Vpc,?Config1,?Value1) :-
  {
    config($Vpc, $Config1, $Value1)~
    label("vpc/$Vpc").
    invalid(1).
  }.

defpost postVpcConfig1(?Vpc,?Config1,?Value1) :- [ consVpcConfig1(?Vpc,?Config1,?Value1) ].
defpost delVpcConfig1(?Vpc,?Config1,?Value1) :- [ dtorVpcConfig1(?Vpc,?Config1,?Value1) ].


defcon consVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) :-
  {
    config($Vpc, $Config1, $Value1).
    config($Vpc, $Config2, $Value2).
    label("vpc/$Vpc").
  }.

defcon dtorVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) :-
  {
    config($Vpc, $Config1, $Value1)~
    config($Vpc, $Config2, $Value2)~
    label("vpc/$Vpc").
    invalid(1).
  }.

defpost postVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) :- [ consVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) ].
defpost delVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) :- [ dtorVpcConfig2(?Vpc,?Config1,?Value1,?Config2,?Value2) ].


defcon consVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :-
  {
    config($Vpc, $Config1, $Value1).
    config($Vpc, $Config2, $Value2).
    config($Vpc, $Config3, $Value3).
    label("vpc/$Vpc").
  }.

defcon dtorVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :-
  {
    config($Vpc, $Config1, $Value1)~
    config($Vpc, $Config2, $Value2)~
    config($Vpc, $Config3, $Value3)~
    label("vpc/$Vpc").
    invalid(1).
  }.

defpost postVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :- [ consVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) ].
defpost delVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :- [ dtorVpcConfig3(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) ].


defcon consVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :-
  {
    config($Vpc, $Config1, $Value1).
    config($Vpc, $Config2, $Value2).
    config($Vpc, $Config3, $Value3).
    config($Vpc, $Config4, $Value4).
    label("vpc/$Vpc").
  }.

defcon dtorVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :-
  {
    config($Vpc, $Config1, $Value1)~
    config($Vpc, $Config2, $Value2)~
    config($Vpc, $Config3, $Value3)~
    config($Vpc, $Config4, $Value4)~
    label("vpc/$Vpc").
    invalid(1).
  }.

defpost postVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :- [ consVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) ].
defpost delVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :- [ dtorVpcConfig4(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) ].


defcon consVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :-
  {
    config($Vpc, $Config1, $Value1).
    config($Vpc, $Config2, $Value2).
    config($Vpc, $Config3, $Value3).
    config($Vpc, $Config4, $Value4).
    config($Vpc, $Config5, $Value5).
    label("vpc/$Vpc").
  }.

defcon dtorVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :-
  {
    config($Vpc, $Config1, $Value1)~
    config($Vpc, $Config2, $Value2)~
    config($Vpc, $Config3, $Value3)~
    config($Vpc, $Config4, $Value4)~
    config($Vpc, $Config5, $Value5)~
    label("vpc/$Vpc").
    invalid(1).
  }.

defpost postVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :- [ consVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) ].
defpost delVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :- [ dtorVpcConfig5(?Vpc,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) ].


defcon consInstanceConfig1(?Instance,?Config1,?Value1) :-
  {
    config($Instance, $Config1, $Value1).
    label("instance/$Instance").
  }.

defcon dtorInstanceConfig1(?Instance,?Config1,?Value1) :-
  {
    config($Instance, $Config1, $Value1)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstanceConfig1(?Instance,?Config1,?Value1) :- [ consInstanceConfig1(?Instance,?Config1,?Value1) ].
defpost delInstanceConfig1(?Instance,?Config1,?Value1) :- [ dtorInstanceConfig1(?Instance,?Config1,?Value1) ].


defcon consInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) :-
  {
    config($Instance, $Config1, $Value1).
    config($Instance, $Config2, $Value2).
    label("instance/$Instance").
  }.

defcon dtorInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) :-
  {
    config($Instance, $Config1, $Value1)~
    config($Instance, $Config2, $Value2)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) :- [ consInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) ].
defpost delInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) :- [ dtorInstanceConfig2(?Instance,?Config1,?Value1,?Config2,?Value2) ].


defcon consInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :-
  {
    config($Instance, $Config1, $Value1).
    config($Instance, $Config2, $Value2).
    config($Instance, $Config3, $Value3).
    label("instance/$Instance").
  }.

defcon dtorInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :-
  {
    config($Instance, $Config1, $Value1)~
    config($Instance, $Config2, $Value2)~
    config($Instance, $Config3, $Value3)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :- [ consInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) ].
defpost delInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) :- [ dtorInstanceConfig3(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3) ].


defcon consInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :-
  {
    config($Instance, $Config1, $Value1).
    config($Instance, $Config2, $Value2).
    config($Instance, $Config3, $Value3).
    config($Instance, $Config4, $Value4).
    label("instance/$Instance").
  }.

defcon dtorInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :-
  {
    config($Instance, $Config1, $Value1)~
    config($Instance, $Config2, $Value2)~
    config($Instance, $Config3, $Value3)~
    config($Instance, $Config4, $Value4)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :- [ consInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) ].
defpost delInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) :- [ dtorInstanceConfig4(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4) ].


defcon consInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :-
  {
    config($Instance, $Config1, $Value1).
    config($Instance, $Config2, $Value2).
    config($Instance, $Config3, $Value3).
    config($Instance, $Config4, $Value4).
    config($Instance, $Config5, $Value5).
    label("instance/$Instance").
  }.

defcon dtorInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :-
  {
    config($Instance, $Config1, $Value1)~
    config($Instance, $Config2, $Value2)~
    config($Instance, $Config3, $Value3)~
    config($Instance, $Config4, $Value4)~
    config($Instance, $Config5, $Value5)~
    label("instance/$Instance").
    invalid(1).
  }.

defpost postInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :- [ consInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) ].
defpost delInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) :- [ dtorInstanceConfig5(?Instance,?Config1,?Value1,?Config2,?Value2,?Config3,?Value3,?Config4,?Value4,?Config5,?Value5) ].


defcon consEndorsementLink(?Endorser,?Target) :-
  ?TargetSet := label(?Endorser, "endorsements/?Target"),
  {
    link($TargetSet).
    label("trusthub").
  }.

defcon dtorEndorsementLink(?Endorser,?Target) :-
  ?TargetSet := label(?Endorser, "endorsements/?Target"),
  {
    link($TargetSet)~
    label("trusthub").
    invalid(1).
  }.

defpost postEndorsementLink(?Endorser,?Target) :- [ consEndorsementLink(?Endorser,?Target) ].
defpost delEndorsementLink(?Endorser,?Target) :- [ dtorEndorsementLink(?Endorser,?Target) ].


defcon consEndorsement(?Target,?Prop,?Value) :-
  {
    endorse($Target, $Prop, $Value).
    label("endorsements/$Target").
  }.

defcon dtorEndorsement(?Target,?Prop,?Value) :-
  {
    endorse($Target, $Prop, $Value)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postEndorsement(?Target,?Prop,?Value) :- [ consEndorsement(?Target,?Prop,?Value) ].
defpost delEndorsement(?Target,?Prop,?Value) :- [ dtorEndorsement(?Target,?Prop,?Value) ].


defcon consInstanceEndorsement(?Target,?Prop,?Value) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet).
    endorse($Target, $Prop, $Value).
    label("endorsements/$Target").
  }.

defcon dtorInstanceEndorsement(?Target,?Prop,?Value) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet)~
    endorse($Target, $Prop, $Value)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postInstanceEndorsement(?Target,?Prop,?Value) :- [ consInstanceEndorsement(?Target,?Prop,?Value) ].
defpost delInstanceEndorsement(?Target,?Prop,?Value) :- [ dtorInstanceEndorsement(?Target,?Prop,?Value) ].


defcon consConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :-
  {
    endorseIfEqual($Target, $Key, $Expected, $Prop, $Value).
    label("endorsements/$Target").
  }.

defcon dtorConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :-
  {
    endorseIfEqual($Target, $Key, $Expected, $Prop, $Value)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :- [ consConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) ].
defpost delConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :- [ dtorConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) ].


defcon consInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet).
    endorseIfEqual($Target, $Key, $Expected, $Prop, $Value).
    label("endorsements/$Target").
  }.

defcon dtorInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet)~
    endorseIfEqual($Target, $Key, $Expected, $Prop, $Value)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :- [ consInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) ].
defpost delInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) :- [ dtorInstanceConditionalEndorsement(?Target,?Key,?Expected,?Prop,?Value) ].


defcon consParameterizedEndorsement(?Target,?Prop,?ConfName) :-
  {
    parameterizedEndorse($Target, $Prop, $ConfName).
    label("endorsements/$Target").
  }.

defcon dtorParameterizedEndorsement(?Target,?Prop,?ConfName) :-
  {
    parameterizedEndorse($Target, $Prop, $ConfName)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postParameterizedEndorsement(?Target,?Prop,?ConfName) :- [ consParameterizedEndorsement(?Target,?Prop,?ConfName) ].
defpost delParameterizedEndorsement(?Target,?Prop,?ConfName) :- [ dtorParameterizedEndorsement(?Target,?Prop,?ConfName) ].


defcon consInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet).
    parameterizedEndorse($Target, $Prop, $ConfName).
    label("endorsements/$Target").
  }.

defcon dtorInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) :-
  ?HostSet := label($BearerRef, "instance/$Self"),
  {
    link($HostSet)~
    parameterizedEndorse($Target, $Prop, $ConfName)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) :- [ consInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) ].
defpost delInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) :- [ dtorInstanceParameterizedEndorsement(?Target,?Prop,?ConfName) ].


defcon consCluster(?Cluster,?OwnerGuard,?JoinerGuard) :-
  ?MasterSet := label($BearerRef, "instance/$Self"),
  {
    link($MasterSet).
    cluster($Cluster, $OwnerGuard, $JoinerGuard).
    label("instance/$Self").
  }.

defcon dtorCluster(?Cluster,?OwnerGuard,?JoinerGuard) :-
  ?MasterSet := label($BearerRef, "instance/$Self"),
  {
    link($MasterSet)~
    cluster($Cluster, $OwnerGuard, $JoinerGuard)~
    label("instance/$Self").
    invalid(1).
  }.

defpost postCluster(?Cluster,?OwnerGuard,?JoinerGuard) :- [ consCluster(?Cluster,?OwnerGuard,?JoinerGuard) ].
defpost delCluster(?Cluster,?OwnerGuard,?JoinerGuard) :- [ dtorCluster(?Cluster,?OwnerGuard,?JoinerGuard) ].


defcon consMembership(?Cluster,?WorkerID) :-
  {
    member($Cluster, $WorkerID).
    label("instance/$Self").
  }.

defcon dtorMembership(?Cluster,?WorkerID) :-
  {
    member($Cluster, $WorkerID)~
    label("instance/$Self").
    invalid(1).
  }.

defpost postMembership(?Cluster,?WorkerID) :- [ consMembership(?Cluster,?WorkerID) ].
defpost delMembership(?Cluster,?WorkerID) :- [ dtorMembership(?Cluster,?WorkerID) ].


defcon consAckMembership(?Cluster,?MasterID) :-
  ?MasterSet := label(?MasterID, "instance/?MasterID"),
  ?SelfSet := label($BearerRef, "instance/$Self"),
  {
    link($MasterSet).
    link($SelfSet).
    join($Cluster, $MasterID).
    label("instance/$Self").
  }.

defcon dtorAckMembership(?Cluster,?MasterID) :-
  ?MasterSet := label(?MasterID, "instance/?MasterID"),
  ?SelfSet := label($BearerRef, "instance/$Self"),
  {
    link($MasterSet)~
    link($SelfSet)~
    join($Cluster, $MasterID)~
    label("instance/$Self").
    invalid(1).
  }.

defpost postAckMembership(?Cluster,?MasterID) :- [ consAckMembership(?Cluster,?MasterID) ].
defpost delAckMembership(?Cluster,?MasterID) :- [ dtorAckMembership(?Cluster,?MasterID) ].


defcon consParameterizedConnection(?Target,?Service,?ConfName) :-
  {
    parameterizedConnection($Target, $Service, $ConfName).
    label("endorsements/$Target").
  }.

defcon dtorParameterizedConnection(?Target,?Service,?ConfName) :-
  {
    parameterizedConnection($Target, $Service, $ConfName)~
    label("endorsements/$Target").
    invalid(1).
  }.

defpost postParameterizedConnection(?Target,?Service,?ConfName) :- [ consParameterizedConnection(?Target,?Service,?ConfName) ].
defpost delParameterizedConnection(?Target,?Service,?ConfName) :- [ dtorParameterizedConnection(?Target,?Service,?ConfName) ].


defcon consTrustHubLink(?OtherHub) :-
  ?HubSet := label(?OtherHub, "trusthub"),
  {
    link($HubSet).
    label("trusthub").
  }.

defcon dtorTrustHubLink(?OtherHub) :-
  ?HubSet := label(?OtherHub, "trusthub"),
  {
    link($HubSet)~
    label("trusthub").
    invalid(1).
  }.

defpost postTrustHubLink(?OtherHub) :- [ consTrustHubLink(?OtherHub) ].
defpost delTrustHubLink(?OtherHub) :- [ dtorTrustHubLink(?OtherHub) ].


//////////////////////////////////////////////////////
// Raw Slang
//////////////////////////////////////////////////////

        defcon lazyDtorInstanceSet(?Instance) :-
          {
              invalid(1).
              label("instance/$Instance").
          }.

        defpost lazyDeleteInstance(?Instance) :- [lazyDtorInstanceSet(?Instance)].
    

//////////////////////////////////////////////////////
// Guards
//////////////////////////////////////////////////////

defguard checkTrustedCluster(?Instance) :- 
  ?InstanceSet := label($BearerRef, "instance/?Instance"),
  ?HostSet := label(?Instance, "instance/?Instance"),
  ?HelperRuleSet := label("MembershipGuardRuleSet"),
  ?TrustWallet := label("trustWallet"),
  ?LibraryRules := label("libraryRules"),
  {
    link($InstanceSet).
    link($HostSet).
    link($HelperRuleSet).
    link($TrustWallet).
    link($LibraryRules).
    trustedCluster($Instance)?
  }.

