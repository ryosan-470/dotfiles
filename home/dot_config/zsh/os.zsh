# OS ごとの設定
case `uname` in
    "Darwin")
        if (($+commands[brew])); then
            alias update="brew update -v && brew upgrade -vy"
        fi
        # pnpm (グローバルの bin を PATH に入れる)
        export PNPM_HOME="$HOME/Library/pnpm"
        case ":$PATH:" in
            *":$PNPM_HOME/bin:"*) ;;
            *) export PATH="$PNPM_HOME/bin:$PATH" ;;
        esac
        # dory (Docker ランタイム) が起動していれば、その socket を Docker CLI に向ける
        if [ -S "$HOME/.dory/dory.sock" ]; then
            export DOCKER_HOST="unix://$HOME/.dory/dory.sock"
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
