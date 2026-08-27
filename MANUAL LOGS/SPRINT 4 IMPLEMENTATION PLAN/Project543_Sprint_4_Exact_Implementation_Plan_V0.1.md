# Project 543 — Sprint 4 Exact Implementation Plan V0.1

**Sprint:** 4  
**Phase:** R2 Core Data Model → R3 Political Model  
**Status:** Proposed for implementation  
**Owner:** Sprint 4 Leader  
**Baseline:** `acb56b2e4878797ece2efc0fa4a46310f787a870`  
**Repository:** https://github.com/shreepremgopal/project543

## 1. Sprint Mission

Establish the first UI-independent political simulation foundation of Project 543: canonical Constituency, Persona, Ideology and Party domain models, deterministic data/configuration infrastructure, constituency-persona population representation, validation, serialization boundaries and automated tests.

The sprint must make the political world representable without requiring Godot UI execution. It must not invent unresolved GDD formulas.

## 2. Why This Sprint Now

The 543-seat GIS/map foundation is already established. The revised roadmap explicitly moves next to the Core Data Model and Political Model. The election engine depends on constituency, persona, ideology, party, campaign and turnout inputs; therefore building the election resolver now would force unresolved rules into code.

## 3. Non-Negotiable Principles

1. GDD V0.1 is product authority.
2. Existing 543-seat map/GIS remains the world foundation.
3. Simulation code must not depend on UI nodes.
4. Configurable values belong in data/configuration, not unexplained constants.
5. Identical inputs must produce identical deterministic state/results where determinism is required.
6. No silent rule invention.
7. Invalid development data fails loudly.
8. Domain models own state; presentation does not.
9. Vertical slices are integration tests, not places to invent backbone rules.
10. Every new rule requires traceability to GDD or an explicit approved design decision.

## 4. Scope

### In scope
- Canonical domain model conventions.
- Constituency model linked to existing GIS identity.
- IdeologyProfile model with six dimensions and bounds.
- Persona model and catalogue infrastructure for 25 personas.
- Persona distribution representation for each constituency.
- Party model and core political identity.
- Initial campaign-state/election-state placeholders only where required by contracts.
- Data loading/configuration boundaries.
- Validation framework.
- Deterministic seed/state conventions.
- Serialization-ready domain state.
- Automated unit tests.
- Controlled non-UI construction test/harness.
- Architecture and design documentation.

### Explicitly out of scope
- Final ideology alignment formula.
- Final risk modifier formula.
- Final campaign saturation curve.
- Final persona numerical vectors unless separately approved.
- Authoritative population dataset selection.
- Production GIS dataset replacement.
- Manifesto effects catalogue.
- Economy/business mechanics.
- Campaign actions.
- AI strategy.
- Turn resolution.
- Election winner calculation.
- Full UI redesign.

## 5. Target Architecture

Source/Data → Domain Models → Simulation Systems → Game-State Orchestration → Presentation.

Sprint 4 primarily implements the Domain Models and their Source/Data boundaries. The existing GIS renderer remains a consumer/foundation and is not allowed to become the owner of political rules.

## 6. Canonical Domain Objects

### 6.1 IdeologyProfile

Six dimensions:
- economic_policy
- welfare
- social_policy
- governance
- environment
- national_policy

Each dimension is constrained to -1.0 through +1.0.

The object must support construction, validation, equality and deterministic serialization.

Do not encode the final alignment metric here.

### 6.2 Persona

Fields:
- persona_id
- display_name
- ideology_profile
- priority_weights
- turnout_tendency (optional until formally specified)

Exactly 25 persona identities are expected for the v0.1 catalogue. Numerical definitions remain configuration/approval controlled.

### 6.3 PersonaDistribution

Represents constituency composition as persona shares. Required invariant: total distribution = 100%.

The representation must avoid floating-point drift causing false validation failures. Internally choose a deterministic representation appropriate to the project, documenting the decision before implementation.

### 6.4 Constituency

