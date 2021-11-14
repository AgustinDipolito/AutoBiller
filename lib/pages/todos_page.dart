import 'package:dist_v2/models/user_preferences.dart';
import 'package:dist_v2/services/cliente_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodosPage extends StatefulWidget {
  TodosPage({Key? key}) : super(key: key);

  @override
  _TodosPageState createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  @override
  Widget build(BuildContext context) {
    final clienteService = Provider.of<ClienteService>(context);
    clienteService.setClientes = UserPreferences.getPedidos();

    return Scaffold(
      backgroundColor: Color(0xFF808080),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * .15,
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
                        fontSize: 33,
                      ),
                    ),
                  ),
                ),
              ),
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
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text("Eliminar"),
                            content: Text("Eliminar todos los pedidos ?"),
                            actions: <Widget>[
                              MaterialButton(
                                  child: Text(
                                    "Cancelar",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                  onPressed: () => Navigator.pop(context)),
                              MaterialButton(
                                  child: Text(
                                    "Si, borrar",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    UserPreferences.clearAllStored();
                                    clienteService.loadClientes();
                                    Navigator.pop(context);
                                  }),
                            ],
                          );
                        });
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Eliminar todo",
                      style: TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 33,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Container(
              height: MediaQuery.of(context).size.height * .8,
              width: MediaQuery.of(context).size.width * .97,
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView.builder(
                itemCount: clienteService.clientes.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: CircleAvatar(
                      maxRadius: 18,
                      child: Text(
                        clienteService.clientes[i].nombre
                            .toUpperCase()
                            .substring(0, 2),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      backgroundColor: Color(0xFF808080),
                    ),
                    title: Text(
                      "${clienteService.clientes[i].nombre}",
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text("Eliminar"),
                              content: Text(
                                  "Eliminar el pedido de ${clienteService.clientes[i].nombre} ?"),
                              actions: <Widget>[
                                MaterialButton(
                                    child: Text(
                                      "Cancelar",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    onPressed: () => Navigator.pop(context)),
                                MaterialButton(
                                    child: Text(
                                      "Si, borrar",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      clienteService.deletePedido(i);
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
        ],
      ),
    );
  }
}
