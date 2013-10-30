#! /bin/bash

echo "hadoop env check ..."
if ! which hadoop > /dev/null 2>&1; then
    echo "hadoop command not found ..."
    exit 90
fi

if ! which hdfs > /dev/null 2>&1; then
    echo "hdfs command not found ..."
    exit 90
fi

hadoop_local_dir=$HOME/hadoop_demo

hdfs_input_dir=/wordcount_input
hdfs_output_dir=/wordcount_output

if [ ! -e $hadoop_local_dir ]; then
    mkdir -p $hadoop_local_dir
fi

# echo "clean $hadoop_local_dir ..."
# rm -rf $hadoop_local_dir/*

if [ ! -e $hadoop_local_dir/20417.txt ] && [ ! -e $hadoop_local_dir/5000.txt ] && [ ! -e $hadoop_local_dir/5000.txt ]; then
    echo "download test txt file from internet ..."

    curl http://www.gutenberg.org/cache/epub/20417/pg20417.txt -o $hadoop_local_dir/20417.txt && curl http://www.gutenberg.org/cache/epub/5000/pg5000.txt -o $hadoop_local_dir/5000.txt && curl http://www.gutenberg.org/cache/epub/4300/pg4300.txt -o $hadoop_local_dir/4300.txt

    if [ $? -ne 0 ]; then
        echo "download txt file failed ! check internet connection ..."
        exit 99
    fi
fi

if ! jps | grep 'NameNode' > /dev/null 2>&1; then
    echo "start hdfs deamons ..."
    start-dfs.sh
    if [ $? -ne 0 ]; then
        echo "hdfs start failed! ..."
        exit 98
    fi
fi

if ! hadoop fs -ls / > /dev/null 2>&1; then
    echo "WARN!!! format hdfs ...."
    hadoop namenode -format
fi

echo "delete output dir on hdfs ..."
if hadoop fs -ls $hdfs_output_dir > /dev/null 2>&1; then
    echo "delete hdfs output dir ... "
    hadoop fs -rm -f -R $hdfs_output_dir

    if [ $? -ne 0 ]; then
        echo "delete hdfs output dir failed!"
        exit 96
    fi
fi

echo "create input dir on hdfs ..."
if ! hadoop fs -ls $hdfs_input_dir > /dev/null 2>&1; then
    hdfs dfs -mkdir -p $hdfs_input_dir
    if [ $? -ne 0 ]; then
        echo "create hdfs input dir failed!"
        exit 96
    fi
fi


echo "copy $hadoop_local_dir files to HDFS folder $hdfs_input_dir ..."
hdfs dfs -copyFromLocal -f $hadoop_local_dir/* $hdfs_input_dir

if [ $? -ne 0 ]; then
    echo "copy local file to hdfs failed!"
    exit 97
fi


if ! jps | grep 'NodeManager' > /dev/null 2>&1; then
    echo "start mapreduce deamons ..."
    start-yarn.sh
    if [ $? -ne 0 ]; then
        echo "yarn mapreduce start failed! ..."
        exit 94
    fi
fi

hadoop_example_jar=$HOME/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.2.0.jar

echo "hdfs input $hdfs_input_dir :"
hadoop fs -ls $hdfs_input_dir

hadoop_demo_output=$HOME/hadoop_demo_output

if [ ! -e $hadoop_demo_output ]; then
    mkdir -p $hadoop_demo_output
fi

echo "clear $hadoop_demo_output ..."
rm -rf $hadoop_demo_output/*

echo "run wordcount example ... "
hadoop jar $HOME/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.2.0.jar wordcount $hdfs_input_dir $hdfs_output_dir

if [ $? -ne 0 ]; then
    echo "wordcount example failed! ..."
    exit 93
fi


echo "hdfs input $hdfs_output_dir :"
hadoop fs -ls $hdfs_output_dir

if ! hadoop fs -ls $hdfs_output_dir/_SUCCESS > /dev/null 2>&1; then
    echo "hadoop sample failed"
    exit 90
fi

echo "get result to local disk ..."
hdfs dfs -get $hdfs_output_dir/part-r-00000 $hadoop_demo_output/wordcount_result.txt

wc -l $hadoop_demo_output/wordcount_result.txt

head -n 10 $hadoop_demo_output/wordcount_result.txt

tail -n 10 $hadoop_demo_output/wordcount_result.txt

if [ $? -eq 0 ]; then
    echo "hadoop sample well DONE."
    exit 0
fi

