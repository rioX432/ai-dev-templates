# React Native Conventions

## Expo (default)
- Use Expo managed workflow — bare workflow only for exceptional native requirements
- EAS Build for CI/CD, EAS Update for OTA updates
- Config Plugins for native customization (no ejecting)
- `npx expo start` for dev server, `npx expo prebuild` for native project generation

## Project Structure (SDK 55+)
```
src/
  app/           # Expo Router file-based routes (thin — re-export from features/)
  features/      # Feature modules (screen logic, hooks, components)
  components/    # Shared UI components
  hooks/         # Shared hooks
  stores/        # Zustand stores
  services/      # API clients, external integrations
  utils/         # Pure utility functions
  types/         # Shared TypeScript types
  constants/     # App-wide constants, design tokens
```
- Routes in `app/` are thin layers — screen logic lives in `features/`
- Promote a component to `components/` only when used in 2+ features
- Path alias: `@/*` maps to `./src/*`

## TypeScript
- `"strict": true` — no exceptions
- Enable `noUncheckedIndexedAccess`, `noImplicitReturns`, `noFallthroughCasesInSwitch`
- Path aliases must be configured in both `tsconfig.json` and `babel.config.js`
- Prefer `interface` for object shapes, `type` for unions/intersections

## Navigation
- Expo Router (file-based routing) — do NOT use React Navigation directly
- Use typed routes via `expo-router` generics
- Layout files (`_layout.tsx`) for shared navigation structure
- Native stack by default — avoid custom JS-based navigation

## State Management
- **Server state**: TanStack Query (`@tanstack/react-query`)
- **Client state**: Zustand (one store per domain: user, canvas, settings)
- Do NOT use Redux for new code
- Do NOT use React Context for frequently changing state (causes re-renders)
- React Hook Form for form state

## Styling
- NativeWind v4 (compile-time Tailwind) or vanilla `StyleSheet.create`
- No inline style objects — extract to `StyleSheet.create` or NativeWind classes
- Design tokens in `constants/tokens.ts` (colors, spacing, typography)
- No magic numbers — reference tokens

## Performance
- Hermes V1 is the default JS engine — no configuration needed
- React Compiler handles memoization automatically — do NOT add manual `useMemo`/`useCallback` unless profiling shows need
- `FlashList` over `FlatList` for long lists
- Reanimated 4 for UI-thread animations — never animate on JS thread
- Gesture Handler for all gestures — never use `PanResponder`
- Use `InteractionManager.runAfterInteractions()` for deferred heavy work
- Image loading: `expo-image` (not `Image` from react-native)

## Canvas / Drawing
- `@shopify/react-native-skia` for canvas rendering
- Gesture Handler + Reanimated shared values driving Skia on UI thread
- Do NOT pass touch coordinates through JS thread — use worklets
- For Apple Pencil pressure/tilt: platform-native module (expo-pencilkit-ui or custom Expo Module)

## Android
- Min touch target: 48dp
- Edge-to-edge display support
- Test on Android emulator with API 34+

## iOS
- Dynamic Type support for all text
- Safe area handling via Expo Router's automatic SafeAreaView or `react-native-safe-area-context`
- Min touch target: 44pt
- Test on iOS Simulator (latest Xcode)

## Testing
- Unit/component: Jest + React Native Testing Library (`@testing-library/react-native`)
- E2E: Maestro (YAML-based, launch + core flow only, keep minimal)
- No Detox unless gray-box synchronization is specifically needed
- Test files: `__tests__/` directories or `*.test.tsx` co-located with source
