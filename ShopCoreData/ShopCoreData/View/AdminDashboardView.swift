//
//  AdminDashboardView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI
import CloudKit

/// Admin-Dashboard für den Künstler.
/// Geschützt durch einen 4-stelligen PIN. Der PIN wird beim ersten Start gesetzt
/// und in der Keychain gespeichert.
struct AdminDashboardView: View {
    @ObservedObject var productViewModel: ProductViewModel
    @ObservedObject var orderViewModel: OrderViewModel
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var isAuthenticated = false
    @State private var pinInput = ""
    @State private var isSettingPin = false
    @State private var confirmPin = ""
    @State private var pinStep: PinStep = .enter
    @State private var showPinError = false

    private enum PinStep {
        case enter, confirm
    }

    /// Prüft ob bereits ein PIN gesetzt wurde.
    private var hasStoredPin: Bool {
        AtelierPinManager.hasPin
    }

    var body: some View {
        if isAuthenticated {
            dashboardContent
        } else {
            pinEntryView
        }
    }

    // MARK: - PIN-Eingabe

    private var pinEntryView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.smokyQuartz)

            Text(isSettingPin ? "Atelier-PIN festlegen" : "Atelier")
                .font(.galleryTitle)
                .foregroundColor(.softWhite)

            Text(pinStepDescription)
                .font(.galleryBody)
                .foregroundColor(.gallerySecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // PIN-Punkte
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.smokyQuartz : Color.galleryChipBackground)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.galleryDivider, lineWidth: 1)
                        )
                }
            }
            .padding(.vertical, 8)

            if showPinError {
                Text(isSettingPin ? "PINs stimmen nicht überein" : "Falscher PIN")
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySold)
                    .transition(.opacity)
            }

            // Nummernpad
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 16), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { digit in
                    PinButton(label: "\(digit)") {
                        appendDigit("\(digit)")
                    }
                }
                // Leeres Feld links
                Color.clear.frame(width: 72, height: 72)

                PinButton(label: "0") {
                    appendDigit("0")
                }

                // Löschen-Button rechts
                Button {
                    if !pinInput.isEmpty {
                        pinInput.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.gallerySecondaryText)
                        .frame(width: 72, height: 72)
                }
            }

            Spacer()
        }
        .background(Color.galleryBackground)
        .onAppear {
            isSettingPin = !hasStoredPin
        }
    }

    private var pinStepDescription: String {
        if isSettingPin {
            return pinStep == .enter
                ? "Wähle einen 4-stelligen PIN für den Zugang zum Atelier."
                : "Bestätige deinen PIN."
        }
        return "Gib deinen PIN ein, um das Atelier zu öffnen."
    }

    private func appendDigit(_ digit: String) {
        guard pinInput.count < 4 else { return }
        pinInput += digit
        showPinError = false

        if pinInput.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                handlePinComplete()
            }
        }
    }

    private func handlePinComplete() {
        if isSettingPin {
            if pinStep == .enter {
                // Erster Schritt: PIN merken und bestätigen lassen
                confirmPin = pinInput
                pinInput = ""
                pinStep = .confirm
            } else {
                // Zweiter Schritt: PINs vergleichen
                if pinInput == confirmPin {
                    AtelierPinManager.setPin(pinInput)
                    withAnimation { isAuthenticated = true }
                } else {
                    showPinError = true
                    pinInput = ""
                    pinStep = .enter
                    confirmPin = ""
                }
            }
        } else {
            // Login: PIN prüfen
            if AtelierPinManager.verify(pinInput) {
                withAnimation { isAuthenticated = true }
            } else {
                showPinError = true
                pinInput = ""
            }
        }
    }

    // MARK: - Dashboard

    private var dashboardContent: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CloudKitStatusCard(cloudKitManager: cloudKitManager)

                    SyncActionsCard(
                        cloudKitManager: cloudKitManager,
                        productViewModel: productViewModel
                    )

                    // Bestellverwaltung
                    NavigationLink(destination: AdminOrderManagementView(orderViewModel: orderViewModel)) {
                        AdminQuickCard(
                            icon: "shippingbox",
                            title: "Bestellungen",
                            subtitle: "\(orderViewModel.orders.count) Bestellungen",
                            color: .oxidCopper
                        )
                    }

                    // Gutscheinverwaltung
                    NavigationLink(destination: AdminCouponView()) {
                        AdminQuickCard(
                            icon: "ticket",
                            title: "Gutscheine",
                            subtitle: "Erstellen & verwalten",
                            color: .smokyQuartz
                        )
                    }

                    ProductManagementCard(productViewModel: productViewModel)
                }
                .padding()
            }
            .background(Color.galleryBackground)
            .navigationTitle("Atelier")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { isAuthenticated = false }
                        pinInput = ""
                    } label: {
                        Image(systemName: "lock")
                            .foregroundColor(.smokyQuartz)
                    }
                }
            }
            .task {
                await cloudKitManager.checkAccountStatus()
            }
        }
    }
}

// MARK: - PIN Button

struct PinButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(.softWhite)
                .frame(width: 72, height: 72)
                .background(Color.galleryPanel)
                .clipShape(Circle())
        }
    }
}

// MARK: - PIN Manager (Keychain-basiert)

