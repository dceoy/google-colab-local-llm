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
    apt-get -y install -qq --no-install-recommends --no-install-suggests aria2 
    apt-get -y autoremove -qq
    apt-get clean -qq
    rm -rf /var/lib/apt/lists/*
    ;;
esac

curl -sSLO https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags
chmod +x print-github-tags

[[ ! -d llama.cpp ]] || rm -rf llama.cpp
./print-github-tags --release --latest --tar ggerganov/llama.cpp \
  | xargs -t curl -sSL -o llama.cpp.tar.gz
tar xf llama.cpp.tar.gz && rm -f llama.cpp.tar.gz
mv llama.cpp-* llama.cpp
mkdir llama.cpp/build
cd llama.cpp/build
cmake .. -DLLAMA_CUBLAS=ON
cmake --build . --config Release
cd ../..

[[ ! -d text-generation-webui ]] || rm -rf text-generation-webui
./print-github-tags --release --latest --tar oobabooga/text-generation-webui \
  | xargs -t curl -sSL -o text-generation-webui.tar.gz
tar xf text-generation-webui.tar.gz && rm -f text-generation-webui.tar.gz
mv text-generation-webui-* text-generation-webui

pip install -q --no-cache-dir -r text-generation-webui/requirements.txt

LLM_URLS=( \
  # 30.6 GB
  'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_S.gguf' \
  # 41.4 GB
  'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q4_K_M.gguf' \
  # 48.8 GB
 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_M.gguf' \
  # 36.7 GB, 36.6 GB
  # 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q8_0.gguf-split-a' \
  # 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q8_0.gguf-split-b' \
  # 32.2 GB
  'https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q5_K_M.gguf' \
  # 14 GB
  'https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/resolve/main/ELYZA-japanese-Llama-2-13b-fast-instruct-q8_0.gguf' \
  # 7.84 GB
  'https://huggingface.co/mmnga/RakutenAI-7B-chat-gguf/resolve/main/RakutenAI-7B-chat-q8_0.gguf' \
)

for u in "${LLM_URLS[@]}"; do
  aria2c --dir text-generation-webui/models --console-log-level=warn -x 16 -s 16 -k 1M "${u}" -o "$(basename "${u}")"
done
