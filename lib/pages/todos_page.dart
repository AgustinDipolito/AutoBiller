import 'package:dist_v2/models/item.dart';
import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/user_preferences.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:dist_v2/utils.dart';
import 'package:dist_v2/widgets/faltantes_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  List<List>? busqueda;
  bool selectionMode = false;
  List<bool> selects = [];

  @override
  Widget build(BuildContext context) {
    final clienteService = Provider.of<ClienteService>(context);

    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Todos los pedidos'),
        actions: [
          if (selectionMode)
            IconButton(
                color: kDefaultIconDarkColor,
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final pedidoGrande = <Item>[];
                  final List<String> nombres = [];

                  for (var i = 0; i < clienteService.clientes.length; i++) {
                    if (selects[i]) {
                      final pedido = clienteService.clientes[i];
                      if (!nombres.contains(pedido.nombre)) {
                        nombres.add(pedido.nombre);
                      }
                      pedidoGrande.addAll(pedido.lista);
                    }
                  }
                  final pedidoGrandeJunto = <Item>[];

                  for (var element in pedidoGrande) {
                    if (!pedidoGrandeJunto
                        .any((conjunto) => element.nombre == conjunto.nombre)) {
                      pedidoGrandeJunto.add(element);
                    } else {
                      final index = pedidoGrandeJunto
                          .indexWhere((conjunto) => element.nombre == conjunto.nombre);
                      pedidoGrandeJunto[index].cantidad += element.cantidad;
                    }
                  }

                  final pedido = Pedido(
                      nombre: 'CONJUNTO - ${nombres.join(", ")}',
                      fecha: DateTime.now(),
                      lista: pedidoGrandeJunto,
                      key: const Key(''),
                      total: 0);
                  selectionMode = false;
                  setState(() {});
                  nav.pushNamed("pedido", arguments: pedido);
                },
                icon: const Icon(Icons.check_circle)),
          IconButton(
              color: kDefaultIconDarkColor,
              onPressed: () async {
                setState(() {
                  selectionMode = !selectionMode;
                  selects = List.generate(clienteService.clientes.length, (i) => false);
                });
              },
              icon: const Icon(Icons.join_full_outlined)),
          FaltantesManager(clienteService: clienteService),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            height: MediaQuery.of(context).size.height * .9,
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
                      if (value.isEmpty) {
                        busqueda = null;
                        setState(() {});

                        return;
                      }

                      busqueda = clienteService.searchOnPedidos(value);
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      focusedBorder: InputBorder.none,
                      border: InputBorder.none,
                      hintText: "Buscar...",
                    ),
                  ),
                ),
                if (busqueda != null)
                  ListView.builder(
                    itemCount: busqueda!.first.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int i) {
                      final item = busqueda!.first[i] as Item;
                      return ListTile(
                        title: Text(
                          item.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text('\$ ${item.precio}'),
                      );
                    },
                  ),
                if (busqueda != null) const Divider(color: Colors.grey),
                if (busqueda != null) const Divider(color: Colors.blueGrey),
                if (busqueda != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: busqueda!.last.length,
                      itemBuilder: (BuildContext context, int i) {
                        final item = busqueda!.last[i] as Pedido;
                        return ListTile(
                          title: Text(
                            item.nombre,
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, "pedido", arguments: item);
                          },
                          trailing: Text(
                            Utils.formatDate(item.fecha),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.normal),
                          ),
                        );
                      },
                    ),
                  ),
                if (busqueda == null)
                  Flexible(
                    child: ListView.builder(
                      itemCount: clienteService.clientes.length,
                      itemBuilder: (BuildContext context, int i) {
                        final cliente = clienteService.clientes[i];
                        return ListTile(
                          leading: selectionMode
                              ? (selects[i]
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.blueGrey,
                                    )
                                  : null)
                              : CircleAvatar(
                                  backgroundColor: Colors.blueGrey,
                                  maxRadius: 18,
                                  child: cliente.nombre.length >= 2
                                      ? Text(
                                          cliente.nombre.toUpperCase().substring(0, 2),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                          title: Text(
                            cliente.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: cliente.msg == null || (cliente.msg?.isEmpty ?? true)
                              ? null
                              : Text(
                                  cliente.msg!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w300, fontSize: 12),
                                ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cliente.lista.any((acc) => acc.faltante))
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    "! " *
                                        cliente.lista.where((acc) => acc.faltante).length,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.red[900],
                                    ),
                                  ),
                                ),
                              Text(
                                cliente.fecha.year == DateTime.now().year
                                    ? Utils.formatDateNoYear(cliente.fecha)
                                    : Utils.formatDate(cliente.fecha),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: cliente.fecha.month != DateTime.now().month
                                      ? Colors.blueGrey
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (selectionMode) {
                              setState(() {
                                selects[i] = !selects[i];
                              });
                            } else {
                              Navigator.pushNamed(context, "pedido", arguments: cliente);
                            }
                          },
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (_) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: const Text("Eliminar"),
                                  content:
                                      Text("Eliminar el pedido de ${cliente.nombre} ?"),
                                  actions: <Widget>[
                                    MaterialButton(
                                        child: const Text(
                                          "Cancelar",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        onPressed: () => Navigator.pop(context)),
                                    MaterialButton(
                                        child: const Text(
                                          "Si, borrar",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          var key = cliente.key.toString();
                                          clienteService.deletePedido(i, key);
                                          Navigator.pop(context);
                                        }),
                                  ],
                                );
                              },
                            );
                          },
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

  void deleteForever(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Eliminar"),
          content: const Text("Eliminar todos los pedidos ?"),
          actions: <Widget>[
            MaterialButton(
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.blue),
                ),
                onPressed: () => Navigator.pop(context)),
            MaterialButton(
                child: const Text(
                  "Si, borrar",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  // await UserPreferences.clearAllStored();
                  setState(() {});
                  if (!mounted) return;
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
}
