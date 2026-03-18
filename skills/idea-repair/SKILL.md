---
name: idea-repair
description: Diagnose and repair IntelliJ IDEA startup hangs, fake freezes, cache/index corruption, and plugin or Maven related opening-project stalls on Windows. Use when the IDE is stuck on startup, only shows the progress overlay, thread dumps mention HttpsURLConnection.getResponseCode / SuvorovProgress / MavenProjectsManager / com.alibabacloud.intellij.cosy, or when clearing caches, disabling plugins, or killing stuck idea64.exe processes may recover the IDE.
---

# IDEA Repair

Repair IntelliJ IDEA startup failures on Windows with a safe workflow: confirm the symptom, close the IDE, back up and clear cache-like directories, then triage plugins, network, and Maven only if cache cleanup is not enough.

## Quick start

1. Confirm the problem matches this skill:
   - IDEA opens very slowly, hangs on splash/project open, or looks frozen behind a progress overlay.
   - A thread dump shows `HttpsURLConnection.getResponseCode`, `SuvorovProgress`, `MavenProjectsManager`, or `com.alibabacloud.intellij.cosy`.
2. Close IDEA fully. Do not clean caches while `idea64.exe` is still using the target profile unless the user explicitly accepts the risk.
3. Run `scripts/clean-idea-cache.ps1` to back up and clear the cache-like directories.
4. Reopen IDEA and verify startup.
5. If the problem remains, follow the plugin / network / Maven checklist in `references/startup-hang-checklist.md`.

## Workflow

### 1. Classify the failure quickly

Treat these as the main buckets:

- **Cache / index corruption likely**
  - Recent crash, forced shutdown, interrupted indexing, or it started working after cache cleanup.
- **Network / auth stall likely**
  - `main` thread blocks in `HttpsURLConnection.getResponseCode`.
  - JetBrains account, AI assistant, or cloud plugin activity appears in the dump.
- **Plugin initialization stall likely**
  - Dump mentions third-party plugin packages such as `com.alibabacloud.intellij.cosy`.
- **Maven restore / import stall likely**
  - Many workers wait under `MavenProjectsManager.initProjectsTree` or `MavenIconProvider`.

Do not jump to JVM deadlock unless there is an actual lock cycle. A progress overlay plus blocked startup work is more common than a true deadlock.

### 2. Perform the safe repair first

Use `scripts/clean-idea-cache.ps1`.

Default target directories:

- `caches`
- `index`
- `tmp`
- `httpFileSystem`
- `jcef_cache`
- `compile-server`
- `compiler`
- `vcs-log`
- `Maven`
- `icon-cache-v1.db`
- `.pid`
- `.port`

The script moves these entries into a timestamped backup directory instead of deleting them directly.

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-idea-cache.ps1 -Product IntelliJIdea -Version 2025.3
```

Auto-detect the newest IDEA profile:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-idea-cache.ps1 -Product IntelliJIdea -AutoDetectLatest
```

Use `-IdeDir` when the exact JetBrains profile path is already known.

### 3. Escalate only if reopening still fails

If cache cleanup alone is not enough:

1. Disable high-risk plugins first:
   - Lingma / Cosy
   - JetBrains AI Assistant
   - Other cloud / AI plugins added recently
2. Test without proxy or with a known-good proxy configuration.
3. Disable Maven auto-import or reopen the project with minimal restored tabs.
4. If needed, remove project-local `.idea` and reimport the project.

### 4. Verify and report clearly

Always report in layers:

- What symptom matched the skill
- Which cache entries were moved
- Backup directory path
- Whether IDEA reopened successfully
- Which next-step suspects remain: plugin, network/auth, or Maven

### 5. Roll back if needed

If the cleanup introduces a new issue, restore the moved directories/files from the generated backup folder while IDEA is fully closed.

## Resources

- `scripts/clean-idea-cache.ps1` — Safe cache cleanup with backup and running-process guard.
- `references/startup-hang-checklist.md` — Deeper diagnosis for thread dumps, plugin suspicion, network/auth stalls, and Maven-related hangs.
