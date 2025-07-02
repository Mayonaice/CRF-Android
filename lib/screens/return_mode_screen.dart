import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReturnModePage extends StatefulWidget {
  const ReturnModePage({Key? key}) : super(key: key);

  @override
  State<ReturnModePage> createState() => _ReturnModePageState();
}

class _ReturnModePageState extends State<ReturnModePage> {
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
    
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header section with back button, title, and user info
            _buildHeader(context, isSmallScreen),
            
            // Main content area
            Expanded(
              child: Center(
                child: Text(
                  'Return Mode - Under Development',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Footer
            _buildFooter(isSmallScreen),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0, 
        vertical: isSmallScreen ? 4.0 : 8.0
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back, 
              color: Colors.red, 
              size: isSmallScreen ? 24 : 30
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Title
          Text(
            'Return Mode',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Location and user info - For small screens, show minimal info
          if (isSmallScreen)
            // Compact header for small screens
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'JAKARTA-CIDENG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CRF_OPR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Full header for larger screens
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'JAKARTA-CIDENG',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Meja : 010101',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CRF_OPR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          SizedBox(width: isSmallScreen ? 8 : 16),
          
          // User avatar and info - Simplified for small screens
          if (isSmallScreen)
            // Just show avatar for small screens
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const AssetImage('assets/images/user.jpg'),
              onBackgroundImageError: (exception, stackTrace) {},
            )
          else
            // Full user info for larger screens
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: const AssetImage('assets/images/user.jpg'),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lorenzo Putra',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '9180812021',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildFooter(bool isSmallScreen) {
    return Container(
      color: Colors.white,
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
    );
  }
} 