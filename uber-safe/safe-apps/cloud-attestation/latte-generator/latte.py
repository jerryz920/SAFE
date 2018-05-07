#!/usr/bin/env python3
import json
import sys

from latte_types import Slang, Expression, Endorsement, Guard, Fact
from utils import fact_from_str
from constants import *

def add_envs(slang, conf):
    # special properties
    slang.add_env("IaaS", "\"152.3.145.38:444\"")
    slang.add_env("IaaSGid", "\"0\"")
    slang.add_env("PropertySource", "\"source\"")
    slang.add_env("PropertyBuilder", "\"builder\"")
    slang.add_env("PropertyAttester", "\"attester\"")
    slang.add_env("PropertyNossh", "\"nossh\"")
    slang.add_env("PropertyDns", "\"dns\"")
    slang.add_env("PropertyVpcId", "\"vpcid\"")
    slang.add_env("PropertyPackage", "\"package\"")
    slang.add_env("PropertyPackageVersion", "\"packageVersion\"")
    slang.add_env("PropertyPackageSource", "\"packageSource\"")

def add_trust_wallet(slang, conf):
    # predefined trusts, we could use it for trustwallet
    trustSet = slang.add_ruleset("trustWallet")
    trustSet.add_fact("trustedCloudProvider", "$IaaS")
    trustSet.add_fact("trustedCloudProvider", "$IaaSGid")
    trustSet.add_fact("tapconImageSource", "\"https://github.com/jerryz920/boot2docker.git#dev\"")
    trustSet.add_fact("tapconDaemonSource", "\"https://github.com/jerryz920/docker.git#tapcon\"")
    trustSet.add_fact("tapconKernelSource", "\"https://github.com/jerryz920/linux.git#tapcon-v4.4\"")
    trustSet.add_fact("approvedDns", "\"8.8.8.8\"")
    trustSet.add_fact("builderImage", '"' + conf.builder + '"')
    trustSet.add_fact("builderSource", '\"https://github.com/jerryz920/boot2docker.git#dev\"')
    trustSet.add_fact("buildsFrom", '"' + conf.builder + '"', '\"https://github.com/jerryz920/boot2docker.git#dev\"') # reproducible build
    return trustSet

def add_latte_statements(slang, conf):

    # Self is an InstanceID (UUID)
    slang.add_attestation_str("Instance",
            ["?Instance", "?Image", "?TrustHub"],
            [
                Expression("?HostSet", ":=", "label($BearerRef, \"instance/$Self\")"),
                Expression("?HubSet", ":=", "label(?TrustHub, \"trusthub\")"),
            ], 
            "link($HostSet)",
            "link($HubSet)",
            "runs($Instance, $Image)",
            "label(\"instance/$Instance\")"
            )

    slang.add_attestation_str("VMInstance",
            ["?Instance", "?Image", "?Vpc", "?TrustHub"],
            [
                #Expression("?ControlSet", ":=", "label($IaaS, \"control/?Instance\")"),
                Expression("?VpcSet", ":=", "label(\"vpc/?Vpc\")"),
                Expression("?HubSet", ":=", "label(?TrustHub, \"trusthub\")"),
            ], 
            #"link($ControlSet)",
            "link($VpcSet)",
            "link($HubSet)",
            "root(\"$IaaS\")",
            "config($Instance,$PropertyVpcId, $Vpc)",
            "runs($Instance, $Image)",
            "label(\"instance/$Instance\")"
            )

    for i in range(1,6):
        args = ["?Vpc"]
        facts = []
        for j in range(1, i + 1):
            args.append("?Config%d" % j)
            args.append("?Value%d" % j)
            facts.append("config($Vpc, $Config%d, $Value%d)" % (j, j))
        facts.append("label(\"vpc/$Vpc\")")
        slang.add_attestation_str("VpcConfig%d" % i,
                args,
                [],
                *facts)
