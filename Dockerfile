FROM debian:jessie
MAINTAINER Ferro Software
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y locales wine wget xvfb procps
RUN echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen pl_PL.utf8 \
	&& /usr/sbin/update-locale LANG=pl_PL.UTF-8
ADD start.sh /start.sh
ADD NET /bin/NET
ADD RUN /bin/RUN
ADD READLINK2FILE /bin/READLINK2FILE
VOLUME ["/fbs"]
EXPOSE 4530 4531
ENTRYPOINT ["/start.sh"]
