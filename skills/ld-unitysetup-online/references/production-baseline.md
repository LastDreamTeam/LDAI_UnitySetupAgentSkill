# International Unity production baseline

Use this baseline for Windows workstations that must open, build, and collaborate on serious Unity projects. Derive exact versions from the supplied project rather than embedding a project name or path.

## Operating system and Unity

- Supported Windows 10/11 x64; prefer a currently supported Windows 11 release on a new workstation.
- Current stable international Unity Hub, signed by Unity Technologies.
- Exact international Editor version from `ProjectSettings/ProjectVersion.txt`.
- Do not substitute a close version automatically. Unity serialization, packages, render pipelines, native plugins, and IL2CPP output can differ between patch releases.
- Base production module: Windows Build Support (IL2CPP).
- Add Android Build Support, Android SDK/NDK Tools, and OpenJDK when Android output is required.
- Add Web, Linux, server, documentation, or language modules only when the project or user needs them.
- Simplified Chinese UI and the `language-zh-hans` module are compatible with an international Editor and are not China-build evidence.

## Visual Studio

Preferred normal profile:

- Current stable Visual Studio 2026 Community, Professional, or Enterprise according to licensing.
- Workload ID: `Microsoft.VisualStudio.Workload.ManagedGame`.
- Required Unity integration component: `Microsoft.VisualStudio.Component.Unity`.
- Include recommended HLSL tooling when shader work is expected.
- Let a repository `.vsconfig` add required workloads, but inspect it before installation.

Compatibility profile:

- Visual Studio 2022 is the normal fallback for older Unity/package combinations.
- Visual Studio 2019 is a legacy/lightweight fallback only when a project actually needs it.
- Do not treat an uninstall entry or installation folder as proof. Use `vswhere -prerelease -products *` and require `isComplete` plus `isLaunchable`.
- A prerelease/Insiders Visual Studio can coexist with stable versions, but do not make it the only production IDE unless the user accepts prerelease risk.

Visual Studio is the primary Unity IDE for deep C# reference analysis, debugging, solution navigation, and human editing. Configure Unity's External Script Editor after the correct Visual Studio Editor package is present.

## VS Code and Codex

VS Code is the secondary lightweight editor for quick code edits, Markdown, JSON, YAML, logs, and other text-oriented artifacts.

- Install current stable VS Code from Microsoft.
- Install Microsoft's C# and Unity extensions. The modern Unity extension installs or depends on the current C# tooling.
- The legacy Unity `com.unity.ide.vscode` package is not sufficient proof of modern VS Code support. Microsoft's Unity extension uses the Unity Visual Studio Editor package instead.
- The official Codex IDE extension is optional and should be installed only from the link in official OpenAI documentation.
- Do not install editor extensions silently. Show the publisher and requested extension, then obtain confirmation.

## Git and GitHub

Required:

- Current Git for Windows.
- Git LFS for large Unity assets.
- Git Credential Manager for HTTPS, or a user-managed SSH authentication path.
- A valid repository remote and branch-based workflow.

Recommended:

- GitHub CLI for repository/authentication diagnostics and pull-request workflows.
- `core.longpaths=true` when the repository demonstrates Windows path-length failures. Prefer repository-local configuration; do not change global/system Git configuration without authorization.
- A reviewed `.gitattributes` with LFS patterns suitable for the project's binary assets.

Readiness levels:

- `Local ready`: Git, LFS, working tree, branch, and remote syntax are valid.
- `Fetch ready`: the user-authorized remote read succeeds.
- `Push capable`: authentication is configured and the user has repository write permission. Do not prove this by creating a test commit or push during an audit.

## Useful supporting tools

Install only when the project needs them:

- GitHub CLI.
- .NET SDK for external tooling; Unity uses its own managed toolchain for the Editor.
- Node.js/npm for web tooling, packages, or documentation pipelines.
- Python for project utilities.
- Native vendor SDKs, device drivers, streaming software, XR runtimes, or motion-capture tools.

These are project-derived additions, not universal Unity prerequisites.
