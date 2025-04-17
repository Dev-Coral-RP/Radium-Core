# 🌐 Radium-Core | Custom FiveM Framework Core

Radium-Core is a **modular**, **lightweight**, and **production-ready** core framework for FiveM servers, built with flexibility and customization in mind. It serves as the foundational layer for all gameplay systems — character creation, spawning, job management, banking, and more.

Designed for creators who want full control without the bloat.

---

## 🔥 Features

- ⚙️ Clean core logic using `ox_lib` and `oxmysql`
- 👤 Integrated multicharacter system with ped previews
- 🏦 Character-specific bank ID (CSN) support
- 🧬 Blood types, gender, and DoB in character data
- 🧠 Modular structure (jobs, money, housing, etc. can be added later)
- 🌆 Airport-based spawn location by default
- 📄 Server-side logging + future webhook logging support
- 🎨 Fully integrated with `illenium-appearance` (custom system coming soon)
- 🛑 Built-in support for NUI control via `ox_lib` dialog/context UIs
- 🔐 Framework-agnostic — **not based on ESX or QBCore**

---

## 🚀 Getting Started

### 1. Requirements
- **oxmysql**
- **ox_lib**
- **spawnmanager** (for player spawns)
- Optional: `illenium-appearance`

### 2. Installation
```bash
git clone https://github.com/Dev-Coral-RP/Radium-Core.git
```

- Add to your `server.cfg`:
```cfg
ensure oxmysql
ensure ox_lib
ensure Radium-Core
```

- Configure the `config.lua` to match your server setup.

---

## 🧭 Roadmap

### ✅ In Progress
- [x] Core character creation/selection
- [x] Ped preview and gender system
- [x] CSN/bank integration
- [x] Basic spawn logic
- [x] ox_lib UI context menus
- [x] Delete character with confirmation

### 🧪 Planned
- [ ] Modular job system (`radium-jobs`)
- [ ] Money system with cash, bank, crypto, dirty
- [ ] Bank UI + transactions
- [ ] Appearance editor replacement (`radium-appearance`)
- [ ] Discord webhook logger system
- [ ] Configurable spawn locations
- [ ] Role-based permissions system
- [ ] NUI Notification & dialog system
- [ ] Housing & garage integrations (external modules)

---

## 🐞 Known Issues

- ❗ Spawn ped may not always use freemode correctly on some builds
- ❗ Raycast support for ped hover isn't active yet
- ❗ Appearance not saved until Illenium or custom system added
- 📝 Spawn position doesn't persist unless configured in DB
- ⚠️ Chat messages may overlap with NUI if not properly hidden

Have a bug? [Open an Issue](https://github.com/Dev-Coral-RP/Radium-Core/issues)

---

## 📁 Project Structure

```plaintext
Radium-Core/
│
├── client/
│   ├── character.lua         # Character UI logic & spawns
│   └── main.lua              # Main client events
│
├── server/
│   ├── main.lua              # Server-side event handlers
│   └── character.lua         # DB character management
│
├── shared/
│   └── config.lua            # Core config (multicharacter, slots, etc.)
│
└── fxmanifest.lua            # Resource definition
```

---

## 📝 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2025 Dev-Coral

Permission is hereby granted, free of charge, to any person obtaining a copy...
```

> Full license included in [`LICENSE`](./LICENSE)

---

## 🤝 Contribution

Contributions are welcome! Whether it’s PRs, ideas, or modules, open a discussion or submit a pull request.

### Tips:
- Follow naming conventions (use `Radium` prefix)
- Keep logic modular and isolated
- Stick to `ox_lib` and `oxmysql` standards

---

## 💬 Support

Need help or want to chat with other devs?  
Join the community Discord: [discord.gg/yourinvite](https://discord.gg/yourinvite)

---

## 🧠 Inspiration

Radium-Core is inspired by:
- `qbox-core` (for its modularity)
- `illenium-appearance`
- Clean and maintainable Lua codebases

---

Built with ❤️ by Dev Coral RP | [github.com/Dev-Coral-RP](https://github.com/Dev-Coral-RP)