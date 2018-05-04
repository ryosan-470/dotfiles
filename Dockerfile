# Dotfiles test environment
FROM ubuntu:18.04
MAINTAINER Ryosuke SATO <rskjtwp@gmail.com>

LABEL Description="This image is used to test my dotfiles installation and running"
# Initialize
RUN apt-get update
RUN apt-get install -y zsh vim git curl tmux python3
RUN apt-get install -y language-pack-en-base language-pack-en
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add normal user
RUN useradd -ms /bin/bash ubuntu
USER ubuntu
WORKDIR /home/ubuntu
