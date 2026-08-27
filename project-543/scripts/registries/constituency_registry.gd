class_name ConstituencyRegistry
extends RefCounted

var constituencies: Dictionary = {}

func add(constituency: Constituency) -> bool:
	if constituency == null or constituency.unique_id.strip_edges().is_empty():
		return false
	if constituencies.has(constituency.unique_id):
		return false
	constituencies[constituency.unique_id] = constituency
	return true

func has(unique_id: String) -> bool:
	return constituencies.has(unique_id)

func get_constituency(unique_id: String) -> Constituency:
	return constituencies.get(unique_id)

func size() -> int:
	return constituencies.size()

func ids() -> Array[String]:
	var result: Array[String] = []
	for unique_id in constituencies:
		result.append(String(unique_id))
	result.sort()
	return result

func validate(persona_registry: PersonaRegistry = null) -> Array[String]:
	var errors: Array[String] = []
	for unique_id in ids():
		var constituency: Constituency = constituencies[unique_id]
		errors.append_array(constituency.validate(persona_registry, false))
		if constituency.unique_id != unique_id:
			errors.append(
				"ConstituencyRegistry key '%s' does not match constituency ID '%s'"
				% [unique_id, constituency.unique_id]
			)
	return errors

func to_array() -> Array:
	var result: Array = []
	for unique_id in ids():
		result.append(constituencies[unique_id].to_dictionary())
	return result

static func from_array(items: Array) -> ConstituencyRegistry:
	var registry := ConstituencyRegistry.new()
	for item in items:
		registry.add(Constituency.from_dictionary(item))
	return registry
