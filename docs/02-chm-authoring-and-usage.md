# CHM 创建、测试与使用

encoding: utf-8
author: Codex (GPT-5.6 Sol xhigh, GPT-6 Astra max)

本文介绍 Microsoft HTML Help Workshop 工具链，并提供可在仓库中直接构建的[最小示例](../examples/minimal/README.md)。路径与命令以 Windows / PowerShell 为例；示例配置、实测环境和未验证功能分别说明，不代表所有设备都具有相同配置。

## 1. 工具链

### 1.1 编译器、安装包与查看器

- `hhc.exe` / `hha.dll`：HTML Help Workshop 的编译工具；将项目、目录、索引、HTML 和资源编译为 `.chm`。
- `htmlhelp.exe`：Workshop 安装包，安装后才会得到编译工具和编辑器。
- `hh.exe`：Windows HTML Help 查看器；可打开或反编译 CHM，但不能把源文件编译成 CHM。

不要把安装包改名为 `hhc.exe`，也不要只复制编译器而遗漏依赖库。已有完整 Workshop 安装时，可直接使用，无需重复下载安装包。

### 1.2 查找已有的编译器：PATH 不是全部

有些设备安装了 Workshop，却没有将它加入 PATH。以下命令没有输出，只能说明 PATH 中未找到编译器，不能说明设备上没有安装：

```powershell
Get-Command hhc.exe -CommandType Application -ErrorAction SilentlyContinue
```

还可以检查常见安装目录：

```powershell
$programDirectories = @(${env:ProgramFiles(x86)}, $env:ProgramFiles)
foreach ($directory in $programDirectories) {
    if ($directory) {
        $candidate = Join-Path $directory 'HTML Help Workshop\hhc.exe'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            Get-Item -LiteralPath $candidate
        }
    }
}
```

常见位置包括 `C:\Program Files (x86)\HTML Help Workshop\hhc.exe` 和 `C:\Program Files\HTML Help Workshop\hhc.exe`。它们不是强制安装位置，也不能保证每台设备都存在。自定义安装时，应检查实际安装目录或 Workshop 快捷方式的目标，并确认同目录中有 `hha.dll`。

本教程的测试设备在第一个位置找到了编译器，且该位置不在 PATH；这只是一个实测例子。使用完整路径即可调用，无需为了编译而修改系统 PATH。仓库的 `build.ps1` 会按“显式参数 → PATH → 常见安装目录”的顺序查找；自定义位置通过 `-CompilerPath` 指定。

### 1.3 获取 HTML Help Workshop

可以从帮助文档工具厂商提供的 Workshop 下载入口取得安装包。下列渠道属于第三方托管，不能称为微软官方下载；应优先进入来源页确认说明，再下载文件。

