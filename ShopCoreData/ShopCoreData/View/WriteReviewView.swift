//
//  WriteReviewView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

/// Sheet zum Schreiben einer Kundenbewertung mit Sternen, Text und optionalem Foto.
struct WriteReviewView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int = 0
    @State private var reviewText = ""
    @State private var authorName = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary

    private let store = PersistentStore.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Produktname
                    Text(product.name ?? "")
                        .font(.gallerySubtitle)
                        .foregroundColor(.softWhite)

                    // Sterne-Auswahl
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deine Bewertung")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        rating = star
                                    }
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 32))
                                        .foregroundColor(.mutedAmber)
                                }
                            }
                        }
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dein Name (optional)")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)

                        TextField("Anonym", text: $authorName)
                            .padding(12)
                            .background(Color.galleryPanel)
                            .foregroundColor(.softWhite)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.galleryDivider, lineWidth: 1)
                            )
                    }

                    // Bewertungstext
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dein Eindruck")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)

                        TextEditor(text: $reviewText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.galleryPanel)
                            .foregroundColor(.softWhite)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.galleryDivider, lineWidth: 1)
                            )
                    }

                    // Foto hinzufügen
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Foto hinzufügen (optional)")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)

                        if let image = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(8)

                                Button {
                                    selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.softWhite)
                                        .shadow(radius: 4)
                                }
                                .padding(8)
                            }
                        } else {
                            Button {
                                showImagePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Foto auswählen")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.galleryPanel)
                                .foregroundColor(.gallerySecondaryText)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.galleryDivider, lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Absenden-Button
                    Button {
                        saveReview()
                    } label: {
                        Text("Bewertung abschicken")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(rating > 0 ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                            .foregroundColor(rating > 0 ? .galleryBackground : .gallerySecondaryText)
                            .cornerRadius(12)
                    }
                    .disabled(rating == 0)
                }
                .padding()
            }
            .background(Color.galleryBackground)
            .navigationTitle("Bewertung schreiben")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(.smokyQuartz)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage, sourceType: imageSourceType)
            }
        }
    }

    private func saveReview() {
        let review = Review(context: store.context)
        review.id = UUID()
        review.rating = Int16(rating)
        review.text = reviewText.isEmpty ? nil : reviewText
        review.authorName = authorName.isEmpty ? nil : authorName
        review.createdAt = Date()
        review.product = product

        // Foto komprimieren und speichern
        if let image = selectedImage {
            review.photoData = image.jpegData(compressionQuality: 0.7)
        }

        store.save()
        dismiss()
    }
}
