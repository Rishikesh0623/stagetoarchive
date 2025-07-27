#!/bin/ksh
set -vx
# Define paths
stage_path=/appdata/system/input/stage
archive_path=/appdata/system/output/archive
# Get yesterday's date in YYYYMMDD format (portable for most Linux distros)
prevdate=$(date -d yesterday "+%Y%m%d")
echo "Processing files with yesterday's date ($prevdate) in $stage_path"
MAX_JOBS=5
current_jobs=0
# Enable nullglob to avoid literal pattern if no files match (bash/ksh-compatible alternative)
found_files=0
for file in "${stage_path}/${prevdate}"*.sis; do
  # Check if no matching file (literal pattern stays if no match)
  if [ ! -f "$file" ]; then
    continue
  fi
  found_files=1
  filename=$(basename "$file")
  clientid=$(echo "$filename" | cut -d '.' -f3)
  mkdir -p "${archive_path}/${clientid}"
  echo "Moving file: $filename to ${archive_path}/${clientid}"
  (
    if mv $file ${archive_path}/${clientid}/; then
      echo "Successfully moved $filename"
    else
      echo "Failed to move $filename"
    fi
  ) &
  current_jobs=$((current_jobs + 1))
  if [ $current_jobs -ge $MAX_JOBS ]; then
    wait
    current_jobs=0
  fi
done
# If no files were processed
if [ "$found_files" -eq 0 ]; then
  echo "No files found to process for date: $prevdate"
fi
# Final wait to finish any background jobs
wait
exit 0
