import AppKit
import ImageIO
import PDFKit
import SwiftUI

@main
struct GlassReaderApp: App {
    @StateObject private var library = ReaderLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(library)
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button(library.t(.openLocalFile) + "...") { library.openWithPanel() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button(library.t(.favoriteCurrent)) { library.toggleFavoriteCurrentSource() }
                    .keyboardShortcut("d", modifiers: [.command])
                Button(library.t(.shortcutClear)) { library.clearDocument() }
                    .keyboardShortcut("w", modifiers: [.command])
            }

            CommandMenu(library.t(.readerMenu)) {
                Button(library.t(.turnLeft)) { library.turnLeft() }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                Button(library.t(.turnRight)) { library.turnRight() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button(library.t(.rematchSpreadAction)) { library.rematchSpreadForward() }
                    .keyboardShortcut("r", modifiers: [.command])
                Button(library.t(.shortcutSpreadBack)) { library.rematchSpreadBackward() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                Button(library.t(.shortcutSpreadForward)) { library.rematchSpreadForward() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                Button(library.t(.shortcutPageMode)) { library.toggleDoublePageMode() }
                    .keyboardShortcut("2", modifiers: [.command])
                Button(library.t(.shortcutDirection)) { library.toggleReadingDirection() }
                    .keyboardShortcut("l", modifiers: [.command])
                Button(library.t(.pageDisplayToggle)) { library.showsPageBadges.toggle() }
                    .keyboardShortcut("p", modifiers: [.command])
                Button(library.t(.slideshowHelp)) { library.toggleSlideshow() }
                    .keyboardShortcut(.space, modifiers: [])
                Button(library.t(.fullscreen)) { library.toggleFullScreen() }
                    .keyboardShortcut("f", modifiers: [.command, .control])
                Button(library.t(.immersive)) { library.toggleImmersiveMode() }
                    .keyboardShortcut("f", modifiers: [.command, .shift])
                Button(library.t(.exitImmersive)) { library.exitImmersiveMode() }
                    .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }
}

enum ReadingDirection: String, CaseIterable, Identifiable, Codable {
    case leftToRight = "普通模式"
    case rightToLeft = "日漫模式"

    var id: String { rawValue }

    var layoutDirection: LayoutDirection {
        self == .rightToLeft ? .rightToLeft : .leftToRight
    }
}

struct ReaderPage: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let sourceURL: URL
    let sortKey: String
    let loader: PageLoader
}

enum PageLoader: Hashable {
    case image(URL)
    case pdfPage(URL, Int)
}

struct FavoriteItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var addedAt: Date
    var lastPageIndex: Int = 0
    var pageCount: Int = 0
    var isDoublePage: Bool?
    var readingDirectionRawValue: String?

    init(
        id: UUID,
        name: String,
        path: String,
        addedAt: Date,
        lastPageIndex: Int = 0,
        pageCount: Int = 0,
        isDoublePage: Bool? = nil,
        readingDirectionRawValue: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.addedAt = addedAt
        self.lastPageIndex = lastPageIndex
        self.pageCount = pageCount
        self.isDoublePage = isDoublePage
        self.readingDirectionRawValue = readingDirectionRawValue
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case addedAt
        case lastPageIndex
        case pageCount
        case isDoublePage
        case readingDirectionRawValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        lastPageIndex = try container.decodeIfPresent(Int.self, forKey: .lastPageIndex) ?? 0
        pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount) ?? 0
        isDoublePage = try container.decodeIfPresent(Bool.self, forKey: .isDoublePage)
        readingDirectionRawValue = try container.decodeIfPresent(String.self, forKey: .readingDirectionRawValue)
    }
}

struct ArchivePasswordPrompt: Identifiable {
    let id = UUID()
    let url: URL
    let rootURL: URL
    let passwords: [String: String]
    let message: String
}

enum SidebarListMode: String, CaseIterable, Identifiable {
    case favorites = "收藏"
    case history = "历史"

    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case en
    case ja
    case ko
    case ru
    case fr
    case de
    case es

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .ru: return "Русский"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .es: return "Español"
        }
    }
}

enum LKey: String {
    case defaultStatus, openLocalFile, chooseReaderFile, open, cancel
    case privateOn, privateOff, noReadablePages, archiveNeedsPasswordStatus, archiveMightNeedPassword
    case archivePasswordFailed, cannotOpen, passwordCancelled, favoriteRemoved, favoriteAdded, alreadyFavorite
    case historyCleared, rematchedSpread, passwordTitle, passwordPlaceholder, nestedPasswordMessage, firstPasswordMessage
    case tagline, view, doublePage, direction, zoom, slideshow, favorites, history, clearHistory
    case favoriteEmpty, privateBrowsingEmpty, historyEmpty, lastRead, showSidebar, hideSidebar
    case favoriteCurrent, unfavoriteCurrent, privateOnHelp, privateOffHelp
    case zoomHelp, spreadBackHelp, spreadForwardHelp, switchSingle, switchDouble, switchManga, switchNormal
    case slideshowHelp, unopened, thumbnails, fullscreen, immersive, exitImmersive, shortcuts
    case shortcutOpen, shortcutClear, shortcutPrivate, shortcutSpreadBack, shortcutSpreadForward, shortcutPageMode
    case shortcutDirection, shortcutPageBadges, shortcutSlideshow, shortcutFullscreen, shortcutImmersive, shortcutExitImmersive
    case author, pageDisplayToggle, emptyTitle, emptySubtitle, chooseFile, unablePage, readerMenu
    case directionNormal, directionManga
    case zoomFitScreen, zoomFitWidth, zoomOriginal, zoomFillScreen, zoomSmartFit
    case unsupportedFile, unreadablePDF, archiveExtractionFailed, missingArchiveTool, archiveNeedsPasswordError
    case turnLeft, turnRight, rematchSpreadAction
}

struct Localizer {
    static func text(_ key: LKey, _ language: AppLanguage) -> String {
        translations[key]?[language] ?? translations[key]?[.zh] ?? key.rawValue
    }