| 渠道 | 来源页 | 安装包 |
| --- | --- | --- |
| Help+Manual | [Microsoft Help Compiler 下载入口](https://www.helpandmanual.com/downloads.html) | [htmlhelp.exe](https://www.helpandmanual.com/download/htmlhelp.exe) |
| HelpNDoc | [Workshop 安装指南](https://www.helpndoc.com/step-by-step-guides/how-to-download-and-install-microsofts-html-help-workshop-compiler/) | [htmlhelp.exe](https://www.helpndoc.com/downloads/htmlhelp.exe) |
| HelpSmith | [HTML Help Workshop 下载入口](https://www.helpsmith.com/download.php) | [htmlhelp.exe](https://www.helpsmith.com/download/htmlhelp.exe) |

下载可达性会随时间和网络环境变化。测试环境仅完整下载并校验了 Help+Manual 的安装包，未执行安装；其他两个渠道未完成文件级校验，不能据此保证所有下载均可用。

运行下载的程序之前，应检查来源、数字签名和文件哈希：

```powershell
Get-AuthenticodeSignature -LiteralPath '.\htmlhelp.exe' |
    Select-Object Status, @{Name='Signer';Expression={$_.SignerCertificate.Subject}}
Get-FileHash -Algorithm SHA256 -LiteralPath '.\htmlhelp.exe'
```

测试取得的安装包签名状态为 `Valid`，签名者为 Microsoft Corporation。哈希应与可信发布记录或团队保存的已验证副本比对；计算出一个哈希本身并不能证明文件可信。来源不明或签名异常时，不应直接运行。

确认可信后，按向导安装 Workshop，并检查 `hhc.exe`、`hha.dll` 的实际位置。安装过程可能提示已有更新版本的 HTML Help；这个提示可能针对 Windows 查看器运行时，应以编译工具是否存在及样例能否编译判断安装结果。[Help+Manual 安装说明](https://www.helpandmanual.com/downloads.html)

### 1.4 替代方案

| 需求 | 路线 | 边界 |
| --- | --- | --- |
| 必须生成 CHM，但不使用微软编译器 | Free Pascal 的 `chmcmd` | 独立读取 HHP 并写出 CHM；未在本项目中运行验证，见第 4.3 节 |
| 希望使用可视化写作界面 | HelpNDoc、HelpSmith 等作者工具 | 这两者的 CHM 输出仍依赖 Workshop，换编辑器不等于替换编译器 |
| 只需要离线阅读，不要求 CHM 或 Windows F1 接口 | HTML 文件夹/ZIP、静态站点或 PDF | 可避开 CHM 编译链，但交付能力不同 |

上述依赖关系见 [FPC CHM 包构建定义](https://gitlab.com/freepascal.org/fpc/source/-/raw/release_3_2_2/packages/chm/fpmake.pp)、[HelpNDoc 系统要求](https://www.helpndoc.com/download/)和 [HelpSmith 编译器说明](https://www.helpsmith.com/webhelp/topics/help-compiler.htm)。

## 2. 最小项目结构

仓库中的 `examples/minimal/` 已提供完整源文件，无需从文档逐段复制：

```text
examples/minimal/
├─ README.md
├─ build.ps1
├─ .gitignore
├─ .gitattributes
├─ manual.hhp
├─ toc.hhc
├─ index.hhk
├─ topics/
│  ├─ index.html
│  └─ install.html
├─ assets/
│  └─ help.css
└─ build/               # 构建时生成，不提交 Git
```

建议源文件使用简短的 ASCII 名称和相对路径，以降低旧工具与不同系统代码页之间的兼容风险。

### 2.1 项目文件 `manual.hhp`

```ini
[OPTIONS]
Compatibility=1.1 or later
Compiled file=build\manual.chm
Contents file=toc.hhc
Index file=index.hhk
Default topic=topics/index.html
Display compile progress=Yes
Full-text search=Yes
Language=0x409 English (United States)
Title=CHM Minimal Example

[FILES]
topics\index.html
topics\install.html
assets\help.css
```

`[OPTIONS]` 定义输出、默认主题、目录、索引、搜索和项目语言；`[FILES]` 列出正文与资源。输出路径相对于项目目录。具体选项见 [Editing Project Options](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/editing-project-options)。

示例有意使用英文项目标题和导航，以便先理解基本流程；`0x409` 是英文（美国）的 Windows LANGID。简体中文（中国）使用 `0x804`，但改变语言值并不自动转换源文件编码。[Microsoft language identifier table](https://learn.microsoft.com/en-us/windows/win32/msi/localizing-the-error-and-actiontext-tables)

### 2.2 目录与索引

[toc.hhc](../examples/minimal/toc.hhc) 定义 Home、Installation 两个目录入口；[index.hhk](../examples/minimal/index.hhk) 定义 build、setup 两个索引关键词。条目的基本形式是：

```html
<li><object type="text/sitemap">
  <param name="Name" value="Installation">
  <param name="Local" value="topics/install.html">
</object></li>
```

`Name` 是显示文字，`Local` 是 CHM 内部相对路径，不是编译机绝对路径。目录可通过嵌套 `<ul>` 形成层级。索引是人工组织的关键词入口，和全文搜索不是同一个功能。

### 2.3 正文与样式

[首页](../examples/minimal/topics/index.html)和[安装说明](../examples/minimal/topics/install.html)是普通 HTML 页面，通过相对链接互相跳转；[help.css](../examples/minimal/assets/help.css)负责字体、颜色和留白。两个页面均以 UTF-8 保存，并显式声明：

```html
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" href="../assets/help.css">
```

图片等资源也通过 HTML 引用并打包。正文相对 URL 使用正斜杠；项目文件中的文件系统路径使用 Windows 反斜杠。[Create HTML Topic Files](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/create-html-topic-files)

## 3. 中文与编码

正文、项目设置、目录/索引和全文搜索可能通过不同机制处理字符。正文显示正常，不能证明中文导航、标题或搜索也正常。

本示例的编码边界是：

- HTML 正文采用 UTF-8 中文，并声明字符集。
- `.hhp/.hhc/.hhk` 只含 ASCII 字符，项目语言为英文；索引和搜索使用英文关键词。
- 所有源文件可按 UTF-8 文本审查；`.gitattributes` 为三个项目/导航文件声明 CRLF，不负责转换中文编码。

制作全中文导航时，应单独验证：

1. 设置匹配的项目 `Language`，检查标题、目录、索引、正文和搜索结果。
2. 简体中文 `.hhp/.hhc/.hhk` 可将 Windows code page 936 / GBK 作为兼容性测试起点；这是待验证的选择，不是适用于所有工具的统一要求。
3. 若选择让所有文件都使用 UTF-8，应在目标 Windows、编译器和查看器上证明中文目录、索引与搜索通过测试。
4. 确定策略后，再用编辑器配置、Git 属性和构建检查固定编码与换行；Git 配置详见[协作方案](03-chm-git-workflow.md)。

HelpSmith 说明查看器导航窗口存在非 Unicode 限制，语言和字符集会影响显示。[HTML Help: General Options](https://www.helpsmith.com/webhelp/topics/html-help-project-options.htm) HTML Help API 具有 ANSI/Unicode 入口，也不能由此推导旧编译器支持所有作者源文件编码。[HTML Help API Overview](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/html-help-api-overview)

## 4. 编译

### 4.1 图形界面

用 HTML Help Workshop 打开 `examples/minimal/manual.hhp`，检查主题、目录、索引、默认主题和全文搜索设置，然后执行 Compile。由于输出设为 `build/manual.chm`，编译前需先在项目旁创建 `build` 目录。编译后仍需在查看器中测试结果。[Create a Help Project](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/create-a-help-project)

### 4.2 PowerShell

在仓库根目录执行：

```powershell
.\examples\minimal\build.ps1
& "$env:WINDIR\hh.exe" .\examples\minimal\build\manual.chm
```

脚本自动查找编译器，不要求它已在 PATH 中。自定义安装位置可手动指定；下列路径只是示例，应替换成设备上的实际位置：

```powershell
.\examples\minimal\build.ps1 -CompilerPath 'C:\Program Files (x86)\HTML Help Workshop\hhc.exe'
```

[build.ps1](../examples/minimal/build.ps1)以自身目录为基准，输出 `build/manual.chm` 和 `build/compile.log`。它只替换该示例的生成物，不改源文件或系统设置；再次编译前请关闭正在查看输出文件的窗口。

若设备策略禁止运行 PowerShell 脚本，可以在 PowerShell 中逐条运行以下命令，或使用 Workshop 界面；无需为此修改系统执行策略。以下命令从仓库根目录开始：

```powershell
Set-Location .\examples\minimal
$compiler = 'C:\Program Files (x86)\HTML Help Workshop\hhc.exe' # 改为实际位置
New-Item -ItemType Directory -Path .\build -Force | Out-Null
& $compiler .\manual.hhp
$LASTEXITCODE
& "$env:WINDIR\hh.exe" .\build\manual.chm
```

核心调用形式是 `hhc <project-file>`。[微软命令行说明](https://learn.microsoft.com/de-at/previous-versions/windows/desktop/htmlhelp/to-compile-a-help-project-from-the-dos-prompt) 上面的直接调用不检查旧产物，应先保留或移走旧 `manual.chm`，避免把编译失败后留下的旧文件当成新结果。

HHC `4.74.8702` 在验证环境中成功时返回 `1`，不能机械地按“非零就是失败”判断。示例脚本按这个约定检查退出码，同时检查错误诊断、新产物和 `ITSF` 文件头；脚本自身成功时返回 `0`。这只是基本构建检查，不代表所有功能都已验收。换用其他编译器版本时，需重新确认退出码和诊断行为。

旧编译器输出中的非 ASCII 路径还可能受终端代码页影响；日志路径文字乱码时，应同时核对实际产物路径。若遇到路径相关故障，可在简短的 ASCII 路径下检出项目对照测试，不应直接据此认定所有中文目录都不受支持。

### 4.3 Free Pascal `chmcmd`

`chmcmd` 使用 Free Pascal 的 CHM 写入库，能读取 `.hhp` 并生成 CHM，不依赖 `hhc.exe` 或 `hha.dll`。以下以 FPC 3.2.2 为例，参数依据[该版本官方源码](https://gitlab.com/freepascal.org/fpc/source/-/raw/release_3_2_2/packages/chm/src/chmcmd.lpr)。

从 [Free Pascal Windows 下载入口](https://www.freepascal.org/down/i386/win32.html)选择官方列出的镜像；[3.2.2 发布目录](https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/)提供完整的 `fpc-3.2.2.i386-win32.exe`。仅名称含 `cross` 的交叉编译附加包不能独立使用。[Windows 包说明](https://www.freepascal.org/down/i386/win32-hungary.html)

安装后在实际安装目录查找 `chmcmd.exe`；下面的 `C:\FPC\3.2.2` 仅为路径示例：

```powershell
Get-ChildItem -LiteralPath 'C:\FPC\3.2.2' -Filter chmcmd.exe -File -Recurse
$chmcmd = 'C:\FPC\3.2.2\bin\i386-win32\chmcmd.exe' # 改为查找到的位置
& $chmcmd --help
```

进入 `examples/minimal`，先保留或移走已有 CHM，再编译：

```powershell
New-Item -ItemType Directory -Path .\build -Force | Out-Null
& $chmcmd --verbosity 3 .\manual.hhp
Get-Item -LiteralPath '.\build\manual.chm' | Select-Object FullName, Length
& "$env:WINDIR\hh.exe" .\build\manual.chm
```

这是有官方源码依据、但未在本项目中运行验证的候选路线，不能视作已验证的等价替换。必须另行测试目录、索引、全文搜索、中文和上下文帮助。

## 5. 打开与定位主题

用户可双击 CHM，或在仓库根目录运行：

```powershell
& "$env:WINDIR\hh.exe" .\examples\minimal\build\manual.chm
```

查看器支持 `-safe` 安全模式，但它不能把未知来源的文件变成完全可信的文件：

```powershell
& "$env:WINDIR\hh.exe" -safe .\examples\minimal\build\manual.chm
```

应用定位主题时使用 `Helpfile.chm::/Topic.htm` 形式；CHM 保留主题的目录层次。[About HTML Help URLs](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/about-html-help-urls) Win32 应用也可调用 HTML Help API：

```cpp
HtmlHelpW(hwnd,
          L"manual.chm::/topics/install.html",
          HH_DISPLAY_TOPIC,
          0);
```

调用者需在应用工程中配置相关头文件、链接依赖和 CHM 路径；这里仅展示定位主题的形式。[HH_DISPLAY_TOPIC command](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/hh-display-topic-command)

## 6. 下载、网络位置与安全

下载后的 CHM 若出现左侧导航可见、正文空白，可按以下顺序排查：

1. 保存到本地磁盘，不从压缩包内部或网络共享直接运行。
2. 核验发布者、签名或可信发布记录中的哈希。
3. 确认来源可信后，若文件属性中有“解除锁定”，再按“属性 → 常规 → 解除锁定 → 确定”操作。
4. 重新打开，检查链接、图片和搜索；仍异常时再排查打包、编码和终端策略。

Windows Attachment Manager 的区域标记可能阻止 CHM 正常渲染。[微软故障排查说明](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/dot-chm-file-not-render-properly) 不建议为了单个文件修改 `ItssRestrictions` 等系统范围注册表设置。

## 7. 反编译仅用于检查或恢复

在仓库根目录执行，提取结果仍放在被 Git 忽略的示例构建目录中：

```powershell
New-Item -ItemType Directory -Path .\examples\minimal\build\extracted -Force | Out-Null
& "$env:WINDIR\hh.exe" -decompile .\examples\minimal\build\extracted .\examples\minimal\build\manual.chm
```

`-decompile <folder> <chm>` 复制容器内容，不删除原 CHM。[Decompiling a Help File](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/decompiling-a-help-file) 它适合检查资源、排查遗漏或紧急恢复，不能取代版本库中的写作源、项目设置和构建脚本。

## 8. 验证范围

下表是一个测试环境的结果，不是跨设备兼容性保证。

| 项目 | 已确认的范围与限制 |
| --- | --- |
| 环境 | Windows build 26200.9457；系统区域 zh-CN；构建脚本在 PowerShell 7.6.5 下运行。Windows PowerShell 5.1 的脚本调用被设备执行策略阻止，未完成该宿主的脚本运行验证 |
| 编译器 | Workshop 默认 x86 安装目录中的 `hhc.exe` 和 `hha.dll`，文件版本均为 `4.74.8702`，微软签名状态为 `Valid`；不在 PATH 时仍能由脚本找到 |
| 示例构建 | 自动查找、显式编译器路径、从其他工作目录调用和重复构建均通过；无效编译器路径被拒绝且未改动已有产物。CHM 约 12 KB，日志报告 2 个主题、6 个本地链接，文件头为 `ITSF`；文件大小不作为构建断言 |
| 内容打包 | 7-Zip 容器完整性检查通过；提取后的两页 HTML、CSS、目录和索引与输入文件逐字节一致。这只能证明打包内容完整，不能证明查看器显示或搜索行为正确 |
| 功能边界 | 查看器中的正文呈现、目录、索引和全文搜索尚未完成人工验收；全中文导航、中文搜索、其他系统区域和编译器版本也未验证 |
| 其他工具 | 未安装运行下载的 Workshop 安装包，也未安装运行 `chmcmd`；下载途径和候选编译路线不等同于安装与功能验证 |
