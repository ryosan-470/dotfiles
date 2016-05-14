# Dotfiles test environment
FROM ubuntu:14.04
MAINTAINER Ryosuke SATO <rskjtwp@gmail.com>

LABEL Description="This image is used to test my dotfiles installation and running"
# Initialize
RUN apt-get update
RUN apt-get install -y zsh vim git curl tmux python3
# Clone and setup repo
RUN curl -fsSL http://dot.jtwp470.net | python3

CMD ["/bin/zsh"]
