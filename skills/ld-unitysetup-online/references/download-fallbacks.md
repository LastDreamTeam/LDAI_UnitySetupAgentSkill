# Unity 下载兜底与 NoUnityCN 协作

本页增加选择路径，不替换技能已有的[实测安装流程](install-and-repair.md)、[国际版判定](international-integrity.md)和[局部路由修复](proxy-routing.md)。原技能已验证实践优先于补充文章；若当前官方证据与旧实践冲突，记录差异后最小重验。所有路线都锁定项目要求的完整版本、revision、OS/架构及模块，不为了“容易下载”升级项目。

## 先区分卡在哪一层

- **页面/目录打不开**：切换官方 Archive、官方 Releases API，或 NoUnityCN 的检索入口；不要据此改 Editor 版本。
- **版本列表有了，Hub 调不起来**：核 `unityhub://` 协议对应的实际国际 Hub，或转官方独立 Editor 安装包。页面成功不代表 Hub 成功。
- **安装包下载失败/地区重定向**：核每个跳转和实际 CDN；在原授权内复用现有代理的 Unity 专用路由，或转可信离线传输。换一个目录页未必能改变同一下载链。
- **安装、模块、登录/激活失败**：分别查对应版本、模块依赖、许可证和服务端点。NoUnityCN 不提供激活 License；下载成功不解决授权或账号问题。[2]

## 多路线选择表

按实际故障选一条最小可行路线，不机械遍历全表、不重复下载已验证的同一包。

| 路线 | 适用与操作 | 完成条件/切换条件 |
| --- | --- | --- |
| A. 官方 Hub / Archive | 保持原首选流程，从官方 Archive 定位精确 Editor，交国际 Hub 安装 | 核完整版本/revision、Hub 实际队列和下载链；列表缺项或网页分流才转 B/C |
| B. 官方 Releases API | 用版本、平台、架构查询，读取 `results` 和 `downloads`；精确比较返回版本，不把模糊搜索首项当目标 | 元数据与项目版本一致；分别取得 Editor 和所需模块的官方 URL，再执行原签名/路由检查 |
| C. NoUnityCN 主站/备用站 | 中文版本检索、Hub 深链和组件入口，作为发现层 | 对照官方 API；数据加载失败可换站或转 B，而不是信任静态“加载中…”页面 |
| D. 官方独立安装包 | 从核定的官方 metadata 提取 URL；安装后按当前官方流程在 Hub 定位已装 Editor | 先验证完整文件/签名/版本，再装匹配模块；不能把“已定位”当模块管理或许可证也通过 |
| E. NoUnityCN GitHub Hub 资产 | 官方 Hub 下载链暂不可达时，检查上游 Release 的确切资产；属于第三方转载渠道 | 须满足下文独立来源核验；无充分证据不执行。不是任意 GitHub EXE 都可信 |
| F. 可信离线包/另一台已授权机器 | 已持有官方取得且验证过的同版本包时，随包保留来源、完整版本、大小及 SHA-256，再有限传输 | 到目标端重算 SHA-256，并重新验平台签名/包签名；缺少模块不标工作站完成 |
| G. 自托管检索前端 | 仅当长期需求明确、用户授权部署时，按上游当前 README 构建 | 只解决检索前端可达性；仍依赖 Unity 元数据/CDN，不是离线 Editor 仓库或许可服务 |

A/B/D 的官方入口沿用 [sources.md](sources.md)。B/C 共用上游并非相互独立的“备份数据源”：当前 NoUnityCN 源码从 Unity Releases API 获取版本数据，默认 `USE_CLIENT_SIDE_FETCH = true`；另实现同源 `/api/releases` 转发路线。[5]

## NoUnityCN 的准确定位与入口

NoUnityCN 是第三方开源检索项目，不是 Unity 官方网站或国际版权威判定器。主站说明内容来自官方下载渠道及公益服务器，应逐项辨别；上游 README 自述不是破解/修改工具。[1][2]

