import { PrismaClient, DeviceStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Memulai proses seeding data RimbaRest ---');

  // 1. Hapus data lama agar bersih (Opsional)
  await prisma.sensorReading.deleteMany({});
  await prisma.deviceNode.deleteMany({});

  // 2. Buat Data Node Sensor yang AKTIF (Status: ONLINE)
  // Kolom status menggunakan ENUM dari DeviceStatus: ONLINE, OFFLINE, MAINTENANCE
  const activeNode = await prisma.deviceNode.create({
    data: {
      nodeCode: 'NODE-BABEL-01',
      name: 'Stasiun Pemantau Pangkalpinang',
      locationName: 'Bangka Belitung',
      latitude: -2.1296,
      longitude: 106.1139,
      status: DeviceStatus.ONLINE, // 🌟 INI KUNCINYA agar terdeteksi aktif oleh backend mobile
      batteryLevel: 89.5,
      signalStrength: -65.0,
      description: 'Sensor utama pemantau kualitas udara dan suara hutan RimbaRest',
      lastSeen: new Date(),
    },
  });

  console.log(`✅ Berhasil membuat node aktif: ${activeNode.name} (${activeNode.nodeCode})`);

  // 3. Buat Data Riwayat Sensor Tiruan (Mock Readings)
  // Kita buat beberapa data mundur ke belakang agar grafik 24 Jam di Flutter langsung terisi
  const now = new Date();
  
  const readingsData = [
    { minsAgo: 60, pm25: 15.5, pm10: 22.1, temp: 26.5, hum: 80.0, noise: 45.2, status: 'NORMAL' },
    { minsAgo: 45, pm25: 18.2, pm10: 25.4, temp: 27.0, hum: 78.5, noise: 48.0, status: 'NORMAL' },
    { minsAgo: 30, pm25: 22.8, pm10: 31.0, temp: 28.2, hum: 75.0, noise: 52.1, status: 'NORMAL' },
    { minsAgo: 15, pm25: 35.4, pm10: 45.2, temp: 29.5, hum: 72.3, noise: 58.7, status: 'WARNING' },
    { minsAgo: 0,  pm25: 12.3, pm10: 19.8, temp: 28.0, hum: 74.0, noise: 42.5, status: 'NORMAL' }, // Data Paling Baru (Real-time)
  ];

  for (const item of readingsData) {
    const timeStamp = new Date(now.getTime() - item.minsAgo * 60000);

    await prisma.sensorReading.create({
      data: {
        nodeId: activeNode.id, // Menghubungkan relasi ke node id di atas
        latitude: activeNode.latitude,
        longitude: activeNode.longitude,
        pm1: item.pm25 * 0.7,
        pm25: item.pm25,
        pm10: item.pm10,
        temperature: item.temp,
        humidity: item.hum,
        noiseLevel: item.noise,
        statusTerpadu: item.status,
        cacheSource: false,
        rawPayload: { info: "Generated via dev seed script" },
        recordedAt: timeStamp,
      },
    });
  }

  console.log('✅ Berhasil menyuntikkan data riwayat metrik sensor!');
  console.log('--- Seeding Selesai! Silakan jalankan hot restart di Flutter ---');
}

main()
  .catch((e) => {
    console.error('❌ Terjadi error saat seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });