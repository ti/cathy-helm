FROM nvcr.io/nvidia/pytorch:25.09-py3
ENV HF_HOME=/app/data/models/hf

# openssh
RUN apt -yqq update && \
    apt install -y --no-install-recommends openssh-server openssh-client lsb-release tmux sudo libgl1-mesa-dev libglib2.0-0 \
    lsof net-tools dnsutils traceroute iproute2 tcpdump build-essential cmake binutils wget vim iputils-ping && \
    apt-get autoremove -y && apt-get clean -y && \
    sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
    sed -i 's/#*PasswordAuthentication .*/PasswordAuthentication no/g' /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    mkdir -p /root/.ssh && \
    mkdir /var/run/sshd &&chmod 0755 /var/run/sshd

# buf
RUN BIN="/usr/local/bin" && VERSION="1.55.1" && \
    curl -sSL "https://github.com/bufbuild/buf/releases/download/v${VERSION}/buf-$(uname -s)-$(uname -m)" \
    -o "${BIN}/buf" && \
    chmod +x "${BIN}/buf"

# postgres
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
RUN apt update && apt install -y postgresql-17 && apt clean && rm -rf /var/lib/apt/lists/*


# Create user 'core' with UID and GID 1000
RUN userdel -f -r ubuntu && groupadd -g 1000 core && \
    useradd -m -u 1000 -g 1000 -s /bin/bash core && \
    echo "core ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /opt/data/share && chown -R core:core /opt/data/share && chmod -R 0700 /opt/data/share

USER core
WORKDIR /home/core

RUN mkdir -p /home/core/.ssh  && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhW4Sz3Xz/+ptXvZM4GCQABDfx3ArAkaT0yAk4sEwhutCDx+QfqCnWB+G7wj3cQNy/5PWg1wtZqnCEO7S+OgA7sQhd9ftsVJYPsnexGTba3uwZVoiOoJFwMY7x+sZn3lDLuLvYLV+0HVv2x4QJjSANswPci6ennuzV1Z4akMZfgF3mqmKurwF4oCkLchYW4WZDelh4aid2UY7x5I7v0m6riqUgEHqqxegk7xtMPM5UF0uK70l4w5ZbgkLIKNL2uAW6eDWFfLxSWBIiAo+6pthj918rivIRHu2nL0e2ZXeo8gCbPQdoAGEhHnsf16h9B05k6auyF2zlOfG4YVJ8lwmF test" > /home/core/.ssh/authorized_keys && \
    chmod 700 /home/core/.ssh && chmod 600 /home/core/.ssh/authorized_keys && \
    touch /home/core/.ssh/environment && chmod 600 /home/core/.ssh/environment

RUN  mkdir -p /home/core/.local/bin && \
     ln -s /opt/data/share /home/core/.local/share && \
     echo "export PATH=/home/core/.local/bin:\$PATH" >> /home/core/.bashrc

RUN PATH="${PATH}:/home/core/.local/bin:/home/core/go/bin:/usr/local/go/bin"

# python
RUN python3 -m venv ~/.local/python && mkdir -p ~/.local/bin && ln -sf ~/.local/python/bin/python ~/.local/bin/python

# nodejs
RUN curl -fsSL https://nodejs.org/dist/v24.4.0/node-v24.4.0-linux-x64.tar.xz | tar -xJ -C /tmp &&  \
    mv /tmp/node-v24.4.0-linux-x64 ~/.local/nodejs && mkdir -p ~/.local/bin &&  \
    ln -sf ~/.local/nodejs/bin/node ~/.local/bin/node && ln -sf ~/.local/nodejs/bin/npm ~/.local/bin/npm

# vscode server
RUN curl -fsSL "https://github.com/coder/code-server/releases/download/v4.103.0/code-server-4.103.0-linux-amd64.tar.gz" | tar -xz -C ~/.local/ && \
    mv ~/.local/code-server-4.103.0-linux-amd64 ~/.local/vscode-server &&  \
    mkdir -p ~/.local/bin && ln -sf ~/.local/vscode-server/bin/code-server ~/.local/bin/code-server && \
    mkdir -p ~/.vscode-server/data && mkdir -p ~/.vscode-server/extensions

# ffmpeg
RUN mkdir ~/.local/ffmpeg && curl -fsSL https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz |tar --strip-components=1 -xJ -C ~/.local/ffmpeg && \
    ln -sf ../ffmpeg/bin/ffmpeg ~/.local/bin/ffmpeg && ln -s ../ffmpeg/bin/ffprobe ~/.local/bin/ffprobe

# conda
RUN sudo mkdir -p /opt/miniconda3 && sudo chown core:core /opt/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /opt/miniconda3/miniconda.sh && \
    bash /opt/miniconda3/miniconda.sh -b -u -p /opt/miniconda3 && \
    rm /opt/miniconda3/miniconda.sh

ENV PATH="${PATH}:/root/.local/bin:/root/go/bin:/usr/local/go/bin:/opt/miniconda3/bin"

RUN conda init bash &&  \
    conda config --add channels conda-forge && \
    conda config --add channels nvidia && \
    conda config --set channel_priority strict && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# amazon q cli
RUN curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" -o "q.zip" && \
    unzip q.zip && mv q/bin/q*  ~/.local/bin/ && \
    rm -rf q*

RUN mkdir /home/core/workspace

RUN cat > ~/.local/bin/entrypoint.sh << 'EOF'
#!/bin/bash
env | grep -v "^_=" > /home/core/.ssh/environment
PASSWORD=QWerCode && nohup /home/core/.local/bin/code-server --bind-addr 0.0.0.0:8300 --disable-workspace-trust --auth password $PASSWORD --user-data-dir /home/core/.vscode-server/data --extensions-dir /home/core/.vscode-server/extensions /home/core/workspace > /tmp/code-server.log 2>&1 &
export PATH=$HOME/.local/bin:$HOME/.local/nodejs/bin:$PATH
exec "$@"
EOF

RUN chmod +x ~/.local/bin/entrypoint.sh

ENTRYPOINT ["/home/core/.local/bin/entrypoint.sh"]
CMD [ "sudo", "/usr/sbin/sshd", "-D", "-p", "22"]
