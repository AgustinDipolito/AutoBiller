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
  PedidoPage({Key? key}) : super(key: key);

  @override
  _PedidoPageState createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  List<bool> _selected = List.generate(100, (i) => false);
  @override
  Widget build(BuildContext context) {
    final cliente = ModalRoute.of(context)!.settings.arguments as Pedido;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.grey.shade600, Colors.grey.shade400]),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * .6,
                height: MediaQuery.of(context).size.height * .90,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cliente.lista.length,
                  itemBuilder: (context, i) {
                    return Container(
                      color: _selected[i] ? Color(0xFF808080) : null,
                      child: ListTile(
                        leading: Text("${cliente.lista[i].cantidad}"),
                        onLongPress: () => _switchColor(i),
                        title: RichText(
                          text: TextSpan(
                            text: "${cliente.lista[i].nombre}",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: "  ---   ",
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w200),
                              ),
                              TextSpan(
                                text: "${cliente.lista[i].tipo}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ],
                          ),
                        ),
                        trailing: RichText(
                          text: TextSpan(
                            text: "${cliente.lista[i].precioT}",
                            style: TextStyle(
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text("${cliente.nombre}\n\$${cliente.total}"),
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          elevation: 0,
                          primary: Color(0xFFE6E6E6),
                        ),
                        onPressed: () async {
                          final date = DateTime.now();
                          final dueDate = date.add(Duration(days: 3));
                          final List<InvoiceItem> lista = <InvoiceItem>[];
                          for (var item in cliente.lista) {
                            lista.add(
                              InvoiceItem(
                                  description: "${item.nombre}-${item.tipo}",
                                  date: date,
                                  quantity: item.cantidad,
                                  unitPrice: item.precio.toDouble()),
                            );
                          }

                          final invoice = Invoice(
                            info: InvoiceInfo(
                                date: date,
                                description: "NOTA DE PRESUPUESTO",
                                dueDate: dueDate,
                                number: "${date.day}${date.month}${date.year}"),
                            supplier: Supplier(
                              address: "Eva Peron 417, Temperley.",
                              name: "DISTRIBUIDORA ALUSOL",
                              paymentInfo: "+54 9 11 66338293",
                            ),
                            customer: Customer(
                                name: cliente.nombre, address: "Ubicacion: -"),
                            items: lista,
                          );
                          final pdffile = await PdfInvoiceApi.generate(invoice);
                          PdfApi.openFile(pdffile);
                        },
                        child: Center(
                          child: Text(
                            "PDF",
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 33,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      // width: MediaQuery.of(context).size.width * .15,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          elevation: 0,
                          primary: Color(0xFFE6E6E6),
                        ),
                        onPressed: () {
                          final pedidoService = Provider.of<PedidoService>(
                              context,
                              listen: false);
                          pedidoService.clearAll();
                          pedidoService.carrito = cliente.lista;
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Editar",
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 33,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      //width: MediaQuery.of(context).size.width * .15,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(0xFFE6E6E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: StadiumBorder(),
                          elevation: 0,
                          primary: Color(0xFFE6E6E6),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Volver",
                            style: TextStyle(
                              color: Color(0xFF202020),
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _switchColor(i) => setState(() => _selected[i] = !_selected[i]);
}
