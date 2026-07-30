import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import 'dashboard_screen.dart';
import 'trade_history_screen.dart';

/// MainScreen actúa como el contenedor de navegación principal con menú lateral Drawer y botón de Logout.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TradeHistoryScreen(),
    DashboardScreen(),
  ];

  void _confirmLogout(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.lossColor),
            SizedBox(width: 10),
            Text('Cerrar Sesión'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de la cuenta de $username? Deberás iniciar sesión de nuevo para acceder a tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lossColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
            },
            label: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final username = authState is Authenticated ? authState.user.username : 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_circle_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'Trading Journal ($username)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Botón de Logout directo en la barra superior
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _confirmLogout(context, username),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.lossColor, size: 20),
              label: const Text(
                'Salir',
                style: TextStyle(
                  color: AppTheme.lossColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.lossColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),

      // Menú Lateral (Drawer) con información de usuario y Logout
      drawer: Drawer(
        backgroundColor: AppTheme.backgroundColor,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.surfaceColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              accountName: Text(
                username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              accountEmail: const Text(
                'Sesión Autenticada',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.format_list_bulleted_rounded, color: AppTheme.primaryColor),
              title: const Text('Historial de Trades'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart_rounded, color: AppTheme.primaryColor),
              title: const Text('Dashboard Estadístico'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(color: AppTheme.cardColor),

            // Botón destacado de Cerrar Sesión en el menú lateral
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppTheme.lossColor.withValues(alpha: 0.15),
                leading: const Icon(Icons.logout_rounded, color: AppTheme.lossColor),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: AppTheme.lossColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout(context, username);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_rounded),
            activeIcon: Icon(Icons.format_list_bulleted_rounded),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded),
            activeIcon: Icon(Icons.pie_chart_rounded),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
