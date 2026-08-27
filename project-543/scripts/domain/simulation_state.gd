class_name SimulationState
extends RefCounted

var schema_version: int = 1
var turn: int = 1
var personas: PersonaRegistry
var constituencies: ConstituencyRegistry
var parties: PartyRegistry
var ledger: Array[PoliticalStateChange] = []

func _init() -> void:
	personas = PersonaRegistry.new()
	constituencies = ConstituencyRegistry.new()
	parties = PartyRegistry.new()

func validate() -> Array[String]:
	var errors: Array[String] = []
	if turn < 1:
		errors.append("SimulationState.turn=%s; expected >= 1" % turn)
	errors.append_array(personas.validate())
	errors.append_array(constituencies.validate(personas))
	errors.append_array(parties.validate(constituencies))
	for index in ledger.size():
		var change: PoliticalStateChange = ledger[index]
		errors.append_array(change.validate())
	return errors

func to_dictionary() -> Dictionary:
	var serialized_ledger: Array = []
	for change in ledger:
		serialized_ledger.append(change.to_dictionary())

	return {
		"schema_version": schema_version,
		"turn": turn,
		"personas": personas.to_array(),
		"constituencies": constituencies.to_array(),
		"parties": parties.to_array(),
		"ledger": serialized_ledger
	}

static func from_dictionary(data: Dictionary) -> SimulationState:
	var state := SimulationState.new()
	state.schema_version = int(data.get("schema_version", 1))
	state.turn = int(data.get("turn", 1))
	state.personas = PersonaRegistry.from_array(data.get("personas", []))
	state.constituencies = ConstituencyRegistry.from_array(data.get("constituencies", []))
	state.parties = PartyRegistry.from_array(data.get("parties", []))
	for item in data.get("ledger", []):
		state.ledger.append(PoliticalStateChange.from_dictionary(item))
	return state
