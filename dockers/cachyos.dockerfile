FROM docker.io/cachyos/cachyos:latest

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=1000

ENV SHELL=/bin/bash
ENV HOME=/home/$USERNAME

RUN pacman -Syu --noconfirm --needed git sudo && \
    pacman -Scc --noconfirm && \
    pacman -S tree --noconfirm
#    pacman -S tree nodejs-nopt npm curl --noconfirm

RUN sed -i 's/^VERSION_ID=.*/VERSION_ID=rolling/' /etc/os-release

RUN groupadd --gid $USER_GID $USERNAME 2>/dev/null || true && \
    useradd -u $USER_UID -g $USER_GID -m -s /bin/bash $USERNAME && \
    echo "$USERNAME:1234" | chpasswd && \
    usermod -aG wheel $USERNAME && \
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["bash"]