    private static let translations: [LKey: [AppLanguage: String]] = [
        .defaultStatus: [.zh: "打开一个文件夹、PDF、ZIP/CBZ 或图片开始阅读", .en: "Open a folder, PDF, ZIP/CBZ, or image to start reading", .ja: "フォルダ、PDF、ZIP/CBZ、画像を開いて読み始めます", .ko: "폴더, PDF, ZIP/CBZ 또는 이미지를 열어 읽기 시작", .ru: "Откройте папку, PDF, ZIP/CBZ или изображение", .fr: "Ouvrez un dossier, PDF, ZIP/CBZ ou une image", .de: "Ordner, PDF, ZIP/CBZ oder Bild öffnen", .es: "Abre una carpeta, PDF, ZIP/CBZ o imagen"],
        .openLocalFile: [.zh: "打开本地文件", .en: "Open Local File", .ja: "ローカルファイルを開く", .ko: "로컬 파일 열기", .ru: "Открыть файл", .fr: "Ouvrir un fichier", .de: "Datei öffnen", .es: "Abrir archivo"],
        .chooseReaderFile: [.zh: "选择要阅读的本地文件", .en: "Choose local content to read", .ja: "読むファイルを選択", .ko: "읽을 파일 선택", .ru: "Выберите файл для чтения", .fr: "Choisir un fichier à lire", .de: "Datei zum Lesen wählen", .es: "Elige un archivo para leer"],
        .open: [.zh: "打开", .en: "Open", .ja: "開く", .ko: "열기", .ru: "Открыть", .fr: "Ouvrir", .de: "Öffnen", .es: "Abrir"],
        .cancel: [.zh: "取消", .en: "Cancel", .ja: "キャンセル", .ko: "취소", .ru: "Отмена", .fr: "Annuler", .de: "Abbrechen", .es: "Cancelar"],
        .privateOn: [.zh: "已开启无痕浏览", .en: "Private browsing is on", .ja: "プライベート閲覧をオンにしました", .ko: "시크릿 모드 켜짐", .ru: "Приватный режим включен", .fr: "Navigation privée activée", .de: "Privater Modus aktiviert", .es: "Navegación privada activada"],
        .privateOff: [.zh: "已关闭无痕浏览", .en: "Private browsing is off", .ja: "プライベート閲覧をオフにしました", .ko: "시크릿 모드 꺼짐", .ru: "Приватный режим выключен", .fr: "Navigation privée désactivée", .de: "Privater Modus deaktiviert", .es: "Navegación privada desactivada"],
        .noReadablePages: [.zh: "没有找到可阅读页面", .en: "No readable pages found", .ja: "読めるページが見つかりません", .ko: "읽을 수 있는 페이지가 없습니다", .ru: "Читаемые страницы не найдены", .fr: "Aucune page lisible trouvée", .de: "Keine lesbaren Seiten gefunden", .es: "No se encontraron páginas legibles"],
        .archiveNeedsPasswordStatus: [.zh: "这个压缩包需要密码", .en: "This archive needs a password", .ja: "この圧縮ファイルにはパスワードが必要です", .ko: "이 압축 파일에는 비밀번호가 필요합니다", .ru: "Архиву нужен пароль", .fr: "Cette archive demande un mot de passe", .de: "Dieses Archiv benötigt ein Passwort", .es: "Este archivo necesita contraseña"],
        .archiveMightNeedPassword: [.zh: "这个压缩包可能需要密码", .en: "This archive may need a password", .ja: "パスワードが必要な可能性があります", .ko: "비밀번호가 필요할 수 있습니다", .ru: "Возможно, архиву нужен пароль", .fr: "Cette archive peut demander un mot de passe", .de: "Dieses Archiv benötigt eventuell ein Passwort", .es: "Puede necesitar contraseña"],
        .archivePasswordFailed: [.zh: "密码不正确或压缩包解压失败", .en: "Wrong password or extraction failed", .ja: "パスワード違い、または解凍に失敗しました", .ko: "비밀번호가 틀렸거나 압축 해제 실패", .ru: "Неверный пароль или ошибка распаковки", .fr: "Mot de passe incorrect ou extraction échouée", .de: "Falsches Passwort oder Entpacken fehlgeschlagen", .es: "Contraseña incorrecta o extracción fallida"],
        .cannotOpen: [.zh: "无法打开", .en: "Cannot open", .ja: "開けません", .ko: "열 수 없음", .ru: "Не удалось открыть", .fr: "Impossible d’ouvrir", .de: "Kann nicht geöffnet werden", .es: "No se puede abrir"],
        .passwordCancelled: [.zh: "已取消输入压缩包密码", .en: "Archive password entry cancelled", .ja: "パスワード入力をキャンセルしました", .ko: "압축 파일 비밀번호 입력 취소됨", .ru: "Ввод пароля отменен", .fr: "Saisie du mot de passe annulée", .de: "Passworteingabe abgebrochen", .es: "Entrada de contraseña cancelada"],
        .favoriteRemoved: [.zh: "已取消收藏", .en: "Removed favorite", .ja: "お気に入りを解除しました", .ko: "즐겨찾기 해제됨", .ru: "Удалено из избранного", .fr: "Favori retiré", .de: "Favorit entfernt", .es: "Quitado de favoritos"],
        .favoriteAdded: [.zh: "已收藏", .en: "Added to favorites", .ja: "お気に入りに追加しました", .ko: "즐겨찾기에 추가됨", .ru: "Добавлено в избранное", .fr: "Ajouté aux favoris", .de: "Zu Favoriten hinzugefügt", .es: "Añadido a favoritos"],
        .alreadyFavorite: [.zh: "这个地址已经在收藏里", .en: "This path is already saved", .ja: "この場所はすでに保存済みです", .ko: "이미 저장된 경로입니다", .ru: "Этот путь уже сохранен", .fr: "Ce chemin est déjà enregistré", .de: "Dieser Pfad ist bereits gespeichert", .es: "Esta ruta ya está guardada"],
        .historyCleared: [.zh: "已清空历史记录", .en: "History cleared", .ja: "履歴を消去しました", .ko: "기록 삭제됨", .ru: "История очищена", .fr: "Historique effacé", .de: "Verlauf gelöscht", .es: "Historial borrado"],
        .rematchedSpread: [.zh: "已重新匹配跨页：当前从第 %@ 页开始", .en: "Spread rematched: starting from page %@", .ja: "見開きを再調整：%@ページから開始", .ko: "펼침면 재정렬: %@쪽부터 시작", .ru: "Разворот обновлен: с страницы %@", .fr: "Double-page ajustée : depuis la page %@", .de: "Doppelseite angepasst: ab Seite %@", .es: "Doble página ajustada: desde la página %@"],
        .passwordTitle: [.zh: "输入压缩包密码", .en: "Enter Archive Password", .ja: "圧縮ファイルのパスワード", .ko: "압축 파일 비밀번호 입력", .ru: "Введите пароль архива", .fr: "Mot de passe de l’archive", .de: "Archivpasswort eingeben", .es: "Contraseña del archivo"],
        .passwordPlaceholder: [.zh: "密码", .en: "Password", .ja: "パスワード", .ko: "비밀번호", .ru: "Пароль", .fr: "Mot de passe", .de: "Passwort", .es: "Contraseña"],
        .firstPasswordMessage: [.zh: "如果这个压缩包设置了密码，请输入后重新打开。", .en: "If this archive is password protected, enter it to reopen.", .ja: "パスワード付きの場合は入力して開き直してください。", .ko: "비밀번호가 있으면 입력 후 다시 여세요.", .ru: "Если архив защищен, введите пароль.", .fr: "Si l’archive est protégée, saisissez le mot de passe.", .de: "Bei geschütztem Archiv Passwort eingeben.", .es: "Si el archivo tiene contraseña, introdúcela."],
        .nestedPasswordMessage: [.zh: "内层压缩包也需要密码，请输入这一层的密码。", .en: "The nested archive also needs a password.", .ja: "内側の圧縮ファイルにもパスワードが必要です。", .ko: "내부 압축 파일에도 비밀번호가 필요합니다.", .ru: "Вложенному архиву тоже нужен пароль.", .fr: "L’archive interne demande aussi un mot de passe.", .de: "Das innere Archiv benötigt ebenfalls ein Passwort.", .es: "El archivo interno también necesita contraseña."],
        .tagline: [.zh: "简简单单的阅读体验", .en: "A simple reading experience", .ja: "シンプルな読書体験", .ko: "간단한 읽기 경험", .ru: "Простое чтение", .fr: "Une lecture toute simple", .de: "Einfaches Leseerlebnis", .es: "Una experiencia simple"],
        .view: [.zh: "视图", .en: "View", .ja: "表示", .ko: "보기", .ru: "Вид", .fr: "Affichage", .de: "Ansicht", .es: "Vista"],
        .doublePage: [.zh: "双页", .en: "Double Page", .ja: "見開き", .ko: "두 페이지", .ru: "Две страницы", .fr: "Double page", .de: "Doppelseite", .es: "Doble página"],
        .direction: [.zh: "方向", .en: "Direction", .ja: "方向", .ko: "방향", .ru: "Направление", .fr: "Sens", .de: "Richtung", .es: "Dirección"],
        .zoom: [.zh: "缩放", .en: "Zoom", .ja: "ズーム", .ko: "확대", .ru: "Масштаб", .fr: "Zoom", .de: "Zoom", .es: "Zoom"],
        .slideshow: [.zh: "幻灯片", .en: "Slideshow", .ja: "スライド", .ko: "슬라이드", .ru: "Слайд-шоу", .fr: "Diaporama", .de: "Diashow", .es: "Diapositivas"],
        .favorites: [.zh: "收藏", .en: "Saved", .ja: "保存", .ko: "저장", .ru: "Избранное", .fr: "Favoris", .de: "Favoriten", .es: "Favoritos"],
        .history: [.zh: "历史", .en: "History", .ja: "履歴", .ko: "기록", .ru: "История", .fr: "Historique", .de: "Verlauf", .es: "Historial"],
        .clearHistory: [.zh: "清空历史记录", .en: "Clear history", .ja: "履歴を消去", .ko: "기록 삭제", .ru: "Очистить историю", .fr: "Effacer l’historique", .de: "Verlauf löschen", .es: "Borrar historial"],
        .favoriteEmpty: [.zh: "收藏只保存路径，文件仍在原位置。", .en: "Saved items keep paths; files stay in place.", .ja: "保存するのは場所だけです。", .ko: "저장은 경로만 보관합니다.", .ru: "Сохраняются только пути.", .fr: "Les favoris gardent seulement les chemins.", .de: "Favoriten speichern nur Pfade.", .es: "Solo se guardan rutas."],
        .privateBrowsingEmpty: [.zh: "无痕浏览开启中，不记录历史。", .en: "Private browsing is on. History is not saved.", .ja: "プライベート閲覧中は履歴を保存しません。", .ko: "시크릿 모드에서는 기록하지 않습니다.", .ru: "Приватный режим: история не сохраняется.", .fr: "Navigation privée : aucun historique.", .de: "Privatmodus: kein Verlauf.", .es: "Modo privado: sin historial."],
        .historyEmpty: [.zh: "打开文件后会自动记录在这里。", .en: "Opened files will appear here.", .ja: "開いたファイルがここに表示されます。", .ko: "연 파일이 여기에 표시됩니다.", .ru: "Открытые файлы появятся здесь.", .fr: "Les fichiers ouverts apparaîtront ici.", .de: "Geöffnete Dateien erscheinen hier.", .es: "Los archivos abiertos aparecerán aquí."],
        .lastRead: [.zh: "上次读到 %@ / %@", .en: "Last read %@ / %@", .ja: "前回 %@ / %@", .ko: "마지막 %@ / %@", .ru: "Последнее %@ / %@", .fr: "Dernière lecture %@ / %@", .de: "Zuletzt %@ / %@", .es: "Última lectura %@ / %@"],
        .showSidebar: [.zh: "显示侧边栏", .en: "Show sidebar", .ja: "サイドバーを表示", .ko: "사이드바 표시", .ru: "Показать боковую панель", .fr: "Afficher la barre latérale", .de: "Seitenleiste anzeigen", .es: "Mostrar barra lateral"],
        .hideSidebar: [.zh: "隐藏侧边栏", .en: "Hide sidebar", .ja: "サイドバーを隠す", .ko: "사이드바 숨기기", .ru: "Скрыть боковую панель", .fr: "Masquer la barre latérale", .de: "Seitenleiste ausblenden", .es: "Ocultar barra lateral"],
        .favoriteCurrent: [.zh: "收藏当前地址", .en: "Save current path", .ja: "現在の場所を保存", .ko: "현재 경로 저장", .ru: "Сохранить путь", .fr: "Enregistrer ce chemin", .de: "Aktuellen Pfad speichern", .es: "Guardar ruta actual"],
        .unfavoriteCurrent: [.zh: "取消收藏当前地址", .en: "Remove current favorite", .ja: "現在のお気に入りを解除", .ko: "현재 즐겨찾기 해제", .ru: "Удалить из избранного", .fr: "Retirer ce favori", .de: "Favorit entfernen", .es: "Quitar favorito"],
        .privateOnHelp: [.zh: "开启无痕浏览", .en: "Turn on private browsing", .ja: "プライベート閲覧をオン", .ko: "시크릿 모드 켜기", .ru: "Включить приватный режим", .fr: "Activer la navigation privée", .de: "Privatmodus aktivieren", .es: "Activar modo privado"],
        .privateOffHelp: [.zh: "关闭无痕浏览", .en: "Turn off private browsing", .ja: "プライベート閲覧をオフ", .ko: "시크릿 모드 끄기", .ru: "Выключить приватный режим", .fr: "Désactiver la navigation privée", .de: "Privatmodus deaktivieren", .es: "Desactivar modo privado"],
        .zoomHelp: [.zh: "缩放模式", .en: "Zoom mode", .ja: "ズームモード", .ko: "확대 모드", .ru: "Режим масштаба", .fr: "Mode de zoom", .de: "Zoommodus", .es: "Modo de zoom"],
        .spreadBackHelp: [.zh: "跨页向前微调一页", .en: "Shift spread backward", .ja: "見開きを前へ調整", .ko: "펼침면 앞으로 조정", .ru: "Сдвинуть разворот назад", .fr: "Décaler la double-page en arrière", .de: "Doppelseite zurückschieben", .es: "Ajustar doble página atrás"],
        .spreadForwardHelp: [.zh: "跨页向后微调一页", .en: "Shift spread forward", .ja: "見開きを後ろへ調整", .ko: "펼침면 뒤로 조정", .ru: "Сдвинуть разворот вперед", .fr: "Décaler la double-page en avant", .de: "Doppelseite vorschieben", .es: "Ajustar doble página adelante"],
        .switchSingle: [.zh: "切换到单页", .en: "Switch to single page", .ja: "単ページに切替", .ko: "한 페이지로 전환", .ru: "Одна страница", .fr: "Passer en page simple", .de: "Zu Einzelseite wechseln", .es: "Cambiar a página única"],
        .switchDouble: [.zh: "切换到双页", .en: "Switch to double page", .ja: "見開きに切替", .ko: "두 페이지로 전환", .ru: "Две страницы", .fr: "Passer en double page", .de: "Zu Doppelseite wechseln", .es: "Cambiar a doble página"],
        .switchManga: [.zh: "切换到日漫模式", .en: "Switch to manga mode", .ja: "日本漫画モードへ", .ko: "일본 만화 모드로", .ru: "Перейти в manga-режим", .fr: "Mode manga", .de: "Zum Manga-Modus", .es: "Cambiar a modo manga"],
        .switchNormal: [.zh: "切换到普通模式", .en: "Switch to normal mode", .ja: "通常モードへ", .ko: "일반 모드로", .ru: "Обычный режим", .fr: "Mode normal", .de: "Zum Normalmodus", .es: "Cambiar a modo normal"],
        .slideshowHelp: [.zh: "幻灯片放映", .en: "Slideshow", .ja: "スライドショー", .ko: "슬라이드 쇼", .ru: "Слайд-шоу", .fr: "Diaporama", .de: "Diashow", .es: "Presentación"],
        .unopened: [.zh: "未打开", .en: "Not Opened", .ja: "未オープン", .ko: "열지 않음", .ru: "Не открыто", .fr: "Non ouvert", .de: "Nicht geöffnet", .es: "Sin abrir"],
        .thumbnails: [.zh: "图片预览", .en: "Thumbnails", .ja: "サムネイル", .ko: "미리보기", .ru: "Миниатюры", .fr: "Aperçus", .de: "Miniaturen", .es: "Miniaturas"],
        .fullscreen: [.zh: "全屏", .en: "Fullscreen", .ja: "フルスクリーン", .ko: "전체 화면", .ru: "Полный экран", .fr: "Plein écran", .de: "Vollbild", .es: "Pantalla completa"],
        .immersive: [.zh: "纯净全屏", .en: "Clean Fullscreen", .ja: "集中フルスクリーン", .ko: "깨끗한 전체 화면", .ru: "Чистый экран", .fr: "Plein écran épuré", .de: "Reines Vollbild", .es: "Pantalla limpia"],
        .exitImmersive: [.zh: "退出纯净全屏", .en: "Exit Clean Fullscreen", .ja: "集中フルスクリーンを終了", .ko: "깨끗한 전체 화면 종료", .ru: "Выйти из чистого экрана", .fr: "Quitter le plein écran épuré", .de: "Reines Vollbild beenden", .es: "Salir de pantalla limpia"],
        .shortcuts: [.zh: "快捷键", .en: "Shortcuts", .ja: "ショートカット", .ko: "단축키", .ru: "Горячие клавиши", .fr: "Raccourcis", .de: "Kurzbefehle", .es: "Atajos"],
        .emptyTitle: [.zh: "打开本地内容开始阅读", .en: "Open local content to start reading", .ja: "ローカルコンテンツを開いて読み始める", .ko: "로컬 콘텐츠를 열어 읽기 시작", .ru: "Откройте локальный файл", .fr: "Ouvrez un contenu local", .de: "Lokalen Inhalt öffnen", .es: "Abre contenido local"],
        .emptySubtitle: [.zh: "支持文件夹、PDF、JPG/PNG/WebP、ZIP/CBZ/RAR/7Z。", .en: "Supports folders, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z.", .ja: "フォルダ、PDF、JPG/PNG/WebP、ZIP/CBZ/RAR/7Zに対応。", .ko: "폴더, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z 지원.", .ru: "Папки, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z.", .fr: "Dossiers, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z.", .de: "Ordner, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z.", .es: "Carpetas, PDF, JPG/PNG/WebP, ZIP/CBZ/RAR/7Z."],
        .chooseFile: [.zh: "选择文件", .en: "Choose File", .ja: "ファイルを選択", .ko: "파일 선택", .ru: "Выбрать файл", .fr: "Choisir un fichier", .de: "Datei wählen", .es: "Elegir archivo"],
        .unablePage: [.zh: "无法显示页面", .en: "Cannot display page", .ja: "ページを表示できません", .ko: "페이지를 표시할 수 없음", .ru: "Не удалось показать страницу", .fr: "Impossible d’afficher la page", .de: "Seite kann nicht angezeigt werden", .es: "No se puede mostrar la página"],
        .readerMenu: [.zh: "阅读", .en: "Reading", .ja: "読書", .ko: "읽기", .ru: "Чтение", .fr: "Lecture", .de: "Lesen", .es: "Lectura"],
        .directionNormal: [.zh: "普通模式", .en: "Normal", .ja: "通常", .ko: "일반", .ru: "Обычный", .fr: "Normal", .de: "Normal", .es: "Normal"],
        .directionManga: [.zh: "日漫模式", .en: "Manga", .ja: "日本漫画", .ko: "일본 만화", .ru: "Манга", .fr: "Manga", .de: "Manga", .es: "Manga"],
        .zoomFitScreen: [.zh: "适应屏幕", .en: "Fit Screen", .ja: "画面に合わせる", .ko: "화면 맞춤", .ru: "По экрану", .fr: "Adapter écran", .de: "An Bildschirm", .es: "Ajustar pantalla"],
        .zoomFitWidth: [.zh: "适应宽度", .en: "Fit Width", .ja: "幅に合わせる", .ko: "너비 맞춤", .ru: "По ширине", .fr: "Adapter largeur", .de: "An Breite", .es: "Ajustar ancho"],
        .zoomOriginal: [.zh: "原始大小", .en: "Original", .ja: "原寸", .ko: "원본 크기", .ru: "Оригинал", .fr: "Original", .de: "Original", .es: "Original"],
        .zoomFillScreen: [.zh: "填满屏幕", .en: "Fill Screen", .ja: "画面いっぱい", .ko: "화면 채우기", .ru: "Заполнить", .fr: "Remplir écran", .de: "Füllen", .es: "Llenar pantalla"],
        .zoomSmartFit: [.zh: "智能适应", .en: "Smart Fit", .ja: "スマート調整", .ko: "스마트 맞춤", .ru: "Умно", .fr: "Ajustement auto", .de: "Smart Fit", .es: "Ajuste inteligente"],
        .unsupportedFile: [.zh: "暂时支持文件夹、图片、PDF、ZIP、CBZ、7Z、CB7、RAR 和 CBR", .en: "Supports folders, images, PDF, ZIP, CBZ, 7Z, CB7, RAR, and CBR", .ja: "フォルダ、画像、PDF、ZIP、CBZ、7Z、CB7、RAR、CBRに対応", .ko: "폴더, 이미지, PDF, ZIP, CBZ, 7Z, CB7, RAR, CBR 지원", .ru: "Поддержка папок, изображений, PDF, ZIP, CBZ, 7Z, CB7, RAR и CBR", .fr: "Dossiers, images, PDF, ZIP, CBZ, 7Z, CB7, RAR et CBR", .de: "Ordner, Bilder, PDF, ZIP, CBZ, 7Z, CB7, RAR und CBR", .es: "Carpetas, imágenes, PDF, ZIP, CBZ, 7Z, CB7, RAR y CBR"],
        .unreadablePDF: [.zh: "PDF 无法读取", .en: "PDF cannot be read", .ja: "PDFを読み込めません", .ko: "PDF를 읽을 수 없습니다", .ru: "PDF не читается", .fr: "PDF illisible", .de: "PDF kann nicht gelesen werden", .es: "No se puede leer el PDF"],
        .archiveExtractionFailed: [.zh: "压缩包解压失败", .en: "Archive extraction failed", .ja: "解凍に失敗しました", .ko: "압축 해제 실패", .ru: "Ошибка распаковки", .fr: "Échec de l’extraction", .de: "Entpacken fehlgeschlagen", .es: "Error al extraer"],
        .missingArchiveTool: [.zh: "读取 %@ 需要安装 unar 或 7-Zip", .en: "Reading %@ requires unar or 7-Zip", .ja: "%@の読み込みにはunarまたは7-Zipが必要です", .ko: "%@ 읽기에는 unar 또는 7-Zip이 필요합니다", .ru: "Для %@ нужен unar или 7-Zip", .fr: "Lire %@ nécessite unar ou 7-Zip", .de: "Für %@ wird unar oder 7-Zip benötigt", .es: "Leer %@ requiere unar o 7-Zip"],
        .archiveNeedsPasswordError: [.zh: "%@ 需要密码", .en: "%@ needs a password", .ja: "%@にはパスワードが必要です", .ko: "%@에는 비밀번호가 필요합니다", .ru: "%@ требует пароль", .fr: "%@ demande un mot de passe", .de: "%@ benötigt ein Passwort", .es: "%@ necesita contraseña"],
        .shortcutClear: [.zh: "清空当前文件", .en: "Clear Current File", .ja: "現在のファイルを閉じる", .ko: "현재 파일 비우기", .ru: "Закрыть файл", .fr: "Fermer le fichier", .de: "Aktuelle Datei schließen", .es: "Cerrar archivo actual"],
        .shortcutPrivate: [.zh: "无痕浏览", .en: "Private Browsing", .ja: "プライベート閲覧", .ko: "시크릿 모드", .ru: "Приватный режим", .fr: "Navigation privée", .de: "Privater Modus", .es: "Modo privado"],
        .shortcutSpreadBack: [.zh: "跨页向前微调", .en: "Shift Spread Back", .ja: "見開きを前へ調整", .ko: "펼침면 앞으로 조정", .ru: "Разворот назад", .fr: "Décaler en arrière", .de: "Doppelseite zurück", .es: "Ajustar atrás"],
        .shortcutSpreadForward: [.zh: "跨页向后微调", .en: "Shift Spread Forward", .ja: "見開きを後ろへ調整", .ko: "펼침면 뒤로 조정", .ru: "Разворот вперед", .fr: "Décaler en avant", .de: "Doppelseite vor", .es: "Ajustar adelante"],
        .shortcutPageMode: [.zh: "切换单页 / 双页", .en: "Single / Double Page", .ja: "単ページ / 見開き", .ko: "한 페이지 / 두 페이지", .ru: "Одна / две страницы", .fr: "Page simple / double", .de: "Einzel / Doppelseite", .es: "Página única / doble"],
        .shortcutDirection: [.zh: "切换普通 / 日漫模式", .en: "Normal / Manga Mode", .ja: "通常 / 日本漫画", .ko: "일반 / 일본 만화", .ru: "Обычный / манга", .fr: "Normal / manga", .de: "Normal / Manga", .es: "Normal / manga"],
        .pageDisplayToggle: [.zh: "显示 / 隐藏页码", .en: "Show / Hide Page Numbers", .ja: "ページ番号 表示 / 非表示", .ko: "쪽 번호 표시 / 숨김", .ru: "Показать / скрыть номера", .fr: "Afficher / masquer les pages", .de: "Seitennummern anzeigen", .es: "Mostrar / ocultar páginas"],
        .author: [.zh: "作者：ifuchen", .en: "Author: ifuchen", .ja: "作者：ifuchen", .ko: "作者: ifuchen", .ru: "Автор: ifuchen", .fr: "Auteur : ifuchen", .de: "Autor: ifuchen", .es: "Autor: ifuchen"],
        .turnLeft: [.zh: "向左翻页", .en: "Turn Left", .ja: "左へページ送り", .ko: "왼쪽으로 넘기기", .ru: "Листать влево", .fr: "Page vers la gauche", .de: "Nach links blättern", .es: "Pasar a la izquierda"],
        .turnRight: [.zh: "向右翻页", .en: "Turn Right", .ja: "右へページ送り", .ko: "오른쪽으로 넘기기", .ru: "Листать вправо", .fr: "Page vers la droite", .de: "Nach rechts blättern", .es: "Pasar a la derecha"],
        .rematchSpreadAction: [.zh: "重新匹配跨页", .en: "Rematch Spread", .ja: "見開きを再調整", .ko: "펼침면 다시 맞춤", .ru: "Обновить разворот", .fr: "Réajuster la double-page", .de: "Doppelseite neu anpassen", .es: "Reajustar doble página"]
    ]
}

