@tool
extends VBoxContainer

signal Translation_Files_Changed

const INI_Settings_Path := "res://Translation/Editor-Translation-Settings.ini"
const INI_Translation_Section_Prefix := "Editor.Property."
const Language_Options := [
	["ar", "阿拉伯语"],
	["bg", "保加利亚语"],
	["cs", "捷克语"],
	["da", "丹麦语"],
	["de", "德语"],
	["el", "希腊语"],
	["en", "英语"],
	["es", "西班牙语"],
	["et", "爱沙尼亚语"],
	["fa", "波斯语"],
	["fi", "芬兰语"],
	["fr", "法语"],
	["he", "希伯来语"],
	["hi", "印地语"],
	["hr", "克罗地亚语"],
	["hu", "匈牙利语"],
	["id", "印度尼西亚语"],
	["it", "意大利语"],
	["ja", "日语"],
	["ko", "韩语"],
	["lt", "立陶宛语"],
	["lv", "拉脱维亚语"],
	["nb", "挪威语"],
	["nl", "荷兰语"],
	["pl", "波兰语"],
	["pt", "葡萄牙语"],
	["ro", "罗马尼亚语"],
	["ru", "俄语"],
	["sk", "斯洛伐克语"],
	["sl", "斯洛文尼亚语"],
	["sr", "塞尔维亚语"],
	["sv", "瑞典语"],
	["th", "泰语"],
	["tr", "土耳其语"],
	["uk", "乌克兰语"],
	["vi", "越南语"],
	["zh", "中文"],
]
const Region_Options := [
	["", "无地区"],
	["ar", "阿根廷"],
	["at", "奥地利"],
	["au", "澳大利亚"],
	["be", "比利时"],
	["br", "巴西"],
	["ca", "加拿大"],
	["ch", "瑞士"],
	["cn", "中国大陆"],
	["cz", "捷克"],
	["de", "德国"],
	["dk", "丹麦"],
	["es", "西班牙"],
	["fi", "芬兰"],
	["fr", "法国"],
	["gb", "英国"],
	["gr", "希腊"],
	["hk", "中国香港"],
	["hr", "克罗地亚"],
	["hu", "匈牙利"],
	["ie", "爱尔兰"],
	["il", "以色列"],
	["in", "印度"],
	["is", "冰岛"],
	["it", "意大利"],
	["jp", "日本"],
	["kr", "韩国"],
	["mx", "墨西哥"],
	["nl", "荷兰"],
	["no", "挪威"],
	["nz", "新西兰"],
	["pl", "波兰"],
	["pt", "葡萄牙"],
	["ro", "罗马尼亚"],
	["ru", "俄罗斯"],
	["sa", "沙特阿拉伯"],
	["se", "瑞典"],
	["sg", "新加坡"],
	["si", "斯洛文尼亚"],
	["sk", "斯洛伐克"],
	["tw", "中国台湾"],
	["ua", "乌克兰"],
	["us", "美国"],
	["za", "南非"],
]

var _Language_Select: OptionButton
var _Region_Select: OptionButton
var _Filter_Select: OptionButton
var _Path_Edit: LineEdit
var _File_List: ItemList
var _Status_Label: Label
var _File_Dialog: FileDialog
var _Move_Up_Button: Button
var _Move_Down_Button: Button
var _Entries: Array[Dictionary] = []
var _Visible_Indices: Array[int] = []


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_Build_Ui()
	_Load_Entries()


