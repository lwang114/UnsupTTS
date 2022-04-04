import argparse
import os
import glob

def merge_transcripts(in_dir, out_prefix):
    with open(out_prefix+'.txt', 'w') as merged_trans_f,\
         open(out_prefix+'.tsv', 'w') as merged_tsv_f:
        for i, fn in enumerate(glob.glob(os.path.join(in_dir, 'hypo.phn-checkpoint_best.*'))):
            split = fn.split('-')[-2] # hypo.phn-checkpoint_best.pt-train-fixed
            print(fn, split)
            with open(fn, 'r') as trans_f,\
                 open(os.path.join(in_dir, f'{split}.tsv'), 'r') as tsv_f:
                merged_trans_f.write(trans_f.read().rstrip('\n')+'\n')
                if i == 0:  
                    merged_tsv_f.write(tsv_f.read().rstrip('\n')+'\n')
                else:
                    merged_tsv_f.write('\n'.join(tsv_f.read().split('\n')[1:-1])+'\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_dir')
    parser.add_argument('--out_prefix')
    args = parser.parse_args()
    merge_transcripts(args.in_dir, args.out_prefix) 
