# Project 543

Project 543 is a turn-based political strategy and election simulation game. The player builds a party, manages money and risk, campaigns across India's 543 parliamentary constituencies, and tries to win the largest number of seats.

## Development

- **Engine:** Godot 4.7.2
- **Language:** GDScript
- **Target:** Windows PC
- **World:** 543 GIS-backed constituencies
- **Campaign:** 45 weekly turns, two strategic actions per week

## Current milestone

**Commercial-quality vertical slice — integrated campaign loop.**

The playable scene now uses one canonical campaign coordinator rather than separate demo controllers. It includes party/platform setup, home constituency selection, deterministic political projections, rallies, interviews, manifestos, fundraising and risk, businesses and recurring income, rival AI actions, paid polling, save/load, and a 543-seat election result with explainable races.

## Running

Open `project-543/project.godot` in Godot 4.7.2 and run the main scene. The map is the primary interface:

1. Choose a platform and party name.
2. Click a constituency and confirm it as home.
3. Use two actions each week, then resolve the week.
4. Reassess the map as rivals move and income compounds.
5. Finish Week 45 to resolve all 543 seats.

The current population, persona distribution, and base-support values are deterministic gameplay bootstrap data. Their provenance is kept in the data files so an approved production dataset can replace them without changing the simulation boundary.

## Validation

The repository includes domain tests for the political and economy models, turn-system contract tests, a 543-seat campaign integration test, the Python data-contract check at `project-543/scripts/validate_campaign_data.py`, and the CI master validation script at `project-543/tools/master_validation.gd`.
