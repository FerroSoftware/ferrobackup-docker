#!/bin/bash
trap finalize SIGTERM

function log() {
  echo -e "\n#" $(date --iso-8601=seconds) "   $1"
}

function finalize() {
  log "Shutting down FBS ($COMPONENTS)..."
  if [ "$ISSERVER" = true ] ; then 
    wine $APPPATH/FBSServer.exe -stop
  fi 
  log "Done."
  exit
}

function startX() {
  log "Starting Xvfb..."
  rm -f /tmp/.X0-lock
  Xvfb :0 -screen 0 1024x768x16 &
  sleep 2
  export DISPLAY=:0.0
}

function isHttpServerAlive() {
  PREVHTTPSERVERALIVE=$HTTPSERVERALIVE
  wget --retry-connrefused --spider -q --tries 20 -T 5 http://127.0.0.1:4530/null && HTTPSERVERALIVE=true || HTTPSERVERALIVE=false
}

function isServerProcessAlive() {
  PREVSERVERPROCESSALIVE=$SERVERPROCESSALIVE
  pgrep "FBSServer.exe" > /dev/null && SERVERPROCESSALIVE=true || SERVERPROCESSALIVE=false
}

function isAutoupdateInProgress() {
  pgrep -f "AUTOUPDATE" > /dev/null && AUTOUPDATE=true || AUTOUPDATE=false
}

function watchdog() {
  if [ "$ISSERVER" = true ] ; then 
    isServerProcessAlive
    if [ "$SERVERPROCESSALIVE" = false ] && [ "$PREVSERVERPROCESSALIVE" = true ] ; then
      isAutoupdateInProgress
      if [ "$AUTOUPDATE" = false ] ; then
        log "FBSServer.exe proccess has been terminated. Restarting FBS Server service..."
        wine $APPPATH/FBSServer.exe -start
      fi  
    else
      isHttpServerAlive
      if [ "$HTTPSERVERALIVE" = false ] && [ "$PREVHTTPSERVERALIVE" = true ] ; then
        isAutoupdateInProgress
        if [ "$AUTOUPDATE" = false ] ; then
          log "HTTP server is not responding. Stopping FBS Server service..."
          wine $APPPATH/FBSServer.exe -stop
        fi  
      fi
    fi
  fi

}

function install() {
  if [ -d $APPPATH ]; then
    UPDATE=true
    INSTTEXT="Update"
  else
    UPDATE=false
    INSTTEXT="Installation"
  fi    
   

  log "$INSTTEXT..."
  
  chmod -R 777 /fbs
  if [ ! $? -eq 0 ];then
     log "Access denied."
     exit 1
  fi
  

  log "Downloading installer..."
  cd /tmp && wget www.ferrobackup.com/download/Fbs5InstDocker.exe
  log "Initializing Wine..."
  WINEDEBUG=-all wine ipconfig > /dev/null
  startX
  log "FBS ($COMPONENTS) - $INSTTEXT..."
  rm -f -v /tmp/setup.log
  wine /tmp/$INSTFILE /SP- /verysilent /noicons /SUPPRESSMSGBOXES /LOG="Z:\tmp\setup.log" /COMPONENTS="$COMPONENTS" /dir="Z:$APPPATH"

  INSTOUT=$?
  if [ ! $INSTOUT -eq 0 ];then
     log "Setup failed to initialize. Error: $INSTOUT"
     cat /tmp/setup.log
     exit 1
  fi

  log "$INSTTEXT completed"
}


COMPONENTS=${1:-"FBS_Server,FBS_Worker"}
INSTFILE="Fbs5InstDocker.exe"
APPPATH="/fbs/app"
PREVHTTPSERVERALIVE=false

if echo "$COMPONENTS" | grep -q "FBS_Server"; then
  ISSERVER=true
else
  ISSERVER=false
fi


log "################################"
log "##### Ferro Backup System ######"
log "################################"

log "Starting..."


if [ ! -f /tmp/$INSTFILE ] 
then
  install
else
  startX
fi


log "Starting NT services ($COMPONENTS)..."


export LC_ALL=pl_PL.UTF-8
export LANG=pl_PL.UTF-8
cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

sleep 10
/usr/lib/i386-linux-gnu/wine/bin/wineserver -p
wine ipconfig > /dev/null

echo
uname -a
lscpu



log "Press any key to exit..."
while true
do 
  sleep 1.0; 
  watchdog  
done

