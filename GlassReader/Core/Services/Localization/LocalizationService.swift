import AppKit
import ImageIO
import PDFKit
import SwiftUI

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
    case shortcutZoomOut, shortcutZoomIn, shortcutZoomReset
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
        .shortcutZoomOut: [.zh: "缩小当前页面", .en: "Zoom Out Current Page", .ja: "現在のページを縮小", .ko: "현재 페이지 축소", .ru: "Уменьшить страницу", .fr: "Réduire la page actuelle", .de: "Aktuelle Seite verkleinern", .es: "Reducir la página actual"],
        .shortcutZoomIn: [.zh: "放大当前页面", .en: "Zoom In Current Page", .ja: "現在のページを拡大", .ko: "현재 페이지 확대", .ru: "Увеличить страницу", .fr: "Agrandir la page actuelle", .de: "Aktuelle Seite vergrößern", .es: "Ampliar la página actual"],
        .shortcutZoomReset: [.zh: "恢复原始比例", .en: "Reset Page Scale", .ja: "ページ倍率をリセット", .ko: "페이지 배율 초기화", .ru: "Сбросить масштаб", .fr: "Réinitialiser l’échelle", .de: "Seitenskalierung zurücksetzen", .es: "Restablecer escala"],
        .pageDisplayToggle: [.zh: "显示 / 隐藏页码", .en: "Show / Hide Page Numbers", .ja: "ページ番号 表示 / 非表示", .ko: "쪽 번호 표시 / 숨김", .ru: "Показать / скрыть номера", .fr: "Afficher / masquer les pages", .de: "Seitennummern anzeigen", .es: "Mostrar / ocultar páginas"],
        .author: [.zh: "作者：ifuchen", .en: "Author: ifuchen", .ja: "作者：ifuchen", .ko: "作者: ifuchen", .ru: "Автор: ifuchen", .fr: "Auteur : ifuchen", .de: "Autor: ifuchen", .es: "Autor: ifuchen"],
        .turnLeft: [.zh: "向左翻页", .en: "Turn Left", .ja: "左へページ送り", .ko: "왼쪽으로 넘기기", .ru: "Листать влево", .fr: "Page vers la gauche", .de: "Nach links blättern", .es: "Pasar a la izquierda"],
        .turnRight: [.zh: "向右翻页", .en: "Turn Right", .ja: "右へページ送り", .ko: "오른쪽으로 넘기기", .ru: "Листать вправо", .fr: "Page vers la droite", .de: "Nach rechts blättern", .es: "Pasar a la derecha"],
        .rematchSpreadAction: [.zh: "重新匹配跨页", .en: "Rematch Spread", .ja: "見開きを再調整", .ko: "펼침면 다시 맞춤", .ru: "Обновить разворот", .fr: "Réajuster la double-page", .de: "Doppelseite neu anpassen", .es: "Reajustar doble página"]
    ]
}
