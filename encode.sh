#!/bin/bash
# Source and output directories
SRC_DIR="content-src"
CONTENT_DIR="content"

# Copy HTML and Markdown files
find "$SRC_DIR" -type f \( -iname "*.html" -o -iname "*.md" \) | while read -r file; do
    rel_path="${file#$SRC_DIR/}"
    out_file="$CONTENT_DIR/$rel_path"
    out_dir=$(dirname "$out_file")
    mkdir -p "$out_dir"
    echo "Copying $file to $out_file"
    cp "$file" "$out_file"
done

# Encode images and extract colors
find "$SRC_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jxl" \) | while read -r file; do
    rel_path="${file#$SRC_DIR/}"
    out_thumb_dir="$CONTENT_DIR/thumbs/$(dirname "$rel_path")"
    out_full_dir="$CONTENT_DIR/$(dirname "$rel_path")"
    mkdir -p "$out_thumb_dir"
    mkdir -p "$out_full_dir"
    
    base_name=$(basename "$file" | sed 's/\.[^.]*$//')
    out_thumb_file="$out_thumb_dir/${base_name}.webp"
    out_full_file="$out_full_dir/${base_name}.webp"
    out_color_file="$out_full_dir/${base_name}.color"
    
    if [ -f "$out_thumb_file" ] && [ -f "$out_full_file" ] && [ -f "$out_color_file" ]; then
        echo "Skipping $file, output files already exist"
        continue
    fi
    
    echo "Processing $file"
    
    # Extract the dominant color
    color=$(magick "$file" -resize 1x1\! -format "%[pixel:p{0,0}]" info:-)
    # Convert the color to hex format
    hex_color=$(echo "$color" | sed -E 's/.*\((.*)\)/\1/' | awk -F',' '{printf "#%02x%02x%02x", $1, $2, $3}')
    
    # Save color to a file next to the image
    echo "$hex_color" > "$out_color_file"
    
    echo "Encoding $file to $out_thumb_file and $out_full_file"
    # Encode the image with the specified dimensions and quality
    magick "$file" -resize 600x600\> -strip -auto-orient -quality 60 "$out_thumb_file"
    magick "$file" -resize 3840x3840\> -auto-orient -quality 75 "$out_full_file"
done