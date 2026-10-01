# CHM 格式、能力与选型

encoding: utf-8
author: Codex (GPT-5.6 Sol xhigh)

> 调研日期：2026-09-06。本文讨论 Microsoft Compiled HTML Help（`.chm`），不是其他同名缩写。

## 1. 结论先行

CHM 是把 HTML 主题页、图片、目录、索引和全文检索数据编译进一个文件的 Windows 帮助格式。它适合需要随 Windows 桌面软件离线交付、并需要目录、索引、搜索或上下文帮助的既有产品；若目标是跨平台、浏览器优先、移动端或持续演进的新文档站点，通常应优先选择静态站点，并按需另行生成 PDF。

CHM 不是“不能再用”，但应被视为成熟的旧技术：微软资料说明 HTML Help 技术最后版本为 1.4、HTML Help Workshop 最后版本为 1.3，并明确表示没有增加新功能的计划；相关开发资料也位于 Microsoft Learn 的“Previous Versions”区域。[Microsoft HTML Help Downloads](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/microsoft-html-help-downloads)

## 2. CHM 是什么

一个典型项目包含以下部分：

| 文件 | 角色 | 是否适合人工编辑 |
| --- | --- | --- |
| `.hhp` | 项目清单和编译选项，关联其余文件 | 是，文本 |
| `.htm` / `.html` | 每一篇帮助主题 | 是，文本 |
| `.css`、图片等 | 样式与资源 | CSS 是文本；图片通常是二进制 |
| `.hhc` | 分层目录（Table of Contents） | 是，HTML 风格文本 |
| `.hhk` | 关键词索引 | 是，HTML 风格文本 |
| `.chm` | 编译后的压缩交付物 | 否，二进制容器 |

微软将 `.hhp` 定义为汇集主题、图片、目录和索引的文本项目文件，完成后由编译器生成单一 `.chm` 文件。[Create a Help Project](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/create-a-help-project) 编译器属于 HTML Help Workshop，也能从命令行调用。[About the HTML Help Compiler](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/about-the-html-help-compiler)

最终用户看到的通常是三栏式帮助查看器：左侧可含目录、索引、搜索和收藏夹，右侧显示主题。Windows 的 `hh.exe` 负责启动查看器；应用还可经 HTML Help API 打开指定主题、关键词或上下文 ID。[The HTML Help Components](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/the-html-help-components) [HTML Help API Overview](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/html-help-api-overview)

## 3. 优势与限制

### 3.1 优势

- 单文件、压缩、离线，适合随 Windows 安装包分发。
- 原生具备目录、关键词索引和全文搜索，不需要运行本地 Web 服务器。
- 可从桌面程序按主题路径、关键词或上下文 ID 调起，适合 F1 帮助。
- 编译前主体是 HTML/CSS/图片，内容可由文本工具或上游文档生成器产生。

### 3.2 限制与风险

- Windows 中心化。其他平台通常需要第三方查看器，显示和集成行为不能假设与 Windows 一致。
- 查看器架构源于旧式 HTML Help/Internet Explorer 组件；应采用保守的 HTML/CSS，不能把现代浏览器中的效果直接视为 CHM 中也受支持。微软对帮助窗口的说明明确提到其承载 `Shdocvw.dll`。[Window Types](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/window-types)
- 从互联网下载的 CHM 可能带有区域标记，表现为主题空白或“导航已取消”。只应在确认来源可信后，通过文件“属性 → 解除锁定”处理；不要把放宽整个系统安全区域的注册表修改作为普通解决方案。[Microsoft：Some .CHM files may not render properly](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/dot-chm-file-not-render-properly)
- CHM 可承载脚本、ActiveX/快捷命令等旧式主动内容能力。未知来源文件应视为不可信；只查看内容时可考虑 `hh.exe -safe`，该开关会禁用快捷命令。[Using Command Line Switches](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/using-command-line-switches)
- `.chm` 是二进制编译产物，Git 能保存，但无法像文本那样有效审查和自动合并。详细策略见《CHM 与 Git 协作》。

## 4. 选型判断

| 主要需求 | 建议 | 理由 |
| --- | --- | --- |
| 既有 Windows 桌面程序、离线、F1/上下文帮助 | 采用或继续采用 CHM | 与 Windows HTML Help API 和查看器直接配合 |
| 新建 Windows-only 工具，要求一个离线文件 | 有条件采用 | 先验证旧渲染器、中文编码、构建工具获取与安全策略 |
| Web、macOS、Linux、移动端也要使用 | 不以 CHM 为主格式 | CHM 的查看与集成以 Windows 为中心 |
| 频繁协作、在线发布、全文可检索 | 静态文档站点优先 | 现代浏览器兼容、部署和评审更直接 |
| 打印、审批或长期版式归档 | PDF 优先 | 分页和版式更可控 |
| 同时需要网站、PDF 和 CHM | 单一文本源、多目标生成 | 避免分别维护三套内容；CHM 只是发布目标之一 |

## 5. 推荐架构

最稳妥的思路是“源文件优先，CHM 是构建产物”：

```text
可审查的源文件（Markdown 或 HTML）
              │
              ├──> 现代静态站点 / PDF（可选）
              │
              └──> CHM 中间源（HTML、HHP、HHC、HHK）
                               │
                               └──> hhc.exe ──> manual.chm
```

如果只维护 CHM，仍应保存 `.hhp`、`.hhc`、`.hhk`、HTML、CSS 和图片，而不是把 `.chm` 当作唯一源文件。微软提供反编译能力来取回容器内文件，但它更适合检查或应急恢复，不等价于保存原始写作源、生成配置和构建环境。[Decompiling a Help File](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/htmlhelp/decompiling-a-help-file)

## 6. 本文结论的边界

- “适合新项目与否”是基于微软停止增加功能、旧渲染架构和平台范围作出的工程判断，不是微软发布的弃用声明。
- 查看器是否存在、企业策略是否允许打开 CHM，应在每个目标 Windows 版本和受管环境中实测。
- 编译器安装来源、许可和可再分发条件应由项目在采用前单独核实；不要从未知镜像下载旧安装程序。
