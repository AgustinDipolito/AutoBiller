import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/services/analysis_service.dart';
import 'package:dist_v2/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_preferences.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  List<VipItem> tops = [];
  late AnalysisService analysisService;

  @override
  void initState() {
    super.initState();

    final List<Pedido> pedidos = UserPreferences.getPedidos();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(
        () {
          analysisService.init(pedidos);
          tops = analysisService.vipItems;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    analysisService = Provider.of<AnalysisService>(context);
    return Column(
      children: [
        ColoredBox(
          color: Colors.blueGrey,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _button(
                  name: 'abc',
                  action: () {
                    tops = analysisService.sortList(SortBy.nameUp);
                  },
                ),
                _button(
                  name: 'zxy',
                  action: () {
                    tops = analysisService.sortList(SortBy.nameDown);
                  },
                ),
                _button(
                  name: 'max cant',
                  action: () {
                    tops = analysisService.sortList(SortBy.cantDown);
                  },
                ),
                _button(
                  name: 'min cant',
                  action: () {
                    tops = analysisService.sortList(SortBy.cantUp);
                  },
                ),
                _button(
                  name: 'max rep',
                  action: () {
                    tops = analysisService.sortList(SortBy.repsDown);
                  },
                ),
                _button(
                  name: 'min rep',
                  action: () {
                    tops = analysisService.sortList(SortBy.repsUp);
                  },
                ),
                _button(
                  name: '\$\$\$',
                  action: () {
                    tops = analysisService.sortList(SortBy.raisedDown);
                  },
                ),
                _button(
                  name: '\$',
                  action: () {
                    tops = analysisService.sortList(SortBy.raisedUp);
                  },
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: ListView.builder(
            itemCount: tops.length,
            itemBuilder: (_, int index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    title: Text(tops[index].nombre),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Utils.formatPrice(tops[index].recaudado.toDouble())),
                        Text('Total: ${tops[index].cantTotal}'),
                        Text('Reps: ${tops[index].repeticiones}'),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.blueGrey,
                    endIndent: 16,
                    indent: 16,
                    thickness: 0,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _button({required Function() action, required String name}) {
    return TextButton(
      onPressed: action,
      child: Text(
        name,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
