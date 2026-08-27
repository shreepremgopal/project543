# Project 543 — GDD System Decomposition V0.1

**Source authority:** Project 543 GDD V0.1  
**Repository:** https://github.com/shreepremgopal/project543

> This document decomposes the GDD for engineering purposes. It does not replace the GDD and does not silently resolve unspecified formulas.

## Product Core

The GDD defines Project 543 as a 45-turn political strategy game where the player manages a political party across 543 parliamentary constituencies and seeks the highest seat count.

Its central strategic relationships are the Money–Time–Campaign triangle and the Ideology–Personas–Campaign triangle.

## Primary Entities

### Party

Party ID, name, colour, leader, ideological profile, money, followers, risk, home constituency, base support and businesses.

### Persona

Persona ID, display name, six-dimensional ideological preference vector, priority weights and optional turnout tendency. Version 0.1 contains 25 abstract personas.

### Constituency

Unique ID, name, state, geographic polygon, population, turnout, persona distribution, current party support, campaign modifiers and election result.

### Campaign State

State required to represent campaign actions and their effects.

### Business

Recurring-income entity with configurable construction cost, income and limits.

### Election Result

Constituency results, party vote totals, party seat totals and winner.

## Core Systems

### Constituency System

Represents the 543 constituencies and their game data, persona distribution, geographic identity and campaign state.

### Ideology System

Represents party and persona ideological profiles and calculates compatibility. The exact mathematical metric is not fully specified in the GDD.

### Persona System

Defines the 25 personas, preference vectors, priority weights and constituency distributions.

### Party System

Handles party identity, ideology, resources, home constituency and businesses.

### Support/Campaign System

Includes Manifesto, Rally and Interview and distinguishes Base Support, Campaign Modifier and Election Score.

### Economy System

Includes money, businesses, recurring income, fundraising, risk, financial scandal and risk recovery.

### Turn System

45 weekly turns with income, intelligence, actions, resolution and next-week transition. Two strategic actions per week.

### Election Engine

The GDD calls this the most important system. It resolves every party × constituency combination and returns constituency results, party vote totals, seat totals and winner.

### AI System

Version 0.1 requires rule-based AI parties using the same basic systems as the player.

### Save System

Captures the campaign state required by the GDD, including turn, party data, resources, businesses, ideology, home constituency, campaign modifiers, AI state, election state and seed when applicable.

### Map Renderer

Represents the geographic world, selection, interaction, political visual state and election colours. It must not own simulation rules.

## Dependency Model

GIS Data → Constituency Model

Persona Definitions → Persona Model

Ideology → Party/Persona Alignment

Constituency + Persona Distribution + Party → Political Compatibility

Campaign + Economy + Risk + Political Compatibility → Election Inputs

Election Inputs → Election Engine

Election Engine → Election Results

Election Results → Map/UI

## GDD-Mandated Validation

Before a complete election: exactly 543 constituencies; each persona distribution sums to 100%; population ≥ 0; turnout in [0%,100%]; distinguishable party colours; valid party/persona ideology; valid geometry; unique constituency IDs. Invalid data must produce a development error.

## GDD-Mandated Tests

Equal parties; perfect alignment; no alignment; campaign effect; home advantage; turnout; risk; business income; all 543 constituencies; total seats = 543.

## Critical Quality Targets

Deterministic election calculation, data-driven configuration, UI-independent election logic, near-immediate resolution, explainable outcomes and no unexplained major modifiers.

## Deliberately Unspecified Areas

Exact ideology distance metric; exact alignment conversion; exact risk modifier; exact campaign saturation curve; exact manifesto catalogue/effects; exact AI weighting; authoritative population source; authoritative production GIS source; exact randomness policy.
