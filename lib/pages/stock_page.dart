import 'dart:async';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/api/pdf_stock_api.dart';
import 'package:dist_v2/services/stock_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class StockPage extends StatefulWidget {
  const StockPage({Key? key}) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late StockService stockService;
  Timer? _debounce;
  List<int> cantMovimiento = List.filled(500, 0);
  List<int> cantAntes = List.filled(500, 0);
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stockService.init();
      for (var element in stockService.stock) {
        cantAntes[element.id] = element.cant;
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    stockService = Provider.of<StockService>(context);
    // stockService.stock = UserPreferences.getStock();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Stock'),
        actions: [
          IconButton(
            onPressed: () async {
              final pdffile = await PdfStockApi.generate(
                  stockService.stockFiltered.isNotEmpty
                      ? stockService.stockFiltered
                      : stockService.stock,
                  busqueda: busqueda);
              PdfApi.openFile(pdffile);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: kDefaultIconDarkColor,
              backgroundColor: Colors.blueGrey,
            ),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            onPressed: () => _showAddDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: kDefaultIconDarkColor,
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Container(
        // height: MediaQuery.of(context).size.height * .69,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.only(left: 20),
              width: MediaQuery.of(context).size.width * .9,
              decoration: BoxDecoration(
                color: Theme.of(context).highlightColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                onChanged: (value) {
                  if (value.isEmpty) return;

                  stockService.searchItem(value);
                  busqueda = value;

                  if (value.isNotEmpty) {
                    stockService.sort();
                  }
                },
                decoration: const InputDecoration(
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none,
                  hintText: "Buscar...",
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: stockService.stockFiltered.isNotEmpty
                    ? stockService.stockFiltered.length
                    : stockService.stock.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = stockService.stockFiltered.isNotEmpty
                      ? stockService.stockFiltered[index]
                      : stockService.stock[index];

                  return ListTile(
                    title: Text(
                      item.name.toUpperCase(),
                      style: const TextStyle(color: Colors.indigo),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Ahora: ${item.cant}  ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Visibility(
                              visible: cantMovimiento[item.id] != 0,
                              child: Text(
                                '${cantMovimiento[item.id].isNegative ? '' : '+'}${cantMovimiento[item.id]}',
                                style: TextStyle(
                                  color: cantMovimiento[item.id].isNegative
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Visibility(
                          visible: cantMovimiento[item.id] != 0,
                          child: Text(
                            'Antes: ${cantAntes[item.id]}',
                            style: const TextStyle(fontWeight: FontWeight.w300),
                          ),
                        ),
                        const Divider()
                      ],
                    ),
                    onLongPress: (() {
                      if (index == 0) {
                        stockService.removeByName(item.name);
                      }
                    }),
                    trailing: SizedBox(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(45),
                              radius: 32,
                              splashColor: Colors.red,
                              onLongPress: () {
                                showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 16),
                                        child: SizedBox(
                                          height: MediaQuery.of(context).size.height * .5,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TextField(
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  hintText: 'Restar cantidad',
                                                ),
                                                onSubmitted: (value) {
                                                  stockService.addCantToItem(
                                                    item.id,
                                                    cant: int.parse(value) * -1,
                                                  );
                                                  cantMovimiento[item.id] -=
                                                      int.parse(value);
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Hay: ${item.cant}  ',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  Flexible(child: Text(item.name)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              onTap: () {
                                stockService.addCantToItem(item.id, cant: -1);
                                cantMovimiento[item.id] -= 1;
                              },
                              child: Ink(
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Material(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(45),
                              radius: 32,
                              splashColor: Colors.green,
                              onLongPress: () {
                                showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12.0, horizontal: 16),
                                        child: SizedBox(
                                          height: MediaQuery.of(context).size.height * .5,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TextField(
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  hintText: 'Sumar cantidad',
                                                ),
                                                onSubmitted: (value) {
                                                  stockService.addCantToItem(
                                                    item.id,
                                                    cant: int.parse(value),
                                                  );
                                                  cantMovimiento[item.id] +=
                                                      int.parse(value);
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Hay: ${item.cant}  ',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  Flexible(child: Text(item.name)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              },
                              onTap: () {
                                stockService.addCantToItem(item.id);
                                cantMovimiento[item.id] += 1;
                              },
                              child: Ink(
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final namecontroller = TextEditingController();
    final cantController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Nuevo ingreso"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                controller: namecontroller,
                decoration: const InputDecoration(hintText: 'Nombre'),
              ),
              TextField(
                autofocus: true,
                controller: cantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Nueva cantidad'),
              ),
            ],
          ),
          actions: <Widget>[
            MaterialButton(
                child: const Text(
                  "Añadir",
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () {
                  if (namecontroller.text.isNotEmpty && cantController.text.isNotEmpty) {
                    final stockService =
                        Provider.of<StockService>(context, listen: false);
                    stockService.createNew(
                      int.parse(cantController.text),
                      namecontroller.text,
                    );
                    Navigator.of(context).pop();
                  }
                })
          ],
        );
      },
    );
  }
}
