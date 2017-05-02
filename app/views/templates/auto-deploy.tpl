#!/bin/bash
# pufferd Installation Script

pufferdVersion={{ pufferdVersion }}

export DEBIAN_FRONTEND=noninteractive
downloadUrl="https://dl.pufferpanel.com/pufferd/${pufferdVersion}/pufferd"

RED=$(tput setf 4)
GREEN=$(tput setf 2)
NORMAL=$(tput sgr0)
BOLD=$(tput bold)

function checkResponseCode() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}An error occurred while installing, halting...${NORMAL}"
        exit 1
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root!" 1>&2
    exit 1
fi

if [ "$SUDO_USER" == "" ]; then
    SUDO_USER="root"
fi

if type apt-get &> /dev/null; then
    if [[ -f /etc/debian_version ]]; then
        echo -e "System detected as some variant of Ubuntu or Debian."
        OS_INSTALL_CMD="apt"
    else
        echo -e "${RED}This OS does not appear to be supported by this program!${NORMAL}"
        exit 1
    fi
elif type yum &> /dev/null; then
    echo -e "System detected as CentOS variant."
    OS_INSTALL_CMD="yum"
else
    echo -e "${RED}This OS does not appear to be supported by this program, or apt-get/yum is not installed!${NORMAL}"
    exit 1
fi

# Install Other Dependencies
echo "Installing some dependiencies."
if [ $OS_INSTALL_CMD == 'apt' ]; then
    apt-get install -y openssl curl openjdk-8-jdk tar python lib32gcc1 lib32tinfo5 lib32z1 lib32stdc++6
else
    yum -y install openssl curl java-1.8.0-openjdk-devel tar python glibc.i686 libstdc++.i686
fi

# Ensure /srv exists
mkdir -p /srv/pufferd

cd /srv/pufferd
curl -L -o pufferd $downloadUrl
checkResponseCode

mkdir /var/lib/pufferd /etc/pufferd

chmod +x pufferd
./pufferd -install -auth {{ settings.master_url }} -token {{ node.daemon_secret }} -config /etc/pufferd/config.json
checkResponseCode

chown -R pufferd:pufferd /srv/pufferd /var/lib/pufferd /etc/pufferd
checkResponseCode

template='
#!/bin/sh\n
### BEGIN INIT INFO\n
# Provides:          pufferd\n
# Required-Start:    $local_fs $network $named $time $syslog\n
# Required-Stop:     $local_fs $network $named $time $syslog\
# Default-Start:     2 3 4 5\n
# Default-Stop:      0 1 6\n
# Description:       pufferd daemon service\n
### END INIT INFO\n
\n
SCRIPT=/srv/pufferd/pufferd\ --config=/etc/pufferd/config.json\n
RUNAS=pufferd\n
\n
PIDFILE=/var/run/pufferd.pid\n
LOGFILE=/var/log/pufferd.log\n
\n
start() {\n
  if [ -f /var/run/$PIDNAME ] && kill -0 $(cat /var/run/$PIDNAME); then\n
    echo \'Service already running\' >&2\n
    return 1\n
  fi\n
  echo \'Starting service…\' >&2\n
  local CMD="$SCRIPT &> \\"$LOGFILE\\" & echo \\$!"\n
  su -c "$CMD" $RUNAS > "$PIDFILE"\n
  echo \'Service started\' >&2\n
}\n
\n
stop() {\n
  if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then\n
    echo \'Service not running\' >&2\n
    return 1\n
  fi\n
  echo \'Stopping service…\' >&2\n
  kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"\n
  echo \'Service stopped\' >&2\n
}\n
\n
uninstall() {\n
  echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "\n
  local SURE\n
  read SURE\n
  if [ "$SURE" = "yes" ]; then\n
    stop\n
    rm -f "$PIDFILE"\n
    echo "Notice: log file has not been removed: \'$LOGFILE\'" >&2\n
    update-rc.d -f pufferd remove\n
    rm -fv "$0"\n
  fi\n
}\n
\n
case "$1" in\n
  start)\n
    start\n
    ;;\n
  stop)\n
    stop\n
    ;;\n
  uninstall)\n
    uninstall\n
    ;;\n
  restart)\n
    stop\n
    start\n
    ;;\n
  *)\n
    echo "Usage: $0 {start|stop|restart|uninstall}"\n
esac
'

if type systemctl &> /dev/null; then
  systemctl start pufferd
  systemctl enable pufferd
else
  echo "systemd not installed, installing init.d script"
  echo "${initScript}" > /etc/init.d/pufferd
  chmod +x "/etc/init.d/pufferd"
  touch /var/log/pufferd.log
  chown pufferd:pufferd /var/log/pufferd.log
  update-rc.d pufferd defaults
  service pufferd start
fi

echo "Successfully installed the daemon"

exit 0
