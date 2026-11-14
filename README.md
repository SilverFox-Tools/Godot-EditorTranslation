# **Godot 编辑器翻译**<br>**Godot Editor Translation**

Godot 编辑器插件，用 INI 翻译文件翻译检查器中的 **GDScript 属性标签**。<br>
A Godot editor plugin that uses INI translation files to translate **GDScript property labels** in the Inspector.

> **支持版本 : Godot 4.6.1**<br>
> **Supported Version : Godot 4.6.1**

> **分支说明 :** **main** 分支以 **Godot 4.6.1** 为开发基准。<br>
> **Branch Description :** The **main** branch targets **Godot 4.6.1**.

## **功能**<br>**Features**

- 根据当前 Godot 编辑器语言显示相应翻译，并支持语言及地区代码。<br>
	Loads translations for the current Godot editor language, including language and region codes.

- 翻译附加了 GDScript 的对象在检查器中显示的属性标签，并支持脚本继承。<br>
	Translates Inspector property labels for objects with attached GDScript, including inherited scripts.

- 可在编辑器底部面板添加、移除、筛选和排序 INI 翻译文件。<br>
	Add, remove, filter, and reorder INI translation files in the editor's bottom panel.

- 翻译文件或设置发生变化时自动重新载入；切换编辑器语言时也会更新。<br>
	Reloads translations when translation files or settings change, and updates when the editor language changes.

## **安装**<br>**Installation**

**步骤一 :** 将插件文件夹复制到 Godot 项目的 `res://addons/Editor-Translation/` 目录。<br>
**Step 1 :** Copy the plugin folder into the Godot project's `res://addons/Editor-Translation/` directory.

**步骤二 :** 在 Godot 中打开 `项目` > `项目设置` > `插件`。<br>
**Step 2 :** In Godot, open `Project` > `Project Settings` > `Plugins`.

**步骤三 :** 启用 `Editor Translation` 插件。<br>
**Step 3 :** Enable the `Editor Translation` plugin.

## **翻译文件**<br>**Translation Files**

每个 INI 文件使用 `[Editor.Property.脚本类名]` 节；脚本类名是 GDScript 文件名（不含扩展名），键名是属性名，值是检查器中显示的翻译。<br>
Each INI file uses an `[Editor.Property.ScriptName]` section. The script name is the GDScript filename without its extension; keys are property names and values are the translated Inspector labels.

```ini
[Editor.Property.Player]
health = "生命值"
move_speed = "移动速度"
```

可在项目中打开底部的 `编辑器翻译` 面板，选择语言及可选地区，再浏览并添加 INI 文件。设置会保存到 `res://Translation/Editor-Translation-Settings.ini`。<br>
Open the `编辑器翻译` bottom panel, choose a language and optional region, then browse for and add an INI file. Settings are saved to `res://Translation/Editor-Translation-Settings.ini`.

未创建设置文件时，如果项目中存在 `res://Translation/Editor.ini`，插件会将其作为中文翻译文件载入。<br>
If no settings file exists and `res://Translation/Editor.ini` is present, the plugin loads it as the Chinese translation file.

## **使用**<br>**Usage**

启用插件后，在 Godot 编辑器底部打开 `编辑器翻译` 面板，添加包含有效翻译节的 `.ini` 文件。<br>
After enabling the plugin, open the `编辑器翻译` panel at the bottom of the Godot editor and add `.ini` files containing valid translation sections.

将编辑器语言设置为翻译文件对应的语言，然后在检查器中查看带有 GDScript 的对象；匹配的属性标签会自动翻译。<br>
Set the editor language to match a translation file, then inspect an object with an attached GDScript; matching property labels are translated automatically.

翻译按脚本文件名和属性名匹配。区域语言（例如 `zh-cn`）会先使用对应地区的翻译，并回退到基础语言（例如 `zh`）。<br>
Translations are matched by script filename and property name. A regional locale (for example, `zh-cn`) uses its specific translations first and falls back to the base language (for example, `zh`).

> **⚠ ⚠ ⚠**<br>
> **本项目在开发过程中大量使用了 AI 代码生成技术。虽然已由作者进行测试，但仍建议在生产环境中先进行充分验证。**<br>
> **This project was developed with extensive use of AI code generation. Although tested by the author, thorough validation in a production environment is recommended.**<br>
> **⚠ ⚠ ⚠**
