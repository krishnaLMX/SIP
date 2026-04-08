import json
import os
import re
import shutil

# Configuration
CONFIG_FILE = "release_config.json"
GRADLE_PATH = "android/app/build.gradle.kts"
MANIFEST_PATH = "android/app/src/main/AndroidManifest.xml"
INFOPLIST_PATH = "ios/Runner/Info.plist"
PBXPROJ_PATH = "ios/Runner.xcodeproj/project.pbxproj"
KOTLIN_BASE_PATH = "android/app/src/main/kotlin"

def load_config():
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def update_file(path, pattern, replacement):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = re.sub(pattern, replacement, content)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated: {path}")

def update_android(config):
    # 1. Update build.gradle.kts
    update_file(GRADLE_PATH, r'namespace = ".*"', f'namespace = "{config["bundle_id"]}"')
    update_file(GRADLE_PATH, r'applicationId = ".*"', f'applicationId = "{config["bundle_id"]}"')
    
    # 2. Update AndroidManifest.xml
    update_file(MANIFEST_PATH, r'android:label=".*"', f'android:label="{config["app_name"]}"')

def update_kotlin(config):
    # Find the current namespace from Gradle file
    with open(GRADLE_PATH, 'r') as f:
        match = re.search(r'namespace = "(.*)"', f.read())
    
    if match:
        old_bundle_id = match.group(1)
        old_path = os.path.join(KOTLIN_BASE_PATH, old_bundle_id.replace('.', '/'))
        new_path = os.path.join(KOTLIN_BASE_PATH, config['bundle_id'].replace('.', '/'))
        
        # Prepare target directory
        if not os.path.exists(new_path):
            os.makedirs(new_path)
        
        # Move MainActivity.kt if it's in the old path
        main_activity_old = os.path.join(old_path, "MainActivity.kt")
        main_activity_new = os.path.join(new_path, "MainActivity.kt")
        
        if os.path.exists(main_activity_old) and main_activity_old != main_activity_new:
            # Update package name inside the file first
            update_file(main_activity_old, r'package .*', f'package {config["bundle_id"]}')
            shutil.move(main_activity_old, main_activity_new)
            print(f"Moved MainActivity to: {main_activity_new}")
            
            # Clean up old empty directories (recursive)
            try:
                os.removedirs(old_path)
            except OSError:
                pass # Folders were not empty or already gone

def update_ios(config):
    # 1. Update Info.plist
    update_file(INFOPLIST_PATH, r'<key>CFBundleDisplayName</key>\n\t<string>.*</string>', 
                f'<key>CFBundleDisplayName</key>\n\t<string>{config["app_name"]}</string>')
    update_file(INFOPLIST_PATH, r'<key>CFBundleName</key>\n\t<string>.*</string>', 
                f'<key>CFBundleName</key>\n\t<string>{config["app_name"]}</string>')
    
    # 2. Update project.pbxproj
    update_file(PBXPROJ_PATH, r'PRODUCT_BUNDLE_IDENTIFIER = .*', 
                f'PRODUCT_BUNDLE_IDENTIFIER = {config["bundle_id"]};')

def main():
    if not os.path.exists(CONFIG_FILE):
        print("Error: release_config.json not found!")
        return

    config = load_config()
    print(f"Updating app information to: {config['app_name']} ({config['bundle_id']})...")
    
    # Run updates
    # Note: Kotlin move must happen AFTER reading the current state but BEFORE final gradle update
    # for simplicity, we call them in order.
    update_kotlin(config)
    update_android(config)
    update_ios(config)
    
    print("\n[SUCCESS] Release configuration synchronized app-wide.")

if __name__ == "__main__":
    main()
