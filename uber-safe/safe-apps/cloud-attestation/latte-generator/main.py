#!/usr/bin/python3

import sys
from argparse import ArgumentParser
import latte
from latte_types import Slang


def parse_option():
    parser = ArgumentParser()
    parser.add_argument("-b", "--builder", dest="builder",
                help="the default builder image ID", metavar="BUILDER",
                required=True)
    parser.add_argument("-e", "--endorsements", dest="endorsements",
                help="external endorsements to load and trust", metavar="ENDORSEMENTS", 
                nargs="*", default=[])
    parser.add_argument("-g", "--guard", dest="guards",
                help="the guards to host for target slang", metavar="GUARDS", 
                nargs="+", default=[])
    parser.add_argument("-s", "--script", dest="script",
                help="shell scripts for testing", metavar="SCRIPT")
    return parser.parse_args()




if __name__ == "__main__":

    conf = parse_option()
    slang = Slang()
    latte.add_envs(slang, conf)
    wallet = latte.add_trust_wallet(slang, conf)
    latte.add_latte_statements(slang, conf)
    latte.add_latte_lib(slang, conf)
    labels_to_link = latte.load_endorsements(slang, conf)

    i = 0
    for link in labels_to_link:
        name = "Auxlabel%d" % i 
        wallet.add_expr("?%s" % name, ":=", "label(\"%s\")" % link)
        wallet.add_fact("link", "$%s" % name)
        i += 1

    latte.load_guards(slang, conf)


    sys.stdout.write(slang.generate())

    if conf.script:
        with open(conf.script, "w") as f:
            f.write(slang.scripts())


#  usable sets to link against
#    trustSet.add_fact("label", "\"trustWallet\"")
#            "label(\"instance/$Instance\")"
#            "label(\"control/$Guest\")"
#            "label(\"endorsements/$Target\")"
#            "label(\"cluster/$Self\")"
