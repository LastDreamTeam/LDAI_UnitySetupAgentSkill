# 为当前 Agent 安装 ld-unitysetup-online

只有用户要求安装/迁移时执行。安装与升级本技能不授权安装 Unity、卸载团结、改代理或删除用户数据。

## 识别宿主

确认当前 Agent、profile、操作系统、允许的技能发现目录、Python 3.10+、Git。优先使用宿主支持的原生管理器，并保留其扫描/审批。不要因另一安装方式被拒绝，就改走复制或 Git 绕过。

- Codex：核当前[官方技能文档](https://developers.openai.com/codex/skills)与本机配置。支持用户级 `.agents/skills` 的实例可采用下面的独立克隆与目录链接；现有 `.codex/skills` 仅在该实例确认扫描时使用。
- Hermes：先核当前版本帮助，若支持仓库子目录安装，可用 `hermes skills install LastDreamTeam/LDAI_UnitySetupAgentSkill/skills/ld-unitysetup-online`，之后验证登记和实际文件。不要假定所有版本的命令相同。
- Claude Code、Cursor 或其他宿主：读该产品当前技能说明，确认作用域与完整目录接入方式，不批量修改其他产品。
- 没有文件/终端能力：报告只能阅读，不能声称完成安装。

## 获取完整技能

唯一默认源为 `https://github.com/LastDreamTeam/LDAI_UnitySetupAgentSkill.git`，默认通道 `main`，子目录 `skills/ld-unitysetup-online`。选择用户可写、长期存在、业务仓库和临时任务目录之外的 `<REPO_DIR>`；每个独立安装目标使用独立克隆。

```sh
git clone --branch main --single-branch https://github.com/LastDreamTeam/LDAI_UnitySetupAgentSkill.git "<REPO_DIR>"
git -C "<REPO_DIR>" remote get-url origin
git -C "<REPO_DIR>" status --porcelain --untracked-files=all
```

已经存在时复用经核实的同一来源，不覆盖脏目录。读取 LICENSE、SKILL.md 和实际要运行的脚本。将完整技能目录接入宿主实际发现位置；不能只复制 SKILL.md。

使用宿主支持的目录注册或链接。Unix 可用目录符号链接；Windows 已确认宿主可扫描目录联接时，可通过 PowerShell `New-Item -ItemType Junction -Path <宿主目录/ld-unitysetup-online> -Target <REPO_DIR/skills/ld-unitysetup-online>` 创建。已有目标一律先核实，不覆盖、不改系统开发者模式或安全设置来获得链接权限。插件打包的技能必须是真实目录，不能把本地链接方式机械用于插件发布。

仅复制目录或原生管理器安装也可使用规范和在线检查，但 Git 更新须由独立克隆后端完成；其他安装用其正式管理器，不改写锁文件或规避原生审批。

## 检查与迁移

从宿主实际使用的完整技能目录运行：

```sh
python -B scripts/maintain.py show
python -B scripts/maintain.py check --force
```

核名称、版本、官方来源、实际状态目录和更新后端。默认每 7 天使用时检查，自动应用更新关闭。检查失败不等于安装失败，但必须报告在线维护尚未验证。

若用户要求替代旧版，先验证新版完整、可读取、路线检查可执行；再记录旧 `ld-unitysetup-v1` 的真实路径，将该实例旧技能移到宿主扫描目录之外的可恢复备份。不要删除其他 profile，不执行两份规则。原审计与脚本能力已被新版包含，不需要继续加载 v1。

确认宿主的发现接口/列表；若当前会话目录快照不能热刷新，说明已接入并已通过绝对路径读取，新会话按宿主机制发现。不要擅自重启当前 Agent 或声称每款终端均已验证。

## 简短回执

报告版本、当前宿主接入位置、Git/原生/只读拷贝后端、检查结果、自动更新开关以及旧版是否已停用。通常不需要用户再执行普通安装步骤；只报告真实的权限/审批/激活障碍。
