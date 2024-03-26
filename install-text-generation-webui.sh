#!/usr/bin/env bash

set -euox pipefail

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
    apt-get -y install -qq --no-install-recommends --no-install-suggests aria2 
    apt-get -y autoremove -qq
    apt-get clean -qq
    rm -rf /var/lib/apt/lists/*
    ;;
esac

if [[ ! -d text-generation-webui ]]; then
  aria2c \
    https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags
  chmod +x print-github-tags
  ./print-github-tags \
    --release --latest --tar oobabooga/text-generation-webui \
    | xargs -t aria2c -o text-generation-webui.tar.gz
  tar xvf text-generation-webui.tar.gz
  rm -f text-generation-webui.tar.gz
  mv text-generation-webui-* text-generation-webui
fi

pip install -q --no-cache-dir -r text-generation-webui/requirements.txt

LLM_URLS=( \
  'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_M.gguf' \   # 48.8 GB
  'https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q5_K_M.gguf' \  # 32.2 GB
  'https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/blob/main/ELYZA-japanese-Llama-2-13b-fast-instruct-q8_0.gguf' \  # 14 GB
  'https://huggingface.co/mmnga/RakutenAI-7B-chat-gguf/blob/main/RakutenAI-7B-chat-q8_0.gguf' \  # 7.84 GB
)

for u in "${LLM_URLS[@]}"; do
  aria2c --dir text-generation-webui/models --console-log-level=warn -x 16 -s 16 -k 1M "${u}"
done
