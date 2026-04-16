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


def delete_positions(seq, positions):
    positions = set(positions)
    return "".join(base for i, base in enumerate(seq, start=1) if i not in positions)


def insert_after(seq, pos, insert_seq):
    return seq[:pos] + insert_seq + seq[pos:]


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
    if tag == "C6C7 (Inser)":
        return insert_after(GUIDE, 6, "C")

    if tag == "G5Del8,9G11":
        seq = apply_subs(GUIDE, {5: "G", 11: "G"})
        return delete_positions(seq, [8, 9])

    return apply_subs(GUIDE, parse_tag(tag))


def insert_variant_into_amplicon(amplicon, guide, variant):
    return amplicon[:GUIDE_IDX] + variant + amplicon[GUIDE_IDX + len(guide):]


def write_fastq(condition, composition, expected_reads):
    prefix = f"Test-condition{condition}-ABE-F"
    r1_path = f"{prefix}_R1.fastq.gz"
    r2_path = f"{prefix}_R2.fastq.gz"

    total = sum(composition.values())
    print(f"Condition {condition}: {total} reads")

    if total != expected_reads:
        raise RuntimeError(f"Condition {condition} mismatch")

    with gzip.open(r1_path, "wt") as r1, gzip.open(r2_path, "wt") as r2:
        read_id = 1

        for tag, count in composition.items():
            if count <= 0:
                continue

            variant = build_variant(tag)
            edited_amplicon = insert_variant_into_amplicon(AMPLICON, GUIDE, variant)

            if len(edited_amplicon) < READ_LEN:
                raise RuntimeError(
                    f"Edited amplicon length ({len(edited_amplicon)}) is shorter than READ_LEN ({READ_LEN}) for {tag}"
                )

            r1_seq = edited_amplicon[:READ_LEN]
            r2_seq = revcomp(edited_amplicon[-READ_LEN:])

            for _ in range(count):
                name = f"{prefix}_{read_id:06d}"
                r1.write(f"@{name}/1\n{r1_seq}\n+\n{QUAL}\n")
                r2.write(f"@{name}/2\n{r2_seq}\n+\n{QUAL}\n")
                read_id += 1


# =========================
# CONDITIONS
# =========================

conditions = {
    1: {
        "A5A8A9A11": 10000,
    },
    2: {
        "A5A8A9A11": 3000,
        "G5G8G9G11": 7000,
    },
    3: {
        "A5A8A9A11": 3000,
        "G5A8A9A11": 420,
        "A5G8A9A11": 520,
        "A5A8G9A11": 460,
        "A5A8A9G11": 420,
        "G5G8A9A11": 380,
        "G5A8G9A11": 340,
        "G5A8A9G11": 300,
        "A5G8G9A11": 260,
        "A5G8A9G11": 240,
        "A5A8G9G11": 220,
        "G5G8G9A11": 200,
        "G5G8A9G11": 260,
        "G5A8G9G11": 280,
        "A5G8G9G11": 200,
        "G5G8G9G11": 2500,
    },
    4: {
        "A5A8A9A11": 3000,
        "G5A8A9A11": 420,
        "A5G8A9A11": 520,
        "A5A8G9A11": 460,
        "A5A8A9G11": 420,
        "G5G8A9A11": 380,
        "G5A8G9A11": 340,
        "G5A8A9G11": 300,
        "A5G8G9A11": 260,
        "A5G8A9G11": 240,
        "A5A8G9G11": 220,
        "G5G8G9A11": 200,
        "G5G8A9G11": 260,
        "G5A8G9G11": 280,
        "A5G8G9G11": 200,
        "G5G8G9G11": 1000,
        "G5G8T9G11": 800,
        "C5A8A9A11": 350,
        "G5A8A9T11": 350,
        "G5Del8,9G11": 0,
        "C6C7 (Inser)": 0,
    },
    5: {
        "A5A8A9A11": 3000,
        "G5A8A9A11": 420,
        "A5G8A9A11": 520,
        "A5A8G9A11": 460,
        "A5A8A9G11": 420,
        "G5G8A9A11": 380,
        "G5A8G9A11": 340,
        "G5A8A9G11": 300,
        "A5G8G9A11": 260,
        "A5G8A9G11": 240,
        "A5A8G9G11": 220,
        "G5G8G9A11": 200,
        "G5G8A9G11": 260,
        "G5A8G9G11": 280,
        "A5G8G9G11": 200,
        "G5G8G9G11": 400,
        "G5G8T9G11": 800,
        "C5A8A9A11": 350,
        "G5A8A9T11": 350,
        "G5Del8,9G11": 250,
        "C6C7 (Inser)": 350,
    },
    6: {
        "A5A8A9A11": 1500,
        "G5A8A9A11": 210,
        "A5G8A9A11": 260,
        "A5A8G9A11": 230,
        "A5A8A9G11": 210,
        "G5G8A9A11": 190,
        "G5A8G9A11": 170,
        "G5A8A9G11": 150,
        "A5G8G9A11": 130,
        "A5G8A9G11": 120,
        "A5A8G9G11": 110,
        "G5G8G9A11": 100,
        "G5G8A9G11": 130,
        "G5A8G9G11": 140,
        "A5G8G9G11": 100,
        "G5G8G9G11": 200,
        "G5G8T9G11": 400,
        "C5A8A9A11": 175,
        "G5A8A9T11": 175,
        "G5Del8,9G11": 125,
        "C6C7 (Inser)": 175,
    },
}

expected_reads = {
    1: 10000,
    2: 10000,
    3: 10000,
    4: 10000,
    5: 10000,
    6: 5000,
}


# =========================
# RUN
# =========================

def main():
    for cond, comp in conditions.items():
        write_fastq(cond, comp, expected_reads[cond])

    print("DONE: All FASTQ files generated correctly.")


if __name__ == "__main__":
    main()