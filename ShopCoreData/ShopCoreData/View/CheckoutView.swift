//
//  CheckoutView.swift
//  ShopCoreData
//
//  Created by Andreas Pelczer on 04.01.24.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var cartViewModel: CartViewModel
    @ObservedObject var orderViewModel: OrderViewModel
    @StateObject private var couponViewModel = CouponViewModel()
    @Environment(\.dismiss) private var dismiss

    // Checkout-Schritte
    @State private var currentStep: CheckoutStep = .address
    @State private var orderPlaced = false

    // Kundendaten (Gast — kein Login nötig)
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var zip = ""
    @State private var city = ""
    @State private var acceptedTerms = false

    // Gutscheincode
    @State private var couponCode = ""

    enum CheckoutStep: Int, CaseIterable {
        case address = 0
        case summary = 1
        case payment = 2
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    private var finalTotal: Double {
        let subtotal = cartViewModel.totalPrice
        let discount = couponViewModel.discountForAppliedCoupon(orderTotal: subtotal)
        return max(subtotal - discount, 0)
    }

    private var isAddressValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        !street.trimmingCharacters(in: .whitespaces).isEmpty &&
        !zip.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            if orderPlaced {
                orderConfirmation
            } else {
                VStack(spacing: 0) {
                    // Fortschrittsanzeige
                    StepIndicator(currentStep: currentStep)
                        .padding(.vertical, 12)
                        .padding(.horizontal)

                    // Inhalt je nach Schritt
                    switch currentStep {
                    case .address:
                        addressForm
                    case .summary:
                        orderSummary
                    case .payment:
                        paymentStep
                    }
                }
                .background(Color.galleryBackground)
                .navigationTitle("Bestellung")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { dismiss() }
                            .foregroundColor(.smokyQuartz)
                    }
                }
            }
        }
    }

    // MARK: - Schritt 1: Adresse & Kontakt

    private var addressForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kontaktdaten
                SectionHeader(title: "Kontaktdaten")

                HStack(spacing: 12) {
                    CheckoutTextField(label: "Vorname", text: $firstName, icon: "person")
                    CheckoutTextField(label: "Nachname", text: $lastName, icon: "person")
                }

                CheckoutTextField(label: "E-Mail", text: $email, icon: "envelope", keyboardType: .emailAddress, autocapitalization: .never)

                CheckoutTextField(label: "Telefon (optional)", text: $phone, icon: "phone", keyboardType: .phonePad)

                // Lieferadresse
                SectionHeader(title: "Lieferadresse")

                CheckoutTextField(label: "Straße & Hausnummer", text: $street, icon: "mappin")

                HStack(spacing: 12) {
                    CheckoutTextField(label: "PLZ", text: $zip, icon: "number", keyboardType: .numberPad)
                        .frame(maxWidth: 120)
                    CheckoutTextField(label: "Stadt", text: $city, icon: "building.2")
                }

                // Weiter-Button
                Button {
                    withAnimation { currentStep = .summary }
                } label: {
                    Text("Weiter zur Übersicht")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAddressValid ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                        .foregroundColor(isAddressValid ? .galleryBackground : .gallerySecondaryText)
                        .cornerRadius(12)
                }
                .disabled(!isAddressValid)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Schritt 2: Zusammenfassung

    private var orderSummary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Produkte
                SectionHeader(title: "Deine Produkte")

                ForEach(cartViewModel.cartItems, id: \.id) { item in
                    HStack(spacing: 12) {
                        if let product = item.product {
                            ProductThumbnailView(product: product, size: 50)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.product?.name ?? "")
                                .font(.galleryBody)
                                .fontWeight(.medium)
                                .foregroundColor(.softWhite)
                            if item.product?.isUnique == true {
                                Text("Unikat")
                                    .font(.galleryCaption)
                                    .foregroundColor(.mutedAmber)
                            } else {
                                Text("Menge: \(item.quantity)")
                                    .font(.galleryCaption)
                                    .foregroundColor(.gallerySecondaryText)
                            }
                        }

                        Spacer()

                        let itemTotal = (item.product?.price ?? 0) * Double(item.quantity)
                        Text(currencyFormatter.string(from: NSNumber(value: itemTotal)) ?? "")
                            .fontWeight(.medium)
                            .foregroundColor(.softWhite)
                    }
                    .padding(12)
                    .background(Color.galleryPanel)
                    .cornerRadius(8)
                }

                // Lieferadresse
                SectionHeader(title: "Lieferadresse")

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(firstName) \(lastName)")
                        .fontWeight(.medium)
                        .foregroundColor(.softWhite)
                    Text(street)
                        .foregroundColor(.gallerySecondaryText)
                    Text("\(zip) \(city)")
                        .foregroundColor(.gallerySecondaryText)
                    Text(email)
                        .foregroundColor(.smokyQuartz)
                    if !phone.isEmpty {
                        Text(phone)
                            .foregroundColor(.gallerySecondaryText)
                    }
                }
                .font(.galleryBody)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.galleryPanel)
                .cornerRadius(8)

                // Gutscheincode
                SectionHeader(title: "Gutscheincode")

                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "ticket")
                            .foregroundColor(.gallerySecondaryText)
                            .frame(width: 20)
                        TextField("Code eingeben", text: $couponCode)
                            .foregroundColor(.softWhite)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }
                    .padding(10)
                    .background(Color.galleryPanel)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.galleryDivider, lineWidth: 1)
                    )

                    Button {
                        couponViewModel.validateCoupon(code: couponCode, orderTotal: cartViewModel.totalPrice)
                    } label: {
                        Text("Einlösen")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(couponCode.isEmpty ? Color.gallerySecondaryText.opacity(0.3) : Color.smokyQuartz)
                            .foregroundColor(couponCode.isEmpty ? .gallerySecondaryText : .galleryBackground)
                            .cornerRadius(8)
                    }
                    .disabled(couponCode.isEmpty)
                }

                if let message = couponViewModel.couponMessage {
                    HStack(spacing: 6) {
                        Image(systemName: couponViewModel.couponIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(message)
                    }
                    .font(.galleryCaption)
                    .foregroundColor(couponViewModel.couponIsValid ? .galleryAvailable : .gallerySold)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((couponViewModel.couponIsValid ? Color.galleryAvailable : Color.gallerySold).opacity(0.1))
                    .cornerRadius(6)
                }

                // Kosten
                VStack(spacing: 8) {
                    HStack {
                        Text("Zwischensumme")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        Text(currencyFormatter.string(from: NSNumber(value: cartViewModel.totalPrice)) ?? "")
                            .foregroundColor(.softWhite)
                    }

                    if couponViewModel.couponIsValid {
                        let discount = couponViewModel.discountForAppliedCoupon(orderTotal: cartViewModel.totalPrice)
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "ticket")
                                Text("Gutschein")
                            }
                            .foregroundColor(.galleryAvailable)
                            Spacer()
                            Text("- \(currencyFormatter.string(from: NSNumber(value: discount)) ?? "")")
                                .foregroundColor(.galleryAvailable)
                        }
                    }

                    HStack {
                        Text("Versand")
                            .foregroundColor(.gallerySecondaryText)
                        Spacer()
                        Text("Kostenlos")
                            .foregroundColor(.galleryAvailable)
                    }
                    Rectangle()
                        .fill(Color.galleryDivider)
                        .frame(height: 1)
                    HStack {
                        Text("Gesamt")
                            .font(.gallerySubtitle)
                            .foregroundColor(.softWhite)
                        Spacer()
                        Text(currencyFormatter.string(from: NSNumber(value: finalTotal)) ?? "")
                            .font(.gallerySubtitle)
                            .foregroundColor(.smokyQuartz)
                    }
                    Text("inkl. MwSt.")
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.galleryBody)
                .padding(12)
                .background(Color.galleryPanel)
                .cornerRadius(8)

                // AGB-Checkbox
                Toggle(isOn: $acceptedTerms) {
                    Text("Ich akzeptiere die AGB und Widerrufsbelehrung")
                        .font(.galleryCaption)
                        .foregroundColor(.gallerySecondaryText)
                }
                .toggleStyle(CheckboxToggleStyle())

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation { currentStep = .address }
                    } label: {
                        Text("Zurück")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.galleryPanel)
                            .foregroundColor(.gallerySecondaryText)
                            .cornerRadius(12)
                    }

                    Button {
                        withAnimation { currentStep = .payment }
                        placeOrder()
                    } label: {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Jetzt bezahlen")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(acceptedTerms ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                        .foregroundColor(acceptedTerms ? .galleryBackground : .gallerySecondaryText)
                        .cornerRadius(12)
                    }
                    .disabled(!acceptedTerms)
                }
            }
            .padding()
        }
    }

    // MARK: - Schritt 3: Bezahlung

    private var paymentStep: some View {
        VStack(spacing: 24) {
            Spacer()

            if StripeCheckoutManager.isConfigured {
                // Stripe ist konfiguriert → Weiterleitung
                ProgressView()
                    .tint(.smokyQuartz)
                    .scaleEffect(1.5)

                Text("Weiterleitung zur Bezahlung...")
                    .font(.galleryBody)
                    .foregroundColor(.gallerySecondaryText)

                Text("Du wirst zu unserem sicheren Zahlungsanbieter weitergeleitet.")
                    .font(.galleryCaption)
                    .foregroundColor(.gallerySecondaryText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // Stripe noch nicht konfiguriert → Bestellung trotzdem speichern
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.galleryAvailable)

                Text("Bestellung eingegangen!")
                    .font(.galleryTitle)
                    .foregroundColor(.softWhite)

                Text("Die Bezahlung wird nachträglich per E-Mail vereinbart.\nDu erhältst eine Bestätigung an:")
                    .font(.galleryBody)
                    .foregroundColor(.gallerySecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(email)
                    .font(.galleryBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.smokyQuartz)

                VStack(spacing: 6) {
                    Text("Hinweis für den Betreiber:")
                        .font(.galleryCaption)
                        .fontWeight(.semibold)
                    Text("Stripe ist noch nicht konfiguriert.\nSiehe StripeCheckoutManager.swift")
                        .font(.galleryCaption)
                }
                .foregroundColor(.mutedAmber)
                .padding(12)
                .background(Color.mutedAmber.opacity(0.1))
                .cornerRadius(8)
            }

            Spacer()

            Button("Fertig") {
                orderPlaced = true
                _ = cartViewModel.clearCart()
                dismiss()
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.smokyQuartz)
            .foregroundColor(.galleryBackground)
            .cornerRadius(10)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color.galleryBackground)
    }

    // MARK: - Bestellbestätigung

    private var orderConfirmation: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.galleryAvailable)

            Text("Vielen Dank!")
                .font(.galleryTitle)
                .foregroundColor(.softWhite)

            Text("Deine Bestellung wurde aufgegeben.\nDein Unikat wird sorgfältig verpackt.")
                .font(.galleryBody)
                .foregroundColor(.gallerySecondaryText)
                .multilineTextAlignment(.center)

            Button("Fertig") {
                dismiss()
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.smokyQuartz)
            .foregroundColor(.galleryBackground)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.galleryBackground)
    }

    // MARK: - Bestellung erstellen

    private func placeOrder() {
        let discount = couponViewModel.discountForAppliedCoupon(orderTotal: cartViewModel.totalPrice)

        orderViewModel.placeOrder(
            cartItems: cartViewModel.cartItems,
            totalAmount: finalTotal,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            street: street,
            zip: zip,
            city: city,
            couponCode: couponViewModel.appliedCoupon?.code,
            discountAmount: discount
        )

        couponViewModel.markCouponUsed()
    }
}

