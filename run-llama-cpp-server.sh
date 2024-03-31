#!/usr/bin/env bash

set -euox pipefail

head -20 /etc/*-release
df -Th
free -g
nvidia-smi || :

apt-get -y update -qq
apt-get -y upgrade -qq
apt-get -y install -qq --no-install-recommends --no-install-suggests aria2
apt-get -y autoremove -qq
apt-get clean -qq
rm -rf /var/lib/apt/lists/*

curl -sSLO https://raw.githubusercontent.com/dceoy/print-github-tags/master/print-github-tags
chmod +x print-github-tags

[[ ! -d llama.cpp ]] || rm -rf llama.cpp
./print-github-tags --release --latest --tar ggerganov/llama.cpp \
  | xargs -t curl -sSL -o llama.cpp.tar.gz
tar xf llama.cpp.tar.gz && rm -f llama.cpp.tar.gz
mv llama.cpp-* llama.cpp
cd llama.cpp
make LLAMA_CUDA=1 &
cd ..

LLM_URLS=( \
  # 4.78 GB
  # 'https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q5_K_M.gguf' \
  # 9.23 GB
  # 'https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q5_K_M.gguf' \
  # 30.6 GB
  # 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_S.gguf' \
  # 41.4 GB
  # 'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q4_K_M.gguf' \
  # 48.8 GB
  'https://huggingface.co/TheBloke/Llama-2-70B-Chat-GGUF/resolve/main/llama-2-70b-chat.Q5_K_M.gguf' \
  # 32.2 GB
  # 'https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q5_K_M.gguf' \
  # 14 GB
  # 'https://huggingface.co/mmnga/ELYZA-japanese-Llama-2-13b-fast-instruct-gguf/resolve/main/ELYZA-japanese-Llama-2-13b-fast-instruct-q8_0.gguf' \
  # 7.84 GB
  # 'https://huggingface.co/mmnga/RakutenAI-7B-chat-gguf/resolve/main/RakutenAI-7B-chat-q8_0.gguf' \
)

for u in "${LLM_URLS[@]}"; do
  aria2c --dir ./models --console-log-level=warn -x 16 -s 16 -k 1M "${u}" -o "$(basename "${u}")"
done

wait

[[ ! -d models ]] || rm -rf models
mkdir models
./llama.cpp/server \
  --port 8000 \
  --host 0.0.0.0 \
  -n 512 \
  -m ./models/llama-2-70b-chat.Q5_K_M.gguf