/// Speichert den Atelier-PIN sicher in der Keychain.
enum AtelierPinManager {
    private static let service = "com.syntax.ShopCoreData.atelierPin"
    private static let account = "atelierPin"

    static var hasPin: Bool {
        loadPin() != nil
    }

    static func setPin(_ pin: String) {
        let data = Data(pin.utf8)

        // Erst löschen falls vorhanden
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Dann speichern
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func verify(_ pin: String) -> Bool {
        guard let stored = loadPin() else { return false }
        return pin == stored
    }

    private static func loadPin() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }
        return pin
    }
}

// MARK: - CloudKit Status Karte

struct CloudKitStatusCard: View {
    @ObservedObject var cloudKitManager: CloudKitManager

    private var statusText: String {
        if !cloudKitManager.isCloudKitConfigured {
            return "Nicht konfiguriert"
        }
        switch cloudKitManager.accountStatus {
        case .available: return "Verbunden"
        case .noAccount: return "Nicht angemeldet"
        case .restricted: return "Eingeschränkt"
        case .couldNotDetermine: return "Unbekannt"
        case .temporarilyUnavailable: return "Vorübergehend nicht verfügbar"
        @unknown default: return "Unbekannt"
        }
    }

    private var statusColor: Color {
        if !cloudKitManager.isCloudKitConfigured {
            return .mutedAmber
        }
        switch cloudKitManager.accountStatus {
        case .available: return .galleryAvailable
        default: return .gallerySold
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("iCloud-Status")
                    .font(.gallerySubtitle)
                    .foregroundColor(.softWhite)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                }
            }

            if let error = cloudKitManager.lastSyncError {
                Text(error)
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySold)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gallerySold.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.galleryPanel)
        .cornerRadius(12)
    }
}

// MARK: - Sync-Aktionen Karte

struct SyncActionsCard: View {
    @ObservedObject var cloudKitManager: CloudKitManager
    @ObservedObject var productViewModel: ProductViewModel
    @State private var showUploadConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CloudKit Sync")
                .font(.gallerySubtitle)
                .foregroundColor(.softWhite)

            // Upload-Button (Künstler)
            Button {
                showUploadConfirm = true
            } label: {
                HStack {
                    if cloudKitManager.isSyncing {
                        ProgressView()
                            .tint(.galleryBackground)
                    } else {
                        Image(systemName: "icloud.and.arrow.up")
                    }
                    Text("Katalog hochladen")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(cloudKitManager.accountStatus == .available ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                .foregroundColor(cloudKitManager.accountStatus == .available ? .galleryBackground : .gallerySecondaryText)
                .cornerRadius(12)
            }
            .disabled(cloudKitManager.isSyncing || cloudKitManager.accountStatus != .available)

            // Download-Button (Kunde)
            Button {
                Task {
                    await cloudKitManager.syncCatalogToLocal()
                    productViewModel.fetchProducts()
                    productViewModel.fetchCategories()
                }
            } label: {
                HStack {
                    if cloudKitManager.isSyncing {
                        ProgressView()
                            .tint(.softWhite)
                    } else {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    Text("Katalog aktualisieren")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.oxidCopper)
                .foregroundColor(.softWhite)
                .cornerRadius(12)
            }
            .disabled(cloudKitManager.isSyncing || cloudKitManager.accountStatus != .available)
        }
        .padding()
        .background(Color.galleryPanel)
        .cornerRadius(12)
        .alert("Katalog hochladen?", isPresented: $showUploadConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Hochladen") {
                Task {
                    await cloudKitManager.uploadEntireCatalog()
                }
            }
        } message: {
            Text("Alle Produkte, Kategorien und Bilder werden in iCloud hochgeladen und für Kunden sichtbar.")
        }
    }
}

// MARK: - Admin Quick Card

struct AdminQuickCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.gallerySubtitle)
                    .foregroundColor(.softWhite)
                Text(subtitle)
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySecondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gallerySecondaryText)
        }
        .padding()
        .background(Color.galleryPanel)
        .cornerRadius(12)
    }
}

// MARK: - Produktverwaltung Karte

struct ProductManagementCard: View {
    @ObservedObject var productViewModel: ProductViewModel

    private let imageManager = ImageStorageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Produkte")
                    .font(.gallerySubtitle)
                    .foregroundColor(.softWhite)
                Spacer()
                Text("\(productViewModel.products.count) Stück")
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySecondaryText)
            }

            ForEach(productViewModel.products, id: \.id) { product in
                NavigationLink(destination: AdminImageUploadView(product: product, viewModel: productViewModel)) {
                    HStack(spacing: 12) {
                        ProductThumbnailView(product: product, size: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.name ?? "")
                                .font(.galleryBody)
                                .fontWeight(.medium)
                                .foregroundColor(.softWhite)
                            Text("\(imageManager.imageCount(for: product)) Bilder")
                                .font(.galleryCaption)
                                .foregroundColor(.gallerySecondaryText)
                        }

                        Spacer()

                        // Bildstatus-Indikator
                        Image(systemName: imageManager.imageCount(for: product) > 0 ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundColor(imageManager.imageCount(for: product) > 0 ? .galleryAvailable : .mutedAmber)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.galleryPanel)
        .cornerRadius(12)
    }
}
