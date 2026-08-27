# Project 543 — Development Governance V0.1

**Repository:** https://github.com/shreepremgopal/project543

## Authority Hierarchy

1. GDD V0.1 — product constitution
2. Approved architecture decisions
3. Development roadmap
4. System specifications
5. Sprint specifications
6. Implementation
7. UI/presentation details

If lower-level implementation conflicts with a higher-level approved document, the conflict must be surfaced rather than silently resolved.

## GDD Supremacy Rule

The GDD is the source of product intent for v0.1. Ambiguities or missing specifications must be recorded in the Clarification Register.

## Core-System Rule

A backbone system is one whose behaviour can materially change the strategic identity or balance of Project 543. Backbone systems require a written model specification, inputs/outputs, invariants, edge cases, tests and an integration contract.

## UI Independence Rule

Simulation logic must not depend on UI implementation. The GDD explicitly states that the Election Engine should not directly control UI.

## Data-Driven Rule

Values identified by the GDD as configurable must not be embedded as unexplained gameplay constants.

## Determinism Rule

The election engine must be reproducible from the same relevant state and seed.

## Validation Rule

Invalid data must fail loudly during development rather than silently generating a bad election.

## Sprint Rule

Every sprint must contain an objective, GDD requirements covered, systems affected, dependencies, acceptance criteria, tests, out-of-scope items, stop conditions and resulting documentation.

## Change Control

Changes to core formulas, entity definitions, simulation interfaces, turn structure, victory condition, scope or major data assumptions require a documented architecture/design decision.

## Prototype Rule

A research prototype may be disposable only when explicitly labelled as such. A validated core model is not to be replaced by UI-driven implementation.

## Integration Rule

Vertical slices are used primarily to validate integration between already-defined systems.

## Current Baseline

The existing 543-seat map/GIS implementation is retained as the world/presentation foundation. The next architectural work is simulation-oriented.
