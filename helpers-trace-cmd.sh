#! /bin/bash


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
        | grep SKB_GSO \
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
