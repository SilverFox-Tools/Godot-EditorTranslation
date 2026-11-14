@tool
extends EditorInspectorPlugin

const INI_Settings_Path := "res://Translation/Editor-Translation-Settings.ini"
const INI_Default_Translation_Path := "res://Translation/Editor.ini"
const INI_Translation_Section_Prefix := "Editor.Property."
const INI_Settings_Section := "Translations"

var _Translations: Dictionary = {}
var _Original_Labels: Dictionary[int, String] = {}
var _Translation_Files: Array[Dictionary] = []
var _Watched_Mtimes: Dictionary[String, int] = {}
var _Editor_Locale := ""
var _Refresh_Queued := false


func _init() -> void:
	Reload_Translations()


func _can_handle(Target_Object: Object) -> bool:
	return Target_Object.get_script() is Script


func _parse_property(
	Target_Object: Object,
	_Type: Variant.Type,
	Name: String,
	_Hint_Type: PropertyHint,
	_Hint_String: String,
	_Usage_Flags: int,
	_Wide: bool
) -> bool:
	if not _Get_Translation(Target_Object, Name).is_empty():
		_Queue_Inspector_Refresh()
	return false


func Reload_If_Changed() -> void:
	var Current_Locale := _Normalize_Locale(EditorInterface.get_editor_language())
	var Changed := Current_Locale != _Editor_Locale
	var Watched_Paths: Array[String] = [INI_Settings_Path]
	for Entry in _Translation_Files:
		Watched_Paths.append(Entry["path"])

	for Path in Watched_Paths:
		var Current_Mtime := FileAccess.get_modified_time(Path)
		if _Watched_Mtimes.get(Path, -1) != Current_Mtime:
			Changed = true
			break

	if Changed:
		Reload_Translations()


func Reload_Translations() -> void:
	_Load_Translations()
	_Editor_Locale = _Normalize_Locale(EditorInterface.get_editor_language())
	_Queue_Inspector_Refresh()


func Restore_Labels() -> void:
	var Inspector := EditorInterface.get_inspector()
	if Inspector == null:
		return

	for Control in Inspector.find_children("*", "EditorProperty", true, false):
		var Property_Editor := Control as EditorProperty
		var Instance_Id := Property_Editor.get_instance_id()
		if _Original_Labels.has(Instance_Id):
			Property_Editor.label = _Original_Labels[Instance_Id]

	_Original_Labels.clear()


func _Load_Translations() -> void:
	_Translation_Files = _Read_Translation_Files()
	_Watched_Mtimes.clear()
	_Watched_Mtimes[INI_Settings_Path] = FileAccess.get_modified_time(INI_Settings_Path)
	var Translations: Dictionary = {}

	for Entry in _Translation_Files:
		var Path: String = Entry["path"]
		var Locale: String = Entry["locale"]
		_Watched_Mtimes[Path] = FileAccess.get_modified_time(Path)

		if not FileAccess.file_exists(Path):
			push_warning("Editor Translation: Translation file does not exist: %s" % Path)
			continue

		var Config := ConfigFile.new()
		var Error := Config.load(Path)
		if Error != OK:
			push_error(
				"Editor Translation: failed to load %s: %s"
				% [Path, error_string(Error)]
			)
			continue

		var Found_Translation_Section := false
		for Section in Config.get_sections():
			if not Section.begins_with(INI_Translation_Section_Prefix):
				continue

			var Translated_Class_Name := Section.substr(INI_Translation_Section_Prefix.length())
			if Translated_Class_Name.is_empty() or Translated_Class_Name.contains("."):
				push_warning(
					"Editor Translation: ignoring invalid section [%s] in %s"
					% [Section, Path]
				)
				continue

			Found_Translation_Section = true
			if not Translations.has(Locale):
				Translations[Locale] = {}
			for Property_Name in Config.get_section_keys(Section):
				if Property_Name.is_empty() or Property_Name.contains("."):
					push_warning(
						"Editor Translation: ignoring invalid property '%s' in [%s]"
						% [Property_Name, Section]
					)
					continue

				var Value := str(Config.get_value(Section, Property_Name)).strip_edges()
				if Value.is_empty():
					push_warning(
						"Editor Translation: ignoring empty Translation for '%s.%s'"
						% [Translated_Class_Name, Property_Name]
					)
					continue

				var Key := "%s.%s" % [Translated_Class_Name, Property_Name]
				if not Translations[Locale].has(Key):
					Translations[Locale][Key] = Value

		if not Found_Translation_Section:
			push_error(
				"Editor Translation: no [%s<ClassName>] section found in %s"
				% [INI_Translation_Section_Prefix, Path]
			)

	var Active_Locale := _Normalize_Locale(EditorInterface.get_editor_language())
	var Language := Active_Locale.get_slice("-", 0)
	_Translations = Translations.get(Language, {}).duplicate()
	if Active_Locale != Language:
		_Translations.merge(Translations.get(Active_Locale, {}), true)


