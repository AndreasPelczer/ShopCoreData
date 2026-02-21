//
//  AdminImageUploadView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

/// Admin-Ansicht zur Verwaltung der Produktbilder.
/// Ermöglicht das Hinzufügen, Anzeigen und Löschen von Bildern für ein Produkt.
struct AdminImageUploadView: View {
    let product: Product
    @ObservedObject var viewModel: ProductViewModel
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImages: [UIImage] = []
    @State private var capturedImage: UIImage?
    @State private var showDeleteConfirmation = false
    @State private var imageToDelete: ProductImage?

    private var productImages: [ProductImage] {
        viewModel.sortedImages(for: product)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header mit Bildanzahl
                HStack {
                    Text("Produktbilder")
                        .font(.galleryTitle)
                        .foregroundColor(.softWhite)
                    Spacer()
                    Text("\(productImages.count) Bild\(productImages.count == 1 ? "" : "er")")
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                }
                .padding(.horizontal)

                // Vorhandene Bilder als Grid
                if !productImages.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(productImages, id: \.id) { productImage in
                            ZStack(alignment: .topTrailing) {
                                if let thumbnail = viewModel.imageManager.loadThumbnail(from: productImage) {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                        .cornerRadius(8)
                                }

                                // Sortierungsnummer
                                Text("\(productImage.sortOrder + 1)")
                                    .font(.galleryBadge)
                                    .foregroundColor(.softWhite)
                                    .frame(width: 22, height: 22)
                                    .background(Color.galleryBackground.opacity(0.7))
                                    .cornerRadius(11)
                                    .padding(4)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)

                                // Löschen-Button
                                Button {
                                    imageToDelete = productImage
                                    showDeleteConfirmation = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 2)
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Leerer Zustand
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(.gallerySecondaryText.opacity(0.5))

                        Text("Noch keine Bilder vorhanden")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)

                        Text("Füge Fotos aus deiner Bibliothek hinzu\noder nutze die Kamera.")
                            .font(.galleryCaption)
                            .foregroundColor(.gallerySecondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }

                // Aktions-Buttons
                VStack(spacing: 10) {
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Aus Fotobibliothek wählen")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.smokyQuartz)
                        .foregroundColor(.galleryBackground)
                        .cornerRadius(12)
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera")
                                Text("Foto aufnehmen")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.oxidCopper)
                            .foregroundColor(.softWhite)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.galleryBackground)
        .navigationTitle("Bilder — \(product.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImages: $selectedImages)
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(capturedImage: $capturedImage)
        }
        .onChange(of: selectedImages) { _, newImages in
            guard !newImages.isEmpty else { return }
            viewModel.addImages(newImages, to: product)
            selectedImages = []
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let image = newImage else { return }
            viewModel.addImages([image], to: product)
            capturedImage = nil
        }
        .alert("Bild löschen?", isPresented: $showDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) {
                imageToDelete = nil
            }
            Button("Löschen", role: .destructive) {
                if let image = imageToDelete {
                    viewModel.deleteImage(image)
                }
                imageToDelete = nil
            }
        } message: {
            Text("Das Bild wird unwiderruflich entfernt.")
        }
    }
}
