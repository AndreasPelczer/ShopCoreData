//
//  Typography.swift
//  ShopCoreData
//
//  Typografie-System: Serif + Neutral Sans + Monospace
//
//  Titel:         Serif (Playfair Display / System Serif)  → Kunstkatalog
//  UI:            System (SF Pro)                          → Neutral Sans
//  Material-Info: Monospaced                               → Laborästhetik
//
//  Für Playfair Display: Font-Dateien ins Projekt einbinden
//  und in Info.plist unter "Fonts provided by application" registrieren.
//  Dann hier `.custom("PlayfairDisplay-Regular", ...)` verwenden.
//

import SwiftUI

extension Font {

    // MARK: - Titel (Serif – Kunstkatalog-Ästhetik)

    /// Großer Titel – z.B. "Pelczer Bongs"
    static let galleryLargeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)

    /// Titel – z.B. Sektionsüberschriften
    static let galleryTitle = Font.system(.title2, design: .serif).weight(.bold)

    /// Untertitel
    static let gallerySubtitle = Font.system(.title3, design: .serif).weight(.semibold)

    // MARK: - UI (SF Pro – Neutral Sans)

    /// Body – Standard-Lesetext
    static let galleryBody = Font.system(.body, design: .default)

    /// Subheadline
    static let gallerySubheadline = Font.system(.subheadline, design: .default)

    /// Caption
    static let galleryCaption = Font.system(.caption, design: .default)

    /// Kleine Badges (UNIKAT etc.)
    static let galleryBadge = Font.system(size: 9, weight: .bold, design: .default)

    // MARK: - Material-Info (Monospace – Laborästhetik)

    /// Material, Höhe, technische Details
    static let galleryMono = Font.system(.subheadline, design: .monospaced)

    /// Kleine technische Angaben
    static let galleryMonoSmall = Font.system(.caption, design: .monospaced)
}
