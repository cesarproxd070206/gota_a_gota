import 'package:material_ui/material_ui.dart';

import '../models/prestamo.dart';
import '../services/auth_service.dart';
import '../services/prestamo_service.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../widgets/motion.dart';
import 'login_screen.dart';
import 'prestamo_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onSeeAll,
    required this.onLoansChanged,
    this.nombre,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onLoansChanged;
  final String? nombre;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = PrestamoService();
  List<Prestamo> _prestamos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prestamos = await _service.listar();
      if (!mounted) {
        return;
      }
      prestamos.sort((a, b) => b.id.compareTo(a.id));
      setState(() => _prestamos = prestamos);
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

  Future<void> _nuevo() async {
    final saved = await Navigator.of(context).push<bool>(
      AppPage.route(const PrestamoFormScreen()),
    );
    if (saved == true) {
      widget.onLoansChanged();
      await _load();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final prestado = _prestamos.fold<double>(0, (sum, item) => sum + item.monto);
    final porCobrar = _prestamos.where((item) => !item.pagado).fold<double>(0, (sum, item) => sum + item.totalACobrar);
    final ganancia = porCobrar - prestado;
    final activos = _prestamos.where((item) => !item.pagado).length;
    final cobrados = _prestamos.where((item) => item.pagado).length;
    final progreso = _prestamos.isEmpty ? 0.0 : cobrados / _prestamos.length;
    final recientes = _prestamos.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        Appear(index: 0, child: _Greeting(nombre: widget.nombre)),
                        const SizedBox(height: 18),
                        Appear(
                          index: 1,
                          child: _ProgressCard(progress: progreso, cobrados: cobrados, total: _prestamos.length),
                        ),
                        const SizedBox(height: 16),
                        Appear(
                          index: 2,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 720;
                              final cards = [
                                _MetricCard(label: 'Total prestado', value: Money.format(prestado), icon: Icons.payments_rounded),
                                _MetricCard(label: 'Por cobrar', value: Money.format(porCobrar), icon: Icons.account_balance_wallet_rounded),
                                _MetricCard(label: 'Ganancia esperada', value: Money.format(ganancia), icon: Icons.trending_up_rounded),
                                _MetricCard(label: 'Préstamos activos', value: '$activos', icon: Icons.pending_actions_rounded, money: false),
                              ];
                              if (!wide) {
                                return Column(
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 12),
                                      cards[i],
                                    ],
                                  ],
                                );
                              }
                              return GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.4,
                                children: cards,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Appear(
                          index: 3,
                          child: Row(
                            children: [
                              Expanded(
                                child: Pressable(
                                  child: FilledButton.icon(
                                    onPressed: _nuevo,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Nuevo préstamo'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Pressable(
                                  child: OutlinedButton.icon(
                                    onPressed: widget.onSeeAll,
                                    icon: const Icon(Icons.list_alt_rounded),
                                    label: const Text('Ver todos'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text('Últimos préstamos', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        if (recientes.isEmpty)
                          const _EmptyHint()
                        else
                          for (var i = 0; i < recientes.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            Appear(index: 4 + i, child: _MiniLoan(prestamo: recientes[i])),
                          ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final saludo = nombre == null || nombre!.trim().isEmpty ? 'Bienvenido' : 'Hola, ${nombre!.trim()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(saludo, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text(
          'Así está tu cartera hoy.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.cobrados, required this.total});

  final double progress;
  final int cobrados;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: const Color(0x33FFFFFF),
                  color: const Color(0xFFE8C872),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cobrado', style: TextStyle(color: Color(0xFFD7F3F1), fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '$cobrados de $total préstamos',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.money = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(color: Color(0x1200695C), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: money ? 16 : 22,
                    color: AppTheme.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLoan extends StatelessWidget {
  const _MiniLoan({required this.prestamo});

  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) {
    final pagado = prestamo.pagado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x1000695C), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prestamo.cliente, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.forest)),
                const SizedBox(height: 2),
                Text(Money.format(prestamo.totalACobrar), style: const TextStyle(color: Color(0xFF667085))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pagado ? const Color(0xFFE5F6EE) : const Color(0xFFFFF1E4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pagado ? 'Pagado' : 'Pendiente',
              style: TextStyle(
                color: pagado ? const Color(0xFF1B7F4E) : const Color(0xFFC56A16),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.water_drop_outlined, color: AppTheme.teal),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todavía no hay préstamos. Crea el primero con Nuevo préstamo.',
              style: TextStyle(color: Color(0xFF667085)),
            ),
          ),
        ],
      ),
    );
  }
}
