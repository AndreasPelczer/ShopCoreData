//
//  ColorTheme.swift
//  ShopCoreData
//
//  Galerie / Nachtstudio – Farbsystem
//

import SwiftUI

extension Color {

    // MARK: - Hintergrund

    /// Sehr dunkles Grau – Haupthintergrund (#0E0E11)
    static let galleryBackground = Color(red: 14/255, green: 14/255, blue: 17/255)

    /// Panels / Karten (#1A1A20)
    static let galleryPanel = Color(red: 26/255, green: 26/255, blue: 32/255)

    // MARK: - Akzent & Highlight

    /// Rauchquarz – edel, nicht kitschig (#8E8A7A)
    static let smokyQuartz = Color(red: 142/255, green: 138/255, blue: 122/255)

    /// Oxid-Kupfer – handwerklich (#6B7C74)
    static let oxidCopper = Color(red: 107/255, green: 124/255, blue: 116/255)

    // MARK: - Text

    /// Weiches Weiß – statt reinem Weiß (#EAEAEA)
    static let softWhite = Color(red: 234/255, green: 234/255, blue: 234/255)

    /// Sekundärer Text – gedämpft (#9A9A9A)
    static let gallerySecondaryText = Color(red: 154/255, green: 154/255, blue: 154/255)

    // MARK: - Status

    /// Gedämpftes Bernstein – Warnhinweise / UNIKAT-Badge (#C4943A)
    static let mutedAmber = Color(red: 196/255, green: 148/255, blue: 58/255)

    /// Verfügbar – gedämpftes Grün (#6B9E78)
    static let galleryAvailable = Color(red: 107/255, green: 158/255, blue: 120/255)

    /// Verkauft – gedämpftes Rot (#A0605A)
    static let gallerySold = Color(red: 160/255, green: 96/255, blue: 90/255)

    // MARK: - Oberflächen

    /// Dezente Trennlinie
    static let galleryDivider = Color.white.opacity(0.08)

    /// Icon-Hintergrund / Chips (unselected)
    static let galleryChipBackground = Color.white.opacity(0.06)
}
