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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => stockService.init());
  }

  @override
  Widget build(BuildContext context) {
    stockService = Provider.of<StockService>(context);
    // stockService.stock = UserPreferences.getStock();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Stock'),
        actions: [
          ElevatedButton.icon(
            label: const Text('Exportar'),
            onPressed: () async {
              final pdffile = await PdfStockApi.generate(
                  stockService.stockFiltered.isNotEmpty
                      ? stockService.stockFiltered
                      : stockService.stock);
              PdfApi.openFile(pdffile);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
            ),
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            label: const Text('Nuevo'),
            onPressed: () => _showAddDialog(context),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black),
            ),
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height * .69,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.only(left: 20),
                width: MediaQuery.of(context).size.width * .75,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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
            ),
            Flexible(
              flex: 4,
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
                    subtitle: Text(item.cant.toString()),
                    onLongPress: (() {
                      stockService.removeByName(item.name);
                    }),
                    trailing: SizedBox(
                      width: MediaQuery.of(context).size.width * .2,
                      child: Row(children: [
                        IconButton(
                          color: Colors.black,
                          icon: const Icon(Icons.remove_circle_outline_sharp),
                          onPressed: () {
                            if (item.cant > 0) {
                              stockService.addCantToItem(item.id, cant: -1);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          color: Colors.black,
                          onPressed: () {
                            stockService.addCantToItem(item.id);
                          },
                        ),
                      ]),
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
                  if (namecontroller.text.isNotEmpty &&
                      cantController.text.isNotEmpty) {
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
