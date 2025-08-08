#!/usr/bin/env python3

"""
Script to round the corners of macOS app icons
Creates rounded versions of existing square icons for better macOS integration
"""

import os
import sys
from PIL import Image, ImageDraw
import argparse

def round_corners(image, radius_percent=20):
    """
    Round the corners of an image
    
    Args:
        image: PIL Image object
        radius_percent: Percentage of the image size to use as corner radius
    
    Returns:
        PIL Image with rounded corners
    """
    # Calculate radius based on image size
    size = min(image.size)
    radius = int(size * radius_percent / 100)
    
    # Create a mask for rounded corners
    mask = Image.new('L', image.size, 0)
    draw = ImageDraw.Draw(mask)
    
    # Draw rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), image.size], 
        radius=radius, 
        fill=255
    )
    
    # Apply the mask
    output = Image.new('RGBA', image.size, (0, 0, 0, 0))
    output.paste(image, (0, 0))
    output.putalpha(mask)
    
    return output

def process_icon_set(icon_dir, radius_percent=20):
    """
    Process all icons in the macOS icon set
    
    Args:
        icon_dir: Path to the .appiconset directory
        radius_percent: Corner radius as percentage of icon size
    """
    print(f"🎨 Rounding macOS app icons in: {icon_dir}")
    print(f"📐 Corner radius: {radius_percent}%")
    
    # Icon files to process
    icon_files = [
        'app_icon_16.png',
        'app_icon_32.png', 
        'app_icon_64.png',
        'app_icon_128.png',
        'app_icon_256.png',
        'app_icon_512.png',
        'app_icon_1024.png'
    ]
    
    processed = 0
    
    for icon_file in icon_files:
        icon_path = os.path.join(icon_dir, icon_file)
        
        if not os.path.exists(icon_path):
            print(f"⚠️  {icon_file} not found, skipping...")
            continue
            
        try:
            # Open the original image
            with Image.open(icon_path) as img:
                # Convert to RGBA if not already
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # Round the corners
                rounded_img = round_corners(img, radius_percent)
                
                # Save back to the same file
                rounded_img.save(icon_path, 'PNG')
                
                print(f"✅ Processed {icon_file} ({img.size[0]}x{img.size[1]})")
                processed += 1
                
        except Exception as e:
            print(f"❌ Error processing {icon_file}: {e}")
    
    print(f"\n🎉 Successfully processed {processed} icon files!")
    return processed > 0

def main():
    parser = argparse.ArgumentParser(description='Round corners of macOS app icons')
    parser.add_argument('--radius', type=int, default=25, 
                       help='Corner radius as percentage (default: 20)')
    parser.add_argument('--icon-dir', type=str,
                       help='Path to .appiconset directory')
    
    args = parser.parse_args()
    
    # Default icon directory
    if not args.icon_dir:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.dirname(script_dir)
        args.icon_dir = os.path.join(
            project_root, 
            'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset'
        )
    
    # Check if directory exists
    if not os.path.exists(args.icon_dir):
        print(f"❌ Icon directory not found: {args.icon_dir}")
        sys.exit(1)
    
    # Check for PIL/Pillow
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("❌ Pillow library not found. Install with: pip3 install Pillow")
        sys.exit(1)
    
    # Process the icons
    success = process_icon_set(args.icon_dir, args.radius)
    
    if success:
        print("\n📱 macOS icons now have rounded corners!")
        print("🔄 You may need to clean and rebuild your project to see changes.")
    else:
        print("\n❌ No icons were processed successfully.")
        sys.exit(1)

if __name__ == '__main__':
    main()
