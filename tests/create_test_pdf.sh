#!/data/data/com.termux/files/usr/bin/bash

# Create a gradient background
magick -size 2000x2000 gradient:blue-red \
    -gravity center \
    \( -size 1000x1000 radial-gradient:white-black \) -compose multiply -composite \
    -fill white \
    -pointsize 72 \
    -annotate +0-800 'PDF Compression Test' \
    -pointsize 48 \
    -annotate +0-600 'This is a test document with various elements' \
    -draw "circle 1000,1000 1000,1200" \
    -draw "rectangle 600,600 1400,1400" \
    -draw "path 'M 200,200 L 400,200 L 300,400 Z'" \
    test_complex.pdf

echo "Created test_complex.pdf with various graphical elements"
