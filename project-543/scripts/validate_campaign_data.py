"""Validate the data contracts needed by the Project 543 campaign slice.

This check deliberately uses only the Python standard library so CI can reject
bad data before Godot is installed or the project is imported.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
GEOJSON_PATH = ROOT / "data/generated/india_ls_seats_543_runtime.geojson"
CAMPAIGN_PATH = ROOT / "data/campaign/campaign_balance_v0_1.json"
PERSONA_PATH = ROOT / "data/personas/persona_catalogue_v0_1.json"
POLITICAL_PERSONA_PATH = ROOT / "data/political/political_personas_v0_1.json"

DIMENSIONS = {
    "economic_policy",
    "welfare",
    "social_policy",
    "governance",
    "environment",
    "national_policy",
}


class ValidationFailure(Exception):
    pass


def read_json(path: Path) -> Any:
    if not path.is_file():
        raise ValidationFailure(f"missing data file: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationFailure(f"cannot parse {path}: {exc}") from exc


def polygon_count(geometry: Any) -> int:
    if not isinstance(geometry, dict):
        return 0
    geometry_type = geometry.get("type")
    if geometry_type == "Polygon":
        coordinates = geometry.get("coordinates")
        return 1 if isinstance(coordinates, list) and coordinates else 0
    if geometry_type == "MultiPolygon":
        coordinates = geometry.get("coordinates")
        return len(coordinates) if isinstance(coordinates, list) else 0
    if geometry_type == "GeometryCollection":
        geometries = geometry.get("geometries")
        return sum(polygon_count(child) for child in geometries) if isinstance(geometries, list) else 0
    return 0


def validate_geojson() -> None:
    data = read_json(GEOJSON_PATH)
    if not isinstance(data, dict) or data.get("type") != "FeatureCollection":
        raise ValidationFailure("GIS data is not a FeatureCollection")
    features = data.get("features")
    if not isinstance(features, list) or len(features) != 543:
        raise ValidationFailure(f"GIS data must contain 543 features, got {len(features) if isinstance(features, list) else 'invalid'}")

    ids: list[str] = []
    for index, feature in enumerate(features):
        if not isinstance(feature, dict):
            raise ValidationFailure(f"GIS feature {index} is not an object")
        properties = feature.get("properties")
        geometry = feature.get("geometry")
        if not isinstance(properties, dict) or not isinstance(geometry, dict):
            raise ValidationFailure(f"GIS feature {index} is missing properties or geometry")
        unique_id = str(properties.get("unique_id", "")).strip()
        if not unique_id:
            raise ValidationFailure(f"GIS feature {index} has no unique_id")
        ids.append(unique_id)
        for key in ("state_ut_name", "ls_seat_name", "state_ut_code", "ls_seat_code"):
            if not str(properties.get(key, "")).strip():
                raise ValidationFailure(f"GIS feature {unique_id} is missing {key}")
        if polygon_count(geometry) == 0:
            raise ValidationFailure(f"GIS feature {unique_id} has no polygon geometry")
    if len(set(ids)) != 543:
        raise ValidationFailure("GIS unique_id values are not unique")


def validate_personas() -> set[str]:
    data = read_json(PERSONA_PATH)
    political_data = read_json(POLITICAL_PERSONA_PATH)
    personas = data.get("personas") if isinstance(data, dict) else None
    political_personas = political_data.get("personas") if isinstance(political_data, dict) else None
    if not isinstance(personas, list) or len(personas) != 25:
        raise ValidationFailure("persona catalogue must contain exactly 25 entries")
    if not isinstance(political_personas, list) or len(political_personas) != 25:
        raise ValidationFailure("political persona catalogue must contain exactly 25 entries")

    ids: set[str] = set()
    for persona in personas:
        if not isinstance(persona, dict):
            raise ValidationFailure("persona entry is not an object")
        persona_id = str(persona.get("persona_id", "")).strip()
        if not persona_id or persona_id in ids:
            raise ValidationFailure(f"invalid or duplicate persona id: {persona_id}")
        ids.add(persona_id)
        ideology = persona.get("ideology_profile")
        weights = persona.get("priority_weights")
        if not isinstance(ideology, dict) or set(ideology) != DIMENSIONS:
            raise ValidationFailure(f"persona {persona_id} ideology dimensions are incomplete")
        if not isinstance(weights, dict) or set(weights) != DIMENSIONS:
            raise ValidationFailure(f"persona {persona_id} priority dimensions are incomplete")
        if any(not isinstance(value, (int, float)) or not math.isfinite(value) or not -1 <= value <= 1 for value in ideology.values()):
            raise ValidationFailure(f"persona {persona_id} has an invalid ideology value")
        if any(not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0 for value in weights.values()):
            raise ValidationFailure(f"persona {persona_id} has an invalid priority weight")
        if not math.isclose(sum(weights.values()), 1.0, abs_tol=1e-8):
            raise ValidationFailure(f"persona {persona_id} priority weights do not sum to one")

    political_ids = {str(item.get("persona_id", "")).strip() for item in political_personas if isinstance(item, dict)}
    if political_ids != ids:
        raise ValidationFailure("political and gameplay persona catalogues are out of alignment")
    return ids


def validate_campaign(persona_ids: set[str]) -> None:
    data = read_json(CAMPAIGN_PATH)
    if not isinstance(data, dict):
        raise ValidationFailure("campaign config root is not an object")
    if data.get("campaign_weeks") != 45 or data.get("actions_per_week") != 2:
        raise ValidationFailure("campaign must define 45 weeks and two actions per week")
    if not 0 <= float(data.get("eligibility_factor", -1)) <= 1:
        raise ValidationFailure("eligibility_factor must be in [0, 1]")

    actions = data.get("actions")
    if not isinstance(actions, dict):
        raise ValidationFailure("campaign actions must be an object")
    for action_id in ("rally", "interview", "manifesto"):
        action = actions.get(action_id)
        if not isinstance(action, dict) or int(action.get("cost", 0)) <= 0:
            raise ValidationFailure(f"campaign action {action_id} is invalid")

    parties = data.get("parties")
    if not isinstance(parties, list) or len(parties) < 2:
        raise ValidationFailure("campaign needs at least two parties")
    party_ids = [str(party.get("id", "")).strip() for party in parties if isinstance(party, dict)]
    if len(party_ids) != len(set(party_ids)) or "party_player" not in party_ids:
        raise ValidationFailure("campaign party ids are invalid")
    for party in parties:
        if not isinstance(party, dict) or set(party.get("ideology_profile", {})) != DIMENSIONS:
            raise ValidationFailure("campaign party ideology dimensions are incomplete")

    manifestos = data.get("manifestos")
    if not isinstance(manifestos, list) or not manifestos:
        raise ValidationFailure("campaign needs at least one manifesto")
    for manifesto in manifestos:
        if not isinstance(manifesto, dict) or not str(manifesto.get("id", "")).strip():
            raise ValidationFailure("manifesto definition is invalid")
        focus = manifesto.get("focus_personas", [])
        if not isinstance(focus, list) or not set(map(str, focus)).issubset(persona_ids):
            raise ValidationFailure(f"manifesto {manifesto.get('id')} references an unknown persona")

    businesses = data.get("businesses")
    if not isinstance(businesses, list) or not businesses:
        raise ValidationFailure("campaign needs at least one business")
    for business in businesses:
        if not isinstance(business, dict) or int(business.get("cost", 0)) <= 0 or int(business.get("limit", 0)) <= 0:
            raise ValidationFailure("business definition is invalid")


def main() -> int:
    try:
        validate_geojson()
        persona_ids = validate_personas()
        validate_campaign(persona_ids)
    except ValidationFailure as exc:
        print(f"CAMPAIGN DATA VALIDATION FAIL: {exc}", file=sys.stderr)
        return 1
    print("CAMPAIGN DATA VALIDATION PASS: 543 seats, 25 personas, campaign config")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
