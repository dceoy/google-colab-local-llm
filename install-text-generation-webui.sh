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
