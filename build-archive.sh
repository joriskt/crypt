#!/bin/bash

# Read input folder.
read -e -p "Input folder: " input_folder
if [ -z $input_folder ] || [ ! -d $input_folder ]; then
    echo "error: not an existing directory: $input_folder"
    exit 1
fi

# Read output filename.
output_file_default=archive.zip
output_file=$output_file_default
read -e -p "Output file name ($output_file_default): " output_file
if [ -z $output_file ]; then
    output_file=$output_file_default
fi
if [ -f $output_file ]; then
    read -p "Output file already exists. Continue? (y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi

# Create a temporary directory and delete it's contents upon script exit.
workdir=$(mktemp -d)
trap "rm -rf $workdir" 0 2 3 15

# Copy the template to our working directory.
cp -r template/archive/* $workdir

# Create a temporary symlink for the data folder. Prepend $PWD if it's a relative path.
if [ "$input_folder" = "${input_folder#/}" ]; then
    input_folder=$PWD/$input_folder
fi
ln -s $input_folder $workdir/data

# Zip the temp folder and save it to the output file.
rm $output_file
7z a -tzip $output_file $workdir/* >/dev/null && echo -e "\nDone: $output_file\n"


