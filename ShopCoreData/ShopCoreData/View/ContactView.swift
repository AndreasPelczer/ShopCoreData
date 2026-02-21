//
//  ContactView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI
import MessageUI

struct ContactView: View {
    @State private var showMailComposer = false
    @State private var showMailUnavailable = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.smokyQuartz)

                        Text("Kontakt & Support")
                            .font(.galleryTitle)
                            .foregroundColor(.softWhite)

                        Text("Fragen zu deiner Bestellung oder unseren Unikaten? Wir helfen dir gerne weiter.")
                            .font(.galleryBody)
                            .foregroundColor(.gallerySecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Kontaktoptionen
                    VStack(spacing: 12) {
                        // E-Mail
                        ContactOptionCard(
                            icon: "envelope.fill",
                            title: "E-Mail",
                            subtitle: "info@pelczer-bongs.de",
                            description: "Antwort innerhalb von 24 Stunden"
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else if let url = URL(string: "mailto:info@pelczer-bongs.de") {
                                UIApplication.shared.open(url)
                            } else {
                                showMailUnavailable = true
                            }
                        }

                        // Telefon
                        ContactOptionCard(
                            icon: "phone.fill",
                            title: "Telefon",
                            subtitle: "+49 123 456 7890",
                            description: "Mo–Fr, 10:00–18:00 Uhr"
                        ) {
                            if let url = URL(string: "tel:+491234567890") {
                                UIApplication.shared.open(url)
                            }
                        }

                        // Instagram
                        ContactOptionCard(
                            icon: "camera.fill",
                            title: "Instagram",
                            subtitle: "@pelczer.bongs",
                            description: "Neueste Werke & Behind the Scenes"
                        ) {
                            if let url = URL(string: "https://instagram.com/pelczer.bongs") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // FAQ
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Häufige Fragen")
                            .font(.gallerySubtitle)
                            .foregroundColor(.softWhite)
                            .padding(.horizontal)

                        FAQItem(
                            question: "Wie lange dauert der Versand?",
                            answer: "Jedes Unikat wird sorgfältig verpackt. Der Versand erfolgt in der Regel innerhalb von 3–5 Werktagen nach Zahlungseingang."
                        )

                        FAQItem(
                            question: "Kann ich meine Bestellung stornieren?",
                            answer: "Eine Stornierung ist bis zum Versand möglich. Kontaktiere uns einfach per E-Mail mit deiner Bestellnummer."
                        )

                        FAQItem(
                            question: "Sind die Produkte wirklich Unikate?",
                            answer: "Ja! Jedes Stück wird von Hand gefertigt und ist einzigartig. Sobald es verkauft ist, gibt es kein zweites identisches Exemplar."
                        )

                        FAQItem(
                            question: "Welche Zahlungsmethoden gibt es?",
                            answer: "Wir akzeptieren Kreditkarte, Apple Pay, SEPA-Lastschrift, Klarna und Giropay über unseren sicheren Zahlungsanbieter Stripe."
                        )
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.galleryBackground)
            .navigationTitle("Kontakt")
            .sheet(isPresented: $showMailComposer) {
                MailComposerView(
                    recipient: "info@pelczer-bongs.de",
                    subject: "Anfrage über die App"
                )
            }
            .alert("E-Mail nicht verfügbar", isPresented: $showMailUnavailable) {
                Button("OK") {}
            } message: {
                Text("Bitte sende eine E-Mail an info@pelczer-bongs.de")
            }
        }
    }
}

// MARK: - Kontaktoption-Karte

struct ContactOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.smokyQuartz)
                    .frame(width: 44, height: 44)
                    .background(Color.smokyQuartz.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.galleryBody)
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                    Text(subtitle)
                        .font(.gallerySubheadline)
                        .foregroundColor(.smokyQuartz)
                    Text(description)
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gallerySecondaryText)
            }
            .padding(14)
            .background(Color.galleryPanel)
            .cornerRadius(12)
        }
    }
}

// MARK: - FAQ Item

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.galleryBody)
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gallerySecondaryText)
                }
                .padding(14)
            }

            if isExpanded {
                Text(answer)
                    .font(.galleryBody)
                    .foregroundColor(.gallerySecondaryText)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
        .background(Color.galleryPanel)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
