#!/bin/bash
# Generate tmux.conf.osx
OS=$(uname)

if [ OS="Linux" ]; then
    echo "Generating .tmux.conf.osx"
    cp .tmux.conf .tmux.conf.osx
    echo "# Enable pbcopy on mac" >> .tmux.conf.osx
    echo 'set-option -g default-command "reattach-to-user-namespace -l zsh"' >> .tmux.conf.osx
else
    echo "There is no need to generate .tmux.conf.osx because you don't use Mac OS X."
fi
