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
