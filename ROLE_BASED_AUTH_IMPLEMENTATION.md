# Role-Based Authentication & Responsive Layout Implementation

## 📋 Overview

Implementasi sistem authentication berbasis role dan responsive layout untuk aplikasi CRF Android. Sistem ini memungkinkan tampilan menu yang berbeda berdasarkan role user dan mengatasi masalah overflow di landscape mode.

## 🎯 Features Implemented

### 1. **Role-Based Authentication**
- ✅ Support untuk 3 role utama: `crf_opr`, `crf_konsol`, `crf_tl`
- ✅ Menu filtering berdasarkan role user
- ✅ Session management dengan role information
- ✅ Branch name dan group ID disimpan di session

### 2. **Responsive Layout Fixes**
- ✅ Overflow issues fixed di landscape mode
- ✅ Dynamic font sizes berdasarkan orientation
- ✅ Compact spacing di landscape mode
- ✅ Preserved design tanpa mengubah layout structure

## 🏗️ Architecture

### **AuthService Enhancements**

#### New Methods Added:
```dart
// Get user role from stored data
Future<String?> getUserRole()

// Check if user has specific role
Future<bool> hasRole(String requiredRole)

// Check if user has any of the specified roles
Future<bool> hasAnyRole(List<String> requiredRoles)

// Get available menu items based on user role
Future<List<String>> getAvailableMenus()
```

#### Enhanced Login Method:
```dart
Future<Map<String, dynamic>> login(String username, String password, String noMeja, {String? selectedBranch})
```

**Features:**
- Role detection dari multiple field names (`role`, `Role`, `userRole`, `position`, dll)
- Enhanced user data dengan standardized field names
- Automatic branch code mapping
- Login timestamp tracking

### **Role-Based Menu System**

#### Role Definitions:
```dart
// CRF_OPR (Operator)
['prepare_mode', 'return_mode', 'device_info', 'settings_opr']

// CRF_KONSOL (Konsol)
['dashboard_konsol', 'monitoring', 'reports_konsol', 'settings_konsol']

// CRF_TL (Team Leader)
['dashboard_tl', 'team_management', 'approvals', 'reports_tl', 'settings_tl']
```

## 🎨 UI Enhancements

### **HomePage Role-Based Menus**

#### Dynamic Menu Display:
- **CRF_OPR**: Prepare Mode, Return Mode, Device Info, Settings
- **CRF_KONSOL**: Dashboard Konsol, Monitoring ATM, Reports, Settings
- **CRF_TL**: Dashboard TL, Team Management, Approvals, Reports

#### Role-Specific Styling:
```dart
// Role-specific colors
crf_opr: Colors.green
crf_konsol: Colors.blue
crf_tl: Colors.orange

// Role-specific greetings
crf_opr: "Dashboard Operator CRF"
crf_konsol: "Dashboard Konsol CRF"
crf_tl: "Dashboard Team Leader"
```

### **Responsive Layout Fixes**

#### Return Page Improvements:
```dart
// Dynamic sizing based on orientation
final isLandscape = size.width > size.height;

// Reduced heights and paddings in landscape
toolbarHeight: isLandscape ? 50 : 60
fontSize: isLandscape ? 16 : 20
padding: EdgeInsets.all(isLandscape ? 8 : 12)
```

#### Key Responsive Features:
- ✅ **Flexible AppBar**: Reduced height dan font sizes di landscape
- ✅ **Overflow Text**: `TextOverflow.ellipsis` untuk text yang panjang
- ✅ **Compact Spacing**: Reduced margins dan paddings
- ✅ **Flexible Layout**: Menggunakan `Flexible` instead of `Expanded`
- ✅ **Dynamic Icons**: Smaller icon sizes di landscape mode

## 🔧 Implementation Details

### **Session Data Structure**

