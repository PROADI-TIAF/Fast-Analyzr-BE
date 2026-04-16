#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import gzip
from typing import Dict

# =========================
# USER INPUT
# =========================

AMPLICON = (
    "GATCTGACATGTTGACCTGATGACCTTAGTACGATGCTAGTTACGATCGTACGATGCTAGTACGATCGATGACCTAGTCGATGCTAGTACGATCGTACGATGCTAGTATTCTCATATAACGCTGGCATCGATGACCTTAGTACGATGCTAGTTACGATCGTACGATGCTAGTACGATCGATGACCTAGTCGATGCTAGTACGATCGTACGATGCTAGTACGATCGATGACCTAGTACA"
)

GUIDE = "ATGCCAGCGTTATATGAGAA"
READ_LEN = 150
QUALITY_CHAR = "?"

# =========================
# HELPERS
# =========================

def reverse_complement(seq: str) -> str:
    table = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(table)[::-1]


def make_fastq_record(name: str, seq: str) -> str:
    qual = QUALITY_CHAR * len(seq)
    return f"@{name}\n{seq}\n+\n{qual}\n"


# =========================
# VARIANT BUILDER
# =========================

def build_edited_guide(guide: str, tag: str):

    if tag == "C4C5C8":
        return guide

    if tag == "T4C5C8":
        return guide[:3] + "T" + guide[4:]

    if tag == "C4T5C8":
        return guide[:4] + "T" + guide[5:]

    if tag == "C4C5T8":
        return guide[:7] + "T" + guide[8:]

    if tag == "T4T5C8":
        return guide[:3] + "TT" + guide[5:]

    if tag == "T4C5T8":
        return guide[:3] + "T" + guide[4:7] + "T" + guide[8:]

    if tag == "C4T5T8":
        return guide[:4] + "T" + guide[5:7] + "T" + guide[8:]

    if tag == "T4T5T8":
        return guide[:3] + "TT" + guide[5:7] + "T" + guide[8:]

    if tag == "A4A5C8":
        return guide[:3] + "AA" + guide[5:]

    if tag == "C4C5G8":
        return guide[:7] + "G" + guide[8:]

    if tag == "Del8":
        return guide[:7] + guide[8:]

    # ✅ FIXED: insertion between positions 4 and 5
    if tag == "A3A4 (Inser)":
        return guide[:4] + "AA" + guide[4:]

    raise ValueError(tag)


# =========================
# APPLY TO AMPLICON
# =========================

def insert_variant_into_amplicon(amplicon: str, guide: str, edited_guide: str):
    protospacer = reverse_complement(guide)
    idx = amplicon.find(protospacer)

    if idx == -1:
        raise RuntimeError("Guide not found in amplicon")

    edited = reverse_complement(edited_guide)

    return amplicon[:idx] + edited + amplicon[idx + len(protospacer):]


# =========================
# FASTQ WRITER
# =========================

def write_fastqs(condition: int, variant_counts: Dict[str, int], total_reads: int):

    prefix = f"Test-condition{condition}-CBE-R"

    with gzip.open(f"{prefix}_R1.fastq.gz", "wt") as r1, \
         gzip.open(f"{prefix}_R2.fastq.gz", "wt") as r2:

        read_id = 1

        for tag, count in variant_counts.items():
            if count == 0:
                continue

            edited_guide = build_edited_guide(GUIDE, tag)
            amp = insert_variant_into_amplicon(AMPLICON, GUIDE, edited_guide)

            r1_seq = amp[:READ_LEN]
            r2_seq = reverse_complement(amp[-READ_LEN:])

            for _ in range(count):
                name = f"{prefix}_{read_id:06d}"

                r1.write(make_fastq_record(name + "/1", r1_seq))
                r2.write(make_fastq_record(name + "/2", r2_seq))

                read_id += 1

        if read_id - 1 != total_reads:
            raise RuntimeError("Read count mismatch")


# =========================
# CONDITIONS
# =========================

conditions = {
    1: {"C4C5C8": 10000},
    2: {"C4C5C8": 2766, "T4T5T8": 7234},
    3: {"C4C5C8": 2766, "T4C5C8": 240, "C4T5C8": 1008, "C4C5T8": 2134,
        "T4T5C8": 238, "T4C5T8": 2000, "C4T5T8": 602, "T4T5T8": 1012},
    4: {"C4C5C8": 2766, "T4C5C8": 240, "C4T5C8": 1008, "C4C5T8": 2134,
        "T4T5C8": 238, "T4C5T8": 2000, "C4T5T8": 602, "T4T5T8": 204,
        "A4A5C8": 404, "C4C5G8": 404},
    5: {"C4C5C8": 2766, "T4C5C8": 240, "C4T5C8": 1008, "C4C5T8": 2134,
        "T4T5C8": 238, "T4C5T8": 2000, "C4T5T8": 602, "T4T5T8": 202,
        "A4A5C8": 204, "C4C5G8": 204, "Del8": 202, "A3A4 (Inser)": 200},
    6: {"C4C5C8": 1383, "T4C5C8": 120, "C4T5C8": 504, "C4C5T8": 1067,
        "T4T5C8": 119, "T4C5T8": 1000, "C4T5T8": 301, "T4T5T8": 101,
        "A4A5C8": 102, "C4C5G8": 102, "Del8": 101, "A3A4 (Inser)": 100},
}

final_reads = {1:10000, 2:10000, 3:10000, 4:10000, 5:10000, 6:5000}


# =========================
# RUN
# =========================

def main():
    for cond, variants in conditions.items():
        write_fastqs(cond, variants, final_reads[cond])

    print("Done")


if __name__ == "__main__":
    main()