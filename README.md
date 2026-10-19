# Aplicativo de Gestão de Rateio e Recibos Condominiais (Condomínio Evaristo Lucchese)

Aplicativo Android desenvolvido em **Flutter/Dart** para automatizar o rateio mensal de despesas, emissão de demonstrativos contábeis e geração dos 11 recibos individuais de condomínio com 7 faixas de vencimento e mora, baseado rigorosamente nas regras de negócio da aba `DADO_RECIBOS`.

---

## 1. Objetivo do Aplicativo

Substituir o processo manual em planilha por uma ferramenta móvel acessível, confiável, offline-first e auditável, permitindo ao síndico:
- Lançar mensalmente as faturas de consumo (Água/CORSAN, Energia/RGE, Limpeza, Caixas d'água, Fundo Emergencial e Seguro).
- Ratear com exatidão matemática cada despesa conforme a convenção (por pessoa, por unidade pagante ou com isenções específicas).
- Conferir instantaneamente o fechamento contábil de 100% dos valores lançados (Checklist da Linha 67 da planilha).
- Emitir e visualizar os 11 recibos individuais prontos para impressão ou compartilhamento digital (WhatsApp, e-mail, PDF).
- Manter histórico das competências e preservar o cadastro dos moradores e frações ideais com backup seguro.

---

## 2. Funcionalidades Disponíveis

- **Painel de Competências Mensais:**
  - Histórico de lançamentos por mês e ano.
  - Semente inicial automática com os dados de **Setembro/2026** idênticos à planilha documentada.
  - Ações rápidas: Demonstrativo Completo, Lista dos 11 Recibos, Geração de PDF e Edição.

- **Lançamento com Orientação Contextual em 100% dos Campos:**
  - Todo campo possui botão de ajuda contextual detalhando: *Nome, Finalidade, Onde encontrar na fatura física, Instrução de preenchimento, Exemplo, Formato, Obrigatoriedade, Regra de validação e Efeito no rateio*.
  - Validação em tempo real com mensagens claras em português.
  - Card de conferência contábil em tempo real na tela de formulário (Linha 67).

- **Demonstrativo Geral de Rateio (Worksheet Completa):**
  - Tabela comparativa com as 11 unidades (Loja + 10 apartamentos).
  - Discriminação de cada rubrica: Água, Luz, Limpeza, Seguro, Outros, Fundo, Rateio do Síndico e Total no Vencimento.
  - Alternador para exibir as linhas de atraso (valores com divisor 0,95).
  - Linha de conferência de totais consolidada.

- **11 Recibos Individuais Prontos:**
  - Visualização formatada conforme o modelo impresso.
  - Quadro de itens detalhado no vencimento.
  - Escala das 7 faixas de vencimento e mora (Vencimento, até 30d, 30-60d com multa de 2% e juros de 1,5% a.m., e progressão mensal até 180 dias).
  - Discriminação de locatário vs proprietário para a Loja comercial.
  - Quadro de transparência com os dados de base do cálculo.
  - Canhoto de quitação e assinatura.

- **Exportação e Impressão em PDF (A4):**
  - Geração nativa de PDF de alta fidelidade para as 11 unidades ou individual por unidade.
  - Pré-visualização com zoom, compartilhamento direto (WhatsApp/e-mail) e envio para impressoras Wi-Fi no Android.

- **Gestão do Cadastro de Unidades:**
  - Edição de moradores, quantidade de residentes, área privativa (m²) e policiamento comunitário.
  - Seleção da unidade do síndico em exercício com atribuição automática da isenção operacional.
  - Opção de restaurar o cadastro para o padrão histórico da planilha.

- **Backup e Restauração Segura:**
  - Exportação de arquivo JSON estruturado com assinatura criptográfica SHA-256.
  - Validação contra arquivos corrompidos ou adulterados.
  - Instruções de segurança sobre retenção de dados locais.

---

## 3. Tecnologias Utilizadas

- **Framework:** Flutter 3.47.5
- **Linguagem:** Dart 3.13.4
- **Persistência na Nuvem:** Supabase (PostgreSQL) via `supabase_flutter` — backend principal
- **Persistência Local (fallback):** SQLite via `sqflite` (usada quando o Supabase está indisponível)
- **Localização:** `flutter_localizations` e `intl` (pt_BR)
- **Geração e Impressão de Documentos:** `pdf` e `printing`
- **Compartilhamento de Arquivos:** `share_plus`
- **Segurança de Dados:** `crypto` (Checksum SHA-256)

---

## 4. Pré-requisitos e Configuração do Ambiente

### Pré-requisitos
- Flutter SDK 3.47+ instalado e configurado no PATH.
- Android SDK Platform 34+ com ferramentas de build.
- Dispositivo Android (ou emulador) com modo desenvolvedor/depuração USB ativado.

### Configuração
Clone ou acerte as dependências no diretório do projeto:
```bash
flutter pub get
```

---

## 5. Como Executar no Android

### Emulador ou Dispositivo Físico Conectado
1. Conecte o dispositivo via USB (verifique com `adb devices` ou `flutter devices`).
2. Execute o aplicativo em modo de depuração:
```bash
flutter run
```

---

## 6. Como Gerar uma Versão Instalável (APK)

Para gerar o pacote de instalação `.apk` para Android:

### Modo Debug (para testes imediatos no aparelho):
```bash
flutter build apk --debug
```
O arquivo gerado estará em:
`build/app/outputs/flutter-apk/app-debug.apk`

### Modo Release (versão final otimizada):
```bash
flutter build apk --release
```
O arquivo gerado estará em:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 7. Como Executar os Testes Automatizados

Para rodar toda a suíte de testes unitários e de widgets:
```bash
flutter test
```

Para executar a análise estática completa de código:
```bash
flutter analyze
```

Teste de integração real contra o Supabase (usa dados de teste e os remove ao
final; desativado por padrão):
```bash
flutter test test/supabase_live_test.dart --dart-define=SUPABASE_LIVE=true
```

---

## 8. Persistência de Dados (Supabase e SQLite local)

O aplicativo usa o **Supabase (PostgreSQL)** como fonte de dados principal. Se a
conexão falhar na inicialização, ele continua funcionando com o banco **SQLite
local** (`sindico_evaristo_lucchese.db`), sem interromper o uso.

- **Indicador na barra superior:** um chip mostra `Supabase` (nuvem) ou `Local`
  (offline). Toque nele para ver o motivo do modo local.
- **Esquema do banco remoto:** definido em `supabase/migrations/`
  (`schema_inicial`, `politicas_rls`, `seed_dados_iniciais`), aplicado via
  `npx supabase db push --db-url "<connection-string>"`.
- **Acesso:** as políticas de RLS liberam leitura/escrita para os papéis `anon`
  e `authenticated` (o app não possui login de usuário final — qualquer portador
  da publishable key acessa os dados do condomínio).
- **Repositórios:** as telas usam as fachadas `CompetenciaRepository`,
  `UnidadeRepository`, `PagamentoRepository` e `DividaRepository`, que escolhem
  automaticamente o backend (Supabase ou SQLite) conforme `Backend.usaSupabase`.
- **Configuração por build (opcional):**
  ```bash
  flutter run --dart-define=SUPABASE_URL=... \
              --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
              --dart-define=SUPABASE_ATIVO=true
  ```
  Use `--dart-define=SUPABASE_ATIVO=false` para forçar o modo local.
- **Backup:** exporta/restaura JSON (checksum SHA-256) a partir dos dados do
  backend ativo — funciona igual em nuvem e offline.

---

## 9. Tratamento de Erros e Prevenção de Falhas

- **Validações Pré-persistência:** Nenhuma despesa ou competência é gravada se houver campos obrigatórios vazios ou valores negativos inconsistentes.
- **Tolerância a Arredondamentos:** O sistema de conferência da Linha 67 trabalha com validação centesimal, evitando divergências por dízimas em divisões por 11 ou 20.
- **Diálogos de Confirmação:** A exclusão de competências e a restauração do cadastro exigem confirmação explícita do usuário.
- **Preservação de Dados Digitados:** O formulário mantém os dados em memória enquanto o usuário corrige eventuais erros.

---

## 10. Limitações Conhecidas e Procedimentos de Preservação de Dados

- **Dados compartilhados na nuvem:** com o Supabase ativo, os dados ficam no PostgreSQL remoto e são acessíveis de qualquer dispositivo que use a mesma publishable key (não há login por usuário).
- **Modo local (fallback):** sem conexão, o app grava no SQLite do dispositivo; esses lançamentos não são enviados automaticamente para a nuvem depois.
- **Risco de Perda por Desinstalação:** no modo local, desinstalar o aplicativo apaga os dados salvos no aparelho (na nuvem os dados permanecem).
- **Procedimento Obrigatório de Backup:** mesmo com o Supabase ativo, recomenda-se usar a tela de **Backup e Segurança** ao final de cada mês, exportando o arquivo JSON para o Google Drive, e-mail pessoal ou computador.

---

## 11. Decisões Técnicas sobre as Inconsistências da Planilha

Conforme detalhado na seção 9 da documentação original:
1. **Recibo do Apto 302:** Na planilha original, a fórmula somava uma coluna errada gerando total zerado no quadro de itens. No aplicativo, o cálculo soma corretamente todas as despesas da unidade.
2. **Caixas d'água:** Na planilha original, vários recibos referenciavam a linha da Loja (`I45`). No aplicativo, cada unidade exibe seu rateio real.
3. **Quadro de Itens do Síndico:** O síndico visualiza com total transparência que sua cota operacional é coberta pelo rateio dos condôminos, pagando no vencimento apenas o fundo de reserva (R$ 100,00).
4. **Divisor do Rateio do Síndico (10 vs 11):** O aplicativo disponibiliza um seletor configurável permitindo optar entre o legado da planilha (divisão por 11) ou o fechamento financeiro exato de 100% (divisão pelos 10 pagantes).
5. **Multa de 2% vs Texto de 10%:** O aplicativo aplica a taxa legal vigente do Código Civil (2,00%), e o texto impresso no recibo reflete dinamicamente a alíquota cadastrada.
