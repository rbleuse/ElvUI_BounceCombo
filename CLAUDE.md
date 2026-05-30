# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ElvUI_BounceCombo** is a World of Warcraft addon that adds a bounce animation to ElvUI's combo point display when combo points are gained. It supports the Classic Anniversary clients (Vanilla and TBC).

- **Author:** Spanja
- **Version:** 1.1
- **Dependency:** ElvUI (required)

## Architecture

The addon is a single-file ElvUI plugin ([ElvUI_BounceCombo.lua](ElvUI_BounceCombo.lua)) following ElvUI's module pattern:

- **Module registration:** `E:NewModule("BounceCombo", "AceHook-3.0", "AceEvent-3.0")` — uses Ace3 mixins for hooking and events.
- **Default profile:** Defaults are stored in `P.bounceCombo` (ElvUI's profile table), picked up automatically by ElvUI's db system. Keys: `enable`, `scale`, `duration`, `smooth`.
- **Hook strategy:** On `PLAYER_ENTERING_WORLD` (`HookClassPower`), `SecureHook` patches `ClassPower.PostUpdate` on `ElvUF_Player`, then unregisters the event. The handler `PostUpdateClassPower` only animates the *newly gained* combo points (tracked via `element._bounceComboPrevious`) and ignores non-`COMBO_POINTS` power types. Animations are created lazily on first combo point gain per frame.
- **Animation:** Each combo point frame gets a `bounceAnim` AnimationGroup with two chained Scale animations (`_scaleUp` → `_scaleDown`). Settings (scale, duration, smoothing) are applied at creation in `CreateBounceAnimation` and refreshed via `UpdateAnimationSettings`/`UpdateAllSettings` when the user changes options. `smooth` toggles easing (`OUT`/`IN`) vs. linear (`NONE`).
- **Options panel:** Injected into `E.Options.args.bounceCombo` (AceConfig group), surfaced in ElvUI's config UI. Profile changes are re-read via `RefreshDB`, wired through ElvUI's `OnProfileChanged`/`OnProfileCopied`/`OnProfileReset` callbacks.

## Development Notes

- No build system — Lua files are loaded directly by the WoW client via the `.toc` files.
- To test: copy/symlink the addon folder into `Interface/AddOns/`, reload WoW UI with `/reload`.
- There are two `.toc` files; the Anniversary client auto-selects the matching one by expansion. Both load the same `ElvUI_BounceCombo.lua`:
  - `ElvUI_BounceCombo_Vanilla.toc` — `## Interface: 11508`
  - `ElvUI_BounceCombo_TBC.toc` — `## Interface: 20505`
- The `## Interface:` versions must match the client patch (Classic Era 1.15.x → `11508`, TBC 2.5.5 → `20505`).
- ElvUI globals used: `E`, `L`, `P` (unpacked from `ElvUI`), and `_G.ElvUF_Player`.
