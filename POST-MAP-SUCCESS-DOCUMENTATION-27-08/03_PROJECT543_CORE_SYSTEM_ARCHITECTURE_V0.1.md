# Project 543 — Core System Architecture V0.1

**Repository:** https://github.com/shreepremgopal/project543

## Objective

Build Project 543 as a data-driven simulation whose core rules can be tested independently from the Godot UI. The existing map remains the geographic/presentation foundation.

## Layer Model

### A — Source/Data

GIS data, constituency data, persona data, party definitions, ideology data, business definitions, manifesto definitions and balance parameters.

### B — Domain Models

Constituency, Persona, Party, Business, Campaign State and Election State.

### C — Simulation Systems

Ideology/Alignment, Support/Campaign, Economy, Risk, Turn Resolution, AI Strategy and Election Engine.

### D — Game-State Orchestration

Game Manager, Turn Manager, Party Manager, system coordination and Save/Load coordination.

### E — Presentation

Map Renderer, Constituency Panel, HUD, Party Screen, Business Screen, Manifesto Screen, Election Results and Tutorial.

## Dependency Rule

Presentation consumes game state; game state orchestrates simulation; simulation consumes domain/data. Simulation must not depend on UI.

## Election Engine Boundary

Conceptual interface:

`CalculateElection(constituencies, parties, personas, campaign_state, turnout_data)`

Returns constituency results, party vote totals, party seat totals and winner.

## Determinism

Identical constituency data, party data, persona data, campaign state, turn and seed must produce reproducible results.

## Testability

Core systems must be callable from automated or controlled tests without requiring the complete Godot UI.

## Integration Strategy

The first integration target is a controlled scenario using the same domain models intended for the full 543-seat game. A small scenario is a test harness, not a second permanent constituency architecture.

## Scaling

The target is all parties × 543 constituencies × 25 personas. The GDD says this should be computationally manageable; clean architecture is the priority.

## Data/Logic Separation

Do not hard-code configurable GDD values such as constituency values, persona definitions, party definitions, ideology values, business prices/income, campaign costs/effects, risk formulas, turn length and election parameters.

## Save/Load

Save simulation state rather than making UI state the source of truth.

## Explainability

Simulation outputs should retain enough information to explain why support changed and why a constituency was won or lost.
