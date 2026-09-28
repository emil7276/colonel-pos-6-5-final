import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../data/database.dart';
import '../models/models.dart';

Future<String> storeName() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('store_name') ?? 'COLONEL FRIED CHICKEN';
}

Future<String> storeAddress() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('store_address') ?? '';
}

Future<String> storePhone() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('store_phone') ?? '';
}

Future<String> printerPaper() async {
  final p = await SharedPreferences.getInstance();
  return p.getString('printer_paper') ?? '58 mm';
}

Future<int> printerCopies() async {
  final p = await SharedPreferences.getInstance();
  return p.getInt('printer_copies') ?? 1;
}

Future<bool> printerAutoPrint() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool('printer_auto_print') ?? false;
}

PdfPageFormat _paperFormat(String paper) {
  final width = paper == '80 mm' ? 80.0 : 58.0;
  final widthPt = width / 25.4 * 72.0;
  final heightPt = 220.0 / 25.4 * 72.0;
  return PdfPageFormat(widthPt, heightPt, marginAll: 8);
}

Future<pw.Document> _buildReceipt(SaleModel sale, {int copies = 1}) async {
  final name = await storeName();
  final address = await storeAddress();
  final phone = await storePhone();
  final items = await DB.saleItems(sale.id);
  final doc = pw.Document();
  final format = _paperFormat(await printerPaper());

  for (var copy = 0; copy < copies; copy++) {
    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              name,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            if (address.isNotEmpty) pw.Text(address, textAlign: pw.TextAlign.center),
            if (phone.isNotEmpty) pw.Text(phone, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 7),
            pw.Text('NOTA PENJUALAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text('${sale.no}\n${sale.time}\nKasir: ${sale.cashier}'),
            ),
            pw.SizedBox(height: 7),
            ...items.map(
              (i) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('${i['name']} x${i['qty']}')),
                  pw.SizedBox(width: 8),
                  pw.Text(rp((i['price'] as int) * (i['qty'] as int))),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal'), pw.Text(rp(sale.subtotal))]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Diskon'), pw.Text(rp(sale.discount))]),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(rp(sale.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('Pembayaran: ${sale.payment}'),
            if (sale.payment == 'Tunai') ...[
              pw.Text('Tunai: ${rp(sale.cash)}'),
              pw.Text('Kembalian: ${rp(sale.change)}'),
            ],
            pw.SizedBox(height: 14),
            pw.Text('Terima kasih'),
            pw.SizedBox(height: 10),
            pw.Text(copyright1),
            pw.Text(copyright2),
          ],
        ),
      ),
    );
  }

  return doc;
}

Future<void> printReceipt(SaleModel sale) async {
  final copies = (await printerCopies()).clamp(1, 2);
  final doc = await _buildReceipt(sale, copies: copies);
  await Printing.layoutPdf(
    name: 'CP POS ${sale.no}',
    onLayout: (_) => doc.save(),
  );
}

Future<void> testPrinterReceipt() async {
  final paper = await printerPaper();
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: _paperFormat(paper),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('CP POS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('TEST PRINT'),
          pw.Divider(),
          pw.Text('Printer siap digunakan.'),
          pw.SizedBox(height: 12),
          pw.Text('Kertas: $paper'),
          pw.SizedBox(height: 14),
          pw.Text('CP Colonel POS V6.5'),
        ],
      ),
    ),
  );
  await Printing.layoutPdf(
    name: 'CP POS Test Print',
    onLayout: (_) => doc.save(),
  );
}
