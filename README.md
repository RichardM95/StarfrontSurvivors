# 星际前线：孤军生还（Starfront Survivors）

俯视角生存肉鸽离线原型，Godot 4.6.3 / GDScript 实现，目标平台为 Android（ARM64）与桌面调试。当前版本 **0.5.0**，为按系统设计稿 v5 重构的验证切片：包含 3 个职业、6 把武器（含 Lv3 A/B 分支）、4 项支援、8 项科技、12 件道具，以及第一幕 4 波、压力房与独立 W12 首领试场。

星际科幻同人方向；角色、美术与音效均为原创或程序生成，不使用商业原作素材，不联网、不商业发行。

## 快速开始

需要 Godot 4.6.3（standard 版）。

```sh
# Linux / macOS / Git Bash：通过脚本启动
./run.sh

# 或直接使用 Godot
godot --path .
```

Windows PowerShell：

```powershell
godot --path "e:\Program Files (x86)\StarfrontSurvivors"
```

入口场景为 [main.tscn](main.tscn)，主逻辑位于 [main_v5.gd](scripts/main_v5.gd)。

## 操作

- 手机：左侧浮动摇杆移动，右侧按钮冲刺与职业技能；技能按住预览、松手施放，拖入取消区取消；点击敌人设置/取消集火。
- 桌面：WASD/方向键移动，空格冲刺，E 施放职业技能，Esc 暂停。

## 测试

测试为 headless 脚本，需设置独立的 `XDG_*` 目录避免污染本机存档：

```sh
./run-v5-tests.sh
```

等价的核心单测命令：

```sh
godot --headless --path . --script res://tests/model_v5_test.gd
godot --headless --path . --script res://tests/save_v5_test.gd
godot --headless --path . --script res://tests/combat_v5_test.gd
godot --headless --path . --script res://tests/ui_v5_test.gd
godot --headless --path . --script res://tests/integration_v5_test.gd
godot --headless --path . --script res://tests/ui_persistence_v5_test.gd
```

日志输出到 `test-results/v5/`。`tests/` 下的 v2/v4 测试针对旧规则，不代表当前版本结论。

## 导出与打包

- 导出预设见 [export_presets.cfg](export_presets.cfg)：Linux x86_64 与 Android ARM64，产物写入 `exports/`（已被忽略）。
- Android 包名 `org.starfront.survivors`，versionCode 6。
- [package-v5.sh](package-v5.sh) 与 [repack-v5-resources.py](repack-v5-resources.py) 为受限云端环境下的封包恢复工具，需已有成功导出的 Android 外壳；正常环境直接用 Godot 编辑器导出即可。

## 目录结构

```
assets/          字体、图标、UI 肖像资源
design/          系统设计稿与 UI 设计稿（v5）
docs/            版本说明与 QA/验收记录
scripts/         游戏逻辑（main_v5 / build_v5 / combat_v5 / save_v5 / data_v5 等）
tests/           headless 测试与预览脚本
test-results/    历史测试日志、截图与封包证据
```

## 文档

- [v0.5.0 验证切片说明](docs/README_V5_CN.md)
- [v0.4.1 UI 验收记录](docs/QA_UI41.md)
- [系统设计稿 v5](design/系统设计稿v5.md)
- [UI 设计稿 v5](design/UI设计稿v5.md)

## 已知限制

- 仅为验证切片，不是完整十二波战役；平衡性未通过验收（首领击杀用时低于 60–90 秒设计目标）。
- 未在实体 Android 设备完成安装、连续握持、系统杀进程与热负载验收。
- 人物/装备美术仍含共用矢量轮廓与占位图标，无配音。
