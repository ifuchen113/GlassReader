# GlassReader Architecture

## Overview

GlassReader 采用单应用 Target、按职责分层的结构。此次整理保留了原有类型名称和实现，只把原先集中在 `main.swift` 的声明移动到可以表达职责的目录与文件中。

```text
GlassReaderApp
    ↓
App composition / ContentView
    ↓
Features (Library, Reader, Tabs, Import, FullScreen, Settings)
    ↓
Core services/readers + Shared models/components
```

所有代码当前仍属于同一个 `GlassReader` 模块，目录不是独立 framework。这样可以先获得清晰结构，同时避免引入跨模块访问控制、依赖注入和构建复杂度。

## App

- `GlassReaderApp.swift`：SwiftUI App 入口、WindowGroup、菜单命令和全局 `ReaderLibrary` 生命周期。
- `ContentView.swift`：应用根布局、侧边栏/阅读器组合、拖放、键盘监听及顶层覆盖层。

App 层负责组合，不实现文件解析或页面渲染算法。

## Features

### Library

收藏、历史记录、侧边栏模式与相关 SwiftUI 组件。数据读写实现目前在 Core/Persistence 的 `ReaderLibrary` 扩展中，以保持原有状态对象和序列化格式。

### Reader

阅读器状态、翻页、单双页、方向、缩放、缩略图、页码条、手势桥接和页面布局。`ReaderLibrary.swift` 只保留可观察状态与派生状态；导航操作位于 `ReaderLibrary+Navigation.swift`。

### Tabs

`ReaderTab`/`PersistedReaderTab` 模型、多标签页切换与恢复逻辑，以及 `TabBarView`。

### Import

打开面板、拖放、异步加载协调与归档密码提示。底层文件、PDF、图片和归档读取仍由 Core 提供。

### FullScreen

标准全屏、专注/沉浸模式、窗口快照与过渡状态。

### Settings

现有侧边栏设置控件。当前没有单独的 Settings window，因而未凭空增加一个页面。

## Core

### Readers

- `ReaderLibrary+Loading.swift`：保持现有文件类型分派、目录遍历、PDF 页面发现、归档解压命令与嵌套归档流程。
- `ImageFileLoader.swift`：图片/PDF 页面降采样、渲染与内存缓存。
- `PageLoader+Metadata.swift`：页面尺寸和宽高比元数据。
- `ReaderError.swift`：加载错误模型与本地化描述。

底层读取代码不依赖具体 SwiftUI 页面。

### Persistence

`ReaderLibrary+Persistence.swift` 保存收藏、历史、阅读进度与阅读布局。为了兼容现有用户数据，所有 `UserDefaults` key 和 Codable 结构保持不变。

### Services

`LocalizationService.swift` 保存现有语言枚举、字符串键和本地化字典。迁移为 String Catalog 可作为独立后续任务。

## Shared

- `Models`：阅读方向、页面加载描述、缩放模式。
- `Components`：跨页面使用的空状态、背景和进度滑杆。
- `DesignSystem`：现有布局尺寸常量。

Shared 只包含跨 Feature 使用的声明，不作为无法分类代码的集合。

## Resources

- `AppIcon.icns`、`AppIcon.png`
- `Tools/unar`、`Tools/7zz`

Xcode 将这些资源复制到 App Bundle。`Tools` 使用 folder reference，确保运行时仍然位于 `Contents/Resources/Tools`。

## Project and Target Membership

`GlassReader.xcodeproj` 使用与 Finder 对应的传统 PBXGroup 层级。每个 Swift 文件在 Sources Build Phase 中恰好出现一次；图标和 `Tools` 在 Resources Build Phase 中恰好出现一次。`Scripts/generate_xcodeproj.rb` 可从文件系统重新生成引用和共享 Scheme。

SwiftPM 继续作为轻量基准编译入口；它排除 App Bundle 专用资源，Xcode 工程负责生成完整应用包。

## Deliberate Constraints

- 未新增业务协议或 repository 层。
- 未改变 UI、快捷键、持久化键或文件格式处理顺序。
- `ReaderLibrary` 仍是全局 ObservableObject；本次通过职责扩展降低单文件体积，而没有重写状态架构。
- 当前没有 Tests target，因为恢复的源码中不存在测试。后续应优先为纯函数和持久化兼容性增加测试，再进一步抽离服务。
