import 'package:dist_v2/models/pedido.dart';
import 'package:dist_v2/models/vip_item.dart';
import 'package:dist_v2/services/analysis_service.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _button(
              icon: Icons.abc,
              action: () {
                tops = analysisService.sortList(SortBy.nameDown);
              },
            ),
            _button(
              icon: Icons.abc,
              action: () {
                tops = analysisService.sortList(SortBy.nameUp);
              },
            ),
            _button(
              icon: Icons.interests,
              action: () {
                tops = analysisService.sortList(SortBy.cantDown);
              },
            ),
            _button(
              icon: Icons.interests_sharp,
              action: () {
                tops = analysisService.sortList(SortBy.cantUp);
              },
            ),
            _button(
              icon: Icons.repeat_one,
              action: () {
                tops = analysisService.sortList(SortBy.repsDown);
              },
            ),
            _button(
              icon: Icons.repeat_one_on,
              action: () {
                tops = analysisService.sortList(SortBy.repsUp);
              },
            ),
            _button(
              icon: Icons.rotate_90_degrees_cw_outlined,
              action: () {
                tops = analysisService.sortList(SortBy.raisedDown);
              },
            ),
            _button(
              icon: Icons.rotate_90_degrees_ccw_rounded,
              action: () {
                tops = analysisService.sortList(SortBy.raisedDown);
              },
            ),
          ],
        ),
        SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * .64,
            child: ListView.builder(
              itemCount: tops.length,
              itemBuilder: (_, int index) {
                return Column (
                  children:[
                    ListTile(
                  title: Text(
                      'Cant. total: ${tops[index].cantTotal}, reps: ${tops[index].repeticiones}'),
                  subtitle: Text(
                      '${tops[index].nombre},   \$ ${tops[index].recaudado}'),
                ),
                const Divider(),
                
                ],);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _button({required Function() action, required IconData icon}) {
    return IconButton(
      onPressed: () => action(),
      color: const Color(0xFFE6E6E6),
      icon: Icon(
        icon,
        color: const Color(0xFF404040),
      ),
    );
  }
}
