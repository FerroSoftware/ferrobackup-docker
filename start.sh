#!/bin/bash
trap finalize SIGTERM

function finalize() {
  echo "Shutting down FBS ($COMPONENTS)..."
  if [ "$ISSERVER" = true ] ; then 
    wine $APPPATH/FBSServer.exe -stop
  fi 
  echo "Done."
  exit
}

function startX() {
  echo "Starting Xvfb..."
  rm -f /tmp/.X0-lock
  Xvfb :0 -screen 0 1024x768x16 &
  sleep 2
  export DISPLAY=:0.0
}

function isHttpServerAlive() {
  PREVHTTPSERVERALIVE=$HTTPSERVERALIVE
  wget --retry-connrefused -q --tries 5 -T 6 http://127.0.0.1:4530/null && HTTPSERVERALIVE=true || HTTPSERVERALIVE=false
}

function isServerProcessAlive() {
  pgrep "FBSServer.exe" > /dev/null && SERVERPROCESSALIVE=true || SERVERPROCESSALIVE=false
}

function isAutoupdateInProgress() {
  pgrep -f "AUTOUPDATE" > /dev/null && AUTOUPDATE=true || AUTOUPDATE=false
}

function watchdog() {
  if [ "$ISSERVER" = true ] ; then 
    isServerProcessAlive
    if [ "$SERVERPROCESSALIVE" = false ] ; then
      isAutoupdateInProgress
      if [ "$AUTOUPDATE" = false ] ; then
        echo "FBSServer.exe proccess has been terminated. Restarting FBS Server service..."
        wine $APPPATH/FBSServer.exe -start
      fi  
    else
      isHttpServerAlive
      if [ "$HTTPSERVERALIVE" = false ] && [ "$PREVHTTPSERVERALIVE" = true ] ; then
        isAutoupdateInProgress
        if [ "$AUTOUPDATE" = false ] ; then
          echo "HTTP server is not responding. Stopping FBS Server service..."
          wine $APPPATH/FBSServer.exe -stop
        fi  
      fi
    fi
  fi

}

function install() {
  echo "Installation..."

  echo "Downloading installer..."
  cd /tmp && wget www.ferrobackup.com/download/Fbs5InstDocker.exe
  echo "Initializing Wine..."
  wine ipconfig
  startX
  echo "Installing FBS ($COMPONENTS)..."
  wine /tmp/$INSTFILE /SP- /verysilent /noicons /LOG /COMPONENTS="$COMPONENTS" /dir="Z:$APPPATH"

  echo "Installation complete"
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


echo "Starting..."


if [ ! -f /tmp/$INSTFILE ] 
then
  install
else
  startX
fi


echo "Starting NT services ($COMPONENTS)..."
sleep 10
/usr/lib/i386-linux-gnu/wine/bin/wineserver -p
wine ipconfig /all




echo "Press any key to exit..."
while true
do 
  sleep 1.0; 
  watchdog  
done

