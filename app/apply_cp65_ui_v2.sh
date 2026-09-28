#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"
if [ ! -f "$ROOT/pubspec.yaml" ] || [ ! -d "$ROOT/lib" ]; then
  echo "Jalankan dari folder app Flutter (yang berisi pubspec.yaml)."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re

root = Path(".")
def read(p): return (root/p).read_text()
def write(p,s): (root/p).write_text(s)

p = root/"pubspec.yaml"
s = read(p)
s = re.sub(r'^version:\s*6\.5\.0\+\d+\s*$', 'version: 6.5.0+2', s, flags=re.M)
if "  file_picker:" not in s:
    s = s.replace("  path_provider: ^2.1.5\n", "  path_provider: ^2.1.5\n  file_picker: ^11.0.3\n")
write(p,s)

p = root/"lib/core/constants.dart"
s = read(p).replace("const bg = Color(0xFFF4F1EF);", "const bg = Color(0xFF0E1620);")
write(p,s)

p = root/"lib/app.dart"
s = read(p)
s = s.replace("backgroundColor: Colors.transparent,\n          foregroundColor: ink,", "backgroundColor: Colors.transparent,\n          foregroundColor: Colors.white,")
s = s.replace("scaffoldBackgroundColor: bg,", """scaffoldBackgroundColor: bg,
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900),
          contentTextStyle: const TextStyle(color: ink, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
        ),""")
s = s.replace("""textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontWeight: FontWeight.w500),""", """textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
          bodySmall: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),""")
write(p,s)

p = root/"lib/features/home/home_page.dart"
s = read(p)
s = s.replace("toolbarHeight: 66,", "toolbarHeight: 72,")
s = s.replace("Text('${widget.username} • ${widget.role}', style: const TextStyle(fontSize: 11, color: inkMuted, fontWeight: FontWeight.w600)),",
              "Text('${widget.username} • ${widget.role}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),")
s = s.replace("""      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),""", """      backgroundColor: bg,
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),""")
write(p,s)

p = root/"lib/core/widgets.dart"
s = read(p)
s = s.replace("Text(copyright1, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),",
              "Text(copyright1, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white70)),")
s = s.replace("Text(copyright2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),",
              "Text(copyright2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white54)),")
write(p,s)

p = root/"lib/features/home/dashboard_page.dart"
s = read(p)
s = s.replace("Text('Transaksi Terbaru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))",
              "Text('Transaksi Terbaru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white))")
s = s.replace("Text('Belum ada transaksi.', style: Theme.of(context).textTheme.bodyMedium)",
              "Text('Belum ada transaksi.', style: const TextStyle(color: inkMuted, fontWeight: FontWeight.w600))")
s = s.replace("_stat('Status', 'V6.5.0'", "_stat('Status', 'V6.5.0+2'")
write(p,s)

p = root/"lib/services/receipt_service.dart"
s = read(p)
old = """Future<bool> _ensureBluetoothConnection() async {
  final mac = await printerMac();
  if (mac == null || mac.trim().isEmpty) return false;
  if (await PrintBluetoothThermal.connectionStatus) return true;
  return PrintBluetoothThermal.connect(macPrinterAddress: mac.trim());
}"""
new = """Future<bool> _ensureBluetoothConnection() async {
  final mac = await printerMac();
  if (mac == null || mac.trim().isEmpty) return false;

  // Android 12+ needs Nearby devices / BLUETOOTH_CONNECT.
  // Trigger the plugin permission flow before checking Bluetooth state.
  try {
    var permission = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!permission) {
      await PrintBluetoothThermal.pairedBluetooths;
      permission = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    }
    if (!permission) {
      throw Exception('Izin Bluetooth/Perangkat terdekat belum diberikan. Buka izin aplikasi CP POS lalu aktifkan Perangkat terdekat.');
    }
  } catch (e) {
    if (e.toString().contains('Izin Bluetooth')) rethrow;
  }

  final enabled = await PrintBluetoothThermal.bluetoothEnabled;
  if (!enabled) {
    throw Exception('Bluetooth HP sedang mati. Nyalakan Bluetooth lalu coba lagi.');
  }

  if (await PrintBluetoothThermal.connectionStatus) return true;
  return PrintBluetoothThermal.connect(macPrinterAddress: mac.trim());
}"""
if old not in s: raise SystemExit("receipt_service: target _ensureBluetoothConnection tidak ditemukan")
write(p, s.replace(old,new))

p = root/"lib/data/database.dart"
s = read(p)
marker = "\n  static Future<void> saveUser({"
if "static Future<void> restore(" not in s:
    method = r"""
  static Future<void> restore(Map<String, dynamic> data) async {
    final requiredTables = <String>[
      'products',
      'users',
      'sales',
      'sale_items',
      'stock_logs',
    ];

    if (data['version'] == null ||
        data['products'] is! List ||
        data['users'] is! List ||
        data['sales'] is! List ||
        data['sale_items'] is! List ||
        data['stock_logs'] is! List) {
      throw Exception('File backup tidak valid atau bukan backup CP POS.');
    }

    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('sale_items');
      await txn.delete('stock_logs');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('users');

      for (final table in requiredTables) {
        final rows = (data[table] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        for (final row in rows) {
          await txn.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
"""
    if marker not in s: raise SystemExit("database: marker saveUser tidak ditemukan")
    s = s.replace(marker, method + marker)
write(p,s)

p = root/"lib/features/settings/backup_page.dart"
backup_page = r"""import 'dart:convert';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup gagal: $e')),
      );
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> restore() async {
    if (working) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore database?'),
        content: const Text(
          'Data transaksi, menu, pengguna dan stok saat ini akan diganti '
          'dengan isi file backup. Pastikan Anda sudah membuat backup terbaru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjut Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => working = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw Exception('Format JSON tidak valid.');
      }
      final data = Map<String, dynamic>.from(decoded);

      await DB.restore(data);

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Restore berhasil'),
          content: const Text(
            'Database CP POS sudah dipulihkan. Silakan kembali ke Dashboard.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text('Restore gagal: $e'),
        ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data CP POS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Backup dan pulihkan database dengan aman.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Menyimpan menu, pengguna, transaksi, item transaksi dan stok ke file JSON.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: working ? null : backup,
                      icon: const Icon(Icons.backup_rounded),
                      label: Text(
                        working ? 'MEMPROSES...' : 'BACKUP DATA',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Restore',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih file backup .json dari HP, Downloads, Drive atau penyimpanan lain.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: working ? null : restore,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('RESTORE DATABASE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Catatan: restore mengganti seluruh isi database dengan isi backup. '
                'Selalu buat backup terbaru sebelum melakukan restore.',
              ),
            ),
          ),
          const CopyrightFooter(),
        ],
      ),
    );
  }
}
"""
write(p, backup_page)

print("Patch CP Colonel POS 6.5+2 selesai.")
PY

flutter pub get
dart analyze lib --no-fatal-warnings
echo
echo "SELESAI. Jika analyze tidak error fatal, build dengan:"
echo "flutter build apk --release"
