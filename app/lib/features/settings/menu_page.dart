import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../models/models.dart';
class MenuPage
    extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() =>
      _MenuPageState();
}
class _MenuPageState
    extends State<MenuPage> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final raw =
        await DB.products();

    if (!mounted) return;

    setState(() {
      products = raw
          .map(Product.fromMap)
          .toList();
    });
  }

  Future<void> edit([
    Product? p,
  ]) async {
    final n =
        TextEditingController(
      text: p?.name ?? '',
    );

    final c =
        TextEditingController(
      text:
          p?.category ?? 'Ayam',
    );

    final pr =
        TextEditingController(
      text:
          p?.price.toString() ?? '',
    );

    final st =
        TextEditingController(
      text:
          p?.stock.toString() ?? '0',
    );

    bool active =
        p?.active ?? true;

    await showDialog(
      context: context,
      builder: (_) =>
          StatefulBuilder(
        builder: (
          context,
          setDialog,
        ) =>
            AlertDialog(
          title: Text(
            p == null
                ? 'Tambah Menu'
                : 'Edit Menu',
          ),
          content:
              SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: n,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Nama',
                  ),
                ),
                TextField(
                  controller: c,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Kategori',
                  ),
                ),
                TextField(
                  controller: pr,
                  keyboardType:
                      TextInputType
                          .number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Harga',
                  ),
                ),
                TextField(
                  controller: st,
                  keyboardType:
                      TextInputType
                          .number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Stok awal',
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (v) {
                    setDialog(
                      () =>
                          active = v,
                    );
                  },
                  title:
                      const Text(
                    'Aktif',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'Batal',
              ),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await DB.saveProduct(
                    id: p?.id,
                    name:
                        n.text.trim(),
                    category:
                        c.text.trim(),
                    price:
                        int.tryParse(
                              pr.text,
                            ) ??
                            0,
                    stock:
                        int.tryParse(
                              st.text,
                            ) ??
                            0,
                    active: active,
                  );

                  if (context
                      .mounted) {
                    Navigator.pop(
                      context,
                    );
                  }
                } catch (e) {
                  if (context
                      .mounted) {
                    ScaffoldMessenger
                            .of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menyimpan menu: '
                          '$e',
                        ),
                      ),
                    );
                  }
                }
              },
              child:
                  const Text(
                'Simpan',
              ),
            ),
          ],
        ),
      ),
    );

    await load();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Menu & Harga',
        ),
        actions: [
          IconButton(
            onPressed: () => edit(),
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(10),
        children:
            products.map((p) {
          return Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.fastfood,
                color: red,
              ),
              title: Text(p.name),
              subtitle: Text(
                '${p.category} • '
                '${rp(p.price)} • '
                'Stok ${p.stock}',
              ),
              trailing: Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Switch(
                    value:
                        p.active,
                    onChanged:
                        (v) async {
                      try {
                        await DB
                            .saveProduct(
                          id: p.id,
                          name:
                              p.name,
                          category:
                              p.category,
                          price:
                              p.price,
                          stock:
                              p.stock,
                          active: v,
                        );

                        await load();
                      } catch (e) {
                        if (!mounted)
                          return;

                        ScaffoldMessenger
                                .of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content:
                                Text(
                              'Gagal: $e',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    onPressed: () =>
                        edit(p),
                    icon:
                        const Icon(
                      Icons.edit,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
