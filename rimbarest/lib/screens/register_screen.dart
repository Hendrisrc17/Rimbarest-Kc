import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const RegisterScreen({
    super.key,
    required this.onLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final nameC = TextEditingController();
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final phoneC = TextEditingController();
  final passC = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _anim.forward();
  }

  @override
  void dispose() {
    nameC.dispose();
    usernameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    passC.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (nameC.text.trim().isEmpty ||
        usernameC.text.trim().isEmpty ||
        emailC.text.trim().isEmpty ||
        passC.text.trim().isEmpty) {
      showMsg("Nama, username, email, dan password wajib diisi");
      return;
    }

    if (passC.text.trim().length < 6) {
      showMsg("Password minimal 6 karakter");
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.register(
        firstName: nameC.text.trim(),
        username: usernameC.text.trim(),
        email: emailC.text.trim(),
        phone: phoneC.text.trim(),
        password: passC.text.trim(),
      );

      if (!mounted) return;

      showMsg("Register berhasil. Silakan login.");
      widget.onLogin();
    } catch (e) {
      showMsg(e.toString().replaceAll("Exception:", "").trim());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 18),
              _logo(),
              const SizedBox(height: 20),
              _card(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onLogin,
                child: const Text(
                  "Sudah punya akun? Login",
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LightGradients.primaryGrad,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            "assets/images/logo.png",
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 36,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Buat Akun",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "Daftar untuk membuka fitur lengkap RIMBAREST",
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _input(
            controller: nameC,
            label: "Nama Lengkap",
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 12),
          _input(
            controller: usernameC,
            label: "Username",
            icon: Icons.badge_rounded,
          ),
          const SizedBox(height: 12),
          _input(
            controller: emailC,
            label: "Email",
            icon: Icons.email_rounded,
            keyboard: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _input(
            controller: phoneC,
            label: "Nomor HP",
            icon: Icons.phone_rounded,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _input(
            controller: passC,
            label: "Password",
            icon: Icons.lock_rounded,
            obscure: !showPassword,
            suffix: IconButton(
              onPressed: () => setState(() => showPassword = !showPassword),
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : register,
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
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Daftar",
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
      ),
    );
  }
}
