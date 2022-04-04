import os
import glob
import argparse

def main(manifest_dir, split, out_dir):
    with open(os.path.join(manifest_dir, f'{split}.tsv'), 'r') as f_tsv,\
         open(os.path.join(manifest_dir, f'{split}.ltr'), 'r') as f_ltr:
        header = None
        for line in f_tsv:
            if not header:
                header = line
                break

        for line, tran in zip(f_tsv, f_ltr):
            wav_path, _ = line.rstrip().split('\t')
            wav_id = wav_path.split('/')[-1].split('.')[0]
            with open(os.path.join(out_dir, f'{split}_{wav_id}.tsv'), 'w') as f_tsv_out,\
                 open(os.path.join(out_dir, f'{split}_{wav_id}.ltr'), 'w') as f_ltr_out:
                f_tsv_out.write(header+'\n'+line)
                f_ltr_out.write(tran)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifest_dir')
    parser.add_argument('--split')
    parser.add_argument('--out_dir')
    args = parser.parse_args()
    main(args.manifest_dir, args.split, args.out_dir)
