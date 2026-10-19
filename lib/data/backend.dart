/// Define de onde os dados do condomínio são lidos/gravados.
enum BackendModo {
  /// SQLite local (padrão de segurança quando o Supabase não está disponível).
  local,

  /// Banco de dados remoto no Supabase (Postgres).
  supabase,
}

/// Estado global do backend ativo.
///
/// O app inicia em [BackendModo.local] e passa para [BackendModo.supabase]
/// depois que [SupabaseBootstrap.inicializar] conseguir conectar com sucesso.
class Backend {
  const Backend._();

  static BackendModo modo = BackendModo.local;

  static bool get usaSupabase => modo == BackendModo.supabase;

  /// Motivo pelo qual o Supabase não está sendo usado (para exibir na UI).
  static String? motivoModoLocal;
}
