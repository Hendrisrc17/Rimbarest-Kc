// File: lib/screens/profile/widgets/profile_card.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/auth_service.dart';
import '../../../auth/api_config.dart';
import '../../../theme/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onPhotoTap;

  const ProfileCard({
    super.key,
    required this.user,
    required this.onPhotoTap,
  });

  static Future<Map<String, dynamic>?> pickAndUploadPhoto() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (img == null) return null;

    final result = await AuthService.getProfile();

    return Map<String, dynamic>.from(
      result["data"] ?? {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = user["username"] ?? "-";

    final firstName = user["firstName"] ?? user["first_name"] ?? "";
    final lastName = user["lastName"] ?? user["last_name"] ?? "";

    final fullName = "$firstName $lastName".trim();
    final name = fullName.isNotEmpty ? fullName : username;

    final email = user["email"] ?? "-";
    final phone = user["phone"] ?? "Nomor belum diisi";
    final address = user["address"] ?? "Alamat belum diisi";
    final role = (user["role"] ?? "PENGGUNA").toString().toUpperCase();
    final photo = user["photo"];

    ImageProvider? photoProvider;

    if (photo != null && photo.toString().isNotEmpty) {
      final apiRoot = ApiConfig.baseUrl.replaceAll("/api", "");

      final photoUrl = photo.toString().startsWith("http")
          ? photo.toString()
          : "$apiRoot$photo";

      photoProvider = NetworkImage(photoUrl);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // 🚀 FIX 1: Mengubah warna background card kustom menjadi warna solid bawaan tema agar lolos compile
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        // 🚀 FIX 2: Mengamankan border color dari token yang hilang ke AppTheme.primary soft
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            // 🚀 FIX 3: Mengganti withOpacity bawaan lama dengan fungsi standar modern .withValues(alpha: ...)
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: photoProvider,
                  child: photoProvider == null
                      ? Text(
                          name.toString().isNotEmpty
                              ? name.toString()[0].toUpperCase()
                              : "R",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email.toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phone.toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    // 🚀 FIX 4: Mengganti badge gradient dengan solid AppTheme.primary modern
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
