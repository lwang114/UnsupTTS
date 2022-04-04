#!/bin/bash

ljspeech_root=$1
tgt_dir_lj=$2
model=$3
fasttext_model=$4
checkpoint_root=$5
espnet_root=$6
gpu_num=$7

stage=2
stop_stage=5

if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
    new_ljspeech_root=$ljspeech_root/wavs_16khz
    if [ ! -d $new_ljspeech_root ]; then
        mkdir -p $new_ljspeech_root
        for fn in $(find ${ljspeech_root}/wavs -name "*.wav"); do
            suffix=${fn##*/}
            sox $fn -r 16000 -c 1 -b 16 ${new_ljspeech_root}/${suffix}
        done
    fi
    python $FAIRSEQ_ROOT/examples/wav2vec/wav2vec_manifest.py $new_ljspeech_root --ext wav --dest $tgt_dir_lj/with_silence --valid-percent 0 || error "wav2vec_manifest 1 failed"
    python scripts/vads.py -r $RVAD_ROOT < $tgt_dir_lj/with_silence/train.tsv > train.vads || error "vad failed"
    python scripts/remove_silence.py --tsv $tgt_dir_lj/with_silence/train.tsv --vads train.vads --out $tgt_dir_lj/without_silence/wavs || error "remove silence failed"
    python $FAIRSEQ_ROOT/examples/wav2vec/wav2vec_manifest.py $tgt_dir_lj/without_silence/wavs --ext wav --dest $tgt_dir_lj/without_silence --valid-percent 0 || error "wav2vec_manifest 2 failed" 
fi

# Extract LJSpeech features
if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
    bash scripts/prepare_audio.sh $tgt_dir_lj/without_silence $tgt_dir_lj/without_silence/feat $model 512 14 $gpu_num
fi

# Phonemize text
if [ $stage -le 4 ] && [ $stop_stage -ge 4 ]; then
    # Prepare .wrd file
    if [ ! -f $tgt_dir_lj/without_silence/train.wrd ]; then
        python scripts/convert_metadata_ljspeech.py $ljspeech_root/metadata.csv $tgt_dir_lj/without_silence/train.tsv $tgt_dir_lj/without_silence/train.wrd
    fi
    #zsh scripts/prepare_text.sh en $tgt_dir_lj/without_silence/train.wrd $tgt_dir_lj/without_silence 1 G2P $fasttext_model
    if [ ! -f $tgt_dir_lj/without_silence/train.phn ]; then
        python scripts/convert_g2p_to_timit_phns.py $tgt_dir_lj/without_silence/phones/lm.phones.filtered.txt $tgt_dir_lj/without_silence/train.phn
    fi
fi

# Process generated text
if [ $stage -le 5 ] && [ $stop_stage -ge 5 ]; then
    if [ ! -d $checkpoint_root/ljspeech ]; then
        mkdir -p $checkpoint_root/ljspeech
        python3 scripts/merge_transcripts.py \
            --in_dir $checkpoint_root \
            --out_prefix $checkpoint_root/ljspeech/all
    fi

    for split in train dev eval deveval train_no_dev; do
        if [ ! -f $espnet_root/data/phn_$split ]; then
            cp -r $espnet_root/data/char_$split $espnet_root/data/phn_$split
        fi
        python3 scripts/convert_wav2vecu_to_kaldi.py \
            --in_path $checkpoint_root/ljspeech/all.txt \
            --in_id_path $checkpoint_root/ljspeech/all.tsv \
            --out_id_path $espnet_root/data/char_$split/wav.scp \
            --out_path $espnet_root/data/phn_$split/text 
        #python3 scripts/convert_wav2vecu_to_kaldi.py \
        #    --in_path $checkpoint_root/ljspeech/train.txt \
        #    --in_id_path $tgt_dir_lj/without_silence/train.tsv \
        #    --out_id_path $espnet_root/data/char_$split/wav.scp \
        #    --out_path $espnet_root/data/phn_$split/text 
    done
fi
