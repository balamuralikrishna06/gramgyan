---
name: mobile-app-design
description: Design and build stunning, production-grade mobile application frontends with exceptional UI/UX quality. Use this skill when the user asks to build mobile apps, cross-platform apps, native mobile UIs, or mobile-first interfaces (examples include React Native apps, Flutter apps, Expo projects, Ionic apps, mobile PWAs, or when designing/styling any mobile user interface). Generates polished, performant, platform-aware code that avoids generic mobile patterns.
---

This skill guides creation of distinctive, production-grade mobile application frontends that avoid generic "template-quality" interfaces. Implement real working code with exceptional attention to platform conventions, performance, interaction design, and visual polish.

The user provides mobile app requirements: screens, flows, features, or an entire application to build. They may include context about the target platform, audience, brand identity, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD design direction:
- **Purpose**: What problem does this app solve? Who uses it, and in what context (on-the-go, focused task, passive browsing)?
- **Platform**: iOS, Android, or cross-platform? Each has distinct design languages — respect them while adding character.
- **Tone**: Pick a strong aesthetic: minimal/clean, bold/vibrant, soft/organic, dark/immersive, playful/illustrated, luxury/refined, brutalist/raw, glassmorphic, neomorphic, material-you-inspired, editorial, retro-digital, or something entirely unique.
- **Constraints**: Performance budgets, offline requirements, accessibility needs, device targets (phones, tablets, foldables).
- **Differentiation**: What makes this app UNFORGETTABLE? What's the one interaction someone will remember?

**CRITICAL**: Choose a clear design direction and execute it with precision. A beautiful minimal app and a richly animated maximalist app both succeed — the key is intentionality, not intensity. Generic apps with default components and no personality FAIL.

Then implement working code that is:
- Production-grade, performant, and functional
- Visually striking with a clear aesthetic point-of-view
- Platform-aware with proper native conventions
- Meticulously refined in every detail — spacing, motion, touch targets

## Mobile Design Guidelines

Focus on:
- **Typography**: Choose fonts that elevate the experience. Avoid settling for system defaults unless the design calls for it. Use distinctive display fonts for headers, clean readable fonts for body. Pair fonts intentionally. Respect platform conventions — San Francisco on iOS, Roboto on Android — but don't be afraid to introduce custom typefaces that match the brand. Use dynamic type sizes with proper scaling for accessibility.
- **Color & Theme**: Commit to a cohesive color system. Use semantic color tokens (primary, secondary, surface, error, onPrimary, etc.) with CSS variables or theme objects. Support both light and dark modes from the start. Bold accent colors with purposeful usage outperform timid, evenly-distributed palettes. Respect system-level appearance preferences. Use color to establish hierarchy, not decoration.
- **Motion & Haptics**: Animations are not optional — they convey meaning. Use spring-based physics for natural feel (React Native Reanimated, Flutter AnimationController). Implement shared element transitions between screens. Add micro-interactions: button press scales, pull-to-refresh animations, skeleton loaders, shimmer effects. Match platform conventions — iOS uses smooth spring curves, Android uses Material motion. Consider haptic feedback for key interactions (success, error, selection).
- **Touch & Gesture**: Design for thumbs. Place primary actions in the bottom third of the screen (thumb zone). Use minimum 44×44pt / 48×48dp touch targets. Implement swipe gestures (swipe-to-delete, swipe-to-archive) where appropriate. Support long-press context menus. Use bottom sheets instead of modals when possible. Design for one-handed operation.
- **Navigation**: Choose the right pattern for the content: bottom tabs for top-level sections (max 5), stack navigation for drill-down flows, drawer for secondary navigation, top tabs for peer content. Use platform-native navigation patterns — iOS uses edge-swipe back gesture, Android uses back button/gesture. Keep navigation predictable and shallow (max 3-4 levels deep).
- **Layout & Spacing**: Use a consistent spacing scale (4pt/8pt grid). Design for variable screen sizes — use responsive layouts, not fixed dimensions. Account for safe areas (notches, home indicators, status bars). Use cards and containers to group related content. Generous white space creates premium feel. Design for both portrait and landscape where appropriate.
- **Loading & Empty States**: Never show blank screens. Use skeleton screens for loading (not spinners). Design meaningful empty states with illustrations and CTAs. Implement optimistic updates for instant-feeling interactions. Show inline loading indicators for partial-screen updates. Use progressive loading for lists and images.
- **Platform Conventions**: Respect each platform's design language while maintaining brand identity. iOS: large titles, SF Symbols, blur effects, sheets. Android: Material You, dynamic color, top app bars, FABs. Cross-platform: find the middle ground that feels native on both without being generic on either.

## Project Structure Conventions

Organize mobile projects with clear separation. Adapt to the framework, but maintain this conceptual structure:

### React Native / Expo
```
src/
├── app/                  # Screen definitions and navigation (Expo Router)
│   ├── (tabs)/           # Tab-based navigation group
│   ├── (auth)/           # Auth flow screens
│   └── _layout.tsx       # Root layout with providers
├── components/
│   ├── ui/               # Reusable UI primitives (Button, Card, Input, etc.)
│   ├── forms/            # Form-specific components
│   └── [feature]/        # Feature-grouped components
├── hooks/                # Custom hooks (useAuth, useTheme, useAPI, etc.)
├── services/             # API clients, storage, analytics
├── stores/               # State management (Zustand, Redux, Jotai)
├── theme/                # Colors, typography, spacing tokens
│   ├── colors.ts
│   ├── typography.ts
│   └── spacing.ts
├── utils/                # Shared helpers, formatters, validators
├── types/                # TypeScript type definitions
└── assets/               # Images, fonts, animations (Lottie)
```

