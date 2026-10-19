/// Configuração de acesso ao Supabase.
///
/// Os valores podem ser sobrescritos em tempo de build:
/// `flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gpgasyauidcidxyxknio.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_1ofFhfTu4R8lPZH_HQazqQ_ADof-MDN',
  );

  /// Quando `true` (padrão), o app tenta usar o Supabase como fonte de dados.
  /// Use `--dart-define=SUPABASE_ATIVO=false` para forçar o modo local (SQLite).
  static const bool ativo = bool.fromEnvironment(
    'SUPABASE_ATIVO',
    defaultValue: true,
  );
}
