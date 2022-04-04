#!/usr/bin/env python3 -u
import re
import shutil
import argparse
import os
from pathlib import Path
from subprocess import run, PIPE, DEVNULL
from tempfile import NamedTemporaryFile
import sys
from typing import List, Dict

CODE2LANG = {
    "ja": "japanese",
    "nl": "dutch",
    "hu": "hungarian",
    "ru": "russian"
}
SIL = "<SIL>"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--wrd_path", help="Path to the original .wrd files in characters")
    parser.add_argument("--in_path", help="Path to words.txt containing the vocabulary of the dataset")
    parser.add_argument("--out_name", help="Name of the new .wrd and .phn files")
    parser.add_argument("--phoneticsaurus", help="Root to Phoneticsaurus")
    parser.add_argument("--g2p_models_dir", help="Root to the LanguageNet G2P")
    parser.add_argument("--lang", help="Language code")
    
    args = parser.parse_args()
    in_path = Path(args.in_path)
    wrd_path = Path(args.wrd_path)
    phone_path = Path(in_path.parent / "phones.txt")
    lexicon_path = Path(in_path.parent / "g2p.txt")
    phoneticsaurus = Path(args.phoneticsaurus)
    g2p_models_dir = Path(args.g2p_models_dir)
    lang = CODE2LANG[args.lang]
    lang2fst = G2PModelProvider(g2p_models_dir)
    model = lang2fst.get(lang)
    if not model: 
        raise ValueError(f"No G2P FST model for language {lang} in {g2p_models_dir}")

    with in_path.open('r') as f:
        lexicon_path.write_text(
            run(
                [ f"{phoneticsaurus}/phonetisaurus-g2pfst",
                  f"--model={g2p_models_dir / model}",
                  f"--wordlist={f.name}",
                ],
                check=True,
                text=True,
                stdout=PIPE,
                stderr=DEVNULL
            ).stdout
        )
        lexicon = LanguageNetLexicon.from_path(lexicon_path)
        lexicon.save_lexicon(phone_path)
        #out_wrd_path = Path(args.out_name+'.wrd')
        out_phn_path = Path(args.out_name+'.phn')
        with wrd_path.open("r") as fin,\
             out_phn_path.open("w") as fphn:
            for line in fin:
                words = line.strip().split()
                phonetic = ["".join(lexicon.transcribe(w)).strip() for w in words]
                if not len(phonetic):
                    phonetic = [SIL]
                #print(*[w for w in phonetic if w], file=fwrd)
                print(*[phn for w in phonetic for phn in w if phn], file=fphn)

class G2PModelProvider:
    def __init__(self, g2p_models_dir: Path):
        self.lang2fst = {
            line.split("_")[0]: line
            for line in run(
                ["ls", g2p_models_dir], text=True, check=True, stdout=PIPE
            ).stdout.split()
        }

    def get(self, lang: str) -> str:
        return self.lang2fst[lang]

Phone = str


class LanguageNetLexicon:
    WORD_SEPARATOR = "#"
    SYLLABLE_SEPARATOR = "."
    STRESS_TOKEN = "ˈ"
    PROLONG_TOKEN = "ː"
    SPECIAL_TOKEN_RE = re.compile(r"<.+>")

    def __init__(self, lexicon: Dict[str, List[str]], words: List[str]):
        self.lexicon = lexicon
        self.words = words

    @staticmethod
    def from_path(p: Path) -> "LanguageNetLexicon":
        lexicon = {}
        words = []
        with p.open() as f:
            for line in f:
                word, _, *phones = line.strip().split()
                lexicon[word] = phones
                words.append(word)
        return LanguageNetLexicon(lexicon, words)

    def transcribe(
        self,
        word: str,
        strip_special_markers: bool = True,
        remove_special_tokens: bool = False,
    ) -> List[Phone]:
        # Treat special words as their own phones or remove
        if self.SPECIAL_TOKEN_RE.match(word):
            return [] if remove_special_tokens else [word]

        phonetic = self.lexicon.get(word.strip(), "")

        def is_not_special_marker_or_special_markers_are_ok(p: str) -> bool:
            if not strip_special_markers:
                return True
            return not any(
                p == sym for sym in [self.SYLLABLE_SEPARATOR, self.WORD_SEPARATOR, self.STRESS_TOKEN, self.PROLONG_TOKEN]
            )

        phonetic = [
            p_
            for p in phonetic for p_ in p
            if p_ and is_not_special_marker_or_special_markers_are_ok(p_)
        ]
        return phonetic   

    def save_lexicon(
        self, phone_path: Path
    ):
        phone_path.write_text(
            "\n".join(
                [ " ".join(self.transcribe(word))
                    for word in self.words
                ]
            )
        )


if __name__ == '__main__':
    main()
