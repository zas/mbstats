#!/bin/bash
set -xe

INTERPRETER=$1
[ -z "$INTERPRETER" ] && INTERPRETER="python"

STATSLOG_SOURCE=~/src/mbstats.testlogs/stats.log
NOW=$(date -u +'%FT%TZ')
TESTTMPDIR=$(mktemp -d -t tmp.XXXXXXXXXX)
function finish {
  rm -rf "$TESTTMPDIR"
}
trap finish EXIT

STATSLOG=$TESTTMPDIR/stats.log

>$STATSLOG

OFFSET=0

SIZE=500000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

COMMON_OPTS=" stats.parser.py -f $STATSLOG -w $TESTTMPDIR -n $NOW -l . "
CMD="$INTERPRETER $COMMON_OPTS"
$CMD --influx-drop-database --startover;

SIZE=100000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

$CMD

SIZE=110000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

$CMD

SIZE=120000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

# simulate a log rotation
mv $STATSLOG $STATSLOG.1

SIZE=130000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

$CMD

SIZE=2000000
HEAD=$(($OFFSET+$SIZE))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

$CMD

#simulate a hole
SIZE=2000000
HEAD=$(($OFFSET+$SIZE+500000))
head -$HEAD $STATSLOG_SOURCE | tail -$SIZE >> $STATSLOG
OFFSET=$HEAD

$CMD
