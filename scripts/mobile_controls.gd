extends RefCounted
## One touch owns movement until release. Other touches never steal that ownership.
const CONTROL_SCALE := 2.0
const RADIUS := 72.0 * CONTROL_SCALE
const DEAD_ZONE := 0.14
const DASH_RADIUS := 64.0 * CONTROL_SCALE
var following := false
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

func configure(view: Rect2, safe: Rect2, arena: Rect2) -> void:
	reset()
	view_bounds = view
	safe_bounds = safe
	var top := maxf(arena.position.y, safe.position.y + 112)
	move_region = Rect2(Vector2(safe.position.x + 20, top), Vector2(view.get_center().x - 40 - safe.position.x - 20, safe.end.y - 20 - top))
	fixed_center = Vector2(safe.position.x + RADIUS + 32, safe.end.y - RADIUS - 48)
	dash_center = Vector2(safe.end.x - DASH_RADIUS - 32, fixed_center.y)
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
	if at.distance_to(dash_center) <= DASH_RADIUS + 12 * CONTROL_SCALE:
		if dash_touch == -1:
			dash_touch = index
			return "dash"
		return ""
	if move_touch != -1:
		return ""
	if (following and move_region.has_point(at)) or (not following and at.distance_to(fixed_center) <= RADIUS + 24 * CONTROL_SCALE):
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
	knob = offset.limit_length(RADIUS)
	var strength := clampf((offset.length() / RADIUS - DEAD_ZONE) / (1.0 - DEAD_ZONE), 0.0, 1.0)
	direction = offset.normalized() * strength if strength > 0 else Vector2.ZERO

func release(index: int) -> void:
	if index == move_touch:
		move_touch = -1
		direction = Vector2.ZERO
		knob = Vector2.ZERO
		if not following:
			center = fixed_center
	if index == dash_touch:
		dash_touch = -1
