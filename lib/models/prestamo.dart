class Prestamo {
  const Prestamo({
    required this.id,
    required this.cliente,
    required this.dni,
    required this.monto,
    required this.interes,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    required this.pagado,
    required this.totalACobrar,
  });

  final int id;
  final String cliente;
  final String dni;
  final double monto;
  final double interes;
  final DateTime fechaPrestamo;
  final DateTime fechaVencimiento;
  final bool pagado;
  final double totalACobrar;

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    return Prestamo(
      id: (json['id'] as num).toInt(),
      cliente: json['cliente'] as String,
      dni: json['dni'] as String,
      monto: (json['monto'] as num).toDouble(),
      interes: (json['interes'] as num).toDouble(),
      fechaPrestamo: DateTime.parse(json['fechaPrestamo'] as String),
      fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
      pagado: json['pagado'] as bool,
      totalACobrar: (json['totalACobrar'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente': cliente,
      'dni': dni,
      'monto': monto,
      'interes': interes,
      'fechaPrestamo': _formatDate(fechaPrestamo),
      'fechaVencimiento': _formatDate(fechaVencimiento),
      'pagado': pagado,
      'totalACobrar': totalACobrar,
    };
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
