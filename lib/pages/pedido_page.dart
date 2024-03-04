import 'package:dist_v2/api/api.dart';
import 'package:dist_v2/api/pdf_invoice_api.dart';
import 'package:dist_v2/models/customer.dart';
import 'package:dist_v2/models/invoice.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/supplier.dart';
import 'package:dist_v2/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PedidoPage extends StatefulWidget {
  const PedidoPage({Key? key}) : super(key: key);

  @override
  State<PedidoPage> createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  List<bool> selecteds = [];
  @override
  Widget build(BuildContext context) {
    final pedido = ModalRoute.of(context)!.settings.arguments as Pedido;

    selecteds = List.generate(pedido.lista.length, (i) => false);
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey,
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text("${pedido.nombre} \$ ${pedido.total}"),
              Text(
                "${pedido.lista.length} items.",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
              Text(
                pedido.msg ?? '',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.normal),
              ),
              //TODO agregar textfield y accion al editar
              Container(
                width: MediaQuery.of(context).size.width * .9,
                height: MediaQuery.of(context).size.height * .6,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pedido.lista.length,
                  itemBuilder: (context, i) {
                    return Container(
                      color: selecteds[i] ? const Color(0xFF808080) : null,
                      child: ListTile(
                        leading: Text("${pedido.lista[i].cantidad}"),
                        onLongPress: () => _switchColor(i),
                        title: RichText(
                          text: TextSpan(
                            text: pedido.lista[i].nombre,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              const TextSpan(
                                text: "  ---   ",
                                style: TextStyle(
                                    color: Colors.black45, fontWeight: FontWeight.w200),
                              ),
                              TextSpan(
                                text: pedido.lista[i].tipo,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                        trailing: RichText(
                          text: TextSpan(
                            text: "${pedido.lista[i].precioT}",
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w100,
                                fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        elevation: 4,
                        backgroundColor: Colors.blueGrey,
                      ),
                      onPressed: () async {
                        final invoice = _generateInvoice(pedido);
                        final pdffile = await PdfInvoiceApi.generate(invoice);
                        await PdfApi.openFile(pdffile);
                      },
                      child: const Center(
                        child: Text(
                          "PDF",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        elevation: 4,
                        backgroundColor: Colors.blueGrey,
                      ),
                      onPressed: () {
                        final pedidoService =
                            Provider.of<PedidoService>(context, listen: false);
                        pedidoService.clearAll();
                        pedidoService.carrito = pedido.lista;
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Editar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        elevation: 4,
                        backgroundColor: Colors.blueGrey,
                      ),
                      onPressed: () {
                        pedido.lista.sort((a, b) => a.nombre.compareTo(b.nombre));

                        setState(() {});
                      },
                      child: const Text(
                        'ABC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  _switchColor(i) => setState(() => selecteds[i] = !selecteds[i]);

  Invoice _generateInvoice(Pedido pedido) {
    final date = DateTime.now();
    final dueDate = date.add(const Duration(days: 3));
    final List<InvoiceItem> lista = <InvoiceItem>[];
    for (var item in pedido.lista) {
      lista.add(
        InvoiceItem(
            description: "${item.nombre}-${item.tipo}",
            date: date,
            quantity: item.cantidad,
            unitPrice: item.precio.toDouble()),
      );
    }

    return Invoice(
      info: InvoiceInfo(
        date: date,
        description: "NOTA DE PRESUPUESTO",
        dueDate: dueDate,
        number: (selecteds.length + 1).toString(),
      ),
      supplier: const Supplier(
        address: "Eva Peron 417, Temperley.",
        name: "DISTRIBUIDORA ALUSOL",
        paymentInfo: "+54 9 11 66338293",
      ),
      customer: Customer(name: pedido.nombre, address: "Ubicacion: -"),
      items: lista,
    );
  }
}
