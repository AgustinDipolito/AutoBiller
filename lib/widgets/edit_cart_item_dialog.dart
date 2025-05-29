import 'package:dist_v2/models/item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class EditCartItemDialog extends StatefulWidget {
  final Item item;
  final Function(int quantity, String description) onSave;

  const EditCartItemDialog({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditCartItemDialog> createState() => _EditCartItemDialogState();
}

class _EditCartItemDialogState extends State<EditCartItemDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.cantidad.toString());
    _descriptionController = TextEditingController(text: widget.item.tipo);

    _descriptionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addToDescription(String text) {
    final currentText = _descriptionController.text;
    _descriptionController.text = '$currentText $text'.trim();
  }

  void _originalDescription() {
    _descriptionController.text = widget.item.tipo;
  }

  void _clearDescription() {
    _descriptionController.clear();
  }

  void _removeLastWord() {
    final currentText = _descriptionController.text;
    if (currentText.isEmpty) return;

    final words = currentText.split(' ');
    if (words.length <= 1) {
      _descriptionController.clear();
    } else {
      words.removeLast();
      _descriptionController.text = words.join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.blueGrey),
      ),
      title: Text('Editando ${widget.item.nombre}',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 18)),
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Cantidad:  ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Flexible(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ingrese cantidad',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descripción
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Descripción:  ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Flexible(
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Descripción del producto',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 4,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Rapidas:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 14)),
                  _buildOptionChip(
                      'BLANCO',
                      _descriptionController.text.toUpperCase().contains('BLANCO')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'NEGRO',
                      _descriptionController.text.toUpperCase().contains('NEGRO')
                          ? null
                          : Colors.white),
                  const SimpleVerticalDivider(primaryIndex: 2),
                  _buildOptionChip(
                      'CAJA',
                      _descriptionController.text.toUpperCase().contains('CAJA')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'UNIDAD',
                      _descriptionController.text.toUpperCase().contains('UNIDAD')
                          ? null
                          : Colors.white),
                  const SimpleVerticalDivider(primaryIndex: 15),
                  _buildOptionChip(
                      'PVC',
                      _descriptionController.text.toUpperCase().contains('PVC')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'ALUMINIO',
                      _descriptionController.text.toUpperCase().contains('ALUMINIO')
                          ? null
                          : Colors.white),
                  const SimpleVerticalDivider(primaryIndex: 5),
                  _buildOptionChip(
                      'LARGO',
                      _descriptionController.text.toUpperCase().contains('LARGO')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'MEDIANO',
                      _descriptionController.text.toUpperCase().contains('MEDIANO')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'CORTO',
                      _descriptionController.text.toUpperCase().contains('CORTO')
                          ? null
                          : Colors.white),
                  const SimpleVerticalDivider(primaryIndex: 0),
                  _buildOptionChip(
                      'x10',
                      _descriptionController.text.toUpperCase().contains('X10')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'x50',
                      _descriptionController.text.toUpperCase().contains('X50')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'x100',
                      _descriptionController.text.toUpperCase().contains('X100')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      'x1000',
                      _descriptionController.text.toUpperCase().contains('X1000')
                          ? null
                          : Colors.white),
                  const SimpleVerticalDivider(primaryIndex: 9),
                  _buildOptionChip(
                      '50',
                      _descriptionController.text.toUpperCase().contains('50 MTS')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      '100',
                      _descriptionController.text.toUpperCase().contains('100 MTS')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      '150',
                      _descriptionController.text.toUpperCase().contains('150 MTS')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      '200',
                      _descriptionController.text.toUpperCase().contains('200 MTS')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      '300',
                      _descriptionController.text.toUpperCase().contains('300 MTS')
                          ? null
                          : Colors.white),
                  _buildOptionChip(
                      ' Mts',
                      _descriptionController.text.toUpperCase().contains('MTS')
                          ? null
                          : Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Card.outlined(
              child: SizedBox(
                height: 45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        child: Text(
                            // dot unicode for bullet point
                            '  ${_descriptionController.text}',
                            style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    const VerticalDivider(
                      color: Colors.blueGrey,
                      thickness: 0,
                      endIndent: 4,
                      indent: 4,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: 'Limpiar descripción',
                      color: Colors.red,
                      onPressed: _clearDescription,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, size: 20),
                      tooltip: 'Restaurar descripción original',
                      color: Colors.blueGrey,
                      onPressed: _originalDescription,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      icon: const Icon(Icons.backspace, size: 20),
                      tooltip: 'Borrar última palabra',
                      color: Colors.red,
                      onPressed: _removeLastWord,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text('Original:  x${widget.item.cantidad} -  ${widget.item.tipo}',
              style: const TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w300, color: Colors.blueGrey)),
          const SizedBox(height: 10),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: () {
            // Parse the quantity and ensure it's at least 1
            final quantity = int.tryParse(_quantityController.text) ?? 1;

            // Pass the updated values back
            widget.onSave(
              quantity < 1 ? 1 : quantity,
              _descriptionController.text,
            );

            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blueGrey,
          ),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }

  Widget _buildOptionChip(String label, [Color? chipColor]) {
    // Determine text color based on chip background
    final textColor =
        chipColor != null && chipColor == Colors.black87 ? Colors.white : Colors.black87;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor ?? Colors.blueGrey.shade100,
      selectedColor: Colors.blueGrey.shade200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: chipColor != null ? Colors.grey.shade400 : Colors.black),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: -2),
      onSelected: (_) => _addToDescription(label),
    );
  }
}

class SimpleVerticalDivider extends StatelessWidget {
  const SimpleVerticalDivider({
    Key? key,
    required this.primaryIndex,
  }) : super(key: key);

  final int primaryIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: .8,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      color: Colors.primaries[primaryIndex].shade300,
    );
  }
}
