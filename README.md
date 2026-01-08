# xray-checker-installer

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Version](https://img.shields.io/badge/version-0.0.1--alpha-orange.svg)](https://github.com/UnderGut/xray-checker-installer)

Автоустановщик для [xray-checker](https://github.com/kutovoys/xray-checker) — инструмента мониторинга прокси-серверов (VLESS, VMess, Trojan, Shadowsocks).

[🇷🇺 Русская версия](README-RU.md)

## ⚡ Quick Install

```bash
bash <(curl -Ls https://raw.githubusercontent.com/UnderGut/xray-checker-installer/main/install_xray_checker.sh)
```

## ✨ Features

- **🚀 Quick Install** — one command, minimal questions
- **🐳 Docker & Binary** — choose your installation method
- **🌐 Multi-language** — English and Russian UI
- **🔐 Auto Basic Auth** — credentials generated automatically
- **🔄 Reverse Proxy** — auto-detection and configuration (Nginx/Caddy)
- **📜 SSL Certificates** — Cloudflare, ACME HTTP-01, Gcore DNS
- **🔗 Remnawave API** — auto-create monitoring user

## 📋 Requirements

- **OS**: Debian 11/12, Ubuntu 22.04/24.04
- **Access**: Root privileges
- **Optional**: Docker (will be installed automatically)

## 🎯 After Installation

```bash
# Open management menu
xchecker

# Or full command
xray_checker_install
```

## 📁 Installation Directory

```
/opt/xray-checker/
├── docker-compose.yml    # Docker configuration
├── .env                  # Environment variables
├── install_method        # "docker" or "binary"
└── selected_language     # "en" or "ru"
```

## 🔧 Management Menu

```
╔══════════════════════════════════════════════╗
║         XRAY-CHECKER INSTALLER               ║
╠══════════════════════════════════════════════╣
║  1. Quick Install (recommended)              ║
║  2. Custom Install                           ║
║  3. Manage Service                           ║
║  4. Update Script                            ║
║  5. Uninstall                                ║
║  0. Exit                                     ║
╚══════════════════════════════════════════════╝
```

## 🔐 Default Endpoints

| Endpoint | Auth | Description |
|----------|------|-------------|
| `GET /` | Optional | Web UI dashboard |
| `GET /health` | ❌ | Health check (returns `OK`) |
| `GET /metrics` | ✅ Basic Auth | Prometheus metrics |
| `GET /api/v1/proxies` | ✅ Basic Auth | Proxy list with details |

## 🔗 Related Projects

- [xray-checker](https://github.com/kutovoys/xray-checker) — Main project
- [Remnawave Panel](https://github.com/remnawave/panel) — VPN panel with subscription support

## 📄 License

This project is licensed under the [AGPL-3.0 License](LICENSE).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
