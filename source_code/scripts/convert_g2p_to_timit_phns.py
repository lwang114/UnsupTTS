import argparse
import os

def convert_g2p_to_timit_phns(in_path, out_path):
    with open(in_path, 'r') as f_in,\
         open(out_path, 'w') as f_out:
        for line in f_in:
            l_out = []
            for phn in line.rstrip('\n').split():
                if phn == '<SIL>':
                    l_out.append('sil')
                else:
                    l_out.append(phn.lower())
            f_out.write(' '.join(l_out)+'\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('in_path')
    parser.add_argument('out_path')
    args = parser.parse_args()           
    convert_g2p_to_timit_phns(args.in_path, args.out_path)
 
