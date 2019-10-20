#!/bin/bash
SLEEP_SECONDS=$1
PID=$2
PERF_TOOLS_HOME=$(pwd)
GEN_RESULTS_DIR=$PERF_TOOLS_HOME/gen-flame-graphs-result
AGENT_HOME=$PERF_TOOLS_HOME/perf-map-agent
AGENT_JAR=$AGENT_HOME/attach-main.jar
AGENT_OUT=$AGENT_HOME/out
FLAME_GRAPH_PL_HOME=$PERF_TOOLS_HOME/FlameGraph
FLAME_GRAPH_GENERAGED_FILE=$PERF_TOOLS_HOME/flamegraph-mixed-model-`date +%Y%m%d-%H%M%S`.svg
MAP_FILE=/tmp/perf-$PID.map
function check_env(){
  if [[ ! -x $JAVA_HOME ]]; then
      echo "ERROR: JAVA_HOME not set correctly; edit $0 and fix"
      exit
  fi
  if [[ ! -x $AGENT_HOME ]]; then
      echo $AGENT_HOME
      echo "ERROR: AGENT_HOME not set correctly; edit $0 and fix."
      exit
  fi
  if [[ ! -x $GEN_RESULTS_DIR ]]; then
      echo "ERROR: '$GEN_RESULTS_DIR' not found;Please mkdir a file :'$GEN_RESULTS_DIR'"
      exit
  fi
}
#generate perf.data with command: perf record
function perf_record(){
  echo "Perf record for all processors with sleep 30 seconds."
  cmd_perf="sudo perf record -F 99 -a -g -- sleep 30"
  eval $cmd_perf
  if [[ -e "./perf.data" ]]; then
     echo "SUCCESS: perf.data was generated."
  else
     echo "ERROR: perf.data not generated;edit $0 and fix."
     exit
  fi
}
#agent mapping pid
function gen_map_file(){
  user=$(ps ho user -p $PID)
  echo "Agent mapping PID $PID with user $user"
  cmd_agent="cd $AGENT_OUT;java -cp attach-main.jar:$JAVA_HOME/lib/tools.jar net.virtualvoid.perf.AttachOnce $PID"
  cmd_agent="sudo -u $user sh -c '$cmd_agent'"
  eval $cmd_agent
  if [[ -e "$MAP_FILE" ]]; then
     echo "generate map file"
     chown root $MAP_FILE
     chmod 666 $MAP_FILE
  else
     echo "ERROR: $MAP_FILE not created."
     exit
  fi
}
#generate flame graph
function gen_flame_graph(){
  cmd_stack="sudo perf script|$FLAME_GRAPH_PL_HOME/stackcollapse-perf.pl  --pid|$FLAME_GRAPH_PL_HOME/flamegraph.pl --color=java --width=800 --minwidth=0.5 --title=\"$PID flame graph\"  --hash > $FLAME_GRAPH_GENERAGED_FILE"
  eval $cmd_stack
}
check_env
perf_record
gen_map_file
gen_flame_graph
echo "SUCCESS: generate flame graph."
