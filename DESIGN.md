# Aarogya Setu — UI Design Rules

Read this fully before touching any screen. These rules are binding for every UI change.

## 1. Who we design for

- **ASHA workers** in the field: one hand on the phone, often in sunlight, patchy network, many visits a day. They need speed and certainty.
- **Rural citizens**: varied literacy, many first-time smartphone users, often older eyes.
- **PHC doctors**: busy, need to scan an urgent queue fast.

So the interface must be **calm, minimal, large, obvious**. Not poppy, not decorative. If a choice adds visual excitement but not clarity, remove it.

## 2. Principles

1. **One main action per screen.** It is a full-width `AppButton` at the bottom of the content (or a FAB on list screens). Everything else is secondary (outlined/text).
2. **Words + icons, always.** No icon-only actions except standard app-bar back/close. Every `IconButton` gets a `tooltip`.
3. **Colour means something.** Teal = brand/interactive. Red/amber/green = triage only. Never use colour as the only signal (pair with icon + word).
4. **Plain language.** Short sentences, everyday words. "Save visit" not "Persist screening record". "Urgent" not "RED — High Urgency". No jargon in citizen-facing text; clinical terms are OK on doctor screens.
5. **Show state honestly.** Offline/sync state via `NetworkBanner` / `SyncStatusBadge`; loading via spinner + label; empty lists via `EmptyState`.
6. **Forgiving.** Confirm destructive actions; validate inline with helpful messages; keep entered data on errors.

## 3. Tokens (never hardcode)

All from `lib/core/constants/app_colors.dart`. **Do not write `Color(0x...)`, `Colors.<name>` (except `Colors.white`/`Colors.transparent`), or magic spacing numbers in screens.**

| Use | Token |
|---|---|
| Brand / interactive | `AppColors.primary`, `primaryDark`, `primarySurface` (tinted bg, selected state) |
| Attention accent (sparingly) | `AppColors.secondary`, `secondarySurface` |
| Triage | `riskRed/riskRedSurface`, `riskYellow/riskYellowSurface`, `riskGreen/riskGreenSurface` |
| Text | `textPrimary` (main), `textSecondary` (supporting), `textMuted` (hints/meta only) |
| Lines | `border` (card/input outline), `divider` (separators) |
| Page / card | `background` (scaffold), `surface` (cards, app bar) |
| Spacing | `AppSpacing.xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32`, `AppSpacing.screen` |
| Radius | `AppRadius.card` (12), `AppRadius.control` (10), `AppRadius.sm` (8), `AppRadius.pill` |
| Sizes | `AppSizes.minTouch 48 · button 52 · primaryButton 56` |

`roleAsha/roleDoctor/rolePatient` all equal `primary` — do not reintroduce per-role colours.

## 4. Typography

Use `Theme.of(context).textTheme.*` where possible. Scale (already in `AppTheme`):

| Style | Size | Use |
|---|---|---|
| headlineSmall | 24 / w700 | Screen hero line (one per screen max) |
| titleLarge | 21 / w700 | Dialog titles, big section |
| titleMedium | 18 / w600 | Section headers |
| titleSmall | 16 / w600 | Card titles, list item names |
| bodyLarge/Medium | 17/16 | Body text |
| bodySmall | 14 | Supporting text (textSecondary) |
| labelSmall | 13 | Minimum — meta, timestamps, nav labels |

**Hard rules:** no text below **13**. Body ≥ 16. Only weights **w400, w600, w700** (no w800/w900, no `bold`→ use w700). No `letterSpacing` tweaks, no ALL-CAPS labels, no custom `fontFamily`.

## 5. Surfaces & decoration

- **Banned:** `LinearGradient`/`RadialGradient`, `BoxShadow`, `elevation > 1`, glassmorphism, decorative blobs/circles, emoji as decoration, multi-colour text.
- Cards: `InfoCard` (white, 1px `border`, radius 12). Use `accent:` for a left triage stripe on referral/screening cards.
- Separation by whitespace and 1px borders, not shadows.
- App bars: theme default (white, dark text, bottom divider). Do not set `backgroundColor` on `AppBar`.
- Icons: Material `*_rounded` or `*_outlined`, size 20–28. Icon "chips" use `primarySurface` square (radius 8) with `primary` icon — no coloured circles per item.
- Images/illustrations only where they carry information (video thumbnails, logo).

## 6. Components — use these first

From `lib/features/shared/widgets/ui.dart`:

- `AppButton(label, icon, onPressed, secondary:, destructive:, loading:)` — full-width 56dp.
- `InfoCard(child, onTap, accent, padding)` — every card.
- `SectionHeader('Title', actionLabel:, onAction:)` — section titles in scroll views.
- `StatTile(label, value, icon, color, onTap)` — dashboard counts. Max 2 per row on phone.
- `ActionTile(title, subtitle, icon, onTap)` — home-screen task list rows (replaces fancy grids).
- `EmptyState(icon, title, message, action)` — any empty list.
- `InfoRow(label, value, valueColor:)` — label/value detail rows (vitals, profile).
- `StatusTag(label, icon:, color:, background:)` — neutral non-triage status ("Pending review", "Saved on phone", "Pregnant").
- `InitialAvatar(name, size:)` — person initial square.
- `StepHeader(step:, total:, title:)` — "Step N of M" + progress for stepped forms.
- `InfoCard(selected: true)` — selectable cards (role choice, options): 2px primary border + tint.
- `AppButton(loading: true, loadingLabel: 'Saving…')` — spinner **with** words.

