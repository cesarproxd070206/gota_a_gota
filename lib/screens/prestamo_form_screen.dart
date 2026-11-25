import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/prestamo.dart';
import '../services/auth_service.dart';
import '../services/prestamo_service.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';

class PrestamoFormScreen extends StatefulWidget {
  const PrestamoFormScreen({super.key, this.prestamo});

  final Prestamo? prestamo;

  @override
  State<PrestamoFormScreen> createState() => _PrestamoFormScreenState();
}

class _PrestamoFormScreenState extends State<PrestamoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PrestamoService();
  late final TextEditingController _clienteController;
  late final TextEditingController _dniController;
  late final TextEditingController _montoController;
  late final TextEditingController _interesController;
  late DateTime _fechaVencimiento;
  late final FocusNode _montoFocus;
  bool _pagado = false;
  bool _loading = false;

  bool get _editando => widget.prestamo != null;

  @override
  void initState() {
    super.initState();
    final prestamo = widget.prestamo;
    _clienteController = TextEditingController(text: prestamo?.cliente ?? '');
    _dniController = TextEditingController(text: prestamo?.dni ?? '');
    _montoController = TextEditingController(
      text: prestamo == null ? '' : Money.format(prestamo.monto),
    );
    _interesController = TextEditingController(
      text: prestamo == null ? '' : prestamo.interes.toStringAsFixed(2),
    );
    _fechaVencimiento = prestamo?.fechaVencimiento ?? DateTime.now().add(const Duration(days: 30));
    _pagado = prestamo?.pagado ?? false;
    _montoFocus = FocusNode();
    _montoFocus.addListener(_formatearMonto);
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _dniController.dispose();
    _montoFocus.removeListener(_formatearMonto);
    _montoFocus.dispose();
    _montoController.dispose();
    _interesController.dispose();
    super.dispose();
  }

  void _formatearMonto() {
    if (_montoFocus.hasFocus) {
      return;
    }
    final monto = Money.tryParse(_montoController.text);
    if (monto == null) {
      return;
    }
    final formatted = Money.format(monto);
    if (_montoController.text != formatted) {
      _montoController.text = formatted;
    }
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fechaVencimiento = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    final prestamo = Prestamo(
      id: widget.prestamo?.id ?? 0,
      cliente: _clienteController.text.trim(),
      dni: _dniController.text.trim(),
      monto: Money.tryParse(_montoController.text)!,
      interes: double.parse(_interesController.text.trim()),
      fechaPrestamo: widget.prestamo?.fechaPrestamo ?? DateTime.now(),
      fechaVencimiento: _fechaVencimiento,
      pagado: _pagado,
      totalACobrar: widget.prestamo?.totalACobrar ?? 0,
    );
    try {
      if (_editando) {
        await _service.actualizar(widget.prestamo!.id, prestamo);
      } else {
        await _service.crear(prestamo);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on SessionExpiredException catch (error) {
      await AuthService().logout();
      if (!mounted) {
        return;
      }
      _showMessage(error.message);
      Navigator.of(context).pushAndRemoveUntil(
        AppPage.route(const LoginScreen()),
        (_) => false,
      );
    } on PrestamoException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo conectar con el servidor');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fecha(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar préstamo' : 'Nuevo préstamo')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _editando ? 'Actualiza los datos del préstamo' : 'Registra un préstamo nuevo',
                      style: const TextStyle(color: Color(0xFF5C726C)),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _clienteController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el cliente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.length != 8) {
                          return 'El DNI debe tener 8 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montoController,
                      focusNode: _montoFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        hintText: 'S/ 9,000.00',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (value) {
                        final monto = Money.tryParse(value ?? '');
                        if (monto == null || monto <= 0) {
                          return 'Ingresa un monto mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _interesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Interés (%)',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                      validator: (value) {
                        final interes = double.tryParse(value?.trim() ?? '');
                        if (interes == null || interes < 0) {
                          return 'Ingresa un interés válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _elegirFecha,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, color: AppTheme.teal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fecha de vencimiento', style: TextStyle(color: Color(0xFF5C726C), fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _fecha(_fechaVencimiento),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_editando) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: SwitchListTile(
                          title: const Text('Pagado'),
                          subtitle: const Text('Marca el préstamo como cobrado'),
                          value: _pagado,
                          onChanged: (value) => setState(() => _pagado = value),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Pressable(
                      child: FilledButton(
                      onPressed: _loading ? null : _guardar,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
