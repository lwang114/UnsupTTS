#!/bin/bash
css_root=$1
tgt_dir_css=$2
model=$3
fasttext_model=$4
checkpoint_root=$5
espnet_root=$6
gpu_num=$7
lang=$8
g2p_models_dir=$9

stage=3
stop_stage=3


if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
    new_css_root=$css_root/wavs_16khz
    if [ ! -d $new_css_root ]; then
        mkdir -p $new_css_root
        for fn in $(find ${css_root} -name "*.wav"); do
            echo $fn
            suffix=${fn##*/}
            sox $fn -r 16000 -c 1 -b 16 ${new_css_root}/${suffix}
        done
    fi
    python $FAIRSEQ_ROOT/examples/wav2vec/wav2vec_manifest.py $new_css_root --ext wav --dest $tgt_dir_css/with_silence --valid-percent 0 || error "wav2vec_manifest 1 failed"
    python scripts/vads.py -r $RVAD_ROOT < $tgt_dir_css/with_silence/train.tsv > train.vads || error "vad failed"
    python scripts/remove_silence.py --tsv $tgt_dir_css/with_silence/train.tsv --vads train.vads --out $tgt_dir_css/without_silence/wavs || error "remove silence failed"
    python $FAIRSEQ_ROOT/examples/wav2vec/wav2vec_manifest.py $tgt_dir_css/without_silence/wavs --ext wav --dest $tgt_dir_css/without_silence --valid-percent 0.01 || error "wav2vec_manifest 2 failed" 
fi

# Extract .wrd and .phn files, Extract wav2vec features
if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
    if [ ! -f $tgt_dir_css/without_silence/${split}.wrd ]; then
        for split in train valid; do
            python scripts/convert_metadata_css.py $css_root/transcript.txt \
                $tgt_dir_css/without_silence/${split}.tsv \
                $tgt_dir_css/without_silence/${split}.wrd \
                $tgt_dir_css/without_silence/${split}.phn
        done
        cat $tgt_dir_css/without_silence/train.wrd $tgt_dir_css/without_silence/valid.wrd > $tgt_dir_css/without_silence/all.wrd
        cat $tgt_dir_css/without_silence/train.phn $tgt_dir_css/without_silence/valid.phn > $tgt_dir_css/without_silence/all.phn
    fi
    bash scripts/prepare_audio.sh $tgt_dir_css/without_silence $tgt_dir_css/without_silence/feat $model 512 14 $gpu_num
fi

# Prepare text
if [ $stage -le 4 ] && [ $stop_stage -ge 4 ]; then
    zsh scripts/prepare_text_css10.sh $lang $tgt_dir_css/without_silence 1 $g2p_models_dir $fasttext_model
fi
