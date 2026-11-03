# SF Mentoria

Aplicação exclusiva para gestão de mentorados de concursos públicos.

## Executar

Instale Node 20+, rode `npm install` e `npm run dev` na pasta sf-mentoria.

## Status

- Interface Next.js responsiva e funcional, com alunos, concursos, metas e planejamento por disponibilidade.
- Persistência local no navegador SOMENTE para demonstração. Não cadastrar alunos reais.
- Migração SQL preliminar em `supabase/schema.sql`. Não aplicada a banco remoto.
- Login, convites, autorização de perfis e persistência Supabase aguardam integração e testes de segurança.

## Segurança

Não adicione chaves privadas ao git; use variáveis de ambiente da hospedagem. Nenhuma conexão é feita ao Supabase nesta etapa. Código em repositório público; não adicionar dados pessoais.
