#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

if [ ! -f pubspec.yaml ] || [ ! -d lib ]; then
  echo "Jalankan dari: ~/storage/downloads/colonel-pos-6-5-upload/app"
  exit 1
fi

# File ini hanya mengubah source code. Tidak membutuhkan Flutter/Dart SDK di Termux.
# Build tetap dilakukan oleh GitHub Actions.

python3 - <<'PY'
from pathlib import Path
import re

root = Path('.')

def rw(rel, fn):
    p = root / rel
    s = p.read_text()
    s = fn(s)
    p.write_text(s)

# Version + restore dependency
rw('pubspec.yaml', lambda s: re.sub(r'^version:\s*6\.5\.0\+\d+\s*$', 'version: 6.5.0+2', s, flags=re.M).replace(
    '  path_provider: ^2.1.5\n', '  path_provider: ^2.1.5\n  file_picker: ^11.0.3\n'
) if '  file_picker:' not in s else re.sub(r'^version:\s*6\.5\.0\+\d+\s*$', 'version: 6.5.0+2', s, flags=re.M))

# Dark navy global shell, while cards remain white.
rw('lib/core/constants.dart', lambda s: s.replace(
    'const bg = Color(0xFFF4F1EF);', 'const bg = Color(0xFF0E1620);'))

rw('lib/app.dart', lambda s: s.replace(
    'foregroundColor: ink,', 'foregroundColor: Colors.white,', 1
).replace(
    "indicatorColor: red.withValues(alpha: .12),", "indicatorColor: red.withValues(alpha: .14),"
))

# Login page adapted to dark shell.
def login_patch(s):
    s = s.replace(
        'colors: [Color(0xFFFFF1F1), bg],',
        'colors: [Color(0xFF182433), bg],'
    )
    s = s.replace(
        "'CP POS',\n                    style: TextStyle(\n                      fontSize: 30,",
        "'CP POS',\n                    style: TextStyle(\n                      color: Colors.white,\n                      fontSize: 30,"
    )
    s = s.replace(
        "'Professional Point of Sale • V6.5',\n                    style: TextStyle(color: inkMuted,",
        "'Professional Point of Sale • V6.5',\n                    style: TextStyle(color: Colors.white70,"
    )
    return s
rw('lib/features/auth/login_page.dart', login_patch)

# Home shell: compact header similar to reference image.
def home_patch(s):
    s = s.replace('toolbarHeight: 66,', 'toolbarHeight: 70,')
    s = s.replace(
        "Text('${widget.username} • ${widget.role}', style: const TextStyle(fontSize: 11, color: inkMuted, fontWeight: FontWeight.w600)),",
        "Text('${widget.username} • ${widget.role}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),"
    )
    return s
rw('lib/features/home/home_page.dart', home_patch)

# Dashboard visual treatment.
def dash_patch(s):
    s = s.replace(
        "Text('Transaksi Terbaru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),",
        "Text('Transaksi Terbaru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),"
    )
    s = s.replace("_stat('Status', 'V6.5.0'", "_stat('Status', 'V6.5.0+2'")
    return s
rw('lib/features/home/dashboard_page.dart', dash_patch)

# Copyright on dark shell.
def widgets_patch(s):
    s = s.replace(
        'Text(copyright1, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),',
        'Text(copyright1, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white70)),')
    s = s.replace(
        'Text(copyright2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),',
        'Text(copyright2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54)),')
    return s
rw('lib/core/widgets.dart', widgets_patch)

# Bluetooth: distinguish permission, Bluetooth-off and connection failures.
def bt_patch(s):
    old = '''Future<bool> _ensureBluetoothConnection() async {\n  final mac = await printerMac();\n  if (mac == null || mac.trim().isEmpty) return false;\n  if (await PrintBluetoothThermal.connectionStatus) return true;\n  return PrintBluetoothThermal.connect(macPrinterAddress: mac.trim());\n}'''
    new = '''Future<bool> _ensureBluetoothConnection() async {\n  final mac = await printerMac();\n  if (mac == null || mac.trim().isEmpty) return false;\n\n  try {\n    var granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;\n    if (!granted) {\n      // Accessing pairedBluetooths lets the plugin request/check the Android 12+\n      // Nearby devices permission before we report a false Bluetooth state.\n      await PrintBluetoothThermal.pairedBluetooths;\n      granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;\n    }\n    if (!granted) {\n      throw Exception(\n        'Izin Perangkat terdekat/Bluetooth belum diberikan. Buka Pengaturan HP > Aplikasi > CP POS > Izin lalu izinkan Perangkat terdekat.',\n      );\n    }\n  } catch (e) {\n    if (e.toString().contains('Izin Perangkat')) rethrow;\n  }\n\n  final enabled = await PrintBluetoothThermal.bluetoothEnabled;\n  if (!enabled) {\n    throw Exception('Bluetooth HP sedang mati. Nyalakan Bluetooth lalu coba lagi.');\n  }\n\n  if (await PrintBluetoothThermal.connectionStatus) return true;\n  final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac.trim());\n  if (!connected) {\n    throw Exception('Printer gagal terhubung. Pastikan printer sudah paired di Pengaturan Bluetooth HP.');\n  }\n  return true;\n}'''
    if old not in s:
        raise SystemExit('Target Bluetooth tidak ditemukan')
    return s.replace(old, new)
