#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import gzip

# =========================
# INPUT
# =========================

AMPLICON = (
    "AGGCTATAAAAAAAATTAAGCAGCAGTATCCTCTTGGGGGCCCCTTCCCCACACTATCTCAATGCAAATATCT"
    "GTCTGAAACGGTCCCTGGCTAAACTCCACCCATGGGTTGGCCAGCCTTGCCTTGACCAATAGCCTTGACAAGGC"
    "AAACTTGACCAATAGTCTTAGAGTATCCAGTGAGGCCAG"
)

GUIDE = "CTTGACCAATAGCCTTGACA"

READ_LEN = 150
QUAL = "?" * READ_LEN


# =========================
# HELPERS
# =========================

def revcomp(seq):
    table = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(table)[::-1]


def find_guide(amplicon, guide):
    idx = amplicon.find(guide)
    if idx == -1:
        raise RuntimeError("Guide not found in amplicon")
    return idx


GUIDE_IDX = find_guide(AMPLICON, GUIDE)


def apply_subs(seq, subs):
    s = list(seq)
    for pos, base in subs.items():
        s[pos - 1] = base
    return "".join(s)


def parse_tag(tag):
    subs = {}
    i = 0
    while i < len(tag):
        if tag[i] in "ACGT":
            j = i + 1
            while j < len(tag) and tag[j].isdigit():
                j += 1
            if j > i + 1:
                subs[int(tag[i + 1:j])] = tag[i]
            i = j
        else:
            i += 1
    return subs


def build_variant(tag):
    return apply_subs(GUIDE, parse_tag(tag))


def insert_variant_into_amplicon(amplicon, guide, variant):
    return amplicon[:GUIDE_IDX] + variant + amplicon[GUIDE_IDX + len(guide):]


# =========================
# CONDITION 2 ONLY
# =========================

composition = {
    "A5A8A9A11": 3000,
    "G5G8G9G11": 7000,
}

EXPECTED_READS = 10000


# =========================
# FASTQ GENERATOR
# =========================

def write_fastq(rep):
    prefix = f"Test-condition2-ABE-F_rep{rep}"
    r1_path = f"{prefix}_R1.fastq.gz"
    r2_path = f"{prefix}_R2.fastq.gz"

    total = sum(composition.values())
    print(f"Rep {rep}: {total} reads")

    if total != EXPECTED_READS:
        raise RuntimeError("Read count mismatch")

    with gzip.open(r1_path, "wt") as r1, gzip.open(r2_path, "wt") as r2:
        read_id = 1

        for tag, count in composition.items():
            variant = build_variant(tag)
            edited_amplicon = insert_variant_into_amplicon(AMPLICON, GUIDE, variant)

            r1_seq = edited_amplicon[:READ_LEN]
            r2_seq = revcomp(edited_amplicon[-READ_LEN:])

            for _ in range(count):
                name = f"{prefix}_{read_id:06d}"
                r1.write(f"@{name}/1\n{r1_seq}\n+\n{QUAL}\n")
                r2.write(f"@{name}/2\n{r2_seq}\n+\n{QUAL}\n")
                read_id += 1


# =========================
# RUN (250 replicates)
# =========================

def main():
    for rep in range(1, 251):  # rep1 → rep250
        write_fastq(rep)

    print("DONE: condition 2, 250 replicates generated.")


if __name__ == "__main__":
    main()