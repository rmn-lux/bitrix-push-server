# install push-server from bx repo
FROM centos:7 as push-server

# bitrix repo
RUN echo $'[bitrix]\n\
name=$OS $releasever - $basearch\n\
failovermethod=priority\n\
baseurl=http://repos.1c-bitrix.ru/yum/el/$releasever/$basearch\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=http://repos.1c-bitrix.ru/yum/RPM-GPG-KEY-BitrixEnv\n' \
>> /etc/yum.repos.d/bitrix.repo && \
# redis repo
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
# node8 repo
curl -sL https://rpm.nodesource.com/setup_8.x | sh - && \
# install
yum -y update && \
yum -y install redis-6.0.4 nodejs-8.17.0 bx-push-server-2.0.0 && \
yum clean all && \
rm -rf /var/cache/yum

########################################

FROM node:8-alpine

WORKDIR /opt/push-server

COPY --from=push-server /opt/push-server /opt/push-server
COPY run.sh /opt/push-server
COPY config.template.json /etc/push-server/config.template.json

# alpine virtual package
RUN set -x && \
    apk add --update "libintl" && \
    apk add --virtual build_deps "gettext" &&  \ 
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps && \
    chmod +x /opt/push-server/run.sh

# default env vars
ENV LISTEN_PORT 8010
ENV LISTEN_HOSTNAME 0.0.0.0
ENV REDIS_HOST redis
ENV REDIS_PORT 6379
ENV SECURITY_KEY IMbEDEnTANDiSPATERSIVeRptUGht
ENV MODE pub

EXPOSE 8010

ENTRYPOINT ["/opt/push-server/run.sh"]