@MainActor
final class ReaderLibrary: ObservableObject {
    @Published var pages: [ReaderPage] = []
    @Published var currentIndex = 0
    @Published var sourceURL: URL?
    @Published var status = Localizer.text(.defaultStatus, .zh)
    @Published var favorites: [FavoriteItem] = []
    @Published var history: [FavoriteItem] = []
    @Published var isPrivateBrowsing = false
    @Published var isDoublePage = true
    @Published var readingDirection: ReadingDirection = .leftToRight
    @Published var language: AppLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .zh {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            if pages.isEmpty, sourceURL == nil {
                status = t(.defaultStatus)
            }
        }
    }
    @Published var isSlideshowRunning = false
    @Published var slideshowInterval: Double = 4
    @Published var zoomMode: ZoomMode = ZoomMode.savedDefault {
        didSet { UserDefaults.standard.set(zoomMode.rawValue, forKey: Self.zoomModeKey) }
    }
    @Published var isFocusMode = false
    @Published var isImmersiveMode = false
    @Published var showsImmersiveSidebar = false
    @Published var showsPageBadges = true
    @Published var archivePasswordPrompt: ArchivePasswordPrompt?
    @Published var keepsTopOverlayOpen = false
    @Published var transitionSnapshot: NSImage?

    private var extractedFolders: [URL] = []
    private var slideshowTimer: Timer?
    static let zoomModeKey = "GlassReader.zoomMode"
    private static let languageKey = "GlassReader.language"
    private let favoritesKey = "GlassReader.favorite.paths"
    private let historyKey = "GlassReader.history.paths"
    private let supportedImages = Set(["jpg", "jpeg", "png", "webp", "gif", "bmp", "tiff", "tif", "heic"])
    private let supportedArchives = Set(["zip", "cbz", "7z", "cb7", "rar", "cbr"])

    init() {
        loadFavorites()
        loadHistory()
        status = t(.defaultStatus)
    }

    func t(_ key: LKey) -> String {
        Localizer.text(key, language)
    }

    func format(_ key: LKey, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    func readingDirectionTitle(_ direction: ReadingDirection) -> String {
        direction == .leftToRight ? t(.directionNormal) : t(.directionManga)
    }

    func zoomModeTitle(_ mode: ZoomMode) -> String {
        switch mode {
        case .fitScreen: return t(.zoomFitScreen)
        case .fitWidth: return t(.zoomFitWidth)
        case .originalSize: return t(.zoomOriginal)
        case .fillScreen: return t(.zoomFillScreen)
        case .smartFit: return t(.zoomSmartFit)
        }
    }

    func sidebarModeTitle(_ mode: SidebarListMode) -> String {
        mode == .favorites ? t(.favorites) : t(.history)
    }

    var pageCount: Int { pages.count }

    var currentPair: [ReaderPage] {
        guard !pages.isEmpty else { return [] }
        if isDoublePage {
            let first = clamped(currentIndex)
            let second = clamped(first + 1)
            if second != first {
                return [pages[first], pages[second]]
            }
        }
        return [pages[clamped(currentIndex)]]
    }

    var visiblePages: [ReaderPage] {
        readingDirection == .rightToLeft ? currentPair.reversed() : currentPair
    }

    func handleKeyEvent(_ event: NSEvent) -> Bool {
        if keyName(for: event) == "Esc", isImmersiveMode {
            exitImmersiveMode()
            return true
        }
        return false
    }

    func openWithPanel() {
        let panel = NSOpenPanel()
        panel.title = t(.chooseReaderFile)
        panel.prompt = t(.open)
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            open(url)
        }
    }

    func openDroppedItemProviders(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers where provider.hasItemConformingToTypeIdentifier("public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                let url = Self.fileURL(fromDroppedItem: item)
                guard let url else { return }
                DispatchQueue.main.async {
                    self.open(url)
                }
            }
            return true
        }
        return false
    }

    func openFavorite(_ favorite: FavoriteItem) {
        open(URL(fileURLWithPath: favorite.path), restoreIndex: favorite.lastPageIndex)
    }

    func openHistory(_ item: FavoriteItem) {
        open(URL(fileURLWithPath: item.path), restoreIndex: item.lastPageIndex)
    }

    func togglePrivateBrowsing() {
        isPrivateBrowsing.toggle()
        status = isPrivateBrowsing ? t(.privateOn) : t(.privateOff)
    }

    func clearDocument() {
        saveCurrentReadingProgress()
        stopSlideshow()
        pages = []
        currentIndex = 0
        sourceURL = nil
        status = t(.defaultStatus)
        archivePasswordPrompt = nil
    }

    func open(_ url: URL, password: String? = nil, restoreIndex: Int? = nil, archivePasswords: [String: String] = [:]) {
        saveCurrentReadingProgress()
        stopSlideshow()
        status = password == nil ? "\(t(.open)) \(url.lastPathComponent)..." : "\(t(.passwordTitle)) \(url.lastPathComponent)..."
        var passwords = archivePasswords
        if let password {
            rememberArchivePassword(password, for: url, in: &passwords)
        }

        Task {
            do {
                let loaded = try await loadPages(from: url, passwords: passwords)
                await MainActor.run {
                    let savedIndex = restoreIndex ?? self.savedProgressIndex(for: url)
                    self.restoreReadingLayout(for: url)
                    self.sourceURL = url
                    self.pages = loaded
                    self.currentIndex = loaded.isEmpty ? 0 : self.clamped(savedIndex)
                    self.archivePasswordPrompt = nil
                    self.status = loaded.isEmpty ? self.t(.noReadablePages) : "\(url.lastPathComponent) · \(loaded.count) 页"
                    self.recordHistory(url, currentIndex: self.currentIndex, pageCount: loaded.count)
                }
            } catch ReaderError.archiveNeedsPassword(let targetURL) {
                await MainActor.run {
                    self.pages = []
                    self.status = self.t(.archiveNeedsPasswordStatus)
                    self.archivePasswordPrompt = ArchivePasswordPrompt(
                        url: targetURL,
                        rootURL: url,
                        passwords: passwords,
                        message: targetURL == url
                            ? self.t(.firstPasswordMessage)
                            : self.t(.nestedPasswordMessage)
                    )
                }
            } catch {
                await MainActor.run {
                    self.pages = []
                    if self.isSupportedArchive(url) {
                        let message = password == nil
                            ? self.t(.firstPasswordMessage)
                            : self.t(.archivePasswordFailed)
                        self.status = password == nil ? self.t(.archiveMightNeedPassword) : self.t(.archivePasswordFailed)
                        self.archivePasswordPrompt = ArchivePasswordPrompt(
                            url: url,
                            rootURL: url,
                            passwords: passwords,
                            message: message
                        )
                    } else {
                        self.status = "\(self.t(.cannotOpen)): \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    func submitArchivePassword(_ prompt: ArchivePasswordPrompt, password: String) {
        archivePasswordPrompt = nil
        var passwords = prompt.passwords
        rememberArchivePassword(password, for: prompt.url, in: &passwords)
        open(prompt.rootURL, restoreIndex: savedProgressIndex(for: prompt.rootURL), archivePasswords: passwords)
    }

    func cancelArchivePassword() {
        archivePasswordPrompt = nil
        status = t(.passwordCancelled)
    }

    func toggleFavoriteCurrentSource() {
        guard let sourceURL else { return }
        let path = sourceURL.path
        if favorites.contains(where: { $0.path == path }) {
            favorites.removeAll { $0.path == path }
            saveFavorites()
            status = "\(t(.favoriteRemoved)) \(sourceURL.lastPathComponent)"
            return
        }
        favorites.insert(
            FavoriteItem(id: UUID(), name: sourceURL.lastPathComponent, path: path, addedAt: Date()),
            at: 0
        )
        saveFavorites()
        status = "\(t(.favoriteAdded)) \(sourceURL.lastPathComponent)"
    }

    func favoriteCurrentSource() {
        guard !isCurrentSourceFavorite() else {
            status = t(.alreadyFavorite)
            return
        }
        toggleFavoriteCurrentSource()
    }

    func isCurrentSourceFavorite() -> Bool {
        guard let sourceURL else { return false }
        return favorites.contains { $0.path == sourceURL.path }
    }

    func removeFavorite(_ favorite: FavoriteItem) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }

    func removeHistory(_ item: FavoriteItem) {
        history.removeAll { $0.id == item.id || $0.path == item.path }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
        status = t(.historyCleared)
    }

    func nextPage() {
        guard !pages.isEmpty else { return }
        currentIndex = clamped(currentIndex + (isDoublePage ? 2 : 1))
        saveCurrentReadingProgress()
    }

    func previousPage() {
        guard !pages.isEmpty else { return }
        currentIndex = clamped(currentIndex - (isDoublePage ? 2 : 1))
        saveCurrentReadingProgress()
    }

    func turnLeft() {
        readingDirection == .rightToLeft ? nextPage() : previousPage()
    }

    func turnRight() {
        readingDirection == .rightToLeft ? previousPage() : nextPage()
    }

    func toggleReadingDirection() {
        setReadingDirection(readingDirection == .leftToRight ? .rightToLeft : .leftToRight)
    }

    func setReadingDirection(_ direction: ReadingDirection) {
        readingDirection = direction
        saveCurrentReadingProgress()
    }

    func toggleDoublePageMode() {
        isDoublePage.toggle()
        saveCurrentReadingProgress()
    }

    func rematchSpreadForward() {
        guard pages.count > 1 else { return }
        currentIndex = clamped(currentIndex + 1)
        status = format(.rematchedSpread, "\(currentIndex + 1)")
        saveCurrentReadingProgress()
    }

    func rematchSpreadBackward() {
        guard pages.count > 1 else { return }
        currentIndex = clamped(currentIndex - 1)
        status = format(.rematchedSpread, "\(currentIndex + 1)")
        saveCurrentReadingProgress()
    }

    func rematchSpreadLeft() {
        readingDirection == .rightToLeft ? rematchSpreadForward() : rematchSpreadBackward()
    }

    func rematchSpreadRight() {
        readingDirection == .rightToLeft ? rematchSpreadBackward() : rematchSpreadForward()
    }

    func jump(to index: Int) {
        currentIndex = clamped(index)
        saveCurrentReadingProgress()
    }

    func toggleSlideshow() {
        isSlideshowRunning ? stopSlideshow() : startSlideshow()
    }

    func startSlideshow() {
        guard !pages.isEmpty else { return }
        stopSlideshow()
        isSlideshowRunning = true
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: slideshowInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextPage()
            }
        }
    }

    func stopSlideshow() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
        isSlideshowRunning = false
    }

    func updateSlideshowInterval(_ interval: Double) {
        slideshowInterval = interval
        if isSlideshowRunning {
            startSlideshow()
        }
    }

    func toggleFullScreen() {
        if isImmersiveMode {
            keepsTopOverlayOpen = false
            setReaderMode(focus: false, immersive: false)
            return
        }
        toggleWindowFullScreen()
    }

    func toggleFocusMode() {
        if isImmersiveMode {
            showsImmersiveSidebar.toggle()
            keepsTopOverlayOpen = showsImmersiveSidebar
            return
        }
        isFocusMode.toggle()
        if !isFocusMode {
            isImmersiveMode = false
        }
    }

    func enterImmersiveMode() {
        showsImmersiveSidebar = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == false {
            toggleWindowFullScreen(useSnapshot: true, prepareTransition: {
                self.setReaderMode(focus: true, immersive: true)
            })
        } else {
            setReaderMode(focus: true, immersive: true)
        }
    }

    func toggleImmersiveMode() {
        isImmersiveMode ? exitImmersiveMode() : enterImmersiveMode()
    }

    func exitImmersiveMode() {
        keepsTopOverlayOpen = false
        showsImmersiveSidebar = false
        if NSApp.keyWindow?.styleMask.contains(.fullScreen) == true {
            toggleWindowFullScreen(useSnapshot: true, afterTransition: {
                self.setReaderMode(focus: false, immersive: false)
            })
        } else {
            setReaderMode(focus: false, immersive: false)
        }
    }

    private func toggleWindowFullScreen(
        useSnapshot: Bool = false,
        prepareTransition: (() -> Void)? = nil,
        afterTransition: (() -> Void)? = nil
    ) {
        guard let window = NSApp.keyWindow else { return }
        if useSnapshot {
            transitionSnapshot = captureWindowSnapshot(window)
        }
        prepareTransition?()
        DispatchQueue.main.asyncAfter(deadline: .now() + (useSnapshot ? 0.02 : 0)) {
            window.toggleFullScreen(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) { [weak self] in
            afterTransition?()
            guard useSnapshot else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                self?.transitionSnapshot = nil
            }
        }
    }

    private func captureWindowSnapshot(_ window: NSWindow) -> NSImage? {
        guard let contentView = window.contentView else { return nil }
        let bounds = contentView.bounds
        guard bounds.width > 0, bounds.height > 0,
              let representation = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        contentView.cacheDisplay(in: bounds, to: representation)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(representation)
        return image
    }

    private func setReaderMode(focus: Bool, immersive: Bool) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            isFocusMode = focus
            isImmersiveMode = immersive
        }
    }

    func displayIndex(for page: ReaderPage) -> Int? {
        pages.firstIndex(of: page).map { $0 + 1 }
    }

    private func page(at index: Int) -> ReaderPage? {
        guard pages.indices.contains(index) else { return nil }
        return pages[index]
    }

    private func clamped(_ index: Int) -> Int {
        min(max(index, 0), max(pages.count - 1, 0))
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) else { return }
        favorites = decoded
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) else { return }
        history = decoded
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func keyName(for event: NSEvent) -> String {
        switch event.keyCode {
        case 49:
            return "Space"
        case 53:
            return "Esc"
        case 123:
            return "←"
        case 124:
            return "→"
        case 125:
            return "↓"
        case 126:
            return "↑"
        default:
            return (event.charactersIgnoringModifiers ?? "").uppercased()
        }
    }

    nonisolated private static func fileURL(fromDroppedItem item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        let rawString: String?
        if let data = item as? Data {
            rawString = String(data: data, encoding: .utf8)
        } else if let string = item as? String {
            rawString = string
        } else {
            rawString = nil
        }

        guard let cleaned = rawString?
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !cleaned.isEmpty else {
            return nil
        }

        if let url = URL(string: cleaned), url.isFileURL {
            return url
        }

        return URL(fileURLWithPath: cleaned)
    }

    private func savedProgressIndex(for url: URL) -> Int {
        let path = url.path
        if let historyItem = history.first(where: { $0.path == path }) {
            return historyItem.lastPageIndex
        }
        if let favoriteItem = favorites.first(where: { $0.path == path }) {
            return favoriteItem.lastPageIndex
        }
        return 0
    }

    private func restoreReadingLayout(for url: URL) {
        let path = url.path
        let item = history.first(where: { $0.path == path })
            ?? favorites.first(where: { $0.path == path })
        if let savedDoublePage = item?.isDoublePage {
            isDoublePage = savedDoublePage
        }
        if let rawValue = item?.readingDirectionRawValue,
           let savedDirection = ReadingDirection(rawValue: rawValue) {
            readingDirection = savedDirection
        }
    }

    private func saveCurrentReadingProgress() {
        guard let sourceURL, !pages.isEmpty else { return }
        recordHistory(sourceURL, currentIndex: currentIndex, pageCount: pages.count)
        let path = sourceURL.path
        if let favoriteIndex = favorites.firstIndex(where: { $0.path == path }) {
            favorites[favoriteIndex].lastPageIndex = currentIndex
            favorites[favoriteIndex].pageCount = pages.count
            favorites[favoriteIndex].isDoublePage = isDoublePage
            favorites[favoriteIndex].readingDirectionRawValue = readingDirection.rawValue
            favorites[favoriteIndex].addedAt = Date()
            saveFavorites()
        }
    }

    private func recordHistory(_ url: URL, currentIndex: Int, pageCount: Int) {
        guard !isPrivateBrowsing else { return }
        let path = url.path
        history.removeAll { $0.path == path }
        history.insert(
            FavoriteItem(
                id: UUID(),
                name: url.lastPathComponent,
                path: path,
                addedAt: Date(),
                lastPageIndex: currentIndex,
                pageCount: pageCount,
                isDoublePage: isDoublePage,
                readingDirectionRawValue: readingDirection.rawValue
            ),
            at: 0
        )
        if history.count > 100 {
            history.removeLast(history.count - 100)
        }
        saveHistory()
    }

    private func loadPages(from url: URL, passwords: [String: String] = [:]) async throws -> [ReaderPage] {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            return try collectPages(in: url)
        }

        let ext = url.pathExtension.lowercased()
        if ext == "pdf" {
            return try collectPDFPages(url)
        }
        if supportedImages.contains(ext) {
            return [ReaderPage(displayName: url.lastPathComponent, sourceURL: url, sortKey: url.path, loader: .image(url))]
        }
        if supportedArchives.contains(ext) {
            return try await loadArchivePages(
                from: url,
                passwords: passwords,
                fallbackPassword: archivePassword(for: url, in: passwords),
                depth: 0
            )
        }
        throw ReaderError.unsupportedFile
    }

    private func loadArchivePages(from url: URL, passwords: [String: String], fallbackPassword: String?, depth: Int) async throws -> [ReaderPage] {
        guard depth < 4 else { throw ReaderError.archiveExtractionFailed }
        let password = archivePassword(for: url, in: passwords) ?? fallbackPassword
        let extracted = try extractArchive(url, password: password)
        await MainActor.run { extractedFolders.append(extracted) }

        let pages = try collectPages(in: extracted)
        if !pages.isEmpty {
            return pages
        }

        let nestedArchives = try collectArchives(in: extracted)
        for archive in nestedArchives {
            do {
                let nestedPages = try await loadArchivePages(
                    from: archive,
                    passwords: passwords,
                    fallbackPassword: password,
                    depth: depth + 1
                )
                if !nestedPages.isEmpty {
                    return nestedPages
                }
            } catch ReaderError.archiveNeedsPassword(let targetURL) {
                throw ReaderError.archiveNeedsPassword(targetURL)
            } catch ReaderError.archiveExtractionFailed {
                continue
            } catch ReaderError.missingArchiveTool {
                continue
            }
        }

        throw ReaderError.archiveExtractionFailed
    }

    private func archivePassword(for url: URL, in passwords: [String: String]) -> String? {
        passwords[url.path] ?? passwords[url.lastPathComponent]
    }

    private func rememberArchivePassword(_ password: String, for url: URL, in passwords: inout [String: String]) {
        passwords[url.path] = password
        passwords[url.lastPathComponent] = password
    }

    private func isSupportedArchive(_ url: URL) -> Bool {
        supportedArchives.contains(url.pathExtension.lowercased())
    }

    private func collectPages(in folder: URL) throws -> [ReaderPage] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey, .localizedNameKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var collected: [ReaderPage] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            if values.isDirectory == true { continue }
            let ext = fileURL.pathExtension.lowercased()
            if supportedImages.contains(ext) {
                collected.append(ReaderPage(displayName: fileURL.lastPathComponent, sourceURL: fileURL, sortKey: fileURL.path, loader: .image(fileURL)))
            } else if ext == "pdf" {
                collected.append(contentsOf: try collectPDFPages(fileURL))
            }
        }

        return collected.sorted { lhs, rhs in
            lhs.sortKey.localizedStandardCompare(rhs.sortKey) == .orderedAscending
        }
    }

    private func collectArchives(in folder: URL) throws -> [URL] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var archives: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            if values.isDirectory == true { continue }
            if supportedArchives.contains(fileURL.pathExtension.lowercased()) {
                archives.append(fileURL)
            }
        }
        return archives.sorted {
            $0.path.localizedStandardCompare($1.path) == .orderedAscending
        }
    }

    private func collectPDFPages(_ url: URL) throws -> [ReaderPage] {
        guard let document = PDFDocument(url: url) else { throw ReaderError.unreadablePDF }
        return (0..<document.pageCount).map { index in
            ReaderPage(
                displayName: "\(url.lastPathComponent) · \(index + 1)",
                sourceURL: url,
                sortKey: "\(url.path)#\(String(format: "%06d", index))",
                loader: .pdfPage(url, index)
            )
        }
    }

    private func extractArchive(_ url: URL, password: String? = nil) throws -> URL {
        let ext = url.pathExtension.lowercased()
        let commands = try archiveCommands(for: ext, archive: url, password: password)
        var didTryCommand = false

        for command in commands {
            didTryCommand = true
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("GlassReader-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            if runArchiveCommand(command, destination: destination) {
                return destination
            }

            try? FileManager.default.removeItem(at: destination)
        }

        if didTryCommand {
            throw ReaderError.archiveNeedsPassword(url)
        }
        throw ReaderError.missingArchiveTool(ext.uppercased())
    }

    private func runArchiveCommand(_ command: (executable: String, arguments: [String]), destination: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments.map {
            $0.replacingOccurrences(of: "__DESTINATION__", with: destination.path)
        }
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0 && containsExtractedFiles(in: destination)
    }

    private func archiveCommands(for ext: String, archive: URL, password: String?) throws -> [(executable: String, arguments: [String])] {
        let password = password?.isEmpty == false ? password : nil
        let bundledTools = bundledArchiveToolPaths()
        var commands: [(executable: String, arguments: [String])] = []

        if ext == "zip" || ext == "cbz" {
            if let password {
                if let unzip = firstExistingExecutable(bundledTools.unzip + ["/usr/bin/unzip", "/opt/homebrew/bin/unzip", "/usr/local/bin/unzip"]) {
                    commands.append((unzip, ["-P", password, "-qq", "-o", archive.path, "-d", "__DESTINATION__"]))
                }
                if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
                    commands.append((unar, ["-quiet", "-force-overwrite", "-password", password, "-output-directory", "__DESTINATION__", archive.path]))
                }
                if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
                    commands.append((sevenZip, ["x", "-y", "-p\(password)", "-o__DESTINATION__", archive.path]))
                }
            } else {
                commands.append(("/usr/bin/ditto", ["-x", "-k", archive.path, "__DESTINATION__"]))
                if let unzip = firstExistingExecutable(bundledTools.unzip + ["/usr/bin/unzip", "/opt/homebrew/bin/unzip", "/usr/local/bin/unzip"]) {
                    commands.append((unzip, ["-qq", "-o", archive.path, "-d", "__DESTINATION__"]))
                }
                if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
                    commands.append((unar, ["-quiet", "-force-overwrite", "-output-directory", "__DESTINATION__", archive.path]))
                }
                if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
                    commands.append((sevenZip, ["x", "-y", "-o__DESTINATION__", archive.path]))
                }
            }
            return commands
        }

        if let unar = firstExistingExecutable(bundledTools.unar + ["/opt/homebrew/bin/unar", "/usr/local/bin/unar", "/usr/bin/unar"]) {
            var arguments = ["-quiet", "-force-overwrite"]
            if let password {
                arguments += ["-password", password]
            }
            arguments += ["-output-directory", "__DESTINATION__", archive.path]
            commands.append((unar, arguments))
        }

        if let sevenZip = firstExistingExecutable(bundledTools.sevenZip + ["/opt/homebrew/bin/7zz", "/opt/homebrew/bin/7z", "/usr/local/bin/7zz", "/usr/local/bin/7z"]) {
            var arguments = ["x", "-y", "-o__DESTINATION__"]
            if let password {
                arguments.append("-p\(password)")
            }
            arguments.append(archive.path)
            commands.append((sevenZip, arguments))
        }

        if let bsdtar = firstExistingExecutable(bundledTools.bsdtar + ["/usr/bin/bsdtar", "/usr/bin/tar", "/opt/homebrew/bin/bsdtar", "/usr/local/bin/bsdtar"]) {
            commands.append((bsdtar, ["-xf", archive.path, "-C", "__DESTINATION__"]))
        }

        guard !commands.isEmpty else { throw ReaderError.missingArchiveTool(ext.uppercased()) }
        return commands
    }

    private func containsExtractedFiles(in folder: URL) -> Bool {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else { return false }

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)) else { continue }
            if values.isDirectory == true { continue }
            if values.isRegularFile == true {
                return true
            }
        }
        return false
    }

    private func bundledArchiveToolPaths() -> (sevenZip: [String], unar: [String], unzip: [String], bsdtar: [String]) {
        let folders = [
            Bundle.main.resourceURL,
            Bundle.main.resourceURL?.appendingPathComponent("Tools", isDirectory: true),
            Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS", isDirectory: true)
        ].compactMap { $0 }

        func paths(named names: [String]) -> [String] {
            folders.flatMap { folder in
                names.map { folder.appendingPathComponent($0).path }
            }
        }

        return (
            sevenZip: paths(named: ["7zz", "7z"]),
            unar: paths(named: ["unar"]),
            unzip: paths(named: ["unzip"]),
            bsdtar: paths(named: ["bsdtar", "tar"])
        )
    }

    private func firstExistingExecutable(_ paths: [String]) -> String? {
        paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

}

