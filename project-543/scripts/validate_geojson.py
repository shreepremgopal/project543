from pathlib import Path
import geopandas as gpd
from shapely.validation import explain_validity


EXPECTED_FEATURE_COUNT = 543

PROJECT_ROOT = Path(__file__).resolve().parents[3]

SOURCE_FILE = (
    PROJECT_ROOT
    / "project543"
    / "project-543"
    / "tools"
    / "gis"
    / "source"
    / "india_ls_seats_543_fixed.geojson"
)


def main() -> None:
    print("Project 543 GIS Validation")
    print("==========================")

    if not SOURCE_FILE.exists():
        raise FileNotFoundError(
            f"Missing source dataset: {SOURCE_FILE}"
        )

    gdf = gpd.read_file(SOURCE_FILE)

    feature_count = len(gdf)

    print(f"Feature count: {feature_count}")

    if feature_count != EXPECTED_FEATURE_COUNT:
        raise ValueError(
            f"Expected {EXPECTED_FEATURE_COUNT} features, "
            f"found {feature_count}."
        )

    print("Feature count: PASS")

    if gdf.crs is None:
        raise ValueError("Dataset has no CRS.")

    print(f"CRS: {gdf.crs}")
    print("CRS: PASS")

    invalid_geometry_count = (~gdf.geometry.is_valid).sum()
    invalid_mask = ~gdf.geometry.is_valid
    print(
            f"Invalid geometries: "
            f"{invalid_geometry_count}"
        )
    
    if invalid_geometry_count != 0:
        print("\nInvalid geometry details:")
        for idx, row in gdf[invalid_mask].iterrows():
            print(f"\nFeature index: {idx}")
            print(f"Geometry type: {row.geometry.geom_type}")
            print(f"Reason: {explain_validity(row.geometry)}")
        raise ValueError(
                                f"Found {invalid_geometry_count} "
                                "invalid geometries."
                            )
    

        

    print("Geometry validity: PASS")

    empty_geometry_count = gdf.geometry.is_empty.sum()

    print(
        f"Empty geometries: "
        f"{empty_geometry_count}"
    )

    if empty_geometry_count != 0:
        raise ValueError(
            f"Found {empty_geometry_count} "
            "empty geometries."
        )

    print("Geometry emptiness: PASS")

    print()
    print("GIS VALIDATION PASSED")


if __name__ == "__main__":
    main()