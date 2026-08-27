class_name PartyRegistry
extends RefCounted

var definitions: Dictionary = {}
var states: Dictionary = {}

func add(definition: PartyDefinition, state: PartyState = null) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if definitions.has(definition.party_id):
		return false
	definitions[definition.party_id] = definition
	if state != null:
		if state.party_id != definition.party_id or not state.is_valid():
			definitions.erase(definition.party_id)
			return false
		states[definition.party_id] = state
	return true

func has(party_id: String) -> bool:
	return definitions.has(party_id)

func get_definition(party_id: String) -> PartyDefinition:
	return definitions.get(party_id)

func get_state(party_id: String) -> PartyState:
	return states.get(party_id)

func size() -> int:
	return definitions.size()

func ids() -> Array[String]:
	var result: Array[String] = []
	for party_id in definitions:
		result.append(String(party_id))
	result.sort()
	return result

func validate(constituency_registry: ConstituencyRegistry = null) -> Array[String]:
	var errors: Array[String] = []
	for party_id in ids():
		var definition: PartyDefinition = definitions[party_id]
		errors.append_array(definition.validate())
		if definition.party_id != party_id:
			errors.append("PartyRegistry key '%s' does not match party ID '%s'" % [party_id, definition.party_id])
		if states.has(party_id):
			var state: PartyState = states[party_id]
			errors.append_array(state.validate(constituency_registry))
			if state.party_id != party_id:
				errors.append("PartyState ID '%s' does not match registry key '%s'" % [state.party_id, party_id])
	return errors

func to_array() -> Array:
	var result: Array = []
	for party_id in ids():
		var item: Dictionary = {
			"definition": definitions[party_id].to_dictionary()
		}
		if states.has(party_id):
			item["state"] = states[party_id].to_dictionary()
		result.append(item)
	return result

static func from_array(items: Array) -> PartyRegistry:
	var registry := PartyRegistry.new()
	for item in items:
		var definition: PartyDefinition = PartyDefinition.from_dictionary(item.get("definition", {}))
		var state_data = item.get("state", null)
		var state: PartyState = null
		if state_data != null:
			state = PartyState.from_dictionary(state_data)
		registry.add(definition, state)
	return registry
