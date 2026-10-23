FROM ubuntu:22.04

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=1000

ENV SHELL=/bin/bash
ENV HOME=/home/$USERNAME
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y git sudo tree npm

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -ms /bin/bash $USERNAME && \
    echo "$USERNAME:1234" | chpasswd && \
    usermod -aG sudo $USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["bash"]
