#!/usr/bin/python3

from ..utils import fact_from_str

import utils

def _s(s):
    return s.stripe()


class CertHeader(object):



    def __init__(self, key, speaker, ts, algo, label):
        self.key = key
        self.speaker = speaker
        self.ts = ts
        self.algo = algo
        self.label = label


    def is_instance(self):
        if self.label.startswith("instance"):
            return True
        return False


    @classmethod
    def parse(cls, lines):
        if len(lines) < 6:
            raise Exception("Safe cert must have at least 6 lines")
        print("debug: cert header [%s]\n", lines[:6])
        return CertHeader(_s(lines[0]), _s(lines[2]),
                _s(lines[3]), _s(lines[4]), _s(lines(5)))



class SafeData(object):

    def __init__(self, data):
        # data is line terminated items
        self.lines = data.split("\n")
        self.header = CertHeader.parse(self.lines)
        self.links = []
        self.facts = [] # other facts 
        self.alive = True
        for n in self.lines[6:]:
            f = fact_from_str(self.n)
            if f.pred == "link" or f.pred == "root":
                if len(f.args) > 1:
                    raise Exception("Format error, label has only 1 arg")
                self.links.append(utils.unquote(f.args[0]))
            else:
                self.facts.append(f)
                if f.pred == "invalid":
                    self.alive = False

    def links(self):
        return self.links

    def alive(self):
        return self.alive

    def is_instance(self):
        return self.header.is_instance()









