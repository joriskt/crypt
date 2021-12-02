#!/bin/bash

# Read input filename.
while [ -z $infile ]; do 
    read -e -p "Input archive: " infile
    if [ -d $infile ]; then
        echo -e "Input archive cannot be a directory.\n"
    fi;
done;
# Make sure path is absolute.
if [ "$infile" = "${infile#/}" ]; then
    infile=$PWD/$infile
fi

# Read output folder.
while [ -z $outdir ]; do
    read -e -p "Output folder: " outdir
    if [ -z $outdir ] || [ -f $outdir ]; then
        echo "error: not an existing directory: $outdir"
    fi;
done;
# Make sure path is absolute.
if [ "$outdir" = "${outdir#/}" ]; then
    outdir=$PWD/$outdir
fi

# Determine the amount of shards.
while [ -z $shards ]; do
    read -p "How many shards should be created?: " shards
    if [ -z $shards ] || [ $shards -lt 3 ]; then
        echo -e "The minimum amount of shards is 3.\n"
    fi
done

# Determine the threshold.
while [ -z $threshold ]; do
    read -p "How many shards should be required to reconstruct the archive?: " threshold
    if [ -z $threshold ] || [ $threshold -lt 2 ] || [ $threshold -gt $shards ]; then
        echo -e "The minimum threshold is 2, the maximum is the amount of shards: $shards.\n"
    fi
done

# Create two temporary directories: one for the shard files, one for the template.
sharddir=$(mktemp -d)
workdir=$(mktemp -d)
trap "rm -rf $sharddir && rm -rf $workdir" 0 2 3 15

# Split the input archive into files called shard.1 through shard.$shards
echo -e "Splitting $infile to $sharddir/shard{1-$shards}\n"
cat $infile | ssss-split -t $threshold -n $shards -Q | split -a 1 -l 1 --numeric-suffixes=1 - $sharddir/shard

echo -e "\n"

# For every shard
for (( i=1; i<=$shards; i++ ))
do
    echo "Preparing shard: $i"
    # Copy the template into the workdir.
    cp -r ./template/shard/* $workdir
    cp -r ./res $workdir

    # Move the archive shard to workdir/data.
    mv $sharddir/shard$i $workdir/data/

    # Generate 100% parity redundancy data.
    echo "Generating parity data"
    par2 c -r100 -q -q -u $workdir/data/shard$i

    # Rename "shard4" to "s4" in all file names.
    (cd $workdir/data && rename 'shard' 's' shard*)

    # Replace the variables in the README files.
    sed -i "s/THRESHOLD/$threshold/" $workdir/*.md
    sed -i "s/SHARDS/$shards/" $workdir/*.md
    sed -i "s/SHARD/$i/" $workdir/*.md

    echo "Contents of $workdir:"
    ls -la $workdir

    # Build the ISO image from the workdir, outputting it to the outdir.
    echo "Building ISO image: $outdir/shard$i.iso"
    mkisofs -r -J -V shard_$i -o $outdir/shard$i.iso $workdir 2>&1 >/dev/null

    # Clean up the workdir.
    echo -e "Cleaning up..\n"
    rm -rf $workdir/*
done
