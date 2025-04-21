extends Node

signal time_updated(formatted_time_string: String, elapsed_seconds: float)

var elapsed_time: float = 0.0
var is_paused: bool = false # Optional: To pause the timer

func _process(delta: float) -> void:
    if is_paused:
        return

    elapsed_time += delta
    emit_signal("time_updated", get_formatted_time(), elapsed_time)

func get_elapsed_time() -> float:
    return elapsed_time

func get_formatted_time() -> String:
    var total_seconds = int(elapsed_time)
    var minutes = total_seconds / 60
    var seconds = total_seconds % 60
    # Format as MM:SS with leading zeros
    return "%02d:%02d" % [minutes, seconds]

func reset_timer() -> void:
    elapsed_time = 0.0
    emit_signal("time_updated", get_formatted_time(), elapsed_time)

func pause_timer() -> void:
    is_paused = true

func resume_timer() -> void:
    is_paused = false