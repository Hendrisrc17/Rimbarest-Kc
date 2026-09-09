// File: lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';

import '../../auth/auth_service.dart';
import '../../theme/app_theme.dart';
import '../auth_gate_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController usernameC;
  late TextEditingController emailC;
  late TextEditingController firstNameC;
  late TextEditingController lastNameC;
  late TextEditingController phoneC;
  late TextEditingController addressC;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    usernameC = TextEditingController(
      text: (widget.user["username"] ?? "").toString(),
    );
    emailC = TextEditingController(
      text: (widget.user["email"] ?? "").toString(),
    );
    firstNameC = TextEditingController(
      text: (widget.user["firstName"] ?? widget.user["first_name"] ?? "")
          .toString(),
    );
    lastNameC = TextEditingController(
      text: (widget.user["lastName"] ?? widget.user["last_name"] ?? "")
          .toString(),
    );
    phoneC = TextEditingController(
      text: (widget.user["phone"] ?? "").toString(),
    );
    addressC = TextEditingController(
      text: (widget.user["address"] ?? "").toString(),
    );
  }

  @override
  void dispose() {
    usernameC.dispose();
    emailC.dispose();
    firstNameC.dispose();
    lastNameC.dispose();
    phoneC.dispose();
    addressC.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final username = usernameC.text.trim();
    final email = emailC.text.trim();
    final firstName = firstNameC.text.trim();
    final lastName = lastNameC.text.trim();
    final phone = phoneC.text.trim();
    final address = addressC.text.trim();

    if (username.isEmpty) {
      showMsg("Username wajib diisi");
      return;
    }

    if (email.isEmpty) {
      showMsg("Email wajib diisi");
      return;
    }

    if (!email.contains("@")) {
      showMsg("Format email tidak valid");
      return;
    }

    setState(() => loading = true);

    try {
      // 1. Menghubungi endpoint PUT /api/mobile/login-register/me di Next.js backend
      final result = await AuthService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        address: address,
      );

      // Ambil token aktif sekarang
      final currentToken = await AuthService.getToken();
      if (currentToken != null) {
        // Cek toleransi pembungkusan data dari helper mobileOk backend
        final updatedData = result["data"] ?? result;
        // Kunci data profil terbaru ke dalam cache SharedPreferences lokal HP
        await AuthService.saveSession(currentToken, updatedData);
      }

      if (!mounted) return;

      showMsg("Profil berhasil diperbarui");

      // Mengirimkan callback nilai true agar halaman ProfileScreen memicu refresh data live
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("🚨 Gagal memperbarui profil: $e");
      final errorText = e.toString().replaceAll("Exception: ", "");

      // Pengecekan sesi kadaluarsa secara ketat agar tidak salah deteksi error koneksi biasa
      if (errorText.toUpperCase().contains("TOKEN_INVALID") ||
          errorText.toUpperCase().contains("UNAUTHORIZED") ||
          errorText.contains("401")) {
        await AuthService.clearSession();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
          (route) => false,
        );
        return;
      }

      // Fallback pesan interaktif ke user tanpa merusak status login
      if (errorText.toLowerCase().contains("username")) {
        showMsg("Username sudah digunakan");
      } else if (errorText.toLowerCase().contains("email")) {
        showMsg("Email sudah used oleh akun lain");
      } else if (errorText.toLowerCase().contains("connection refused") ||
          errorText.toLowerCase().contains("socketexception")) {
        showMsg(
            "Gagal terhubung ke backend. Periksa kembali IP server laptop kamu!");
      } else {
        showMsg(errorText.isNotEmpty
            ? errorText
            : "Gagal menyimpan profil, periksa koneksi server backend kamu");
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text(
          "Edit Profil",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgPage,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          _input(
            "Username",
            usernameC,
            Icons.badge_rounded,
            enabled: false,
          ),
          _input(
            "Email",
            emailC,
            Icons.email_rounded,
            keyboard: TextInputType.emailAddress,
            enabled: false,
          ),
          _input(
            "Nama Depan",
            firstNameC,
            Icons.person_rounded,
          ),
          _input(
            "Nama Belakang",
            lastNameC,
            Icons.person_outline_rounded,
          ),
          _input(
            "Nomor Telepon",
            phoneC,
            Icons.phone_rounded,
            keyboard: TextInputType.phone,
          ),
          _input(
            "Alamat Lengkap",
            addressC,
            Icons.location_city_rounded,
            keyboard: TextInputType.multiline,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "Simpan Perubahan",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(
          color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
          fontSize: 14,
          fontWeight: enabled ? FontWeight.w500 : FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(
            icon,
            color: enabled ? AppTheme.primary : AppTheme.textLight,
            size: 20,
          ),
          filled: true,
          fillColor: enabled ? AppTheme.bgInput : AppTheme.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.borderSoft,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.borderSoft,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.borderSoft,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppTheme.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
