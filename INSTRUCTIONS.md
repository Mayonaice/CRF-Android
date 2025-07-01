# CRF App - Running Instructions

## Project Structure

```
crf-and1/
├── lib/
│   ├── main.dart           # Main application entry point
│   ├── screens/
│   │   ├── login_page.dart # Login screen
│   │   └── home_page.dart  # Home screen
│   ├── models/
│   ├── services/
│   └── utils/
├── assets/
│   └── images/             # Store application images here
├── web/
│   ├── index.html          # Main web app entry point
│   ├── run.html            # Simple launcher for direct browser access
│   └── manifest.json       # Web app manifest
└── pubspec.yaml            # Dependencies and app configuration
```

## Running Instructions

### Method 1: Run Using Flutter (Recommended if Flutter is installed)

1. Install Flutter:
   - Download and install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. Enable web support:
   ```
   flutter config --enable-web
   ```

3. Run the app in Edge:
   ```
   cd crf-and1
   flutter run -d edge
   ```

### Method 2: Run Directly in Edge Browser (No Flutter required)

1. Copy the entire `crf-and1` folder to your web server or use a local server
   - You can use tools like [http-server](https://www.npmjs.com/package/http-server) or [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)

2. Navigate to the `web` folder

3. Open `run.html` in Edge browser

4. Click the "Launch CRF Application" button

### Method 3: Build and Deploy to a Web Server

1. Build the Flutter web app:
   ```
   cd crf-and1
   flutter build web
   ```

2. Copy the contents of the `build/web` directory to your web server

3. Access the app through your web server URL

## Important Notes

- The application is designed to run in landscape mode only
- The app connects to the login API at `http://10.10.0.223/LocalCRF/api/CRF/Login`
- Make sure you have network access to the API server for login functionality
- If running directly from browser (Method 2), some features might be limited compared to running with Flutter (Method 1)
- For the best experience, run in fullscreen mode (F11 in most browsers) 