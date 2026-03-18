# IDEA Startup Hang Checklist

Use this checklist when cache cleanup does not fully solve the startup problem.

## Signature patterns

### 1. Network / auth stall

Common signs:

- `main` thread blocked in `HttpsURLConnection.getResponseCode`
- JetBrains account or AI related classes nearby
- The UI thread sits behind `SuvorovProgress.showNiceOverlay`

Interpretation:

- Usually not a JVM deadlock
- More likely a synchronous startup request waiting on auth, network, proxy, or TLS

Next actions:

1. Restart once with proxy disabled or network disconnected for comparison.
2. Sign out / sign back in to JetBrains account if needed.
3. Disable AI or cloud plugins temporarily.

### 2. Plugin initialization stall

Common signs:

- Third-party plugin package names dominate the dump
- Threads block in plugin binary checks, decompression, or startup hooks
- Example seen in practice: `com.alibabacloud.intellij.cosy`

Next actions:

1. Disable the suspect plugin.
2. Reopen IDEA.
3. Re-enable plugins one by one only after the IDE is stable.

### 3. Maven project restore / icon computation stall

Common signs:

- Many workers wait under `MavenProjectsManager.initProjectsTree`
- Stack traces include `MavenIconProvider`, `computeFileIconImpl`, or editor restore paths

Next actions:

1. Disable Maven auto-import.
2. Reduce restored tabs/editors if possible.
3. Remove project `.idea` and reimport if the project model looks corrupted.

## Practical commands

### Check whether IDEA still has running processes

```powershell
Get-Process idea64 -ErrorAction SilentlyContinue
```

### Inspect the local JetBrains profile directory

```powershell
Get-ChildItem "$env:LOCALAPPDATA\JetBrains\IntelliJIdea2025.3" -Force
```

### Run the cleanup script

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean-idea-cache.ps1 -Product IntelliJIdea -Version 2025.3
```

## Real-world lesson captured in this skill

A thread dump that shows:

- `main` waiting in `HttpsURLConnection.getResponseCode`
- `AWT-EventQueue-0` in `SuvorovProgress`
- multiple workers under `MavenProjectsManager`
- plugin activity like `com.alibabacloud.intellij.cosy`

should be treated as a startup chain stall, not immediately as a JVM deadlock. Start with safe cache cleanup, then plugin/network/Maven isolation.
