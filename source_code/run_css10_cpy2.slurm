#!/bin/bash
#SBATCH -J wav2vecu_css10
#SBATCH -o wav2vecu_css10_%j.out
#SBATCH -e wav2vecu_css10_%j.err
#SBATCH --mail-user=limingw@mit.edu
#SBATCH --qos=sched_level_2
#SBATCH --mail-type=ALL
#SBATCH --gres=gpu:4
#SBATCH --gpus-per-node=4
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=0
#SBATCH --time=24:00:00
#SBATCH --exclusive

function error
{
    if [ -z "$1" ]
    then
        message="fatal error"
    else
        message="fatal error: $1"
    fi

    echo $message
    echo "finished at $(date)"
    exit 1
}

source /nobackup/users/junruin2/anaconda3/etc/profile.d/conda.sh
lang="nl"
trans_type="phn"
tts_type="unsupervised"
gpu_num=4
g2p_models_dir=/nobackup/users/junruin2/g2ps/models
phoneticsaurus=/nobackup/users/junruin2/kaldi/tools/phonetisaurus-g2p
css_root=/nobackup/users/limingw/data/css10/${lang}
if [ ${trans_type} = phn ]; then
    tgt_dir=resources/phn_css10_${lang}
else
    tgt_dir=resources/css10_${lang}
fi
root=/nobackup/users/limingw/spring2022/source_code
#model=${root}/unsupervised/checkpoints/wav2vec2/xlsr_53_56k.pt
model=${root}/unsupervised/checkpoints/wav2vec2/wav2vec_vox_new.pt
fasttext_model=/nobackup/users/junruin2/fairseq_expspring2022/examples/wav2vec/unsupervised/scripts/lid.176.bin

if [ ${lang} = nl ]; then
    if [ ${trans_type} = phn ]; then
        checkpoint_root=$root/unsupervised/multirun/2022-02-22/14-55-49/1
    else
        checkpoint_root=$root/unsupervised/multirun/2022-02-22/14-55-49/0
    fi
elif [ ${lang} = ja ]; then 
    checkpoint_root=$root/unsupervised/multirun/2022-02-20/23-33-49/0
elif [ ${lang} = hu ]; then
    if [ ${trans_type} = phn ]; then
        checkpoint_root=$root/unsupervised/multirun/2022-03-19/16-16-42/0 
    else
        checkpoint_root=$root/unsupervised/multirun/2022-02-27/18-42-14/0 
    fi
elif [ ${lang} = ru ]; then 
    checkpoint_root=$root/unsupervised/multirun/2022-02-27/18-43-18/2
elif [ ${lang} = de ]; then
    checkpoint_root=$root/unsupervised/multirun/???
elif [ ${lang} = zh ]; then
    checkpoint_root=$root/unsupervised/multirun/???
else
    error "Unknown language ${lang}"
fi

if [ ${tts_type} = unsupervised ]
    then
        espnet_root=/nobackup/users/junruin2/espnet_tracked/egs/limingw/css10_${lang}/tts1
    else
        espnet_root=/nobackup/users/junruin2/espnet_tracked/egs/limingw/css10_${lang}/tts2
fi
echo $espnet_root

KALDI_ROOT=/nobackup/users/junruin2/pykaldi_expspring2022/tools/kaldi
FAIRSEQ_ROOT=/nobackup/users/junruin2/fairseq_expspring2022
RVAD_ROOT=/nobackup/users/junruin2/rVAD/rVADfast_py_2.0
KENLM_ROOT=/nobackup/users/junruin2/kenlm/build/bin
export root
export KALDI_ROOT
export FAIRSEQ_ROOT
export RVAD_ROOT
export KENLM_ROOT

