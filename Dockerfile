FROM debian:latest
MAINTAINER Ferro Software
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y locales wine32 wget xvfb
RUN echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen pl_PL.utf8 \
	&& /usr/sbin/update-locale LANG=pl_PL.UTF-8
ADD start.sh /start.sh
VOLUME ["/fbs"]
EXPOSE 4530 4531
ENTRYPOINT ["/start.sh"]
