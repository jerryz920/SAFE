#!/usr/bin/python3


def unquote(s):
    n = s.strip()
    if len(n) < 2:
        return n
    start = 0
    if n[0] == '"' or n[0] == '\'':
        start = 1
    end = len(s)
    if n[-1] == '"' or n[-1] == '\'':
        end = end - 1
    return s[start:end]


