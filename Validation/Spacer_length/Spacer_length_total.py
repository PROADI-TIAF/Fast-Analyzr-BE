#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Unified FASTQ generator
Generates ONLY condition 6 for:
- ABE-F
- ABE-R
- CBE-F
- CBE-R
"""

import gzip
import random

# =========================================================
# COMMON HELPERS
# =========================================================

def revcomp(seq):
    table = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(table)[::-1]


# =========================================================
# ====================== ABE-F =============================
# =========================================================

AMPLICON_ABE_F = (
    "AGGCTATAAAAAAAATTAAGCAGCAGTATCCTCTTGGGGGCCCCTTCCCCACACTATCTCAATGCAAATATCT"
    "GTCTGAAACGGTCCCTGGCTAAACTCCACCCATGGGTTGGCCAGCCTTGCCTTGACCAATAGCCTTGACAAGGC"
    "AAACTTGACCAATAGTCTTAGAGTATCCAGTGAGGCCAG"
)

GUIDE_ABE_F = "CTTGACCAATAGCCTTGACA"
READ_LEN = 150
QUAL_ABE_F = "?" * READ_LEN

GUIDE_IDX_ABE_F = AMPLICON_ABE_F.find(GUIDE_ABE_F)

def apply_subs(seq, subs):
    s = list(seq)
    for pos, base in subs.items():
        s[pos - 1] = base
    return "".join(s)

def delete_positions(seq, positions):
    return "".join(base for i, base in enumerate(seq, 1) if i not in positions)

def insert_after(seq, pos, ins):
    return seq[:pos] + ins + seq[pos:]

def parse_tag(tag):
    subs = {}
    i = 0
    while i < len(tag):
        if tag[i] in "ACGT":
            j = i + 1
            while j < len(tag) and tag[j].isdigit():
                j += 1
            subs[int(tag[i+1:j])] = tag[i]
            i = j
        else:
            i += 1
    return subs

def build_variant_abe_f(tag):
    if tag == "C6C7 (Inser)":
        return insert_after(GUIDE_ABE_F, 6, "C")
    if tag == "G5Del8,9G11":
        seq = apply_subs(GUIDE_ABE_F, {5:"G",11:"G"})
        return delete_positions(seq, [8,9])
    return apply_subs(GUIDE_ABE_F, parse_tag(tag))

def run_abe_f():
    composition = {
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
    }

    prefix = "Test-condition6-ABE-F"

    with gzip.open(prefix+"_R1.fastq.gz","wt") as r1, gzip.open(prefix+"_R2.fastq.gz","wt") as r2:
        read_id = 1
        for tag,count in composition.items():
            variant = build_variant_abe_f(tag)
            amp = AMPLICON_ABE_F[:GUIDE_IDX_ABE_F] + variant + AMPLICON_ABE_F[GUIDE_IDX_ABE_F+len(GUIDE_ABE_F):]

            r1_seq = amp[:READ_LEN]
            r2_seq = revcomp(amp[-READ_LEN:])

            for _ in range(count):
                name = f"{prefix}_{read_id:06d}"
                r1.write(f"@{name}/1\n{r1_seq}\n+\n{QUAL_ABE_F}\n")
                r2.write(f"@{name}/2\n{r2_seq}\n+\n{QUAL_ABE_F}\n")
                read_id += 1


# =========================================================
# ====================== ABE-R =============================
# =========================================================

AMPLICON_ABE_R = (
"GGAATGACTGAATCGGAACAAGGCAAAGGCTATAAAAAAAATTAAGCAGCAGTATCCTCTTGGGGGCCCCTTCCCCACACTATCTCAATGCAAATATCTGTCTGAAACG"
"GTCCCTGGCTAAACTCCACCCATGGGTTGGCCAGCCTTGCCTTGACCAATAGCCTTGACAAGGCAAACTTGACCAATAGTCTTAGAGTATCCAGTGAGGCCAG"
)

GUIDE_ABE_R = "CTATCTCAATGCAAATATCT"
GUIDE_START_ABE_R = AMPLICON_ABE_R.find(GUIDE_ABE_R)

def make_variant_abe_r(cat):
    if cat == "(-G5G11)":
        return "CTATCTCAATGCAAATACT"
    if cat == "Insert_3C_between_A3_and_T4":
        return "CTATCTCAATGCAAATAGGGTCT"

    base_map = {3:"A",5:"A",11:"A"}
    i=0
    while i<len(cat):
        if cat[i] in "ACGT":
            j=i+1
            while j<len(cat) and cat[j].isdigit():
                j+=1
            base_map[int(cat[i+1:j])] = cat[i]
            i=j
        else:
            i+=1

    seq = list(GUIDE_ABE_R)
    n=len(seq)
    conv={"A":"T","G":"C","C":"G","T":"A"}
    for p,b in base_map.items():
        seq[n-p] = conv[b]
    return "".join(seq)

def run_abe_r():
    composition = {
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
    }

    prefix="Test-condition6-ABE-R"

    with gzip.open(prefix+"_R1.fastq.gz","wt") as r1, gzip.open(prefix+"_R2.fastq.gz","wt") as r2:
        read_id=1
        for cat,count in composition.items():
            frag = make_variant_abe_r(cat)
            amp = AMPLICON_ABE_R[:GUIDE_START_ABE_R] + frag + AMPLICON_ABE_R[GUIDE_START_ABE_R+len(GUIDE_ABE_R):]

            r1_seq = amp[:READ_LEN]
            r2_seq = revcomp(amp[-READ_LEN:])

            for _ in range(count):
                name=f"{prefix}_{read_id:06d}"
                r1.write(f"@{name}/1\n{r1_seq}\n+\n{'I'*READ_LEN}\n")
                r2.write(f"@{name}/2\n{r2_seq}\n+\n{'I'*READ_LEN}\n")
                read_id+=1


# =========================================================
# ====================== CBE-F =============================
# =========================================================

AMPLICON_CBE_F = "TGCTAGCTGATCGATGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGTTGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTAGAGTATCCGATGATGAATGATTGGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTAGCTAGTACGATCGTACGATGCTAGCTGATCGATGACCTAGTCGATGCTA"
GUIDE_CBE_F = "AGTATCCGATGATGAATGAT"
GUIDE_START_CBE_F = AMPLICON_CBE_F.find(GUIDE_CBE_F)

def edit_cbe_f(variant):
    g=GUIDE_CBE_F
    if variant=="C6C7": return g
    if variant=="T6C7": return g[:5]+"T"+g[6:]
    if variant=="C6T7": return g[:6]+"T"+g[7:]
    if variant=="T6T7": return g[:5]+"TT"+g[7:]
    if variant=="G6G7": return g[:5]+"GG"+g[7:]
    if variant=="A6T7": return g[:5]+"AT"+g[7:]
    if variant=="DelDel": return g[:5]+g[7:]
    if variant=="AGTATCGGCGATGATGAATGAT": return g[:6]+"GG"+g[6:]
    raise ValueError

def run_cbe_f():
    comp = {
        "C6C7": 1229,"T6C7":449,"C6T7":500,"T6T7":947,
        "G6G7":400,"A6T7":175,"DelDel":625,"AGTATCGGCGATGATGAATGAT":675
    }

    prefix="Test-condition6-CBE-F"

    with gzip.open(prefix+"_R1.fastq.gz","wt") as f1, gzip.open(prefix+"_R2.fastq.gz","wt") as f2:
        rid=1
        for v,c in comp.items():
            edited = edit_cbe_f(v)
            amp = AMPLICON_CBE_F[:GUIDE_START_CBE_F]+edited+AMPLICON_CBE_F[GUIDE_START_CBE_F+len(GUIDE_CBE_F):]

            r1=amp[:READ_LEN]
            r2=revcomp(amp[-READ_LEN:])

            for _ in range(c):
                name=f"{prefix}_{rid:06d}"
                f1.write(f"@{name}/1\n{r1}\n+\n{'I'*READ_LEN}\n")
                f2.write(f"@{name}/2\n{r2}\n+\n{'I'*READ_LEN}\n")
                rid+=1


# =========================================================
# ====================== CBE-R =============================
# =========================================================

AMPLICON_CBE_R = "GATCTGACATGTTGACCTGATGACCTTAGTACGATGCTAGTTACGATCGTACGATGCTAGTACGATCGATGACCTAGTCGATGCTAGTACGATCGTACGATGCTAGTATTCTCATATAACGCTGGCATCGATGACCTTAGTACGATGCTAGTTACGATCGTACGATGCTAGTACGATCGATGACCTAGTCGATGCTAGTACGATCGTACGATGCTAGTACGATCGATGACCTAGTACA"
GUIDE_CBE_R = "ATGCCAGCGTTATATGAGAA"

def edit_cbe_r(tag):
    g=GUIDE_CBE_R
    if tag=="C4C5C8": return g
    if tag=="T4C5C8": return g[:3]+"T"+g[4:]
    if tag=="C4T5C8": return g[:4]+"T"+g[5:]
    if tag=="C4C5T8": return g[:7]+"T"+g[8:]
    if tag=="T4T5C8": return g[:3]+"TT"+g[5:]
    if tag=="T4C5T8": return g[:3]+"T"+g[4:7]+"T"+g[8:]
    if tag=="C4T5T8": return g[:4]+"T"+g[5:7]+"T"+g[8:]
    if tag=="T4T5T8": return g[:3]+"TT"+g[5:7]+"T"+g[8:]
    if tag=="A4A5C8": return g[:3]+"AA"+g[5:]
    if tag=="C4C5G8": return g[:7]+"G"+g[8:]
    if tag=="Del8": return g[:7]+g[8:]
    if tag=="A3A4 (Inser)": return g[:4]+"AA"+g[4:]
    raise ValueError

def run_cbe_r():
    comp = {
        "C4C5C8":1383,"T4C5C8":120,"C4T5C8":504,"C4C5T8":1067,
        "T4T5C8":119,"T4C5T8":1000,"C4T5T8":301,"T4T5T8":101,
        "A4A5C8":102,"C4C5G8":102,"Del8":101,"A3A4 (Inser)":100
    }

    prefix="Test-condition6-CBE-R"

    with gzip.open(prefix+"_R1.fastq.gz","wt") as r1, gzip.open(prefix+"_R2.fastq.gz","wt") as r2:
        rid=1
        for tag,c in comp.items():
            edited = edit_cbe_r(tag)

            protospacer = revcomp(GUIDE_CBE_R)
            idx = AMPLICON_CBE_R.find(protospacer)
            amp = AMPLICON_CBE_R[:idx] + revcomp(edited) + AMPLICON_CBE_R[idx+len(protospacer):]

            r1_seq = amp[:READ_LEN]
            r2_seq = revcomp(amp[-READ_LEN:])

            for _ in range(c):
                name=f"{prefix}_{rid:06d}"
                r1.write(f"@{name}/1\n{r1_seq}\n+\n{'?'*READ_LEN}\n")
                r2.write(f"@{name}/2\n{r2_seq}\n+\n{'?'*READ_LEN}\n")
                rid+=1


# =========================================================
# ========================== RUN ===========================
# =========================================================

def main():
    print("Generating condition 6 only...\n")

    run_abe_f()
    print("ABE-F done")

    run_abe_r()
    print("ABE-R done")

    run_cbe_f()
    print("CBE-F done")

    run_cbe_r()
    print("CBE-R done")

    print("\nDONE: All condition 6 FASTQs generated correctly.")


if __name__ == "__main__":
    main()