func _Build_Ui() -> void:
	var Heading := Label.new()
	Heading.text = "编辑器属性翻译文件"
	add_child(Heading)

	var Filter_Row := HBoxContainer.new()
	add_child(Filter_Row)
	var Filter_Label := Label.new()
	Filter_Label.text = "语言筛选"
	Filter_Row.add_child(Filter_Label)
	_Filter_Select = OptionButton.new()
	_Filter_Select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_Filter_Select.add_item("全部语言")
	_Filter_Select.set_item_metadata(0, "")
	_Filter_Select.item_selected.connect(_Refresh_File_List)
	Filter_Row.add_child(_Filter_Select)

	var Locale_Row := HBoxContainer.new()
	add_child(Locale_Row)
	var Language_Label := Label.new()
	Language_Label.text = "语言"
	Locale_Row.add_child(Language_Label)
	_Language_Select = OptionButton.new()
	_Language_Select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_Add_Options(_Language_Select, Language_Options)
	Locale_Row.add_child(_Language_Select)

	var Region_Label := Label.new()
	Region_Label.text = "地区（可选）"
	Locale_Row.add_child(Region_Label)
	_Region_Select = OptionButton.new()
	_Region_Select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_Add_Options(_Region_Select, Region_Options)
	Locale_Row.add_child(_Region_Select)

	var File_Row := HBoxContainer.new()
	add_child(File_Row)
	var File_Label := Label.new()
	File_Label.text = "INI 文件"
	File_Row.add_child(File_Label)
	_Path_Edit = LineEdit.new()
	_Path_Edit.placeholder_text = "选择包含 [Editor.Property.ClassName] 节的 .ini 文件"
	_Path_Edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	File_Row.add_child(_Path_Edit)
	var Browse_Button := Button.new()
	Browse_Button.text = "浏览..."
	Browse_Button.pressed.connect(_Open_File_Dialog)
	File_Row.add_child(Browse_Button)

	var Action_Row := HBoxContainer.new()
	add_child(Action_Row)
	var Add_Button := Button.new()
	Add_Button.text = "添加翻译文件"
	Add_Button.pressed.connect(_Add_Translation_File)
	Action_Row.add_child(Add_Button)
	var Remove_Button := Button.new()
	Remove_Button.text = "移除所选"
	Remove_Button.pressed.connect(_Remove_Selected_File)
	Action_Row.add_child(Remove_Button)
	_Move_Up_Button = Button.new()
	_Move_Up_Button.text = "上移"
	_Move_Up_Button.pressed.connect(_Move_Selected_File.bind(-1))
	Action_Row.add_child(_Move_Up_Button)
	_Move_Down_Button = Button.new()
	_Move_Down_Button.text = "下移"
	_Move_Down_Button.pressed.connect(_Move_Selected_File.bind(1))
	Action_Row.add_child(_Move_Down_Button)

	_File_List = ItemList.new()
	_File_List.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_File_List.item_selected.connect(_Update_Move_Buttons)
	add_child(_File_List)

	_Status_Label = Label.new()
	add_child(_Status_Label)

	_File_Dialog = FileDialog.new()
	_File_Dialog.title = "选择编辑器翻译 INI"
	_File_Dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_File_Dialog.access = FileDialog.ACCESS_RESOURCES
	_File_Dialog.add_filter("*.ini", "INI 翻译文件")
	_File_Dialog.file_selected.connect(_On_File_Selected)
	add_child(_File_Dialog)


func _Add_Options(Option_Button: OptionButton, Options: Array) -> void:
	for Option in Options:
		Option_Button.add_item("%s (%s)" % [Option[1], Option[0]] if Option[0] else Option[1])
		Option_Button.set_item_metadata(Option_Button.item_count - 1, Option[0])
	if not Options.is_empty():
		Option_Button.select(0)


func _Load_Entries() -> void:
	_Entries.clear()
	if not FileAccess.file_exists(INI_Settings_Path):
		if FileAccess.file_exists("res://Translation/Editor.ini"):
			_Entries.append({"locale": "zh", "path": "res://Translation/Editor.ini"})
		_Refresh_Filter_Options()
		_Refresh_File_List()
		return

	var Config := ConfigFile.new()
	var Error := Config.load(INI_Settings_Path)
	if Error != OK:
		_Set_Status("读取设置失败：%s" % error_string(Error), true)
		return

	var Stored_Entries: Variant = Config.get_value("Translations", "Files", [])
	if not Stored_Entries is Array:
		_Set_Status("设置文件中的 Files 必须是数组。", true)
		return

	for Entry in Stored_Entries:
		if Entry is Dictionary and Entry.has("locale") and Entry.has("path"):
			_Entries.append(
				{
					"locale": _Normalize_Locale(str(Entry["locale"])),
					"path": str(Entry["path"]),
				}
			)
	_Refresh_Filter_Options()
	_Refresh_File_List()


func _Open_File_Dialog() -> void:
	_File_Dialog.popup_centered_ratio(0.65)


func _On_File_Selected(Path: String) -> void:
	_Path_Edit.text = Path


func _Add_Translation_File() -> void:
	var Language := str(_Language_Select.get_selected_metadata())
	var Region := str(_Region_Select.get_selected_metadata())
	if Language.is_empty():
		_Set_Status("请选择语言。", true)
		return
	var Locale := Language if Region.is_empty() else "%s-%s" % [Language, Region]

	var Path := _Normalize_Project_Path(_Path_Edit.text.strip_edges())
	if Path.is_empty() or not Path.to_lower().ends_with(".ini"):
		_Set_Status("请选择项目内的 .ini 翻译文件。", true)
		return
	if not FileAccess.file_exists(Path):
		_Set_Status("文件不存在：%s" % Path, true)
		return

	var Config := ConfigFile.new()
	var Error := Config.load(Path)
	if Error != OK:
		_Set_Status("无法读取 INI：%s" % error_string(Error), true)
		return
	if not _Has_Property_Translation_Section(Config):
		_Set_Status("文件必须包含 [Editor.Property.类名称] 格式的节。", true)
		return

	var Replaced := false
	for Index in _Entries.size():
		if _Entries[Index]["path"] == Path:
			_Entries[Index]["locale"] = Locale
			Replaced = true
			break
	if not Replaced:
		_Entries.append({"locale": Locale, "path": Path})

	if not _Save_Entries():
		return
	_Path_Edit.clear()
	_Refresh_Filter_Options()
	_Refresh_File_List()
	_Set_Status("翻译文件已添加。", false)
	Translation_Files_Changed.emit()


