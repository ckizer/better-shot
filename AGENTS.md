---
name: ui-skills
description: Opinionated constraints for building better interfaces with agents.
---

# BetterShot Agent Rules

## Repo-Specific Rules

- Do not use skills or extra agent workflows in this repository unless the user explicitly requests them.
- Start every AI response with `😎🔥` followed by the response.
- BetterShot is primarily a native macOS app. Do not assume Electron, Tauri, or webview architecture for the app.
- The `bettershot-landing` directory is a separate Next/Tailwind marketing site. Apply frontend rules there, not to SwiftUI/AppKit code.

## Coding Behavior

- Think before coding. State assumptions when the request is ambiguous.
- Ask before implementing if multiple interpretations would lead to meaningfully different code.
- Surface tradeoffs. If a simpler approach exists, say so. Push back when warranted.
- Prefer the simplest solution that fully satisfies the request.
- Do not add speculative features, abstractions, configurability, or broad error handling unless asked.
- Keep changes surgical. Touch only files needed for the task.
- Match existing project style, even when a different style might be personally preferred.
- Do not refactor adjacent code unless required to complete the task.
- Remove only unused code created by your own changes.
- Mention unrelated issues instead of fixing them silently.
- For multi-step tasks, use a short plan and verify each meaningful step.
- Prefer tests, builds, type checks, or targeted manual verification when the change has behavior risk.
- Every changed line should trace back to the user request.

## Documentation / Memory

- If deploying anything significant, document it in `/docs` as its own markdown file so humans and AI agents can reference it later.
- Keep documentation clear, concise, and useful for frontend engineers when it concerns the landing site.
- For user-facing app or website changes, update `CHANGELOG.md` or a running list of website changes with a high-level concise note.
- Update `docs/HANDOFF.md` after meaningful work sessions with what was built, what was decided and why, open questions, and the next slice.

# UI Skills

Opinionated constraints for building better interfaces with agents.

## Stack

- MUST use Tailwind CSS defaults (spacing, radius, shadows) before custom values
- MUST use `motion/react` (formerly `framer-motion`) when JavaScript animation is required
- SHOULD use `tw-animate-css` for entrance and micro-animations in Tailwind CSS
- MUST use `cn` utility (`clsx` + `tailwind-merge`) for class logic

## Components

- MUST use accessible component primitives for anything with keyboard or focus behavior (`Base UI`, `React Aria`, `Radix`)
- MUST use the project’s existing component primitives first
- NEVER mix primitive systems within the same interaction surface
- SHOULD prefer [`Base UI`](https://base-ui.com/react/components) for new primitives if compatible with the stack
- MUST add an `aria-label` to icon-only buttons
- NEVER rebuild keyboard or focus behavior by hand unless explicitly requested

## Interaction

- MUST use an `AlertDialog` for destructive or irreversible actions
- SHOULD use structural skeletons for loading states
- NEVER use `h-screen`, use `h-dvh`
- MUST respect `safe-area-inset` for fixed elements
- MUST show errors next to where the action happens
- NEVER block paste in `input` or `textarea` elements

## Animation

- NEVER add animation unless it is explicitly requested
- MUST animate only compositor props (`transform`, `opacity`)
- NEVER animate layout properties (`width`, `height`, `top`, `left`, `margin`, `padding`)
- SHOULD avoid animating paint properties (`background`, `color`) except for small, local UI (text, icons)
- SHOULD use `ease-out` on entrance
- NEVER exceed `200ms` for interaction feedback
- MUST pause looping animations when off-screen
- MUST respect `prefers-reduced-motion`
- NEVER introduce custom easing curves unless explicitly requested
- SHOULD avoid animating large images or full-screen surfaces

## Typography

- MUST use `text-balance` for headings and `text-pretty` for body/paragraphs
- MUST use `tabular-nums` for data
- SHOULD use `truncate` or `line-clamp` for dense UI
- NEVER modify `letter-spacing` (`tracking-`) unless explicitly requested

## Layout

- MUST use a fixed `z-index` scale (no arbitrary `z-x`)
- SHOULD use `size-x` for square elements instead of `w-x` + `h-x`

## Performance

- NEVER animate large `blur()` or `backdrop-filter` surfaces
- NEVER apply `will-change` outside an active animation
- NEVER use `useEffect` for anything that can be expressed as render logic

## Design

- NEVER use gradients unless explicitly requested
- NEVER use purple or multicolor gradients
- NEVER use glow effects as primary affordances
- SHOULD use Tailwind CSS default shadow scale unless explicitly requested
- MUST give empty states one clear next action
- SHOULD limit accent color usage to one per view
- SHOULD use existing theme or Tailwind CSS color tokens before introducing new ones
