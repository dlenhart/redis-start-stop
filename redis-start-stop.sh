#!/bin/sh

###
# redis-start-stop.sh
#
# Author:  Drew D. Lenhart
# Date:  10/28/2018
# URL: https://github.com/dlenhart/redis-start-stop
# Desc:  Start/Stop shell script for Redis
#
# Use: ./redis-start-stop.sh {start|stop}
###

##Config path
REDIS_CONFIG_PATH=/path/to/configs
##Config name
REDIS_CONFIG=redis.conf
SENTINEL_CONFIG=sentinel.conf
##Use Sentinel? true/false - Optional
USE_SENTINEL=true
##Run Ping/Pong test - Optional
RUN_PING_PONG=true
##Server Infomation
REDIS_SERVER=127.0.0.1
REDIS_PORT=6380
SENTINEL_PORT=16380

#RUN CLI Command
run_command () {
  redis-cli -h $1 -p $2 $3
}

#CHECK for arguments
case "$1" in
  start)
    echo "STARTING REDIS ... "

    #START Redis with customized Redis config
    redis-server ${REDIS_CONFIG_PATH}/${REDIS_CONFIG} --daemonize yes

    echo "CHECKING PID ... "

    #Get PID
    redispid=`ps -ef | grep redis-server | grep -v grep | grep -v tail | awk '{print $2}'`

    #Regex to check if pid is number
    regex='^[0-9]+$'

    if ! [[ $redispid =~ $regex ]] ; then
      echo $redispid
      echo "COULD NOT GET PID OF REDIS-SERVER, CHECK LOGS!" >&2; exit 1
      #Set flag to false for sentinel operation
      RedisFlag=false
    else
      echo "REDIS-SERVER STARTED ON PID: $redispid "
      echo "REDIS-SERVER STARTUP SUCCESS!"

      if ${RUN_PING_PONG} ; then
        echo "TESTING PING ... "
        run_command ${REDIS_SERVER} ${REDIS_PORT} PING
      fi

      #set flag to TRUE
      RedisFlag=true
    fi

    #Only start Sentinel if RedisFlag is TRUE & USE_SENTINEL is TRUE
    if ${USE_SENTINEL} ; then
      if $RedisFlag ; then
        echo "STARTING SENTINEL ... "
        sleep 2
        #Redis running, Start Sentinel
        redis-sentinel ${REDIS_CONFIG_PATH}/${SENTINEL_CONFIG} --daemonize yes

        echo "CHECKING SENTINEL PID ... "

        sentinelpid=`ps -ef | grep redis-sentinel | grep -v grep | grep -v tail | awk '{print $2}'`

        if ! [[ $sentinelpid =~ $regex ]] ; then
          echo "COULD NOT GET PID OF REDIS-SENTINEL, CHECK LOGS!" >&2; exit 1
        else
          echo "REDIS SENTINEL STARTED ON PID: $sentinelpid "
          echo "SENTINEL STARTUP SUCCESS!"
        fi
      fi
    fi
    ;;
  stop)
    echo "STOPPING REDIS-SERVER ... "
    #STOP Redis
    run_command ${REDIS_SERVER} ${REDIS_PORT} shutdown

    #If sentinel true - stop it.
    if ${USE_SENTINEL} ; then
      echo "STOPPING REDIS-SENTINEL ... "
      run_command ${REDIS_SERVER} ${SENTINEL_PORT} shutdown
    fi
    ;;
  *)
    echo "UKNOWN OPTION!"
    exit 1
    ;;
esac

exit 0
