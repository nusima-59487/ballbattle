extends CanvasLayer
class_name DialogueBox

## On-screen dialogue with a typewriter effect.
##
## Usage (from any node):
##     await DialogueBox.show_dialogue(self, "Angler", ["Hey!", "Let's battle!"]).finished
##
## Click, Space or Enter finishes the current line; pressing again goes to the next line.
## With fullscreen = true the screen fades to black and the text is centred (used for "You blacked out").

signal finished

const FONT: FontFile = preload("res://assets/pixel_font/PressStart2P-Regular.ttf")
const CHARS_PER_SECOND := 40.0

var _speaker := ""
var _lines: Array[String] = []
var _fullscreen := false
var _index := 0
var _accepting_input := false
var _done := false

var _text_label: Label
var _hint_label: Label
var _typing_tween: Tween


## Creates a dialogue box under `parent`, starts it, and returns it so you can await `finished`.
static func show_dialogue(parent: Node, speaker: String, lines: Array[String], fullscreen: bool = false) -> DialogueBox:
	var box := DialogueBox.new()
	box._speaker = speaker
	box._lines = lines
	box._fullscreen = fullscreen

	if parent.name == "VerityVillager": 
		GameInstance.player_balls_lineup.append("verity")
	elif parent.name == "LovityVillager": 
		GameInstance.player_balls_lineup.append("lovity")

	parent.add_child(box)
	return box


func _ready() -> void:
	layer = 100
	# Keep working while the tree is paused (battle pauses during end-of-battle dialogue).
	process_mode = Node.PROCESS_MODE_ALWAYS

	if _lines.is_empty():
		# Nothing to say; finish on the next frame so callers can still `await finished`.
		_finish.call_deferred()
		return

	if _fullscreen:
		_build_fullscreen_ui()
	else:
		_build_box_ui()
		_accepting_input = true
		_show_line()


func _build_box_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP # block clicks on buttons underneath
	add_child(root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = -170
	panel.offset_bottom = -24
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.94)
	style.border_color = Color(1, 1, 1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var name_label := _make_label(16, Color.WHITE)
	name_label.text = _speaker
	name_label.visible = _speaker != ""
	vbox.add_child(name_label)

	_text_label = _make_label(14, Color.WHITE)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text_label)

	_hint_label = _make_label(10, Color(1, 1, 1, 0.6))
	_hint_label.text = " ▼  "
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint_label)


func _build_fullscreen_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color.BLACK
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.modulate.a = 0.0
	add_child(bg)

	_text_label = _make_label(24, Color.WHITE)
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bg.add_child(_text_label)

	_hint_label = _make_label(10, Color(1, 1, 1, 0.6))
	_hint_label.text = " ▼  "
	_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint_label.offset_left = -260
	_hint_label.offset_top = -48
	_hint_label.offset_right = -24
	_hint_label.offset_bottom = -24
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.visible = false
	bg.add_child(_hint_label)

	var fade := create_tween()
	fade.tween_property(bg, "modulate:a", 1.0, 0.8)
	fade.tween_interval(0.3)
	fade.tween_callback(func() -> void:
		_accepting_input = true
		_show_line())


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _show_line() -> void:
	var line := _lines[_index]
	_text_label.text = line
	_text_label.visible_ratio = 0.0
	_hint_label.visible = false
	if _typing_tween:
		_typing_tween.kill()
	_typing_tween = create_tween()
	_typing_tween.tween_property(_text_label, "visible_ratio", 1.0, maxf(line.length() / CHARS_PER_SECOND, 0.05))
	_typing_tween.tween_callback(func() -> void: _hint_label.visible = true)


func _input(event: InputEvent) -> void:
	if _done or not _accepting_input or event.is_echo():
		return
	var pressed_mouse: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if pressed_mouse or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	# First press while typing: reveal the whole line.
	if _typing_tween and _typing_tween.is_running():
		_typing_tween.kill()
		_text_label.visible_ratio = 1.0
		_hint_label.visible = true
		return
	_index += 1
	if _index >= _lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()
