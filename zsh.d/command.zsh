# コマンド
# hoge.tar.gz を ./hoge.tar.gz で展開
function extract() {
    case $1 in
        *.tar.gz|*.tgz) tar xzvf $1 ;;
        *.tar.xz) tar Jxvf $1 ;;
        *.zip) unzip $1 ;;
        *.lzh) lha e $1 ;;
        *.tar.bz2|*.tbz) tar xjvf $1 ;;
        *.tar.Z) tar zxvf $1 ;;
        *.gz) gzip -dc $1 ;;
        *.bz2) bzip2 -dc $1 ;;
        *.Z) uncompress $1 ;;
        *.tar) tar xvf $1 ;;
        *.arj) unarj $1 ;;
        *.rar) unrar $1 ;;
        *.7z) 7z x $1 ;;         # require: p7zip p7zip-full
        *.cab) cabextract $1 ;;  # require: cabextract
        *.jar) java -jar $1 & ;; # Launch java app
    esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz,rar,7z,cab,jar}=extract

# copy to clipboard
function c2b() {
    TARGET=$1
    cat $TARGET | pbcopy
}

# gpg2
if which gpg-agent > /dev/null; then
    pgrep gpg-agent> /dev/null 2>&1 || eval $(gpg-agent --daemon --write-env-file ${HOME}/.gpg-agent-info)
    [ -f ${HOME}/.gpg-agent-info ] && source ${HOME}/.gpg-agent-info
    export GPG_AGENT_INFO
    export GPG_TTY=`tty`
fi

function urlencode() {
    echo $1 | nkf -WwMQ | sed -e 's/=/%/g'
}

function urldecode() {
    echo $1 | nkf --url-input
}

function dot() {
    ret=$PWD
    help_message=$(cat << DOT
The dot command is a controller my dotfiles based on CLI
There are common dot commands used in various situations:

update         Update your dotfiles from GitHub (e.g git fetch origin master)
help           Print this message
DOT
)
    case $1 in
        update) cd ~/.dotconfig/dotfiles > /dev/null;
                git pull origin master;
                cd $ret > /dev/null;;
        *) echo $help_message;;
    esac
}

function ipinfo() {
    domain=$1
    ip=$(resolveip -s ${domain})
    curl https://ipinfo.io/${ip}
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
    INPUTFILE=${1}
    FILENAME=(${INPUTFILE:r})
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
            [ -e ${COMPILED} ] && rm ${COMPILED}
            ${COMPILER} ${OPTIONS} ${INPUTFILE} -o ${COMPILED}
            [ $? -eq 0 ] && ./${COMPILED} || fail_message;;
        "java")
            ${COMPILER} ${INPUTFILE}
            [ $? -eq 0 ] && java ${FILENAME} || fail_message;;
    esac
}
alias -s {c,cc,cpp,java}=run
