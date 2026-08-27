class_name PersonaCatalogLoader
extends RefCounted

static func load_json(path: String) -> PersonaRegistry:
	var registry := PersonaRegistry.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Persona catalogue could not be opened: " + path)
		return registry

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"Persona catalogue JSON parse error: %s at line %s"
			% [parser.get_error_message(), parser.get_error_line()]
		)
		return registry

	if typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Persona catalogue root must be a Dictionary.")
		return registry

	var items = parser.data.get("personas", [])
	if typeof(items) != TYPE_ARRAY:
		push_error("Persona catalogue 'personas' must be an Array.")
		return registry

	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			push_error("Persona catalogue contains a non-Dictionary entry.")
			continue

		var definition := PersonaDefinition.from_dictionary(item)
		if not registry.add(definition):
			push_error(
				"Persona catalogue rejected definition '%s'."
				% definition.persona_id
			)

	return registry

static func load_exact_25(path: String) -> PersonaRegistry:
	var registry := load_json(path)
	if registry.size() != 25:
		push_error(
			"Persona catalogue must contain exactly 25 definitions; got %s."
			% registry.size()
		)
	return registry
