import json
import sys


def main():
    if len(sys.argv) != 2:
        print("Usage: python D:/Shree/project543/project-543/scripts/inspect_geojson_godot.py <geojson>")
        sys.exit(1)

    path = sys.argv[1]

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    features = data.get("features", [])

    print(f"Feature count: {len(features)}")
    print()

    if not features:
        print("No features found.")
        sys.exit(1)

    print("First feature:")
    print(json.dumps(features[0], indent=2, ensure_ascii=False))

    print()
    print("Property keys:")
    
    properties = features[0].get("properties", {})

    for key, value in properties.items():
        print(f"  {key}: {value!r}")


if __name__ == "__main__":
    main()