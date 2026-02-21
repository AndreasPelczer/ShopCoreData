//
//  AdminDashboardView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI
import CloudKit

/// Admin-Dashboard für den Künstler.
/// Bietet Überblick über Produkte, Bildverwaltung und CloudKit-Sync.
struct AdminDashboardView: View {
    @ObservedObject var productViewModel: ProductViewModel
    @StateObject private var cloudKitManager = CloudKitManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // CloudKit Status
                    CloudKitStatusCard(cloudKitManager: cloudKitManager)

                    // Sync-Buttons
                    SyncActionsCard(
                        cloudKitManager: cloudKitManager,
                        productViewModel: productViewModel
                    )

                    // Produktübersicht
                    ProductManagementCard(productViewModel: productViewModel)
                }
                .padding()
            }
            .background(Color.galleryBackground)
            .navigationTitle("Atelier")
            .task {
                await cloudKitManager.checkAccountStatus()
            }
        }
    }
}

// MARK: - CloudKit Status Karte

struct CloudKitStatusCard: View {
    @ObservedObject var cloudKitManager: CloudKitManager

    private var statusText: String {
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
