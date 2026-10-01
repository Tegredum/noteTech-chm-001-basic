# 最小 CHM 编译示例

encoding: utf-8
author: Codex (GPT-6 Astra max)

两篇 HTML 页面、一份样式、目录与索引，通过 HTML Help Workshop 编译为一个离线帮助文件。正文使用 UTF-8 中文；项目标题、目录和索引使用 ASCII 英文，便于先验证基本流程。中文导航和中文全文搜索需要另行测试，不能从正文正常显示推断它们也可用。

## 准备编译器

需要 Windows、PowerShell，以及完整的 HTML Help Workshop（包含 `hhc.exe` 和 `hha.dll`）。获取方法见[创建与使用教程](../../docs/02-chm-authoring-and-usage.md)。

部分设备已安装 Workshop，但 `hhc.exe` 不在 PATH。脚本按以下顺序定位它：`-CompilerPath` 参数 → PATH → `ProgramFiles(x86)` 和 `ProgramFiles` 下的 `HTML Help Workshop` 目录。自定义安装目录需要显式传入；`C:\Program Files (x86)\HTML Help Workshop\hhc.exe` 只是一个常见位置。

## 构建与打开

在仓库根目录运行：

```powershell
.\examples\minimal\build.ps1
& "$env:WINDIR\hh.exe" .\examples\minimal\build\manual.chm
```

也可从本目录运行 `./build.ps1`。脚本根据自己的位置查找源文件，不依赖调用者的工作目录。若需指定编译器，以下参数值应替换成设备上的实际路径：

```powershell
.\examples\minimal\build.ps1 -CompilerPath 'C:\Program Files (x86)\HTML Help Workshop\hhc.exe'
```

产物是 `build/manual.chm`，日志是 `build/compile.log`。再次构建会替换这两个生成文件；构建前请关闭正在查看该 CHM 的窗口。`build/` 已由本目录的 `.gitignore` 排除，文本源文件可直接提交到 Git。

## 不使用脚本时的核心命令

进入 `examples/minimal` 目录，按实际位置设置 `$compiler`：

若设备策略禁止运行 `.ps1`，可在 PowerShell 中逐条执行这些命令，或在 Workshop 中打开 `manual.hhp` 编译，无需修改系统执行策略。直接调用编译器不会检查是否留下了旧产物；应先保留或移走旧 `build/manual.chm`，避免误判。

```powershell
$compiler = 'C:\Program Files (x86)\HTML Help Workshop\hhc.exe'
New-Item -ItemType Directory -Path .\build -Force | Out-Null
& $compiler .\manual.hhp
& "$env:WINDIR\hh.exe" .\build\manual.chm
```

核心操作只有 `hhc.exe manual.hhp`；脚本额外负责查找编译器、保存日志和检查新产物。编译器 `4.74.8702` 在验证环境中成功时返回 `1`，所以脚本结合这个约定、错误诊断和 CHM 文件头判断基本编译结果；脚本自身成功时返回 `0`。这不能替代查看器中的功能验收。

## 文件与修改入口

| 文件 | 作用 | 可尝试的修改 |
| --- | --- | --- |
| `manual.hhp` | 输出名、默认主题、语言、全文搜索、输入清单 | 修改 `Title`，重新编译后看窗口标题 |
| `toc.hhc` | 两条目录项：Home、Installation | 改动英文目录名称或顺序 |
| `index.hhk` | 两个关键词：build、setup | 添加关键词并关联主题 |
| `topics/index.html` | 首页 | 修改一段中文，再构建并打开 |
| `topics/install.html` | 第二篇主题 | 修改说明步骤，验证链接与搜索 |
| `assets/help.css` | 字体、颜色与留白 | 改动标题颜色后重新编译 |
| `build.ps1` | 查找编译器并调用 HHC | 通过参数选择安装位置 |

所有源文件使用 UTF-8；三个帮助项目/导航文件仅含 ASCII 字符，因而也兼容常见 Windows 本地代码页。项目使用英文语言标识 `0x409`，搜索验收使用英文单词。需要制作全中文导航时，按教程的“中文与编码”一节单独设置语言和编码。

## 人工验收

1. 构建命令无脚本错误，`build/manual.chm` 存在，查看器显示 `CHM Minimal Example` 标题。
2. 默认页显示“CHM 编译示例”；中文可读，蓝色标题和浅蓝提示框说明 CSS 已打包。
3. 左侧“目录”中点击 Home 和 Installation，分别打开对应主题；两页正文链接可互相跳转。
4. 在“索引”中选择 `setup`，打开安装说明。
5. 在“搜索”中查询 `installation`，结果包含 Installation，且可以打开。该单词也可能匹配首页正文。
6. 修改 `topics/index.html` 中的一句话，关闭查看器并重新构建；再次打开，确认显示改动后的正文。
7. 在仓库根目录运行 `git status --short --untracked-files=all`，确认待提交文件中没有 `build/manual.chm` 和 `build/compile.log`。

## 验证范围

编译器行为和平台支持以[教程的验证范围](../../docs/02-chm-authoring-and-usage.md#9-验证范围)为准。测试环境中的安装路径和语言配置只是一个验证样本，不是所有 Windows 设备的配置要求。
