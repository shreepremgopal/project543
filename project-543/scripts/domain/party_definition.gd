class_name PartyDefinition
extends RefCounted

var party_id: String
var name: String
var colour: String
var leader: String
var ideological_profile: IdeologyProfile
var provenance: Dictionary

func _init(
	id_value: String = "",
	name_value: String = "",
	colour_value: String = "",
	leader_value: String = "",
	profile_value: IdeologyProfile = null,
	provenance_value: Dictionary = {}
) -> void:
	party_id = id_value
	name = name_value
	colour = colour_value
	leader = leader_value
	ideological_profile = profile_value if profile_value != null else IdeologyProfile.new()
	provenance = provenance_value.duplicate(true)

func validate() -> Array[String]:
	var errors: Array[String] = []
	if party_id.strip_edges().is_empty():
		errors.append("PartyDefinition.party_id must not be empty")
	if name.strip_edges().is_empty():
		errors.append("PartyDefinition.name must not be empty")
	if colour.strip_edges().is_empty():
		errors.append("PartyDefinition.colour must not be empty")
	if leader.strip_edges().is_empty():
		errors.append("PartyDefinition.leader must not be empty")
	if ideological_profile == null:
		errors.append("PartyDefinition.ideological_profile must not be null")
	else:
		errors.append_array(ideological_profile.validate())
	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"party_id": party_id,
		"name": name,
		"colour": colour,
		"leader": leader,
		"ideological_profile": ideological_profile.to_dictionary(),
		"provenance": provenance.duplicate(true)
	}

static func from_dictionary(data: Dictionary) -> PartyDefinition:
	return PartyDefinition.new(
		String(data.get("party_id", "")),
		String(data.get("name", "")),
		String(data.get("colour", "")),
		String(data.get("leader", "")),
		IdeologyProfile.from_dictionary(data.get("ideological_profile", {})),
		data.get("provenance", {})
	)
