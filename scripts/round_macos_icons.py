#!/usr/bin/env python3

"""
Script to round the corners of macOS app icons
Creates rounded versions of existing square icons for better macOS integration
"""

import os
import sys
import shutil
from PIL import Image, ImageDraw
import argparse

def backup_and_check_original(icon_path, force=False):
    """
    Create a backup of the original icon if it doesn't exist and check if processing is needed.
    
    Args:
        icon_path: Path to the icon file
        force: Force reprocessing even if already processed
        
    Returns:
        tuple: (needs_processing: bool, original_path: str)
    """
    icon_dir = os.path.dirname(icon_path)
    icon_filename = os.path.basename(icon_path)
    original_filename = f"original_{icon_filename}"
    original_path = os.path.join(icon_dir, original_filename)
    
    # If original backup doesn't exist, create it and indicate processing is needed
    if not os.path.exists(original_path):
        shutil.copy2(icon_path, original_path)
        return True, original_path
    
    # If original exists and force is not set, skip processing
    if not force:
        return False, original_path
    
    # Force reprocessing from original
    return True, original_path

def add_safe_area(image, margin_percent: int = 0):
    """
    Add a transparent margin (safe area) around the icon content.

    The original image is scaled down and centered, leaving a transparent
    border of the requested percentage on each side.

    Args:
        image: PIL Image object (expected RGBA)
        margin_percent: Percentage of width/height to keep as transparent
                         margin on each side. Example: 8 means 8% on left,
                         8% on right, etc.

    Returns:
        PIL Image with transparent margins applied.
    """
    if margin_percent <= 0:
        return image

    width, height = image.size

    # Compute margins in pixels on each side
    margin_x = int(width * margin_percent / 100)
    margin_y = int(height * margin_percent / 100)

    # Target inner content size after margins are applied
    target_width = max(1, width - (2 * margin_x))
    target_height = max(1, height - (2 * margin_y))

    # Resize original content to fit inside the safe area
    resized = image.resize((target_width, target_height), Image.LANCZOS)

    # Create transparent canvas and center the resized content
    canvas = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    paste_x = (width - target_width) // 2
    paste_y = (height - target_height) // 2
    canvas.paste(resized, (paste_x, paste_y), resized)

    return canvas

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
    
    # Apply the mask while preserving existing transparency
    output = Image.new('RGBA', image.size, (0, 0, 0, 0))
    
    # If the image has an alpha channel, combine it with our mask
    if image.mode == 'RGBA':
        # Get the existing alpha channel
        _, _, _, existing_alpha = image.split()
        # Combine the existing alpha with our rounded mask
        from PIL import ImageChops
        combined_alpha = ImageChops.multiply(existing_alpha, mask)
        # Paste the RGB channels
        output.paste(image, (0, 0))
        # Apply the combined alpha
        output.putalpha(combined_alpha)
    else:
        # No existing alpha, just use our mask
        output.paste(image, (0, 0))
        output.putalpha(mask)
    
    return output

def process_icon_set(icon_dir, radius_percent=20, margin_percent: int = 0, force=False):
    """
    Process all icons in the macOS icon set
    
    Args:
        icon_dir: Path to the .appiconset directory
        radius_percent: Corner radius as percentage of icon size
    """
    print(f"🎨 Rounding macOS app icons in: {icon_dir}")
    print(f"📐 Corner radius: {radius_percent}%")
    if margin_percent > 0:
        print(f"🧊 Safe area margin: {margin_percent}% on each side")
    
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
    skipped = 0
    
    for icon_file in icon_files:
        icon_path = os.path.join(icon_dir, icon_file)
        
        if not os.path.exists(icon_path):
            print(f"⚠️  {icon_file} not found, skipping...")
            continue
            
        try:
            # Handle backup and get original file
            needs_processing, original_path = backup_and_check_original(icon_path, force)
            
            if not needs_processing:
                print(f"⏭️  {icon_file} already processed, skipping...")
                skipped += 1
                continue
            
            # Open the original image (not the potentially modified one)
            with Image.open(original_path) as img:
                # Convert to RGBA if not already
                if img.mode != 'RGBA':
                    img = img.convert('RGBA')
                
                # Apply transparent safe-area margin first
                img_with_margin = add_safe_area(img, margin_percent)
                # Then apply rounded corners to final canvas
                rounded_img = round_corners(img_with_margin, radius_percent)
                
                # Save to the main icon file
                rounded_img.save(icon_path, 'PNG')
                
                print(f"✅ Processed {icon_file} ({img.size[0]}x{img.size[1]}) from original")
                processed += 1
                
        except Exception as e:
            print(f"❌ Error processing {icon_file}: {e}")
    
    if processed > 0:
        print(f"\n🎉 Successfully processed {processed} icon files!")
    elif skipped > 0:
        print(f"\n✅ All {skipped} icon files already processed!")
    else:
        print(f"\n⚠️  No icon files found to process.")
        return False
    
    return True

def main():
    parser = argparse.ArgumentParser(description='Round corners of macOS app icons')
    parser.add_argument('--radius', type=int, default=25, 
                       help='Corner radius as percentage (default: 25)')
    parser.add_argument('--margin', type=int, default=8,
                       help='Safe area margin as percentage on each side (default: 8)')
    parser.add_argument('--icon-dir', type=str,
                       help='Path to .appiconset directory')
    parser.add_argument('--force', action='store_true',
                       help='Force reprocessing even if already processed')
    
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
    success = process_icon_set(args.icon_dir, args.radius, args.margin, args.force)
    
    if success:
        print("\n📱 macOS icons now have rounded corners!")
        print("🔄 You may need to clean and rebuild your project to see changes.")
    else:
        print("\n❌ No icons were processed successfully.")
        sys.exit(1)

if __name__ == '__main__':
    main()
