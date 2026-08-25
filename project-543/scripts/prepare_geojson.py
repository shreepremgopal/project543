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
    if len(sys.argv) != 3:
        print(
            "Usage: python D:/Shree/project543/project-543/scripts/prepare_geojson.py "
            "<input.geojson> <output.geojson>"
        )
        sys.exit(1)

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    if not input_path.exists():
        fail(f"Input file not found: {input_path}")

    with input_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if data.get("type") != "FeatureCollection":
        fail("Input is not a FeatureCollection")

    features = data.get("features", [])

    if len(features) != 543:
        fail(f"Expected 543 features, got {len(features)}")

    prepared_features = []

    seen_ids = set()

    for index, feature in enumerate(features):
        properties = feature.get("properties", {})
        geometry = feature.get("geometry")

        for key in REQUIRED_PROPERTIES:
            if key not in properties:
                fail(f"Feature {index}: missing '{key}'")

        unique_id = str(properties["unique_id"]).strip()

        if unique_id in seen_ids:
            fail(f"Duplicate unique_id: {unique_id}")

        seen_ids.add(unique_id)

        prepared_features.append(
            {
                "type": "Feature",
                "properties": {
                    "state_ut_name": str(
                        properties["state_ut_name"]
                    ).strip(),

                    "ls_seat_name": str(
                        properties["ls_seat_name"]
                    ).strip(),

                    "state_ut_code": str(
                        properties["state_ut_code"]
                    ).strip(),

                    "ls_seat_code": str(
                        properties["ls_seat_code"]
                    ).strip(),

                    "unique_id": unique_id,
                },
                "geometry": geometry,
            }
        )

    output = {
        "type": "FeatureCollection",
        "features": prepared_features,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", encoding="utf-8") as f:
        json.dump(
            output,
            f,
            ensure_ascii=False,
            separators=(",", ":"),
        )

    print(f"Prepared features: {len(prepared_features)}")
    print(f"Output: {output_path}")
    print("RUNTIME GEOJSON PREPARATION PASSED")


if __name__ == "__main__":
    main()