stage=11
stop_stage=11
if [ $stage -le 0 ] && [ $stop_stage -ge 0 ]; then
    if [ ! -d $tgt_dir ]; then
        mkdir -p $tgt_dir
    fi
    bash scripts/prepare_css10.sh \
        $css_root $root/unsupervised/$tgt_dir \
        $model $fasttext_model \
        $checkpoint_root \
        $gpu_num $lang \
        $phoneticsaurus \
        $g2p_models_dir \
        $trans_type || error "prepare_css10.sh failed" 
fi

if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
    PREFIX=w2v_unsup_gan_xp
    TASK_DATA=$root/unsupervised/$tgt_dir/without_silence/feat/precompute_pca512_cls128_mean_pooled 
    TEXT_DATA=$root/unsupervised/$tgt_dir/without_silence/phones  # path to fairseq-preprocessed GAN data (phones dir)
    KENLM_PATH=$root/unsupervised/$tgt_dir/without_silence/phones/lm.phones.filtered.04.bin #kenlm.phn.o4.bin  # KenLM 4-gram phoneme language model (LM data = GAN data here)

    PYTHONPATH=$FAIRSEQ_ROOT PREFIX=$PREFIX fairseq-hydra-train \
        -m --config-dir config/gan \
        --config-name w2vu_4gpu_uer_bestonly \
        task.data=${TASK_DATA} \
        task.text_data=${TEXT_DATA} \
        task.kenlm_path=${KENLM_PATH} \
        common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
        model.code_penalty=4 model.gradient_penalty=2.0 \
        model.smoothness_weight=0.5,1.0 'common.seed=range(0,1)'
 
    PYTHONPATH=$FAIRSEQ_ROOT PREFIX=$PREFIX fairseq-hydra-train \
        -m --config-dir config/gan \
        --config-name w2vu_4gpu_uer_bestonly \
        task.data=${TASK_DATA} \
        task.text_data=${TEXT_DATA} \
        task.kenlm_path=${KENLM_PATH} \
        common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
        model.code_penalty=4 model.gradient_penalty=2.0 \
        model.smoothness_weight=0.75 'common.seed=range(0,1)'
        
#    PYTHONPATH=$FAIRSEQ_ROOT PREFIX=$PREFIX fairseq-hydra-train \
#        -m --config-dir config/gan \
#        --config-name w2vu_4gpu_uer_bestonly \
#        task.data=${TASK_DATA} \
#        task.text_data=${TEXT_DATA} \
#        task.kenlm_path=${KENLM_PATH} \
#        common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
#        model.code_penalty=4 model.gradient_penalty=1.5 \
#        model.smoothness_weight=0.75,0.5,1.0 'common.seed=range(0,1)'
        
#    PYTHONPATH=$FAIRSEQ_ROOT PREFIX=$PREFIX fairseq-hydra-train \
#        -m --config-dir config/gan \
#        --config-name w2vu_4gpu_uer_bestonly \
#        task.data=${TASK_DATA} \
#        task.text_data=${TEXT_DATA} \
#        task.kenlm_path=${KENLM_PATH} \
#        common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
#        model.code_penalty=2 model.gradient_penalty=2.0 \
#        model.smoothness_weight=0.5,0.75,1.0 'common.seed=range(0,1)'
        
#    PYTHONPATH=$FAIRSEQ_ROOT PREFIX=$PREFIX fairseq-hydra-train \
#        -m --config-dir config/gan \
#        --config-name w2vu_4gpu_uer_bestonly \
#        task.data=${TASK_DATA} \
#        task.text_data=${TEXT_DATA} \
#        task.kenlm_path=${KENLM_PATH} \
#        common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
#        model.code_penalty=2 model.gradient_penalty=1.5 \
#        model.smoothness_weight=0.75,0.5,1.0 'common.seed=range(0,1)'
fi

