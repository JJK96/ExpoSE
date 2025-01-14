FROM debian:latest

#Install SSH, Xvfb etc
RUN apt update && apt install --assume-yes git bash openssh-server clang build-essential vim curl xvfb python3 python3-pip python3-venv libgtk-3-0 tmux libxss1 libgconf-2-4 libnss3 libasound2 unzip

# Setup VENV https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip3 install mitmproxy
RUN useradd --create-home --shell /bin/bash expose
RUN echo 'expose:expose' | chpasswd
RUN mkdir -p /run/sshd
RUN mkdir -p ~/.ssh/ && echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
RUN ssh-keygen -A

#Install ExpoSE into /source/
ADD . /source
USER root
RUN chown -R expose /source; chmod -R 777 /source/
USER expose
WORKDIR /source
ENV NODE_VERSION=14.16.1
RUN curl -fsSL https://fnm.vercel.app/install | bash
ENV PATH="/home/expose/.local/share/fnm:$PATH"
RUN echo "$PATH"
RUN eval $(fnm env) && fnm install $NODE_VERSION && fnm alias default $NODE_VERSION && fnm use default
ENV PATH="/home/expose/.local/share/fnm/aliases/default/bin:$PATH"
RUN ./install
RUN nohup Xvfb :1 -screen 0 800x600x24 &
ENV DISPLAY 1
USER root

#Setup Volumes
RUN mkdir -p /work
RUN chown -R expose /work
VOLUME ["/work"]

EXPOSE 22
CMD ["/source/expoSE"]
