-- ============================================================================
-- Dados iniciais (idempotentes): 11 unidades da planilha + competência
-- histórica de Setembro/2026. Mesmos valores do seed local (unidadesPadrao e
-- Competencia.exemploSetembro2026).
-- ============================================================================

insert into public.unidades
  (codigo, nome_morador, numero_pessoas, area_privativa, fracao_ideal,
   is_sindico, participa_policiamento, valor_policiamento, tipo)
values
  ('LOJA', 'Daniel Rasia',                    0,  44.11, 0.0838, false, false, 0, 'comercial'),
  ('101',  'Adélia Kaiser Lucchese',          1, 106.61, 0.2026, false, false, 0, 'residencial'),
  ('201',  'Sandra Maria Oliveira',           1,  62.70, 0.1191, false, false, 0, 'residencial'),
  ('202',  'Diogo Perini',                    2,  38.89, 0.0739, false, false, 0, 'residencial'),
  ('203',  'Ana Cristina F. Côrtes',          2,  38.33, 0.0728, false, false, 0, 'residencial'),
  ('301',  'Ben Hur Luchese',                 2,  42.46, 0.0807, true,  false, 0, 'residencial'),
  ('302',  'Laura Sofia Ortiz Cecconello',    2,  37.20, 0.0707, false, false, 0, 'residencial'),
  ('303',  'Daniel Caravaglia',               3,  38.89, 0.0739, false, false, 0, 'residencial'),
  ('401',  'Fernanda Facchin',                4,  42.68, 0.0811, false, false, 0, 'residencial'),
  ('402',  'Marciano Rossatto',               2,  37.20, 0.0707, false, false, 0, 'residencial'),
  ('403',  'Salete Caravaglia',               1,  37.20, 0.0707, false, false, 0, 'residencial')
on conflict (codigo) do nothing;

insert into public.competencias
  (mes_referencia, ano_referencia, data_vencimento, nome_sindico, apto_sindico,
   periodo_mandato, valor_conta_agua, valor_esgoto_total, taxa_minima_agua,
   consumo_agua_m3, fmrh, consumo_energia_kwh, valor_conta_energia,
   servicos_limpeza, materiais_limpeza, limpeza_caixas_agua,
   discriminacao_outras_despesas, fundo_manutencao_mensal,
   discriminacao_fundo_manutencao, valor_apolice, numero_parcelas,
   juros_mora_mensal, multa_mora, divisor_rateio_sindico, fator_atraso,
   observacoes, criado_em)
values
  ('SETEMBRO', 2026, date '2026-10-15', 'Rosângela Lucchese', '301',
   'ago/2026 à jul/2027', 823.17, 252.78, 38.60,
   72, 0, 82, 138.37,
   800.00, 0, 360.00,
   'Limpeza de caixas d''água', 100.00,
   'Fundo de manutenções emergenciais', null, null,
   0.015, 0.02, 11, 0.95,
   null, timestamptz '2026-09-30 00:00:00-03')
on conflict (ano_referencia, mes_referencia) do nothing;
