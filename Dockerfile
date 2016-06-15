FROM i386/alpine:latest 
#debian:i386
MAINTAINER Ferro Software
RUN apk update
RUN apk add wine
RUN cd /tmp && wget www.ferrobackup.com/download/FbsDockerInst.tgz \
 && tar xvzf FbsDockerInst.tgz -C / \
 && rm FbsDockerInst.tgz
ENV DISPLAY :0
EXPOSE 4530 4531
#CMD wine /fbs/FBSServer.exe -standalone
ENTRYPOINT ["wineconsole", "/fbs/FBSServer.exe", "-standalone"]
