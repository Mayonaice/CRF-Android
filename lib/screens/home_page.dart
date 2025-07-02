import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'prepare_mode_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // Calculate adaptive sizes based on screen width
    final avatarRadius = isSmallScreen ? 25.0 : 40.0;
    final headerPadding = isSmallScreen 
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8) 
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    final statusBoxWidth = isSmallScreen ? (screenSize.width * 0.35) : 250.0;
    
    return Scaffold(
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        // Use new background image with responsive fit
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg-choosemenu.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Column(
          children: [
            // Top section with user info and dashboard
            Container(
              padding: headerPadding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // Slightly transparent for better design
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // User info with photo - Flexible for small screens
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // User photo - using PersonIcon.png
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.blue[100],
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/PersonIcon.png',
                              width: avatarRadius * 1.8,
                              height: avatarRadius * 1.8,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: avatarRadius * 1.2,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 15),
                        // User name and location
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Selamat Datang !',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 15,
                                  vertical: isSmallScreen ? 3 : 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Lorenzo Putra',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 16,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 5),
                              Text(
                                'JAKARTA - CIDENG',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  const Spacer(), // Add extra spacer to push dashboard more to the right
                  
                  // Dashboard Trip - Flexible for small screens
                  Flexible(
                    flex: isSmallScreen ? 3 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dashboard Trip button
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 15 : 30,
                            vertical: isSmallScreen ? 6 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Dashboard Trip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 5 : 10),
                        
                        // Trip stats in a scrollable row if needed
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Belum Prepare
                              _buildStatusBox(
                                title: 'Belum Prepare',
                                count: '1.000',
                                width: statusBoxWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                              
                              SizedBox(width: isSmallScreen ? 10 : 20),
                              
                              // Belum Return
                              _buildStatusBox(
                                title: 'Belum Return',
                                count: '1.000',
                                width: statusBoxWidth,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: isSmallScreen ? 10 : 20),
                  
                  // Clock icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: isSmallScreen ? 1 : 2),
                    ),
                    child: CircleAvatar(
                      radius: isSmallScreen ? 14 : 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.access_time,
                        color: Colors.black,
                        size: isSmallScreen ? 20 : 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menu title
                          Padding(
                            padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 15),
                            child: Text(
                              'Menu Utama :',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text to stand out on background
                                shadows: [
                                  Shadow(
                                    blurRadius: 2.0,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: const Offset(1.0, 1.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Menu items aligned to the left (per design requirement)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Add extra space at the start to balance the layout
                              SizedBox(width: isSmallScreen ? 20 : 40),
                              
                              // Prepare Mode button with custom icon
                              _buildMainMenuButton(
                                context: context,
                                title: 'Prepare\nMode',
                                iconAsset: 'assets/images/PrepareModeIcon.png',
                                route: '/prepare_mode',
                                isSmallScreen: isSmallScreen,
                              ),
                              
                              SizedBox(width: isSmallScreen ? 20 : 40),
                              
                              // Return Mode button with custom icon
                              _buildMainMenuButton(
                                context: context,
                                title: 'Return\nMode',
                                iconAsset: 'assets/images/ReturnModeIcon.png',
                                route: '/return_mode',
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                          
                          // Additional menu section
                          Padding(
                            padding: EdgeInsets.only(
                              top: isSmallScreen ? 15 : 30, 
                              bottom: isSmallScreen ? 8 : 15
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Menu Lain :',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white, // White text to stand out on background
                                    shadows: [
                                      Shadow(
                                        blurRadius: 2.0,
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(1.0, 1.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Additional menu items with custom icons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildSmallMenuButton(
                                iconAsset: 'assets/images/PhoneIcon.png',
                                isSmallScreen: isSmallScreen,
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 20),
                              _buildSmallMenuButton(
                                iconAsset: 'assets/images/PersonIcon.png',
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Footer
            Container(
              color: Colors.white.withOpacity(0.95), // Slightly transparent
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 5 : 10,
                horizontal: isSmallScreen ? 10 : 20,
              ),
              child: Row(
                children: [
                  // Left side - version info
                  Row(
                    children: [
                      Text(
                        'CASH REPLENISH FORM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ver. 0.0.1',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Right side - logos
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/advantage_logo.png',
                        height: isSmallScreen ? 30 : 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: isSmallScreen ? 30 : 40,
                            width: isSmallScreen ? 80 : 120,
                            color: Colors.transparent,
                            child: Center(child: Text('ADVANTAGE')),
                          );
                        },
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 20),
                      Image.asset(
                        'assets/images/crf_logo.png',
                        height: isSmallScreen ? 30 : 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: isSmallScreen ? 30 : 40,
                            width: isSmallScreen ? 40 : 60,
                            color: Colors.transparent,
                            child: Center(child: Text('CRF')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build status boxes
  Widget _buildStatusBox({
    required String title,
    required String count,
    required double width,
    required bool isSmallScreen,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(isSmallScreen ? 5 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: isSmallScreen ? 14 : 24),
              SizedBox(width: isSmallScreen ? 5 : 10),
              Text(
                count,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: isSmallScreen ? 3 : 5),
              Text(
                'Trip',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper method to build main menu buttons with custom icons
  Widget _buildMainMenuButton({
    required BuildContext context,
    required String title,
    required String iconAsset,
    required String route,
    required bool isSmallScreen,
  }) {
    // Calculate size based on screen size, but keep relatively fixed proportions
    final size = isSmallScreen ? 120.0 : 180.0;
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(route);
      },
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                iconAsset,
                width: size * 0.6,
                height: size * 0.6,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    size: size * 0.4,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text to stand out on background
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.7),
                  offset: const Offset(1.0, 1.0),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Helper method to build small menu buttons with custom icons
  Widget _buildSmallMenuButton({
    required String iconAsset,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 50 : 70,
      height: isSmallScreen ? 50 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          iconAsset,
          width: isSmallScreen ? 30 : 40,
          height: isSmallScreen ? 30 : 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.error,
              size: isSmallScreen ? 25 : 35,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }
}