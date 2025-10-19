#!/bin/bash

# Script to convert WAV files to AAC for optimal mobile playback
# Requires ffmpeg to be installed

echo "Converting WAV files to AAC format..."

# Create audio directory if it doesn't exist
mkdir -p "app/assets/audio"

# Convert each WAV file to AAC
for wav_file in *.wav; do
    if [ -f "$wav_file" ]; then
        # Extract filename without extension
        filename=$(basename "$wav_file" .wav)
        
        # Convert to AAC with optimized settings for mobile
        ffmpeg -i "$wav_file" \
            -c:a aac \
            -b:a 64k \
            -ar 22050 \
            -ac 1 \
            -y \
            "app/assets/audio/${filename}.aac"
        
        echo "Converted: $wav_file -> app/assets/audio/${filename}.aac"
    fi
done

echo "Conversion complete! Place your WAV files in this directory and run this script."
echo "The converted AAC files will be placed in app/assets/audio/"
