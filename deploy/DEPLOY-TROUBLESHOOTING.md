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
