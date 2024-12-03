#! /bin/bash

function count_poll() {
    usage="count_poll FILE [prefix]"

    if [ -z 1 ]; then
    echo $usage
    return
    else
    FILE=$1
    fi

    shift
    PREFIX=$1

    total=`cat $FILE | grep wg_packet_rx_poll | cut -d" " -f2 | awk '{ sum += $1} END {print sum}'`
    in_ksoftirqd=`cat $FILE | grep wg_packet_rx_poll | grep ksoftirqd | cut -d" " -f2 | awk '{ sum += $1} END {print sum}'`
    in_decrypt=`cat $FILE | grep wg_packet_rx_poll | grep wg_packet_decrypt_worker | cut -d" " -f2 | awk '{ sum += $1} END {print sum}'`
    in_encrypt=`cat $FILE | grep wg_packet_rx_poll | grep wg_packet_encrypt_worker | cut -d" " -f2 | awk '{ sum += $1} END {print sum}'`

    echo $PREFIX,$in_ksoftirqd,$in_encrypt,$in_decrypt,$total
}

function download_traces() {
    usage="download_traces res_dir"
    if [ -z $1 ]; then
	echo $usage
	return
    else
	res_dir=$1
    fi

    scp -r nancy.g5k:wireguard-experiment/$res_dir .
}

function extract_funcgraph_trace() {
    usage="extract_funcgraph_trace file [PREFIX]"

    if [ -z $1 ]; then
    FILE=trace.dat
    else
    FILE=$1
    fi

    PREFIX=$2

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -R -i $FILE \
        | grep funcgraph_exit \
        | tr "=[]" " " \
        | awk -v prefix=$PREFIX '{ print prefix,$1,$2,$4,$7,$13,$15 }' \
        | tr ' ' ',' \
        | sed 's/:,/,/'
}

function extract_rx_poll_stop() {
    usage="extract_rx_poll_stop file [PREFIX]"

    if [ -z $1 ]; then
    FILE=trace.dat
    else
    FILE=$1
    fi

    PREFIX=$2

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -i $FILE \
        | grep "RX_POLL STOP" \
        | tr "=[]" " " \
        | tr -d ":" \
        | awk -v prefix=$PREFIX '{ print prefix,$2,$4,$NF }' \
        | tr ' ' ',' \
        | sed 's/LIST_EMPTY/1/' \
        | sed 's/UNCRYPTED_PACKET/2/'
}

function extract_tx_work_stop() {
    usage="extract_tx_work_stop file [PREFIX]"

    if [ -z $1 ]; then
    FILE=trace.dat
    else
    FILE=$1
    fi

    PREFIX=$2

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -i $FILE \
        | grep "TX_WORKER STOP" \
        | tr "=[]" " " \
        | tr -d ":" \
        | awk -v prefix=$PREFIX '{ print prefix,$2,$4,$NF }' \
        | tr ' ' ',' \
        | sed 's/LIST_EMPTY/1/' \
        | sed 's/UNCRYPTED_PACKET/2/'
}


function extract_skb_seg() {
    usage="extract_skb_seg file [PREFIX]"

    if [ -z $1 ]; then
    FILE=trace.dat
    else
    FILE=$1
    fi

    PREFIX=$2

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -i $FILE \
        | grep bprint \
        | grep SKB_ \
        | tr "=" " " \
        | tr -d ":" \
        | awk -v prefix=$PREFIX '{ print prefix,$4,$NF }' \
        | tr ' ' ','
}

function extract_packet_duration() {
    usage="extract_packet_duration type file [PREFIX]"

    if [ -z $1 ]; then
        echo $usage
        return
    else
        type=$1
    fi

    if [ -z $2 ]; then
    FILE=trace.dat
    else
    FILE=$2
    fi

    PREFIX=$3

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -i $FILE \
        | grep bprint \
        | grep $type \
        | grep PACKET_DURATION \
        | tr "=[]" " " \
        | awk -v prefix=$PREFIX '{ print prefix,$1,$2,$4,$NF }' \
        | tr ' ' ',' \
        | sed 's/:,/,/'
}

function extract_worker_duration() {
    usage="extract_worker_duration type file [PREFIX]"

    if [ -z $1 ]; then
        echo $usage
        return
    else
        type=$1
    fi

    if [ -z $2 ]; then
    FILE=trace.dat
    else
    FILE=$2
    fi

    PREFIX=$3

    # trace-cmd report -R -i $run/$cpu/$flow/trace-printk/trace.dat \
    trace-cmd report -i $FILE \
        | grep bprint \
        | grep $type \
        | grep WORKER_DURATION \
        | tr "=[]" " " \
        | awk -v prefix=$PREFIX '{ print prefix,$1,$2,$(NF-2),$NF }' \
        | tr ' ' ',' \
        | sed 's/:,/,/'
}

function get_traces() {
    if [ -z $1 ]; then
        FILE=up-down
    else
        FILE=$1
    fi

    for resdir in `ls $FILE`; do
        type=`cat $FILE/$resdir/EXPERIMENT_DATA/CURRENT_EXP`

        # unzip resdir
        cd $FILE/$resdir/server
        if [ ! -d results ]; then
            unzip results.zip
        fi
        # get trace file
        cp results/run-1/CPU-18/nflow-100/trace-printk/trace.dat ../../../traces/trace-$type.dat
        # get out.perf
        cp results/run-1/CPU-18/nflow-100/perf/out.perf ../../../perf/perf-$type.out
        cp results/run-1/CPU-18/nflow-100/perf/perf.data ../../../perf/perf-$type.data
        # get sar
        cp results/run-1/CPU-18/nflow-100/sar/sar.data ../../../sar/sar-$type.data

        cd ../../../
    done
}

function extract_all() {
    if [ -z $1 ]; then  
        echo "give a trace file please"
        return
    else
        FILE=$1
    fi

    if [ -z $2 ]; then
        OUT=traces_out
    else
        OUT=$2
    fi

    mkdir -p $OUT

    types="RX TX ENCRYPT DECRYPT"

    extract_funcgraph_trace $FILE > $OUT/$FILE.funcgraph.csv &
    extract_rx_poll_stop $FILE > $OUT/$FILE.rx-stop.csv &
    extract_tx_work_stop $FILE > $OUT/$FILE.tx-stop.csv &
    extract_skb_seg $FILE > $OUT/$FILE.skb-segs &

    for type in $types; do
        extract_packet_duration $type $FILE > $OUT/$FILE.$type-packet.csv &
        extract_worker_duration $type $FILE > $OUT/$FILE.$type-worker.csv &
    done
}

function draw_flamegraph() {
    if [ -z $1 ]; then  
        echo "give a perf file please"
        return
    else
        FILE=$1
    fi
    FlameGraph/stackcollapse-perf.pl $FILE > $FILE.folded
    FlameGraph/flamegraph.pl $FILE.folded > $FILE.svg
    rm $FILE.folded
}
