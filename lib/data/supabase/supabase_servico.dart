import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../backend.dart';
import '../erro_persistencia.dart';

/// Inicialização e acesso ao cliente Supabase.
class SupabaseServico {
  const SupabaseServico._();

  /// Inicializa o SDK e marca o backend remoto como ativo.
  ///
  /// Em caso de falha o app continua funcionando com o banco local (SQLite),
  /// registrando o motivo em [Backend.motivoModoLocal].
  static Future<void> inicializar() async {
    if (!SupabaseConfig.ativo) {
      Backend.modo = BackendModo.local;
      Backend.motivoModoLocal = 'Supabase desativado por configuração.';
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      Backend.modo = BackendModo.supabase;
      Backend.motivoModoLocal = null;
      debugPrint('Supabase conectado: ${SupabaseConfig.url}');
    } catch (e) {
      Backend.modo = BackendModo.local;
      Backend.motivoModoLocal = 'Não foi possível conectar ao Supabase. '
          'Os dados serão salvos apenas neste dispositivo.';
      debugPrint('Falha ao inicializar o Supabase: $e');
    }
  }

  static SupabaseClient get client => _clienteInjetado ?? Supabase.instance.client;

  static SupabaseClient? _clienteInjetado;

  /// Permite injetar um cliente próprio (scripts, testes e ambientes sem o
  /// plugin `supabase_flutter` inicializado). Passe `null` para voltar ao
  /// cliente global do SDK.
  static void injetarCliente(SupabaseClient? cliente) {
    _clienteInjetado = cliente;
  }

  static SupabaseQueryBuilder tabela(String nome) => client.from(nome);

  /// Executa uma operação remota traduzindo falhas de rede/servidor para
  /// [ErroPersistencia] com mensagem amigável.
  static Future<T> executar<T>(
    Future<T> Function() acao, {
    String contexto = 'acessar os dados',
  }) async {
    try {
      return await acao();
    } on ErroPersistencia {
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException ao $contexto: ${e.message} (code ${e.code})');
      throw ErroPersistencia(
        'O servidor recusou a operação ($contexto). ${_dica(e)}',
        causa: e,
      );
    } on TimeoutException catch (e) {
      throw ErroPersistencia(
        'O servidor demorou demais para responder ao $contexto. Tente novamente.',
        causa: e,
      );
    } catch (e) {
      debugPrint('Erro inesperado ao $contexto: $e');
      if (_pareceFalhaDeRede(e)) {
        throw ErroPersistencia(
          'Sem conexão com o servidor ao $contexto. Verifique sua internet e tente novamente.',
          causa: e,
        );
      }
      throw ErroPersistencia('Erro inesperado ao $contexto.', causa: e);
    }
  }

  /// Detecta erros de rede de forma multiplataforma (web não tem dart:io).
  static bool _pareceFalhaDeRede(Object e) {
    final texto = e.toString().toLowerCase();
    return texto.contains('socketexception') ||
        texto.contains('failed host lookup') ||
        texto.contains('connection closed') ||
        texto.contains('connection refused') ||
        texto.contains('network') ||
        texto.contains('xmlhttprequest error') ||
        texto.contains('fetch');
  }

  static String _dica(PostgrestException e) {
    final mensagem = e.message.toLowerCase();
    if (mensagem.contains('duplicate key')) {
      return 'Já existe um registro com esses mesmos dados.';
    }
    if (mensagem.contains('violates foreign key')) {
      return 'O registro está vinculado a outros dados ou não existe.';
    }
    if (mensagem.contains('violates check constraint')) {
      return 'Algum valor enviado não é aceito pelo servidor.';
    }
    if (mensagem.contains('permission denied') || e.code == '42501') {
      return 'O acesso a esta tabela não está liberado.';
    }
    return 'Tente novamente; se persistir, verifique o banco no painel do Supabase.';
  }
}
