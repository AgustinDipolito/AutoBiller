import 'package:dist_v2/models/user_preferences.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  @override
  Widget build(BuildContext context) {
    final clienteService = Provider.of<ClienteService>(context);
    clienteService.setClientes = UserPreferences.getPedidos();

    return Scaffold(
      backgroundColor: Colors.grey.shade600,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Todos los pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
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
                  });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Container(
                  height: MediaQuery.of(context).size.height * .69,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListView.builder(
                    itemCount: clienteService.clientes.length,
                    itemBuilder: (BuildContext context, int i) {
                      return ListTile(
                        leading: CircleAvatar(
                          // foregroundColor: Colors.black,
                          backgroundColor: Colors.black,

                          maxRadius: 18,
                          child: clienteService.clientes[i].nombre.length >= 2
                              ? Text(
                                  clienteService.clientes[i].nombre
                                      .toUpperCase()
                                      .substring(0, 2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          clienteService.clientes[i].nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                            "${clienteService.clientes[i].fecha.day}- ${clienteService.clientes[i].fecha.month}"),
                        onTap: () {
                          Navigator.pushNamed(context, "pedido",
                              arguments: clienteService.clientes[i]);
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
                                  content: Text(
                                      "Eliminar el pedido de ${clienteService.clientes[i].nombre} ?"),
                                  actions: <Widget>[
                                    MaterialButton(
                                        child: const Text(
                                          "Cancelar",
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context)),
                                    MaterialButton(
                                        child: const Text(
                                          "Si, borrar",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onPressed: () {
                                          var key = clienteService
                                              .clientes[i]
                                              // .toList()[i]
                                              .key
                                              .toString();
                                          clienteService.deletePedido(i, key);
                                          Navigator.pop(context);
                                        }),
                                  ],
                                );
                              });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