enum ReaderError: LocalizedError {
    case unsupportedFile
    case unreadablePDF
    case archiveExtractionFailed
    case missingArchiveTool(String)
    case archiveNeedsPassword(URL)

    var errorDescription: String? {
        let language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "GlassReader.language") ?? "") ?? .zh
        switch self {
        case .unsupportedFile:
            return Localizer.text(.unsupportedFile, language)
        case .unreadablePDF:
            return Localizer.text(.unreadablePDF, language)
        case .archiveExtractionFailed:
            return Localizer.text(.archiveExtractionFailed, language)
        case .missingArchiveTool(let format):
            return String(format: Localizer.text(.missingArchiveTool, language), format)
        case .archiveNeedsPassword(let url):
            return String(format: Localizer.text(.archiveNeedsPasswordError, language), url.lastPathComponent)
        }
    }
}

enum ZoomMode: String, CaseIterable, Identifiable {
    case fitScreen = "适应屏幕"
    case fitWidth = "适应宽度"
    case originalSize = "原始大小"
    case fillScreen = "填满屏幕"
    case smartFit = "智能适应"

    var id: String { rawValue }

    private static let storageKey = "GlassReader.zoomMode"

    static var savedDefault: ZoomMode {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        if saved == "适应" { return .fitScreen }
        if saved == "宽度" { return .fitWidth }
        if saved == ZoomMode.smartFit.rawValue { return .fitScreen }
        return saved.flatMap(ZoomMode.init(rawValue:)) ?? .fitScreen
    }

