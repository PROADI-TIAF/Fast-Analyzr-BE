#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
FASTQ.GZ generator for CBE-F (Cytosine Base Editing – foward strand)
"""

import gzip
from typing import Dict

# =========================
# USER CONFIGURATION
# =========================

AMPLICON = (
    "TGCTAGCTGATCGATGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGTTGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTAGAGTATCCGATGATGAATGATTGGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTA"
)

GUIDE = "AGTATCCGATGATGAATGAT"

READ_LEN = 150
QUAL = "I" * READ_LEN

# =========================
# HELPER FUNCTIONS
# =========================

def revcomp(seq: str) -> str:
    table = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(table)[::-1]


def build_edited_guide(guide: str, variant: str) -> str:
    if variant == "C6C7":
        return guide
    if variant == "T6C7":
        return guide[:5] + "T" + guide[6:]
    if variant == "C6T7":
        return guide[:6] + "T" + guide[7:]
    if variant == "T6T7":
        return guide[:5] + "TT" + guide[7:]
    if variant == "G6G7":
        return guide[:5] + "GG" + guide[7:]
    if variant == "A6T7":
        return guide[:5] + "AT" + guide[7:]
    if variant == "DelDel":
        return guide[:5] + guide[7:]
    if variant == "INS_GG":
        return guide[:6] + "GG" + guide[6:]
    raise ValueError(f"Unknown variant: {variant}")


def apply_variant_to_amplicon(amplicon: str, guide_start: int, variant: str) -> str:
    edited_guide = build_edited_guide(GUIDE, variant)
    return amplicon[:guide_start] + edited_guide + amplicon[guide_start + len(GUIDE):]


def variant_to_amplicon(amplicon: str, guide_start: int, variant_label: str) -> str:
    if variant_label == "AGTATCGGCGATGATGAATGAT":
        return apply_variant_to_amplicon(amplicon, guide_start, "INS_GG")
    else:
        return apply_variant_to_amplicon(amplicon, guide_start, variant_label)


def write_fastq_pair(prefix: str, composition: Dict[str, int], amplicon: str, guide_start: int) -> None:
    r1_path = f"{prefix}_R1.fastq.gz"
    r2_path = f"{prefix}_R2.fastq.gz"

    read_id = 0

    with gzip.open(r1_path, "wt") as f1, gzip.open(r2_path, "wt") as f2:
        for variant_label, n_reads in composition.items():
            if n_reads <= 0:
                continue

            edited_amplicon = variant_to_amplicon(amplicon, guide_start, variant_label)

            if len(edited_amplicon) < READ_LEN:
                raise RuntimeError(f"Amplicon too short for {variant_label}")

            r1_seq = edited_amplicon[:READ_LEN]
            r2_seq = revcomp(edited_amplicon[-READ_LEN:])

            for _ in range(n_reads):
                read_id += 1
                header = f"@{prefix}_{read_id:06d}"

                f1.write(f"{header}/1\n{r1_seq}\n+\n{QUAL}\n")
                f2.write(f"{header}/2\n{r2_seq}\n+\n{QUAL}\n")


# =========================
# FIND GUIDE
# =========================

GUIDE_START = AMPLICON.find(GUIDE)
if GUIDE_START == -1:
    raise RuntimeError("Guide not found in amplicon")

# =========================
# CONDITIONS
# =========================

conditions = {
    "cond1": {
        "C6C7": 10000,
        "T6C7": 0, "C6T7": 0, "T6T7": 0,
        "G6G7": 0, "A6T7": 0,
        "DelDel": 0, "AGTATCGGCGATGATGAATGAT": 0,
    },
    "cond2": {
        "C6C7": 2458,
        "T6T7": 7542,
        "T6C7": 0, "C6T7": 0,
        "G6G7": 0, "A6T7": 0,
        "DelDel": 0, "AGTATCGGCGATGATGAATGAT": 0,
    },
    "cond3": {
        "C6C7": 2458,
        "T6C7": 898,
        "C6T7": 1000,
        "T6T7": 5644,
        "G6G7": 0, "A6T7": 0,
        "DelDel": 0, "AGTATCGGCGATGATGAATGAT": 0,
    },
    "cond4": {
        "C6C7": 2458,
        "T6C7": 898,
        "C6T7": 1000,
        "T6T7": 4494,
        "G6G7": 800,
        "A6T7": 350,
        "DelDel": 0, "AGTATCGGCGATGATGAATGAT": 0,
    },
    "cond5": {
        "C6C7": 2458,
        "T6C7": 898,
        "C6T7": 1000,
        "T6T7": 1894,
        "G6G7": 800,
        "A6T7": 350,
        "DelDel": 1250,
        "AGTATCGGCGATGATGAATGAT": 1350,
    },
    "cond6": {
        "C6C7": 1229,
        "T6C7": 449,
        "C6T7": 500,
        "T6T7": 947,
        "G6G7": 400,
        "A6T7": 175,
        "DelDel": 625,
        "AGTATCGGCGATGATGAATGAT": 675,
    },
}

# =========================
# MAIN
# =========================

def main():
    for i, (cond_name, comp) in enumerate(conditions.items(), start=1):
        total = sum(comp.values())
        print(f"Condition {i}: {total} reads")

        prefix = f"Test-condition{i}-CBE-F"

        write_fastq_pair(
            prefix=prefix,
            composition=comp,
            amplicon=AMPLICON,
            guide_start=GUIDE_START,
        )

    print("\nDone.")


if __name__ == "__main__":
    main()