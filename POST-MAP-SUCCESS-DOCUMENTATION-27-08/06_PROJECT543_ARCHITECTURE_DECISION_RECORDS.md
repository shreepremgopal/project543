# Project 543 — Architecture Decision Records

**Repository:** https://github.com/shreepremgopal/project543

## ADR-001 — Existing 543 Map Is the Permanent World Foundation

**Status:** Accepted  
**Date:** 27 August 2026

The existing 543-constituency map/GIS architecture remains the permanent world foundation. A separate one-constituency map architecture will not be created as a required permanent implementation step.

## ADR-002 — Core Simulation Systems Are Developed Independently

**Status:** Accepted  
**Date:** 27 August 2026

Backbone systems are designed and tested independently before deep UI integration because election, persona, economy and related models define the strategic identity of Project 543.

## ADR-003 — Vertical Slices Are Integration Tools

**Status:** Accepted  
**Date:** 27 August 2026

Vertical slices remain part of development but primarily prove integration between independently designed systems. They must not become the hidden place where core rules are invented.

## ADR-004 — GDD V0.1 Is Product Authority

**Status:** Accepted  
**Date:** 27 August 2026

The GDD V0.1 is the product constitution for the current version. Ambiguities are logged rather than silently resolved.

## ADR-005 — Simulation Must Be UI-Independent

**Status:** Accepted

Core simulation systems must not require Godot UI execution for their fundamental calculations. The GDD explicitly requires the Election Engine to remain separate from UI.

## ADR-006 — Deterministic Election Engine

**Status:** Accepted

The election engine must be deterministic given identical inputs and seed. Randomness, if used, must be explicit and reproducible.

## ADR-007 — No Silent Rule Invention

**Status:** Accepted

If the GDD does not specify an exact rule required by implementation, development stops at that decision boundary until the rule is documented and approved.
