import 'package:material_ui/material_ui.dart';

import '../models/prestamo.dart';
import '../services/auth_service.dart';
import '../services/prestamo_service.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';
import 'prestamo_form_screen.dart';

class ListaPrestamosScreen extends StatefulWidget {
  const ListaPrestamosScreen({super.key, this.reloadToken = 0});

  final int reloadToken;

  @override
  State<ListaPrestamosScreen> createState() => _ListaPrestamosScreenState();
}

class _ListaPrestamosScreenState extends State<ListaPrestamosScreen> {
  final _service = PrestamoService();
  final _authService = AuthService();
  List<Prestamo> _prestamos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ListaPrestamosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prestamos = await _service.listar();
      if (!mounted) {
        return;
      }
      setState(() => _prestamos = prestamos);
    } on SessionExpiredException catch (error) {
      await _cerrarSesion(error.message);
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

  Future<void> _abrirFormulario([Prestamo? prestamo]) async {
    final saved = await Navigator.of(context).push<bool>(
      AppPage.route(PrestamoFormScreen(prestamo: prestamo)),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _marcarPagado(Prestamo prestamo) async {
    try {
      await _service.marcarPagado(prestamo.id);
      if (!mounted) {
        return;
      }
      _showMessage('${prestamo.cliente} quedó marcado como pagado');
      await _load();
    } on SessionExpiredException catch (error) {
      await _cerrarSesion(error.message);
    } on PrestamoException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo conectar con el servidor');
    }
  }

  Future<void> _eliminar(Prestamo prestamo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar préstamo'),
          content: Text('Se eliminará el préstamo de ${prestamo.cliente}.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await _service.eliminar(prestamo.id);
      if (!mounted) {
        return;
      }
      _showMessage('Préstamo eliminado');
      await _load();
    } on SessionExpiredException catch (error) {
      await _cerrarSesion(error.message);
    } on PrestamoException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('No se pudo conectar con el servidor');
    }
  }

  Future<void> _cerrarSesion([String? message]) async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    if (message != null) {
      _showMessage(message);
    }
    Navigator.of(context).pushAndRemoveUntil(
      AppPage.route(const LoginScreen()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _fecha(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _monto(double value) => Money.format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gota a Gota'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _cerrarSesion(),
              tooltip: 'Cerrar sesión',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.forest,
              ),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: Pressable(
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo'),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 840;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: _prestamos.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                                children: const [
                                  _EmptyLoans(),
                                ],
                              )
                            : CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                                      child: _SummaryCard(prestamos: _prestamos, monto: _monto),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: wide ? 2 : 1,
                                        mainAxisExtent: 196,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final prestamo = _prestamos[index];
                                          return Appear(
                                            index: index,
                                            child: _PrestamoCard(
                                              prestamo: prestamo,
                                              monto: _monto(prestamo.monto),
                                              total: _monto(prestamo.totalACobrar),
                                              vencimiento: _fecha(prestamo.fechaVencimiento),
                                              onOpen: () => _abrirFormulario(prestamo),
                                              onPay: prestamo.pagado ? null : () => _marcarPagado(prestamo),
                                              onDelete: () => _eliminar(prestamo),
                                            ),
                                          );
                                        },
                                        childCount: _prestamos.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0x140D7377), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 20),
        Text('Todavía no hay préstamos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Cuando registres uno, verás el cliente, el monto\ny lo que queda por cobrar.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF667085), height: 1.4),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.prestamos, required this.monto});

  final List<Prestamo> prestamos;
  final String Function(double) monto;

  @override
  Widget build(BuildContext context) {
    final prestado = prestamos.fold<double>(0, (sum, item) => sum + item.monto);
    final porCobrar = prestamos.where((item) => !item.pagado).fold<double>(0, (sum, item) => sum + item.totalACobrar);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x2A00695C), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _SummaryValue(label: 'Total prestado', value: monto(prestado))),
          Container(width: 1, height: 42, color: const Color(0x33FFFFFF)),
          Expanded(child: _SummaryValue(label: 'Por cobrar', value: monto(porCobrar), alignEnd: true)),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFD7F3F1), fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PrestamoCard extends StatelessWidget {
  const _PrestamoCard({
    required this.prestamo,
    required this.monto,
    required this.total,
    required this.vencimiento,
    required this.onOpen,
    required this.onDelete,
    this.onPay,
  });

  final Prestamo prestamo;
  final String monto;
  final String total;
  final String vencimiento;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final pagado = prestamo.pagado;
    return Material(
      color: pagado ? const Color(0xFFF3FAF7) : Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        onLongPress: onDelete,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pagado ? const Color(0xFFCDE5DC) : AppTheme.line),
            boxShadow: const [
              BoxShadow(color: Color(0x1400695C), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        prestamo.cliente,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forest,
                        ),
                      ),
                    ),
                    _StatusBadge(pagado: pagado),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _Amount(label: 'Monto', value: monto)),
                    Expanded(child: _Amount(label: 'Total a cobrar', value: total)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 16, color: Color(0xFF5C726C)),
                    const SizedBox(width: 6),
                    Text(
                      'Vence $vencimiento',
                      style: const TextStyle(color: Color(0xFF5C726C)),
                    ),
                    const Spacer(),
                    if (onPay != null)
                      IconButton(
                        tooltip: 'Marcar pagado',
                        onPressed: onPay,
                        icon: const Icon(Icons.task_alt_rounded),
                      ),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5C726C), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.pagado});

  final bool pagado;

  @override
  Widget build(BuildContext context) {
    final color = pagado ? const Color(0xFF1B7F4E) : const Color(0xFFC56A16);
    final background = pagado ? const Color(0xFFE5F6EE) : const Color(0xFFFFF1E4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pagado ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            pagado ? 'Pagado' : 'Pendiente',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
