# Pelczer Bongs Shop — Setup-Anleitung für den Betreiber

## 1. Stripe-Bezahlung einrichten

### Account erstellen
1. Gehe zu https://dashboard.stripe.com/register
2. E-Mail, Name und Passwort eingeben
3. Unternehmensdaten ausfüllen (Einzelunternehmer/GbR/etc.)
4. Bankverbindung hinterlegen (IBAN) — dahin gehen die Einnahmen
5. Identität verifizieren (Ausweis-Upload)

### API-Key in die App eintragen
1. Im Stripe Dashboard → Entwickler → API-Schlüssel
2. Den **Publishable Key** kopieren (`pk_test_...` für Tests, `pk_live_...` für echte Zahlungen)
3. In Xcode die Datei `Model/StripeCheckoutManager.swift` öffnen
4. Zeile `static let publishableKey = "pk_test_DEIN_KEY_HIER"` ersetzen

### Payment Links erstellen (einfachste Methode, kein Backend)
1. Stripe Dashboard → Zahlungslinks → Neuer Link
2. Produkt anlegen (Name, Preis, Bild)
3. Den generierten Link kopieren (z.B. `https://buy.stripe.com/abc123`)
4. Dieser Link kann in der App geöffnet werden → Kunde bezahlt dort

### Unterstützte Zahlungsarten (automatisch über Stripe)
- Kreditkarte (Visa, Mastercard, Amex)
- Apple Pay (wenn auf dem iPhone konfiguriert)
- Google Pay
- SEPA-Lastschrift
- Klarna (Rechnungskauf / Ratenzahlung)
- Sofortüberweisung / Giropay

### Gebühren
- **1,5% + 0,25€** pro Kartenzahlung (EU)
- **Keine monatlichen Kosten** — nur bei tatsächlichen Verkäufen
- Beispiel: Bei 489€ (Carrara Classic) → ~7,59€ Gebühr → 481,41€ auf deinem Konto

---

## 2. CloudKit (bereits konfiguriert)

CloudKit ist aktiviert und synchronisiert Produkte, Bilder und Kategorien
zwischen deinem Gerät und den Kunden-Geräten.

- **Public Database**: Alle Kunden sehen den Katalog
- **Container**: `iCloud.com.syntax.ShopCoreData`
- **Schema**: Wird automatisch beim ersten Upload erstellt

---

## 3. Rechtliche Pflichten (Deutschland)

### Impressum (Pflicht!)
Muss in der App hinterlegt werden:
```
Pelczer Manufaktur
[Vor- und Nachname]
[Straße und Hausnummer]
[PLZ Ort]
E-Mail: [...]
Telefon: [...]
USt-IdNr: [falls vorhanden]
```

### AGB
Für den Verkauf physischer Waren brauchst du AGB. Empfehlung:
- IT-Recht Kanzlei (ab ~10€/Monat): https://www.it-recht-kanzlei.de
- Oder: Händlerbund (ab ~15€/Monat): https://www.haendlerbund.de
- Beide generieren rechtssichere AGB, Widerrufsbelehrung und Datenschutzerklärung

### Widerrufsrecht
- 14 Tage Widerrufsrecht für Online-Käufe (gesetzlich)
- Muster-Widerrufsbelehrung muss VOR dem Kauf sichtbar sein
- Bei **Unikaten / Sonderanfertigungen** kann das Widerrufsrecht ausgeschlossen sein
  (§ 312g Abs. 2 Nr. 1 BGB), ABER das muss korrekt formuliert sein → Anwalt/Kanzlei

### Datenschutzerklärung (DSGVO)
Pflicht, weil du E-Mail-Adressen und Lieferadressen speicherst.
- Beschreiben welche Daten gespeichert werden
- Rechtsgrundlage: Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO)
- Stripe als Auftragsverarbeiter nennen
- CloudKit/Apple als Auftragsverarbeiter nennen

### Kleinunternehmerregelung (§19 UStG)
Falls Jahresumsatz unter 22.000€:
- Keine Mehrwertsteuer auf Rechnungen
- Statt "inkl. MwSt." schreibst du:
  "Gemäß §19 UStG wird keine Umsatzsteuer berechnet."
- In der App müsste die Anzeige dann angepasst werden

### Gewerbeanmeldung
- Beim zuständigen Gewerbeamt anmelden
- Kosten: ~20-65€ einmalig
- Auch für Nebenerwerb/Hobby-Verkauf nötig

---

## 4. Versand

### Empfehlung für empfindliche Unikate
- DHL Paket (mit Versicherung)
- Für Marmor/Granit: Sperrgutzuschlag beachten (Gewicht!)
- Schokoladen-Bongs: Isolierte Verpackung im Sommer

### Versandkosten
Aktuell in der App auf "Kostenlos" gesetzt.
Kann in `CheckoutView.swift` angepasst werden:
- Pauschal (z.B. 6,90€)
- Nach Gewicht/Material
- Ab bestimmtem Bestellwert kostenlos

---

## 5. App Store Veröffentlichung

### Voraussetzungen
- Apple Developer Account (99€/Jahr): https://developer.apple.com
- App-Icon (1024x1024px)
- Screenshots für iPhone und iPad
- Beschreibungstext und Keywords

### Wichtig für die Review
- Apple verlangt: Physische Waren NICHT über In-App-Purchase
- Stripe/externe Bezahlung ist erlaubt für physische Güter
- Impressum und Datenschutzerklärung müssen verlinkt sein
- App muss ohne Login nutzbar sein (Gastbestellung ✓)

---

## 6. Checkliste vor dem Launch

- [ ] Stripe-Account erstellt und verifiziert
- [ ] API-Key in `StripeCheckoutManager.swift` eingetragen
- [ ] Payment Links für Produkte erstellt
- [ ] Gewerbe angemeldet
- [ ] AGB + Widerrufsbelehrung + Datenschutzerklärung erstellt
- [ ] Impressum in die App integriert
- [ ] Produktfotos über den Atelier-Tab hochgeladen
- [ ] CloudKit-Sync getestet (Upload + Download)
- [ ] Testbestellung durchgeführt (Stripe Test-Modus)
- [ ] Apple Developer Account erstellt
- [ ] App im App Store eingereicht
