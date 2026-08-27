# Project 543 — GDD Clarification Register

**Repository:** https://github.com/shreepremgopal/project543

Purpose: track GDD ambiguities before they become hidden implementation rules.

## CR-001 — Exact Ideology Alignment Formula

**Status:** Open

The GDD specifies six-dimensional vectors and an alignment score from 0.00 to 1.00, but not the exact distance metric and conversion function.

## CR-002 — Exact Election Risk Modifier

**Status:** Open

The election formula includes a Risk Modifier, while the GDD separately defines fundraising risk/scandal behaviour. The exact numerical conversion into Election Strength is not fully specified.

## CR-003 — Campaign Saturation Curve

**Status:** Open

The GDD gives an illustrative +1.00%, +0.80%, +0.60% sequence and says the exact curve should be configurable. The canonical curve remains open.

## CR-004 — Persona Vector Catalogue

**Status:** Open

The GDD names 25 personas and gives an example vector but does not provide a complete authoritative six-dimensional vector table for all 25.

## CR-005 — Constituency Population Dataset

**Status:** Open

The GDD requires a selected national population dataset and explicitly says not to artificially force a 1.5 billion total. The authoritative source/methodology remains to be selected.

## CR-006 — Production GIS Dataset

**Status:** Open

Sprint 2 distinguishes prototype geometry from production/authoritative data. Sprint 3 also notes limitations in the current visualization dataset. Do not describe prototype geometry as legally authoritative boundary data.

## CR-007 — Exact AI Target-Scoring Formula

**Status:** Open

The GDD proposes Potential Seat Value × Probability of Winning ÷ Campaign Cost but does not fully define the component calculations or weights.

## CR-008 — Manifesto Catalogue and Exact Effects

**Status:** Open

The GDD defines manifesto structure/design philosophy but leaves the exact catalogue and costs/effects to balancing.

## CR-009 — Randomness Scope

**Status:** Partially defined

The GDD requires minimal randomness and deterministic outcomes for identical inputs/seed. Any randomness must have documented purpose, range and seed behaviour.

## CR-010 — Engine Metadata Consistency

**Status:** Open

The GDD header currently says Engine: TBD, while the repository README/development logs identify Godot 4.7.2/GDScript. Resolve through formal documentation update rather than silent contradiction.
