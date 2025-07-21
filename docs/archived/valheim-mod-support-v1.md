# 📜 Spec: Valheim Mod Support Debug Log Finalization

## 🧭 Purpose

Formalize the results of successful modded Valheim server operation via Docker, and define the criteria for updating all existing documentation to reflect this working configuration.

This spec will be moved to `docs/spec/archive/` once all workspace docs are updated accordingly.

---

## ✅ What Worked

* The `lloesche/valheim-server` Docker image natively supports BepInEx mods using `-e BEPINEX=true`.
* Mods placed inside `/config/BepInEx/plugins` were automatically detected and loaded.
* Verified in logs:

  ```
  [Info   :   BepInEx] Loading [AzuClock 1.0.5]
  ```
* External client successfully joined modded server via internal IP.
* Mod files downloaded directly from Thunderstore using `curl` or `wget` and unzipped into the correct plugin folder.

---

## 🧾 Spec Requirements

Each documentation file in this workspace that pertains to Valheim setup, mod installation, or Docker server hosting **must reflect** the following:

### 🧩 Required Content:

* ✅ Docker image used: `lloesche/valheim-server`
* ✅ BepInEx activation: `-e BEPINEX=true`
* ✅ Directory structure:

  ```
  /mnt/e/deep.space.10/server
  ├── BepInEx
  │   └── plugins
  │       └── <modname>
  └── start_server_bepinex.sh (unused in final config)
  ```
* ✅ Mod installation instructions via command line
* ✅ Notes on `valheim_server.x86_64` restore using SteamCMD
* ✅ Successful container log output indicating BepInEx load
* ✅ External connectivity checklist (firewall, port forwarding, NAT loopback caveats)

### 🧪 Optional Enhancements:

* Include debug logs for mod boot sequences
* Provide a mod helper install script stub (e.g. `download-mod.sh`)

---

## 📌 Acceptance Criteria

This spec may be archived **only after**:

* [ ] All relevant `.md` docs in the workspace match the spec content above
* [ ] Public access flow log has been updated
* [ ] Mod support debug log is fully aligned

---

## 🗃️ Destination Upon Completion

Move to:

```
docs/spec/archive/valheim-mod-support-v1.md
```

---

## 🔖 Spec ID

`valheim-mod-support-v1`
