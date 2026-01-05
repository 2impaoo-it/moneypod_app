import 'package:moneypod/repositories/profile_repository.dart';
import 'package:moneypod/screens/profile/profile_screen.dart';
import 'package:moneypod/services/auth_service.dart';
import 'package:moneypod/services/profile_service.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool _loading = true;
  String _token = '';
  late final ProfileService _profileService;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(ProfileRepository());
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await _authService.getToken();
    setState(() {
      _token = t ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ProfileScreen(profileService: _profileService, token: _token);
  }
}
