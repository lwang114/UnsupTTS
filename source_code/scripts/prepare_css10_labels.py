#!/usr/bin/env python3
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

"""
Helper script to pre-compute embeddings for a flashlight (previously called wav2letter++) dataset
"""

import argparse
import os
from collections import defaultdict


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("wrd")
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--output-name", required=True)
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    ltr_dict = defaultdict(int)
    with open(args.wrd, "r") as wrd, open(
        os.path.join(args.output_dir, args.output_name + ".ltr"), "w"
    ) as ltr_out:
        for line in wrd:
            line = line.strip()
            trans = " ".join(list(line.replace(" ", "|"))) + " |"
            print(
                trans,
                file=ltr_out,
            )
            for l in trans.split():
                ltr_dict[l] += 1

    with open(os.path.join(args.output_dir, "dict.ltr.txt"), "w") as dict_out:
        for k, v in ltr_dict.items():
            dict_out.write(f"{k} {v}\n")


if __name__ == "__main__":
    main()
