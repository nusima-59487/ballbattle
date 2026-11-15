extends Node2D
## Purely cosmetic layer for the battle scene.
##
## Animated background, arena floor + marquee rim, ambient embers, styled HUD,
## ball glows/trails/shadows, hit flashes, KO explosions, screen shake and an intro banner.
## It only READS battle state (balls, slots, ult bars) and never changes gameplay.

const FONT: FontFile = preload("res://assets/pixel_font/PressStart2P-Regular.ttf")

## Arena interior; matches the BounceAreaBound collision walls in main.tscn.
const ARENA := Rect2(-51.5, -48, 103.5, 96)

const PLAYER_COLOR := Color(0.35, 0.85, 1.0)
const ENEMY_COLOR := Color(1.0, 0.32, 0.38)
const ACCENT := Color(0.86, 0.6, 0.36) # the orange from the original background
const PANEL_COLOR := Color(0.07, 0.03, 0.07, 0.85)

const FALLBACK_PLAYER_SLOTS := [Vector2(-65.25, 17.5), Vector2(-65.25, 34.5), Vector2(-65.25, 51.5)]
const FALLBACK_ENEMY_SLOTS := [Vector2(68, 18), Vector2(68, 35), Vector2(68, 52)]
const SLOT_SIZE := 16.0

const TRAIL_POINTS := 14

const BACKGROUND_SHADER := """
shader_type canvas_item;
uniform vec4 col_light : source_color = vec4(0.25, 0.09, 0.19, 1.0);
uniform vec4 col_dark : source_color = vec4(0.08, 0.03, 0.08, 1.0);
uniform vec4 accent : source_color = vec4(0.86, 0.6, 0.36, 1.0);
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = floor(world); // snap to the 1-unit pixel grid
	float d = length(p / vec2(175.0, 115.0));
	vec3 col = mix(col_light.rgb, col_dark.rgb, smoothstep(0.15, 1.1, d));

	// slowly rotating sunburst behind the arena
	float ang = atan(p.y, p.x);
	float rays = step(0.5, fract(ang * 8.0 / 6.2831853 + TIME * 0.015));
	col += rays * 0.035 * (1.0 - smoothstep(0.0, 1.2, d));

	// scrolling diagonal stripes
	float s = fract((p.x + p.y + TIME * 5.0) / 18.0);
	col += step(0.8, s) * 0.02;

	// pulsing dot grid
	vec2 g = mod(p, 12.0);
	float dots = step(g.x, 0.5) * step(g.y, 0.5);
	float wave = 0.5 + 0.5 * sin(TIME * 1.5 - length(p) * 0.05);
	col = mix(col, accent.rgb, dots * (0.06 + 0.1 * wave));

	// twinkling stars
	vec2 cell = floor(p / 7.0);
	float h = hash(cell);
	vec2 m = mod(p, 7.0);
	vec2 star_at = floor(vec2(hash(cell + 3.1), hash(cell + 7.7)) * 6.0);
	float is_star = step(0.93, h) * step(distance(m, star_at), 0.1);
	float tw = 0.5 + 0.5 * sin(TIME * 2.5 + h * 80.0);
	col = mix(col, vec3(1.0, 0.9, 0.8), is_star * tw * 0.8);

	COLOR = vec4(col, 1.0);
}
"""

const FLOOR_SHADER := """
shader_type canvas_item;
uniform vec2 arena_size = vec2(103.5, 96.0);
uniform vec4 accent : source_color = vec4(0.86, 0.6, 0.36, 1.0);
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(world);
	float checker = mod(floor(p.x / 8.0) + floor(p.y / 8.0), 2.0);
	vec3 col = mix(vec3(0.17, 0.14, 0.2), vec3(0.21, 0.17, 0.24), checker);

	// tile seams
	vec2 t = mod(p, 8.0);
	col *= 1.0 - 0.12 * (step(t.x, 0.5) + step(t.y, 0.5));

	// light sheen sweeping across the floor
	float sweep = fract((p.x - p.y) / 160.0 - TIME * 0.12);
	col += (smoothstep(0.0, 0.03, sweep) - smoothstep(0.03, 0.07, sweep)) * 0.07;

	// centre emblem: two rings and a halfway line
	float r = length(p);
	float ring = step(abs(r - 20.0), 0.6) + step(abs(r - 5.0), 0.6);
	float mid = step(abs(p.x), 0.5) * 0.5;
	float emblem_pulse = 0.08 + 0.05 * sin(TIME * 2.0);
	col = mix(col, accent.rgb, clamp(ring + mid, 0.0, 1.0) * emblem_pulse);

	// inner shadow near the walls
	vec2 dist = min(UV, 1.0 - UV) * arena_size;
	float edge = min(dist.x, dist.y);
	col *= mix(0.55, 1.0, smoothstep(0.0, 9.0, edge));

	COLOR = vec4(col, 1.0);
}
"""