Fields:
- unique_id
- name
- state/UT
- GIS reference/identity
- population
- turnout state/parameter boundary
- persona distribution
- current party support boundary
- campaign-state boundary
- election-result boundary

Geometry must remain owned by the GIS/world layer or a clean GIS reference; political domain state must not duplicate geometry unnecessarily.

### 6.5 Party

Fields required by the GDD:
- party_id
- name
- colour
- leader
- ideological_profile
- money
- followers
- risk
- home_constituency
- base_support
- businesses reference/boundary

Economy/business behaviour is not implemented in this sprint.

## 7. Data-Driven Strategy

Separate definitions from mutable campaign state.

Recommended conceptual split:
- PersonaDefinition
- PartyDefinition
- ConstituencyStaticData
- ConstituencyPoliticalState
- CampaignState
- SimulationState

Definitions should be immutable/read-only after loading where practical. Mutable campaign state must be isolated so save/load and deterministic tests can reproduce state.

## 8. GIS Integration Contract

The current GIS loader provides constituency identity and geometry. Sprint 4 must consume identity without rewriting the GIS pipeline.

Required mapping contract:

GIS unique_id → Constituency.unique_id

Validation must detect:
- missing IDs
- duplicate IDs
- missing required identity fields
- invalid population
- invalid persona distribution
- invalid ideology

The system must be able to construct a 543-constituency domain registry from the existing data once population/persona configuration is available.

## 9. Validation Contract

Development validation must reject:
- ideology dimensions outside [-1,1]
- empty/duplicate IDs
- negative population
- persona shares outside valid bounds
- persona distribution totals not equal to 100%
- invalid turnout values when turnout is present
- missing required party identity
- invalid party ideology
- invalid home constituency reference
- duplicate party IDs
- invalid colour representation where distinguishability is required

Validation errors should identify object, field, actual value and expected invariant.

## 10. Determinism

Sprint 4 establishes deterministic construction and serialization. Random generation of persona distributions is not allowed to become an undocumented balancing mechanism.

If a seeded generator is introduced for test fixtures, its seed and generation purpose must be explicit.

## 11. Explainability Foundation

Every mutable political state should have room for source attribution in later systems. Do not yet implement the full explainability engine, but avoid designs that collapse all support into one opaque number.

Where practical, future-compatible state should distinguish:
- base support
- campaign modifier
- other explicitly named modifiers

## 12. Testing Strategy

Tests are required before sprint completion.

### Ideology tests
- valid boundary values
- invalid below/above bounds
- equality
- serialization round-trip

### Persona tests
- all 25 IDs/names exist in the approved catalogue
- valid ideology profile
- valid priority weights
- invalid definitions fail

### Distribution tests
- exactly 100% total
- under/over total rejected
- negative share rejected
- unknown persona rejected
- deterministic serialization

### Constituency tests
- valid identity
- duplicate ID rejected at registry level
- negative population rejected
- valid GIS reference accepted
- invalid political state rejected

### Party tests
- valid construction
- ideology validation
- resource constraints
- home constituency reference
- serialization round-trip

### Registry/integration tests
- load a controlled subset
- load all 543 constituency identities
- verify unique IDs
- verify every required persona definition exists
- construct a complete deterministic domain fixture without UI

## 13. Controlled Scenario

Create a small test fixture using the same domain classes as the full game.

The fixture is not a second game architecture. It exists to prove that a constituency, personas, ideology and party can be composed and serialized independently of Godot UI.

A second full-map validation should instantiate the 543 constituency registry from the existing world data and report validation status without requiring gameplay UI.

## 14. Recommended Implementation Sequence

### Phase A — Architecture skeleton
1. Establish domain/data directories and naming conventions.
2. Establish base validation/error conventions.
3. Establish serialization conventions.
4. Add tests first for core invariants.

### Phase B — Ideology
5. Implement six-dimensional IdeologyProfile.
6. Implement validation and serialization.
7. Add tests.
8. Define a future AlignmentCalculator interface only; do not implement the unresolved canonical formula.

