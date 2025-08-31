# Device Setup Guide for Swornim Mobile App

## Overview

This guide explains how to configure the app to work with real Android devices instead of the emulator.

## Step 1: Find Your Computer's IP Address

### On Windows:
1. Open Command Prompt
2. Type: `ipconfig`
3. Look for "IPv4 Address" under your active network adapter
4. Note the IP address (e.g., `192.168.1.100`)

### On macOS/Linux:
1. Open Terminal
2. Type: `ifconfig` (macOS/Linux) or `ip addr` (Linux)
3. Look for "inet" followed by your IP address
4. Note the IP address (e.g., `192.168.1.100`)

## Step 2: Update the Configuration

### Option A: Quick Change (Recommended)
1. Open `lib/config/app_config.dart`
2. Find this line:
   ```dart
   static const String _deviceBaseUrl = 'http://192.168.1.100:9009/api/v1'; // Change this to your computer's IP
   ```
3. Replace `192.168.1.100` with your actual IP address
4. Save the file

### Option B: Environment-Based Configuration
The app is already configured to automatically use the correct URL based on the environment:
- **Debug mode**: Uses device URL (your computer's IP)
- **Release mode**: Uses production URL

## Step 3: Ensure Backend is Accessible

### Check Backend Server:
1. Make sure your Node.js backend is running on port 9009
2. Test from your computer: `http://YOUR_IP:9009/api/v1/health`
3. Ensure your firewall allows connections on port 9009

### Firewall Settings (Windows):
1. Open Windows Defender Firewall
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Add your Node.js application or allow port 9009

### Firewall Settings (macOS):
1. Go to System Preferences > Security & Privacy > Firewall
2. Click "Firewall Options"
3. Add your Node.js application

## Step 4: Connect Your Device

### Requirements:
- Your Android device and computer must be on the same WiFi network
- USB debugging enabled on your device
- Device connected via USB or WiFi debugging

### Enable USB Debugging:
1. Go to Settings > About Phone
2. Tap "Build Number" 7 times to enable Developer Options
3. Go to Settings > Developer Options
4. Enable "USB Debugging"

### Connect Device:
1. Connect your device via USB
2. Run: `flutter devices` to verify connection
3. Run: `flutter run` to build and install the app

## Step 5: Test the Connection

### Test API Connection:
1. Open the app on your device
2. Try to register or login
3. Check if the backend responds correctly

### Debug Network Issues:
1. Check the Flutter console for network errors
2. Verify your IP address is correct
3. Test the backend URL in a browser on your device

## Troubleshooting

### Common Issues:

1. **"Connection refused" error:**
   - Check if backend is running
   - Verify IP address is correct
   - Check firewall settings

2. **"Network unreachable" error:**
   - Ensure device and computer are on same network
   - Check WiFi connection
   - Try using computer's IP instead of localhost

3. **"Timeout" error:**
   - Check backend server is responding
   - Verify port 9009 is open
   - Check network connectivity

### Debug Commands:
```bash
# Check if backend is accessible
curl http://YOUR_IP:9009/api/v1/health

# Test from device (if you have curl installed)
curl http://YOUR_IP:9009/api/v1/health

# Check Flutter devices
flutter devices

# Run with verbose logging
flutter run -v
```

## Configuration Files Updated

The following files now use the centralized configuration:

- ✅ `lib/config/app_config.dart` - Central configuration
- ✅ `lib/pages/providers/auth/auth_provider.dart` - Auth endpoints
- ✅ `lib/pages/providers/service_providers/service_provider_manager.dart` - Service provider endpoints
- ✅ `lib/pages/services/simple_image_service.dart` - Image upload endpoints
- ✅ `lib/pages/widgets/common/simple_image_picker.dart` - Image picker endpoints
- ✅ `lib/pages/widgets/common/simple_portfolio_gallery.dart` - Portfolio endpoints
- ✅ `lib/pages/widgets/auth/auth_wrapper.dart` - Auth wrapper endpoints
- ✅ `lib/pages/providers/payments/payment_manager.dart` - Payment endpoints

## Quick Switch Between Emulator and Device

To quickly switch between emulator and device testing:

1. **For Emulator Testing:**
   ```dart
   // In lib/config/app_config.dart
   return _emulatorBaseUrl; // Use 10.0.2.2
   ```

2. **For Device Testing:**
   ```dart
   // In lib/config/app_config.dart
   return _deviceBaseUrl; // Use your computer's IP
   ```

## Production Deployment

When ready for production:

1. Update the production URL in `app_config.dart`:
   ```dart
   static const String _productionBaseUrl = 'https://your-actual-domain.com/api/v1';
   ```

2. Build release version:
   ```bash
   flutter build apk --release
   ```

## Security Notes

- The current setup uses HTTP for development
- For production, always use HTTPS
- Consider using environment variables for sensitive URLs
- Implement proper SSL certificates for production

## Next Steps

1. Update your IP address in `app_config.dart`
2. Test the connection with your device
3. Verify all features work correctly
4. Build and test the release version when ready 