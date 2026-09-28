import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
class BackupPage
    extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() =>
      _BackupPageState();
}
class _BackupPageState
    extends State<BackupPage> {
  bool working = false;

  Future<File> makeBackup() async {
    final data =
        await DB.backup();

    final dir =
        await getApplicationDocumentsDirectory();

    final file = File(
      path.join(
        dir.path,
        'colonel_pos_v65_backup_'
        '${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(data),
    );

    return file;
  }

  Future<void> backup() async {
    if (working) return;

    setState(
      () => working = true,
    );

    try {
      final file =
          await makeBackup();

      await Share.shareXFiles(
        [XFile(file.path)],
        subject:
            'Backup Colonel Fried Chicken POS V6.5.0',
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Backup gagal: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () => working = false,
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Backup'),
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(16),
              child: Text(
                'Backup menyimpan data '
                'transaksi, menu, pengguna, '
                'dan stok dalam file lokal '
                'JSON. File dapat dibagikan '
                'ke HP lain, cloud storage, '
                'atau email melalui menu '
                'berbagi Android.',
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          FilledButton.icon(
            onPressed:
                working ? null : backup,
            icon: const Icon(
              Icons.backup,
            ),
            label: Text(
              working
                  ? 'MEMBUAT BACKUP...'
                  : 'BACKUP DATA',
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Catatan: backup V6.5.0 '
            'menggunakan penyimpanan '
            'lokal dan Android Share Sheet. '
            'Restore database belum '
            'diaktifkan pada versi ini.',
          ),
          const CopyrightFooter(),
        ],
      ),
    );
  }
}
