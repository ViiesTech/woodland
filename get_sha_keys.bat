@echo off
echo ========================================
echo Getting SHA-1 and SHA-256 Fingerprints
echo ========================================
echo.

echo DEBUG KEYSTORE:
echo ----------------
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr /i "SHA1 SHA256"

echo.
echo ========================================
echo Copy the SHA-1 and SHA-256 values above
echo and add them to Firebase Console:
echo.
echo 1. Go to Firebase Console
echo 2. Project Settings
echo 3. Your Android App
echo 4. Add Fingerprint
echo 5. Paste SHA-1 and SHA-256
echo ========================================
pause