Enhanced user data yang disimpan di session:
```json
{
  "role": "crf_opr",
  "branchCode": "001", 
  "branchName": "JAKARTA-CIDENG",
  "tableCode": "010101",
  "warehouseCode": "Cideng",
  "loginTimestamp": "2024-01-01T12:00:00.000Z",
  "name": "Lorenzo Putra",
  "nik": "9190812021"
}
```

### **Menu Availability Check**

Sistem checking menu berdasarkan role:
```dart
bool _isMenuAvailable(String menuKey) {
  return _availableMenus.contains(menuKey);
}

// Usage in UI
if (_isMenuAvailable('prepare_mode'))
  _buildMainMenuButton(...)
```

### **Role-Based Route Guards**

Future implementation untuk route protection:
```dart
// Middleware untuk protect routes berdasarkan role
bool canAccessRoute(String route, String userRole) {
  final roleRoutes = {
    'crf_opr': ['/prepare_mode', '/return_page', '/device_info'],
    'crf_konsol': ['/dashboard_konsol', '/monitoring'],
    'crf_tl': ['/dashboard_tl', '/team_management'],
  };
  
  return roleRoutes[userRole]?.contains(route) ?? false;
}
```

## 🧪 Testing

### **Role Testing Scenarios**

1. **Login sebagai CRF_OPR**
   - Menu: Prepare Mode, Return Mode, Device Info
   - Color theme: Green
   - Greeting: "Dashboard Operator CRF"

2. **Login sebagai CRF_KONSOL**
   - Menu: Dashboard Konsol, Monitoring ATM
   - Color theme: Blue
   - Greeting: "Dashboard Konsol CRF"

3. **Login sebagai CRF_TL**
   - Menu: Dashboard TL, Team Management
   - Color theme: Orange
   - Greeting: "Dashboard Team Leader"

### **Responsive Testing**

1. **Portrait Mode**
   - Normal font sizes dan spacing
   - Full AppBar height (60px)
   - Standard padding (12px)

2. **Landscape Mode**
   - Reduced font sizes
   - Compact AppBar height (50px)
   - Reduced padding (8px)
   - No overflow issues

## 🎯 Benefits

### **User Experience**
- ✅ **Personalized Interface**: Menu sesuai dengan role user
- ✅ **Responsive Design**: Optimal viewing di semua orientations
- ✅ **Clear Visual Hierarchy**: Role-specific colors dan greetings
- ✅ **No Overflow Issues**: Text selalu terbaca dengan baik

### **Developer Experience**
- ✅ **Maintainable Code**: Clear separation of concerns
- ✅ **Extensible Architecture**: Easy to add new roles
- ✅ **Type Safety**: Proper type checking untuk roles
- ✅ **Debugging Support**: Enhanced logging untuk troubleshooting

### **Security**
- ✅ **Role-Based Access Control**: Menu filtering berdasarkan permissions
- ✅ **Session Management**: Secure storage of role information
- ✅ **Future-Ready**: Ready untuk route-level protection

## 🚀 Next Steps

### **Phase 2 - Menu Implementation**
- [ ] Implement actual screens untuk CRF_KONSOL dan CRF_TL
- [ ] Add route guards untuk protect unauthorized access
- [ ] Implement role-specific data filtering

### **Phase 3 - Advanced Features**
- [ ] Role hierarchy system (TL dapat access OPR menus)
- [ ] Permission-based feature toggling
- [ ] Audit logging untuk role-based actions

## 📝 Notes

- Design dan flow existing tidak berubah
- Backward compatibility maintained untuk existing users
- Performance optimized dengan conditional rendering
- Ready untuk future enhancements tanpa breaking changes

## 🔍 Debug Commands

```bash
# Check user role
print('🎯 HOME: User role: $_userRole');

# Check available menus
print('🎯 HOME: Available menus: $_availableMenus');

# Check login data
print('🚀 DEBUG LOGIN: Enhanced user data: ${json.encode(enhancedUserData)}');
```

---

**Implementation Status:** ✅ **COMPLETE**  
**Testing Status:** ✅ **READY FOR TESTING**  
**Documentation Status:** ✅ **DOCUMENTED** 