extends SceneTree


const GIS_PATH := (
	"res://data/generated/"
	+ "india_ls_seats_543_runtime.geojson"
)

const PERSONA_PATH := (
	"res://data/personas/"
	+ "persona_catalogue_v0_1.json"
)


func _initialize() -> void:
	var failures: Array[String] = []

	var config := PoliticalBalanceConfig.load_json(
		"res://data/political/"
		+ "political_balance_v0_1.json"
	)

	failures.append_array(
		config.validate()
	)

	var persona_registry := (
		PersonaCatalogLoader.load_json(
			PERSONA_PATH
		)
	)

	if persona_registry.size() != 25:
		failures.append(
			"Expected exactly 25 personas; got %s"
			% persona_registry.size()
		)

	var loader := GISDataLoader.new()

	var seats: Array = loader.load_seats(
		GIS_PATH
	)

	if seats.size() != 543:
		failures.append(
			"Expected 543 GIS seats; got %s"
			% seats.size()
		)

	var constituency_registry := (
		ConstituencyRegistry.new()
	)

	for seat in seats:
		var unique_id := String(
			seat.get("unique_id", "")
		)

		if unique_id.is_empty():
			failures.append(
				"GIS seat contains empty unique_id"
			)
			continue

		var distribution := (
			_build_deterministic_distribution(
				unique_id,
				persona_registry
			)
		)

		var constituency := Constituency.new(
			unique_id,
			String(
				seat.get(
					"ls_seat_name",
					unique_id
				)
			),
			String(
				seat.get(
					"state_ut_name",
					""
				)
			),
			String(
				seat.get(
					"state_ut_code",
					""
				)
			),
			unique_id,
			1,
			0.65,
			true,
			distribution,
			{
				"source": "existing GIS runtime GeoJSON",
				"political_source": (
					"Sprint 5 deterministic bootstrap"
				)
			}
		)

		if not constituency_registry.add(
			constituency
		):
			failures.append(
				"Duplicate/invalid constituency: "
				+ unique_id
			)

	if constituency_registry.size() != 543:
		failures.append(
			"Constituency registry size=%s; expected 543"
			% constituency_registry.size()
		)

	for constituency_id in constituency_registry.ids():
		var constituency := (
			constituency_registry.get_constituency(
				constituency_id
			)
		)

		var errors := constituency.validate(
			persona_registry,
			true
		)

		failures.append_array(errors)

	if failures.is_empty():
		print(
			"SPRINT 5 PASS: 543 constituency political profiles validated."
		)
		quit(0)
		return

	for failure in failures:
		print(
			"SPRINT 5 FAILURE: "
			+ failure
		)

	quit(1)


func _build_deterministic_distribution(
	constituency_id: String,
	persona_registry: PersonaRegistry
) -> PersonaDistribution:
	var distribution := PersonaDistribution.new()

	var ids := persona_registry.ids()

	if ids.is_empty():
		return distribution

	var digest := (
		constituency_id.sha256_text()
	)

	var weights: Array[int] = []

	var total_weight := 0

	for index in ids.size():
		var hex_position := (
			index % digest.length()
		)

		var value := (
			_hex_value(
				digest[hex_position]
			)
			+ 1
		)

		var weight := value

		weights.append(weight)
		total_weight += weight

	var assigned := 0

	for index in ids.size():
		var units: int

		if index == ids.size() - 1:
			units = (
				PersonaDistribution.TOTAL_UNITS
				- assigned
			)
		else:
			units = int(
				floor(
					float(
						weights[index]
					)
					/ float(total_weight)
					* PersonaDistribution.TOTAL_UNITS
				)
			)

		distribution.set_share(
			ids[index],
			units
		)

		assigned += units

	return distribution


func _hex_value(
	character: String
) -> int:
	var chars := "0123456789abcdef"

	return max(
		0,
		chars.find(
			character.to_lower()
		)
	)
