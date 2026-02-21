//
//  AdminCouponView.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import SwiftUI

struct AdminCouponView: View {
    @StateObject private var couponViewModel = CouponViewModel()
    @State private var showCreateSheet = false

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        List {
            if couponViewModel.coupons.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket")
                        .font(.system(size: 40))
                        .foregroundColor(.gallerySecondaryText)
                    Text("Keine Gutscheine vorhanden")
                        .font(.galleryBody)
                        .foregroundColor(.gallerySecondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.galleryBackground)
            } else {
                ForEach(couponViewModel.coupons, id: \.id) { coupon in
                    CouponRow(coupon: coupon, currencyFormatter: currencyFormatter) {
                        couponViewModel.toggleCouponActive(coupon)
                    }
                    .listRowBackground(Color.galleryPanel)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        couponViewModel.deleteCoupon(couponViewModel.coupons[index])
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.galleryBackground)
        .navigationTitle("Gutscheine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.smokyQuartz)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCouponView(couponViewModel: couponViewModel, isPresented: $showCreateSheet)
        }
        .onAppear {
            couponViewModel.fetchCoupons()
        }
    }
}

// MARK: - Gutschein-Zeile

struct CouponRow: View {
    let coupon: Coupon
    let currencyFormatter: NumberFormatter
    let onToggle: () -> Void

    private var discountText: String {
        if coupon.discountType == "percent" {
            return "\(Int(coupon.discountValue))%"
        } else {
            return currencyFormatter.string(from: NSNumber(value: coupon.discountValue)) ?? ""
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(coupon.code ?? "")
                        .font(.galleryMono)
                        .fontWeight(.bold)
                        .foregroundColor(.softWhite)

                    Text(discountText)
                        .font(.galleryCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.galleryBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.smokyQuartz)
                        .cornerRadius(4)
                }

                HStack(spacing: 12) {
                    if coupon.maxUsage > 0 {
                        Text("\(coupon.usageCount)/\(coupon.maxUsage) genutzt")
                            .font(.galleryCaption)
                            .foregroundColor(.gallerySecondaryText)
                    }
                    if let expiry = coupon.expiryDate {
                        Text("bis \(dateFormatter.string(from: expiry))")
                            .font(.galleryCaption)
                            .foregroundColor(expiry < Date() ? .gallerySold : .gallerySecondaryText)
                    }
                }
            }

            Spacer()

            Button(action: onToggle) {
                Text(coupon.isActive ? "Aktiv" : "Inaktiv")
                    .font(.galleryCaption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(coupon.isActive ? Color.galleryAvailable.opacity(0.2) : Color.gallerySold.opacity(0.2))
                    .foregroundColor(coupon.isActive ? .galleryAvailable : .gallerySold)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Gutschein erstellen

struct CreateCouponView: View {
    @ObservedObject var couponViewModel: CouponViewModel
    @Binding var isPresented: Bool

    @State private var code = ""
    @State private var discountType = "percent"
    @State private var discountValue = ""
    @State private var minimumOrderAmount = ""
    @State private var maxUsage = ""
    @State private var hasExpiry = false
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    private var isValid: Bool {
        !code.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(discountValue.replacingOccurrences(of: ",", with: ".")) ?? 0) > 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(title: "Gutscheincode")
                    CheckoutTextField(label: "Code (z.B. SOMMER25)", text: $code, icon: "ticket", autocapitalization: .characters)

                    SectionHeader(title: "Rabattart")
                    Picker("Rabattart", selection: $discountType) {
                        Text("Prozent (%)").tag("percent")
                        Text("Festbetrag (€)").tag("fixed")
                    }
                    .pickerStyle(.segmented)
                    .tint(.smokyQuartz)

                    CheckoutTextField(
                        label: discountType == "percent" ? "Rabatt in %" : "Rabatt in €",
                        text: $discountValue,
                        icon: discountType == "percent" ? "percent" : "eurosign",
                        keyboardType: .decimalPad,
                        autocapitalization: .never
                    )

                    SectionHeader(title: "Optionale Einschränkungen")

                    CheckoutTextField(
                        label: "Mindestbestellwert (€, optional)",
                        text: $minimumOrderAmount,
                        icon: "cart",
                        keyboardType: .decimalPad,
                        autocapitalization: .never
                    )

                    CheckoutTextField(
                        label: "Max. Einlösungen (0 = unbegrenzt)",
                        text: $maxUsage,
                        icon: "number",
                        keyboardType: .numberPad,
                        autocapitalization: .never
                    )

                    Toggle(isOn: $hasExpiry) {
                        Text("Ablaufdatum setzen")
                            .font(.galleryBody)
                            .foregroundColor(.softWhite)
                    }
                    .tint(.smokyQuartz)

                    if hasExpiry {
                        DatePicker(
                            "Gültig bis",
                            selection: $expiryDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .foregroundColor(.softWhite)
                        .tint(.smokyQuartz)
                    }

                    Button {
                        createCoupon()
                    } label: {
                        Text("Gutschein erstellen")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.smokyQuartz : Color.gallerySecondaryText.opacity(0.3))
                            .foregroundColor(isValid ? .galleryBackground : .gallerySecondaryText)
                            .cornerRadius(12)
                    }
                    .disabled(!isValid)
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.galleryBackground)
            .navigationTitle("Neuer Gutschein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                        .foregroundColor(.smokyQuartz)
                }
            }
        }
    }

    private func createCoupon() {
        let value = Double(discountValue.replacingOccurrences(of: ",", with: ".")) ?? 0
        let minOrder = Double(minimumOrderAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        let maxUse = Int32(maxUsage) ?? 0

        couponViewModel.createCoupon(
            code: code,
            discountType: discountType,
            discountValue: value,
            minimumOrderAmount: minOrder,
            maxUsage: maxUse,
            expiryDate: hasExpiry ? expiryDate : nil
        )

        isPresented = false
    }
}
