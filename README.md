# Unsupervised Text-to-Speech Synthesis by Unsupervised Automatic-Speech-Recognition
<div align="left"><img src="doc/image/unsup_tts.drawio.png" width="800"/></div>

UnsupTTS is an unsupervised text-to-speech (TTS) system learned from unparallel speech and text data

If you find this project useful, please consider citing our paper.
```
@inproceedings{Ni-etal-2022-unsup-tts,
  author={Junrui Ni, Liming Wang, Heting Gao, Kaizhi Qian, Yang Zhang, Shiyu Chang, Mark Hasegawa-Johnson},
  title={Unsupervised text-to-speech synthesis by unsupervised automatic speech recognition},
  booktitle={arKiv},
  year={2022},
  url={https://arxiv.org/pdf/2203.15796.pdf}
}
```
### Speech demo
Speech samples can be found [here](https://cactuswiththoughts.github.io/UnsupTTS-Demo/)

### Dependencies
- [fairseq](https://github.com/pytorch/fairseq) >= 1.0.0 with dependencies for [wav2vec-u](https://github.com/pytorch/fairseq/tree/main/examples/wav2vec/unsupervised)
- [ESPnet](https://github.com/espnet/espnet) <= 010f483e7661019761b169563ee622464125e56f
- [ParallelWaveGAN](https://github.com/kan-bayashi/ParallelWaveGAN)
- [LanguageNet G2Ps](https://github.com/uiuc-sst/g2ps) (For models using phoneme transcripts only)

### How to run it?

0.Download the LJSpeech and CSS10 datasets; modify the paths and settings in source_code/unsupervised/run_css10_cpy2.slurm and tts1/css10_nl/run.sh. Current default language is Dutch (nl) with phoneme transcripts, but you can change the ```$lang``` variable to change the language and ```$trans_type``` variable to change the transcript type.

1.Run ```bash run_css10_cpy2.slurm```


### Pretrained models
| LJSpeech | ASR | TTS |
|--|--|--|
| en |[link]|[link]|

| CSS10 | Unit | ASR | TTS |
|---------|---------|---------|---------|
| ja | char |[link]|[link](https://drive.google.com/file/d/191J9NwPZmnRlgunieYCr2oM2VwmbcELD/view?usp=sharing)|
| hu | char |[link]|[link](https://drive.google.com/file/d/1hX2HBn3gdYEdF5PxqWMLbDtLE-JOMjTL/view?usp=sharing)|
| nl | char |[link]|[link](https://drive.google.com/file/d/14CyW14L7VCKnti8aMnOvJsq3ENlbtcIi/view?usp=sharing)|
| fi | char |[link]|[link]|
| es | char |[link]|[link]|
| de | char |[link]|[link]|
| hu | phn |[link]|[link](https://drive.google.com/file/d/1hX2HBn3gdYEdF5PxqWMLbDtLE-JOMjTL/view?usp=sharing)|
| nl | phn |[link]|[link](https://drive.google.com/file/d/14CyW14L7VCKnti8aMnOvJsq3ENlbtcIi/view?usp=sharing)|
| fi | phn |[link]|[link]|
