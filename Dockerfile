# Dotfiles test environment
FROM ubuntu:16.04
MAINTAINER Ryosuke SATO <rskjtwp@gmail.com>

LABEL Description="This image is used to test my dotfiles installation and running"
# Initialize
RUN apt-get update
RUN apt-get install -y zsh vim git curl tmux python3 python

# Add normal user
RUN useradd -ms /bin/bash ubuntu
USER ubuntu
WORKDIR /home/ubuntu
