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

    Install a VNC server, either TigerVNC (default) or TurboVNC
ARG vncserver=tigervnc
RUN if [ "${vncserver}" = "tigervnc" ]; then \
        echo "Installing TigerVNC"; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            tigervnc-standalone-server \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN if [ "${vncserver}" = "turbovnc" ]; then \
        echo "Installing TurboVNC"; \
        # Install instructions from https://turbovnc.org/Downloads/YUM
        wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
        gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg; \
        wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list; \
        apt-get -y -qq update; \
        apt-get -y -qq install \
            turbovnc \
        ; \
        rm -rf /var/lib/apt/lists/*; \
    fi
    

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
