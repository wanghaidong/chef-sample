#! /bin/bash

echo "stop hadoop deamons ..."
stop-yarn.sh && stop-dfs.sh

echo "clear hadoop work dir ..."
rm -rf $HOME/hadoop_demo_output/ $HOME/hadoop/dfs/data/* $HOME/hadoop/dfs/name/* $HOME/hadoop/tmp/* $HOME/hadoop/logs/*

echo "DONE."

