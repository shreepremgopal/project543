# Project 543 — Development Roadmap V0.1 Revision 1

**Repository:** https://github.com/shreepremgopal/project543  
**Status:** Post-roadmap-review baseline

## Purpose

This document revises execution after the successful 543-constituency map milestone. It does not replace the GDD.

## Completed Foundation

Development environment, Godot project, GIS pipeline, 543-seat runtime dataset, map rendering, transforms, zoom/pan, constituency selection, geometry caching, constituency identity and map interaction are retained as the foundation.

## Roadmap Philosophy

**System-first, dependency-aware, test-first, integration-driven.**

Not map-first, UI-first, throwaway-prototype-first or feature accumulation without architecture.

## R1 — GDD Decomposition and Architecture Lock

Deliverables: GDD system decomposition, domain entity inventory, dependency graph, architecture baseline, clarification register and requirements traceability.

## R2 — Core Data Model

Establish canonical Constituency, Persona, Ideology, Party, Business, Campaign State and Election State representations.

## R3 — Political Model

Engineer ideology, persona preferences, persona distributions, alignment and base-support foundations.

## R4 — Economy and Campaign Model

Engineer money, businesses, income, fundraising, risk, campaign actions, saturation and temporary/permanent effects.

## R5 — Turn and Resolution System

Implement the 45-week structure: Income → Intelligence → Actions → Resolution → Next Week, with two strategic actions per week.

## R6 — Election Engine

Build the central deterministic election system: party × constituency resolution, persona compatibility, support, campaign, risk, turnout, votes, winners and seats.

## R7 — AI Strategy

Implement rule-based opponents using the same core systems as the player.

## R8 — Integration Slice

Connect the independent systems into a controlled end-to-end scenario using the existing world/data architecture. This is where vertical slicing is deliberately used as integration validation.

## R9 — Full 543 Campaign

Run the complete GDD game loop across the full map: party creation/join, ideology, home constituency, two actions/week, economy/risk, 45 turns, election and seat totals.

## R10 — Balance and Explainability

Validate aggressive, economic, ideological, risk and regional strategies; test for dominant strategies and causal explainability.

## R11 — Presentation and V0.1 Completion

UI polish, feedback, tutorial, save/load UX, election result presentation, map colouring, audio and game feel.

## Removed From Previous Direction

A separate single-constituency map implementation is no longer a required permanent roadmap step. A controlled small scenario remains allowed as a test/integration harness.

## Scope Preservation

The revised roadmap does not reduce the GDD V0.1 scope: 543 constituencies, 25 personas, party ideology, population, turnout, 45 turns, two actions/turn, home constituency, campaign, manifestos, rallies, interviews, businesses, fundraising, risk, AI, election engine, vote/seat calculation, result map, save/load and tutorial.

## Governance

Roadmap changes require a GDD change, an architectural discovery, a newly identified technical risk or a formally approved design decision. The roadmap must not change merely to accommodate implementation convenience.
