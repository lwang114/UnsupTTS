import os
import argparse
import shutil
import pathlib

def main(in_path, out_dir, val_size):
    in_path = pathlib.Path(in_path)
    shutil.copyfile(in_path, in_path.parent / 'all.tsv')
    with open(in_path, 'r') as f_in,\
         open(os.path.join(out_dir, 'train.tsv'), 'w') as f_tr,\
         open(os.path.join(out_dir, 'valid.tsv'), 'w') as f_val:
        lines = f_in.read().strip().split('\n')
        f_tr.write('\n'.join(lines[-val_size:]))
        f_val.write('\n'.join(lines[-val_size:]))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_path', required=True)
    parser.add_argument('--val_size', type=int, required=True)
    parser.add_argument('--out_dir', required=True)
    args = parser.parse_args()

    main(args.in_path, 
         args.out_dir,
         args.val_size)
