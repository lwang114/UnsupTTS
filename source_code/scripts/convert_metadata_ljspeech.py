import os
import argparse

def convert_fairseq(in_path, tsv_path, out_path):
    text_dict = dict()
    with open(in_path, 'r') as f_in,\
         open(tsv_path, 'r') as f_tsv,\
         open(out_path, 'w') as f_out:
        for line in f_in:
            utterance_id, text = line.strip().split('|')[:2]
            text_dict[utterance_id] = text
            
        for i, line in enumerate(f_tsv):
            if i == 0:
                continue
            utterance_id = line.split('\t')[0].split('/')[1].rstrip('.wav')
            text = text_dict[utterance_id]
            f_out.write(text+'\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('in_path')
    parser.add_argument('tsv_path')
    parser.add_argument('out_path')
    args = parser.parse_args()
    convert_fairseq(args.in_path, args.tsv_path, args.out_path)
