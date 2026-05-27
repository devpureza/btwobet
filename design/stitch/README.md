# Stitch — Bolão Copa do Mundo 2026

Exportação local dos designs gerados no Google Stitch.

## Projeto

- **Título:** Bolão Copa do Mundo 2026
- **ID:** `14895410954006795741`
- **Design System:** Unity Arena (`assets/333a74ed03214e2d96304958a5d0c627`)

## Estrutura

```
design/stitch/
├── DESIGN.md                 # Tokens e guidelines (designMd)
├── manifest.json             # Índice de telas exportadas
├── design-system/
│   ├── design-systems.json   # Resposta completa da API
│   └── style-guidelines.md
├── exports/
│   ├── boas-vindas-e-login/
│   ├── meu-historico/
│   ├── painel-de-palpites/
│   └── ranking-geral/
└── screens/                  # Metadados brutos da API (JSON)
```

Cada pasta em `exports/` contém:

- `index.html` — código HTML/Tailwind gerado pelo Stitch
- `screenshot.png` — preview da tela

## Telas exportadas

| Tela | Slug | Screen ID |
|------|------|-----------|
| Boas-vindas e Login | `boas-vindas-e-login` | `3f64d5ba200a4f428bf7b77078130920` |
| Meu Histórico | `meu-historico` | `e8a5b8877d514423be3c31576403924e` |
| Painel de Palpites | `painel-de-palpites` | `227b5c8dbd24440ab4fa7de78a002708` |
| Ranking Geral | `ranking-geral` | `83f3d3bdec7f49a9b8d70916d3552920` |

## Design System

O item "Design System" no Stitch é um **asset de design system**, não uma screen. Foi exportado via `list_design_systems` para `DESIGN.md` e `design-system/`.

## Re-exportar

Com `STITCH_API_KEY` configurada:

```bash
export STITCH_API_KEY="sua-chave"   # ou use .cursor/mcp.local.json (gitignored)
python3 scripts/export-stitch.py
```

O script baixa HTML, screenshots, imagens embutidas (`design/stitch/assets/`) e atualiza `manifest.json`. Copia `DESIGN.md` e o hero para `mobile/assets/`.

Ou via MCP HTTP:

```bash
curl -sS -X POST "https://stitch.googleapis.com/mcp" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: $STITCH_API_KEY" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_screen","arguments":{"projectId":"14895410954006795741","screenId":"SCREEN_ID"}}}'
```
