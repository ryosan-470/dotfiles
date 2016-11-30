#!/bin/bash
if [ ! -e ~/.local.zsh ]; then
    echo "Make ~/.local.zsh"
    cat <<EOF > ~/.local.zsh
# -*- mode: sh -*-
# This area is for local configuration which is depend on your environment.
EOF
fi

if [ ! -e ~/.gitconfig.local ]; then
    echo "Make ~/.gitconfig.local"
    cat <<EOF > ~/.gitconfig.local
# -*- mode: gitconfig -*-
EOF
fi

echo "Finished"
exit 0