### Phase C — Personas
9. Implement PersonaDefinition.
10. Add the 25 approved persona identities.
11. Add configuration loading boundary.
12. Represent unresolved vectors without silently selecting canonical numbers.
13. Implement priority-weight validation.
14. Add tests.

### Phase D — Constituency political model
15. Implement Constituency domain object.
16. Implement PersonaDistribution.
17. Connect constituency unique IDs to GIS identity.
18. Add population field and validation without selecting an authoritative external dataset.
19. Add tests.

### Phase E — Party
20. Implement PartyDefinition and mutable PartyState boundary.
21. Add ideology, identity, resources, risk, home constituency and base-support representation.
22. Validate references and ranges.
23. Add tests.

### Phase F — Registry/state
24. Implement registries for personas, constituencies and parties.
25. Enforce uniqueness and referential integrity.
26. Implement deterministic state serialization.
27. Build 543-seat controlled validation harness.

### Phase G — Review gate
28. Run complete automated suite.
29. Run 543-domain construction/validation.
30. Review unresolved decision boundaries.
31. Update architecture records if any contract changed.
32. Update development log.
33. Only then authorize dependent political-model work.

## 15. High-Leverage Architectural Idea — State Ledger

Introduce a lightweight, future-compatible concept of a **Political State Ledger**.

Instead of allowing systems to overwrite a constituency's support as an unexplained final number, later systems can append named state changes with source, turn, magnitude and reason. Sprint 4 should only establish the data shape/interface if it does not overcomplicate the domain.

Example conceptual record:

StateChange:
- source_system
- source_action
- turn
- target_id
- dimension/type
- delta
- reason_code

This is deliberately not a full event-sourcing architecture. Its purpose is to preserve causal explainability and prevent the election result from becoming a black box.

## 16. High-Leverage Architectural Idea — Scenario Packs

Create deterministic scenario fixtures as reusable **Scenario Packs** rather than scattered unit-test dictionaries.

Examples for future sprints:
- perfect ideological alignment
- ideological mismatch
- close race
- home advantage
- high turnout
- low turnout
- campaign saturation
- risk shock
- national 543-seat case

Sprint 4 should establish the fixture mechanism and implement only scenarios relevant to the current models.

## 17. High-Leverage Architectural Idea — Provenance Everywhere

Where practical, data definitions should carry provenance metadata such as source document/section, configuration version and approval status. This is particularly valuable because the project has explicitly chosen a no-silent-rule-invention policy.

The objective is that a future engineer can answer: “Why does this value exist?” without reverse-engineering code.

Do not turn provenance into runtime overhead for every calculation; it can primarily live in definitions/configuration.

## 18. Stop Conditions

Stop Sprint 4 implementation and request architectural/design review if:
- an unresolved GDD formula is required to continue;
- the model requires UI execution to calculate state;
- GIS code must own political rules;
- a configurable value must be hard-coded for convenience;
- a domain contract must change unexpectedly;
- the population/persona dataset assumptions materially change;
- deterministic state cannot be reproduced;
- validation requires silently repairing invalid source data;
- an implementation choice would permanently constrain a later system without an ADR.

## 19. Acceptance Criteria

Sprint 4 is complete only when:
1. Core domain objects exist independently of UI.
2. Six-dimensional ideology is represented and validated.
3. The 25-persona catalogue infrastructure exists.
4. Persona distributions are representable and validated to 100%.
5. Constituency state can reference the existing 543-seat GIS identity.
6. Party political identity can be represented.
7. Definitions and mutable state are cleanly separated.
8. Deterministic serialization works for core state.
9. Automated tests cover all core invariants.
10. A controlled non-UI scenario works.
11. A 543-constituency registry validation works against the existing world foundation.
12. No unresolved GDD rule has been silently invented.
13. Architecture documentation and logs are updated.

## 20. Sprint Exit State

At sprint exit, Project543 should have moved from:

**“We have a map of India.”**

to:

**“We have a formally structured political world that can exist independently of the map UI.”**

The next dependency is the Political Model layer: approved ideology alignment, support/base-support foundations and campaign-compatible political calculations.
