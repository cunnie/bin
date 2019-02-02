#!/usr/bin/env python3

# This program takes, on STDIN, 
# RTTM v1.3 (https://catalog.ldc.upenn.edu/docs/LDC2004T12/RTTM-format-v13.pdf)
# data and, if the two utterances of the same speaker are within 0.01 seconds
# of each other, it merges the two records and spits it out. Otherwise it 
# spits out the record unchanged

# e.g. given these three lines:
#
# SPEAKER meeting 1 32.58 0.20000000000000284 <NA> <NA> spkr_2 <NA>
# SPEAKER meeting 1 32.78 0.14000000000000057 <NA> <NA> spkr_2 <NA>
# SPEAKER meeting 1 32.92 0.259999999999998 <NA> <NA> spkr_2 <NA>
#
# it would output
# SPEAKER meeting 1 32.58 0.60 <NA> <NA> spkr_2 <NA>

# Typical invocation:
#
#   squash_rttm.py < /tmp/ibm_ES2008a.rttm > /tmp/ibm_ES2008a_squashed.rttm

# To test
#
#   python3 -m unittest squash_rttm.py < /dev/null

import math
import sys
import unittest


class TestRTTMMethods(unittest.TestCase):
    def test_squash_rttm_empty(self):
        self.assertEqual(squash_rttm([]), "")

    def test_squash_rttm_two_decimals(self):
        pre_squashed = [
            "SPEAKER meeting 1       31.69   0.31000000000000014     <NA>    <NA>    Speaker_3       <NA>",
        ]
        squashed = "SPEAKER\tmeeting\t1\t31.69\t0.31\t<NA>\t<NA>\tSpeaker_3\t<NA>\n"
        self.assertEqual(squash_rttm(pre_squashed), squashed)

    def test_squash_rttm_two_lines(self):
        pre_squashed = [
            "SPEAKER meeting 1       31.69   0.31000000000000014     <NA>    <NA>    Speaker_3       <NA>",
            "SPEAKER meeting 1       32.00   0.59000000000000014     <NA>    <NA>    Speaker_3       <NA>",
        ]
        squashed = "SPEAKER\tmeeting\t1\t31.69\t0.90\t<NA>\t<NA>\tSpeaker_3\t<NA>\n"
        self.assertEqual(squash_rttm(pre_squashed), squashed)

    def test_squash_rttm_two_lines_two_speakers(self):
        pre_squashed = [
            "SPEAKER meeting 1       31.69   0.31000000000000014     <NA>    <NA>    Speaker_2       <NA>",
            "SPEAKER meeting 1       32.00   0.59000000000000014     <NA>    <NA>    Speaker_3       <NA>",
        ]
        squashed = "SPEAKER\tmeeting\t1\t31.69\t0.31\t<NA>\t<NA>\tSpeaker_2\t<NA>\n" + \
                   "SPEAKER\tmeeting\t1\t32.00\t0.59\t<NA>\t<NA>\tSpeaker_3\t<NA>\n"
        self.assertEqual(squash_rttm(pre_squashed), squashed)

    def test_squash_rttm_two_lines_one_pause(self):
        pre_squashed = [
            "SPEAKER meeting 1       31.69   0.29000000000000014     <NA>    <NA>    Speaker_3       <NA>",
            "SPEAKER meeting 1       32.00   0.59000000000000014     <NA>    <NA>    Speaker_3       <NA>",
        ]
        squashed = "SPEAKER\tmeeting\t1\t31.69\t0.29\t<NA>\t<NA>\tSpeaker_3\t<NA>\n" + \
                   "SPEAKER\tmeeting\t1\t32.00\t0.59\t<NA>\t<NA>\tSpeaker_3\t<NA>\n"
        self.assertEqual(squash_rttm(pre_squashed), squashed)


class RTTM:
    def __init__(self, array_of_args):
        self.type = array_of_args[0]
        self.file = array_of_args[1]
        self.chnl = array_of_args[2]
        self.tbeg = float(array_of_args[3])
        self.tdur = float(array_of_args[4])
        self.ortho = array_of_args[5]
        self.stype = array_of_args[6]
        self.name = array_of_args[7]
        self.conf = array_of_args[8]

    def __str__(self):
        return ("{}\t{}\t{}\t{:.2f}\t{:.2f}\t{}\t{}\t{}\t{}\n".format(
            self.type,
            self.file,
            self.chnl,
            self.tbeg,
            self.tdur,
            self.ortho,
            self.stype,
            self.name,
            self.conf
        ))

    def end(self):
        return self.tbeg + self.tdur


def squash_rttm(rttm_lines):
    previous_rttm = None  # "original"
    squashed_rttm_lines = ''

    for line in rttm_lines:
        current_rttm = RTTM(line.split())
        if previous_rttm is None:
            previous_rttm = current_rttm
        else:
            if current_rttm.name == previous_rttm.name and math.isclose(current_rttm.tbeg, previous_rttm.end(),
                                                                        abs_tol=0.01):
                # collapse the two
                previous_rttm.tdur += current_rttm.tdur
            else:
                # print the line & move on
                squashed_rttm_lines += str(previous_rttm)
                previous_rttm = current_rttm
    if not (previous_rttm is None):
        squashed_rttm_lines += str(previous_rttm)
    return (squashed_rttm_lines)


print(squash_rttm(sys.stdin.readlines()))
