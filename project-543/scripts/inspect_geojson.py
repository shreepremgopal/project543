from pathlib import Path
import geopandas as gpd


PROJECT_ROOT = Path(__file__).resolve().parents[3]

SOURCE_FILE = (
    PROJECT_ROOT
    / "project543"
    / "project-543"
    / "tools"
    / "gis"
    / "source"
    / "india_ls_seats_543.geojson"
)


def main() -> None:
    print("Project 543 GIS Inspection")
    print("==========================")
    print(f"Source: {SOURCE_FILE}")
    print()

    if not SOURCE_FILE.exists():
        raise FileNotFoundError(
            f"GIS source file not found: {SOURCE_FILE}"
        )

    gdf = gpd.read_file(SOURCE_FILE)

    print(f"Feature count: {len(gdf)}")
    print(f"CRS: {gdf.crs}")
    print()
    print("Columns:")
    print(list(gdf.columns))
    print()
    print("First feature:")
    print(gdf.iloc[0])


if __name__ == "__main__":
    main()