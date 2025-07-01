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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFAED4DC), // Light blue background
        ),
        child: Column(
          children: [
            // Top section with user info and dashboard
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // User info with photo
                  Row(
                    children: [
                      // User photo
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/user.jpg'),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback if image doesn't load
                        },
                        child: Container(),
                      ),
                      const SizedBox(width: 15),
                      // User name and location
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang !',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Lorenzo Putra',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'JAKARTA - CIDENG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Dashboard Trip
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dashboard Trip button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Dashboard Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Trip stats
                      Row(
                        children: [
                          // Belum Prepare
                          Container(
                            width: 250,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Belum Prepare',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bar_chart),
                                    const SizedBox(width: 10),
                                    Text(
                                      '1.000',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Trip',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Belum Return
                          Container(
                            width: 250,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Belum Return',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bar_chart),
                                    const SizedBox(width: 10),
                                    Text(
                                      '1.000',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Text(
                                      'Trip',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Clock icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.access_time,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu Utama text
                    const Text(
                      'Menu Utama :',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Main menu options
                    Row(
                      children: [
                        // Prepare Mode - ENLARGED
                        _buildMenuOption(
                          icon: Icons.checklist,
                          label: 'Prepare\nMode',
                          iconColor: Colors.teal,
                          onTap: () {
                            // Navigate to prepare mode screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrepareModePage(),
                              ),
                            );
                          },
                          width: 180, // Increased width
                          height: 180, // Increased height
                          iconSize: 80, // Increased icon size
                        ),
                        
                        const SizedBox(width: 20),
                        
                        // Return Mode - ENLARGED
                        _buildMenuOption(
                          icon: Icons.currency_exchange,
                          label: 'Return\nMode',
                          iconColor: Colors.teal,
                          onTap: () {
                            // Handle return mode tap
                          },
                          width: 180, // Increased width
                          height: 180, // Increased height
                          iconSize: 80, // Increased icon size
                        ),
                        
                        const Spacer(),
                        
                        // Menu Lain section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menu Lain :',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Mobile phone menu
                                _buildSmallMenuOption(
                                  icon: Icons.phone_android,
                                  onTap: () {
                                    // Handle mobile option tap
                                  },
                                ),
                                
                                const SizedBox(width: 15),
                                
                                // User menu
                                _buildSmallMenuOption(
                                  icon: Icons.person,
                                  onTap: () {
                                    // Handle user option tap
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with version info and logos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
              ),
              child: Row(
                children: [
                  // Version text
                  const Text(
                    'CASH REPLENISH FORM   ver. 0.0.1',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Logos
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 40,
                            width: 100,
                            child: Placeholder(),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/crf_logo.png',
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            height: 40,
                            width: 100,
                            child: Placeholder(),
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
  
  // Helper method to build main menu options with customizable size
  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
    double width = 120,
    double height = 120,
    double iconSize = 60,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18, // Increased font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build small menu options
  Widget _buildSmallMenuOption({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 30,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}