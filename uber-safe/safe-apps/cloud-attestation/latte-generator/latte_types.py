#!/usr/bin/python3

from io import StringIO
from utils import fact_from_str as fact_from_str_helper
from utils import expr_from_str
import sys


#### IMPORTANT WORKAROUND:
### the fact can be expression as well!
def fact_from_str(s):
    try:
        if isinstance(s, list):
            return NegateFacts(*[fact_from_str(line) for line in s])
        return fact_from_str_helper(s, Fact)
    except ValueError as e:
        try:
            return expr_from_str(s, Expression)
        except ValueError as e:
            raise

class Attestation(object):

    def __init__(self, name, args, exprs, facts):
        self.name = name
        self.exprs = exprs
        self.facts = facts
        self.args = args

    def to_str(self):
        exprlist = "\n  ".join([stmt.to_str() + "," for stmt in self.exprs])
        if len(self.exprs) > 0:
            exprlist = "\n  " + exprlist
        formats = { 
            "name": self.name,
            "argslist": ",".join(self.args),
            "firstarg": self.args[0],
            "exprlist": exprlist,
            "factlist": "\n    ".join([stmt.to_str() + "." for stmt in self.facts]),
            "revokelist": ("\n    ".join([stmt.to_revoke()  for stmt in self.facts])) + "\n    invalid(1)."
        }
        return '''\ndefcon cons%(name)s(%(argslist)s) :-%(exprlist)s
  {
    %(factlist)s
  }.

defcon dtor%(name)s(%(argslist)s) :-%(exprlist)s
  {
    %(revokelist)s
  }.

defpost post%(name)s(%(argslist)s) :- [ cons%(name)s(%(argslist)s) ].
defpost del%(name)s(%(argslist)s) :- [ dtor%(name)s(%(argslist)s) ].
''' % formats

    def scripts(self):
        copied = self.args.copy()
        # handling instance is different because of IP and Cidr field
        if self.name == "Instance":
            copied.insert(2, "?AuthID")
        elif self.name == "VMInstance":
            copied.insert(2, "?AuthID")
            copied.insert(3, "?Cidr")

        formats = { 
            "name": self.name,
            "arglist": ",".join(["\\\"${%s}\\\"" % arg for arg in range(1, len(copied) + 1)]),
            "formalargs": ",".join(copied)
        }
        return '''
post%(name)s() {
    local principal=$1
    shift 1
# %(formalargs)s
    curl -XPOST $SAFE_ADDR/post%(name)s -d "{ \\"principal\\": \\"$principal\\", \\"otherValues\\": [%(arglist)s]}"
}
del%(name)s() {
    local principal=$1
    shift 1
    curl -XPOST $SAFE_ADDR/del%(name)s -d "{ \\"principal\\": \\"$principal\\", \\"otherValues\\": [%(arglist)s]}"
}
        ''' % formats


class Endorsement(object):

    def __init__(self, name, label, speaker, facts, rules, envs):
        self.speaker = speaker
        self.trust_wallet = []
        self.ruleset = Ruleset(name, label)
        self.ruleset.add_fact_str(*facts)
        for r in rules:
            self.ruleset.add_rule_str(r[0], *r[1:])
        self.envs = map(lambda k: Env(k, envs[k]), envs)

    def to_str(self):
        raise RuntimeError("An endorsement is added into slang, \
                there is no need to call this function ever")


class Env(object): 
    def __init__(self, name, value):
        self.name = name
        self.value = value
        if self.value.startswith("@"):
            with open(self.value[1:], "r") as f:
                self.value = f.read()
                self.value = self.value.replace('\\', '\\\\')
                self.value = self.value.replace('"', '\\"')
                self.value = self.value.replace('\'', '\\\'')
                self.value = '"' + self.value + '"'

    def to_str(self):
        return "defenv %s() :- %s." % (self.name, self.value)

class Expression(object):
    # right is a fact
    def __init__(self, left, op, right):
        self.left = left
        self.op = op
        self.right = right

    def to_str(self):
        return "%s %s %s" % (self.left, self.op, self.right)

    def to_revoke(self):
        return self.to_str()


class Fact(object):
    def __init__(self, pred, *args, **kwargs):
        self.pred = pred
        if args:
            self.args = args
        else:
            self.args = []
        self.negate = kwargs.pop("negate", False)
        self.speaker = kwargs.pop("speaker", "")

    def to_str(self):
        if self.speaker:
            prefix = "%s : " % (self.speaker.strip())
        else:
            prefix = ""
        if not self.negate:
            return "%s%s(%s)" % (prefix, self.pred, ",".join(self.args))
        else:
            return "%s\+(%s(%s))" % (prefix, self.pred, ",".join(self.args))

    def to_revoke(self):
        if self.pred == "label":
            return self.to_str() + "."
        else:
            return self.to_str() + "~"

class NegateFacts(object):
    def __init__(self, *facts):
        self.facts = facts

    def to_str(self):
        formats = {
                "factlist": ",".join(["\n        %s" % f.to_str() for f in self.facts])
        }
        return '''\+(%(factlist)s
      )''' % formats 


class Rule(object):
    def __init__(self, head, facts):
        self.head = head
        self.facts = facts

    def to_str(self):
        return "%s :-\n      %s" % (self.head.to_str(),
               ",\n      ".join([fact.to_str() for fact in self.facts]))

