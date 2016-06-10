FROM i386/alpine:latest 
#debian:i386
MAINTAINER Ferro Software
RUN apk update && apk add wine
RUN cd /tmp && wget www.ferrobackup.com/download/FbsDockerInst.zip
RUN unzip FbsDockerInst.zip -d / && rm FbsDockerInst.zip
#RUN apt-get update && apt-get install -y wine
# dpkg --add-architecture i386 &&  
ENV DISPLAY :0
#COPY . /FBS/

EXPOSE 4530 4531
CMD wine /fbs/FBSServer.exe -standalone
