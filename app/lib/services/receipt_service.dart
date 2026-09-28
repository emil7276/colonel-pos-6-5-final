import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../data/database.dart';
import '../models/models.dart';

Future<String> storeName() async { final p=await SharedPreferences.getInstance(); return p.getString('store_name') ?? 'COLONEL FRIED CHICKEN'; }
Future<String> storeAddress() async { final p=await SharedPreferences.getInstance(); return p.getString('store_address') ?? ''; }
Future<String> storePhone() async { final p=await SharedPreferences.getInstance(); return p.getString('store_phone') ?? ''; }

Future<void> printReceipt(SaleModel sale) async {
  final name=await storeName(); final address=await storeAddress(); final phone=await storePhone(); final items=await DB.saleItems(sale.id); final doc=pw.Document();
  doc.addPage(pw.Page(build:(_)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.center,children:[pw.Text(name,style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),if(address.isNotEmpty) pw.Text(address),if(phone.isNotEmpty) pw.Text(phone),pw.SizedBox(height:8),pw.Text('NOTA PENJUALAN'),pw.Divider(),pw.Align(alignment:pw.Alignment.centerLeft,child:pw.Text('${sale.no}\n${sale.time}\nKasir: ${sale.cashier}')),pw.SizedBox(height:8),...items.map((i)=>pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Expanded(child:pw.Text('${i["name"]} x${i["qty"]}')),pw.Text(rp((i['price'] as int)*(i['qty'] as int)))])),pw.Divider(),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('Subtotal'),pw.Text(rp(sale.subtotal))]),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('Diskon'),pw.Text(rp(sale.discount))]),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('TOTAL',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),pw.Text(rp(sale.total),style:pw.TextStyle(fontWeight:pw.FontWeight.bold))]),pw.SizedBox(height:6),pw.Text('Pembayaran: ${sale.payment}'),if(sale.payment=='Tunai') ...[pw.Text('Tunai: ${rp(sale.cash)}'),pw.Text('Kembalian: ${rp(sale.change)}')],pw.SizedBox(height:18),pw.Text('Terima kasih'),pw.SizedBox(height:14),pw.Text(copyright1),pw.Text(copyright2)])));
  await Printing.layoutPdf(onLayout:(_)=>doc.save());
}