if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
    cwd=$(pwd)
    cp ${cwd}/$tgt_dir/without_silence/phones/dict.phn.txt ${cwd}/$tgt_dir/without_silence/feat/precompute_pca512_cls128_mean_pooled
    cd ${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised
    for split in train; do # valid
        HYDRA_FULL_ERROR=1 python w2vu_generate.py --config-dir ${cwd}/config/generate --config-name viterbi \
        fairseq.common.user_dir=${FAIRSEQ_ROOT}/examples/wav2vec/unsupervised \
        fairseq.task.data=${cwd}/$tgt_dir/without_silence/feat/precompute_pca512_cls128_mean_pooled \
        fairseq.common_eval.path=${checkpoint_root}/checkpoint_best.pt \
        fairseq.dataset.gen_subset=${split} results_path=${checkpoint_root}/css10_${lang}_mean_pooled
    done
    cd ${cwd}
fi

# Kaldi self-training
if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
    LM_PATH=$root/unsupervised/$tgt_dir/without_silence/phones/lm.phones.filtered.04.arpa
    KENLM_PATH=$root/unsupervised/$tgt_dir/without_silence/phones/lm.phones.filtered.04.bin #kenlm.phn.o4.bin  # KenLM 4-gram phoneme language model (LM data = GAN data here)

    cwd=$(pwd)
    cd kaldi_self_train/st
    if [ -L utils ]; then
        rm utils
    fi
    if [ -L steps ]; then
        rm steps
    fi 
    ln -s $KALDI_ROOT/egs/wsj/s5/utils utils
    ln -s $KALDI_ROOT/egs/wsj/s5/steps steps
    cp ${cwd}/$tgt_dir/without_silence/phones/dict.phn.txt ${cwd}/$tgt_dir/without_silence/feat/precompute_pca512

    bash train.sh $root/unsupervised/$tgt_dir/without_silence/feat/precompute_pca512 \
        ${checkpoint_root}/css10_${lang}_mean_pooled \
        ${checkpoint_root}/st \
        ${LM_PATH} \
        ${KENLM_PATH}
    cd ${cwd} 
fi

if [ $stage -le 4 ] && [ $stop_stage -ge 4 ]; then
    cwd=$(pwd)
    cd kaldi_self_train/st
    bash decode_phone.sh ${checkpoint_root}/st \
        7.0.0 tri2b \
        steps/decode.sh
    cd ${cwd}
fi

# Process generated text
if [ $stage -le 5 ] && [ $stop_stage -ge 5 ]; then
    #if [ ! -d $checkpoint_root/css10_${lang} ]; then
    #    mkdir -p $checkpoint_root/css10_${lang}
    #    python3 scripts/merge_transcripts.py \
    #        --in_dir $checkpoint_root \
    #        --out_prefix $checkpoint_root/css10_${lang}/all
    #fi
    #for split in train dev eval deveval train_no_dev; do
    if [ $tts_type = "unsupervised" ]
        then
            for split in train valid; do 
                # Prepare Kaldi directory using the pseudo-transcripts by Wav2Vec-U
                python3 scripts/convert_wav2vecu_to_kaldi.py \
                    --in_path $checkpoint_root/st/dec_data/${split}/text \
                    --in_id_path $root/unsupervised/resources/css10_${lang}/without_silence/${split}.tsv \
                    --wav_dir ${css_root}/wavs_16bit \
                    --out_dir $espnet_root/data/${trans_type}_$split
            done

            for split in train valid; do
                # Prepare Kaldi directory using the ground truth transcripts
                python3 scripts/convert_wav2vecu_to_kaldi.py \
                    --in_path $checkpoint_root/st/data/${split}_gt/text \
                    --in_id_path $root/unsupervised/resources/css10_${lang}/without_silence/${split}.tsv \
                    --wav_dir ${css_root}/wavs_16bit \
                    --out_dir $espnet_root/data/${trans_type}_${split}_gt
            done
        else
            for split in train valid; do
                # Prepare Kaldi directory using the ground truth transcripts
                python3 scripts/convert_wav2vecu_to_kaldi.py \
                    --in_path $checkpoint_root/st/data/${split}_gt/text \
                    --in_id_path $root/unsupervised/resources/css10_${lang}/without_silence/${split}.tsv \
                    --wav_dir ${css_root}/wavs_16bit \
                    --out_dir $espnet_root/data/${trans_type}_$split
            done
    fi
fi

# Train unsupervised TTS
if [ $stage -le 6 ] && [ $stop_stage -ge 6 ]; then
    cwd=$(pwd)
    conda activate espnet-tracked
    cd $espnet_root
    bash run.sh 4 6 ${trans_type}
    bash run.sh 5 6 ${trans_type}
    bash run.sh 6 6 ${trans_type}
    conda deactivate
    cd $cwd
fi

# Prepare CSS10 for finetuning
if [ $stage -le 7 ] && [ $stop_stage -ge 7 ]; then
    for split in train valid; do
        python scripts/prepare_css10_labels.py \
            ${root}/unsupervised/resources/css10_${lang}/without_silence/${split}.wrd \
            --output-dir ${root}/unsupervised/resources/css10_${lang}/without_silence \
            --output-name ${root}/unsupervised/resources/css10_${lang}/without_silence/${split}
    done
fi

# XXX Finetune on CSS10
#if [ $stage -le 8 ] && [ $stop_stage -ge 8 ]; then
#    manifest_dir=${root}/unsupervised/resources/css10_${lang}/without_silence
#    model_dir=${root}/unsupervised/checkpoints/wav2vec2
#    save_dir=${root}/unsupervised/outputs/wav2vec2_finetune_${lang}
#    fairseq-hydra-train \
#        common.log_file=train.log \
#        checkpoint.save_dir=${save_dir} hydra.run.dir=${save_dir} \
#        +optimization.update_freq='[8]' \
#        task.data=${manifest_dir} \
#        model.w2v_path=${model_dir}/wav2vec-small \
#        --config-dir ${root}/unsupervised/config/finetuning \
#        --config-name wav2vec_finetune
#fi

# Generate manifest files for the resynthesized files from espnet
if [ $stage -le 9 ] && [ $stop_stage -ge 9 ]; then
    if [ $tts_type = "supervised" ]; then
        subsets=valid
    else
        subsets="valid_gt valid"
    fi
    
    for subset in ${subsets}; do
        manifest_dir=${root}/unsupervised/resources/css10_${lang}/without_silence
        dest=${root}/unsupervised/resources/css10_${lang}/without_silence/${subset}_tts
        model_dir=${root}/unsupervised/checkpoints/wav2vec2
        save_dir=${root}/unsupervised/outputs/wav2vec2_finetune_${lang}
        for suffix in "" _ljspeech_hifigan.v1; do
            generation_root=$espnet_root/exp/${trans_type}_train_pytorch_train_pytorch_tacotron2/outputs_model.loss.best_decode_denorm${suffix}_16khz/${trans_type}_${subset}
            dest=${generation_root}
            echo ${dest}
            split=$(echo $subset | cut -d"_" -f 1)
            cp ${manifest_dir}/${split}.* ${dest}
            python scripts/wav2vec_manifest.py \
                $generation_root --valid-percent 0 \
                --dest $dest --ext "wav"
            mv $generation_root/train.tsv $dest/${split}.tsv
        done
    done
fi

# Evaluate the synthetic speech using CER and WER
if [ $stage -le 10 ] && [ $stop_stage -ge 10 ]; then
    if [ $tts_type = "supervised" ]; then
        subsets=valid
    else
        subsets="valid_gt valid"
    fi

    for subset in ${subsets}; do
        split=$(echo $subset | cut -d"_" -f 1)
        save_dir=${root}/unsupervised/outputs/wav2vec2_finetune_${lang}
        for suffix in "" _ljspeech_hifigan.v1; do
            manifest_dir=$espnet_root/exp/${trans_type}_train_pytorch_train_pytorch_tacotron2/outputs_model.loss.best_decode_denorm${suffix}_16khz/${trans_type}_${subset}
            # CER
            python ${FAIRSEQ_ROOT}/examples/speech_recognition/infer.py \
                ${manifest_dir} --task audio_finetuning \
                --nbest 1 --path ${save_dir}/checkpoint_best.pt \
                --gen-subset ${split} --results-path ${checkpoint_root}/eval_asr \
                --w2l-decoder viterbi \
                --lm-weight 2 --word-score -1 \
                --sil-weight 0 --criterion ctc \
                --labels ltr --max-tokens 4000000 \
                --post-process none \
                --quiet

            # WER
            python ${FAIRSEQ_ROOT}/examples/speech_recognition/infer.py \
                ${manifest_dir} --task audio_finetuning \
                --nbest 1 --path ${save_dir}/checkpoint_best.pt \
                --gen-subset ${split} --results-path ${checkpoint_root}/eval_asr \
                --w2l-decoder viterbi \
                --lm-weight 2 --word-score -1 \
                --sil-weight 0 --criterion ctc \
                --labels ltr --max-tokens 4000000 \
                --post-process letter \
                --quiet

            #python -m examples.speech_synthesis.evaluation.eval_asr \
            #    --audio-header audio --text-header text --err-unit char --split ${subset} \
            #    --w2v-ckpt ${save_dir}/checkpoint_best.pt \
            #    --raw-manifest ${manifest_dir}/ --asr-dir ${checkpoint_root}/eval_asr
        done
    done
fi

# Evaluate individual synthetic speech utterance using CER and WER
if [ $stage -le 11 ] && [ $stop_stage -ge 11 ]; then
    if [ $tts_type = "supervised" ]; then
        subsets=valid
    else
        subsets=valid_gt
    fi

    for subset in ${subsets}; do
        split=$(echo $subset | cut -d"_" -f 1)
        save_dir=${root}/unsupervised/outputs/wav2vec2_finetune_${lang}
        for suffix in "" _ljspeech_hifigan.v1; do
            manifest_dir=$espnet_root/exp/${trans_type}_train_pytorch_train_pytorch_tacotron2/outputs_model.loss.best_decode_denorm${suffix}_16khz/${trans_type}_${subset}
            if [ -d ${manifest_dir}_single_utterance ]; then
                python split_manifest_into_single_utterance.py \
                    --manifest_dir ${manifest_dir} \
                    --split ${split} \
                    --out_dir ${manifest_dir}_single_utterance
            fi

            for subset in ${manifest_dir}_single_utterance/*.tsv; do
                # CER
                python ${FAIRSEQ_ROOT}/examples/speech_recognition/infer.py \
                    ${manifest_dir} --task audio_finetuning \
                    --nbest 1 --path ${save_dir}/checkpoint_best.pt \
                    --gen-subset ${split} --results-path ${checkpoint_root}/eval_asr_${split} \
                    --w2l-decoder viterbi \
                    --lm-weight 2 --word-score -1 \
                    --sil-weight 0 --criterion ctc \
                    --labels ltr --max-tokens 4000000 \
                    --post-process none \
                    --quiet

                # WER
                python ${FAIRSEQ_ROOT}/examples/speech_recognition/infer.py \
                    ${manifest_dir} --task audio_finetuning \
                    --nbest 1 --path ${save_dir}/checkpoint_best.pt \
                    --gen-subset ${split} --results-path ${checkpoint_root}/eval_asr_${split} \
                    --w2l-decoder viterbi \
                    --lm-weight 2 --word-score -1 \
                    --sil-weight 0 --criterion ctc \
                    --labels ltr --max-tokens 4000000 \
                    --post-process letter \
                    --quiet
            done

            #python -m examples.speech_synthesis.evaluation.eval_asr \
            #    --audio-header audio --text-header text --err-unit char --split ${subset} \
            #    --w2v-ckpt ${save_dir}/checkpoint_best.pt \
            #    --raw-manifest ${manifest_dir}/ --asr-dir ${checkpoint_root}/eval_asr
        done
    done
fi
