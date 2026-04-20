// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/fabrica_source.dart';
import '../services/fabrica_service.dart';
import '../utils.dart';

/// Wizard de importación de archivos de fábrica
/// Paso 1: Seleccionar archivo y nombre de fábrica
/// Paso 2: Preview de datos y mapeo de columnas (con auto-detección)
/// Paso 3: Confirmar importación
class FabricaImportDialog extends StatefulWidget {
  /// Si se pasa, se actualiza la fábrica existente
  final FabricaSource? fabricaExistente;

  const FabricaImportDialog({super.key, this.fabricaExistente});

  @override
  State<FabricaImportDialog> createState() => _FabricaImportDialogState();
}

class _FabricaImportDialogState extends State<FabricaImportDialog> {
  final _fabricaService = FabricaService();
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1 data
  List<int>? _fileBytes;
  String? _fileName;
  String? _fileType; // 'xlsx' | 'pdf'

  // Step 2 data (Excel only)
  List<String> _hojas = [];
  String? _hojaSeleccionada;
  List<String> _headers = [];
  Map<String, String> _columnMapping = {};
  List<List<String>> _preview = [];
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    if (widget.fabricaExistente != null) {
      _nombreController.text = widget.fabricaExistente!.nombre;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fabricaExistente != null
                              ? 'Actualizar Fábrica'
                              : 'Importar Archivo de Fábrica',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          _getStepLabel(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Step indicator
            _buildStepIndicator(),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Procesando archivo...'),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildCurrentStep(),
                    ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _retroceder,
                      child: const Text('Atrás'),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _avanzar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 2 ? Colors.green : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_currentStep == 2 ? 'Importar' : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepLabel() {
    switch (_currentStep) {
      case 0:
        return 'Paso 1: Seleccionar archivo';
      case 1:
        return 'Paso 2: Mapear columnas';
      case 2:
        return 'Paso 3: Confirmar';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _buildStepCircle(0, 'Archivo'),
          Expanded(child: _buildStepLine(0)),
          _buildStepCircle(1, 'Mapeo'),
          Expanded(child: _buildStepLine(1)),
          _buildStepCircle(2, 'Confirmar'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
            border: isCurrent ? Border.all(color: AppTheme.primaryColor, width: 3) : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade500,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: _currentStep > afterStep ? AppTheme.primaryColor : Colors.grey.shade300,
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ==================== STEP 1: File Selection ====================

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Factory name
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la fábrica / proveedor *',
              hintText: 'Ej: Axal, Flexico, Bronzen...',
              prefixIcon: Icon(Icons.factory),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese el nombre de la fábrica';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // File picker
          InkWell(
            onTap: _seleccionarArchivo,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _fileBytes != null ? Colors.green.shade300 : Colors.grey.shade300,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _fileBytes != null ? Colors.green.shade50 : Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Icon(
                    _fileBytes != null
                        ? (_fileType == 'pdf' ? Icons.picture_as_pdf : Icons.table_chart)
                        : Icons.cloud_upload_outlined,
                    size: 48,
                    color: _fileBytes != null ? Colors.green : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _fileBytes != null
                        ? _fileName ?? 'Archivo seleccionado'
                        : 'Click para seleccionar archivo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _fileBytes != null
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Formatos soportados: Excel (.xlsx) o PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (_fileBytes != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _seleccionarArchivo,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label:
                          const Text('Cambiar archivo', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_fileType == 'pdf') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los archivos PDF se guardan como referencia visual. '
                      'Para importar productos, use archivos Excel (.xlsx).',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo leer el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _fileBytes = file.bytes!;
        _fileName = file.name;
        _fileType = file.extension?.toLowerCase() == 'pdf' ? 'pdf' : 'xlsx';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  // ==================== STEP 2: Column Mapping ====================

  Widget _buildStep2() {
    if (_fileType == 'pdf') {
      return _buildPdfConfirmation();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sheet selector
        if (_hojas.length > 1) ...[
          DropdownButtonFormField<String>(
            initialValue: _hojaSeleccionada,
            decoration: const InputDecoration(
              labelText: 'Hoja de Excel',
              prefixIcon: Icon(Icons.tab),
              border: OutlineInputBorder(),
            ),
            items: _hojas.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
            onChanged: (value) {
              if (value != null && value != _hojaSeleccionada) {
                _hojaSeleccionada = value;
                _prepararExcel();
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Se detectaron $_totalRows filas y ${_headers.length} columnas. '
                  'Asigne cada columna al campo correspondiente.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Column mapping
        const Text(
          'Mapeo de columnas:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ..._headers.map((header) => _buildMappingRow(header)),
        const SizedBox(height: 16),

        // Preview
        if (_preview.isNotEmpty) ...[
          const Text(
            'Vista previa (primeras 5 filas):',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildPreviewTable(),
        ],
      ],
    );
  }

  Widget _buildMappingRow(String header) {
    final currentMapping = _columnMapping[header];

    // Check if this field is already mapped to another column
    Set<String> usedFields = {};
    for (final entry in _columnMapping.entries) {
      if (entry.key != header && entry.value.isNotEmpty) {
        usedFields.add(entry.value);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                header,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: currentMapping,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('— Ignorar —')),
                ...FabricaFieldMapping.allFields
                    .where((f) => f == currentMapping || !usedFields.contains(f))
                    .map((field) => DropdownMenuItem(
                          value: field,
                          child: Text(
                            FabricaFieldMapping.fieldLabels[field] ?? field,
                            style: const TextStyle(fontSize: 13),
                          ),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null || value.isEmpty) {
                    _columnMapping.remove(header);
                  } else {
                    _columnMapping[header] = value;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columnSpacing: 16,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 40,
          headingRowHeight: 36,
          columns: _headers
              .map((h) => DataColumn(
                    label: Text(h,
                        style:
                            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ))
              .toList(),
          rows: _preview.map((row) {
            return DataRow(
              cells: List.generate(_headers.length, (i) {
                return DataCell(
                  Text(
                    i < row.length ? row[i] : '',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPdfConfirmation() {
    return Column(
      children: [
        Icon(Icons.picture_as_pdf, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        const Text(
          'Archivo PDF seleccionado',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'El archivo "$_fileName" se guardará como referencia visual '
          'para la fábrica "${_nombreController.text}".\n\n'
          'Los productos no se parsearán automáticamente desde el PDF.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ==================== STEP 3: Confirmation ====================

  Widget _buildStep3() {
    final mappedFields = _columnMapping.entries.where((e) => e.value.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Resumen de importación',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(Icons.factory, 'Fábrica', _nombreController.text),
              _buildSummaryRow(Icons.insert_drive_file, 'Archivo', _fileName ?? ''),
              _buildSummaryRow(Icons.table_chart, 'Tipo',
                  _fileType == 'pdf' ? 'PDF (referencia)' : 'Excel'),
              if (_fileType != 'pdf') ...[
                _buildSummaryRow(
                    Icons.view_list, 'Filas a importar', '$_totalRows productos'),
                _buildSummaryRow(Icons.map, 'Campos mapeados',
                    '${mappedFields.length} de ${FabricaFieldMapping.allFields.length}'),
              ],
              if (widget.fabricaExistente != null)
                _buildSummaryRow(Icons.update, 'Acción', 'Actualizar fábrica existente'),
            ],
          ),
        ),

        if (_fileType != 'pdf' && mappedFields.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Campos mapeados:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...mappedFields.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${e.key} → ${FabricaFieldMapping.fieldLabels[e.value] ?? e.value}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )),
        ],

        if (_fileType != 'pdf' &&
            !_columnMapping.values.contains(FabricaFieldMapping.nombre)) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Advertencia: No se ha mapeado la columna "Nombre". '
                    'Los productos sin nombre serán omitidos.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION ====================

  void _retroceder() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _avanzar() async {
    switch (_currentStep) {
      case 0:
        // Validar paso 1
        if (!_formKey.currentState!.validate()) return;
        if (_fileBytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seleccione un archivo'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_fileType == 'pdf') {
          // PDF: saltar mapeo, ir directo a confirmación
          setState(() => _currentStep = 2);
        } else {
          // Excel: preparar preview y mapeo
          await _prepararExcel();
          if (_headers.isNotEmpty) {
            setState(() => _currentStep = 1);
          }
        }
        break;

      case 1:
        // Ir a confirmación
        setState(() => _currentStep = 2);
        break;

      case 2:
        // Confirmar importación
        await _confirmarImportacion();
        break;
    }
  }

  Future<void> _prepararExcel() async {
    setState(() => _isLoading = true);
    try {
      final resultado = await _fabricaService.prepararImportExcel(
        bytes: _fileBytes!,
        fileName: _fileName!,
        nombreFabrica: _nombreController.text,
      );

      setState(() {
        _hojas = List<String>.from(resultado['hojas']);
        _hojaSeleccionada = resultado['hojaSeleccionada'];
        _headers = List<String>.from(resultado['headers']);
        _columnMapping = Map<String, String>.from(resultado['autoMapping']);
        _preview =
            (resultado['preview'] as List).map((row) => List<String>.from(row)).toList();
        _totalRows = resultado['totalRows'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmarImportacion() async {
    setState(() => _isLoading = true);
    try {
      if (_fileType == 'pdf') {
        await _fabricaService.importarPdf(
          fileName: _fileName!,
          nombreFabrica: _nombreController.text,
        );
      } else {
        await _fabricaService.confirmarImportExcel(
          bytes: _fileBytes!,
          fileName: _fileName!,
          nombreFabrica: _nombreController.text,
          columnMapping: _columnMapping,
          hojaExcel: _hojaSeleccionada,
          fabricaIdExistente: widget.fabricaExistente?.id,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // true = importación exitosa
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _fileType == 'pdf'
                  ? 'PDF registrado exitosamente'
                  : 'Productos importados exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