Triage helpers (`priority_badge.dart`): `priority.color`, `priority.surfaceColor`, `priority.word` (Urgent/Moderate/Normal). **Never write your own triage colour switch.**

Also: `PriorityBadge`, `SyncStatusBadge` (compact still shows the word), `NetworkBanner`, `AppBrandLogo` (already has semantics — don't wrap it), `showSignOutConfirmationDialog`. Bottom sheets are themed (`bottomSheetTheme`) — don't pass shape/backgroundColor.

**App-bar actions:** max 2. Voice help = `TextButton.icon` "Listen". Sign-out may be an `IconButton` (logout icon) **with tooltip "Sign out"** — the one allowed icon-only action besides back/close.

**Errors shown to users:** never show raw exceptions (`$e`, `e.toString()`). Show a plain sentence ("Could not save. Please try again.") and `debugPrint` the error.

**Red/amber/green are triage-only.** Data warnings (duplicates, missing fields) use `AppColors.secondary`/`secondarySurface`; success states ("Saved on phone") use `primary`/`primarySurface`.

Material widgets are themed already — prefer plain `ElevatedButton`, `OutlinedButton`, `TextButton`, `TextField`/`TextFormField`, `ChoiceChip`/`FilterChip`, `ListTile`, `SwitchListTile`, `CheckboxListTile`, `AlertDialog`, `SnackBar` **without per-instance style overrides** unless a rule here requires it.

If you need a pattern that isn't here, build it from tokens, keep it private to your file, and note it in your report.

## 7. Layout

- Screen padding `AppSpacing.screen` (16). Gaps between cards `AppSpacing.md` (12); between sections `AppSpacing.xl` (24) — `SectionHeader` already adds this.
- Phone-first: design at **360 × 800**. Must not overflow at 320 width or with system text scale 1.3. Use `Expanded`/`Flexible`/`Wrap`, never fixed widths for text containers.
- Single column. Grids only for `StatTile` (2 columns max).
- Long forms: grouped into sections with `SectionHeader`; very long flows (screening) become **steps** (`Stepper` or a simple "Step 2 of 4" header + Next/Back buttons). Primary action pinned at the bottom (`bottomNavigationBar: SafeArea(Padding(AppSpacing.screen, AppButton(...)))`) on form screens.
- Lists: `ListView.separated` with `SizedBox(height: AppSpacing.md)` separators, or `InfoCard` stack.
- Bottom navigation: theme `BottomNavigationBar` (white, labels always shown, 26px icons). Remove custom containers/shadows/gradients wrapped around it; a top 1px `divider` border is fine. Max 4–5 items, each with a short one-word label.

## 8. Screen patterns

- **Dashboard (home):** greeting line (`headlineSmall`, e.g. "Namaste, Shanti") + one short status line → 2–4 `StatTile`s → `SectionHeader('Tasks')` → `ActionTile`s → recent items. No hero banners, no illustrations.
- **List screen:** search field (if >10 items) → filter chips (one row, scrollable) → `InfoCard` list → `EmptyState` → FAB/AppButton for "Add".
- **Detail screen:** header card (name, key facts, `PriorityBadge`) → sections of `InfoRow`s → actions at bottom.
- **Form:** labelled fields (label above or floating), helper text for units ("mmHg"), numeric keyboards for numbers, inline validation, pinned primary button.
- **Triage result:** big clear outcome block: `PriorityBadge` + one-sentence meaning + next step; disclaimer in `bodySmall` below. The colour block may use the triage surface colour as background.
- **Chat:** user bubbles `primary` with white text, bot bubbles `surface` with `border`; radius 12; 16px text; input pinned at bottom with a send `IconButton` (tooltip). Suggestion chips as `ActionChip`s.
- **Auth/role select:** logo (stacked) → one line explaining → role choices as large `InfoCard`s/`ActionTile`s (icon + role name + one-line description) → continue button. Demo quick-login stays but as secondary `OutlinedButton`s/`TextButton`s.

## 9. Accessibility checklist (every screen)

- [ ] Every tap target ≥ 48dp.
- [ ] No text < 13, body ≥ 16, contrast AA (use tokens and you're fine).
- [ ] Every `IconButton` has `tooltip`; meaningful images have `semanticLabel`.
- [ ] Triage shown as icon + word, not colour alone.
- [ ] Works at 320 width and text scale 1.3 without overflow.
- [ ] Keyboard types correct (`TextInputType.number`/`phone`), `textInputAction` set on forms.

## 10. Scope rules for implementers

- **UI only.** Do not change models, services, repositories, sync, routing logic, providers, or business rules (`screening_rules.dart`). Keep every existing callback, navigation target, validation rule and data binding working.
- Keep all existing features visible/reachable — simplify presentation, don't delete functionality. You may reorder or merge cluttered sections.
- Replace deprecated `withOpacity(x)` with `withValues(alpha: x)` where you touch it (better: use a token).
- Split very large `build` methods into private widgets/methods in the same file.
- Don't edit shared widgets/tokens/theme; if you need a change there, say so in your report.
- Must pass `flutter analyze` with **no errors or warnings** introduced in your files.
