from pathlib import Path
import geopandas as gpd


SOURCE_FILE = Path(
    "D:/Shree/project543/project-543/tools/gis/source/india_ls_seats_543.geojson"
)

OUTPUT_FILE = Path(
    "D:/Shree/project543/project-543/tools/gis/source/india_ls_seats_543_fixed.geojson"
)


def main() -> None:
    gdf = gpd.read_file(SOURCE_FILE)

    print(f"Original features: {len(gdf)}")
    print(f"Invalid before repair: {(~gdf.geometry.is_valid).sum()}")

    # Repair invalid geometries
    gdf["geometry"] = gdf.geometry.make_valid()

    print(f"Invalid after repair: {(~gdf.geometry.is_valid).sum()}")

    gdf.to_file(
        OUTPUT_FILE,
        driver="GeoJSON"
    )

    print(f"Saved repaired file to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()