#! /usr/bon/bash

function decompress_all() {
	for res_dir in `ls results | grep results-`; do
		if [ -d $res_dir ]; then
			echo $res_dir already copied! Skipping...
		else
			cp -r results/$res_dir .
		fi
		if [ -d $res_dir/server/results.tar.zst ]; then
			echo Decompressing $res_dir...
			./decompress_results.sh $res_dir
		fi
		echo $res_dir decompressed!
	done
}

function check_if_decompressed() {
	for res_dir in `ls | grep results-`; do
		echo -n "$res_dir: ";
		if [ -n "$(find $res_dir -iname *.zst)" ]; then
			echo Needs decompression...
		else
			echo Already decompressed!
		fi
	done
}

function list_all_tests() {
	i=0
	for res_dir in `ls | grep results-`; do
		i=$(( i+1 ))
		echo -n "$i. $res_dir: "
		cat $res_dir/EXPERIMENT_DATA/TEST_CONFIG
	done
}

<<<<<<< HEAD
function check_if_extracted() {
	i=0
	for res_dir in `ls | grep results-`; do
		i=$((i+1))
		echo -n "$i. $res_dir: "
		if [ -d $res_dir/summary ]; then
			echo YES;
		else
			echo NO;
		fi
	done
}

function extract_all() {
	for res_dir in `ls | grep results-`; do
		if [ -d "$res_dir/summary" ]; then
			echo $res_dir already done. Skipping...
		else
			echo Extracting data from $res_dir...
			./extract-data.sh $res_dir
			echo Done!
		fi
	done
=======
function list_site() {
#    usage="Usage: list_by_site <SITE>"
#    if [ -z $1 ]; then
#        echo "Please give the site..."
#        echo $usage
#        return -1
#    else
#        site=$1
#    fi

    for res in $(ls | grep results-); do
	echo -n $res:
	server=$(cat $res/EXPERIMENT_DATA/SERVER | cut -d- -f1)
	echo $server
    done

    #results=$(ssh $site.g5k "ls wireguard-experiment/results/$variant/")
    #for res in $results; do
    #    echo $res;
    #done
}


function list_by_variant() {
    usage="Usage: list_by_variant <SITE> <VARIANT>"
    if [ -z $1 ]; then
	echo "Please give the site..."
	echo $usage
	return -1
    else
	site=$1
    fi

    if [ -z $2 ]; then
	echo "Please give the variant"
	echo $usage
	return -1
    else
	variant=$2
    fi

    results=$(ssh $site.g5k "ls wireguard-experiment/results/$variant/")
    for res in $results; do
	echo $res;
    done
}

function check_analyzed_tests() {
    for i in `ls | grep results-`; do
        echo "$i: "
	echo "TEST_CONFIG: $(cat $i/EXPERIMENT_DATA/TEST_CONFIG)"
	echo -n "Analysed: "
	if [ -z "$(ls $i | grep summary)" ]; then
            echo "No"
	else
            echo "Yes"
	fi
	echo
    done
>>>>>>> dc8cb74 (LAst work)
}
