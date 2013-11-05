#!/bin/bash
# coding utf-8
# under control files
files="
.tmux.conf
"
REPO="${PWD}"
TARGET_DIR=${HOME}/.dotconfig/dotfiles
echo '==========================================================='
echo ' We will make symbolic link to your computer(And first setup)'
if [ ! -d $TARGET_DIR ]
then
    echo 'Abort installing. Please move this directory to ${TARGET_DIR}'
    exit 0
fi
echo ' zshrc, tmux.conf'
echo ' Dependences: zsh, tmux, oh-my-zsh, zaw'
echo '==========================================================='
echo 'Do you really install now?(yes/no)'
read ans
if [ "$ans" = "yes" ]
then
    echo 'Start making symbolic link...'
    for file in ${files}
    do
	filepath="${PWD}/${file}"
	homefile="${HOME}/${file}"
	
	if [ ! -e "${homefile}" ]; then
	    echo "${file} not exis, make symbolic link to ${homefile}"
	    ln -s "${filepath}" "${homefile}"
	else
	    echo "${file} exist, so if you renew ${file}, please delete it"
	fi
    done  
else
    echo 'Abort installing'
    exit 0
fi

echo '###########################################################'
echo ' We will download and install dependences'
echo ' Do you really install now?(yes/no)[RECOMMENDED]'
read ans
if [ "$ans" = "yes" ]
then
    # oh-my-zsh installing
    echo 'installing oh-my-zsh...'
    cd $HOME
    curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
    # remove zshrc which makes after installing zshrc
    rm -rf $HOME/.zshrc
    # 各環境に対応できないのでコピーにする 
    cp  ${REPO}/.zshrc $HOME/.zshrc
    echo '###########################################################'
    echo 'installing zaw...'
    cd $HOME/.dotconfig/
    # zaw.zshのインストール
    git clone git://github.com/zsh-users/zaw.git
#    echo "source $HOME/.dotconfig/zaw/zaw.zsh" >> $HOME/.zshrc
else
    echo 'Abort installing'
    exit 0
fi


echo '###########################################################'
echo ' Finished and completed installing...'


# .zshrcを各環境ごとに書き換える
#if [ 'uname' # "Darwin" ]; then
#   
#elif ['uname' # "Linux"]; then
#
#fi
