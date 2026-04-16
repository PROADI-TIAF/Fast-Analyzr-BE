#!/usr/bin/env python3
"""
FASTQ.GZ generator for ABE-R (Adenine Base Editing – reverse strand)

"""

import gzip
import random
from dataclasses import dataclass
from typing import Dict, List, Tuple

# -----------------------------
# Sequences
# -----------------------------
AMPLICON = (
    "GGAATGACTGAATCGGAACAAGGCAAAGGCTATAAAAAAAATTAAGCAGCAGTATCCTCTTGGGGGCCCCTTCCCCACACTATCTCAATGCAAATATCTGTCTGAAACG"
    "GTCCCTGGCTAAACTCCACCCATGGGTTGGCCAGCCTTGCCTTGACCAATAGCCTTGACAAGGCAAACTTGACCAATAGTCTTAGAGTATCCAGTGAGGCCAG"
)

GUIDE_RC_R1 = "CTATCTCAATGCAAATATCT"

READ_LEN = 150
RNG_SEED = 12345

HIGHQ_CHAR = "I"
LOWQ_CHAR = "!"

# -----------------------------
# Special variants
# -----------------------------
SPECIAL_DELETION_A3_R1 = "CTATCTCAATGCAAATACT"
SPECIAL_INSERT_3C_R1 = "CTATCTCAATGCAAATAGGGTCT"

GUIDE_TO_R1_BASE = {"A": "T", "G": "C", "C": "G", "T": "A"}

# -----------------------------
# Helper functions
# -----------------------------
def revcomp(seq: str) -> str:
    comp = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(comp)[::-1]

def find_unique_subseq(haystack: str, needle: str) -> int:
    idx = haystack.find(needle)
    if idx == -1:
        raise ValueError("Guide not found")
    return idx

def set_bases_from_back(seq: str, pos_map: Dict[int, str]) -> str:
    s = list(seq)
    n = len(s)
    for p, b in pos_map.items():
        s[n - p] = b
    return "".join(s)

def make_variant(category: str) -> str:
    if category == "(-G5G11)":
        return SPECIAL_DELETION_A3_R1
    if category == "Insert_3C_between_A3_and_T4":
        return SPECIAL_INSERT_3C_R1

    bases = {3: "A", 5: "A", 11: "A"}

    i = 0
    while i < len(category):
        if category[i] in "ACGT":
            j = i + 1
            while j < len(category) and category[j].isdigit():
                j += 1
            pos = int(category[i+1:j])
            bases[pos] = category[i]
            i = j
        else:
            i += 1

    return set_bases_from_back(
        GUIDE_RC_R1,
        {p: GUIDE_TO_R1_BASE[b] for p, b in bases.items()}
    )

def mutate_amplicon(amplicon: str, start: int, new_seq: str) -> str:
    return amplicon[:start] + new_seq + amplicon[start + len(GUIDE_RC_R1):]

def make_reads(seq: str) -> Tuple[str, str]:
    return seq[:READ_LEN], revcomp(seq[-READ_LEN:])

# -----------------------------
# Data structure
# -----------------------------
@dataclass
class ConditionSpec:
    total_reads: int
    final_reads: int
    category_counts: Dict[str, int]
    lowq_reads: int = 0

# -----------------------------
# Conditions (CORRECTED)
# -----------------------------
CONDITIONS = {
    1: ConditionSpec(10000, 10000, {"A3A5A11": 10000}),
    2: ConditionSpec(10000, 10000, {
        "A3A5A11": 4100,
        "G3G5G11": 5900,
    }),
    3: ConditionSpec(10000, 10000, {
        "A3A5A11": 4100,
        "G3A5A11": 240,
        "G3G5A11": 230,
        "A3G5A11": 1130,
        "A3G5G11": 272,
        "A3A5G11": 1008,
        "G3A5G11": 700,
        "G3G5G11": 2320,
    }),
    4: ConditionSpec(10000, 10000, {
        "A3A5A11": 4100,
        "G3A5A11": 240,
        "G3G5A11": 230,
        "A3G5A11": 1130,
        "A3G5G11": 272,
        "A3A5G11": 1008,
        "G3A5G11": 700,
        "G3G5G11": 882,
        "C3G5G11": 238,
        "G3T5G11": 556,
        "G3G5C11": 644,
    }),
    5: ConditionSpec(10000, 10000, {
        "A3A5A11": 4100,
        "G3A5A11": 240,
        "G3G5A11": 230,
        "A3G5A11": 1130,
        "A3G5G11": 272,
        "A3A5G11": 1008,
        "G3A5G11": 700,
        "G3G5G11": 882,
        "C3G5G11": 278,
        "G3T5G11": 120,
        "G3G5C11": 322,
        "(-G5G11)": 278,
        "Insert_3C_between_A3_and_T4": 440,
    }),
    6: ConditionSpec(10000, 5000, {
        "A3A5A11": 2050,
        "G3A5A11": 120,
        "G3G5A11": 115,
        "A3G5A11": 565,
        "A3G5G11": 136,
        "A3A5G11": 504,
        "G3A5G11": 350,
        "G3G5G11": 441,
        "C3G5G11": 139,
        "G3T5G11": 60,
        "G3G5C11": 161,
        "(-G5G11)": 139,
        "Insert_3C_between_A3_and_T4": 220,
    }, lowq_reads=5000),
}

# -----------------------------
# Validation
# -----------------------------
def validate():
    for cid, spec in CONDITIONS.items():
        if sum(spec.category_counts.values()) != spec.final_reads:
            raise ValueError(f"Condition {cid}: mismatch in counts")
        if spec.final_reads + spec.lowq_reads != spec.total_reads:
            raise ValueError(f"Condition {cid}: total mismatch")

# -----------------------------
# FASTQ writer
# -----------------------------
def write_fastq(path, records):
    with gzip.open(path, "wt") as f:
        for name, seq, qual in records:
            f.write(f"@{name}\n{seq}\n+\n{qual}\n")

# -----------------------------
# Generator
# -----------------------------
def generate(cond_id, spec):
    random.seed(RNG_SEED + cond_id)
    start = find_unique_subseq(AMPLICON, GUIDE_RC_R1)

    categories = []
    for k, v in spec.category_counts.items():
        categories += [k] * v

    random.shuffle(categories)

    r1, r2 = [], []

    for i, cat in enumerate(categories):
        frag = make_variant(cat)
        seq = mutate_amplicon(AMPLICON, start, frag)
        read1, read2 = make_reads(seq)

        name = f"cond{cond_id}_{i}"
        r1.append((name+"/1", read1, HIGHQ_CHAR*READ_LEN))
        r2.append((name+"/2", read2, HIGHQ_CHAR*READ_LEN))

    for i in range(spec.lowq_reads):
        frag = make_variant("A3A5A11")
        seq = mutate_amplicon(AMPLICON, start, frag)
        read1, read2 = make_reads(seq)

        name = f"cond{cond_id}_low_{i}"
        r1.append((name+"/1", read1, LOWQ_CHAR*READ_LEN))
        r2.append((name+"/2", read2, LOWQ_CHAR*READ_LEN))

    prefix = f"Test-condition{cond_id}-ABE-R"
    write_fastq(prefix+"_R1.fastq.gz", r1)
    write_fastq(prefix+"_R2.fastq.gz", r2)

    print(f"[OK] Condition {cond_id}")

# -----------------------------
# Main
# -----------------------------
def main():
    validate()
    for cid in CONDITIONS:
        generate(cid, CONDITIONS[cid])

if __name__ == "__main__":
    main()