class Ruleset(object):

    def __init__(self, name, label=None):
        self.name = name
        self.exprs = []
        if label:
            self.facts = [Fact("label", '"' + label + '"')]
        else:
            self.facts = [Fact("label", '"' + name + '"')]
        self.rules = []

    def add_fact(self, predicate, *args, **kwargs):
        negate = kwargs.pop("negate", False)
        speaker = kwargs.pop("speaker", "")
        self.facts.append(Fact(predicate, *args, negate=negate, speaker=speaker))

    def add_fact_str(self, *facts):
        self.facts.extend(map(lambda s: fact_from_str(s), facts))

    def add_expr(self, left, op, right):
        self.facts.append(Expression(left, op, right))

    def add_rule(self, head, facts):
        self.rules.append(Rule(head, facts))

    # helper
    def add_rule_str(self, headstr, *factstrs):
        head = fact_from_str(headstr)
        facts = [fact_from_str(fact) for fact in factstrs]
        self.rules.append(Rule(head, facts))

    def to_str(self):
        exprlist = "\n  ".join([stmt.to_str() + "," for stmt in self.exprs])
        if len(self.exprs) > 0:
            exprlist = "\n  " + exprlist
        rulelist = "\n\n    ".join([rule.to_str() + "." for rule in self.rules])
        if len(self.rules) > 0 and len(self.facts) > 0:
            rulelist = "\n    " + rulelist

        factlist = "\n    ".join([stmt.to_str() + "." for stmt in self.facts])
        if len(self.facts) > 0 and len(self.rules) > 0:
            factlist += "\n"

        formats = { 
            "name": self.name[0].upper() + self.name[1:],
            "exprlist": exprlist,
            "factlist": factlist,
            "rulelist": rulelist
        }
        return '''\ndefcon cons%(name)s() :-%(exprlist)s
  {
    %(factlist)s%(rulelist)s
  }.

definit cons%(name)s().''' % formats

class Guard(object):

    def __init__(self, name, args, exprs, links, *queries):
        self.name = name
        self.args = args
        self.exprs = exprs
        self.links = links
        self.queries = queries

    def to_str(self):
        exprlist = "\n  ".join([stmt.to_str() + "," for stmt in self.exprs])
        if len(self.exprs) > 0:
            exprlist = "\n  " + exprlist
        linklist = "\n    ".join([("link(%s)." % link) for link in self.links])
        querylist = "\n    ".join([q.to_str() + "?" for q in self.queries])
        if len(self.queries) > 0 and len(self.links) > 0:
            querylist = "\n    " + querylist
        formats = {
            "name": self.name,
            "argslist": ",".join(self.args),
            "exprlist": exprlist, 
            "linklist": linklist,
            "querylist": querylist,
        }
        return '''\ndefguard check%(name)s(%(argslist)s) :- %(exprlist)s
  {
    %(linklist)s%(querylist)s
  }.
''' % formats

    def scripts(self):

        formats = { 
            "name": self.name,
            "arglist": ",".join(["\\\"${%s}\\\"" % arg for arg in range(1, len(self.args) + 1)]),
            "formalargs": ",".join(self.args)
        }
        return '''
check%(name)s() {
    local principal=$1
    shift 1
# %(formalargs)s
    curl -XPOST $SAFE_ADDR/check%(name)s -d "{ \\"principal\\": \\"$principal\\", \\"otherValues\\": [%(arglist)s]}"
}
        ''' % formats


def _c(s):
    return "// " + s + "\n"

def _b(s):
    return "\n//////////////////////////////////////////////////////\n" + \
           "// " + s + "\n" + \
           "//////////////////////////////////////////////////////\n"


class Slang(object):
    def __init__(self):
        self.envs = []
        self.attestations = []
        self.rulesets = []
        self.endorsements = []
        self.guards = []
        self.raw = []

    def add_env(self, name, value):
        # env does not need a label.
        self.envs.append(Env(name, value))

    def add_attestation(self, name, args, exprs, facts):
        self.attestations.append(Attestation(name, args, exprs, facts))

    def add_attestation_str(self, name, args, exprs, *factstrs):
        facts = [fact_from_str(f) for f in factstrs]
        self.attestations.append(Attestation(name, args, exprs, facts))

    def add_ruleset(self, name):
        r = Ruleset(name)
        self.rulesets.append(r)
        return r

    def add_endorsement(self, e):
        self.endorsements.append(e)
        return e

    def add_guard(self, g):
        self.guards.append(g)
        return g

    def add_raw_slang(self, s):
        self.raw.append(s)


# return a string of slang 
    def generate(self):
        output = StringIO()

        output.write(_b("Enviroments"))

        output.write(_c("Envs from Latte default"))
        for e in self.envs:
            output.write(e.to_str())
            output.write("\n")

        for eds in self.endorsements:
            output.write(_c("Envs from external endorsements: %s" % eds.ruleset.name))
            for e in eds.envs:
                output.write(e.to_str())
                output.write("\n")

        output.write(_b("Rulesets"))
        output.write(_c("Rulesets of Latte library"))
        for r in self.rulesets:
            output.write(r.to_str())
            output.write("\n")

        for eds in self.endorsements:
            output.write(_c("Rulesets of external endorsements: %s" % eds.ruleset.name))
            output.write(eds.ruleset.to_str())
            output.write("\n")

        output.write(_b("Interfaces for attestations"))
        for stmt in self.attestations:
            output.write(stmt.to_str())
            output.write("\n")

        output.write(_b("Raw Slang"))
        for r in self.raw:
            output.write(r)
            output.write("\n")

        output.write(_b("Guards"))
        for g in self.guards:
            output.write(g.to_str())
            output.write("\n")
        return output.getvalue()

    def scripts(self):
        output = StringIO()
        output.write('''#!/bin/bash

if [ -z "$SAFE_ADDR" ]; then
    echo ' must set SAFE_ADDR env '
    exit 1
fi

''')
        for stmt in self.attestations:
            output.write(stmt.scripts())
            output.write('\n')
        for g in self.guards:
            output.write(g.scripts())
            output.write('\n')
        return output.getvalue()

