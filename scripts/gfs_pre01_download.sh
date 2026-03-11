#!/bin/bash
# Adapted from UGAWRF download script
DATA_DIR="/path/to/download/DATA/GFS"
START_FHR=0
END_FHR=$1 # takes in a number of hours to download as argument, 27hr is good for 24hr run
# --- End Configuration ---

# --- Main Script ---
mkdir -p "$DATA_DIR"
cd "$DATA_DIR" || exit
rm gfs.*

hour_utc=$(date -u +"%H")
utc_date=$(date -u +"%Y%m%d")

echo "Current UTC date is: $utc_date"
echo "Current UTC hour is: $hour_utc"

if (( hour_utc >= 4 && hour_utc < 10 )); then
    run_hour="00"
elif (( hour_utc >= 10 && hour_utc < 16 )); then
    run_hour="06"
elif (( hour_utc >= 16 && hour_utc < 22 )); then
    run_hour="12"
else
    run_hour="18"
    if (( hour_utc < 4 )); then
        utc_date=$(date -u -d "yesterday" +"%Y%m%d")
        echo "Fetching previous day's 18Z run for date: $utc_date"
    fi
fi

echo "Selected GFS run: ${run_hour}Z for date $utc_date"

BASE_URL="https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.${utc_date}/${run_hour}/atmos"

echo "Downloading GFS forecast hours from F${START_FHR} to F${END_FHR}..."
for fhr_num in $(seq $START_FHR $END_FHR); do
    fhr=$(printf "%03d" $fhr_num)
    
    FILENAME="gfs.t${run_hour}z.pgrb2.0p25.f${fhr}"
    FULL_URL="${BASE_URL}/${FILENAME}"
    
    echo "Queueing download: ${FILENAME}"

    wget -nv "$FULL_URL" &
done

wait

echo "All GFS files downloaded successfully to ${DATA_DIR}"