- 用户给定入口：<https://www.nounitycn.top/>。
- 上游 README 公布的主域：<https://nounitycn.top/>。
- 上游公布的备用网址：<https://nounitycn-vinext.danke666.top/>、<https://nounitycn.danke666.top/>。
- 源码/更新与说明：<https://github.com/DanKE123abc/NoUnityCN>。
- Hub 页面：<https://www.nounitycn.top/unityhub>；GitHub 资产目录：<https://github.com/DanKE123abc/NoUnityCN/releases>。[2][6]

入口使用前从上游 README 重新确认，不把相似域名、搜索广告或任意“下载加速器”加入默认列表。多个站可能共享上游故障，不能承诺互相兜底必然成功。

上游 README 明确限制其面向人群/地区（包括声明不为大中华区本土开发者提供服务）、不提供激活 License，并对公益下载服务提示可能中断及非商业使用要求；这些是该项目自己的声明，不是本技能对 Unity 授权的独立法律判定。采用对应服务前核其当前条件及用户实际资格；收录链接不授予服务、Editor 或账号使用权。仓库 MIT 也不覆盖经 API 获取的 Unity 内容、商标和安装包。[2]

## 实际接法：检索 → 核对 → 选择传输 → 原技能验收

1. 从 `ProjectSettings/ProjectVersion.txt` 或用户明确要求锁定完整版本及 revision。没有工程时也不要把网页默认最新版本当用户选择。
2. 在官方 API 或 NoUnityCN 检索精确版本，记录 `version`、`shortRevision` 和目标 `downloads[].platform/architecture/url`；模块从同一发布记录取得，不跨版本拼包。
3. NoUnityCN 的 `unityhub://<version>/<revision>` 只是交给本机 Hub 的安装入口，不是 HTTP 安装包。只采用当前网页/官方 metadata 得到的准确值，不能凭版本猜 revision；调用前核协议目标不是团结/中国 Hub。
4. 若 Hub 安装链失败，可转同一已核发布的独立 Editor/模块 URL，不自动升小版本。对每个实际 URL 运行现有 route probe，保留完整跳转证据；HEAD 被服务端拒绝仅表示探测未知，不是 TLS 可忽略或包必定不存在。
5. 下载完成再核完整大小/摘要及平台签名；Windows 继续用 `Test-LDUnityInstaller.ps1`，macOS/Linux 采用原平台流程。第三方页面上的“国际版”、文件名或成功 HTTP 状态都不是通过依据。
6. 安装 Editor 后核实际可执行文件，再按需求加模块、验证必要工具链及正常许可。完成等级沿原技能报告，不把检索/链接可达当安装/激活完成。

在技能目录使用已有命令（Agent 经宿主终端工具执行），不另造下载器：

```sh
python -B scripts/probe_routes.py --url "https://www.nounitycn.top/" --json
python -B scripts/probe_routes.py --url "https://nounitycn-vinext.danke666.top/" --json
python -B scripts/probe_routes.py --url "<从官方发布元数据取得的 HTTPS 安装包 URL>" --json
```

这些 probe 的 `PASS` **只表示该次 HTTP 路由检查通过**，不是证明页面有实际版本数据、软件官方身份、签名、可安装或许可合规。

下面只查询官方元数据，不安装、不调起 Hub。示例版本用于说明，执行时替换为实际目标，不能将它作为项目默认版本：

```sh
curl --fail --show-error --silent --get --connect-timeout 8 --max-time 30 \
  --data-urlencode "version=2022.3.62f1" \
  --data-urlencode "platform=WINDOWS" \
  --data-urlencode "architecture=X86_64" \
  --data-urlencode "limit=1" \
  "https://services.api.unity.com/unity/editor/release/v1/releases"
```

字段/schema 变化或结果为空时回当前官方文档核对，不从旧模板拼造下载地址。版本目录故障时可只读尝试 NoUnityCN 同源 `/api/releases`，但它是第三方代理，不传账号、Cookie、Authorization、项目数据或私人 URL；不把它当 Unity 官方 API。[5]

