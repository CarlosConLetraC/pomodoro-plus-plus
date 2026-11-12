FROM debian:13

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=1000

ENV SHELL=/bin/bash
ENV HOME=/home/$USERNAME
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    sudo \
    tree \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -ms /bin/bash $USERNAME && \
    echo "$USERNAME:1234" | chpasswd && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["bash"]