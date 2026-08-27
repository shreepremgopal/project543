class_name PersonaRegistry
extends RefCounted

var definitions: Dictionary = {}

func add(definition: PersonaDefinition) -> bool:
	if definition == null or not definition.is_structurally_valid():
		return false
	if definitions.has(definition.persona_id):
		return false
	definitions[definition.persona_id] = definition
	return true

func has(persona_id: String) -> bool:
	return definitions.has(persona_id)

func get_definition(persona_id: String) -> PersonaDefinition:
	return definitions.get(persona_id)

func size() -> int:
	return definitions.size()

func ids() -> Array[String]:
	var result: Array[String] = []
	for persona_id in definitions:
		result.append(String(persona_id))
	result.sort()
	return result

func validate() -> Array[String]:
	var errors: Array[String] = []
	for persona_id in ids():
		var definition: PersonaDefinition = definitions[persona_id]
		errors.append_array(definition.validate())
		if definition.persona_id != persona_id:
			errors.append("PersonaRegistry key '%s' does not match definition ID '%s'" % [persona_id, definition.persona_id])
	return errors

func to_array() -> Array:
	var result: Array = []
	for persona_id in ids():
		result.append(definitions[persona_id].to_dictionary())
	return result

static func from_array(items: Array) -> PersonaRegistry:
	var registry := PersonaRegistry.new()
	for item in items:
		registry.add(PersonaDefinition.from_dictionary(item))
	return registry