@onready var battle: Node2D = get_parent()
@onready var camera: Camera2D = get_parent().get_node_or_null("Camera2D")

var _time := 0.0
var _trauma := 0.0
var _tracked: Array[Dictionary] = []
var _rings: Array[Dictionary] = []
var _ult_was_full := {}
var _battle_ready := false
var _rim_layer: Node2D
var _flash_rect: ColorRect


func _ready() -> void:
	# Keep animating while the battle is paused for end-of-battle dialogue.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var old_bg := battle.get_node_or_null("Sprite2D_bg")
	if old_bg:
		old_bg.visible = false

	_build_background()
	_build_floor()
	_build_ambient_particles()
	_build_flash_layer()

	# Balls are added as children of the battle node; catch them as they spawn.
	battle.child_entered_tree.connect(_on_battle_child_added)

	# Battle's @onready vars are only set once the battle node itself is ready.
	await battle.ready
	_battle_ready = true
	_style_ult_bar(battle.player_ult_bar, PLAYER_COLOR)
	_style_ult_bar(battle.enemy_ult_bar, ENEMY_COLOR)
	_play_intro()


# --------------------------------------------------------------------------- building

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.z_index = -20
	bg.position = Vector2(-500, -300)
	bg.size = Vector2(1000, 600)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = BACKGROUND_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	bg.material = mat
	add_child(bg)


func _build_floor() -> void:
	# Rim (dark frame with marquee lights) sits between the background and the floor.
	_rim_layer = Node2D.new()
	_rim_layer.z_index = -10
	_rim_layer.draw.connect(_draw_rim)
	add_child(_rim_layer)

	var floor_rect := ColorRect.new()
	floor_rect.z_index = -8
	floor_rect.position = ARENA.position
	floor_rect.size = ARENA.size
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FLOOR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("arena_size", ARENA.size)
	floor_rect.material = mat
	add_child(floor_rect)


func _build_ambient_particles() -> void:
	var embers := CPUParticles2D.new()
	embers.z_index = -6
	embers.amount = 45
	embers.lifetime = 7.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(170, 95)
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -3)
	embers.initial_velocity_min = 2.0
	embers.initial_velocity_max = 7.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 1.5
	var tint := Gradient.new()
	tint.set_color(0, ACCENT)
	tint.set_color(1, Color(1.0, 0.45, 0.6))
	embers.color_initial_ramp = tint
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 0.7))
	fade.add_point(0.8, Color(1, 1, 1, 0.5))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	embers.color_ramp = fade
	add_child(embers)


func _build_flash_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash_rect)


func _style_ult_bar(bar: ProgressBar, color: Color) -> void:
	if not bar:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = PANEL_COLOR
	bg.border_color = ACCENT.darkened(0.35)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.border_color = color.darkened(0.45)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


# --------------------------------------------------------------------------- balls

func _on_battle_child_added(node: Node) -> void:
	if not node is Ball:
		return
	var ball: Ball = node
	# battle.gd assigns enemy_ball before add_child, so this tells us the side.
	var is_enemy: bool = ball == battle.get("enemy_ball")
	var color := ENEMY_COLOR if is_enemy else PLAYER_COLOR

	var sprite := ball.find_child("Sprite2D", false) as Sprite2D
	var radius := 12.0
	if sprite and sprite.texture:
		radius = sprite.texture.get_width() * absf(sprite.scale.x) * 0.5

	var trail := Line2D.new()
	trail.z_index = -4
	trail.width = radius * 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(1, 1))
	trail.width_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(color, 0.0))
	grad.set_color(1, Color(color, 0.45))
	trail.gradient = grad
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(trail)

	var entry := {
		"ball": ball,
		"color": color,
		"sprite": sprite,
		"sprite_color": sprite.self_modulate if sprite else Color.WHITE,
		"radius": radius,
		"trail": trail,
		"phase": randf() * TAU,
	}
	_tracked.append(entry)

	if ball.healthComponent:
		ball.healthComponent.health_changed.connect(_on_ball_health_changed.bind(entry))
	ball.die.connect(_on_ball_ko.bind(entry))

	# Spawn pop: ring + sparks. Deferred so the ball has its final position.
	(func() -> void:
		if is_instance_valid(ball):
			_add_ring(ball.global_position, color, radius * 3.0, 0.45)
			_burst(ball.global_position, color, 16, 70.0, 0.5, 1.5)
	).call_deferred()


