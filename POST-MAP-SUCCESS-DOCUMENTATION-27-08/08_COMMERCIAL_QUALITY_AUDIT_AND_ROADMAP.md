# Project 543 — Commercial-Quality Audit and Execution Roadmap

**Date:** 28 August 2026
**Baseline:** `arena/01a049ec-project543`
**Product authority:** GDD V0.1

## Audit snapshot

### Working foundation

- The 543-seat GIS runtime dataset and cached map projection are present.
- Polygon selection, hover, zoom and pan already existed and were preserved.
- Domain models for ideology, personas, constituencies, parties, economy, risk and turn contracts exist and serialize.
- Sprint 4–7 validation scripts cover useful invariants around model structure, ledger conservation, effects, action limits, deterministic turn resolution and resume state.

### Partial or fragile systems found

- The main scene ran two unrelated campaign controllers at once. The visible campaign shell used hashed placeholder support, did not use the political model, did not award complete election votes, and competed with the political intelligence UI.
- The visible map rendered boundaries only; two `GeometryCollection` constituencies could not be projected by the geometry helper, so the full map was not genuinely interactive.
- The original runtime bootstrap loaded a catalogue with unresolved/empty numerical persona values, causing alignment and support calculations to be non-strategic or to fail validation.
- Base-support generation could exceed the model's required population budget, making the political calculation return no result.
- Save/load restored a collection of shell variables rather than the canonical simulation state, with no schema validation or atomic replacement.
- There was no UI-independent election engine returning conserved votes, seat totals, winners and causal factors.
- Onboarding, party identity, home advantage, strategic action feedback, AI movement, election presentation and recovery from bad input were incomplete.

### Highest-impact conclusion

The project did not need another isolated feature. It needed one authoritative campaign state and one complete player loop. The first milestone is therefore an integrated vertical slice on the permanent 543-seat world, not a second map prototype or a further disconnected system demo.

## Prioritised roadmap

### P0 — Critical functionality

- [x] Remove the duplicate visible campaign controller from the main scene.
- [x] Establish a canonical 543-seat campaign coordinator.
- [x] Resolve deterministic projections and final votes/seats with conserved totals.
- [x] Make all 543 map geometries renderable and selectable, including geometry collections.
- [x] Keep map input below UI controls so actions cannot accidentally select a seat.

### P1 — Core experience

- [x] Platform/party setup and custom party naming.
- [x] Home constituency selection and +2% base-support advantage.
- [x] Two-action weekly economy with rallies, interviews, manifestos, fundraising and businesses.
- [x] Recurring business income, risk recovery and financial-scandal penalty.
- [x] Rival actions using the same action/economy path as the player.
- [x] Paid polling with deterministic uncertainty and staleness.
- [x] Week 45 election handoff and results.

### P2 — Depth and strategy

- [x] Deterministic persona distributions and ideological compatibility.
- [x] Local saturation with diminishing returns.
- [x] Temporary interviews versus permanent rallies.
- [x] Manifestos whose value depends on constituency persona composition.
- [x] Money–time–campaign opportunity cost through business ROI and two slots.
- [ ] Balance laboratory with repeatable 45-week archetype simulations.
- [ ] AI personality tuning and stronger defensive/target-switching behaviour.
- [ ] Regional/seat-value targeting tools and advanced comparison view.

### P3 — UX and accessibility

- [x] Progressive onboarding: platform → home → first weekly decisions.
- [x] Plain-language forecast, contest status, tooltips and causal explanations.
- [x] Persistent action, resource, risk and seat forecast hierarchy.
- [x] Stale-poll state and safe failure messages.
- [ ] Beginner/advanced information-density toggle.
- [ ] Keyboard navigation audit, colour-blind-safe secondary indicators and scalable text setting.

### P4 — Polish

- [x] Dark political-command visual language, filled forecast map, selected/home/hover states.
- [x] Event briefing feed and election-night review of closest races.
- [ ] Dedicated election count animation with progressive seat updates.
- [ ] UI transition tweens, sound effects, music states and richer result feedback.
- [ ] Production art pass after the simulation is balanced.

### P5 — Technical quality

- [x] UI-independent deterministic election engine.
- [x] Versioned data-driven campaign configuration.
- [x] Schema-aware serialized campaign state and safe load rejection.
- [x] Master validation now boots the 543-seat campaign slice.
- [ ] Split the large coordinator into economy, AI and persistence services after rules stabilise.
- [ ] Add profiling for repeated forecast calculation and cache structural support.
- [ ] Add full save/resume, election and property-test coverage to CI execution.

### P6 — Commercial readiness

- [x] Complete start-to-election loop exists on the permanent world.
- [x] New campaign and save/load recovery paths exist.
- [ ] Settings, pause/menu flow, quit confirmation and autosave slots.
- [ ] Difficulty/personality selection and campaign summary screen.
- [ ] Balance sign-off against aggressive, economic, ideological, regional and conservative strategies.
- [ ] Final production GIS and population provenance review.

## Highest-value milestone delivered first

**Integrated Campaign Loop:** one source of truth from platform selection to home selection, weekly decisions, rival response, deterministic 543-seat resolution and explainable election results. This is the correct next step because it validates the interaction between the political model, economy, time pressure, AI, map and UI before spending effort on presentation polish.

## Next milestone

Build a repeatable balance laboratory around `CampaignCoordinator` and `ElectionEngine`, then use its output to tune AI priorities, manifesto strength, business ROI, risk recovery and the player seat forecast. Only after the strategic triangle produces multiple viable plans should the project invest in final audio, animation and production assets.
