import 'package:flutter/material.dart';

/// Widget genérico para mostrar estados booleanos como chips
///
/// Ejemplo de uso:
/// ```dart
/// StatusChip(
///   value: true,
///   trueLabel: 'Activo',
///   falseLabel: 'Inactivo',
///   trueColor: Colors.green,
///   falseColor: Colors.red,
/// )
/// ```
class StatusChip extends StatelessWidget {
  /// Valor booleano del estado
  final bool value;

  /// Texto a mostrar cuando el valor es true
  final String trueLabel;

  /// Texto a mostrar cuando el valor es false
  final String falseLabel;

  /// Color cuando el valor es true
  final Color trueColor;

  /// Color cuando el valor es false
  final Color falseColor;

  /// Tamaño de fuente (por defecto 11)
  final double fontSize;

  /// Padding horizontal (por defecto 8)
  final double paddingHorizontal;

  /// Padding vertical (por defecto 4)
  final double paddingVertical;

  /// Radio del borde redondeado (por defecto 12)
  final double borderRadius;

  /// Ancho del borde (por defecto 1)
  final double borderWidth;

  /// Si se debe mostrar con opacidad en el fondo (por defecto 0.2)
  final double backgroundOpacity;

  /// Si se debe usar un tono más oscuro para el texto (por defecto true)
  final bool useDarkerText;

  /// Callback cuando se hace tap en el chip
  final VoidCallback? onTap;

  const StatusChip({
    super.key,
    required this.value,
    this.trueLabel = 'Sí',
    this.falseLabel = 'No',
    this.trueColor = Colors.green,
    this.falseColor = Colors.red,
    this.fontSize = 11,
    this.paddingHorizontal = 8,
    this.paddingVertical = 4,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.backgroundOpacity = 0.2,
    this.useDarkerText = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? trueColor : falseColor;
    final label = value ? trueLabel : falseLabel;

    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color,
          width: borderWidth,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: useDarkerText ? _getDarkerColor(color) : color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // Si hay onTap, envolver en InkWell
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      );
    }

    return child;
  }

  /// Obtiene un tono más oscuro del color para mejor contraste
  Color _getDarkerColor(Color color) {
    // Si el color es verde, usar shade900
    if (color == Colors.green) {
      return Colors.green.shade900;
    }
    // Si el color es rojo, usar shade900
    if (color == Colors.red) {
      return Colors.red.shade900;
    }
    // Si el color es azul, usar shade900
    if (color == Colors.blue) {
      return Colors.blue.shade900;
    }
    // Si el color es naranja, usar shade900
    if (color == Colors.orange) {
      return Colors.orange.shade900;
    }

    // Para otros colores, calcular un tono más oscuro manualmente
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - 0.3).clamp(0.0, 1.0));
    return darker.toColor();
  }
}

/// Variantes predefinidas del StatusChip

/// Chip para estado Activo/Inactivo
class ActiveStatusChip extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const ActiveStatusChip({
    super.key,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      value: isActive,
      trueLabel: 'Activo',
      falseLabel: 'Inactivo',
      trueColor: Colors.green,
      falseColor: Colors.red,
      onTap: onTap,
    );
  }
}

/// Chip para estado Disponible/No Disponible
class AvailabilityStatusChip extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback? onTap;

  const AvailabilityStatusChip({
    super.key,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      value: isAvailable,
      trueLabel: 'Disponible',
      falseLabel: 'No Disponible',
      trueColor: Colors.green,
      falseColor: Colors.orange,
      onTap: onTap,
    );
  }
}

/// Chip para estado Visible/Oculto
class VisibilityStatusChip extends StatelessWidget {
  final bool isVisible;
  final VoidCallback? onTap;

  const VisibilityStatusChip({
    super.key,
    required this.isVisible,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      value: isVisible,
      trueLabel: 'Visible',
      falseLabel: 'Oculto',
      trueColor: Colors.blue,
      falseColor: Colors.grey,
      onTap: onTap,
    );
  }
}

/// Chip para estado Pagado/Pendiente
class PaymentStatusChip extends StatelessWidget {
  final bool isPaid;
  final VoidCallback? onTap;

  const PaymentStatusChip({
    super.key,
    required this.isPaid,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      value: isPaid,
      trueLabel: 'Pagado',
      falseLabel: 'Pendiente',
      trueColor: Colors.green,
      falseColor: Colors.orange,
      onTap: onTap,
    );
  }
}

/// Chip para estado Completado/En Proceso
class CompletionStatusChip extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;

  const CompletionStatusChip({
    super.key,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      value: isCompleted,
      trueLabel: 'Completado',
      falseLabel: 'En Proceso',
      trueColor: Colors.green,
      falseColor: Colors.blue,
      onTap: onTap,
    );
  }
}
