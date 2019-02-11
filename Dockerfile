# Dotfiles test environment
FROM ubuntu:18.04
MAINTAINER Ryosuke SATO <rskjtwp@gmail.com>

LABEL Description="This image is used to test my dotfiles installation and running"
# Initialize
RUN apt update && \
  apt install -y \
  zsh \
  vim \
  git \
  curl \
  tmux \
  python3 \
  language-pack-en-base \
  language-pack-en \
  gcc \
  make \
  ncurses-dev \
  pkg-config  \
  && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV EMACS_VERSION 26.1
RUN curl -o /tmp/emacs.tar.gz https://ftp.gnu.org/pub/gnu/emacs/emacs-${EMACS_VERSION}.tar.gz && \
  tar xvf /tmp/emacs.tar.gz -C /tmp && \
  cd /tmp/emacs-${EMACS_VERSION} && \
  ./configure --with-x-toolkit=no --with-gif=no --with-gnutls=no && \
  make && \
  make install && \
  rm -rf /tmp/emacs-${EMACS_VERSION} /tmp/emacs.tar.gz

# Add normal user
RUN useradd -ms /bin/zsh ubuntu
USER ubuntu
WORKDIR /home/ubuntu
ADD . .dotconfig/dotfiles
RUN python3 .dotconfig/dotfiles/install.py
ENV SPACEMACS_BRANCH develop
RUN git clone --branch ${SPACEMACS_BRANCH} https://github.com/syl20bnr/spacemacs ~/.emacs.d
CMD ["/bin/zsh"]