#
#    slang.add_attestation_str("InstanceAuthID",
#            ["?Instance", "?AuthID"],
#            [
#                Expression("?GuestIP", ":=", "ipFromNetworkID(?AuthID)"),
#                Expression("?GuestPorts", ":=", "portFromNetworkID(?AuthID)")
#            ],
#            "bindToId($Instance, $GuestIP, $GuestPorts)",
#            "label(\"instance/$Instance\")"
#            )
#
#    slang.add_attestation_str("InstanceAuthKey",
#            ["?Instance", "?AuthID", "?AuthKey"],
#            [
#                Expression("?GuestIP", ":=", "ipFromNetworkID(?AuthID)"),
#                Expression("?GuestPorts", ":=", "portFromNetworkID(?AuthID)")
#            ],
#            "bindToId($Instance, $GuestIP, $GuestPorts, $AuthKey)",
#            "label(\"instance/$Instance\")"
#            )
#
    for i in range(1,6):
        args = ["?Instance"]
        facts = []
        for j in range(1, i + 1):
            args.append("?Config%d" % j)
            args.append("?Value%d" % j)
            facts.append("config($Instance, $Config%d, $Value%d)" % (j, j))
        facts.append("label(\"instance/$Instance\")")
        slang.add_attestation_str("InstanceConfig%d" % i,
                args,
                [],
                *facts)
#    slang.add_attestation_str("InstanceCidrConfig",
#            ["?Instance", "?Config", "?NetParam"],
#            [
#                Expression("?IP", ":=", "ipFromNetworkID(?NetParam)")
#            ],
#            "config($Instance, $Config, $IP)",
#            "label(\"instance/$Instance\")"
#            )


    # should always be called by the one who asserts the image
    slang.add_attestation_str("EndorsementLink",
            ["?Endorser", "?Target"],
            [
                Expression("?TargetSet", ":=", "label(?Endorser, \"endorsements/?Target\")")
            ],
            "link($TargetSet)",
            "label(\"trusthub\")"
            )

    slang.add_attestation_str("Endorsement",
            ["?Target", "?Prop", "?Value"],
            [],
            "endorse($Target, $Prop, $Value)",
            "label(\"endorsements/$Target\")"
            )
    slang.add_attestation_str("InstanceEndorsement",
            ["?Target", "?Prop", "?Value"],
            [
                Expression("?HostSet", ":=", "label($BearerRef, \"instance/$Self\")")
            ],
            "link($HostSet)",
            "endorse($Target, $Prop, $Value)",
            "label(\"endorsements/$Target\")"
            )

    slang.add_attestation_str("ConditionalEndorsement",
            ["?Target", "?Key", "?Expected", "?Prop", "?Value"],
            [],
            "endorseIfEqual($Target, $Key, $Expected, $Prop, $Value)",
            "label(\"endorsements/$Target\")"
            )

    slang.add_attestation_str("InstanceConditionalEndorsement",
            ["?Target", "?Key", "?Expected", "?Prop", "?Value"],
            [
                Expression("?HostSet", ":=", "label($BearerRef, \"instance/$Self\")")
            ],
            "link($HostSet)",
            "endorseIfEqual($Target, $Key, $Expected, $Prop, $Value)",
            "label(\"endorsements/$Target\")"
            )

    slang.add_attestation_str("ParameterizedEndorsement",
            ["?Target", "?Prop", "?ConfName"],
            [ ],
            "parameterizedEndorse($Target, $Prop, $ConfName)",
            "label(\"endorsements/$Target\")"
            )
    slang.add_attestation_str("InstanceParameterizedEndorsement",
            ["?Target", "?Prop", "?ConfName"],
            [
                Expression("?HostSet", ":=", "label($BearerRef, \"instance/$Self\")")
            ],
            "link($HostSet)",
            "parameterizedEndorse($Target, $Prop, $ConfName)",
            "label(\"endorsements/$Target\")"
            )

    slang.add_attestation_str("Cluster",
            ["?Cluster", "?OwnerGuard", "?JoinerGuard"],
            [
                Expression("?MasterSet", ":=", "label($BearerRef, \"instance/$Self\")")
            ],
            "link($MasterSet)", # hostset: this is different from below label!
            "cluster($Cluster, $Self)",
            "ownerGuard($OwnerGuard)",
            "joinerGuard($JoinerGuard)",
            "label(\"instance/$Self\")" #self claims
            )

    slang.add_attestation_str("Membership",
            ["?Cluster", "?WorkerID"],
            [],
            "member($Cluster, $WorkerID)",
            "label(\"instance/$Self\")" # self claim
            )

    slang.add_attestation_str("AckMembership",
            ["?Cluster", "?MasterID"],
            [
                Expression("?MasterSet", ":=", "label(?MasterID, \"instance/?MasterID\")"),
                Expression("?SelfSet", ":=", "label($BearerRef, \"instance/$Self\")")
            ],
            "link($MasterSet)", # link to master's self claim set
            "link($SelfSet)",
            "join($Cluster, $MasterID)",
            "label(\"instance/$Self\")", # spoken for itself
            )

    slang.add_attestation_str("ParameterizedConnection",
            ["?Target", "?Service", "?ConfName"],
            [],
            "parameterizedConnection($Target, $Service, $ConfName)",
            "label(\"endorsements/$Target\")"
            )

    # Garbage collector will delete it when not used.
    slang.add_raw_slang('''
        defcon lazyDtorInstanceSet(?Instance) :-
          {
              invalid(1).
              label("instance/$Instance").
          }.

        defpost lazyDeleteInstance(?Instance) :- [lazyDtorInstanceSet(?Instance)].
    ''')

    # trust hub link differs from ImageOwnerLink in that it posts to a general
    # set owned by the trusthub. It may introduce heavy dependencies, but we might
    # be able to invent some link reduction techniques to load needed content on
    # demand.
    slang.add_attestation_str("TrustHubLink",
            ["?OtherHub"],
            [
                Expression("?HubSet", ":=", "label(?OtherHub, \"trusthub\")")
            ],
            "link($HubSet)",
            "label(\"trusthub\")"
        )

