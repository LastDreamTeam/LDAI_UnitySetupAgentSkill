# Unity-only route repair

## Diagnose the actual request

Use `probe_routes.py` without browser Cookies. Test `unity.com/releases/editor/archive`, `unity.com/download`, and the actual installer separately. A `.com` installer can return 307 to a China CDN even when a web entry looks international. HEAD may differ from GET; pages use GET, binaries use HEAD to avoid downloading the installer merely to audit it.

The curl route may follow process proxy variables while a browser uses Windows user settings and Hub uses another stack. Inspect current configuration and listeners; never print credentials or change those global settings as a diagnostic. A public geolocation result for Cloudflare/Google describes that request, not Unity/Akamai's classification.

Locale prefixes, English headers and clearing Cookie data are not established fixes when a no-Cookie request already receives a server 302. Do not keep repeating cosmetic variants after they fail. A certificate failure is UNKNOWN; do not disable TLS checks.

## Authorized application-scoped repair

When the user authorizes changing an existing proxy route:

1. Inventory supported existing nodes privately. Do not copy subscriptions, passwords, UUIDs, endpoint addresses or account-bearing labels into a public skill or report.
2. Probe alternatives without changing the active global node. If a temporary diagnostic core is necessary, use the installed trusted binary, a loopback-only ephemeral listener, in-memory configuration and guaranteed process cleanup. Do not install another persistent proxy.
3. Require HTTP 200 with the international archive body and no China hop; also test the binary CDN. An available node or region label alone is insufficient.
4. Read the installed proxy application's current official schema/source before persistence. Do not ship a universal SQLite patch or assume every version has the same fields.
5. Save only the affected routing state locally. Add priority rules for `domain:unity.com` and `domain:unity3d.com` pointing at the verified existing node. Preserve security blocks, existing rules, default node, DNS configuration and other traffic. Do not route all traffic through the new node.
6. Coordinate any brief existing-core restart; disclose its effect before disrupting shared connections. Check loaded runtime rules, not just database writes. Roll back on failure.
7. Verify the original archive URL, content, binary host and unrelated default route sample. Persisted routing should survive a normal application restart. Cached browser tabs already at `.cn` need the original international URL re-entered.

In the verified 2026-10 case, one of eight existing nodes worked; a Unity-only native v2rayN route restored both archive and Hub CDN while the default node and Windows proxy values stayed unchanged. This is evidence for the method, not a universal country/node recommendation.

For v2rayN 7.23.2, a custom rule's `outboundTag` may identify an existing node by an exact, unique remark; the application resolves it and generates a dedicated outbound. Check the installed version first: [routing generation](https://github.com/2dust/v2rayN/blob/7.23.2/v2rayN/ServiceLib/Services/CoreConfig/V2ray/V2rayRoutingService.cs), [context construction](https://github.com/2dust/v2rayN/blob/7.23.2/v2rayN/ServiceLib/Handler/Builder/CoreConfigContextBuilder.cs). Changing/deleting that node or remark can invalidate the rule.

If no authorized route works, stop installation and report the actual missing exit/network decision. Unity's [Release API](https://docs.unity.com/en-us/oas-release/1.0.0) can supply international release/module metadata; it is not proof that the original webpage or binary route has been repaired.
