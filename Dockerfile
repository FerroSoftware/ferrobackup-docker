FROM debian:latest
MAINTAINER Ferro Software
RUN dpkg --add-architecture i386
RUN apt-get update && apt-get install -y wine:i386 wget xvfb
ADD start.sh /start.sh
VOLUME ["/fbs"]
EXPOSE 4530 4531
ENTRYPOINT ["/start.sh"]