## GitHub Hub 资产：有路可走，但不能降级信任

当前上游 Hub 页直接链接其 GitHub Release 资产；发布流水线从 Unity CDN/官方下载地址同步，并生成 `checksums.md5`。这是来源线索，不等于已独立审过某个资产的实际字节。[6][7]

- 从当前 Release API/页面枚举存在的资产，核 tag、平台/架构、大小和摘要；不要按网页静态按钮猜每个架构必有包。`latest` 会漂移，当前同步流水线也可能删除并重建同名 Release，因此 tag/URL 不是不可变证据。实际下载/回执同时记录 release/asset ID、查询时间、大小和实际文件 SHA-256；资产变化后重新核验，不复用旧批准。[7][8]
- `checksums.md5` 仅能辅助发现传输错误，不能作抗篡改或官方发布者身份证明。同一第三方提供的 SHA-256/GitHub digest 也不能独立证明 Unity 官方来源。
- 原技能的官方来源优先不变。第三方转载仅在用户接受该传输渠道、官方来源链可独立核对且完整版本/有效发布者签名等原完整性条件全部满足时才作为候选兜底；有官方发布摘要时必须比较。缺少平台可信验证证据就保留 `UNKNOWN`，不执行、不开启“不安全下载”。
- 不关闭 TLS/签名验证，不回避安全软件隔离，不通过未知代理转发凭据，不把 GitHub 仓库许可证当 Unity 软件许可证。

## 自托管与旧网址

上游 README 提供 Next.js 与 vinext 两套构建/部署路线，使用 Node.js 20+，并列出相应命令；实际部署必须读取当前 README，不在普通 Unity 安装中自动开新服务。[2]

上游还说明 v2 保留 `/download`、`/component`、`/tools`、`/releaseNotses`、`/unityModule` 等旧端点以兼容旧链接。保留原文拼写 `releaseNotses` 不等于已验证该拼写路径可用；本文核定源码另有 `app/releaseNotes`，需逐页检查。不要把兼容旧 URL 或一个尚未部署的分支功能当现役服务保证。[2]

## 本次核验范围（2026-10-09）

- 已读取官网、README 与固定源码 `e63b073559428a4a314077e2ee99f9a928ac390e`；主站及两个上游公布备用站返回了含 NoUnityCN 内容的页面。
- 官方 API 与主站 `/api/releases` 对同一示例查询均返回 `2022.3.62f1`、`shortRevision=4af31df58517`，Windows x64 Editor 官方 URL 一致。[9][10]
- 已读取 GitHub 最新 Release 的资产元数据；没有下载大安装包、运行这些包、验证其本地签名，或进行 Windows/macOS/Linux 安装/激活。上述可达性不是未来可用承诺。
- 博客/知乎的历史经验另见 [community-reference-notes.md](community-reference-notes.md)，低于原实测流程，不能据此改默认版本、浏览器或代理。

## Sources

[1] https://www.nounitycn.top
[2] https://github.com/DanKE123abc/NoUnityCN
[5] https://api.github.com/repos/DanKE123abc/NoUnityCN/contents/lib/unity-api.ts?ref=e63b073559428a4a314077e2ee99f9a928ac390e
[6] https://api.github.com/repos/DanKE123abc/NoUnityCN/contents/app/unityhub/page.tsx?ref=e63b073559428a4a314077e2ee99f9a928ac390e
[7] https://api.github.com/repos/DanKE123abc/NoUnityCN/contents/.github/workflows/unityhub-sync.yml?ref=e63b073559428a4a314077e2ee99f9a928ac390e
[8] https://api.github.com/repos/DanKE123abc/NoUnityCN/releases/latest
[9] https://services.api.unity.com/unity/editor/release/v1/releases?version=2022.3.62f1&platform=WINDOWS&architecture=X86_64&limit=1
[10] https://www.nounitycn.top/api/releases?version=2022.3.62f1&platform=WINDOWS&architecture=X86_64&limit=1