rw('lib/services/receipt_service.dart', bt_patch)

# Database restore: replaces all backed-up tables in one transaction.
def db_patch(s):
    if 'static Future<void> restore(' in s:
        return s
    marker = '\n  static Future<void> saveUser({'
    method = '''\n  static Future<void> restore(Map<String, dynamic> data) async {\n    if (data['version'] == null ||\n        data['products'] is! List ||\n        data['users'] is! List ||\n        data['sales'] is! List ||\n        data['sale_items'] is! List ||\n        data['stock_logs'] is! List) {\n      throw Exception('File backup tidak valid atau bukan backup CP POS.');\n    }\n\n    final db = await database;\n    await db.transaction((txn) async {\n      await txn.delete('sale_items');\n      await txn.delete('stock_logs');\n      await txn.delete('sales');\n      await txn.delete('products');\n      await txn.delete('users');\n\n      for (final table in ['products', 'users', 'sales', 'sale_items', 'stock_logs']) {\n        final rows = (data[table] as List)\n            .map((e) => Map<String, dynamic>.from(e as Map))\n            .toList();\n        for (final row in rows) {\n          await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);\n        }\n      }\n    });\n  }\n'''
    if marker not in s:
        raise SystemExit('Marker database tidak ditemukan')
    return s.replace(marker, method + marker)
rw('lib/data/database.dart', db_patch)

# Replace Backup page with working Android file picker restore.
backup = r'''import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool working = false;

  Future<File> makeBackup() async {
    final data = await DB.backup();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(
      dir.path,
      'colonel_pos_v65_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    ));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<void> backup() async {
    if (working) return;
    setState(() => working = true);
    try {
      final file = await makeBackup();
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Backup CP Colonel POS 6.5',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup gagal: $e')));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restore() async {
    if (working) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore database?'),
        content: const Text(
          'Semua data saat ini akan diganti dengan isi file backup. '
          'Buat backup terbaru sebelum melanjutkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjut Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => working = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final bytes = picked.bytes ?? (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null) throw Exception('File backup tidak dapat dibaca.');
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw Exception('Format JSON tidak valid.');
      await DB.restore(Map<String, dynamic>.from(decoded));

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Restore berhasil'),
          content: const Text('Database CP POS sudah dipulihkan. Kembali ke Dashboard untuk melihat data terbaru.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(duration: const Duration(seconds: 6), content: Text('Restore gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [red, darkRed]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.storage_rounded, color: Colors.white, size: 34),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Data CP POS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Backup dan pulihkan database dengan aman.', style: TextStyle(color: Colors.white70)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Backup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Menyimpan menu, pengguna, transaksi, item transaksi dan stok ke file JSON.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: working ? null : backup, icon: const Icon(Icons.backup_rounded), label: Text(working ? 'MEMPROSES...' : 'BACKUP DATA'))),
          ]))),
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Restore', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Pilih file backup .json dari HP, Downloads, Drive atau penyimpanan lain.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: working ? null : restore, icon: const Icon(Icons.restore_rounded), label: const Text('RESTORE DATABASE'))),
          ]))),
          const SizedBox(height: 10),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Restore mengganti seluruh isi database dengan isi backup. Selalu buat backup terbaru sebelum restore.'))),
          const CopyrightFooter(),
        ],
      ),
    );
  }
}
'''
(root/'lib/features/settings/backup_page.dart').write_text(backup)

print('PATCH_OK')
PY

echo
echo 'Source sudah dipatch.'
echo 'Flutter/Dart tidak diperlukan di Termux untuk tahap ini.'
echo
echo 'Selanjutnya:'
echo '  git diff --stat'
echo '  git add .'
echo '  git commit -m "CP POS 6.5.0+2 UI restore bluetooth"'
echo '  git push origin main'
