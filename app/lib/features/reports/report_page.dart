import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
import '../../services/receipt_service.dart';

class ReportPage extends StatefulWidget {
  final String role;
  const ReportPage({super.key, required this.role});
  @override State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime selectedDate = DateTime.now();
  bool loading = true;
  int omzet = 0, transaksi = 0, item = 0, retur = 0;
  Map<String,int> payments = {};
  List<SaleModel> sales = [];
  List<Map<String,dynamic>> best = [], hours = [];

  DateTime get start => DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  DateTime get end => start.add(const Duration(days: 1));

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final summary = await DB.daySummary(selectedDate);
      final b = await DB.bestSelling(start, end);
      final h = await DB.hourly(start, end);
      if (!mounted) return;
      setState(() {
        omzet = summary['omzet'] as int; transaksi = summary['transaksi'] as int; item = summary['item'] as int; retur = summary['returned'] as int;
        payments = Map<String,int>.from(summary['payments'] as Map);
        sales = (summary['sales'] as List).map((e)=>SaleModel.fromMap(e as Map<String,dynamic>)).toList();
        best = b; hours = h; loading = false;
      });
    } catch(e) { if (!mounted) return; setState(()=>loading=false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Gagal memuat laporan: $e'))); }
  }

  @override void initState(){ super.initState(); load(); }

  Future<void> pickDate() async {
    final d=await showDatePicker(context:context,initialDate:selectedDate,firstDate:DateTime(2020),lastDate:DateTime.now());
    if(d!=null){setState(()=>selectedDate=d); await load();}
  }

  @override Widget build(BuildContext context){
    return RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,28),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Laporan Harian',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),Text(displayDate(selectedDate),style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))])),OutlinedButton.icon(onPressed:pickDate,icon:const Icon(Icons.calendar_month_outlined),label:const Text('Pilih tanggal'))]),
      const SizedBox(height:16),
      if(loading) const LinearProgressIndicator(minHeight:3),
      const SizedBox(height:8),
      LayoutBuilder(builder:(context,c){final cols=c.maxWidth>=900?4:2; return GridView.count(crossAxisCount:cols,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:2.0,children:[_metric('Omzet',rp(omzet),Icons.payments_outlined),_metric('Transaksi','$transaksi',Icons.receipt_long_outlined),_metric('Item Terjual','$item',Icons.fastfood_outlined),_metric('Retur','$retur',Icons.assignment_return_outlined)]);}),
      const SizedBox(height:16),
      _section('Ringkasan Pembayaran',payments.isEmpty?[const ListTile(title:Text('Belum ada transaksi pada tanggal ini.'))]:payments.entries.map((e)=>ListTile(leading:Icon(e.key=='Tunai'?Icons.payments_outlined:Icons.qr_code_2_outlined),title:Text(e.key),trailing:Text('${e.value} transaksi',style:const TextStyle(fontWeight:FontWeight.w700)))).toList()),
      _section('Menu Terlaris',best.isEmpty?[const ListTile(title:Text('Belum ada penjualan.'))]:best.take(8).map((x)=>ListTile(leading:CircleAvatar(child:Text('${x['qty']}')),title:Text(x['name'].toString()),trailing:Text(rp(x['omzet'] as num),style:const TextStyle(fontWeight:FontWeight.w700)))).toList()),
      _section('Jam Transaksi',hours.isEmpty?[const ListTile(title:Text('Belum ada penjualan.'))]:hours.take(8).map((x)=>ListTile(leading:const Icon(Icons.schedule_outlined),title:Text('${x['jam']}:00'),trailing:Text('${x['transaksi']} transaksi'))).toList()),
      const SizedBox(height:6),
      const Text('Transaksi Hari Ini',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),
      const SizedBox(height:8),
      if(sales.isEmpty) Card(child:Padding(padding:const EdgeInsets.all(18),child:Text('Tidak ada transaksi pada ${displayDate(selectedDate)}.'))),
      ...sales.map((s)=>Card(child:ListTile(onTap:()=>saleDetail(s),leading:CircleAvatar(child:Icon(s.returned?Icons.undo:Icons.receipt_long_outlined)),title:Text(s.no,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${s.time} • ${s.cashier} • ${s.payment}'),trailing:Text(s.returned?'RETUR':rp(s.total),style:TextStyle(fontWeight:FontWeight.w800,color:s.returned?Colors.red:null))))),
      const CopyrightFooter(),
    ]));
  }

  Widget _metric(String title,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Icon(icon,color:red,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(title),FittedBox(alignment:Alignment.centerLeft,child:Text(value,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)))]))])));
  Widget _section(String title,List<Widget> children)=>Card(margin:const EdgeInsets.only(bottom:12),child:ExpansionTile(initiallyExpanded:true,title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),children:children));

  Future<void> saleDetail(SaleModel s) async {
    final items = await DB.saleItems(s.id);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            children: [
              Text(s.no, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              Text('${s.time} • ${s.cashier}'),
              const Divider(),
              ...items.map((i) => ListTile(
                    dense: true,
                    title: Text(i['name'].toString()),
                    subtitle: Text('Qty ${i['qty']}'),
                    trailing: Text(rp((i['price'] as int) * (i['qty'] as int))),
                  )),
              ListTile(
                title: const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800)),
                trailing: Text(rp(s.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        printReceipt(s);
                      },
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Cetak'),
                    ),
                  ),
                  if (widget.role == 'Administrator' && !s.returned) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          authorizeReturn(s);
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Retur'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> authorizeReturn(SaleModel sale) async {
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otorisasi Retur Admin'),
        content: TextField(
          controller: pass,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password Admin'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final admin = await DB.login('admin', pass.text);
              if (!context.mounted) return;
              Navigator.pop(context, admin != null && admin['role'] == 'Administrator');
            },
            child: const Text('OTORISASI'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DB.returnSale(sale.id, 'admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retur berhasil. Stok dikembalikan.')));
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Retur gagal: $e')));
    }
  }
}
