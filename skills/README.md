# skills

这个目录存放 `ai-studio` 的可复用 AgentSkills 源码与说明。

## 目录约定

- 每个 skill 一个独立目录
- 目录内至少包含 `SKILL.md`
- 可按需包含 `scripts/`、`references/`、`assets/`

## 当前 skills

### `idea-repair`
用于排查和修复 **IntelliJ IDEA 启动卡死 / 假死 / 打开项目过慢** 一类问题，重点覆盖：

- 缓存 / 索引损坏后的安全清理
- 线程转储里 `HttpsURLConnection.getResponseCode`、`SuvorovProgress`、`MavenProjectsManager` 等典型卡点识别
- `Lingma / Cosy`、`JetBrains AI Assistant` 等插件引发的启动链路阻塞排查
- Maven 自动导入、项目恢复、图标计算导致的假死排查
- Windows 下带备份的 IDEA 缓存清理脚本

源码位置：`skills/idea-repair/`
打包产物：`skills/dist/idea-repair.skill`
