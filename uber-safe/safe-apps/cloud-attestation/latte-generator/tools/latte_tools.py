#!/usr/bin/python3

import riak
import argparse
import constants
import gc


def create_config():
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", "--bucket", dest="bucket",
            metavar="BUCKET", default=None)
    parser.add_argument("-k", "--key", dest="key", 
            metavar="KEY", default=None)
    parser.add_argument("-p", "--port", dest="riak_port", metavar="RIAK_PORT",
            default=8098)
    parser.add_argument("-H", "--host", dest="riak_host", metavar="RIAK_HOST",
            default="localhost")
    parser.add_argument("-t", "--protocol", dest="riak_protocol",
            metavar="RIAK_PROTOCOL", default="http")
    parser.add_argument("-v", "--verbose", dest="riak_verbose", nargs="?",
            const=True, metavar="RIAK_VERBOSE", default=False)
    parser.add_argument("-g", "--garbage-collect", dest="run_gc", nargs="?", const=True,
            metavar="GC", default=False)
    parser.add_argument("--bt", dest="bucket_type", metavar="BUCKET_TYPE", default=constants.BUCKET_TYPE)
    return parser.parse_args()


def riak_client(conf):
    if conf.riak_protocol == "http":
        return riak.RiakClient(protocol=conf.riak_protocol,
            host=conf.riak_host, http_port=conf.riak_port)
    else:
        return riak.RiakClient(protocol=conf.riak_protocol,
            host=conf.riak_host, pb_port=conf.riak_port)

# list all buckets names
# list all keys in a bucket
# show content of a key



def list_all_buckets(client, conf):
    t = client.bucket_type(conf.bucket_type)
    buckets= client.get_buckets(bucket_type=t)
    print(buckets)

def list_all_keys(client, conf):
    t = client.bucket_type(conf.bucket_type)
    b = client.bucket(conf.bucket, bucket_type=t)
    keys = client.get_keys(bucket=b)
    if conf.riak_verbose:
        for x in keys:
            #print("%s: {\n  %s\n}\n" % (x, b.get(x).data.replace("\n", "\n  ")))
            print("%s\n" % (b.get(x).data))
    else:
        print(keys)

def show(client, conf):
    t = client.bucket_type(conf.bucket_type)
    b = client.bucket(conf.bucket, bucket_type=t)
    key = b.get(conf.key)
    print(key)


def gc(client, conf):
    gc.run_gc(client, conf)


dispatch_table = {
        "listall": list_all_buckets,
        "listkey": list_all_keys,
        "showkey": show, 
        "gc": gc
        }


if __name__ == "__main__":

    conf = create_config()
    client = riak_client(conf)
    operation = "listall"
    if conf.bucket:
        operation = "listkey"
        if conf.key:
            operation = "showkey"

    if conf.run_gc:
        operation= "gc"
    dispatch_table[operation](client, conf)
