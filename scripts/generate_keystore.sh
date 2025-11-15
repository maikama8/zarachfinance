#!/bin/bash

# Script to generate Android keystore for app signing
# This script should be run once to create the keystore file

echo "=========================================="
echo "Android Keystore Generation Script"
echo "=========================================="
echo ""
echo "This script will generate a keystore for signing your Android app."
echo "Please provide the following information:"
echo ""

# Prompt for keystore details
read -p "Enter keystore password (min 6 characters): " KEYSTORE_PASSWORD
read -p "Confirm keystore password: " KEYSTORE_PASSWORD_CONFIRM

if [ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]; then
    echo "Error: Passwords do not match!"
    exit 1
fi

read -p "Enter key alias (e.g., device-admin-key): " KEY_ALIAS
read -p "Enter key password (min 6 characters): " KEY_PASSWORD
read -p "Confirm key password: " KEY_PASSWORD_CONFIRM

if [ "$KEY_PASSWORD" != "$KEY_PASSWORD_CONFIRM" ]; then
    echo "Error: Key passwords do not match!"
    exit 1
fi

read -p "Enter your name: " DNAME_CN
read -p "Enter organizational unit (e.g., Development): " DNAME_OU
read -p "Enter organization name (e.g., Finance Store): " DNAME_O
read -p "Enter city: " DNAME_L
read -p "Enter state/province: " DNAME_ST
read -p "Enter country code (e.g., NG): " DNAME_C

# Create android directory if it doesn't exist
mkdir -p android

# Generate keystore
echo ""
echo "Generating keystore..."
keytool -genkey -v \
    -keystore android/app-release-key.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=$DNAME_CN, OU=$DNAME_OU, O=$DNAME_O, L=$DNAME_L, ST=$DNAME_ST, C=$DNAME_C"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Keystore generated successfully!"
    echo "=========================================="
    echo ""
    echo "Keystore location: android/app-release-key.jks"
    echo ""
    echo "Creating key.properties file..."
    
    # Create key.properties file
    cat > android/key.properties << EOF
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=app-release-key.jks
EOF
    
    echo ""
    echo "key.properties file created at: android/key.properties"
    echo ""
    echo "IMPORTANT SECURITY NOTES:"
    echo "1. Add 'android/key.properties' to .gitignore"
    echo "2. Add 'android/app-release-key.jks' to .gitignore"
    echo "3. Store these files securely and create backups"
    echo "4. Never commit these files to version control"
    echo ""
    echo "Next steps:"
    echo "1. Update android/app/build.gradle.kts to use the signing config"
    echo "2. Run: flutter build apk --release"
    echo ""
else
    echo ""
    echo "Error: Failed to generate keystore"
    exit 1
fi
