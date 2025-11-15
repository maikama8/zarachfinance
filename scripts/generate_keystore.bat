@echo off
REM Script to generate Android keystore for app signing (Windows version)
REM This script should be run once to create the keystore file

echo ==========================================
echo Android Keystore Generation Script
echo ==========================================
echo.
echo This script will generate a keystore for signing your Android app.
echo Please provide the following information:
echo.

REM Prompt for keystore details
set /p KEYSTORE_PASSWORD="Enter keystore password (min 6 characters): "
set /p KEYSTORE_PASSWORD_CONFIRM="Confirm keystore password: "

if not "%KEYSTORE_PASSWORD%"=="%KEYSTORE_PASSWORD_CONFIRM%" (
    echo Error: Passwords do not match!
    exit /b 1
)

set /p KEY_ALIAS="Enter key alias (e.g., device-admin-key): "
set /p KEY_PASSWORD="Enter key password (min 6 characters): "
set /p KEY_PASSWORD_CONFIRM="Confirm key password: "

if not "%KEY_PASSWORD%"=="%KEY_PASSWORD_CONFIRM%" (
    echo Error: Key passwords do not match!
    exit /b 1
)

set /p DNAME_CN="Enter your name: "
set /p DNAME_OU="Enter organizational unit (e.g., Development): "
set /p DNAME_O="Enter organization name (e.g., Finance Store): "
set /p DNAME_L="Enter city: "
set /p DNAME_ST="Enter state/province: "
set /p DNAME_C="Enter country code (e.g., NG): "

REM Create android directory if it doesn't exist
if not exist android mkdir android

REM Generate keystore
echo.
echo Generating keystore...
keytool -genkey -v -keystore android\app-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias %KEY_ALIAS% -storepass %KEYSTORE_PASSWORD% -keypass %KEY_PASSWORD% -dname "CN=%DNAME_CN%, OU=%DNAME_OU%, O=%DNAME_O%, L=%DNAME_L%, ST=%DNAME_ST%, C=%DNAME_C%"

if %errorlevel% equ 0 (
    echo.
    echo ==========================================
    echo Keystore generated successfully!
    echo ==========================================
    echo.
    echo Keystore location: android\app-release-key.jks
    echo.
    echo Creating key.properties file...
    
    REM Create key.properties file
    (
        echo storePassword=%KEYSTORE_PASSWORD%
        echo keyPassword=%KEY_PASSWORD%
        echo keyAlias=%KEY_ALIAS%
        echo storeFile=app-release-key.jks
    ) > android\key.properties
    
    echo.
    echo key.properties file created at: android\key.properties
    echo.
    echo IMPORTANT SECURITY NOTES:
    echo 1. Add 'android/key.properties' to .gitignore
    echo 2. Add 'android/app-release-key.jks' to .gitignore
    echo 3. Store these files securely and create backups
    echo 4. Never commit these files to version control
    echo.
    echo Next steps:
    echo 1. Update android/app/build.gradle.kts to use the signing config
    echo 2. Run: flutter build apk --release
    echo.
) else (
    echo.
    echo Error: Failed to generate keystore
    exit /b 1
)
