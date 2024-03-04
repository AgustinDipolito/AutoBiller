import 'dart:async';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/api/pdf_stock_api.dart';
import 'package:dist_v2/services/stock_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StockPage extends StatefulWidget {
  const StockPage({Key? key}) : super(key: key);

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late StockService stockService;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => stockService.init());
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
                      : stockService.stock);
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
                    title: Text(item.name.toUpperCase()),
                    subtitle: Text('${item.cant}'),
                    onLongPress: (() {
                      stockService.removeByName(item.name);
                    }),
                    trailing: SizedBox(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            color: kDefaultIconDarkColor,
                            icon: const Icon(Icons.remove_circle_outline_sharp),
                            onPressed: () {
                              if (item.cant > 0) {
                                stockService.addCantToItem(item.id, cant: -1);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            color: kDefaultIconDarkColor,
                            onPressed: () {
                              stockService.addCantToItem(item.id);
                            },
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