// MARK: - Fortschrittsanzeige

struct StepIndicator: View {
    let currentStep: CheckoutView.CheckoutStep

    private let steps = ["Adresse", "Übersicht", "Bezahlung"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(index <= currentStep.rawValue ? Color.smokyQuartz : Color.galleryChipBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(index <= currentStep.rawValue ? .galleryBackground : .gallerySecondaryText)
                        )

                    Text(steps[index])
                        .font(.galleryCaption)
                        .foregroundColor(index <= currentStep.rawValue ? .softWhite : .gallerySecondaryText)
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep.rawValue ? Color.smokyQuartz : Color.galleryDivider)
                        .frame(height: 1)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
}

// MARK: - Textfeld im Checkout-Stil

struct CheckoutTextField: View {
    let label: String
    @Binding var text: String
    var icon: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.galleryCaption)
                .foregroundColor(.gallerySecondaryText)

            HStack(spacing: 8) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .foregroundColor(.gallerySecondaryText)
                        .frame(width: 20)
                }
                TextField("", text: $text)
                    .foregroundColor(.softWhite)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
            .padding(10)
            .background(Color.galleryPanel)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.galleryDivider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .smokyQuartz : .gallerySecondaryText)
                    .font(.title3)
                configuration.label
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.gallerySubtitle)
            .foregroundColor(.softWhite)
    }
}
