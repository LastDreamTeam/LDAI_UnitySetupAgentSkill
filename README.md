# LDAI_UnitySetupAgentSkill

**`ld-unitysetup-online`：安装、验证国际版 Unity，清理 Unity 中国版 / 团结，并诊断地区重定向的持续维护技能。**

由 LastDream / LD 提出需求，OpenAI Codex 整理实现。新版吸收 `ld-unitysetup-v1` 与真实工作站修复经验，固定技能名，以语义版本升级，不再叠加执行旧版。

## 一句话交给任意支持技能的 Agent

```text
请阅读 https://github.com/LastDreamTeam/LDAI_UnitySetupAgentSkill/blob/main/skills/install.md，为当前 Agent 安装完整的 ld-unitysetup-online，验证在线检查，并在确认新版可用后迁移停用 ld-unitysetup-v1。
```

[Agent 安装说明](skills/install.md) · [技能正文](skills/ld-unitysetup-online/SKILL.md) · [更新记录](CHANGELOG.md)

“任意 Agent”指允许安装本地技能、具备文件/终端/网络能力的宿主，不意味着所有产品和操作系统均已实机验收。只安装当前宿主，不批量接管同机其他 Agent，不安装系统服务或计划任务。没有执行能力的聊天模型只能阅读。

## 能做什么

- 按项目的精确版本安装国际 Hub、Editor 与必要模块，验证签名、完整版本、发布源、服务端点和实际下载链。
- 盘点并通过已验证的官方卸载器移除团结 / 中国版 Editor，处理协议、应用缓存和旧版本登记；保护国际版、项目与有效许可证。
- 识别官网/CDN 地区分流：不带 Cookie 逐跳检查，避免只看 `.com` 起点、普通 `f1`、中文界面或最终响应。
- 获得具体授权后，在已有代理中仅为 Unity 国际域名选择已验证出口，保留默认节点和其他路由，备份并实测恢复结果。
- 区分“已卸载”“残留已隔离”“磁盘彻底清除”“尚有历史日志/安装包”，不把隔离备份说成已删除。

## 支持边界

Windows 提供审计、签名检查、应用缓存隔离和团结盘点脚本。路线检查、在线维护采用 Python 3.10+ 与 curl/Git，可跨平台运行；macOS/Linux 的 Unity 安装、签名和卸载走各平台官方流程，尚未宣称自动清理脚本实机通过。详见[平台说明](skills/ld-unitysetup-online/references/platforms.md)。

技能安装不是卸载软件、关闭未保存项目、改网络或永久删除的授权。用户已经明确授权的同一范围无需反复确认；审计请求仍只读。系统/宿主审批必须保留，遇到拒绝不得换工具或包装等价操作绕过。

## 检查与更新

默认在使用技能时每 7 天检查一次；自动应用更新默认关闭。用户明确要求检查时立即检查；确认更新后仅在空闲时 fast-forward 官方克隆，不覆盖本地修改、不变更业务仓库。

```sh
python -B scripts/maintain.py show
python -B scripts/maintain.py check --force
python -B scripts/maintain.py sync --idle --approve-update
python -B scripts/maintain.py config --interval-days 7 --auto-update off
```

以上命令在完整技能目录运行。只有用户要求长期自动更新才使用 `--auto-update on`。原生管理器安装由该管理器更新；单纯文件拷贝可查版本，不能冒称 Git 更新后端可用。见[维护与迁移](skills/ld-unitysetup-online/references/maintenance.md)。

## 许可

沿用参考分发项目的分区方式：Markdown 文档为 CC BY-SA 4.0，实际脚本与测试代码为 AGPL-3.0-only。见 [LICENSE](LICENSE)、[NOTICE.md](NOTICE.md)。使用技能协助开发不自动给独立业务产品附加相同许可。