    func resolved(forAspectRatio aspectRatio: CGFloat) -> ZoomMode {
        guard self == .smartFit else { return self }
        if aspectRatio < 0.85 {
            return .fitWidth
        }
        return .fitScreen
    }
}

struct ContentView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var keyMonitor: Any?

    var body: some View {
        ZStack(alignment: .topLeading) {
            LiquidBackground()
            HStack(spacing: 0) {
                if !library.isFocusMode && !library.isImmersiveMode {
                    SidebarView()
                        .frame(width: sidebarWidth)
                        .zIndex(2)
                    Divider()
                        .opacity(0.35)
                        .zIndex(2)
                }
                ReaderView()
                    .clipped()
                    .zIndex(1)
            }

            if library.isImmersiveMode && library.showsImmersiveSidebar {
                SidebarView()
                    .frame(width: sidebarWidth)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                    .padding(.leading, 14)
                    .padding(.top, 64)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .zIndex(7)
            }

            if !library.isFocusMode && !library.isImmersiveMode {
                Button {
                    library.toggleFocusMode()
                } label: {
                    Image(systemName: "rectangle.inset.filled")
                }
                .buttonStyle(ToolbarPillButtonStyle())
                .help(library.t(.hideSidebar))
                .padding(.leading, 18)
                .padding(.top, 16)
                .zIndex(8)
            }

            if let snapshot = library.transitionSnapshot {
                Image(nsImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.identity)
                    .zIndex(20)
            }
        }
        .sheet(item: $library.archivePasswordPrompt) { prompt in
            ArchivePasswordView(prompt: prompt)
                .environmentObject(library)
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            library.openDroppedItemProviders(providers)
        }
        .onAppear {
            guard keyMonitor == nil else { return }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if library.archivePasswordPrompt != nil {
                    return event
                }
                if NSApp.keyWindow?.firstResponder is NSTextView {
                    return event
                }
                return library.handleKeyEvent(event) ? nil : event
            }
        }
        .onDisappear {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
            keyMonitor = nil
        }
    }
}

