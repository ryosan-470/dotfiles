# OS ごとの設定
case `uname` in
    "Darwin")
        if [ -e /opt/homebrew/bin/brew ]; then
            eval $(/opt/homebrew/bin/brew shellenv)
            alias update="brew update -v && brew upgrade -v"
        fi
        ;;
    "Linux")
        #For Linux General
        alias open='gnome-open'
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
        local UPDATE_CMD=""
        if [ -e /etc/lsb-release ]; then
            # Ubuntu
            UPDATE_CMD="sudo apt update && sudo apt upgrade"
        elif [ -e /etc/arch-release ]; then
            # ArchLinux
            UPDATE_CMD="sudo pacman -Syu"
        elif [ -e /etc/redhat-release ]; then
            # CentOS
            UPDATE_CMD="sudo yum update";
        elif cat /etc/os-release | grep Raspbian >/dev/null 2>&1 ; then
            # Raspbian
            UPDATE_CMD="sudo apt-get update && sudo apt-get upgrade"
        else
            UPDATE_CMD="echo 'Not support your using distribution.'"
        fi
        alias update=${UPDATE_CMD}
        alias dstat-full='dstat -Tclmdrn'
        alias dstat-mem='dstat -Tclm'
        alias dstat-cpu='dstat -Tclr'
        alias dstat-net='dstat -Tclnd'
        alias dstat-disk='dstat -Tcldr'
        ;;
esac
