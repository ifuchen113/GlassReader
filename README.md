# GlassReader

GlassReader 是一款原生 macOS 漫画与图像阅读器，使用 Swift、SwiftUI、AppKit、PDFKit 和 ImageIO 构建。它面向本地阅读，支持文件夹、图片、PDF 和常见漫画压缩包。

## 当前功能

- 文件夹与 JPG、PNG、WebP、GIF、BMP、TIFF、HEIC 图片
- PDF 分页阅读
- ZIP/CBZ、RAR/CBR、7Z/CB7，包括密码与嵌套压缩包流程
- 单页/双页、LTR/RTL、跨页重新匹配
- 适应屏幕、适应宽度、原始大小、填满屏幕等显示方式
- 多标签页、收藏、历史记录、阅读进度与重启恢复
- 缩略图、进度条、幻灯片、全屏和沉浸模式
- 中文、英文、日文、韩文、俄文、法文、德文和西班牙文界面文本

## 环境要求

- macOS 14.0 或更高版本
- Xcode 16 或更高版本（工程最近使用 Xcode 26.6 验证）
- Swift 6 工具链
- Apple Silicon 为当前主要验证架构

## 在 Xcode 中运行

1. 打开 `GlassReader.xcodeproj`。
2. 选择共享的 `GlassReader` Scheme。
3. 选择 “My Mac”。
4. 执行 Build 或 Run。

项目没有第三方 Swift Package 依赖。归档读取所需的 `unar` 和 `7zz` 已保存在 `GlassReader/Resources/Tools`，并由 Xcode 的 Resources Build Phase 放入 App Bundle。

## 命令行构建

Swift Package 基准构建：

```bash
CLANG_MODULE_CACHE_PATH=/tmp/glassreader-swift-cache \
SWIFT_MODULECACHE_PATH=/tmp/glassreader-swift-cache \
swift build -c release
```

Xcode 工程构建：

```bash
xcodebuild \
  -project GlassReader.xcodeproj \
  -scheme GlassReader \
  -configuration Release \
  -derivedDataPath .build/xcode \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  build
```

## 项目结构

```text
GlassReader/
├── App/                 # App 入口和根页面
├── Features/            # Library、Reader、Tabs、Import、FullScreen、Settings
├── Core/                # 读取、持久化与本地化等底层能力
├── Shared/              # 公共模型、组件和设计尺寸
└── Resources/           # 图标和归档工具
```

详细说明见 [Docs/Architecture.md](Docs/Architecture.md)，产品与交互记录见 [Docs/Design.md](Docs/Design.md)。重构前分析见 [CurrentArchitectureAnalysis.md](CurrentArchitectureAnalysis.md)。

## 工程文件维护

Finder 目录是结构真源。添加、移动或删除 Swift 文件后，运行：

```bash
ruby Scripts/generate_xcodeproj.rb
```

脚本会重新生成 Xcode 文件引用、Target Membership、Build Phases 和共享 Scheme，避免残留失效引用或重复编译项。

## License

GlassReader 继续采用 GNU General Public License Version 3.0 only（GPL-3.0-only）开源，详见 [LICENSE](LICENSE)。随 App 分发的第三方归档工具采用各自许可证，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

---

# GlassReader — English

GlassReader is a native macOS comic and image reader built with Swift, SwiftUI, AppKit, PDFKit, and ImageIO. It is designed for local reading and supports folders, images, PDF documents, and common comic-book archive formats.

## Features

- Folders and JPG, PNG, WebP, GIF, BMP, TIFF, and HEIC images
- Paginated PDF reading
- ZIP/CBZ, RAR/CBR, and 7Z/CB7 archives, including password-protected and nested archives
- Single-page and two-page layouts, LTR/RTL reading, and spread realignment
- Fit to screen, fit to width, actual size, and fill screen display modes
- Multiple tabs, favorites, history, reading progress, and session restoration
- Thumbnails, progress controls, slideshow, full-screen, and immersive modes
- Interface text in Chinese, English, Japanese, Korean, Russian, French, German, and Spanish

## Requirements

- macOS 14.0 or later
- Xcode 16 or later (the project was most recently verified with Xcode 26.6)
- Swift 6 toolchain
- Apple Silicon is the primary currently verified architecture

## Running in Xcode

1. Open `GlassReader.xcodeproj`.
2. Select the shared `GlassReader` scheme.
3. Select **My Mac** as the run destination.
4. Build or run the project.

The project has no third-party Swift Package dependencies. The `unar` and `7zz` tools required for archive extraction are stored in `GlassReader/Resources/Tools` and copied into the App Bundle by the Xcode Resources Build Phase.

## Command-Line Builds

Swift Package baseline build:

```bash
CLANG_MODULE_CACHE_PATH=/tmp/glassreader-swift-cache \
SWIFT_MODULECACHE_PATH=/tmp/glassreader-swift-cache \
swift build -c release
```

Xcode project build:

```bash
xcodebuild \
  -project GlassReader.xcodeproj \
  -scheme GlassReader \
  -configuration Release \
  -derivedDataPath .build/xcode \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  build
```

## Project Structure

```text
GlassReader/
├── App/                 # App entry point and root view
├── Features/            # Library, Reader, Tabs, Import, FullScreen, Settings
├── Core/                # Reading, persistence, localization, and core services
├── Shared/              # Shared models, components, and layout metrics
└── Resources/           # Icons and archive tools
```

See [Docs/Architecture.md](Docs/Architecture.md) for architecture details and [Docs/Design.md](Docs/Design.md) for product and interaction notes. The pre-refactor analysis is available in [CurrentArchitectureAnalysis.md](CurrentArchitectureAnalysis.md).

## Maintaining the Xcode Project

The Finder directory structure is the source of truth. After adding, moving, or deleting Swift files, run:

```bash
ruby Scripts/generate_xcodeproj.rb
```

The script regenerates Xcode file references, target membership, build phases, and the shared scheme, preventing stale references and duplicate compilation entries.

## License

GlassReader remains open source under the GNU General Public License Version 3.0 only (GPL-3.0-only). See [LICENSE](LICENSE). Third-party archive tools distributed with the app retain their respective licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
