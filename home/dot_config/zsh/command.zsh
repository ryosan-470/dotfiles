# コマンド
# hoge.tar.gz を ./hoge.tar.gz で展開
# jar は実行されるため展開対象から外している (suffix alias も廃止)
function extract() {
    case "$1" in
        *.tar.gz|*.tgz) tar xzvf "$1" ;;
        *.tar.xz) tar Jxvf "$1" ;;
        *.zip) unzip "$1" ;;
        *.lzh) lha e "$1" ;;
        *.tar.bz2|*.tbz) tar xjvf "$1" ;;
        *.tar.Z) tar zxvf "$1" ;;
        *.gz) gunzip -k "$1" ;;   # 元の .gz は残す
        *.bz2) bunzip2 -k "$1" ;; # 元の .bz2 は残す
        *.Z) uncompress "$1" ;;
        *.tar) tar xvf "$1" ;;
        *.arj) unarj "$1" ;;
        *.rar) unrar "$1" ;;
        *.7z) 7z x "$1" ;;         # require: p7zip p7zip-full
        *.cab) cabextract "$1" ;;  # require: cabextract
        *) echo "extract: unsupported format: $1" >&2; return 1 ;;
    esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz,rar,7z,cab}=extract

# copy to clipboard
function c2b() {
    TARGET=$1
    cat "$TARGET" | pbcopy
}

# gpg2
if (($+commands[gpg])) && [[ -t 0 ]]; then
    export GPG_TTY=$(tty)
fi

function urlencode() {
    printf '%s\n' "$1" | nkf -WwMQ | sed -e 's/=/%/g'
}

function urldecode() {
    printf '%s\n' "$1" | nkf --url-input
}

function dot() {
    ret=$PWD
    help_message=$(cat << DOT
The dot command is a controller my dotfiles based on CLI
There are common dot commands used in various situations:

update         Update your dotfiles from GitHub and apply them (chezmoi update)
diff           Show changes chezmoi would apply (chezmoi diff)
private        Move to the private repository (~/.config/private)
help           Print this message
DOT
)
    case $1 in
        update) chezmoi update;;
        diff) chezmoi diff;;
        private)
            if [[ -d ~/.config/private ]]; then
                cd ~/.config/private
            else
                echo "~/.config/private がありません。chezmoi apply で clone されます" >&2
            fi
            ;;
        *) echo $help_message;;
    esac
}

function ipinfo() {
    domain=$1
    ip=$(resolveip -s "${domain}")
    curl "https://ipinfo.io/${ip}"
}

# aws sso login のときだけ dualstack エンドポイントを使う
# (testcontainers など他ツールへの影響を避けるため環境変数はグローバルに export しない)
function aws() {
    if [[ " $* " == *" sso "* && " $* " == *" login "* ]]; then
        AWS_USE_DUALSTACK_ENDPOINT=true command aws "$@"
    else
        command aws "$@"
    fi
}

# run.zsh
# Usage: run test.cpp
# Compile the source and running
#####################################################
# コンパイルが必要な言語をコンパイルして実行する
#####################################################
# Support language : C/C++, Java
function fail_message() {
    STATUS=1  # BOLD
    COLOR=31  # RED
    arrow="\033[1;37m==> \033[0;39m"
    begin="\033[${STATUS};${COLOR}m"
    end="\033[0;39m"
    echo -e ${arrow}${begin}"Failed to compile and run"${end}
    return 1
}

function run() {
    INPUTFILE="${1}"
    FILENAME="${INPUTFILE:r}"
    case ${INPUTFILE} in
        # BUG: オプションがひとつしか指定できない
        *.c)          PROG_TYPE="c"    COMPILER=gcc OPTIONS="-Wall";;
        *.cc | *.cpp) PROG_TYPE="cpp"  COMPILER=g++ OPTIONS="-std=c++11";;
        *.java)       PROG_TYPE="java" COMPILER=javac;;
        *)            PROG_TYPE="no_support";;
    esac

    case ${PROG_TYPE} in
        "c" | "cpp")
            COMPILED="${FILENAME}.out"
            [ -e "${COMPILED}" ] && rm "${COMPILED}"
            ${COMPILER} ${OPTIONS} "${INPUTFILE}" -o "${COMPILED}"
            [ $? -eq 0 ] && "./${COMPILED}" || fail_message;;
        "java")
            ${COMPILER} "${INPUTFILE}"
            [ $? -eq 0 ] && java "${FILENAME}" || fail_message;;
    esac
}
# suffix alias (`foo.c` だけでコンパイル&実行) は廃止。明示的に `run foo.c` で呼ぶ

################################################
## tmux自動起動
################################################
if [ "$TMUX" = "" ] && [ "$TERM_PROGRAM" != "Orca" ]; then
    if (($+commands[tmux])); then
        tmux attach || tmux;
    fi
fi

# ghq と組み合わせて Ctrl+L で移動できる
function peco-src () {
    local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src
