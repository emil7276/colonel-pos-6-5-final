import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
class DashboardPage extends StatefulWidget {
  final String username;

  const DashboardPage({
    super.key,
    required this.username,
  });

  @override
  State<DashboardPage> createState() =>
      _DashboardPageState();
}
class _DashboardPageState
    extends State<DashboardPage> {
  int omzet = 0;
  int transaksi = 0;
  int item = 0;
  List<SaleModel> recent = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all = await DB.sales();

    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    var om = 0;
    var tr = 0;

    for (final raw in all) {
      final s = SaleModel.fromMap(raw);
      final d = DateTime.tryParse(s.time);

      if (d != null &&
          !d.isBefore(start) &&
          d.isBefore(end) &&
          !s.returned) {
        om += s.total;
        tr++;
      }
    }

    final db = await DB.database;

    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(si.qty),0) jumlah
      FROM sale_items si
      INNER JOIN sales s
        ON s.id=si.sale_id
      WHERE s.sale_time >= ?
        AND s.sale_time < ?
        AND s.returned=0
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    if (!mounted) return;

    setState(() {
      omzet = om;
      transaksi = tr;
      item = (rows.first['jumlah'] as num)
          .toInt();

      recent = all
          .take(5)
          .map(SaleModel.fromMap)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'COLONEL FRIED CHICKEN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Ringkasan penjualan hari ini',
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final width = c.maxWidth;
              final cross =
                  width > 700 ? 4 : 2;

              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.8,
                children: [
                  statCard(
                    'Omzet',
                    rp(omzet),
                    Icons.payments,
                  ),
                  statCard(
                    'Transaksi',
                    '$transaksi',
                    Icons.receipt_long,
                  ),
                  statCard(
                    'Item Terjual',
                    '$item',
                    Icons.fastfood,
                  ),
                  statCard(
                    'Status',
                    'V6.5.0',
                    Icons.verified,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Transaksi Terbaru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Belum ada transaksi.',
                ),
              ),
            )
          else
            ...recent.map(
              (s) => Card(
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    backgroundColor: red,
                    child: Icon(
                      Icons.receipt,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(s.no),
                  subtitle: Text(
                    '${s.time} • ${s.cashier}',
                  ),
                  trailing: Text(
                    rp(s.total),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          const CopyrightFooter(),
        ],
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              icon,
              color: red,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  FittedBox(
                    alignment:
                        Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