func _on_ball_health_changed(_current: int, _base: int, delta: int, entry: Dictionary) -> void:
	var ball: Ball = entry.ball
	if not is_instance_valid(ball) or delta == 0:
		return
	if delta < 0:
		_shake(clampf(-delta / 40.0, 0.15, 0.45))
		_burst(ball.global_position, Color(1, 0.95, 0.85), 8, 60.0, 0.3, 1.0)
		var sprite: Sprite2D = entry.sprite
		if is_instance_valid(sprite):
			sprite.self_modulate = Color(4, 4, 4)
			var t := create_tween()
			t.tween_property(sprite, "self_modulate", entry.sprite_color, 0.12)
	else:
		_burst(ball.global_position, Color(0.5, 1.0, 0.55), 10, 25.0, 0.7, 1.2)


func _on_ball_ko(entry: Dictionary) -> void:
	var ball: Ball = entry.ball
	if not is_instance_valid(ball):
		return
	var pos := ball.global_position
	_shake(0.85)
	_flash(0.45)
	_add_ring(pos, Color.WHITE, entry.radius * 5.0, 0.6)
	_add_ring(pos, entry.color, entry.radius * 3.5, 0.45)
	_burst(pos, entry.color, 40, 140.0, 0.9, 2.0)
	_burst(pos, Color(1, 0.95, 0.8), 20, 90.0, 0.6, 1.2)


# --------------------------------------------------------------------------- effects

func _burst(pos: Vector2, color: Color, amount: int, speed: float, lifetime: float, size: float) -> void:
	var p := CPUParticles2D.new()
	p.z_index = 5
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.4
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	p.color = color
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	add_child(p)
	p.emitting = true
	get_tree().create_timer(lifetime + 0.3).timeout.connect(p.queue_free)


func _add_ring(pos: Vector2, color: Color, max_radius: float, duration: float) -> void:
	_rings.append({"pos": pos, "color": color, "max_r": max_radius, "dur": duration, "t": 0.0})


