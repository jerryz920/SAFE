#!/usr/bin/env python3
import re

# matching () is actually impossible in RE. Need extra check if we want safety
# format
# \+ [speaker:] pred([arglist])
# or 
# \+ ([speaker:] pred([arglist]))
FACT_PATTERN = re.compile(r"\s*(\\\+)?\s*\(?\s*((.*):)?\s*(\S+)\s*\(([^()]*)\)\s*\)?")

def fact_from_str(s, fact_cls): 
    m = FACT_PATTERN.match(s)
    if m:
        negate = True if m.group(1) == "\\+" else False
        speaker = m.group(3)
        pred = m.group(4)
        # group(5) returns "" on empty
        arglist = m.group(5).split(",")


        return fact_cls(pred, *[arg for arg in arglist if arg != ""], speaker=speaker,
                negate=negate)
    else:
        raise ValueError("string %s is mal-format fact" % s) 

EXPR_PATTERN = re.compile(r"\s*(\S+)\s*([=<>:^!&*+-/\\]+)\s*(.+)")
def expr_from_str(s, expr_cls):
    m = EXPR_PATTERN.match(s)
    if m:
        left = m.group(1)
        op = m.group(2)
        right = m.group(3)
        return expr_cls(left, op, right)
    else:
        raise ValueError("string %s is mal-format expression" % s) 

