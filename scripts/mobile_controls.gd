extends RefCounted
## One touch owns movement until release. Other touches never steal that ownership.
const CONTROL_SCALE := 1.1
const REFERENCE_SHORT_EDGE := 810.0
const MIN_SIZE_FACTOR := 0.85
const MAX_SIZE_FACTOR := 1.0
const MAX_JOYSTICK_DIAMETER_DP := 120.0
const MAX_DASH_DIAMETER_DP := 100.0
const RADIUS := 72.0 * CONTROL_SCALE
const DASH_RADIUS := 64.0 * CONTROL_SCALE
var following := false
var visual_scale := CONTROL_SCALE
var radius := RADIUS
var dash_radius := DASH_RADIUS
var move_touch := -1
var dash_touch := -1
var direction := Vector2.ZERO
var center := Vector2.ZERO
var knob := Vector2.ZERO
var fixed_center := Vector2.ZERO
var dash_center := Vector2.ZERO
var view_bounds := Rect2()
var safe_bounds := Rect2()
var move_region := Rect2()

func configure(view: Rect2, safe: Rect2, arena: Rect2, screen_pixel_scale: float = 1.0, screen_density: float = 1.0) -> void:
	reset()
	view_bounds = view
	safe_bounds = safe
	var size_factor := clampf(minf(safe.size.x, safe.size.y) / REFERENCE_SHORT_EDGE, MIN_SIZE_FACTOR, MAX_SIZE_FACTOR)
	visual_scale = CONTROL_SCALE * size_factor
	# Cap the final display size after the game's canvas stretch, not just logical pixels.
	var pixels_per_unit := maxf(0.001, screen_pixel_scale)
	var density := maxf(0.1, screen_density)
	var display_limit := minf(MAX_JOYSTICK_DIAMETER_DP * density / (144.0 * pixels_per_unit), MAX_DASH_DIAMETER_DP * density / (128.0 * pixels_per_unit))
	visual_scale = minf(visual_scale, display_limit)
	radius = 72.0 * visual_scale
	dash_radius = 64.0 * visual_scale
	var top := maxf(arena.position.y, safe.position.y + 112)
	move_region = Rect2(Vector2(safe.position.x + 20, top), Vector2(view.get_center().x - 40 - safe.position.x - 20, safe.end.y - 20 - top))
	fixed_center = Vector2(safe.position.x + radius + 32, safe.end.y - radius - 48)
	dash_center = Vector2(safe.end.x - dash_radius - 32, fixed_center.y)
	center = fixed_center

func reset() -> void:
	move_touch = -1
	dash_touch = -1
	direction = Vector2.ZERO
	center = fixed_center
	knob = Vector2.ZERO

func set_following(enabled: bool) -> void:
	following = enabled
	reset()

func press(index: int, at: Vector2) -> String:
	if index == move_touch or index == dash_touch:
		return ""
	if at.distance_to(dash_center) <= dash_radius + 12 * visual_scale:
		if dash_touch == -1:
			dash_touch = index
			return "dash"
		return ""
	if move_touch != -1:
		return ""
	if (following and move_region.has_point(at)) or (not following and at.distance_to(fixed_center) <= radius + 24 * visual_scale):
		move_touch = index
		# A new floating touch establishes a neutral center: landing never moves the player.
		center = at if following else fixed_center
		knob = Vector2.ZERO
		direction = Vector2.ZERO
		if not following:
			drag(index, at)
		return "move"
	return ""

func drag(index: int, at: Vector2) -> void:
	if index != move_touch:
		return
	var offset := at - center
	# The touchdown point stays anchored for this gesture; only the knob moves.
	knob = offset.limit_length(radius)
	direction = offset.normalized()

func release(index: int) -> void:
	if index == move_touch:
		move_touch = -1
		direction = Vector2.ZERO
		knob = Vector2.ZERO
		if not following:
			center = fixed_center
	if index == dash_touch:
		dash_touch = -1
