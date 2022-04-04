import argparse
import os
import shutil
from tqdm import tqdm

SIL = '<SIL>'
def convert_transcript(in_path, in_id_path, out_id_path, out_path):
    """
    Args:
        in_path : str, path to the input transcripts
        in_id_path : str, path to the .tsv file with utterance ids in the 
                     same order as in in_path (first line is header)
        out_id_path : str, path to the output ids in the same order as in
                      out_path
        out_path : str, path to the output transcripts
    """
    with open(in_path, 'r') as f_in,\
         open(in_id_path, 'r') as f_inid,\
         open(out_id_path, 'r') as f_outid,\
         open(out_path, 'w') as f_out:
        in_lines = f_inid.read().strip().split('\n')[1:] # Skip header
        texts = f_in.read().strip().split('\n')
        out_lines = f_outid.read().strip().split('\n')
    
        utt2text = dict()
        for line, text in tqdm(zip(in_lines, texts)):
            utt_id = line.split()[0].split('/')[-1].split('.')[0]
            utt2text[utt_id] = text

        for line in tqdm(out_lines):
            utt_id = line.split()[0].split('/')[-1]
            f_out.write(f'{utt_id} {utt2text[utt_id]}\n')

def main(in_path, in_id_path, wav_dir, out_dir):
    """
    Args:
        in_path : str, path to the pseudo transcripts 
        in_id_path : str, path to the .tsv file with utterance ids in the 
                     same order as in in_path (first line is header)
        wav_dir : str, path to the .wav files
        out_dir : str, path to the output transcripts
    """

    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    with open(in_path, 'r') as f_in,\
         open(in_id_path, 'r') as f_inid,\
         open(os.path.join(out_dir, 'text'), 'w') as f_txt,\
         open(os.path.join(out_dir, 'utt2spk'), 'w') as f_utt2spk,\
         open(os.path.join(out_dir, 'wav.scp'), 'w') as f_wvscp:
        in_lines = f_inid.read().strip().split('\n')[1:]
        lines = [line.strip() for line in f_in]
        print(in_path, in_id_path) # XXX

        utt_ids = [line.split()[0] for line in lines]
        texts = [' '.join(line.split()[1:]) for line in lines]
    
        for idx, (utt_id, line, text) in tqdm(enumerate(zip(utt_ids, in_lines, texts))):
            fn = line.split()[0].split('/')[-1]
            if not len(text.strip().split()):
                print(f'Warning: {utt_id} contains no speech')
                text = SIL
            wav_path = os.path.join(wav_dir, fn)
            if not os.path.exists(wav_path):
                for subdir in os.listdir(wav_dir):
                    wav_path = os.path.join(wav_dir, subdir, fn)
                    if not subdir in ['wavs_16khz', 'wavs_16bit'] and os.path.exists(wav_path):
                        break
            f_wvscp.write(f'{utt_id} {wav_path}\n')
            f_txt.write(f'{utt_id} {text}\n')
            f_utt2spk.write(f'{utt_id} {utt_id}\n')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--in_path')
    parser.add_argument('--in_id_path')
    parser.add_argument('--wav_dir')
    parser.add_argument('--out_dir')
    #parser.add_argument('--out_id_path')
    #parser.add_argument('--out_path')
    args = parser.parse_args()

    main(
        args.in_path, 
        args.in_id_path, 
        args.wav_dir, 
        args.out_dir
    )
