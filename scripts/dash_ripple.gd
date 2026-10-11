extends Node2D
## A dash leaves an expanding, fading ring at its starting position.

const CYAN := Color("65f6dc")
const LIFETIME := 0.9
const MAX_RIPPLES := 4
var ripples: Array[Dictionary] = []
var emitted_count := 0


func reset() -> void:
	ripples.clear()
	emitted_count = 0
	queue_redraw()


func emit_at(at: Vector2) -> void:
	if ripples.size() >= MAX_RIPPLES:
		ripples.pop_front()
	ripples.append({"position": at, "age": 0.0})
	emitted_count += 1
	queue_redraw()


func advance(delta: float) -> void:
	for index in range(ripples.size() - 1, -1, -1):
		ripples[index]["age"] += delta
		if ripples[index]["age"] >= LIFETIME:
			ripples.remove_at(index)


static func appearance(ripple: Dictionary) -> Vector2:
	var progress := clampf(float(ripple["age"]) / LIFETIME, 0, 1)
	return Vector2(lerpf(12, 92, 1.0 - pow(1.0 - progress, 2)), pow(1.0 - progress, 1.6))


func _draw() -> void:
	for ripple in ripples:
		var shape := appearance(ripple)
		var center: Vector2 = ripple["position"]
		draw_arc(center, shape.x, 0, TAU, 128, CYAN * Color(1, 1, 1, shape.y * 0.12), 6, true)
		draw_arc(center, shape.x, 0, TAU, 128, CYAN * Color(1, 1, 1, shape.y), 2, true)