def add_latte_lib(slang, conf):
    librarySet = slang.add_ruleset("libraryRules")

    # controls
    #librarySet.add_rule_str(
    #        "controls(Host, Guest)",
    #        "IaaS : controls(Host, Guest)",
    #        "trustedCloudProvider(IaaS)")

    #librarySet.add_rule_str(
    #        "contains(HostAddr, GuestAddr)",
    #        "IaaSAddr: allocate(HostAddr, CIDR)",
    #        "trustedCloudProvider($IaaSAddr)",
    #        "cidrContains(CIDR, GuestAddr)")

    #librarySet.add_rule_str(
    #        "contains(HostAddr, GuestAddr)",
    #        "ipPortContains(HostAddr, GuestAddr)")

    # hasConfig
    librarySet.add_rule_str(
            "hasConfig(Instance, ConfName, ConfValue)",
            "H: config(Instance, ConfName, ConfValue)",
            "attester(H)")

    # launches
    librarySet.add_rule_str(
            "launches(Instance, Image)",
            "H: runs(Instance, Image)",
            "attester(H)")

    librarySet.add_rule_str(
            "attester(Instance)",
            "checkProperty(Instance, $PropertyAttester, 1)")

    librarySet.add_rule_str(
            "attester(Instance)",
            "trustedCloudProvider(Instance)")


    librarySet.add_rule_str(
            "builder(Instance)",
            "checkProperty(Instance, $PropertyBuilder, 1)")

    librarySet.add_rule_str(
            "builder(Instance)",
            "launches(Instance, Image)",
            "builderImage(Image)")
    librarySet.add_rule_str(
            "builder(Instance)",
            "launches(Instance, Image)",
            "buildsFrom(Image, Source)",
            "builderSource(Source)")

    librarySet.add_rule_str(
            "buildsFrom(Image, Source)",
            "B: endorse(Image, $PropertySource, Source)",
            "builder(B)")

    librarySet.add_rule_str(
            "packageBuildsFrom(Image, Package, Source)",
            "packageSource(Image, Package, Source)")

    librarySet.add_rule_str(
            "packageBuildsFrom(Image, Package, Source)",
            "buildsFrom(Image, ISource)",
            "packageSource(ISource, Package, Source)")

    librarySet.add_rule_str(
            "imageProperty(Image, Property, Value)",
            "endorse(Image, Property, Value)")

    librarySet.add_rule_str(
            "imageProperty(Image, Property, Value)",
            "buildsFrom(Image, Source)",
            "endorse(Source, Property, Value)")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "endorse(Image, Property, Value)")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "buildsFrom(Image, Source)",
            "endorse(Source, Property, Value)")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "parameterizedEndorse(Image, Property, ConfName)",
            "hasConfig(Instance, ConfName, Value)")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "buildsFrom(Image, Source)",
            "parameterizedEndorse(Source, Property, ConfName)",
            "hasConfig(Instance, ConfName, Value)")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "endorseIfEqual(Image, Key, Expected, Property, Value)",
            "hasConfig(Instance, Key, Real)",
            "Real = Expected")

    librarySet.add_rule_str(
            "checkProperty(Instance, Property, Value)",
            "launches(Instance, Image)",
            "buildsFrom(Image, Source)",
            "endorseIfEqual(Source, Key, Expected, Property, Value)",
            "hasConfig(Instance, Key, Real)",
            "Real = Expected")

    librarySet.add_rule_str(
            "sourceCheck(Instance, Package, Source)",
            "launches(Instance, Image)",
            "packageBuildsFrom(Image, Package, Source)")

    librarySet.add_rule_str(
            "sourceCheck(Instance, Package, Source)",
            "launches(Instance, Image)",
            "buildsFrom(Image, ISource)",
            "packageBuildsFrom(ISource, Package, Source)")

    librarySet.add_rule_str(
            "versionCheck(Instance, Package, Version)",
            "launches(Instance, Image)",
            "packageVersion(Image, Package, Source)")

    librarySet.add_rule_str(
            "versionCheck(Instance, Package, Version)",
            "launches(Instance, Image)",
            "buildsFrom(Image, ISource)",
            "packageVersion(ISource, Package, Source)")

    librarySet.add_rule_str(
            "memberCheck(Instance, Cluster, Master)",
            "Master: member(Cluster, Instance)",
            "Instance: join(Cluster, Master)")

    librarySet.add_rule_str(
            "memberCheck(Instance, Cluster, Master)",
            "Master: member(Cluster, Instance)",
            "trustedCloudProvider(Master)")

    librarySet.add_rule_str(
            "connection(Instance, Package, Ep)",
            "launches(Instance, Image)",
            "parameterizedConnection(Image, Package, ConfKey)",
            "hasConfig(Instance, ConfKey, Ep)")

    librarySet.add_rule_str(
            "connection(Instance, Package, Ep)",
            "launches(Instance, Image)",
            "buildsFrom(Image, Source)",
            "parameterizedConnection(Source, Package, ConfKey)",
            "hasConfig(Instance, ConfKey, Ep)")
    return librarySet

