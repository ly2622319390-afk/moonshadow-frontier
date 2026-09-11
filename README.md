# 月影边境

《月影边境》是一款使用 Godot 4.7 和 GDScript 制作的 2D 俯视角中世纪奇幻生活模拟游戏。玩家来到被遗弃的月影边境，经营农场，在农场、小镇、森林、河流和矿洞之间探索，并逐步调查长夜灾变与女巫石碑的秘密。

本仓库保存当前可运行的垂直切片和开发中的占位美术。游戏使用原创角色、地图、素材和剧情，不包含《星露谷物语》的原始资源或代码。

## 运行环境

- Godot 4.7.2 stable
- Windows 10/11（其他平台可在 Godot 中自行导出）
- 渲染器：Compatibility / GLES3

打开 Godot Project Manager，点击“导入”，选择本目录下的 `project.godot`，然后运行项目。主场景为 `res://scenes/regions/Farm.tscn`。

## 操作

| 操作 | 按键 |
| --- | --- |
| 移动 | WASD / 方向键 |
| 交互与使用工具 | E / 鼠标左键（按当前提示） |
| 选择快捷栏 | 数字键 1–8 / 鼠标点击 |
| 打开背包 | Tab 或 I |
| 关闭面板 | Esc |

## 项目结构

```text
assets/       图片、精灵表、UI 和地图占位素材
resources/    Godot Resource 数据配置（物品、作物、NPC、工具等）
scenes/       可复用场景和区域场景
scripts/
  core/       全局单例与系统服务：时间、存档、世界、物品、任务、商店
  player/     玩家输入、移动、朝向和工具使用
  world/      区域、出口、农田、资源点、建筑门和 NPC 控制
  ui/         HUD、背包、快捷栏、交互提示和钓鱼界面
tests/        阶段审计与回归检查脚本
outputs/      本地导出或检查产物（不作为运行时资源）
work/         本地临时处理文件，不提交到仓库
```

## 场景组织

- `scenes/regions/`：Farm、Town、Forest、River、Mine 等区域，以及室内场景。
- `scenes/player/`：玩家场景和碰撞体。
- `scenes/ui/`：正式 HUD、背包、快捷栏和交互提示。
- `scenes/world/`：资源点、农田、出口、建筑入口等可复用节点。

区域场景负责地图布局和节点实例化；系统逻辑由脚本和 Autoload 管理，避免把游戏规则写死在单个地图场景中。

## 核心系统关系

`WorldManager` 负责当前区域和场景切换；`TimeManager` 推进日期、时间和昼夜；`SaveManager` 保存与读取世界状态；`ItemCatalog`、`CropCatalog`、`NPCatalog` 提供数据配置；玩家控制器调用工具、农田、资源点和交互节点；HUD 只读取系统状态并显示反馈。

新增物品、作物或 NPC 时，优先在 `resources/data/` 添加或修改 `.tres` 数据，再由对应系统读取，保持数值与行为分离。

## 调试与测试

正式 HUD 默认隐藏调试面板。阶段审计脚本位于 `tests/`，可使用 Godot 4.7.2 的无头模式运行。例如：

```powershell
& "C:\\Users\\26223\\AppData\\Local\\Microsoft\\WinGet\\Packages\\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\\Godot_v4.7.2-stable_win64_console.exe" `
  --headless --path "." --script "res://tests/audit_stage6_11.gd"
```

`.godot/`、导入缓存、临时备份和 `work/` 文件夹不会提交。最终美术替换时，将图片放入对应 `assets/` 子目录，并在场景或数据资源中替换纹理引用即可。

## 开发约定

1. 使用 Godot 4 和 GDScript。
2. 保持区域、系统、数据和 UI 分层。
3. 不修改存档结构、核心玩法数值或 NPC 日程，除非任务明确要求。
4. 占位素材统一放在 `assets/`，不把临时生成文件混入正式资源目录。
5. 每次修改后运行项目和相关审计脚本，并在提交信息中说明变更范围。
