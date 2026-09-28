import 'package:flutter/material.dart';
import '../../core/constants.dart';

class QaPage extends StatelessWidget {
  const QaPage({super.key});

  static const items = [
    (
      'Apa fungsi CP Colonel POS?',
      'CP Colonel POS membantu mengelola menu dan harga, stok, transaksi penjualan, laporan, retur, pengguna, backup data, printer, QRIS, dan keuangan.'
    ),
    (
      'Bagaimana cara membuat transaksi?',
      'Masuk ke menu Transaksi, pilih menu yang dibeli, atur jumlahnya, isi pelanggan bila perlu, gunakan diskon jika diperlukan, lalu tekan BAYAR dan pilih metode pembayaran.'
    ),
    (
      'Apa yang terjadi setelah transaksi berhasil?',
      'Transaksi tersimpan, stok otomatis berkurang, laporan ikut diperbarui, dan jika printer otomatis diaktifkan maka struk dapat langsung dicetak.'
    ),
    (
      'Bagaimana mengatur menu dan harga?',
      'Administrator dapat membuka Pengaturan lalu memilih Menu & Harga. Dari sana menu dapat ditambah, diubah, diaktifkan, dinonaktifkan, dan harganya diperbarui.'
    ),
    (
      'Bagaimana mengelola stok?',
      'Administrator dapat membuka Pengaturan lalu Stok untuk melihat dan memperbarui jumlah stok barang. Stok juga otomatis berkurang ketika transaksi berhasil.'
    ),
    (
      'Apa fungsi Laporan?',
      'Laporan digunakan untuk melihat ringkasan penjualan, barang terjual, pelanggan, omzet, transaksi retur, dan informasi penjualan berdasarkan periode.'
    ),
    (
      'Bagaimana melakukan retur transaksi?',
      'Administrator dapat memilih transaksi yang akan diretur dari bagian laporan/transaksi yang tersedia. Setelah retur berhasil, stok barang dikembalikan dan transaksi ditandai sebagai retur.'
    ),
    (
      'Apa fungsi Keuangan?',
      'Keuangan khusus Administrator digunakan untuk mencatat pengeluaran dan melihat pendapatan, pengeluaran, serta hasil bersih. Pengeluaran tidak mengubah jumlah transaksi atau omzet pada laporan penjualan.'
    ),
    (
      'Bagaimana melakukan Backup dan Restore?',
      'Administrator dapat membuka Pengaturan > Backup. Backup digunakan untuk menyimpan data aplikasi, sedangkan Restore digunakan untuk mengembalikan data dari file backup.'
    ),
    (
      'Apa perbedaan Administrator dan Kasir?',
      'Kasir fokus pada transaksi. Administrator memiliki akses tambahan untuk pengaturan, menu, stok, pengguna, QRIS, printer, backup, laporan administrasi, dan Keuangan.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Q&A mengenai aplikasi ini')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Text(
              'Panduan singkat CP Colonel POS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          ...items.map(
            (item) => Card(
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline_rounded, color: red),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        color: inkMuted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
