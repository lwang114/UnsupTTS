import os
import argparse

def main(in_path, tsv_path, wrd_path, phn_path, trans_type):
    text_dict = dict()
    with open(in_path, 'r') as f_in,\
         open(tsv_path, 'r') as f_tsv,\
         open(wrd_path, 'w') as f_wrd,\
         open(phn_path, 'w') as f_phn:
        for line in f_in:
            if trans_type == 'char':
                fn, _, text = line.strip().split('|')[:3]
            elif trans_type == 'phn': # If using phonemes, use the orthographic transcript as inputs to G2P
                fn, text, _ = line.strip().split('|')[:3]
            utterance_id = fn.split('/')[-1].split('.')[0]
            wrds = []
            phns = []
            text_dict[utterance_id] = {'wrd': None, 'phn': None}
            for w in text.split(): 
                wrd = []
                for phn in w.lower():
                    if phn.isalpha():
                        phns.append(phn)
                        wrd.append(phn)
                if len(wrd):
                    wrds.append(''.join(wrd))
            text_dict[utterance_id]['wrd'] = ' '.join(wrds)
            text_dict[utterance_id]['phn'] = ' '.join(phns)

        for i, line in enumerate(f_tsv):
            if i == 0:
                continue
            utterance_id = line.split('\t')[0].split('/')[1].rstrip('.wav')
            f_wrd.write(text_dict[utterance_id]['wrd']+'\n')
            f_phn.write(text_dict[utterance_id]['phn']+'\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('in_path')
    parser.add_argument('tsv_path')
    parser.add_argument('wrd_path')
    parser.add_argument('phn_path')
    parser.add_argument('trans_type')
    args = parser.parse_args()
    main(args.in_path, args.tsv_path, args.wrd_path, args.phn_path, args.trans_type)
