# game_data.gd
extends Node

var all_techniques: Array[TechniqueData] = []
var all_passives: Array[PassiveData] = []

# --- Technique Constants ---
const TECHNIQUES_ROOT_PATH = "res://src/resource/technique/"
const TECHNIQUE_BASE_SCRIPT = preload("res://src/data/technique/technique_data.gd")

# --- Passive Constants ---
const PASSIVES_ROOT_PATH = "res://src/resource/passive/"
const PASSIVE_BASE_SCRIPT = preload("res://src/data/passive/passive_data.gd") # Preload the base passive script

func _ready():
    # --- ADDED: Check if base scripts loaded ---
    if not TECHNIQUE_BASE_SCRIPT is Script:
        printerr("GameData: Failed to preload TECHNIQUE_BASE_SCRIPT! Check path and export settings.")
        return # Stop if base script fails
    if not PASSIVE_BASE_SCRIPT is Script:
        printerr("GameData: Failed to preload PASSIVE_BASE_SCRIPT! Check path and export settings.")
        return # Stop if base script fails
    # --- END ADDED ---

    # Load Techniques
    _load_resources_recursively(TECHNIQUES_ROOT_PATH, all_techniques, TECHNIQUE_BASE_SCRIPT)
    print("GameData Loaded: ", all_techniques.size(), " Techniques")
    if all_techniques.is_empty():
        printerr("GameData: No techniques were loaded. Check paths, resource script assignments, and TECHNIQUE_BASE_SCRIPT path.")

    # Load Passives
    _load_resources_recursively(PASSIVES_ROOT_PATH, all_passives, PASSIVE_BASE_SCRIPT)
    print("GameData Loaded: ", all_passives.size(), " Passives")
    if all_passives.is_empty():
        printerr("GameData: No passives were loaded. Check paths, resource script assignments, and PASSIVE_BASE_SCRIPT path.")


func _load_resources_recursively(path: String, target_array: Array, base_script: Script):
    var dir = DirAccess.open(path)
    if dir:
        dir.list_dir_begin()
        var item_name = dir.get_next()
        while item_name != "":
            if item_name == "." or item_name == "..":
                item_name = dir.get_next()
                continue

            var full_item_path = path.path_join(item_name)

            if dir.current_is_dir():
                _load_resources_recursively(full_item_path, target_array, base_script)
            else:
                var resource_path_to_load: String = ""
                var is_resource_file = false

                # Check for both .tres.remap and .tres
                if item_name.ends_with(".tres.remap"):
                    is_resource_file = true
                    resource_path_to_load = full_item_path.trim_suffix(".remap")
                elif item_name.ends_with(".tres"):
                    is_resource_file = true
                    resource_path_to_load = full_item_path

                if is_resource_file:
                    # Load using the determined path
                    var resource = load(resource_path_to_load)
                    if resource:
                        var actual_script = resource.get_script()
                        if actual_script:
                            var current_script = actual_script
                            var is_correct_type = false
                            while current_script:
                                if current_script == base_script:
                                    is_correct_type = true
                                    break
                                current_script = current_script.get_base_script()

                            if is_correct_type:
                                target_array.append(resource)
                            else:
                                # Keep this log: Indicates a potential setup error
                                print("GameData: Incorrect script type for: ", resource_path_to_load, " Expected base: ", base_script.resource_path)
                        else:
                            # Keep this log: Indicates resource missing script
                            print("GameData: Resource has NO script: ", resource_path_to_load)
                    else:
                        # Keep this error: Essential for debugging load failures
                        printerr("GameData: Failed to load resource (check path/dependencies/export settings): ", resource_path_to_load)
                # Removed log for non-.tres files

            item_name = dir.get_next()
    else:
        # Keep this error: Essential for debugging path issues
        printerr("GameData: Could not open directory: ", path)
