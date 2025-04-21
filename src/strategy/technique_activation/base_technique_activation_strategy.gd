class_name TechniqueActivationStrategy extends Resource

# Base class for all technique activation strategies.
# Defines the interface for how a technique is activated.

# Abstract method - must be implemented by subclasses.
# player: The Player node activating the technique.
# calculated_stats: A dictionary containing the pre-calculated final stats for this technique activation.
# technique_data: The TechniqueData resource associated with this activation.
func activate(_player: Player, _calculated_stats: Dictionary, _technique_data: TechniqueData) -> void:
	push_error("activate() must be implemented by the subclass.")