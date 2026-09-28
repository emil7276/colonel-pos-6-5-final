import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
import '../../services/receipt_service.dart';
class PosPage extends StatefulWidget {
  final String cashier;

  const PosPage({
    super.key,
    required this.cashier,
  });

  @override
  State<PosPage> createState() =>
      PosPageState();
}
class PosPageState extends State<PosPage> {
  List<Product> products = [];
  final List<CartLine> cart = [];

  String category = 'Semua';
  int discount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final raw = await DB.products();

      if (!mounted) return;

      setState(() {
        products = raw
            .map(Product.fromMap)
            .where((p) => p.active)
            .toList();
      });

      // If stock changed while a product was
      // already in the cart, adjust cart quantity.
      for (final line in cart) {
        final fresh = products.where(
          (p) => p.id == line.product.id,
        );

        if (fresh.isNotEmpty &&
            line.qty > fresh.first.stock) {
          line.qty = fresh.first.stock;
        }
      }

      cart.removeWhere(
        (line) => line.qty <= 0,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat stok: $e',
          ),
        ),
      );
    }
  }

  List<String> get categories {
    final x = <String>{'Semua'};
    x.addAll(
      products.map((p) => p.category),
    );
    return x.toList();
  }

  int get subtotal => cart.fold(
        0,
        (sum, x) =>
            sum + x.product.price * x.qty,
      );

  int get total =>
      (subtotal - discount)
          .clamp(0, 1 << 31);

  void add(Product p) {
    final found = cart.where(
      (x) => x.product.id == p.id,
    );

    if (found.isEmpty) {
      if (p.stock <= 0) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content:
                Text('Stok ${p.name} habis.'),
          ),
        );
        return;
      }

      setState(() {
        cart.add(CartLine(p, 1));
      });
    } else {
      final line = found.first;

      if (line.qty >= p.stock) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Stok ${p.name} hanya ${p.stock}.',
            ),
          ),
        );
        return;
      }

      setState(() => line.qty++);
    }
  }

  void minus(CartLine line) {
    setState(() {
      line.qty--;

      if (line.qty <= 0) {
        cart.remove(line);
      }
    });
  }

  Future<void> discountDialog() async {
    final c = TextEditingController(
      text: discount == 0
          ? ''
          : discount.toString(),
    );

    final value =
        await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Diskon'),
        content: TextField(
          controller: c,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
            labelText:
                'Nominal diskon',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                int.tryParse(c.text) ??
                    0,
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (value != null) {
      setState(() {
        discount = value.clamp(
          0,
          subtotal,
        );
      });
    }
  }

  Future<void> payment() async {
    if (cart.isEmpty) return;

    final cashController =
        TextEditingController();

    String method = 'Tunai';

    final result =
        await showDialog<
            Map<String, dynamic>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (
            context,
            setDialog,
          ) {
            final cash =
                int.tryParse(
                      cashController
                          .text,
                    ) ??
                    0;

            final change =
                method == 'Tunai'
                    ? cash - total
                    : 0;

            return AlertDialog(
              title:
                  const Text('Pembayaran'),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL ${rp(total)}',
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  DropdownButtonFormField<
                      String>(
                    value: method,
                    items: const [
                      DropdownMenuItem(
                        value: 'Tunai',
                        child:
                            Text('Tunai'),
                      ),
                      DropdownMenuItem(
                        value: 'QRIS',
                        child:
                            Text('QRIS'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialog(
                          () =>
                              method = v,
                        );
                      }
                    },
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Metode',
                    ),
                  ),
                  if (method ==
                      'Tunai') ...[
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller:
                          cashController,
                      keyboardType:
                          TextInputType
                              .number,
                      onChanged: (_) =>
                          setDialog(
                        () {},
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Uang diterima',
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      change >= 0
                          ? 'Kembalian '
                            '${rp(change)}'
                          : 'Uang kurang '
                            '${rp(-change)}',
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                  ),
                  child:
                      const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final c =
                        int.tryParse(
                              cashController
                                  .text,
                            ) ??
                            0;

                    if (method ==
                            'Tunai' &&
                        c < total) {
                      ScaffoldMessenger
                              .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Uang diterima '
                            'belum cukup.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      {
                        'method': method,
                        'cash':
                            method ==
                                    'Tunai'
                                ? c
                                : total,
                        'change':
                            method ==
                                    'Tunai'
                                ? c - total
                                : 0,
                      },
                    );
                  },
                  child:
                      const Text('PROSES'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final id = await DB.createSale(
        cashier: widget.cashier,
        items: cart,
        subtotal: subtotal,
        discount: discount,
        total: total,
        cash:
            result['cash'] as int,
        change:
            result['change'] as int,
        payment:
            result['method'] as String,
      );

      final db = await DB.database;

      final rows = await db.query(
        'sales',
        where: 'id=?',
        whereArgs: [id],
        limit: 1,
      );

      if (!mounted) return;

      setState(() {
        cart.clear();
        discount = 0;
      });

      await load();

      if (rows.isNotEmpty) {
        final sale =
            SaleModel.fromMap(
          rows.first,
        );

        if (await printerAutoPrint()) {
          await printReceipt(sale);
        }

        await showDialog(
          context: context,
          builder: (_) =>
              AlertDialog(
            title: const Text(
              'Transaksi Berhasil',
            ),
            content: Text(
              '${sale.no}\n'
              'Total ${rp(sale.total)}',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                child:
                    const Text('Tutup'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(
                    context,
                  );

                  await printReceipt(
                    sale,
                  );
                },
                child:
                    const Text('Cetak'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          duration:
              const Duration(
            seconds: 5,
          ),
          content: Text(
            'Transaksi gagal diproses:\n$e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        category == 'Semua'
            ? products
            : products
                .where(
                  (p) =>
                      p.category ==
                      category,
                )
                .toList();

    return LayoutBuilder(
      builder: (context, c) {
        final tablet =
            c.maxWidth >= 700;

        final productGrid =
            Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Menu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text('${filtered.length} menu', style: const TextStyle(color: inkMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection:
                    Axis.horizontal,
                children:
                    categories.map((x) {
                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      right: 8,
                    ),
                    child: ChoiceChip(
                      label: Text(x),
                      selected:
                          category == x,
                      onSelected: (_) {
                        setState(
                          () =>
                              category = x,
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child:
                  GridView.builder(
                padding:
                    const EdgeInsets
                        .only(
                  bottom: 20,
                ),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      tablet ? 4 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio:
                      tablet
                          ? 1.28
                          : 1.08,
                ),
                itemCount:
                    filtered.length,
                itemBuilder: (_, i) {
                  final p =
                      filtered[i];

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          add(p),
                      child:
                          Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          7,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: redSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.fastfood_rounded, size: 22, color: red),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              p.name,
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            Text(
                              rp(p.price),
                            ),
                            Text(
                              'Stok ${p.stock}',
                              style:
                                  TextStyle(
                                color: p.stock <=
                                        0
                                    ? Colors
                                        .red
                                    : Colors
                                        .green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        final cartPanel = Card(
          child: Column(
            children: [
              const ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(Icons.shopping_cart_rounded, color: red, size: 21),
                title: Text('Keranjang', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              Expanded(
                child: cart.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada item',
                        ),
                      )
                    : ListView(
                        children:
                            cart.map(
                          (line) {
                            return ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                              title: Text(
                                line.product
                                    .name,
                              ),
                              subtitle:
                                  Text(
                                rp(line
                                    .product
                                    .price),
                              ),
                              leading: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  IconButton(
                                    onPressed:
                                        () =>
                                            minus(
                                      line,
                                    ),
                                    icon:
                                        const Icon(
                                      Icons
                                          .remove_circle,
                                    ),
                                  ),
                                  Text(
                                    '${line.qty}',
                                  ),
                                  IconButton(
                                    onPressed:
                                        () =>
                                            add(
                                      line
                                          .product,
                                    ),
                                    icon:
                                        const Icon(
                                      Icons
                                          .add_circle,
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  Text(
                                rp(
                                  line.product
                                          .price *
                                      line.qty,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                        ),
                        Text(
                          rp(subtotal),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Diskon',
                        ),
                        Text(
                          rp(discount),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          rp(total),
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 18,
                            color: red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                discountDialog,
                            child:
                                const Text(
                              'Diskon',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          flex: 2,
                          child:
                              FilledButton(
                            onPressed:
                                cart.isEmpty
                                    ? null
                                    : payment,
                            style:
                                FilledButton
                                    .styleFrom(
                              backgroundColor:
                                  red,
                            ),
                            child:
                                const Text(
                              'BAYAR',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (tablet) {
          return Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: productGrid,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  flex: 4,
                  child: cartPanel,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              flex: 6,
              child: productGrid,
            ),
            SizedBox(
              height: 315,
              child: cartPanel,
            ),
          ],
        );
      },
    );
  }
}
