import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/theme.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bento_card.dart';
import '../widgets/glass_container.dart';
import '../widgets/kinetic_typography.dart';
import '../widgets/particle_atmosphere.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _occupationController;
  
  String _gender = '';
  String _language = 'en';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _countryController = TextEditingController();
    _stateController = TextEditingController();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    _occupationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  String? _loadedUid;

  void _populateFields(UserProfile? profile) {
    if (profile == null) return;
    if (_initialized && _loadedUid == profile.uid) return;

    _loadedUid = profile.uid;
    _nameController.text = profile.fullName;
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? profile.email;
    _phoneController.text = profile.phoneNumber;
    _dobController.text = profile.dateOfBirth;
    _countryController.text = profile.country;
    _stateController.text = profile.state;
    _cityController.text = profile.city;
    _addressController.text = profile.address;
    _occupationController.text = profile.occupation;
    _gender = profile.gender;
    if (_gender.isEmpty) _gender = 'Male';
    _language = profile.language;
    _initialized = true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        await ref.read(profileProvider.notifier).uploadImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: ReceiptoTheme.error),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose Profile Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(Icons.camera_alt_rounded, 'Camera', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    }),
                    _buildOptionButton(Icons.photo_library_rounded, 'Gallery', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    }),
                    _buildOptionButton(Icons.delete_forever_rounded, 'Remove', () {
                      Navigator.pop(context);
                      ref.read(profileProvider.notifier).removeImage();
                    }, isDelete: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(IconData icon, String label, VoidCallback onTap, {bool isDelete = false}) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          iconSize: 28,
          icon: Icon(icon, color: isDelete ? ReceiptoTheme.error : ReceiptoTheme.secondary),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.04),
            padding: const EdgeInsets.all(16.0),
            shape: const CircleBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: isDelete ? ReceiptoTheme.error : Colors.white70)),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ReceiptoTheme.secondary,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile(UserProfile current) async {
    if (_formKey.currentState?.validate() ?? false) {
      final updated = current.copyWith(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _gender,
        country: _countryController.text.trim(),
        state: _stateController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        language: _language,
        occupation: _occupationController.text.trim(),
      );

      try {
        await ref.read(profileProvider.notifier).updateProfile(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully.'),
              backgroundColor: ReceiptoTheme.primary,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: ReceiptoTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    profileState.whenData((profile) {
      if (profile != null) _populateFields(profile);
    });

    return Scaffold(
      body: ParticleAtmosphere(
        child: Stack(
          children: [
            const Positioned.fill(child: KineticTypography()),
            SafeArea(
              child: profileState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(ReceiptoTheme.secondary)),
                ),
                error: (err, _) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: ReceiptoTheme.error)),
                ),
                data: (profile) {
                  if (profile == null) {
                    return const Center(child: Text('No Profile Loaded'));
                  }
                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                              onPressed: () => context.pop(),
                            ),
                            const Text(
                              'User Profile',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      
                      // Body
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: BentoCard(
                            glowColor: ReceiptoTheme.secondary,
                            borderRadius: 32,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Profile Photo
                                    Center(
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 54,
                                            backgroundColor: Colors.white.withOpacity(0.05),
                                            backgroundImage: profile.photoURL != null
                                                ? NetworkImage(profile.photoURL!)
                                                : null,
                                            child: profile.photoURL == null
                                                ? Text(
                                                    profile.fullName.isNotEmpty
                                                        ? profile.fullName[0].toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                                  )
                                                : null,
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: IconButton(
                                              onPressed: _showImagePickerOptions,
                                              icon: const Icon(Icons.edit_rounded, color: Colors.black),
                                              style: IconButton.styleFrom(
                                                backgroundColor: ReceiptoTheme.secondary,
                                                padding: const EdgeInsets.all(8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    // Full Name
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                                      validator: (val) => (val == null || val.isEmpty) ? 'Full Name is required' : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Email (Read Only)
                                    TextFormField(
                                      controller: _emailController,
                                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                                      readOnly: true,
                                      decoration: _buildInputDecoration('Email Address', Icons.email_outlined, isReadOnly: true),
                                    ),
                                    const SizedBox(height: 16),

                                    // Mobile Number
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Mobile Number', Icons.phone_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // Date of Birth
                                    TextFormField(
                                      controller: _dobController,
                                      readOnly: true,
                                      onTap: _selectDate,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Date of Birth', Icons.calendar_today_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // Gender
                                    DropdownButtonFormField<String>(
                                      value: _gender.isEmpty ? 'Male' : _gender,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Gender', Icons.wc_outlined),
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (val) => setState(() => _gender = val ?? ''),
                                    ),
                                    const SizedBox(height: 16),

                                    // Country
                                    TextFormField(
                                      controller: _countryController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Country', Icons.public_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // State
                                    TextFormField(
                                      controller: _stateController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('State', Icons.map_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // City
                                    TextFormField(
                                      controller: _cityController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('City', Icons.location_city_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // Address
                                    TextFormField(
                                      controller: _addressController,
                                      maxLines: 2,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Address', Icons.home_outlined),
                                    ),
                                    const SizedBox(height: 16),

                                    // Language
                                    DropdownButtonFormField<String>(
                                      value: _language,
                                      dropdownColor: Colors.black87,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Preferred Language', Icons.language_outlined),
                                      items: const [
                                        DropdownMenuItem(value: 'en', child: Text('English')),
                                        DropdownMenuItem(value: 'es', child: Text('Spanish')),
                                        DropdownMenuItem(value: 'fr', child: Text('French')),
                                        DropdownMenuItem(value: 'de', child: Text('German')),
                                      ],
                                      onChanged: (val) => setState(() => _language = val ?? 'en'),
                                    ),
                                    const SizedBox(height: 16),

                                    // Occupation
                                    TextFormField(
                                      controller: _occupationController,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      decoration: _buildInputDecoration('Occupation', Icons.work_outline),
                                    ),
                                    const SizedBox(height: 32),

                                    // Action Buttons: Save & Cancel
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () => _saveProfile(profile),
                                      child: Container(
                                        height: 52,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: const LinearGradient(
                                            colors: [ReceiptoTheme.primary, ReceiptoTheme.secondary],
                                          ),
                                        ),
                                        child: const Text(
                                          'Save Changes',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      onPressed: () => context.pop(),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 12),
                                    
                                    // Logout Button
                                    TextButton.icon(
                                      onPressed: () async {
                                        await ref.read(authProvider.notifier).signOut();
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      },
                                      icon: const Icon(Icons.logout_rounded, color: ReceiptoTheme.error),
                                      label: const Text('Logout', style: TextStyle(color: ReceiptoTheme.error, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, {bool isReadOnly = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: isReadOnly ? Colors.white30 : ReceiptoTheme.secondary, size: 18),
      suffixIcon: isReadOnly ? const Icon(Icons.lock_outline, color: Colors.white30, size: 18) : null,
      labelText: label,
      labelStyle: TextStyle(color: isReadOnly ? Colors.white30 : Colors.white38, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isReadOnly ? Colors.white.withOpacity(0.08) : ReceiptoTheme.secondary),
      ),
    );
  }
}
