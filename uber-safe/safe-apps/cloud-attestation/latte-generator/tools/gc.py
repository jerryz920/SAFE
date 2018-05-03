#!/usr/bin/python3

import os

import constants
import safe_data



'''

    Link relationship:


    Instance (Instance, label instance/uuid)
        -> HostSet(Instance, label instance/uuid)
        -> ControlImage (Aux, label image-control/image-uuid)
           -> Endorsement(Image, label endorsements/image-uuid)
              -> speaker: Instance ...
        -> ControlSet(Aux, label instance-control/instance-uuid)
        -> MasterSet(Aux, label cluster/instance-uuid)
        -> VpcSet(Instance, label vpc/vpc-uuid)




'''
class UsageAnalysis(object):

    def __init__(self):
        self.nodes = {}
        self.live_map = {}


    def add_node(self, key, data, alive=True):
        info = {"data": data, "alive": alive, "edges": []}
        self.nodes[key] = info

    def add_host_link(self, guest, host):
        self.nodes[guest]["edges"].append(host)
        if host in self.live_map:
            self.live_map[host].append(guest)
        else:
            self.live_map[host] = [guest]

    def add_regular_link(self, node, other):
        self.nodes[node]["edges"].append(other)

    # return a list of nodes starting from root that is alive
    def do_check_liveness(self, node, liveness, mark):

        # traverse the live map from the root, we can efficiently paralize the collection
        # by starting from alive virtual machines, as IaaS will always be alive.

        # further, the structure of the instance live map is a tree, so there
        # is no need to have a "visited" array for caching
        if not node in self.live_map:
            raise Exception("the root node %s is not in live map %s" % (root, self.live_map))

        if node in liveness:
            raise Exception("cyclic reference, there should not be loop in live_map, node %s" % node)

        if not self.nodes[node]["alive"]:
            mark = False

        liveness[node] = mark
        for guest in self.live_map[node]:
            self.do_check_liveness(guest, liveness, mark)

    def check_liveness(self, root):
        # can parallel this
        liveness = {}
        self.do_check_liveness(root, liveness, True)
        return liveness

    def do_check_reference(self, used, node):
        if not used[node]:
            return
        # for any used instance, its image is also marked as used,
        # even if it is not valid any more. Its host is marked
        # as well
        for e in self.nodes[node]["edges"]:
            used[e] = True
            self.do_check_instance_reference(used, e)


    def check_reference(self, instance_liveness):
        used = {k: i["alive"] for k, i in self.nodes.items()}
        used.update({k: alive for k, alive in instance_liveness.items()})

        # start from every alived node, trying to compute the references
        for n, alive in instance_liveness.items():
            self.do_check_reference(used, n)


def is_root_record(key, data):
    return key


def construct_analyze(client, conf):
    t = client.bucket_type(conf.bucket_type)
    b = client.bucket(conf.bucket, bucket_type=t)
    keys = client.get_keys(bucket=b)

    analyze_graph = UsageAnalysis()
    analyze_graph.add_node(constants.IAAS, {"alive": True, "edges": []}, True)
    for x in keys:
        data = safe_data.SafeData(b.get(x).data)
        key = data.header.key
        analyze_graph.add_node(key, data, data.alive)
        if data.is_instance and data.speaker == constants.IAAS:
            analyze_graph.add_host_link(key, constants.IAAS)

    # process links
    for key, info in analyze_graph.nodes.items():
        data = info["data"]
        links = data.links()
        for l in links:
            if data.is_instance:
                other = analyze_graph.nodes[l]
                if other["data"].is_instance:
                    analyze_graph.add_host_link(key, l)
                else:
                    analyze_graph.add_regular_link(key, l)
            else:
                analyze_graph.add_regular_link(key, l)
    return analyze_graph


def run_gc(client, conf):
    # this method will print out the list of collectable records
    analyze_graph = construct_analyze(client, conf)
    liveness = analyze_graph.check_liveness(constants.IAAS)
    print("liveness map:")
    print(liveness)
    reference = analyze_graph.check_reference(liveness)
    print("reference map:")
    print(reference)

    # for node not in liveness and not reference
    '''
    for n in analyze_graph.nodes:
        if not (n in liveness and liveness[n] or \
                n in reference and reference[n]):
            client.remove_key(n)
    '''






