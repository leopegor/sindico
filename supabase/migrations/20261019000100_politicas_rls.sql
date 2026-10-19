-- ============================================================================
-- Políticas de acesso (RLS) + grants.
--
-- O app Flutter acessa o Supabase apenas com a publishable key (sem login de
-- usuário final). Por isso as políticas liberam leitura/escrita para os papéis
-- `anon` e `authenticated`. Isso significa que qualquer portador da publishable
-- key pode ler/gravar os dados — aceitável enquanto o app for de uso interno
-- (condomínio). Se/quando houver autenticação, troque as políticas por regras
-- baseadas em `auth.uid()`.
-- ============================================================================

-- ------------------------------- unidades ---------------------------------
alter table public.unidades enable row level security;

drop policy if exists unidades_acesso_total on public.unidades;
create policy unidades_acesso_total
  on public.unidades
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- ------------------------------ competencias ------------------------------
alter table public.competencias enable row level security;

drop policy if exists competencias_acesso_total on public.competencias;
create policy competencias_acesso_total
  on public.competencias
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- ------------------------------- pagamentos -------------------------------
alter table public.pagamentos enable row level security;

drop policy if exists pagamentos_acesso_total on public.pagamentos;
create policy pagamentos_acesso_total
  on public.pagamentos
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- --------------------------- dividas_anteriores ---------------------------
alter table public.dividas_anteriores enable row level security;

drop policy if exists dividas_anteriores_acesso_total on public.dividas_anteriores;
create policy dividas_anteriores_acesso_total
  on public.dividas_anteriores
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- --------------------------- abatimentos_divida ---------------------------
alter table public.abatimentos_divida enable row level security;

drop policy if exists abatimentos_divida_acesso_total on public.abatimentos_divida;
create policy abatimentos_divida_acesso_total
  on public.abatimentos_divida
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- ------------------------------ grants ------------------------------------
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.unidades            to anon, authenticated;
grant select, insert, update, delete on public.competencias        to anon, authenticated;
grant select, insert, update, delete on public.pagamentos          to anon, authenticated;
grant select, insert, update, delete on public.dividas_anteriores  to anon, authenticated;
grant select, insert, update, delete on public.abatimentos_divida  to anon, authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;
