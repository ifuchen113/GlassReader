# GlassReader Current Architecture Analysis

## Baseline

- Source recovered from the previous local GlassReader Swift Package workspace.
- Build system: Swift Package Manager (`Package.swift`), macOS 14+
- Product: one executable target named `GlassReader`
- UI stack: SwiftUI with AppKit bridges; PDF rendering uses PDFKit; image metadata/downsampling uses ImageIO
- Baseline release build: successful before structural changes
- Existing packaged app: version `0.1.20 (21)`, bundle identifier `local.codex.GlassReader`
- Tests: no test targets or test source files were present

## Current Project Structure

```text
GlassReader1/
├── Package.swift
├── GlassReader1-Info.plist
└── Sources/
    └── GlassReader/
        └── main.swift
```

The entire application is implemented in one 3,337-line Swift file. The packaged `.app` additionally contains `AppIcon.icns`, `AppIcon.png`, and archive helpers (`unar`, `7zz`), but those resources were not stored beside the editable source project.

## Major Declarations and Responsibilities

| Current declaration | Current responsibility | Recommended destination |
| --- | --- | --- |
| `GlassReaderApp` | App entry, window scene, commands, global `ReaderLibrary` creation | `App/GlassReaderApp.swift` |
| `ReadingDirection`, `ZoomMode`, `ReaderPage`, `PageLoader` | Reader domain and display models | `Shared/Models/` and `Features/Reader/` |
| `FavoriteItem` | Persisted favorite/history record | `Features/Library/Models/` |
| `ReaderTab`, `PersistedReaderTab` | Runtime and persisted tab state | `Features/Tabs/` |
| `ArchivePasswordPrompt` | Archive-password workflow state | `Features/Import/` |
| `SidebarListMode` | Library sidebar selection | `Features/Library/` |
| `AppLanguage`, `LKey`, `Localizer` | In-code localization catalog and lookup | `Core/Services/Localization/` |
| `ReaderLibrary` | Global state, importing, archive extraction, PDF discovery, tab/session persistence, favorites/history, paging, slideshow, fullscreen, keyboard handling | Keep type name initially; split implementation by responsibility across feature/core extension files |
| `ReaderError` | File/PDF/archive loading errors | `Core/Readers/ReaderError.swift` |
| `ContentView` | Root window composition, overlays, drop handling and keyboard monitor | `App/ContentView.swift` |
| `SidebarView`, `FavoriteRow`, settings controls | Library/history/settings UI | `Features/Library/` and `Features/Settings/` |
| `ReaderView`, `SpreadStage`, `PageSurface` | Main reader layout and page presentation | `Features/Reader/` |
| `TabBarView` | Multi-tab UI | `Features/Tabs/Components/` |
| `ToolbarView`, glyphs, shortcut panel | Reader controls | `Features/Reader/Components/` |
| `ThumbnailPreviewPanel`, `PageStrip`, `FlatProgressSlider` | Page navigation UI | `Features/Reader/Components/` |
| `ScrollWheelPagingMonitor` | AppKit event bridge for wheel/gesture paging | `Features/Reader/Components/` |
| `PageLoader` extension, `ImageFileLoader`, `PageImage` | Image/PDF sizing, rendering and cache | `Core/Readers/` plus reader presentation component |
| `EmptyReaderState`, `LiquidBackground` | Reusable/root visual states | `Shared/Components/` |

## Existing Functional Areas

- File import: `NSOpenPanel`, app document-open events, and file URL drag/drop.
- Inputs: folders, common raster images, PDF, ZIP/CBZ, RAR/CBR, and 7Z/CB7.
- Archive handling: shelling out to bundled or system `ditto`, `unzip`, `unar`, `7zz`/`7z`, and `bsdtar`/`tar`; includes nested and password-protected archives.
- PDF handling: page enumeration and rendering through PDFKit.
- Reader: single/double-page modes, LTR/RTL direction, spread rematching, multiple fit modes, paging gestures, slideshow, thumbnails and progress slider.
- Window behavior: standard fullscreen, focus/immersive presentation, keyboard shortcuts and overlay controls.
- Persistence: favorites, history, reading position/layout, open tabs, active tab, zoom and language through `UserDefaults`.
- Localization: Chinese, English, Japanese, Korean, Russian, French, German and Spanish strings embedded in Swift.
- Tabs: multiple sources with active-tab switching and per-tab page/layout/password state.

## Responsibility-Mixing Problems

1. `main.swift` is both the composition root and the implementation location for every feature and service.
2. `ReaderLibrary` is a large state object that combines UI state, navigation, persistence, file import, archive subprocess execution, PDF discovery, slideshow timing and window control.
3. Image/PDF rendering and cache policy sit next to SwiftUI presentation components.
4. Favorites, history and session persistence directly access `UserDefaults` from the feature state object.
5. Localization data and lookup are embedded in the same file as business logic and views.
6. Feature-specific controls and broadly reusable UI helpers are not distinguishable by their filesystem location.
7. The editable source lacks the icon and archive-tool resources that exist in the packaged app, so reproducing the distribution bundle is not self-contained.
8. There is no Xcode project, automated test target, architecture documentation or source-control history in the recovered project.

## Refactoring Strategy

The safest first pass is structural: preserve every existing declaration and implementation, split the monolithic file at top-level declaration boundaries, and use Swift extensions only where needed to separate responsibilities without changing behavior. The initial target will remain a Swift Package so each phase can be compiled immediately. An Xcode project can be added only after the source layout is stable and its file references can be validated.

## Files Not Recommended for Behavioral Changes Yet

- The archive command construction and password fallback sequence: compatibility-sensitive and not covered by tests.
- The page-size, zoom and gesture calculations in `SpreadStage`, `PageSurface` and `ScrollWheelPagingMonitor`.
- Fullscreen/immersive transition timing and snapshot behavior.
- Existing `UserDefaults` key strings and Codable payload shapes, because renaming them would break user state restoration.
- Bundle identifier, deployment target, signing and document-type declarations.
- In-code localization keys/text, until localization migration can be tested independently.

## Validation Risks

- There are no automated tests, so build checks alone cannot validate archive passwords, nested archives, gesture behavior or state restoration.
- The bundled archive executables must be copied and packaged with executable permissions.
- Moving private members into separate extensions would fail because Swift `private` is file-scoped in relevant cases; the first split must therefore keep tightly coupled private implementation together or deliberately relax access only where necessary.
- The packaged executable is code-signed after assembly, so its hash does not directly match the raw SwiftPM release executable.
