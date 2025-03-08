# Base image
FROM quay.io/jupyter/base-notebook:2024-12-31

# Executar comandos como root
USER root

# Instalar dependências do sistema e TurboVNC
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        dbus-x11 \
        xclip \
        xfce4 \
        xfce4-panel \
        xfce4-session \
        xfce4-settings \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
        git \
        tigervnc-standalone-server \
        wget \
        gpg && \
    wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor > /etc/apt/trusted.gpg.d/TurboVNC.gpg && \
    echo "deb https://packagecloud.io/dcommander/turbovnc/ubuntu focal main" > /etc/apt/sources.list.d/TurboVNC.list && \
    apt-get update -qq && \
    apt-get install -y -qq turbovnc && \
    apt-get remove -y -qq xfce4-screensaver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Corrigir permissões no diretório do usuário
RUN mkdir -p /opt/install && \
    chown -R $NB_UID:$NB_GID $HOME /opt/install

# Adicionar scripts e pacotes adicionais
COPY --chown=$NB_UID:$NB_GID . /opt/install
RUN fix-permissions /opt/install

# Retornar ao usuário padrão
USER $NB_USER

# Atualizar o ambiente Conda e instalar pacotes Python
COPY --chown=$NB_UID:$NB_GID environment.yml /tmp
RUN mamba env update --quiet --file /tmp/environment.yml && \
    rm -rf /tmp/environment.yml

# Instalar Node.js e pacotes Python
RUN mamba install -y -q "nodejs>=22" && \
    pip install /opt/install

# Copiar o script de monitoramento
COPY --chown=$NB_UID:$NB_GID monitor.py /opt/install/monitor.py

# Configurar inicialização do VNC e ambiente gráfico
CMD ["start.sh"]
