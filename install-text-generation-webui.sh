#!/usr/bin/env bash

set -euox pipefail

if [[ ! -d text-generation-webui ]]; then
  ./print-github-tags/print-github-tags \
    --release --latest --tar oobabooga/text-generation-webui \
    | xargs -t curl -SL -o text-generation-webui.tar.gz
  tar xvf text-generation-webui.tar.gz
  rm -f text-generation-webui.tar.gz
  mv text-generation-webui-* text-generation-webui
fi