func _Read_Translation_Files() -> Array[Dictionary]:
	var Result: Array[Dictionary] = []
	if not FileAccess.file_exists(INI_Settings_Path):
		if FileAccess.file_exists(INI_Default_Translation_Path):
			Result.append({"locale": "zh", "path": INI_Default_Translation_Path})
		return Result

	var Settings := ConfigFile.new()
	var Error := Settings.load(INI_Settings_Path)
	if Error != OK:
		push_error(
			"Editor Translation: failed to load %s: %s"
			% [INI_Settings_Path, error_string(Error)]
		)
		return Result

	if not Settings.has_section(INI_Settings_Section):
		push_error("Editor Translation: missing [%s] section in %s" % [INI_Settings_Section, INI_Settings_Path])
		return Result

	var Entries: Variant = Settings.get_value(INI_Settings_Section, "Files", [])
	if not Entries is Array:
		push_error("Editor Translation: 'Files' must be an array in %s" % INI_Settings_Path)
		return Result

	for Entry in Entries:
		if not Entry is Dictionary:
			push_warning("Editor Translation: ignoring invalid file entry in %s" % INI_Settings_Path)
			continue

		var Locale := _Normalize_Locale(str(Entry.get("locale", "")))
		var Path := str(Entry.get("path", ""))
		if Locale.is_empty() or Path.is_empty():
			push_warning("Editor Translation: ignoring incomplete file entry in %s" % INI_Settings_Path)
			continue
		Result.append({"locale": Locale, "path": Path})

	return Result


func _Normalize_Locale(Locale: String) -> String:
	var Normalized := Locale.strip_edges().replace("_", "-").to_lower()
	while Normalized.contains("--"):
		Normalized = Normalized.replace("--", "-")
	return Normalized


func _Get_Translation(Target_Object: Object, Property_Name: String) -> String:
	var Attached_Script := Target_Object.get_script() as Script
	while Attached_Script != null:
		var Script_Name := Attached_Script.resource_path.get_file().get_basename()
		if not Script_Name.is_empty():
			var Key := "%s.%s" % [Script_Name, Property_Name]
			if _Translations.has(Key):
				return _Translations[Key]
		Attached_Script = Attached_Script.get_base_script()

	return ""


func _Queue_Inspector_Refresh() -> void:
	if _Refresh_Queued:
		return

	_Refresh_Queued = true
	call_deferred("_Refresh_Inspector_Labels")


func _Refresh_Inspector_Labels() -> void:
	_Refresh_Queued = false
	var Inspector := EditorInterface.get_inspector()
	if Inspector == null:
		return

	var Active_Editor_Ids: Dictionary[int, bool] = {}
	for Control in Inspector.find_children("*", "EditorProperty", true, false):
		var Property_Editor := Control as EditorProperty
		var Instance_Id := Property_Editor.get_instance_id()
		Active_Editor_Ids[Instance_Id] = true
		var Target_Object := Property_Editor.get_edited_object()
		if Target_Object == null:
			continue

		var Property_Name := str(Property_Editor.get_edited_property())
		var Translation := _Get_Translation(Target_Object, Property_Name)

		if Translation.is_empty():
			if _Original_Labels.has(Instance_Id):
				Property_Editor.label = _Original_Labels[Instance_Id]
			continue

		if not _Original_Labels.has(Instance_Id):
			_Original_Labels[Instance_Id] = Property_Editor.label
		Property_Editor.label = Translation

	for Instance_Id in _Original_Labels.keys():
		if not Active_Editor_Ids.has(Instance_Id):
			_Original_Labels.erase(Instance_Id)
