# 🏰 Polygondwanaland

Polygondwanaland is a modular, manifest-driven infrastructure platform designed for self-hosting applications with ease and security. It integrates secrets management, observability, and private networking through a unified runtime powered by 1Password Connect, Grafana OSS, and Tailscale.

At the core of the platform is a custom CLI tool called castle, which reads a single manifest file to orchestrate your entire environment. This manifest defines:

* Applications to run in Docker containers, including their sources, commands, ports, and runtime environments.
* System-level services like:
    * 🔐 Secrets from a self-hosted 1Password Connect instance
    * 📈 Observability using Grafana, Loki, Tempo, and Prometheus
    * 🌐 Proxying and HTTPS via Tailscale and an internal reverse proxy

With castle, you can bring up, manage, and observe your full stack from a single, declarative configuration.

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
├── secrets.json          # 1password connect auth, excluded by .gitignore
proxy (proxy.ts_friendly_name/localhost:3001)
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
