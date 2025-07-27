#!/bin/ksh
set -vx

# Define paths
stage_path=/appdata/system/input/stage
archive_path=/appdata/system/output/archive
log_dir=/appdata/system/output/logs
mkdir -p $log_dir
# Date setup
prevdate=$(date -d yesterday "+%Y%m%d")
logfile=${log_dir}/move_log_${prevdate}_$(date '+%H%M%S').log
# Job control
MAX_JOBS=5
current_jobs=0
# Counters
total_files=0
success_count=0
failure_count=0
echo "Processing files from $prevdate" | tee -a $logfile
found_files=0
for file in ${stage_path}/${prevdate}*.sis; do
  if [ ! -f $file ]; then
    continue
  fi
  found_files=1
  total_files=$((total_files + 1))
  filename=$(basename "$file")
  clientid=$(echo "$filename" | cut -d '_' -f3)
  mkdir -p ${archive_path}/${clientid}
  echo "[$(date '+%F %T')] Moving $filename to ${archive_path}/${clientid}" | tee -a $logfile
  (
    if mv $file ${archive_path}/${clientid}/; then
      echo "[$(date '+%F %T')] SUCCESS: $filename moved successfully." >> $logfile
      touch ${archive_path}/${clientid}/.success_${filename}
      echo "ok" > "/tmp/move_status_${filename}"
    else
      echo "[$(date '+%F %T')] ERROR: Failed to move $filename." >> $logfile
      echo "ERROR: $filename move failed" | mailx -s "ALERT: Move Failure - $filename" admin@example.com
      echo "fail" > /tmp/move_status_${filename}
    fi
  ) &
  current_jobs=$((current_jobs + 1))
  if [ $current_jobs -ge $MAX_JOBS ]; then
    wait
    # Read status files and update counters
    for status_file in /tmp/move_status_*; do
      if grep -q "ok" $status_file; then
        success_count=$((success_count + 1))
      else
        failure_count=$((failure_count + 1))
      fi
      rm -f $status_file
    done
    current_jobs=0
  fi
done
# Final wait and final status collection
wait
for status_file in /tmp/move_status_*; do
  if grep -q "ok" $status_file; then
    success_count=$((success_count + 1))
  else
    failure_count=$((failure_count + 1))
  fi
  rm -f $status_file
done
# No files case
if [ $found_files -eq 0 ]; then
  echo "[$(date '+%F %T')] No files found for date: $prevdate" | tee -a $logfile
fi
# Summary
echo "========== Summary ==========" | tee -a "$logfile"
echo "Date: $prevdate" | tee -a "$logfile"
echo "Total files processed : $total_files" | tee -a "$logfile"
echo "Successful moves      : $success_count" | tee -a "$logfile"
echo "Failed moves          : $failure_count" | tee -a "$logfile"
echo "Log saved to          : $logfile"
exit 0
