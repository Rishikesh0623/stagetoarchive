#!/bin/ksh
set -vx
#define paths
stage_path=/appdata/system/input/stage
archive_path=/appdata/system/output/archive
prevdate=$(date --date yesterday "+%Y%m%d")
#processing the files in stage_path
echo 'processing files with yesterday date in $stage_path'
#loop for picking the files from stage_path
for file in ${$stage_path}/${prevdate}.*.sis;
do
filename=$(basename "$file")
clientid=$(echo "$filename" | cut -d '.' -f3)
#create client folder if not already present in $archive_path
mkdir -p ${$archive_path}/${$clientid}
echo 'Moving files $filename to ${archive_path}/${clientid}'
mv $file ${archive_path}/${clientid}/
sleep 5
done
exit 0