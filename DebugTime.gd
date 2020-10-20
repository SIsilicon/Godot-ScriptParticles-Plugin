tool
extends Node

var times := {}


func start_record(record: String) -> bool:
	if not times.has(record):
		times[record] = OS.get_ticks_msec()
		return true
	return false


func stop_record(record: String, return_in_secs := false) -> float:
	if times.has(record):
		var prev_time: float = times[record]
		times.erase(record)
		return (OS.get_ticks_msec() - prev_time) / (1000.0 if return_in_secs else 1.0)
	return -1.0

