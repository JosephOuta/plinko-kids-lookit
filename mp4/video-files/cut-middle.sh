#!/bin/bash

# Define the input and output folders
input_folder="/Users/jouta1/Desktop/Appendix/projects/plinko/plinko-blender/blend-files/current-version.nosync/2025/exports-audio-script/test-with-sound"
output_folder="/Users/jouta1/Desktop/Appendix/projects/plinko/plinko-blender/blend-files/current-version.nosync/2025/exports-audio-script/test-with-sound/reduced"

mkdir -p "$output_folder" # Create output folder if it doesn't exist

echo "==== Starting batch processing ===="
start_all=$(date +%s)

# Loop through all matching files in the input folder
for input_video in $input_folder/{7..14}-*.mp4; do
    [ -e "$input_video" ] || continue

    filename=$(basename "$input_video")
    output_video="$output_folder/$filename"

    echo ""
    echo "----- Processing $filename -----"
    start_file=$(date +%s)

    temp_video1="temp_part1.mp4"
    temp_video2="temp_part2.mp4"
    temp_video3="temp_part3.mp4"

    echo "[1/6] Extracting 0–2s..."
    #ffmpeg -y -ss 0 -i "$input_video" -t 2 -c:v libx264 -c:a aac "$temp_video1"

    ##ffmpeg -y -ss 0 -i "$input_video" -t 2 -c:v libx264 -crf 18 -c:a copy "$temp_video1"
    ffmpeg -y -ss 0.25 -i "$input_video" -t 2 -avoid_negative_ts make_zero -c:v libx264 -crf 18 -preset veryfast -c:a aac "$temp_video1"

    echo "[2/6] Extracting 4–6s..."
    ffmpeg -y -ss 4 -i "$input_video" -t 2 -avoid_negative_ts make_zero -c:v libx264 -crf 18 -preset veryfast -c:a aac "$temp_video2"

    echo "[3/6] Extracting 7s–end..."
    ffmpeg -y -ss 7 -i "$input_video" -avoid_negative_ts make_zero -c:v libx264 -crf 18 -preset veryfast -c:a aac "$temp_video3"

    echo "[4/6] Converting to .ts for concat..."
    ffmpeg -y -i "$temp_video1" -c copy -bsf:v h264_mp4toannexb -f mpegts part1.ts
    ffmpeg -y -i "$temp_video2" -c copy -bsf:v h264_mp4toannexb -f mpegts part2.ts
    ffmpeg -y -i "$temp_video3" -c copy -bsf:v h264_mp4toannexb -f mpegts part3.ts

    echo "[5/6] Concatenating segments..."
    ffmpeg -y -i "concat:part1.ts|part2.ts|part3.ts" -c copy -bsf:a aac_adtstoasc "$output_video"

    echo "[6/6] Cleaning up..."
    rm "$temp_video1" "$temp_video2" "$temp_video3" part1.ts part2.ts part3.ts

    end_file=$(date +%s)
    duration=$((end_file - start_file))
    echo "✅ Done processing $filename in ${duration}s"
done

end_all=$(date +%s)
total_duration=$((end_all - start_all))
echo ""
echo "🎉 All done! Total time: ${total_duration}s"