struct ArchivePasswordView: View {
    @EnvironmentObject private var library: ReaderLibrary
    let prompt: ArchivePasswordPrompt
    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(library.t(.passwordTitle))
                    .font(.title3.weight(.semibold))
                Text(prompt.url.lastPathComponent)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(prompt.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SecureField(library.t(.passwordPlaceholder), text: $password)
                .textFieldStyle(.roundedBorder)
                .onSubmit(openWithPassword)

            HStack {
                Spacer()
                Button(library.t(.cancel)) {
                    library.cancelArchivePassword()
                }
                Button(library.t(.open)) {
                    openWithPassword()
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 380)
    }

    private func openWithPassword() {
        guard !password.isEmpty else { return }
        library.submitArchivePassword(prompt, password: password)
    }
}

private let sidebarWidth: CGFloat = 270
private let sidebarSettingControlWidth: CGFloat = 136

struct ViewSettingRow<Control: View>: View {
    let title: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
            control
                .frame(width: sidebarSettingControlWidth, alignment: .trailing)
        }
    }
}

struct SidebarFixedDropdown<Option: Hashable>: View {
    let title: String
    let options: [Option]
    let optionTitle: (Option) -> String
    let select: (Option) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(optionTitle(option)) {
                    select(option)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .frame(width: sidebarSettingControlWidth, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}

struct SidebarView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var listMode: SidebarListMode = .favorites

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Spacer(minLength: 48)
                VStack(alignment: .trailing, spacing: 5) {
                    Text("GlassReader")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text(library.t(.tagline))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Button {
                library.openWithPanel()
            } label: {
                Label(library.t(.openLocalFile), systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 10) {
                Text(library.t(.view))
                    .font(.headline)

                ViewSettingRow(title: library.t(.doublePage)) {
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { library.isDoublePage },
                            set: { newValue in
                                if library.isDoublePage != newValue {
                                    library.toggleDoublePageMode()
                                }
                            }
                        )
                    )
                    .labelsHidden()
                    .frame(width: sidebarSettingControlWidth, alignment: .trailing)
                }

                ViewSettingRow(title: library.t(.direction)) {
                    SidebarFixedDropdown(
                        title: library.readingDirectionTitle(library.readingDirection),
                        options: ReadingDirection.allCases,
                        optionTitle: { library.readingDirectionTitle($0) },
                        select: { library.setReadingDirection($0) }
                    )
                }

                ViewSettingRow(title: library.t(.zoom)) {
                    SidebarFixedDropdown(
                        title: library.zoomModeTitle(library.zoomMode),
                        options: ZoomMode.allCases,
                        optionTitle: { library.zoomModeTitle($0) },
                        select: { library.zoomMode = $0 }
                    )
                }

                ViewSettingRow(title: "Language") {
                    SidebarFixedDropdown(
                        title: library.language.nativeName,
                        options: AppLanguage.allCases,
                        optionTitle: { $0.nativeName },
                        select: { library.language = $0 }
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(library.t(.slideshow))
                        .font(.headline)
                    Spacer()
                    Button {
                        library.toggleSlideshow()
                    } label: {
                        Image(systemName: library.isSlideshowRunning ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderless)
                }
                HStack {
                    FlatProgressSlider(
                        value: library.slideshowInterval,
                        range: 1...20,
                        step: 1,
                        onChange: { library.updateSlideshowInterval($0) }
                    )
                    .frame(height: 24)
                    Text("\(Int(library.slideshowInterval))s")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 34, alignment: .trailing)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Picker("列表", selection: $listMode) {
                        ForEach(SidebarListMode.allCases) { mode in
                            Text(library.sidebarModeTitle(mode)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    Spacer()
                    if listMode == .favorites {
                        Button {
                            library.toggleFavoriteCurrentSource()
                        } label: {
                            Image(systemName: library.isCurrentSourceFavorite() ? "star.fill" : "star")
                        }
                        .buttonStyle(.borderless)
                        .disabled(library.sourceURL == nil)
                        .help(library.isCurrentSourceFavorite() ? library.t(.unfavoriteCurrent) : library.t(.favoriteCurrent))
                    } else {
                        HStack(spacing: 4) {
                            Button {
                                library.togglePrivateBrowsing()
                            } label: {
                                Image(systemName: library.isPrivateBrowsing ? "eye.slash.fill" : "eye")
                            }
                            .buttonStyle(.borderless)
                            .help(library.isPrivateBrowsing ? library.t(.privateOffHelp) : library.t(.privateOnHelp))

                            Button {
                                library.clearHistory()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .disabled(library.history.isEmpty)
                            .help(library.t(.clearHistory))
                        }
                    }
                }

                if currentItems.isEmpty {
                    Text(emptyText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(currentItems) { item in
                                FavoriteRow(
                                    item: item,
                                    openAction: { open(item) },
                                    removeAction: { remove(item) }
                                )
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(20)
        .background(.thinMaterial)
    }

    private var currentItems: [FavoriteItem] {
        listMode == .favorites ? library.favorites : library.history
    }

    private var emptyText: String {
        switch listMode {
        case .favorites:
            return library.t(.favoriteEmpty)
        case .history:
            return library.isPrivateBrowsing ? library.t(.privateBrowsingEmpty) : library.t(.historyEmpty)
        }
    }

    private func open(_ item: FavoriteItem) {
        listMode == .favorites ? library.openFavorite(item) : library.openHistory(item)
    }

    private func remove(_ item: FavoriteItem) {
        listMode == .favorites ? library.removeFavorite(item) : library.removeHistory(item)
    }
}

struct FavoriteRow: View {
    @EnvironmentObject private var library: ReaderLibrary
    let item: FavoriteItem
    let openAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .lineLimit(1)
                    .font(.subheadline.weight(.medium))
                Text(item.path)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if item.pageCount > 0 {
                    Text(library.format(.lastRead, "\(item.lastPageIndex + 1)", "\(item.pageCount)"))
                        .lineLimit(1)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                openAction()
            }

            Button(action: removeAction) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ReaderView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var showsTopOverlay = false
    @State private var showsBottomOverlay = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    if !library.isImmersiveMode || showsTopOverlay {
                        ToolbarView()
                            .padding(.horizontal, 22)
                            .padding(.vertical, 14)
                            .background(library.isImmersiveMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ZStack {
                        if library.pages.isEmpty {
                            EmptyReaderState()
                        } else {
                            SpreadStage()
                                .padding(.horizontal, library.isFocusMode ? 0 : 8)
                                .padding(.vertical, library.isFocusMode ? 0 : 6)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !library.isFocusMode || showsBottomOverlay {
                        PageStrip(compact: library.isFocusMode)
                            .frame(height: library.isFocusMode ? 44 : 34)
                            .padding(.horizontal, library.isFocusMode ? 80 : 20)
                            .padding(.bottom, library.isFocusMode ? 18 : 10)
                            .background(library.isFocusMode ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.clear))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .onContinuousHover { phase in
                guard library.isFocusMode else { return }
                switch phase {
                case .active(let location):
                    showsTopOverlay = library.keepsTopOverlayOpen || location.y < 88
                    showsBottomOverlay = location.y > proxy.size.height - 96
                case .ended:
                    showsTopOverlay = library.keepsTopOverlayOpen
                    showsBottomOverlay = false
                }
            }
            .onChange(of: library.keepsTopOverlayOpen) { _, keepOpen in
                if keepOpen {
                    showsTopOverlay = true
                }
            }
        }
        .animation(.easeOut(duration: 0.16), value: showsTopOverlay)
        .animation(.easeOut(duration: 0.16), value: showsBottomOverlay)
    }
}

struct ToolbarView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var showsShortcuts = false
    @State private var showsThumbnails = false

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                if library.isFocusMode {
                    Button {
                        library.toggleFocusMode()
                    } label: {
                        Image(systemName: (library.isImmersiveMode && library.showsImmersiveSidebar) ? "rectangle.inset.filled" : "sidebar.leading")
                    }
                    .help((library.isImmersiveMode && library.showsImmersiveSidebar) ? library.t(.hideSidebar) : library.t(.showSidebar))
                }

                Picker(library.t(.zoom), selection: $library.zoomMode) {
                    ForEach(ZoomMode.allCases) { mode in
                        Text(library.zoomModeTitle(mode)).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 112)
                .help(library.t(.zoomHelp))

                Button { library.rematchSpreadBackward() } label: {
                    Image(systemName: "arrowtriangle.left.fill")
                }
                .help(library.t(.spreadBackHelp))

                Button { library.rematchSpreadForward() } label: {
                    Image(systemName: "arrowtriangle.right.fill")
                }
                .help(library.t(.spreadForwardHelp))

                Divider()
                    .frame(height: 24)

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        library.toggleDoublePageMode()
                    }
                } label: {
                    PageModeGlyph(pageCount: library.isDoublePage ? 2 : 1)
                }
                .help(library.isDoublePage ? library.t(.switchSingle) : library.t(.switchDouble))

                Button {
                    withAnimation(.snappy(duration: 0.18)) {
                        library.toggleReadingDirection()
                    }
                } label: {
                    DirectionModeGlyph(direction: library.readingDirection)
                }
                .help(library.readingDirection == .leftToRight ? library.t(.switchManga) : library.t(.switchNormal))

                Button { library.toggleSlideshow() } label: {
                    Image(systemName: library.isSlideshowRunning ? "pause.circle.fill" : "play.circle")
                }
                .help(library.t(.slideshowHelp))
            }
            .layoutPriority(3)

            VStack(alignment: .leading, spacing: 2) {
                Text(library.sourceURL?.lastPathComponent ?? library.t(.unopened))
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(library.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            HStack(spacing: 6) {
                if library.pageCount > 0 {
                    Text("\(library.currentIndex + 1) / \(library.pageCount)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(minWidth: 58, alignment: .trailing)
                }

                Button {
                    showsThumbnails.toggle()
                } label: {
                    Image(systemName: "rectangle.grid.1x2")
                }
                .help(library.t(.thumbnails))
                .popover(isPresented: $showsThumbnails, arrowEdge: .bottom) {
                    ThumbnailPreviewPanel()
                        .environmentObject(library)
                }
                .onChange(of: showsThumbnails) { _, isPresented in
                    library.keepsTopOverlayOpen = isPresented || showsShortcuts || library.showsImmersiveSidebar
                }

                Button { library.toggleFullScreen() } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help(library.t(.fullscreen))

                Button { library.toggleImmersiveMode() } label: {
                    Image(systemName: "viewfinder")
                }
                .help(library.isImmersiveMode ? library.t(.exitImmersive) : library.t(.immersive))

                Button {
                    showsShortcuts.toggle()
                } label: {
                    Image(systemName: "keyboard")
                }
            .help(library.t(.shortcuts))
            .popover(isPresented: $showsShortcuts, arrowEdge: .bottom) {
                ShortcutPanel()
                    .environmentObject(library)
            }
            .onChange(of: showsShortcuts) { _, isPresented in
                library.keepsTopOverlayOpen = isPresented || showsThumbnails || library.showsImmersiveSidebar
            }
            }
            .layoutPriority(4)
        }
        .buttonStyle(ToolbarPillButtonStyle())
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.18), value: library.isFocusMode)
    }
}

struct ToolbarPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(minWidth: 34)
            .frame(height: 28)
            .padding(.horizontal, 2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Color.primary.opacity(0.16) : Color.primary.opacity(0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct PageModeGlyph: View {
    let pageCount: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(.primary, lineWidth: 1.6)
                .frame(width: 20, height: 16)
            Text("\(pageCount)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
        }
        .frame(width: 24, height: 20)
    }
}

struct DirectionModeGlyph: View {
    let direction: ReadingDirection

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(.primary, lineWidth: 1.6)
                .frame(width: 22, height: 16)
            Image(systemName: direction == .leftToRight ? "arrow.right" : "arrow.left")
                .font(.system(size: 11, weight: .bold))
        }
        .frame(width: 24, height: 20)
    }
}

struct ShortcutPanel: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(library.t(.shortcuts))
                .font(.headline)
            ShortcutRow(systemImage: "folder", title: library.t(.openLocalFile), keys: "⌘O") {
                library.openWithPanel()
            }
            ShortcutRow(systemImage: "xmark.circle", title: library.t(.shortcutClear), keys: "⌘W") {
                library.clearDocument()
            }
            ShortcutRow(systemImage: library.isCurrentSourceFavorite() ? "star.fill" : "star", title: library.isCurrentSourceFavorite() ? library.t(.unfavoriteCurrent) : library.t(.favoriteCurrent), keys: "⌘D") {
                library.toggleFavoriteCurrentSource()
            }
            ShortcutRow(systemImage: library.isPrivateBrowsing ? "eye.slash.fill" : "eye", title: library.t(.shortcutPrivate), keys: "点击") {
                library.togglePrivateBrowsing()
            }
            ShortcutRow(systemImage: "arrowtriangle.left.fill", title: library.t(.shortcutSpreadBack), keys: "⌘←") {
                library.rematchSpreadBackward()
            }
            ShortcutRow(systemImage: "arrowtriangle.right.fill", title: library.t(.shortcutSpreadForward), keys: "⌘→") {
                library.rematchSpreadForward()
            }
            ShortcutRow(title: library.t(.shortcutPageMode), keys: "⌘2") {
                PageModeGlyph(pageCount: library.isDoublePage ? 2 : 1)
            } action: {
                withAnimation(.snappy(duration: 0.18)) {
                    library.toggleDoublePageMode()
                }
            }
            ShortcutRow(title: library.t(.shortcutDirection), keys: "⌘L") {
                DirectionModeGlyph(direction: library.readingDirection)
            } action: {
                withAnimation(.snappy(duration: 0.18)) {
                    library.toggleReadingDirection()
                }
            }
            ShortcutRow(systemImage: library.showsPageBadges ? "number.circle.fill" : "number.circle", title: library.t(.pageDisplayToggle), keys: "⌘P") {
                library.showsPageBadges.toggle()
            }
            ShortcutRow(systemImage: library.isSlideshowRunning ? "pause.circle.fill" : "play.circle", title: library.t(.slideshowHelp), keys: "Space") {
                library.toggleSlideshow()
            }
            ShortcutRow(systemImage: "arrow.up.left.and.arrow.down.right", title: library.t(.fullscreen), keys: "⌃⌘F") {
                library.toggleFullScreen()
            }
            ShortcutRow(systemImage: "viewfinder", title: library.t(.immersive), keys: "⇧⌘F") {
                library.toggleImmersiveMode()
            }
            ShortcutRow(systemImage: "escape", title: library.t(.exitImmersive), keys: "Esc") {
                library.exitImmersiveMode()
            }
            Divider()
                .padding(.vertical, 2)
            Text(library.t(.author))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(width: 340)
    }
}

struct ShortcutRow<Icon: View>: View {
    let title: String
    let keys: String
    @ViewBuilder var icon: Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                icon
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Text(keys)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension ShortcutRow where Icon == Image {
    init(systemImage: String, title: String, keys: String, action: @escaping () -> Void) {
        self.title = title
        self.keys = keys
        self.icon = Image(systemName: systemImage)
        self.action = action
    }
}

struct ThumbnailPreviewPanel: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pageEntries, id: \.page.id) { entry in
                        Button {
                            library.jump(to: entry.index)
                        } label: {
                            HStack(spacing: 10) {
                                PageImage(loader: entry.page.loader, maxPixelSize: 360)
                                    .scaledToFit()
                                    .frame(width: 86, height: 116)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(entry.index + 1)")
                                        .font(.headline.monospacedDigit())
                                    Text(entry.page.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(
                                entry.index == library.currentIndex ? AnyShapeStyle(.tint.opacity(0.22)) : AnyShapeStyle(.clear),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(entry.index)
                    }
                }
                .padding(12)
            }
            .frame(width: 280, height: 480)
            .onAppear {
                reader.scrollTo(library.currentIndex, anchor: .center)
            }
        }
    }

    private var pageEntries: [(index: Int, page: ReaderPage)] {
        let entries = Array(library.pages.enumerated()).map { (index: $0.offset, page: $0.element) }
        return library.readingDirection == .rightToLeft ? Array(entries.reversed()) : entries
    }
}

struct SpreadStage: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let pages = library.visiblePages
            let totalWidth = pages.reduce(CGFloat.zero) {
                $0 + pageWidth($1, stageSize: proxy.size, visibleCount: pages.count)
            }

            HStack(spacing: 0) {
                ForEach(pages) { page in
                    PageSurface(page: page)
                        .frame(
                            width: pageWidth(page, stageSize: proxy.size, visibleCount: pages.count),
                            height: height
                        )
                        .overlay(alignment: .bottomTrailing) {
                            if library.showsPageBadges, let index = library.displayIndex(for: page) {
                                Text("\(index)")
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .padding(10)
                            }
                        }
                }
            }
            .frame(width: totalWidth, height: height)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if value.location.x < proxy.size.width / 2 {
                            library.turnLeft()
                        } else {
                            library.turnRight()
                        }
                    }
            )
            .clipped()
        }
    }

    private func pageWidth(_ page: ReaderPage, stageSize: CGSize, visibleCount: Int) -> CGFloat {
        let slotWidth = max(1, stageSize.width / CGFloat(max(visibleCount, 1)))
        let aspect = page.loader.aspectRatio
        switch library.zoomMode.resolved(forAspectRatio: aspect) {
        case .smartFit:
            return slotWidth
        case .fitScreen:
            return max(1, stageSize.height * aspect)
        case .fitWidth:
            return slotWidth
        case .originalSize:
            return max(1, page.loader.pointSize.width)
        case .fillScreen:
            return slotWidth
        }
    }
}

