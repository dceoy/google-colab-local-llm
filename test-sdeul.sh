#!/usr/bin/env bash

set -euox pipefail

head -20 /etc/*-release
df -Th
free -g
nvidia-smi || :

case "${OSTYPE}" in
  darwin* )
    brew update -q
    brew upgrade -q
    brew install -q aria2
    brew cleanup -q
    ;;
  linux* )
    apt-get -y update -qq
    apt-get -y upgrade -qq
    apt-get -y install -qq --no-install-recommends --no-install-suggests \
      aria2 time
    apt-get -y autoremove -qq
    apt-get clean -qq
    rm -rf /var/lib/apt/lists/*
    ;;
esac

export CMAKE_ARGS='-DLLAMA_CUBLAS=on' FORCE_CMAKE=1

curl -sSLO https://github.com/dceoy/sdeul/archive/main.tar.gz
pip install -q -U --no-cache-dir ./main.tar.gz
tar xf main.tar.gz && rm -f main.tar.gz
[[ ! -d tests ]] || rm -rf tests
mv sdeul-main/test/data tests && rm -rf sdeul-main

LLM_URLS=( \
  # 4.78 GB
  #'https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q5_K_M.gguf' \
  # 9.23 GB
  #'https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q5_K_M.gguf' \
  # 30.6 GB
  #'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_S.gguf' \
  # 41.4 GB
  'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q4_K_M.gguf' \
  # 48.8 GB
 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_M.gguf' \
  # 36.7 GB, 36.6 GB
  #'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q8_0.gguf-split-a' \
  #'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q8_0.gguf-split-b' \
  # 32.2 GB
  'https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q5_K_M.gguf' \
  # 14 GB
  'https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/resolve/main/ELYZA-japanese-Llama-2-13b-fast-instruct-q8_0.gguf' \
  # 7.84 GB
  'https://huggingface.co/mmnga/RakutenAI-7B-chat-gguf/resolve/main/RakutenAI-7B-chat-q8_0.gguf' \
)

[[ ! -d models ]] || rm -rf models
mkdir models
for u in "${LLM_URLS[@]}"; do
  aria2c \
    --dir models --console-log-level=warn -x 16 -s 16 -k 1M \
    "${u}" -o "$(basename "${u}")"
  time sdeul extract \
    --pretty-json --model-gguf="models/$(basename "${u}")" \
    --n-batch=1 \
    --n-gpu-layers=-1 \
    tests/medication_history.schema.json \
    tests/patient_medication_record.txt || :
done
