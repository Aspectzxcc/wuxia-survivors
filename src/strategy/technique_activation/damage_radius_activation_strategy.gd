class_name DamageRadiusActivationStrategy
extends TechniqueActivationStrategy

const StatType = Enums.StatType # Assuming you have this Enum

# Overrides the base activate method
func activate(player: Player, calculated_stats: Dictionary, technique_data: TechniqueData) -> void:
	if not is_instance_valid(player):
		printerr("DamageRadiusActivation: Invalid Player node provided.")
		return
	if not is_instance_valid(technique_data) or not technique_data.effect_scene:
		printerr("DamageRadiusActivation: Technique data or scene not set!")
		return

	var existing_instance: Node2D = null

	# --- Check for existing instance directly ---
	for child in player.get_children():
		if child.name.replace(" ", "") == technique_data.technique_name.replace(" ", "") and child is Area2D:
			existing_instance = child
			break

	# --- Process based on whether an instance was found ---
	if not is_instance_valid(existing_instance):
		# --- Instance doesn't exist, create it ---
		var instance = technique_data.effect_scene.instantiate()
		if not instance is Node2D:
			printerr("DamageRadiusActivation: Instantiated scene is not a Node2D!")
			if is_instance_valid(instance):
				instance.queue_free()
			return

		if instance.has_method("initialize"):
			instance.initialize(calculated_stats)
		else:
			printerr("DamageRadiusActivation: Instantiated scene '%s' is missing initialize method." % technique_data.scene.resource_path)

		player.add_child(instance)
		player.move_child(instance, 0)
		instance.owner = player

	else:
		# --- Instance already exists, update its stats ---
		if existing_instance.has_method("initialize"):
			existing_instance.initialize(calculated_stats)
		else:
			printerr("DamageRadiusActivation: Existing instance '%s' is missing initialize method for update." % existing_instance.name)
