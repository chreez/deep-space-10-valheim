# ✅ Valheim Dedicated Server Diagnostic Summary – PRD Enhancement

## 🌟 Purpose

This document supplements the original Valheim server PRD and install spec. It captures successful diagnostic strategies, confirmed working patterns, and safe fallback configurations usable in WSL (Ubuntu) or Docker.

---

## 🔍 Key Findings (from debug session)

| Area                  | Result                                                                  |
| --------------------- | ----------------------------------------------------------------------- |
| Native WSL Binary     | Launches but exits early after `GameServer.Init()`                      |
| SteamCMD              | Broken initially; fixed via i386 libs. GSLT integration possible        |
| Docker Support        | ✅ Functional. Containers run reliably in WSL with proper volume mounts  |
| GSLT Token            | Created: `E604789482D21A6DBD8BC97ECAA7538F`. May require manual linkage |
| Server Visibility     | Not visible to friends without full Steam credentials or token setup    |
| Join Test             | ✅ Joining via IP (`127.0.0.1:2456` or `WSL-IP:2456`) confirmed          |
| Mod Support (BepInEx) | Present in mounted folder but not tested in Docker                      |

---

## 🐳 Docker-Specific Configuration

Use this for safe, non-destructive testing:

```bash
docker run --rm -it --name valheim-test \
  -p 2456-2458:2456-2458/udp \
  -v /mnt/e/deep.space.10/server:/config \
  -e SERVER_NAME="DeepSpace10" \
  -e WORLD_NAME="DeepSpace10" \
  -e SERVER_PASS="yourpassword" \
  -e PUBLIC=0 \
  -e SERVER_TOKEN="E604789482D21A6DBD8BC97ECAA7538F" \
  lloesche/valheim-server
```

For persistent background hosting:

```bash
docker run -d --name valheim-server \
  -p 2456-2458:2456-2458/udp \
  -v /mnt/e/deep.space.10/server:/config \
  -e SERVER_NAME="DeepSpace10" \
  -e WORLD_NAME="DeepSpace10" \
  -e SERVER_PASS="yourpassword" \
  -e PUBLIC=0 \
  -e SERVER_TOKEN="E604789482D21A6DBD8BC97ECAA7538F" \
  lloesche/valheim-server
```

Check status:

```bash
docker ps
docker logs -f valheim-server
```

---

## 🔐 Steam Token Integration

The GSLT token is pre-generated and passed via Docker as:

```bash
-e SERVER_TOKEN="E604789482D21A6DBD8BC97ECAA7538F"
```

No manual SteamCMD interaction is needed.

---

## 🧾 To-Do for PRD Finalization

* [ ] Add optional Docker run integration to install script
* [ ] Move token storage to secure env file or CI secret
* [ ] Add test for GSLT validation inside container logs
* [ ] Confirm mod (BepInEx) compatibility inside container
