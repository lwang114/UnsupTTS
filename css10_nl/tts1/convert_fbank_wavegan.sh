#!/bin/bash

pretrained_model_tag=$1
feats_scp=$2
outdir=$3
echo $pretrained_model_tag

stage=1
stop_stage=1
pretrain_dir=../../pretrain_model

# Download wavegan and pretrained models
if [ $stage -le 0 ] && [ $stop_stage -ge 0 ]; then
    #. ./path.sh && pip install -U parallel_wavegan
    mkdir -p ${pretrain_dir}
    python local/download_wavegan.py --pretrained_model_tag $pretrained_model_tag
    ls ${pretrain_dir}/$pretrained_model_tag
fi

# Convert Mel filterbanks to audio waveforms
if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
    parallel-wavegan-decode \
        --checkpoint ${pretrain_dir}/train_nodev_${pretrained_model_tag}/checkpoint-2500000steps.pkl \
        --feats-scp $feats_scp \
        --outdir $outdir
fi