struct PageSurface: View {
    @EnvironmentObject private var library: ReaderLibrary
    let page: ReaderPage

    var body: some View {
        GeometryReader { proxy in
            let mode = library.zoomMode.resolved(forAspectRatio: page.loader.aspectRatio)
            content(mode: mode, size: proxy.size)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func content(mode: ZoomMode, size: CGSize) -> some View {
        switch mode {
        case .smartFit:
            fitScreenContent(size: size)
        case .fitScreen:
            fitScreenContent(size: size)
        case .fitWidth:
            ScrollView(.vertical, showsIndicators: false) {
                PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
                    .scaledToFit()
                    .frame(width: max(size.width, 1), alignment: .top)
            }
        case .originalSize:
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: page.loader.pointSize))
                    .scaledToFit()
                    .frame(
                        width: max(page.loader.pointSize.width, 1),
                        height: max(page.loader.pointSize.height, 1)
                    )
            }
        case .fillScreen:
            PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
                .scaledToFill()
                .frame(width: max(size.width, 1), height: max(size.height, 1))
                .clipped()
        }
    }

    private func fitScreenContent(size: CGSize) -> some View {
        PageImage(loader: page.loader, maxPixelSize: renderPixelSize(in: size))
            .scaledToFit()
            .frame(width: max(size.width, 1), height: max(size.height, 1), alignment: .center)
    }

    private func renderPixelSize(in size: CGSize) -> CGFloat {
        let screenScale = NSScreen.main?.backingScaleFactor ?? 2
        let target = max(size.width, size.height) * screenScale
        let rounded = ceil(target / 256) * 256
        return min(3072, max(1280, rounded))
    }
}

