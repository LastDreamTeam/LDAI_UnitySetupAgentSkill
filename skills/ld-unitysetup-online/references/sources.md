# Maintained sources

Use current primary documentation before changing installation commands, workload IDs, supported operating systems, module IDs, or CLI behavior.

## Primary sources

- Unity Hub installation: https://docs.unity.com/en-us/hub/install-hub-win-mac
- Unity Editor installation and archive workflow: https://docs.unity.com/en-us/hub/add-editor
- Unity Hub CLI: https://docs.unity.com/en-us/hub/hub-cli
- Unity CLI reference and proxy diagnostics: https://docs.unity.com/en-us/unity-cli/unity-cli-reference
- Unity Hub log locations: https://docs.unity.com/en-us/hub/hub-log-locations
- Unity Releases API: https://docs.unity.com/en-us/oas-release/1.0.0
- Unity archive: https://unity.com/releases/editor/archive
- Unity Package Manager configuration: https://docs.unity3d.com/Manual/upm-config.html
- Visual Studio installation: https://learn.microsoft.com/visualstudio/install/install-visual-studio
- Visual Studio workload IDs: https://learn.microsoft.com/visualstudio/install/workload-and-component-ids
- Visual Studio Tools for Unity: https://learn.microsoft.com/visualstudio/gamedev/unity/get-started/getting-started-with-visual-studio-tools-for-unity
- VS Code Unity development: https://code.visualstudio.com/docs/other/unity
- Git for Windows: https://git-scm.com/install/windows
- GitHub Git setup: https://docs.github.com/get-started/git-basics/set-up-git
- GitHub remote repositories: https://docs.github.com/get-started/git-basics/about-remote-repositories
- OpenAI Codex IDE extension: https://developers.openai.com/codex/ide

## Supplementary community reading

These sources can suggest symptoms or experiments but are not installer trust roots. Existing verified skill practice takes priority over supplementary articles; check current primary evidence and explicitly revalidate any conflict rather than silently adopting a new source. The provider reports a past success once, not current success of every article or step. Detailed status and adopted/rejected claims are in [historical auxiliary reference notes](community-reference-notes.md):

- https://zhuanlan.zhihu.com/p/1914827912286307473 — supplied historical reference; on 2026-10-09 the page and public article endpoint returned 403, so its body/title/instructions were not verified. Do not attribute another article's steps to this URL.
- https://www.cnblogs.com/mthoutai/p/19614230 — describes proxy environment variables and region redirects. Its advice to avoid all `f1` releases is overbroad; check the complete suffix, feed, and signature instead.
- https://www.nounitycn.top/ and https://github.com/DanKE123abc/NoUnityCN — third-party index/source, not an official Unity service. See [download fallback routes](download-fallbacks.md) for upstream-published alternate sites, official API comparison, Hub URI versus installer delivery, reviewed Hub mirror candidates and offline transfer. Preserve service/region conditions and separate source-code licensing from Unity artifacts/licensing.

## Maintenance rule

Record observed behavior as evidence, not timeless fact. Region redirects, Unity service endpoints, CLI commands, Visual Studio editions, VS Code extension dependencies, and Git releases can change. Re-check current primary sources before updating this skill. v2rayN's version-specific routing sources are linked in proxy-routing.md; do not assume a historical database schema is a universal API.
