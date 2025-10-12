#!/usr/bin/env python3

import os
from PIL import Image

def generate_app_icons():
    # Source image path
    source_path = "/Users/simonas/envs/Finally Done/tools/icon.png"
    
    # iOS app icon sizes (in pixels)
    icon_sizes = {
        # App Store
        "AppStore": 1024,
        
        # iPhone
        "iPhone-20@2x": 40,    # iPhone Settings
        "iPhone-20@3x": 60,    # iPhone Settings
        "iPhone-29@2x": 58,    # iPhone Settings
        "iPhone-29@3x": 87,    # iPhone Settings
        "iPhone-40@2x": 80,    # iPhone Spotlight
        "iPhone-40@3x": 120,   # iPhone Spotlight
        "iPhone-60@2x": 120,   # iPhone App
        "iPhone-60@3x": 180,   # iPhone App
        
        # iPad
        "iPad-20": 20,         # iPad Settings
        "iPad-20@2x": 40,      # iPad Settings
        "iPad-29": 29,         # iPad Settings
        "iPad-29@2x": 58,      # iPad Settings
        "iPad-40": 40,         # iPad Spotlight
        "iPad-40@2x": 80,      # iPad Spotlight
        "iPad-76": 76,         # iPad App
        "iPad-76@2x": 152,     # iPad App
        "iPad-83.5@2x": 167,   # iPad Pro App
    }
    
    # Load the source image
    try:
        source_image = Image.open(source_path)
        print(f"✅ Loaded source image: {source_image.size}")
    except Exception as e:
        print(f"❌ Error loading source image: {e}")
        return
    
    # Create output directory
    output_dir = "/Users/simonas/envs/Finally Done/app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate all icon sizes
    generated_files = []
    
    for name, size in icon_sizes.items():
        try:
            # Resize the image
            resized = source_image.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save the icon
            filename = f"{name}.png"
            filepath = os.path.join(output_dir, filename)
            resized.save(filepath, "PNG")
            
            generated_files.append((name, size, filename))
            print(f"✅ Generated {filename} ({size}x{size})")
            
        except Exception as e:
            print(f"❌ Error generating {name}: {e}")
    
    # Create Contents.json for Xcode
    contents_json = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    # Add image entries for Contents.json
    for name, size, filename in generated_files:
        if "iPhone" in name:
            idiom = "iphone"
        elif "iPad" in name:
            idiom = "ipad"
        elif "AppStore" in name:
            idiom = "ios-marketing"
        else:
            idiom = "universal"
        
        scale = "1x"
        if "@2x" in name:
            scale = "2x"
        elif "@3x" in name:
            scale = "3x"
        
        image_entry = {
            "filename": filename,
            "idiom": idiom,
            "scale": scale,
            "size": f"{size}x{size}"
        }
        
        contents_json["images"].append(image_entry)
    
    # Save Contents.json
    import json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents_json, f, indent=2)
    
    print(f"✅ Generated {len(generated_files)} app icons")
    print(f"✅ Created Contents.json")
    print(f"📁 Icons saved to: {output_dir}")
    print("\n🎉 App icons are ready! You can now build and run your app.")

if __name__ == "__main__":
    generate_app_icons()
