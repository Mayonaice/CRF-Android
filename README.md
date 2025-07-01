# CRF (Cash Replenish Form) Android Application

A Flutter application for managing Cash Replenish Forms in Android devices. This application is designed to run in landscape mode and can be run on both web and Android devices.

## Features

- Login with User ID, Password, and Table Number
- Dashboard with trip status information
- Prepare Mode and Return Mode functionality
- Responsive UI designed for landscape orientation

## How to Run in Edge Browser (Web)

1. **Install Flutter:**
   - Download and install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. **Enable Flutter Web:**
   ```
   flutter channel stable
   flutter upgrade
   flutter config --enable-web
   ```

3. **Run the Application:**
   - Navigate to the project directory:
     ```
     cd crf-and1
     ```
   - Run the application in Chrome or Edge:
     ```
     flutter run -d edge
     ```
   - Or build the application for web deployment:
     ```
     flutter build web
     ```
     Then deploy the contents of the `build/web` directory to a web server.

4. **Access the Application:**
   - The application will open automatically in the Edge browser when using `flutter run -d edge`
   - Or access it via the URL provided by your web server if you deployed it

## API Integration

The application is connected to the following API:
- Login API: `http://10.10.0.223/LocalCRF/api/CRF/Login`
- Parameters:
  - username: User ID
  - password: Password
  - noMeja: Table Number

## Notes

- The application is designed to run in landscape orientation only
- For the best experience, use a device with a display resolution of 1280x720 or higher
- Make sure to have network access to the API server (10.10.0.223) for login functionality 