import os
import shutil
import argparse

def main(in_tsv, out_dir):
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    in_dir = None
    with open(in_tsv, 'r') as f_tsv:
        for idx, line in enumerate(f_tsv):
            if idx == 0:
                in_dir = line.rstrip('\n')
                print(in_dir)
                continue
            wav_path = line.rstrip('\n').split()[0]
            new_wav_path = f'utt{idx:010d}.wav'
            print(new_wav_path)
            shutil.copyfile(os.path.join(in_dir, wav_path), os.path.join(out_dir, new_wav_path))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_tsv')
    parser.add_argument('--out_dir')
    args = parser.parse_args()
    main(args.in_tsv, args.out_dir)
