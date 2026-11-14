@tool
extends EditorPlugin

const Inspector_Translator = preload("res://addons/Editor-Translation/Inspector-Translator.gd")
const Translation_Panel = preload("res://addons/Editor-Translation/Translation-Panel.gd")

var _Inspector_Translator: EditorInspectorPlugin
var _Translation_Panel: VBoxContainer
var _Reload_Timer := 0.0


func _enter_tree() -> void:
	_Inspector_Translator = Inspector_Translator.new()
	add_inspector_plugin(_Inspector_Translator)

	_Translation_Panel = Translation_Panel.new()
	_Translation_Panel.Translation_Files_Changed.connect(_On_Translation_Files_Changed)
	add_control_to_bottom_panel(_Translation_Panel, "编辑器翻译")
	set_process(true)


func _exit_tree() -> void:
	set_process(false)
	if _Inspector_Translator != null:
		_Inspector_Translator.Restore_Labels()
		remove_inspector_plugin(_Inspector_Translator)
		_Inspector_Translator = null
	if _Translation_Panel != null:
		remove_control_from_bottom_panel(_Translation_Panel)
		_Translation_Panel.queue_free()
		_Translation_Panel = null


func _process(Delta: float) -> void:
	_Reload_Timer += Delta
	if _Reload_Timer < 1.0:
		return

	_Reload_Timer = 0.0
	_Inspector_Translator.Reload_If_Changed()


func _On_Translation_Files_Changed() -> void:
	_Inspector_Translator.Reload_Translations()
