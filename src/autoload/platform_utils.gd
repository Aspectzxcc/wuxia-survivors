extends Node

# Enum to represent different platform categories
const PlatformType = Enums.PlatformType

# Variable to store the detected platform type
var current_platform: PlatformType = PlatformType.UNKNOWN

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("web_ios") or OS.has_feature("web_android"):
		current_platform = PlatformType.MOBILE
		print("PlatformUtils: Detected platform: Mobile")
	else:
		current_platform = PlatformType.PC
		print("PlatformUtils: Detected platform: PC")


# Helper function to easily check if the current platform is mobile
func is_mobile() -> bool:
	return current_platform == PlatformType.MOBILE


# Helper function to easily check if the current platform is PC (or web)
func is_pc() -> bool:
	return current_platform == PlatformType.PC