### Flutter
```
lib/
├── app/                  # App entry, routing, dependency injection
├── features/             # Feature modules
│   └── [feature]/
│       ├── presentation/ # Screens, widgets, state (BLoC/Riverpod)
│       ├── domain/       # Entities, use cases, repository interfaces
│       └── data/         # Repository implementations, models, datasources
├── core/
│   ├── theme/            # ThemeData, colors, text styles
│   ├── widgets/          # Shared reusable widgets
│   ├── utils/            # Helpers, extensions, formatters
│   └── constants/        # App-wide constants
└── assets/               # Images, fonts, animations
```

## Anti-Patterns to Avoid

NEVER use naive mobile implementations like:
- Default unstyled components with no personality or brand identity
- Fixed pixel dimensions that break on different screen sizes
- Spinners everywhere instead of skeleton screens and shimmer effects
- Modals and alerts for everything instead of contextual inline interactions
- Ignoring safe areas (content hidden behind notches, navigation bars)
- Tiny touch targets (< 44pt) that frustrate users
- No loading, error, or empty states — just blank screens
- Blocking the main thread with heavy computations
- Ignoring platform conventions (iOS back swipe, Android back button)
- Static, lifeless interfaces with zero animation or transition
- One-size-fits-all navigation (forcing tabs when a stack works better)
- Placeholder images and Lorem Ipsum in final output
- Ignoring dark mode / system appearance preferences
- Hardcoded strings instead of localizable text

## Framework & Tooling Quick Reference

| Framework       | Language     | Styling                          | Navigation                  | State Management              | Animation                       |
| --------------- | ------------ | -------------------------------- | --------------------------- | ----------------------------- | ------------------------------- |
| React Native    | TypeScript   | StyleSheet, NativeWind, Tamagui  | React Navigation, Expo Router | Zustand, Redux, Jotai, TanStack Query | Reanimated, Moti, Lottie       |
| Flutter         | Dart         | ThemeData, Custom Widgets        | GoRouter, AutoRoute          | Riverpod, BLoC, Provider      | AnimationController, Rive       |
| Expo            | TypeScript   | StyleSheet, NativeWind           | Expo Router (file-based)     | Zustand, Jotai                | Reanimated, Moti, Skia          |
| Ionic           | TypeScript   | CSS, Tailwind, Ionic themes      | Ionic Router, Angular Router | NgRx, Signals, Stencil Store  | Ionic Animations, GSAP          |
| SwiftUI (ref)   | Swift        | Native modifiers                 | NavigationStack              | @State, @Observable, Combine  | withAnimation, matchedGeometry  |
| Jetpack Compose | Kotlin       | Material3 theme, Modifier chains | Navigation Compose           | ViewModel, StateFlow, Hilt    | animate*AsState, AnimatedContent|

## Decision Framework

```
What type of mobile app is this?
├── Simple utility (calculator, timer, notes)
│   └── Single-screen or minimal nav, focus on polish and micro-interactions
├── Content-driven (news, social, media)
│   └── Tab navigation, infinite scroll, image caching, offline support
├── Task/workflow app (banking, health, productivity)
│   └── Stack navigation, form flows, validation, secure storage
├── Real-time/social (messaging, collaboration)
│   └── WebSockets, push notifications, optimistic updates, presence indicators
└── E-commerce / marketplace
    └── Complex navigation, search/filter, cart state, payment flows, deep linking

Cross-platform or native?
├── Need to ship fast on both platforms → React Native / Expo or Flutter
├── Platform-specific features critical → SwiftUI + Jetpack Compose
├── Existing web team → React Native (shared knowledge) or Ionic
└── High-performance graphics/animation → Flutter or native
```

## Performance Essentials

- **Images**: Use progressive loading, proper sizing, and caching (FastImage for RN, cached_network_image for Flutter). Use WebP format. Lazy-load off-screen images.
- **Lists**: Use virtualized lists (FlatList/FlashList for RN, ListView.builder for Flutter). Never render all items at once. Implement pull-to-refresh and infinite scroll.
- **Bundle Size**: Tree-shake unused code. Lazy-load screens and heavy modules. Monitor bundle size in CI.
- **Startup**: Minimize work before first paint. Use splash screens with smooth transitions into the app. Defer non-critical initialization.
- **Memory**: Dispose listeners, timers, and subscriptions on unmount. Avoid memory leaks from closures and event handlers. Profile with platform tools (Instruments, Android Profiler).

Interpret requirements thoughtfully and make bold design choices that serve the user and context. No two mobile apps should look the same. Vary between light and dark themes, different type scales, different interaction paradigms — based on the actual use case, not defaults.

**IMPORTANT**: Match design complexity to the app's purpose. A meditation app needs calm restraint with breath-like animations. A fitness app needs energy with bold colors and progress visualizations. A banking app needs trust with clean layouts and precise typography. The design should serve the user's emotional and functional needs.

Remember: Mobile apps live in users' pockets — the most personal screen they own. Every pixel, every animation, every interaction is felt intimately. Build interfaces that feel like they were crafted by someone who cares deeply about the experience.
