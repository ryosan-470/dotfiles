#!/bin/bash
# Install oh-my-zsh (initialize section)
echo "Init Oh-my-zsh"
cd ${HOME}
if [ ! -d ~/.oh-my-zsh ]; then
    if type curl > /dev/null 2>&1; then
        curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
    else
        # curl がない場合はwgetを使う
        wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh  && sh install.sh
    fi

    rm -f ${HOME}/.zshrc  # oh-my-zsh で自動生成される.zshrcを削除
    mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc
fi
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
