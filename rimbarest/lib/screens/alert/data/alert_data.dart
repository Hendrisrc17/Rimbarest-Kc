// File: lib/screens/alert/data/alert_data.dart

class AlertData {
  final String id;
  final String level; // 'high', 'medium', 'low' / 'critical', 'warning', 'info'
  final String title;
  final String desc;
  final String time;
  final String node;
  final String
      category; // 'KEBAKARAN_PARTIKULAT', 'ANCAMAN_AUDIO', 'KUOTA_INTERNET', 'INFO'

  // 🔥 FIX UTAMA: Hapus 'final' agar status read bisa diubah (mutable) saat tombol "Tandai Baca" ditekan
  bool read;
  final String? audioUrl;

  AlertData({
    required this.id,
    required this.level,
    required this.title,
    required this.desc,
    required this.time,
    required this.node,
    required this.category,
    this.read = false, // Default false jika dari backend bernilai null
    this.audioUrl,
  });

  // 🧠 PARSER DARI RESPONSE BACKEND NEXT.JS (/api/mobile/alert)
  factory AlertData.fromJson(Map<String, dynamic> json) {
    // Format Waktu Tampil (Jam & Menit)
    String formattedTime = 'Baru saja';
    if (json['createdAt'] != null) {
      try {
        final DateTime dt =
            DateTime.parse(json['createdAt'].toString()).toLocal();
        final String hour = dt.hour.toString().padLeft(2, '0');
        final String minute = dt.minute.toString().padLeft(2, '0');
        formattedTime = '$hour:$minute WIB';
      } catch (_) {
        formattedTime = json['createdAt'].toString();
      }
    }

    // 🔥 FIX UTAMA PARSING READ: Mendukung multi-key dari Next.js / Prisma
    final bool isReadValue = json['read'] == true ||
        json['isRead'] == true ||
        json['is_read'] == true ||
        json['status']?.toString().toUpperCase() == 'DIBACA' ||
        json['status']?.toString().toUpperCase() == 'READ';

    return AlertData(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      level: (json['level'] ?? 'LOW').toString().toLowerCase(),
      title: json['title']?.toString() ?? 'Peringatan Sistem',
      desc: json['message']?.toString() ?? json['desc']?.toString() ?? '',
      time: json['time']?.toString() ?? formattedTime,
      node: json['nodeCode']?.toString() ??
          json['nodeName']?.toString() ??
          json['node']?.toString() ??
          'NODE-001',
      category: (json['category'] ?? 'INFO').toString().toUpperCase(),
      read: isReadValue,
      audioUrl: json['audioUrl']?.toString(),
    );
  }

  // KONVERSI KE MAP / JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'title': title,
      'message': desc,
      'time': time,
      'nodeCode': node,
      'category': category,
      'read': read,
      'audioUrl': audioUrl,
    };
  }
}

// 🎯 FILTER SESUAI NOTIFIKASI SENSING RIMBAREST
const alertFilters = ['Semua', 'Kebakaran', 'Audio', 'Kuota'];

// 📦 DUMMY FALLBACK / INITIAL DATA (Gunakan tanpa const karena AlertData tidak const)
List<AlertData> alertItems = [
  AlertData(
    id: '1',
    level: 'critical',
    title: '🚨 ANCAMAN SUARA: CHAINSAW',
    desc:
        'Model DS-CNN mengidentifikasi "Chainsaw" dengan akurasi 98% pada Node B1 Hutan Lindung.',
    time: '09:38 WIB',
    node: 'NODE-001',
    category: 'ANCAMAN_AUDIO',
    read: false,
  ),
  AlertData(
    id: '2',
    level: 'warning',
    title: '🔥 BAHAYA KEBAKARAN HUTAN',
    desc:
        'Konsentrasi PM2.5 di NODE-001 mencapai 195 µg/m³, berpotensi timbul asap tebal.',
    time: '09:12 WIB',
    node: 'NODE-001',
    category: 'KEBAKARAN_PARTIKULAT',
    read: false,
  ),
  AlertData(
    id: '3',
    level: 'warning',
    title: '⚠️ KUOTA INTERNET HAMPIR HABIS',
    desc:
        'Sisa kuota data internet pada NODE-002 tinggal 450 MB (di bawah 1 GB).',
    time: '08:45 WIB',
    node: 'NODE-002',
    category: 'KUOTA_INTERNET',
    read: true,
  ),
  AlertData(
    id: '4',
    level: 'info',
    title: '✅ KONDISI LINGKUNGAN AMAN',
    desc:
        'Parameter kualitas udara dan suara ambient terpantau stabil di seluruh sektor.',
    time: '06:00 WIB',
    node: 'SISTEM',
    category: 'INFO',
    read: true,
  ),
];
