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
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Laporan Harian',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),Text(displayDate(selectedDate),style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))])),OutlinedButton.icon(onPressed:pickDate,icon:const Icon(Icons.calendar_month_outlined),label:const Text('Pilih tanggal'))]),
      const SizedBox(height:16),
      if(loading) const LinearProgressIndicator(minHeight:3),
      const SizedBox(height:8),
      LayoutBuilder(builder:(context,c){final cols=c.maxWidth>=900?4:2; return GridView.count(crossAxisCount:cols,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:2.15,children:[_metric('Omzet',rp(omzet),Icons.payments_outlined),_metric('Transaksi','$transaksi',Icons.receipt_long_outlined,onTap:showTransactions),_metric('Item Terjual','$item',Icons.fastfood_outlined,onTap:showItemsSold),_metric('Retur','$retur',Icons.assignment_return_outlined) ]);}),
      const SizedBox(height:16),
      _paymentSummary(),
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


  Widget _paymentSummary() {
    final total = payments.values.fold<int>(0, (a, b) => a + b);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Pembayaran', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada transaksi pada tanggal ini.'),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: CustomPaint(
                      painter: _DonutPainter(values: payments.values.toList()),
                      child: Center(
                        child: Text(
                          '$total\\ntransaksi',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: payments.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _paymentColor(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${e.value}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _paymentColor(String key) {
    final i = payments.keys.toList().indexOf(key);
    const colors = [
      red,
      navy,
      Color(0xFF2E7D32),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
    ];
    return colors[i % colors.length];
  }

  Widget _metric(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: redSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: red, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: inkMuted,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          const Icon(Icons.chevron_right_rounded, size: 17, color: inkMuted),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showTransactions() async {
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada transaksi pada tanggal ini.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaksi', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (_, i) {
                      final s = sales[i];
                      return ListTile(
                        onTap: () => saleDetail(s),
                        dense: true,
                        leading: const Icon(Icons.receipt_long_rounded, color: red),
                        title: Text(s.no, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${s.time} • ${s.payment}'),
                        trailing: Text(
                          s.returned ? 'RETUR' : rp(s.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showItemsSold() async {
    if (best.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada item terjual pada tanggal ini.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Item Terjual', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              ...best.take(12).map(
                (x) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: redSoft,
                    foregroundColor: red,
                    child: Text('${x['qty']}'),
                  ),
                  title: Text(x['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: Text(rp(x['omzet'] as num), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

class _DonutPainter extends CustomPainter {
  final List<int> values;

  _DonutPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = radius * .28;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - stroke / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const colors = [
      red,
      navy,
      Color(0xFF2E7D32),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
    ];

    var start = -1.5708;

    for (var i = 0; i < values.length; i++) {
      final sweep = 6.283185307 * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return true;
  }
}
