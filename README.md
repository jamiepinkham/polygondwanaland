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
metrics (metrics.ts_friendly_name/localhost:3000)
├── docker-compose.yaml   # compose file for grafana/tempo/loki
secrets (secrets.ts_friendly_name/localhost:8080)
├── docker-compose.yaml   # compose file for 1password connect 
├── secrets.json          # excluded by .gitignore
proxy (proxy.ts_friendly_name/localhost:3000)
├── docker-compose.yaml   # compose file for tsdproxy
├── config
    ├── .auth_key         # ts auth key, excluded by .gitignore
    ├── tsdproxy.yaml

manifest.yml              # defines projects to deploy
```

---

## 🚀 Getting Started

### Prerequisites

- Docker + Docker Compose
- [1Password CLI](https://developer.1password.com/docs/cli)
- [yq](https://github.com/mikefarah/yq)


## 📜 Manifest Example (`manifest.yml`)

```yaml

castle:
  proxy:
    enabled: true
      ts_friendly_name: friendly-name.ts.net
  metrics: true #spins up grafana on 3000
  secrets: false #spins up 1pw connect on 8080

  projects:
    - name: linux-shell
      source:
        type: image
        image: tsl0922/ttyd
      expose_port: 7681
      listen_port: 80
      env_name: dev

```

---

## 🧪 CLI Reference (`castle.sh`)

| Command                  | Description                              |
|--------------------------|------------------------------------------|
| `up`                    | Deploy all projects from manifest        |
| `down`                  | Stop all or specific projects            |
---

## 🧠 Philosophy

- Minimalist and observable by default
- Secrets stay in 1Password, not Git
- Declarative over imperative
- Everything routes over Tailscale

---

## 🪪 License

MIT © [Jamie Pinkham]

Inspired by the musical and metaphysical layers of King Gizzard’s *Polygondwanaland*.
