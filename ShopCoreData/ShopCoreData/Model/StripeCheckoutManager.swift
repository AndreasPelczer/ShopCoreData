//
//  StripeCheckoutManager.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import Foundation
import UIKit

/// Verwaltet die Stripe-Anbindung via Payment Links / Checkout Sessions.
///
/// SETUP-ANLEITUNG FÜR DEN AUFTRAGGEBER:
/// 1. Stripe-Account erstellen: https://dashboard.stripe.com/register
/// 2. Publishable Key und Secret Key aus dem Dashboard kopieren
/// 3. Den `publishableKey` unten ersetzen
/// 4. Im Stripe Dashboard → Produkte anlegen (oder Payment Links erstellen)
/// 5. Optional: Webhook-Endpunkt für Bestellstatus-Updates einrichten
///
/// FLOW:
/// App → Safari öffnet Stripe Checkout → Kunde bezahlt → Stripe Redirect → App
///
/// OHNE BACKEND:
/// - Stripe Payment Links können direkt im Dashboard erstellt werden
/// - Die App öffnet den Link in Safari
/// - Nach Bezahlung wird der Kunde zurück zur App geleitet (URL Scheme)
///
/// MIT BACKEND (optional, für Automatisierung):
/// - Server erstellt Checkout Sessions via Stripe API
/// - Webhooks benachrichtigen den Server bei erfolgreicher Zahlung
/// - Server aktualisiert Bestellstatus via CloudKit
enum StripeCheckoutManager {

    // MARK: - Konfiguration

    /// ⚠️ HIER DEN ECHTEN KEY EINSETZEN
    /// Test-Key fängt an mit "pk_test_..."
    /// Live-Key fängt an mit "pk_live_..."
    static let publishableKey = "pk_test_DEIN_KEY_HIER"

    /// URL Scheme für die Rückkehr zur App nach Bezahlung.
    /// Muss in Info.plist unter URL Types registriert werden.
    static let returnURLScheme = "pelczershop"
    static let successURL = "\(returnURLScheme)://payment-success"
    static let cancelURL = "\(returnURLScheme)://payment-cancel"

    /// Ob der echte Key bereits konfiguriert ist.
    static var isConfigured: Bool {
        !publishableKey.contains("DEIN_KEY_HIER") && !publishableKey.isEmpty
    }

    // MARK: - Payment Link öffnen

    /// Öffnet einen Stripe Payment Link in Safari.
    /// Der Auftraggeber erstellt Payment Links im Stripe Dashboard für jedes Produkt
    /// oder einen allgemeinen Link mit dynamischem Betrag.
    ///
    /// - Parameter paymentLinkURL: Die vollständige Stripe Payment Link URL
    ///   z.B. "https://buy.stripe.com/test_abc123"
    static func openPaymentLink(_ paymentLinkURL: String) {
        guard let url = URL(string: paymentLinkURL) else { return }
        UIApplication.shared.open(url)
    }

    /// Erstellt eine Checkout-URL mit vorausgefüllten Kundendaten.
    /// Nutzt Stripe Payment Links mit Query-Parametern.
    ///
    /// - Parameters:
    ///   - baseURL: Die Payment Link URL aus dem Stripe Dashboard
    ///   - email: Kunden-E-Mail (wird vorausgefüllt)
    ///   - amount: Betrag in Cent (nur für Custom Amounts)
    static func buildCheckoutURL(
        baseURL: String,
        email: String? = nil,
        customerName: String? = nil
    ) -> URL? {
        var components = URLComponents(string: baseURL)

        var queryItems: [URLQueryItem] = []
        if let email = email {
            queryItems.append(URLQueryItem(name: "prefilled_email", value: email))
        }
        // Stripe Payment Links unterstützen prefilled_email als Parameter

        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        return components?.url
    }

    // MARK: - Bestellstatus (ohne Backend)

    /// Ohne Backend-Server wird der Bestellstatus manuell im Admin-Bereich verwaltet.
    /// Der Künstler sieht die Bestellung in der App + im Stripe Dashboard
    /// und aktualisiert den Status manuell.
    ///
    /// Mögliche Status-Werte:
    enum PaymentStatus: String {
        case pending = "Ausstehend"          // Checkout geöffnet, noch nicht bezahlt
        case paid = "Bezahlt"                // Stripe meldet Zahlung erfolgreich
        case shipped = "Versendet"           // Künstler hat verpackt und verschickt
        case delivered = "Zugestellt"        // Paket angekommen
        case refunded = "Erstattet"          // Geld zurückerstattet
        case cancelled = "Storniert"         // Bestellung abgebrochen
    }

    /// Bestellbestätigungs-E-Mail vorbereiten (öffnet Mail-App).
    /// Für den Fall, dass der Auftraggeber kein automatisches E-Mail-System hat.
    static func composeOrderConfirmationEmail(
        to email: String,
        orderID: String,
        totalAmount: String,
        productNames: [String]
    ) {
        let subject = "Bestellbestätigung – Pelczer Manufaktur (\(orderID))"
        let body = """
        Vielen Dank für deine Bestellung!

        Bestellnummer: \(orderID)
        Produkte: \(productNames.joined(separator: ", "))
        Gesamtbetrag: \(totalAmount)

        Dein Unikat wird sorgfältig verpackt und versendet.
        Du erhältst eine Versandbenachrichtigung, sobald dein Paket auf dem Weg ist.

        Mit besten Grüßen,
        Pelczer Manufaktur
        """

        let emailString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: emailString) {
            UIApplication.shared.open(url)
        }
    }
}
