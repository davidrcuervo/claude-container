FROM ubuntu:26.04 AS claude

RUN apt update
RUN apt upgrade -y

RUN apt install -y openssl sudo curl

RUN PASSWORD=$(openssl passwd -1 secret) && \
    useradd -c "Administrator user" --password "$PASSWORD" --shell /bin/bash --create-home --home-dir /home/admuser admuser
RUN usermod -a -G sudo admuser

RUN PASSWORD=$(openssl passwd -1 secret) && \
    useradd -c "Simple user" --password "$PASSWORD" --shell /bin/bash --create-home --home-dir /home/claudia claudia

WORKDIR /home/claudia
USER claudia
RUN curl -fsSL -O https://claude.ai/install.sh
RUN chmod +x install.sh
RUN ./install.sh

COPY --chmod=0600 --chown=claudia:claudia settings.json /home/claudia/.claude/settings.json

ENV HOME=/home/claudia
ENV CLAUDE_CONFIG_DIR=/home/claudia/.claude
ENV PATH="$HOME/.local/bin:$PATH"