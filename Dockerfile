FROM node:0.10.46
MAINTAINER Holger Schinzel <holger@dash.org>

RUN apt-get update && apt-get install vim telnet -y

RUN useradd --user-group --create-home --shell /bin/false app &&\
    npm install --global npm@3.10.5 &&\
    npm install jsonfile@2.3.1 lodash@4.14.1

ENV HOME=/home/app

COPY package.json $HOME/unomp/
COPY docker-entrypoint.sh /entrypoint.sh

RUN chown -R app:app $HOME/* &&\
    chmod +x /entrypoint.sh

USER app
WORKDIR $HOME/unomp
RUN npm update

USER root
COPY . $HOME/unomp
RUN chown -R app:app $HOME/*
USER app

EXPOSE 8080 3032

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "init.js"]