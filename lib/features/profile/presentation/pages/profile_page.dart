import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app_assets/app_assets.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, bool> _settings;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carBrandController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settings = {
      'pushNotifications': true,
      'locationServices': true,
      'darkMode': false,
    };
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId != null) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final userData = await firestoreService.getUserData(userId);
      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _carBrandController.text = userData['car']?['brand'] ?? '';
          _carModelController.text = userData['car']?['model'] ?? '';

          // Load settings
          _settings = Map<String, bool>.from(userData['settings'] ?? _settings);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.updateUserData({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'car': {
            'brand': _carBrandController.text,
            'model': _carModelController.text,
          },
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Profile information saved successfully'),
                ],
              ),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Error saving profile. Please try again.'),
                ],
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _saveSettings(String key, bool value) async {
    setState(() => _settings[key] = value);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserData({
        'settings': _settings,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Error saving settings. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
      return const SizedBox.shrink();
    }

    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black87,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_rounded),
              color: Theme.of(context).primaryColor,
              onPressed: _saveProfileInfo,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Header with gradient background and profile info
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4CAF50),
                              const Color(0xFF66BB6A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile picture with white background
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    const AssetImage(AppAssets.profile),
                                child: user.photoURL == null
                                    ? null
                                    : ClipOval(
                                        child: Image.network(
                                          user.photoURL!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.displayName ??
                                  "${_firstNameController.text} ${_lastNameController.text}" ??
                                  'User Name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.electric_car,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${_carBrandController.text} ${_carModelController.text}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Main content with form and settings
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileSection(),
                              const SizedBox(height: 24),
                              _buildSection(
                                'App Settings',
                                [
                                  _buildSettingTile(
                                    'Push Notifications',
                                    'Receive alerts about charging status',
                                    Icons.notifications_active,
                                    _settings['pushNotifications'] ?? true,
                                    (value) => _saveSettings(
                                        'pushNotifications', value),
                                  ),
                                  _buildSettingTile(
                                    'Location Services',
                                    'Allow app to access your location',
                                    Icons.location_on,
                                    _settings['locationServices'] ?? true,
                                    (value) =>
                                        _saveSettings('locationServices', value),
                                  ),
                                  _buildSettingTile(
                                    'Dark Mode',
                                    'Switch between light and dark theme',
                                    Icons.dark_mode,
                                    _settings['darkMode'] ?? false,
                                    (value) => _saveSettings('darkMode', value),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: _signOut,
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign Out'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.red[600],
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildInputField(
          controller: _firstNameController,
          labelText: 'First Name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your first name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _lastNameController,
          labelText: 'Last Name',
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your last name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _emailController,
          labelText: 'Email',
          prefixIcon: Icons.email_outlined,
          enabled: false,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          labelText: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        // Vehicle section with icon
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.electric_car,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildInputField(
          controller: _carBrandController,
          labelText: 'Car Brand',
          prefixIcon: Icons.branding_watermark_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your car brand';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _carModelController,
          labelText: 'Car Model',
          prefixIcon: Icons.directions_car_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your car model';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(
            prefixIcon,
            color: Theme.of(context).primaryColor,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _carModelController.dispose();
    _carBrandController.dispose();
    super.dispose();
  }
}