def load_endorsement_file(slang, fname):

    try:
        with open(fname, "r") as f:
            v = json.load(f)
            label = "endorsements/%s" % v["label"]
            slang.add_endorsement(Endorsement(v["name"], 
                label, v["speaker"],
                v.get("attestations", []), v.get("rules", []), v.get("envs", {})))
            return label
    except Exception as e: 
        sys.stderr.write("Json parse exception in loading endorsements %s, %s\n" % (fname, e))
        raise

def load_endorsements(slang, conf):
    labels_to_link = []
    for efile in conf.endorsements:
        labels_to_link.append(load_endorsement_file(slang, efile))
    return labels_to_link

def load_guard_file(slang, fname):
    try:
        with open(fname, "r") as f:
            v = json.load(f)
            rulesetName = v["name"] + "GuardRuleSet"
            slang.add_endorsement(Endorsement(rulesetName, None, "",
                v.get("trustWallet", []), v.get("rules", []), v.get("envs", {})))
            for name, g in v.get("guards", {}).items():
                exprs = [Expression(e[0], e[1], e[2]) for e in g.get("exprs", [])]
                exprs.append(Expression("?HelperRuleSet", ":=", 
                    "label(\"%s\")" % rulesetName))
                exprs.append(Expression("?TrustWallet", ":=", 
                    "label(\"%s\")" % TrustWallet))
                exprs.append(Expression("?LibraryRules", ":=", 
                    "label(\"%s\")" % LatteLibrary))
                links = g.get("links", [])
                links.append("$HelperRuleSet")
                links.append("$TrustWallet")
                links.append("$LibraryRules")
                queries = [fact_from_str(s, Fact) for s in g.get("queries", [])]
                slang.add_guard(Guard(name, g["args"], exprs, links, *queries))
    except Exception as e: 
        sys.stderr.write("Json parse exception in loading guards %s, %s\n" % (fname, e))
        raise

def load_guards(slang, conf):
    for gfile in conf.guards:
        load_guard_file(slang, gfile)
