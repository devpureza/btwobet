# Deploy EC2 — troubleshooting

## Sintoma: site em produção sem UI nova (ex.: card "Regras do bolão")

1. Confirme que `main` tem o commit com o código Flutter.
2. Abra **Actions → Deploy EC2** no GitHub. O job deve terminar **success**.
3. Se falhar em **Sync files to EC2**: verifique secrets `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY` (chave privada PEM completa, sem passphrase se possível). Teste SSH manual do seu Mac.
4. Se falhar em **Deploy on EC2**: SSH na instância, `cd /opt/btwobet`, rode `./deploy/remote-deploy.sh` e leia o erro do Docker.
5. Após deploy OK, valide:
   ```bash
   curl -sS https://btwobet.click/main.dart.js | grep -c 'Regras do bol'
   ```
   Deve retornar `1` ou mais. `0` = bundle antigo ainda no servidor.
6. No navegador: **Ctrl+Shift+R** (hard refresh). O app desregistra service worker antigo, mas o JS precisa estar atualizado no servidor.

## Como o Flutter chega no nginx

- CI roda `flutter build web` em `mobile/` (artefato **não** vai pro git).
- `rsync` copia `mobile/build/web/` para `/opt/btwobet/mobile/build/web/` na EC2.
- `docker-compose.prod.yml` monta `./mobile/build/web` em `nginx:/usr/share/nginx/html`.

Rebuild manual na EC2 (emergência):

```bash
cd /opt/btwobet/mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://btwobet.click/api
cd /opt/btwobet && ./deploy/remote-deploy.sh
```

## Variável `APP_URL` (GitHub → Settings → Variables)

Defina `APP_URL=https://btwobet.click` para o build web apontar à API correta.

## Atualizar só o Flutter Web (sem tocar no PostgreSQL)

O diretório `mobile/build/web/` **não vai para o git** (`mobile/build/` no `.gitignore`). `git pull` atualiza o código-fonte, **não** o que o nginx serve.

### Procedimento seguro na EC2

```bash
cd /opt/btwobet
git pull origin main
./deploy/flutter-web-prod.sh
```

Com Flutter instalado na máquina, o script faz `flutter build web` e reinicia **somente** o container `nginx`.

### Build local + envio do bundle (sem Flutter na EC2)

No Mac (ajuste host/usuário/chave):

```bash
cd /caminho/para/btwobet
git pull origin main
cd mobile
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://btwobet.click/api
rsync -azv --delete build/web/ ubuntu@SEU_IP:/opt/btwobet/mobile/build/web/
ssh -i sua-chave.pem ubuntu@SEU_IP \
  'cd /opt/btwobet && docker compose -f docker-compose.prod.yml --env-file .env.production restart nginx'
```

### Deploy completo (backend + Flutter via CI)

GitHub Actions **Deploy EC2**: build Flutter, rsync do repo inteiro, `./deploy/remote-deploy.sh` (rebuild app, `migrate --force`). O volume `postgres_data` **permanece**; evite `RUN_SEED=true` após o primeiro deploy.

### Nunca rode em produção (perda ou sobrescrita de dados)

| Comando | Risco |
|---------|--------|
| `docker compose down -v` | Apaga volume `postgres_data` |
| `docker volume rm ... postgres_data` | Idem |
| `php artisan worldcup:import-openfootball` | Reimporta/apaga dados de jogos conforme implementação |
| `php artisan db:seed --force` com `RUN_SEED=true` no app | Roda seeders de novo no container |
| Reset administrativo destrutivo / scripts de “reset bolão” | Apaga palpites/usuários conforme o comando |

`./deploy/remote-deploy.sh` é seguro para o **banco** (não usa `-v`), mas **não** use quando a intenção for só atualizar o front — prefira `./deploy/flutter-web-prod.sh`.
