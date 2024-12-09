#!/data/data/com.termux/files/usr/bin/bash

echo "Creating test elements..."

# Create a high-quality background
magick -size 4000x4000 \
    -quality 100 \
    gradient:blue-red \
    -blur 0x8 \
    background.png

# Add complex patterns
magick -size 4000x4000 \
    -quality 100 \
    plasma:red-blue \
    pattern.png

# Add detailed text
magick -size 4000x4000 \
    -quality 100 \
    xc:none \
    -fill black \
    -pointsize 400 \
    -gravity center \
    -annotate +0+0 "TEST PDF" \
    text.png

echo "Combining elements..."
magick \
    background.png \
    \( pattern.png -alpha set -channel A -evaluate set 50% \) \
    text.png \
    -quality 100 \
    -compress none \
    test_source.pdf

rm background.png pattern.png text.png
echo "Created test_source.pdf"
