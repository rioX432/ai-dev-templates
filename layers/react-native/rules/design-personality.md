# Design Personality — Project-grounded React Native UI

Distinctiveness comes from a coherent product point of view, not from replacing every platform default. Apply
this rule only after accessibility, the explicit brief, and the project's existing design system.

## Decision order

1. Accessibility and the user's task
2. Explicit product brief and brand requirements
3. Existing project tokens, components, and interaction patterns
4. iOS and Android conventions for the surface
5. Deliberate visual exploration

A system font, color count, radius, shadow, spacing value, press treatment, or easing curve is not wrong merely
because another choice is more fashionable. Flag it only when it breaks an earlier source in this order or
creates measurable inconsistency, ambiguity, or task friction.

## Establish a visual direction

Before introducing a new visual language, identify:

- the product purpose and intended feeling
- the content or action that should dominate attention
- the existing token and component vocabulary
- one or two intentional differentiators, such as typography, imagery, composition, or motion

Keep the rest restrained. Avoid both unmodified starter-template styling and arbitrary novelty.

## Tokens and components

- Express repeated typography, color, spacing, shape, elevation, and motion choices as project tokens.
- Reuse accessible native or project components when they satisfy the task. Customize their tokens before
  building bespoke controls.
- Preserve platform target sizes, roles and labels, focus/pressed states, font scaling, contrast, and
  reduced-motion behavior when customizing.
- Use a spacing rhythm and radius family rather than one mandatory grid or radius. Exceptions are acceptable when
  the content or component geometry explains them.
- Fonts, shadows, borders, and surface colors are product decisions. Test them on both platforms, light/dark
  themes, translated text, and large text rather than banning or requiring one style globally.

## Motion and feedback

- Motion should explain state change, hierarchy, continuity, or direct manipulation.
- Keep decorative motion subordinate to task completion and honor reduced-motion preferences.
- Every interactive control needs perceivable pressed, focused, disabled, loading, success, and error feedback as
  applicable. A custom press treatment must remain at least as discoverable as the native default.

## Content states

Design loading, empty, error, offline, permission, and partial-content states as part of the flow. Choose skeleton,
spinner, inline feedback, illustration, or full-screen treatment according to expected duration and user action;
no single treatment is universally correct.

## Reference-driven work

Use references to communicate a property, not to copy a brand:

- Name what is relevant: hierarchy, density, content treatment, typography, motion, or navigation.
- Compare the reference with project tokens and platform behavior.
- Keep assets and interaction patterns original unless the user has rights and explicitly asks for faithful
  reproduction.

## Review boundary

This rule guides implementation and optional brand-fit critique. Accessibility requirements belong to the
platform conventions and the UI reviewer. A review finding must cite the project brief, token, component,
platform rule, or observed user impact that the code violates.