func _Has_Property_Translation_Section(Config: ConfigFile) -> bool:
	for Section in Config.get_sections():
		if not Section.begins_with(INI_Translation_Section_Prefix):
			continue
		var Translated_Class_Name := Section.substr(INI_Translation_Section_Prefix.length())
		if not Translated_Class_Name.is_empty() and not Translated_Class_Name.contains("."):
			return true
	return false


func _Remove_Selected_File() -> void:
	var Visible_Selection := _File_List.get_selected_items()
	if Visible_Selection.is_empty():
		_Set_Status("请先选择要移除的文件。", true)
		return

	_Entries.remove_at(_Visible_Indices[Visible_Selection[0]])
	if not _Save_Entries():
		return
	_Refresh_Filter_Options()
	_Refresh_File_List()
	_Set_Status("翻译文件已移除。", false)
	Translation_Files_Changed.emit()


func _Move_Selected_File(Offset: int) -> void:
	var Visible_Selection := _File_List.get_selected_items()
	if Visible_Selection.is_empty():
		return

	var Selected_Index := Visible_Selection[0]
	var Target_Index := Selected_Index + Offset
	if Target_Index < 0 or Target_Index >= _Visible_Indices.size():
		return

	var Source_Entry_Index := _Visible_Indices[Selected_Index]
	var Target_Entry_Index := _Visible_Indices[Target_Index]
	var Entry := _Entries[Source_Entry_Index]
	_Entries[Source_Entry_Index] = _Entries[Target_Entry_Index]
	_Entries[Target_Entry_Index] = Entry

	if not _Save_Entries():
		return
	_Refresh_File_List()
	_File_List.select(Target_Index)
	_Update_Move_Buttons(Target_Index)
	_Set_Status("翻译文件顺序已更新。", false)
	Translation_Files_Changed.emit()


func _Save_Entries() -> bool:
	var Config := ConfigFile.new()
	Config.set_value("Translations", "Files", _Entries)
	var Error := Config.save(INI_Settings_Path)
	if Error != OK:
		_Set_Status("保存设置失败：%s" % error_string(Error), true)
		return false
	return true


func _Refresh_Filter_Options(_Selected_Index: int = -1) -> void:
	var Selected_Locale := _Get_Filter_Locale()
	_Filter_Select.clear()
	_Filter_Select.add_item("全部语言")
	_Filter_Select.set_item_metadata(0, "")
	_Filter_Select.select(0)

	var Locales: Dictionary[String, bool] = {}
	for Entry in _Entries:
		Locales[Entry["locale"]] = true
	var Sorted_Locales := Locales.keys()
	Sorted_Locales.sort()
	for Locale in Sorted_Locales:
		_Filter_Select.add_item(Locale)
		_Filter_Select.set_item_metadata(_Filter_Select.item_count - 1, Locale)
		if Locale == Selected_Locale:
			_Filter_Select.select(_Filter_Select.item_count - 1)


func _Refresh_File_List(_Selected_Index: int = -1) -> void:
	if _File_List == null:
		return

	var Selected_Locale := _Get_Filter_Locale()
	_File_List.clear()
	_Visible_Indices.clear()
	for Index in _Entries.size():
		var Entry := _Entries[Index]
		var Locale: String = Entry["locale"]
		if not Selected_Locale.is_empty() and Locale != Selected_Locale:
			continue

		var Path: String = Entry["path"]
		var Missing_Marker := "" if FileAccess.file_exists(Path) else " [文件不存在]"
		_File_List.add_item("%s  —  %s%s" % [Locale, Path, Missing_Marker])
		_Visible_Indices.append(Index)

	_Update_Move_Buttons(-1)


func _Get_Filter_Locale() -> String:
	if _Filter_Select == null or _Filter_Select.selected < 0:
		return ""
	return str(_Filter_Select.get_selected_metadata())


func _Update_Move_Buttons(Selected_Index: int) -> void:
	if _Move_Up_Button == null or _Move_Down_Button == null:
		return
	var Has_Selection := Selected_Index >= 0 and Selected_Index < _Visible_Indices.size()
	_Move_Up_Button.disabled = not Has_Selection or Selected_Index == 0
	_Move_Down_Button.disabled = not Has_Selection or Selected_Index >= _Visible_Indices.size() - 1


func _Normalize_Project_Path(Path: String) -> String:
	var Project_Path := Path
	if not Project_Path.begins_with("res://"):
		Project_Path = ProjectSettings.localize_path(Project_Path)
	if not Project_Path.begins_with("res://"):
		return ""
	return Project_Path


func _Normalize_Locale(Locale: String) -> String:
	return Locale.strip_edges().replace("_", "-").to_lower()


func _Set_Status(Message: String, Is_Error: bool) -> void:
	_Status_Label.text = Message
	_Status_Label.modulate = Color("#ff7070") if Is_Error else Color("#80d080")
