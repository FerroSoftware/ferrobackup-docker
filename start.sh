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

function startNTServices() {
  log "Starting Xvfb..."
  rm -f /tmp/.X88-lock
  rm -f /tmp/.X11-unix/X88
  Xvfb :88 -screen 0 1024x768x16 &
  timeout=30
  while [ ! -e /tmp/.X11-unix/X88 ] || [ ! -e /tmp/.X88-lock ]; do
    sleep 0.1
    timeout=$(( timeout - 1 ))
    if [ "$timeout" -eq "0" ]; then
        log "Error: Xvfb not available."
        exit 1
    fi
  done
  sleep 1
  export DISPLAY=:88.0

  log "Starting NT services ($COMPONENTS)..."
  /usr/lib/wine/wineserver -p
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
  
  log "Verifing installation path..."
  rootDirProtect="/fbs/root"
  if [ -d "$rootDirProtect" ]; then
     echo "Parameter -v /:/fbs of docker run command is invalid. Installation in root folder is prohibited."
     exit 1
  fi
  chmod -R 777 /fbs || exit

  log "Downloading installer..."
  cd /tmp && wget www.ferrobackup.com/download/Fbs5InstDocker.exe || exit

  log "Initializing Wine..."
  WINEDEBUG=-all wine ipconfig > /dev/null

  log "Preparing temp path..."
  mkdir -p /fbs/tmp || exit
  chmod -R 777 /fbs/tmp || exit
  rm -rf /root/.wine/drive_c/users/root/Temp && ln -s /fbs/tmp /root/.wine/drive_c/users/root/Temp || exit

  startNTServices
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
log "#####---------------------######"
log "##### docker container v5 ######"
log "################################"

log "Starting..."

export LC_ALL=pl_PL.UTF-8
export LANG=pl_PL.UTF-8
cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime


if [ ! -f /tmp/$INSTFILE ] 
then
  install
else
# remove network connections from the previous session
  rm -rf /mnt/fbs
  dosdevs="/root/.wine/dosdevices"
  find -L $dosdevs -name $dosdevs -o -type d -prune -o -type l -exec rm {} +
  startNTServices
fi



echo
uname -a
echo --- NETWORK ---
wine ipconfig /all
echo --- DISKS ---
lsblk
echo
echo --- CPU ---
lscpu



log "Press any key to exit..."
while true
do 
  sleep 5
  watchdog  
done

