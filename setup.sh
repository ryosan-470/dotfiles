#!/bin/bash
###################################################################
##
## setup.sh -- setup tool for jtwp470's Emacs and dotfiles config
##
## Author : Ryosuke SATO (jtwp470)  tango@jtwp470.net
## Licence: Public
##
###################################################################
set -e
set -u

TARGET_DIR="${HOME}/.dotconfig"       # 保存先
VERSION="1.30"

DEMACS="${HOME}/.emacs.d"
INSTALL_PATH="${HOME}/.dotconfig/dotemacs"
OS=`uname`  # Distribution type (support Linux (Ubuntu) & Darwin)
# echo色付け Usage echowcl text [COLOR] [TYPE]
function echowcl() {
    TEXT="${1}"
    if [ $# -lt 3 ]; then
            echo "${TEXT}"
    else
            case $2 in
                black)
                        COLOR=30;; #COLOR=BLACK
                red)
                        COLOR=31;; #COLOR=RED
                green)
                        COLOR=32;; #COLOR=GREEN
                yellow)
                        COLOR=33;; #COLOR=YELLOW
                blue)
                        COLOR=34;; #COLOR=BLUE
                white)
                        COLOR=37;; #COLOR=WHITE
                *)
                        COLOR=37;; #COLOR=DEFAULT
            esac

            case $3 in
                normal)
                        STATUS=0;; #STATUS=NORMAL
                bold)
                        STATUS=1;; #STATUS=BOLD
                line)
                        STATUS=4;; #STATUS=Underline
                *)
                        STATUS=0;;
            esac
            arrow="\033[1;37m==> \033[0;39m"
            begin="\033[${STATUS};${COLOR}m"
            end="\033[0;39m"
            echo -e ${arrow}${begin}${TEXT}${end}
    fi
}

# Usage format TEXT type
function format() {
    TEXT="${1}"
    type=$2
    if [ $# -lt 2 ]; then
            echowcl "${TEXT}" white normal
    else
            case $type in
                info)    echowcl "${TEXT}" blue normal;;
                success) echowcl "${TEXT}" green bold;;
                fail)    echowcl "${TEXT}" red bold;;
                warn)    echowcl "${TEXT}" yellow bold;;
                *)       echowcl "${TEXT}" white normal
            esac
    fi
}

# [DEPLOY] Clone git repository.
function fetch() {
    _branch=${1:-"master"}
    REPO="jtwp470/dotemacs.git"
    GIT_CLONE="git clone -b ${_branch} --single-branch"
    # COMMAND="${GIT_CLONE} git@github.com:${REPO} ${INSTALL_PATH} --recursive"
    COMMAND="${GIT_CLONE} https://github.com/${REPO} ${INSTALL_PATH} --recursive"
    format "${COMMAND}" info
    ${COMMAND}
    if [ $? -ne 0 ]; then
        format "Error: Cannot clone repository. Exit" fail
        return 1
    fi
    return 0;
}

# [DEPLOY] make symlink
function symlink() {
    if [ -e ${DEMACS} ]; then
        # 既存の.emacs.dは名前を変えてバックアップ
        RNAME=".emacs.d_bk_`date +%Y%m`"
        mv ${DEMACS} ${HOME}/${RNAME}
        format "Rename .emacs.d to ${RNAME}" info
    fi
    format "Make symlink ${INSTALL_PATH} to ${DEMACS}" success
    ln -s ${INSTALL_PATH} ${DEMACS}

    # make symbolic link to .java_base.tag
    ln -s ${DEMACS}/.java_base.tag ${HOME}/.java_base.tag
    format "Make symlink java_base.tag" success
    return 0
}


# [INIT] auto-complete-clang-async
function install-acca() {
    if [ ${OS} = "Linux" ]; then
        # Ubuntuであると仮定する
        format "install dependences" info
        sudo apt-get install clang-3.5 libclang-3.5-dev llvm-3.5-dev || (format "Failed to install dependences using apt" fail && exit 1)
        cd ${DEMACS}/elisp/emacs-clang-complete-async
        make LLVM_CONFIG=llvm-config-3.5
        ln -s ./clang-complete ~/.emacs.d/clang-complete
    elif [ ${OS} = "Darwin" ]; then
        # Mac OSX
        brew install emacs-clang-complete-async
        ln -s `brew --prefix`/Cellar/emacs-clang-complete-async/clang-complete ~/.emacs.d/clang-complete
    else
        format "Not supported your OS" fail
        return 1
    fi
    format "Success to install emacs-clang-complete-async" success
    return 0
}

# Deploy
function deploy() {
    format "Starting installation for dotemacs" info
    _branch=${1:-"master"}
    fetch ${_branch} || exit 1
    format "Make symlink" info
    symlink
    return 0
}

# init
function init() {
    format "initialize" info
    format "None" success
    return 0
}

# test
function tests() {
    cd ${DEMACS}/inits/
    format "Emacs byte-compile test" info
    make || (format "Test failed" fail && exit 1)
    format "Test finished" success
    return 0
}

function install-travis() {
    format "Emacs version:\n`emacs --version`" info
    deploy "master"
    init
    # format "Starting to build emacs-clang-complete-async" info
    # install-acca
    tests
}
OPT=$1

case ${OPT} in
    "deploy")
        deploy && exit 0;;
    "init")
        init && exit 0;;
    "test")
        tests && exit 0;;
    "install-acca")
        install-acca && exit 0;;
    "install-travis")
        install-travis && exit 0;;
    "help")
        cat <<_EOT_
setup.sh [options]

Version: ${VERSION}

The setup.sh for emacs configuration setup scripts.

[OPTIONS]:

- all            Default installation command. Deploy, init and install-acca command
- deploy         Deploy. Clone repository, make symlink and install cask
- init           Initialize. Emacs installation via cask.
- test           Test section. byte compile  ~/.emacs.d/inits/*.el.
- install-acca   Only to install emacs-clang-complete-async.
- install-travis For Travis CI test
- help           This section.
_EOT_
        ;;
    "all")
        format "Installing all" info
        format "Start deploying" info
        deploy || (format "[FAILED] deploying..." fail && exit 1)
        format "Initialize" info
        init   || (format "[FAILED] initialize..." fail && exit 1)
        format "Starting installation to emacs-clang-complete-async" info
        install-acca
        exit 0;;
    *)
        bash ./setup.sh help
        exit 0;;
esac
