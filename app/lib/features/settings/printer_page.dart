import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../services/receipt_service.dart';

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  static const _modeKey = 'printer_mode';
  static const _paperKey = 'printer_paper';
  static const _copiesKey = 'printer_copies';
  static const _autoKey = 'printer_auto_print';

  String mode = 'System';
  String paper = '58 mm';
  int copies = 1;
  bool autoPrint = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      mode = p.getString(_modeKey) ?? 'System';
      paper = p.getString(_paperKey) ?? '58 mm';
      copies = p.getInt(_copiesKey) ?? 1;
      autoPrint = p.getBool(_autoKey) ?? false;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final p = await SharedPreferences.getInstance();
    await p.setString(_modeKey, mode);
    await p.setString(_paperKey, paper);
    await p.setInt(_copiesKey, copies);
    await p.setBool(_autoKey, autoPrint);
    if (!mounted) return;
    setState(() => saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan printer disimpan.')),
    );
  }

  Future<void> _testPrint() async {
    try {
      await testPrinterReceipt();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print dibuka. Pilih printer pada dialog cetak.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test print gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _heroCard(),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Koneksi & Kertas',
            icon: Icons.print_outlined,
            children: [
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(
                  labelText: 'Mode printer',
                  prefixIcon: Icon(Icons.print_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'System', child: Text('System Print')), 
                  DropdownMenuItem(value: 'Bluetooth', child: Text('Bluetooth')), 
                  DropdownMenuItem(value: 'USB', child: Text('USB')), 
                ],
                onChanged: (v) => setState(() => mode = v ?? 'System'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paper,
                decoration: const InputDecoration(
                  labelText: 'Ukuran kertas',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: '58 mm', child: Text('Thermal 58 mm')), 
                  DropdownMenuItem(value: '80 mm', child: Text('Thermal 80 mm')), 
                ],
                onChanged: (v) => setState(() => paper = v ?? '58 mm'),
              ),
              const SizedBox(height: 8),
              Text(
                mode == 'System'
                    ? 'Android akan menampilkan dialog cetak untuk memilih printer.'
                    : 'Mode $mode disiapkan sebagai profil printer. Koneksi langsung bergantung pada dukungan printer dan Android.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _sectionCard(
            title: 'Perilaku Cetak',
            icon: Icons.tune_outlined,
            children: [
              DropdownButtonFormField<int>(
                value: copies,
                decoration: const InputDecoration(
                  labelText: 'Jumlah salinan',
                  prefixIcon: Icon(Icons.copy_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 lembar')), 
                  DropdownMenuItem(value: 2, child: Text('2 lembar')), 
                ],
                onChanged: (v) => setState(() => copies = v ?? 1),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: autoPrint,
                onChanged: (v) => setState(() => autoPrint = v),
                title: const Text('Cetak otomatis setelah transaksi'),
                subtitle: const Text('Jika aktif, proses cetak dijalankan setelah transaksi berhasil.'),
                secondary: const Icon(Icons.print_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _testPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('TEST PRINT'),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pengaturan ini tersimpan di perangkat. Untuk printer Bluetooth/USB langsung, dukungan perangkat keras dapat berbeda menurut model printer dan Android.',
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [red, darkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.print_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CP POS Printer', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Atur ukuran kertas dan perilaku cetak struk.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: red), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