func _shake(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


func _flash(alpha: float) -> void:
	_flash_rect.color.a = alpha
	var t := create_tween()
	t.tween_property(_flash_rect, "color:a", 0.0, 0.3)


func _play_intro() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0.85)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

	var top_bar := ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.anchor_right = 1.0
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_bar)
	var bottom_bar := ColorRect.new()
	bottom_bar.color = Color.BLACK
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_bar)

	var title := _make_banner_label("BATTLE START!", 40, ACCENT.lightened(0.35))
	title.offset_top = -40
	title.offset_bottom = -40
	title.offset_left = -1500
	title.offset_right = -1500
	root.add_child(title)

	var enemy_name: String = GameInstance.current_enemy_display_name
	var vs := _make_banner_label("VS  " + (enemy_name.to_upper() if enemy_name != "" else "???"), 20, ENEMY_COLOR.lightened(0.25))
	vs.offset_top = 30
	vs.offset_bottom = 30
	vs.offset_left = 1500
	vs.offset_right = 1500
	root.add_child(vs)

	var t := create_tween()
	t.tween_property(flash, "color:a", 0.0, 0.45)
	t.parallel().tween_property(top_bar, "offset_bottom", 64.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(bottom_bar, "offset_top", -64.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(title, "offset_left", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(title, "offset_right", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(vs, "offset_left", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(vs, "offset_right", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.9)
	t.tween_property(root, "modulate:a", 0.0, 0.35)
	t.tween_callback(layer.queue_free)


func _make_banner_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	return label


# --------------------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_time += delta

	# screen shake
	if camera:
		_trauma = maxf(_trauma - delta * 2.2, 0.0)
		var s := _trauma * _trauma
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * s * 4.0
		camera.rotation = randf_range(-1, 1) * s * 0.02

	# trails; fade out and drop balls that are gone
	for i in range(_tracked.size() - 1, -1, -1):
		var e := _tracked[i]
		var trail: Line2D = e.trail
		if not is_instance_valid(e.ball):
			_tracked.remove_at(i)
			var t := create_tween()
			t.tween_property(trail, "modulate:a", 0.0, 0.3)
			t.tween_callback(trail.queue_free)
			continue
		trail.add_point((e.ball as Ball).global_position)
		while trail.get_point_count() > TRAIL_POINTS:
			trail.remove_point(0)

	# expanding rings
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i].t += delta
		if _rings[i].t >= _rings[i].dur:
			_rings.remove_at(i)

	if _battle_ready:
		_update_hud()

	queue_redraw()
	_rim_layer.queue_redraw()


func _update_hud() -> void:
	# ult bars glow + sparkle when full
	for bar_data in [[battle.player_ult_bar, PLAYER_COLOR], [battle.enemy_ult_bar, ENEMY_COLOR]]:
		var bar: ProgressBar = bar_data[0]
		if not bar:
			continue
		var full := bar.value >= bar.max_value
		if full:
			var b := 1.25 + 0.35 * sin(_time * 10.0)
			bar.self_modulate = Color(b, b, b)
			if not _ult_was_full.get(bar, false):
				_burst(bar.get_global_rect().get_center(), bar_data[1], 14, 50.0, 0.5, 1.2)
		else:
			bar.self_modulate = Color.WHITE
		_ult_was_full[bar] = full

	# dim player slots whose ball has already been sent out
	for slot: TextureButton in battle.player_slots:
		slot.self_modulate = Color(0.35, 0.35, 0.4) if slot.disabled else Color.WHITE

	# dim defeated enemy balls
	var idx: int = battle.current_enemy_ball_idx
	for i in battle.enemy_slots.size():
		var s: Sprite2D = battle.enemy_slots[i]
		s.self_modulate = Color(0.3, 0.3, 0.35) if i < idx else Color.WHITE


# --------------------------------------------------------------------------- drawing

func _draw_rim() -> void:
	var rim := ARENA.grow(7)
	# drop shadow + frame
	_rim_layer.draw_rect(Rect2(rim.position + Vector2(3, 4), rim.size), Color(0, 0, 0, 0.45))
	_rim_layer.draw_rect(rim, Color(0.11, 0.05, 0.1))
	_rim_layer.draw_rect(rim, ACCENT.darkened(0.4), false, 1.0)

	# marquee lights chasing around the rim
	var inset := rim.grow(-3.5)
	var corners := [inset.position, Vector2(inset.end.x, inset.position.y), inset.end, Vector2(inset.position.x, inset.end.y)]
	var light_idx := 0
	for side in 4:
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var steps := int(a.distance_to(b) / 8.0)
		for k in steps:
			var p := a.lerp(b, float(k) / steps)
			var on := 0.5 + 0.5 * sin(_time * 6.0 - light_idx * 0.7)
			var c := ACCENT.darkened(0.55).lerp(ACCENT.lightened(0.3), on)
			_rim_layer.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), c)
			light_idx += 1

	# bright inner edge that gently pulses
	var pulse := 0.55 + 0.25 * sin(_time * 2.5)
	_rim_layer.draw_rect(ARENA.grow(1), Color(ACCENT, pulse), false, 1.0)


func _draw() -> void:
	# ball shadows and glows (drawn before the balls, which come later in the tree)
	for e in _tracked:
		var ball: Ball = e.ball
		if not is_instance_valid(ball):
			continue
		var pos := ball.global_position
		var r: float = e.radius
		draw_set_transform(pos + Vector2(0, r * 0.8), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, r * 0.95, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var pulse := 0.8 + 0.2 * sin(_time * 6.0 + e.phase)
		for i in 3:
			draw_circle(pos, r + 1.5 + i * 2.0, Color(e.color, 0.09 * pulse * (3 - i)))

	# shockwave rings
	for ring in _rings:
		var k: float = ring.t / ring.dur
		var radius: float = lerpf(2.0, ring.max_r, 1.0 - pow(1.0 - k, 3.0))
		draw_arc(ring.pos, radius, 0.0, TAU, 32, Color(ring.color, 1.0 - k), lerpf(3.0, 0.5, k))

	if _battle_ready:
		_draw_hud()


func _draw_hud() -> void:
	var player_centers: Array[Vector2] = []
	for i in battle.player_slots.size():
		var slot: TextureButton = battle.player_slots[i]
		var rect := slot.get_global_rect()
		player_centers.append(rect.get_center() if rect.size.x > 1.0 else FALLBACK_PLAYER_SLOTS[i])
	var enemy_centers: Array[Vector2] = []
	for i in battle.enemy_slots.size():
		var s: Sprite2D = battle.enemy_slots[i]
		enemy_centers.append(s.global_position if s.texture else FALLBACK_ENEMY_SLOTS[i])

	_draw_slot_column(player_centers, PLAYER_COLOR, "YOU")
	_draw_slot_column(enemy_centers, ENEMY_COLOR, "FOE")

	# selected player slot: pulsing outline
	var pulse := 0.6 + 0.4 * sin(_time * 8.0)
	for i in battle.player_slots.size():
		var slot: TextureButton = battle.player_slots[i]
		if slot.button_pressed and not slot.disabled:
			var r := Rect2(player_centers[i] - Vector2.ONE * (SLOT_SIZE * 0.5 + 1.5), Vector2.ONE * (SLOT_SIZE + 3))
			draw_rect(r, Color(PLAYER_COLOR.lightened(0.4), pulse), false, 1.0)

	# active enemy ball: pulsing outline + pointer
	var idx: int = battle.current_enemy_ball_idx
	if idx < enemy_centers.size():
		var c := enemy_centers[idx]
		var r := Rect2(c - Vector2.ONE * (SLOT_SIZE * 0.5 + 1.5), Vector2.ONE * (SLOT_SIZE + 3))
		draw_rect(r, Color(ENEMY_COLOR.lightened(0.3), pulse), false, 1.0)
		var tip := c + Vector2(SLOT_SIZE * 0.5 + 3 + sin(_time * 6.0), 0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(4, -3), tip + Vector2(4, 3)]), ENEMY_COLOR)

	# ult bar labels
	for bar_data in [[battle.player_ult_bar, PLAYER_COLOR], [battle.enemy_ult_bar, ENEMY_COLOR]]:
		var bar: ProgressBar = bar_data[0]
		if not bar:
			continue
		var rect := bar.get_global_rect()
		draw_rect(rect.grow(2), PANEL_COLOR)
		draw_rect(rect.grow(2), Color(bar_data[1], 0.5), false, 1.0)
		var full := bar.value >= bar.max_value
		var label := "MAX" if full else "ULT"
		var col: Color = bar_data[1].lightened(0.3) if full and fmod(_time, 0.3) < 0.15 else Color(1, 1, 1, 0.8)
		_draw_text_centered(label, Vector2(rect.get_center().x, rect.position.y - 5), 4, col)


func _draw_slot_column(centers: Array[Vector2], color: Color, title: String) -> void:
	var half := SLOT_SIZE * 0.5
	var bounds := Rect2(centers[0] - Vector2.ONE * half, Vector2.ONE * SLOT_SIZE)
	for c in centers:
		bounds = bounds.expand(c - Vector2.ONE * half).expand(c + Vector2.ONE * half)
	bounds = bounds.grow(3)
	draw_rect(Rect2(bounds.position + Vector2(2, 2), bounds.size), Color(0, 0, 0, 0.4))
	draw_rect(bounds, PANEL_COLOR)
	draw_rect(bounds, Color(color, 0.6), false, 1.0)
	for c in centers:
		draw_rect(Rect2(c - Vector2.ONE * half, Vector2.ONE * SLOT_SIZE), Color(color, 0.08))
	_draw_text_centered(title, Vector2(bounds.get_center().x, bounds.position.y - 3), 4, color.lightened(0.2))


func _draw_text_centered(text: String, baseline_center: Vector2, font_size: int, color: Color) -> void:
	# Press Start 2P is only crisp at multiples of 8px, so draw at 8 and scale down.
	var scale_factor := font_size / 8.0
	var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_set_transform(baseline_center, 0.0, Vector2.ONE * scale_factor)
	var pos := Vector2(-w * 0.5, 0)
	draw_string(FONT, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0, 0, 0, 0.8))
	draw_string(FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
