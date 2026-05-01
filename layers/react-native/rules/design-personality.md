# Design Personality — Beyond Platform Defaults

Platform defaults produce generic, template-like UIs. This rule defines how to create polished, distinctive interfaces in React Native.

**Philosophy: iOS HIG's "deference to content" — UI should not shout. Content is the star.**

## Token Overrides

### Typography
- **Do NOT rely on system default fonts** — they look like every other app
- Use a modern alternative: Inter, Pretendard, Plus Jakarta Sans, or project-specific brand font
- Load custom fonts via `expo-font` or `useFonts` hook
- Tighten the typescale to **5-7 levels**:
  - Display (hero text only)
  - Headline (section headers)
  - Title (card/list headers)
  - Body (main content)
  - Label (captions, chips, buttons)
- Letter spacing: tighter than defaults (-0.02em to 0em)
- Noto Sans JP for Japanese text

### Color
- **Single accent color** for CTAs and links only — do NOT spread primary across surfaces
- Surfaces: high-neutral palette (grays, not colored surfaces)
- Dark mode: `#121212` to `#1C1C1E` (not pure black `#000000`)
- Define all colors as design tokens in `constants/tokens.ts`

### Corner Radius
- **Unified radius**: 12 for all components (cards, buttons, dialogs, sheets)
- Small elements (chips, badges): 8
- Full round: FAB only
- No per-component radius variation

### Shadows
- Use subtle, layered shadows:
  ```tsx
  const softShadow = {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 4,
  };
  ```
- Shadow = "feel it, don't see it"

### Press Indication
- Do NOT use default opacity reduction (feels cheap)
- Use subtle background alpha change:
  ```tsx
  <Pressable style={({ pressed }) => [
    styles.button,
    pressed && { backgroundColor: 'rgba(0,0,0,0.04)' }
  ]}>
  ```
- Or use Reanimated for smooth press animations

### Animation & Motion
- Use iOS-inspired easing via Reanimated:
  ```tsx
  withTiming(value, {
    duration: 280,
    easing: Easing.bezier(0.25, 0.1, 0.25, 1.0),
  })
  ```
- Duration: 250-350ms
- Spring animations:
  ```tsx
  withSpring(value, { damping: 15, stiffness: 400 })
  ```
- Shared element transitions: use Expo Router's built-in support

### Spacing
- **8pt grid, strictly enforced** — only these values:
  - 4 / 8 / 12 / 16 / 24 / 32 / 48
- No arbitrary values (no 10, 14, 20)
- Section gaps: 24 or 32
- List item spacing: 8 or 12
- Screen horizontal padding: 16 (consistent across all screens)
- Define as `spacing` object in tokens

### Content Density
- List row height: 48 (not platform default 56)
- Card internal padding: 12 to 16
- Embrace whitespace — it's part of the design, not wasted space

## Component Rules

### Navigation
- Bottom tabs: max 5 items, icons + labels always visible
- Header: large title with collapse behavior for content screens (Expo Router `headerLargeTitle`)
- No drawer unless absolutely necessary (prefer bottom sheet)

### Cards
- Minimal elevation — use subtle border (`borderWidth: 0.5, borderColor: 'rgba(0,0,0,0.08)'`) instead of shadow
- Or: background color differentiation only (no border, no shadow)
- Content-first: image/data prominent, chrome minimal

### Buttons
- Primary: filled, single accent color, borderRadius 12
- Secondary: outlined or text-only, never filled with secondary color
- Destructive: red accent, text-only or outlined (never large filled red button)

### Empty / Loading / Error States
- Empty: illustration + message + single CTA (not just text)
- Loading: skeleton shimmer (not ActivityIndicator) for content areas
- Error: inline message + retry, not full-screen error

## Reference-Driven Design

When implementing a new screen:
1. Find 2-3 reference screenshots from polished apps (Mobbin, App Store, competitor)
2. Include screenshots in the prompt to Claude Code
3. Specify: "Match this visual density and spacing, adapt to our design tokens"
4. Do NOT say "make it look like X app" — say what specifically to match (spacing, hierarchy, density)

## What This Rule Does NOT Cover

- Brand identity (logo, brand colors, illustrations) — project-specific
- Platform-specific adaptations (iOS vs Android nav patterns) — mobile-conventions.md
- Accessibility requirements (touch targets, contrast) — mobile-conventions.md + ui-reviewer agent
