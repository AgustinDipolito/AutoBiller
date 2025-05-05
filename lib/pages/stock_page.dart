// ignore_for_file: sdk_version_since

import 'dart:async';

import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/api/pdf_stock_api.dart';
import 'package:dist_v2/models/stock.dart';
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

  final _searchController = TextEditingController();

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
    _searchController.dispose();
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
                busqueda: _searchController.text,
              );
              FileApi.openFile(pdffile);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: kDefaultIconDarkColor,
              backgroundColor: Colors.blueGrey,
            ),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            onPressed: () {
              _searchController.clear();
              stockService.searchItem('');
            },
            icon: const Icon(Icons.clear_all),
          ),
          IconButton(
            onPressed: () {
              stockService.filterMovements();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: kDefaultIconDarkColor,
            ),
            icon: const Icon(Icons.filter_alt),
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
            Row(
              children: [
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.only(left: 20),
                    // width: MediaQuery.of(context).size.width * .9,
                    decoration: BoxDecoration(
                      color: Theme.of(context).highlightColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
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
                IconButton(
                  icon: Icon(Icons.warning),
                  onPressed: () {
                    _showFilterSheet(context);
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DropdownButton<StockType>(
                  icon: const Icon(Icons.saved_search),
                  hint: const Text('Tipo'),
                  value: stockService.stockFiltered.firstOrNull?.type,
                  items: StockType.values
                      .map((e) => DropdownMenuItem<StockType>(
                            value: e,
                            child: Text(e.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (value) => stockService.searchByType(value!),
                ),
                DropdownButton<Proveedor>(
                  icon: const Icon(Icons.factory),
                  hint: const Text('Prov'),
                  value: stockService.stockFiltered.firstOrNull?.proveedor,
                  items: Proveedor.values
                      .map((e) => DropdownMenuItem<Proveedor>(
                            value: e,
                            child: Text(e.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (value) => stockService.searchByProvider(value!),
                ),
              ],
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

                  return Padding(
                    padding: const EdgeInsets.all(2),
                    child: Card.outlined(
                      color: Colors.white,
                      clipBehavior: Clip.hardEdge,
                      child: ListTile(
                        title: Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(color: Colors.indigo),
                        ),
                        subtitle: Card.outlined(
                          child: InkWell(
                            onTap: () => _showAddDialog(context, stock: item),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'x ${item.cant}  ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
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
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                      const Divider()
                                    ],
                                  ),
                                  const Spacer(),
                                  ActionChip(
                                    padding: const EdgeInsets.all(0),
                                    side: const BorderSide(color: Colors.white),
                                    elevation: 0,
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    tooltip: 'Tipo',
                                    label: Text(
                                      item.type.toString().split('.').last,
                                    ),
                                    backgroundColor:
                                        Colors.primaries[item.type.index].shade400,
                                    onPressed: () {
                                      stockService.searchByType(item.type);
                                    },
                                  ),
                                  ActionChip(
                                    padding: const EdgeInsets.all(0),
                                    elevation: 0,
                                    tooltip: 'Proveedor',
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    side: const BorderSide(color: Colors.white),
                                    label: Text(
                                      item.proveedor.toString().split('.').last,
                                    ),
                                    backgroundColor:
                                        Colors.primaries[item.proveedor.index].shade400,
                                    onPressed: () {
                                      stockService.searchByProvider(item.proveedor);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onLongPress: (() {
                          if (index == 0) {
                            stockService.removeByName(item.name);
                          }
                        }),
                        trailing: Row(
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
                                            height:
                                                MediaQuery.of(context).size.height * .5,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                            height:
                                                MediaQuery.of(context).size.height * .5,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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

  void _showFilterSheet(BuildContext context) {
    final quantityController = TextEditingController();
    bool useProvider = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      elevation: MediaQuery.sizeOf(context).height,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad mínima',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Filtrar por proveedor'),
                    subtitle: Text(
                        stockService.stockFiltered.firstOrNull?.proveedor.name ?? ''),
                    value: useProvider,
                    onChanged: (value) {
                      setState(() {
                        useProvider = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text('Aplicar filtros'),
                      onPressed: () {
                        final quantity = int.tryParse(quantityController.text) ?? 0;
                        // Here you can call your filter method with the parameters
                        if (useProvider) {
                          stockService.searchLowerThanWithType(quantity,
                              stockService.stockFiltered.firstOrNull?.proveedor ?? '');
                        } else {
                          stockService.searchLowerThan(quantity);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, {Stock? stock}) {
    final namecontroller = TextEditingController();
    final cantController = TextEditingController();
    Proveedor prov = Proveedor.otro;
    StockType type = StockType.otro;
    if (stock != null) {
      namecontroller.text = stock.name;
      cantController.text = stock.cant.toString();
      prov = stock.proveedor;
      type = stock.type;
    }
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
              Row(
                children: [
                  Flexible(
                    child: DropdownMenu(
                      inputDecorationTheme: const InputDecorationTheme(
                        border: InputBorder.none,
                      ),
                      trailingIcon: const SizedBox.shrink(),
                      label: const Text('Proveedor'),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      initialSelection: prov,
                      onSelected: (value) => prov = value as Proveedor,
                      dropdownMenuEntries: Proveedor.values
                          .map(
                            (e) => DropdownMenuEntry(
                              value: e,
                              label: e.toString().split('.').last,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: DropdownMenu(
                      inputDecorationTheme: const InputDecorationTheme(
                        border: InputBorder.none,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      trailingIcon: const SizedBox.shrink(),
                      label: const Text('Tipo'),
                      initialSelection: type,
                      onSelected: (value) => type = value as StockType,
                      dropdownMenuEntries: StockType.values
                          .map(
                            (e) => DropdownMenuEntry(
                              value: e,
                              label: e.toString().split('.').last,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: stock == null,
                controller: namecontroller,
                decoration: const InputDecoration(hintText: 'Nombre'),
              ),
              TextField(
                controller: cantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Nueva cantidad'),
              ),
            ],
          ),
          actions: <Widget>[
            MaterialButton(
              child: stock == null
                  ? const Text(
                      "Añadir",
                      style: TextStyle(color: Colors.blue),
                    )
                  : const Text(
                      "Actualizar",
                      style: TextStyle(color: Colors.blue),
                    ),
              onPressed: () {
                if (namecontroller.text.isNotEmpty && cantController.text.isNotEmpty) {
                  final stockService = Provider.of<StockService>(context, listen: false);
                  if (stock != null) {
                    stockService.updateItem(
                      Stock(
                        cant: int.parse(cantController.text),
                        name: namecontroller.text,
                        id: stock.id,
                        proveedor: prov,
                        type: type,
                        fechaMod: DateTime.now(),
                        ultimoMov: int.parse(cantController.text),
                      ),
                    );
                  } else {
                    stockService.createNew(
                      cant: int.parse(cantController.text),
                      name: namecontroller.text,
                      proveedor: prov,
                      type: type,
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        );
      },
    );
  }
}
