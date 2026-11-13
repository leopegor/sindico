import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../data/backend.dart';
import 'app_drawer.dart';
import 'auth_gate.dart';
import 'navegacao.dart';

/// Layout principal da aplicação.
///
/// Mantém a navegação sempre visível: barra lateral fixa em telas largas
/// (web/desktop) e drawer em telas estreitas. As páginas da seção ativa são
/// abertas em um navegador interno, ocupando apenas a área de conteúdo — a
/// barra de navegação permanece ativa durante toda a navegação.
class AppLayout extends StatefulWidget {
  final DestinoApp secaoInicial;

  static const double breakpointDesktop = 900;

  const AppLayout({super.key, this.secaoInicial = DestinoApp.competencias});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  late DestinoApp _secao = widget.secaoInicial;
  GlobalKey<NavigatorState> _navegadorKey = GlobalKey<NavigatorState>();

  void _abrirSecao(DestinoApp destino) {
    if (destino == _secao) return;
    setState(() {
      _secao = destino;
      _navegadorKey = GlobalKey<NavigatorState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final usarRail = largura >= AppLayout.breakpointDesktop;

    final navegador = NavigatorPopHandler(
      onPopWithResult: (resultado) => _navegadorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navegadorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => _secao.criarTela(),
          settings: settings,
        ),
      ),
    );

    return ShellScope(
      secao: _secao,
      usarRail: usarRail,
      abrirSecao: _abrirSecao,
      child: usarRail
          ? Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavegacaoLateral(
                    secaoAtual: _secao,
                    estendida: largura >= 1180,
                    onSelecionar: _abrirSecao,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: navegador),
                ],
              ),
            )
          : navegador,
    );
  }
}

/// Disponibiliza o estado do layout (seção ativa e navegação) para as telas.
class ShellScope extends InheritedWidget {
  final DestinoApp secao;
  final bool usarRail;
  final ValueChanged<DestinoApp> abrirSecao;

  const ShellScope({
    super.key,
    required this.secao,
    required this.usarRail,
    required this.abrirSecao,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      secao != oldWidget.secao || usarRail != oldWidget.usarRail;
}

/// Estrutura padrão de uma página: AppBar, conteúdo centralizado e FAB.
///
/// A barra de navegação (rail/drawer) é controlada pelo [AppLayout].
class PainelScaffold extends StatelessWidget {
  final String titulo;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;
  final double larguraMaximaConteudo;
  final PreferredSizeWidget? bottom;

  const PainelScaffold({
    super.key,
    required this.titulo,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.larguraMaximaConteudo = 1100,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    final usarRail = shell?.usarRail ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const IndicadorBackend(),
          ],
        ),
        actions: actions,
        bottom: bottom,
      ),
      drawer: usarRail
          ? null
          : AppDrawer(
              secaoAtual: shell?.secao ?? DestinoApp.competencias,
              onSelecionar: shell?.abrirSecao,
            ),
      body: ConteudoCentralizado(
        larguraMaxima: larguraMaximaConteudo,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class _NavegacaoLateral extends StatelessWidget {
  final DestinoApp secaoAtual;
  final bool estendida;
  final ValueChanged<DestinoApp> onSelecionar;

  const _NavegacaoLateral({
    required this.secaoAtual,
    required this.estendida,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinos = DestinoApp.values;
    final indice = destinos.indexOf(secaoAtual);

    return NavigationRail(
      extended: estendida,
      minWidth: 72,
      minExtendedWidth: 250,
      backgroundColor: theme.colorScheme.surface,
      selectedIndex: indice < 0 ? 0 : indice,
      onDestinationSelected: (i) => onSelecionar(destinos[i]),
      leading: Padding(
        padding: EdgeInsets.fromLTRB(estendida ? 16 : 0, 20, estendida ? 16 : 0, 12),
        child: estendida
            ? SizedBox(
                width: 218,
                child: Row(
                  children: [
                    Icon(Icons.apartment, color: theme.colorScheme.primary, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evaristo Lucchese',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Gestão de Rateio',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.apartment, color: theme.colorScheme.primary),
                ),
              ),
      ),
      destinations: [
        for (final destino in destinos)
          NavigationRailDestination(
            icon: Icon(destino.icone),
            selectedIcon: Icon(destino.icone, color: theme.colorScheme.primary),
            label: Text(destino.titulo),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
      ],
      trailing: AuthScope.maybeOf(context) == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                tooltip: 'Sair',
                icon: const Icon(Icons.logout),
                onPressed: () => AuthScope.maybeOf(context)?.sair(),
              ),
            ),
    );
  }
}

/// Centraliza o conteúdo limitando sua largura máxima em telas largas.
class ConteudoCentralizado extends StatelessWidget {
  final Widget child;
  final double larguraMaxima;

  const ConteudoCentralizado({
    super.key,
    required this.child,
    this.larguraMaxima = 1100,
  });

  @override
  Widget build(BuildContext context) {
    if (!larguraMaxima.isFinite) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: child,
      ),
    );
  }
}

/// Chip na barra superior indicando de onde vêm os dados (Supabase ou local).
class IndicadorBackend extends StatelessWidget {
  const IndicadorBackend({super.key});

  Color get _cor => Backend.usaSupabase
      ? const Color(0xFF2E7D32)
      : const Color(0xFFB26A00);

  String get _rotulo => Backend.usaSupabase ? 'Supabase' : 'Local';

  String get _detalhe {
    if (Backend.usaSupabase) {
      return 'Dados salvos no Supabase (nuvem) em ${SupabaseConfig.url}.';
    }
    return Backend.motivoModoLocal ??
        'Supabase indisponível: os dados são salvos apenas neste dispositivo.';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _detalhe,
      child: ActionChip(
        avatar: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _cor, shape: BoxShape.circle),
        ),
        label: Text(
          _rotulo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _cor,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(_detalhe)));
        },
      ),
    );
  }
}
