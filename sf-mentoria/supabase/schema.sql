-- SF Mentoria — esquema inicial para revisão em ambiente de desenvolvimento.
-- Não executar em produção sem testes de RLS e revisão de permissões.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null check(length(full_name) between 2 and 120),
 role text not null default 'student' check(role in ('mentor','student')),
 created_at timestamptz not null default now()
);
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(title) between 3 and 160),
 exam_date date,
 created_at timestamptz not null default now()
);
create table if not exists public.topics (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exams(id) on delete cascade,
 title text not null,
 weight numeric(6,2) not null default 1 check(weight>0),
 position integer not null default 0,
 unique(exam_id,title)
);
create table if not exists public.enrollments (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 exam_id uuid not null references public.exams(id),
 daily_minutes integer not null default 120 check(daily_minutes between 20 and 720),
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(student_id,exam_id)
);
create table if not exists public.study_plans (
 id uuid primary key default gen_random_uuid(),
 enrollment_id uuid not null references public.enrollments(id) on delete cascade,
 version integer not null check(version>0),
 status text not null default 'draft' check(status in ('draft','published','archived')),
 created_at timestamptz not null default now(),
 unique(enrollment_id,version)
);
create table if not exists public.study_tasks (
 id uuid primary key default gen_random_uuid(),
 study_plan_id uuid not null references public.study_plans(id) on delete cascade,
 topic_id uuid not null references public.topics(id),
 scheduled_for date not null,
 kind text not null check(kind in ('theory','questions','review','simulation')),
 estimated_minutes integer not null check(estimated_minutes between 10 and 720),
 completed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.study_sessions (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 task_id uuid references public.study_tasks(id),
 actual_minutes integer not null check(actual_minutes between 1 and 720),
 occurred_at timestamptz not null default now()
);
create table if not exists public.question_results (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.profiles(id) on delete cascade,
 topic_id uuid not null references public.topics(id),
 total integer not null check(total>0),
 correct integer not null check(correct>=0 and correct<=total),
 occurred_at timestamptz not null default now()
);
create index if not exists idx_topics_exam on public.topics(exam_id);
create index if not exists idx_enrollments_student on public.enrollments(student_id);
create index if not exists idx_tasks_plan_date on public.study_tasks(study_plan_id,scheduled_for);
create index if not exists idx_sessions_student_date on public.study_sessions(student_id,occurred_at);
create index if not exists idx_results_student_topic on public.question_results(student_id,topic_id);

alter table public.profiles enable row level security;
alter table public.exams enable row level security;
alter table public.topics enable row level security;
alter table public.enrollments enable row level security;
alter table public.study_plans enable row level security;
alter table public.study_tasks enable row level security;
alter table public.study_sessions enable row level security;
alter table public.question_results enable row level security;

-- Mentor é definido exclusivamente por app_metadata (não user_metadata).
-- Somente backend administrativo confiável poderá atribuir app_metadata.role.
create policy profiles_select on public.profiles for select to authenticated
 using (id=(select auth.uid()) or (auth.jwt()->'app_metadata'->>'role'='mentor'));
create policy exams_select on public.exams for select to authenticated
 using ((auth.jwt()->'app_metadata'->>'role'='mentor') or exists(select 1 from public.enrollments e where e.exam_id=exams.id and e.student_id=(select auth.uid())));
create policy topics_select on public.topics for select to authenticated
 using ((auth.jwt()->'app_metadata'->>'role'='mentor') or exists(select 1 from public.enrollments e where e.exam_id=topics.exam_id and e.student_id=(select auth.uid())));
create policy enrollments_select on public.enrollments for select to authenticated
 using(student_id=(select auth.uid()) or auth.jwt()->'app_metadata'->>'role'='mentor');
create policy plans_select on public.study_plans for select to authenticated
 using(auth.jwt()->'app_metadata'->>'role'='mentor' or exists(select 1 from public.enrollments e where e.id=study_plans.enrollment_id and e.student_id=(select auth.uid()) and study_plans.status='published'));
create policy tasks_select on public.study_tasks for select to authenticated
 using(auth.jwt()->'app_metadata'->>'role'='mentor' or exists(select 1 from public.study_plans p join public.enrollments e on e.id=p.enrollment_id where p.id=study_tasks.study_plan_id and e.student_id=(select auth.uid()) and p.status='published'));
create policy sessions_select on public.study_sessions for select to authenticated
 using(student_id=(select auth.uid()) or auth.jwt()->'app_metadata'->>'role'='mentor');
create policy results_select on public.question_results for select to authenticated
 using(student_id=(select auth.uid()) or auth.jwt()->'app_metadata'->>'role'='mentor');

-- Por segurança, escritas administrativas ficam exclusivamente em endpoints server-side
-- autenticados e autorizados. Não há policies de insert/update/delete para os clientes.
-- As políticas de gravação pelo aluno deverão ser incluídas após testes de isolamento.
