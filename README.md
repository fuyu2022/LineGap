# 线隙 · LINE GAP

版本：`0.2.0-beta`。一个由点、线、圆环组成的 Godot 生存游戏。

[在线游玩](https://fuyu2022.github.io/LineGap/)

## 操作

- WASD / 方向键：移动。
- 鼠标左键 / 空格：冲刺；空格也用于开始、重开和继续。
- ESC：暂停 / 继续；切换窗口时自动暂停。
- R：重开。
- 右下角切换中英文和背景音乐，选择自动保存。音乐开关不影响音效；网页版首次点击或按键后启用声音。

## 玩法

躲避白色实线，金色虚线为预警。光球每个加 50 分、增加一条命并清空冲刺冷却，最多三条命；存活每秒加 10 分。受伤后获得 2 秒保护，最后一条命耗尽时结束。

- 一条命：冲刺使障碍暂时虚化，距离 160 像素，冷却 1.5 秒。
- 两条命：冲刺可击碎障碍，冷却减为 0.75 秒。
- 三条命：保留击碎能力，冲刺距离增加到 280 像素。

每收集 7 个光球进入 **7 秒超级冲刺状态**：移动速度为普通状态的 **2.5 倍**，全程无敌、冲刺无冷却，接触障碍即可击碎。冲刺仍需手动按空格或点击鼠标触发，冲刺中可转向。状态条和拖尾变为金色；结束后恢复普通移动速度，再获得 2 秒保护。暂停冻结计时，重开清空本局进度。最高分和最长存活时间自动保存。

## 本地运行与打包

源码用 Godot 4.7.2 打开 `project.godot`，或双击 `play.cmd` 游玩、`editor.cmd` 编辑。打包需安装匹配的导出模板：

```powershell
.\build.ps1      # Windows x64 免安装版
.\build-web.ps1  # Web 版
```

两个脚本可通过 `-GodotPath` 指定引擎路径，压缩包生成到 `builds/`，文件名自动读取版本号。Windows 版解压后运行 `LineGap.exe`，保留同目录的 `LineGap.pck`。

Web 版需发布整个 `builds/LineGap-Web/` 目录，不能直接双击 HTML。本地预览可运行导出目录里的 `preview.cmd`（需要 Python）。测试脚本在 `tests/`，截图和报告在 `artifacts/`。

## GitHub Pages

在 [Pages 设置](https://github.com/fuyu2022/LineGap/settings/pages) 中将 Source 设为 **GitHub Actions**。推送源码到 `main` 后，工作流会自动导出并发布 Web 版；在 [Actions](https://github.com/fuyu2022/LineGap/actions) 查看进度。无需提交 `builds/`，也无需额外配置 Token。

## 署名

背景音乐：[Bumba Crossing](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1500031)，Kevin MacLeod（incompetech.com），[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)。原始音频未修改，游戏内降低音量并循环播放；完整说明见 [音乐署名](assets/music/ATTRIBUTION.txt)。

Web 字体为 Noto Sans SC 的子集，使用 [SIL OFL 1.1](assets/fonts/OFL.txt)。导出包包含音乐、字体和 Godot 引擎的许可信息。