extension PageLoader {
    @MainActor
    var aspectRatio: CGFloat {
        switch self {
        case .image(let url):
            return ImageFileLoader.aspectRatio(for: url) ?? 0.707
        case .pdfPage(let url, let index):
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: index) else { return 0.707 }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.height > 0 else { return 0.707 }
            return bounds.width / bounds.height
        }
    }

    @MainActor
    var pointSize: CGSize {
        switch self {
        case .image(let url):
            let pixelSize = ImageFileLoader.pixelSize(for: url) ?? CGSize(width: 1200, height: 1600)
            let scale = NSScreen.main?.backingScaleFactor ?? 2
            return CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)
        case .pdfPage(let url, let index):
            guard let document = PDFDocument(url: url),
                  let page = document.page(at: index) else {
                return CGSize(width: 800, height: 1100)
            }
            return page.bounds(for: .mediaBox).size
        }
    }
}

@MainActor
enum ImageFileLoader {
    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 320 * 1024 * 1024
        return cache
    }()

    static func aspectRatio(for url: URL) -> CGFloat? {
        guard let size = pixelSize(for: url), size.height > 0 else { return nil }
        return size.width / size.height
    }

    static func pixelSize(for url: URL) -> CGSize? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        let width = numericCGFloat(properties[kCGImagePropertyPixelWidth])
        let height = numericCGFloat(properties[kCGImagePropertyPixelHeight])
        guard let width, let height, height > 0 else { return nil }
        return CGSize(width: width, height: height)
    }

    private static func numericCGFloat(_ value: Any?) -> CGFloat? {
        if let value = value as? CGFloat {
            return value
        }
        if let value = value as? NSNumber {
            return CGFloat(truncating: value)
        }
        if let value = value as? Double {
            return CGFloat(value)
        }
        if let value = value as? Int {
            return CGFloat(value)
        }
        return nil
    }

    static func image(for url: URL, maxPixelSize: CGFloat = 4096) -> NSImage? {
        let key = "\(url.path)#image#\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        cache.setObject(image, forKey: key, cost: cgImage.width * cgImage.height * 4)
        return image
    }

    static func pdfImage(for url: URL, pageIndex: Int, maxPixelSize: CGFloat) -> NSImage? {
        let key = "\(url.path)#pdf#\(pageIndex)#\(Int(maxPixelSize))" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        guard let document = PDFDocument(url: url),
              let page = document.page(at: pageIndex) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(maxPixelSize / max(bounds.width, bounds.height), 2)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
        image.unlockFocus()
        cache.setObject(image, forKey: key, cost: Int(size.width * size.height * 4))
        return image
    }
}

struct PageImage: View {
    @EnvironmentObject private var library: ReaderLibrary
    let loader: PageLoader
    var maxPixelSize: CGFloat = 4096

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(nsImage: image)
                    .resizable()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text(library.t(.unablePage))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func loadImage() -> NSImage? {
        switch loader {
        case .image(let url):
            return ImageFileLoader.image(for: url, maxPixelSize: maxPixelSize)
        case .pdfPage(let url, let index):
            return ImageFileLoader.pdfImage(for: url, pageIndex: index, maxPixelSize: maxPixelSize)
        }
    }
}

struct PageStrip: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var sliderValue = 0.0
    var compact = false

    var body: some View {
        if library.pages.isEmpty {
            EmptyView()
        } else if library.pageCount <= 1 {
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(height: 6)
        } else {
            FlatProgressSlider(
                value: sliderValue,
                range: 0...Double(library.pageCount - 1),
                step: 1,
                isRightToLeft: library.readingDirection == .rightToLeft,
                onEditingChanged: { editing in
                    if editing {
                        sliderValue = Double(library.currentIndex)
                    }
                },
                onChange: { value in
                    jumpWithoutAnimation(to: Int(value.rounded()))
                }
            )
            .frame(height: 24)
            .onAppear {
                sliderValue = Double(library.currentIndex)
            }
            .onChange(of: library.currentIndex) { _, newValue in
                sliderValue = Double(newValue)
            }
        }
    }

    private func jumpWithoutAnimation(to index: Int) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            library.jump(to: index)
        }
    }
}

struct FlatProgressSlider: View {
    let value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var isRightToLeft = false
    var onEditingChanged: (Bool) -> Void = { _ in }
    let onChange: (Double) -> Void

    @State private var draftValue: Double?
    @State private var isDragging = false

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let activeValue = clamped(draftValue ?? value)
            let progress = progress(for: activeValue)
            let thumbCenter = width * (isRightToLeft ? 1 - progress : progress)
            let fillOffset = isRightToLeft ? thumbCenter : 0
            let fillWidth = isRightToLeft ? width - thumbCenter : thumbCenter

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.22))
                    .frame(height: 6)
                Capsule()
                    .fill(.tint)
                    .frame(width: fillWidth, height: 6)
                    .offset(x: fillOffset)
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                    .offset(x: min(max(thumbCenter - 9, 0), max(width - 18, 0)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        draftValue = valueFromDrag(x: drag.location.x, width: width)
                    }
                    .onEnded { drag in
                        let finalValue = valueFromDrag(x: drag.location.x, width: width)
                        draftValue = nil
                        isDragging = false
                        onChange(finalValue)
                        onEditingChanged(false)
                    }
            )
        }
    }

    private func clamped(_ rawValue: Double) -> Double {
        min(max(rawValue, range.lowerBound), range.upperBound)
    }

    private func progress(for rawValue: Double) -> Double {
        let span = max(range.upperBound - range.lowerBound, 1)
        return min(max((rawValue - range.lowerBound) / span, 0), 1)
    }

    private func valueFromDrag(x: CGFloat, width: CGFloat) -> Double {
        let rawProgress = min(max(x / max(width, 1), 0), 1)
        let progress = isRightToLeft ? 1 - rawProgress : rawProgress
        let rawValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(progress)
        guard step > 0 else { return clamped(rawValue) }
        let stepped = (rawValue / step).rounded() * step
        return clamped(stepped)
    }
}

struct EmptyReaderState: View {
    @EnvironmentObject private var library: ReaderLibrary

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.pages")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.secondary)
            Text(library.t(.emptyTitle))
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
            Text(library.t(.emptySubtitle))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                library.openWithPanel()
            } label: {
                Label(library.t(.chooseFile), systemImage: "folder.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(34)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct LiquidBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(red: 0.86, green: 0.91, blue: 0.95),
                Color(red: 0.94, green: 0.94, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
