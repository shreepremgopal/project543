import json
import sys
from pathlib import Path


REQUIRED_PROPERTIES = [
    "state_ut_name",
    "ls_seat_name",
    "state_ut_code",
    "ls_seat_code",
    "unique_id",
]


def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)


def main():
    if len(sys.argv) != 2:
        print("Usage: python D:/Shree/project543/project-543/scripts/validate_seat_data.py <geojson>")
        sys.exit(1)

    path = Path(sys.argv[1])

    if not path.exists():
        fail(f"File not found: {path}")

    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:
        fail(f"Could not parse JSON: {exc}")

    if data.get("type") != "FeatureCollection":
        fail("Root object is not a FeatureCollection")

    features = data.get("features")

    if not isinstance(features, list):
        fail("features is not a list")

    print(f"Feature count: {len(features)}")

    if len(features) != 543:
        fail(f"Expected 543 features, got {len(features)}")

    unique_ids = set()

    for index, feature in enumerate(features):
        properties = feature.get("properties")

        if not isinstance(properties, dict):
            fail(f"Feature {index}: properties missing or invalid")

        for key in REQUIRED_PROPERTIES:
            if key not in properties:
                fail(f"Feature {index}: missing property '{key}'")

            value = properties[key]

            if value is None or str(value).strip() == "":
                fail(f"Feature {index}: empty property '{key}'")

        unique_id = str(properties["unique_id"]).strip()

        if unique_id in unique_ids:
            fail(f"Duplicate unique_id: {unique_id}")

        unique_ids.add(unique_id)

    print("Required properties: PASS")
    print("unique_id uniqueness: PASS")
    print(f"Unique IDs: {len(unique_ids)}")
    print("SEAT DATA VALIDATION PASSED")


if __name__ == "__main__":
    main()