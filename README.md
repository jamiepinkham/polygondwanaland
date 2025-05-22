# 🏰 Polygondwanaland

**Polygondwanaland** is a modular, manifest-driven infrastructure platform for self-hosted applications. It combines secrets management, observability, and private networking via [1Password Connect](https://developer.1password.com/docs/connect), [Grafana](https://grafana.com/), and [Tailscale](https://tailscale.com/).

The entire system is orchestrated with a custom CLI called `castle`.

---

## ✨ Features

- 🔒 **Secrets Management** with 1Password Connect
- 📈 **Observability Stack** (Grafana, Loki, Tempo)
- 🕵️‍♀️ **Private App Hosting** with Tailscale + tsdproxy
- 📦 **Manifest-based Deployment** per project/environment
- 🧰 **CLI-Driven Workflow** using the `castle` command

---

## 🧱 Directory Structure

```
castle/
├── castle.sh          # main CLI dispatcher
├── lib.sh             # shared functions for all helpers
└── helpers/
    ├── up.sh
    ├── down.sh
    ├── proxy_config.sh
    └── setup.sh

manifest.yml           # defines projects to deploy
```

---

## 🚀 Getting Started

### 1. Prerequisites

- Docker + Docker Compose
- [1Password CLI](https://developer.1password.com/docs/cli)
- [yq](https://github.com/mikefarah/yq)

### 2. Environment Setup

### 3. Launch

```bash
castle up            # Deploy all apps from manifest
castle down          # Tear down all containers
```

---

## 📜 Manifest Example (`manifest.yml`)

```yaml
projects:
  - name: players
    source:
      type: git
      url: https://github.com/your-org/players.git
      path: players
      auth:
        type: oauth
        token: op://vault/github/oauth-token
    compose: docker-compose.yml
    env: environments/players/.env
    expose_port: 4567

  - name: dashboard
    source:
      type: local
      path: services/dashboard
    compose: docker-compose.yml
    env: environments/dashboard/.env
    env_name: dashboard
    expose_port: 3000
```

---

## 🧪 CLI Reference

```yaml
projects:
  - name: players
    path: players
    compose: docker-compose.yml
    env: op://vault/players/env-file
    env_name: op://vault/players/env-name
    expose_port: 4567
    git:
      url: https://github.com/your-org/players.git
      auth:
        type: oauth
        token: op://vault/github/oauth-token
```

---

## 🧪 CLI Reference (`castle.sh`)

| Command                  | Description                              |
|--------------------------|------------------------------------------|
| `up`                    | Deploy all projects from manifest        |
| `down`                  | Stop all or specific projects            |
| `reload-proxy`          | Regenerate and reload tsdproxy routes    |
| `proxy_page`            | Open the tsdproxy UI in your browser     |
| `secrets reveal <env>`  | Inject `.env` from 1Password templates   |

---

## 🧠 Philosophy

- Minimalist and observable by default
- Secrets stay in 1Password, not Git
- Declarative over imperative
- Everything routes over Tailscale

---

## 🪪 License

MIT © [Your Name or Org]

Inspired by the musical and metaphysical layers of King Gizzard’s *Polygondwanaland*.
