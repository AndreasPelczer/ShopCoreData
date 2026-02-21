//
//  CouponViewModel.swift
//  ShopCoreData
//
//  Created by Claude on 21.02.26.
//

import Foundation
import CoreData

class CouponViewModel: ObservableObject {

    @Published var coupons: [Coupon] = []
    @Published var errorMessage: String?

    // Checkout-State
    @Published var appliedCoupon: Coupon?
    @Published var couponMessage: String?
    @Published var couponIsValid = false

    let store: PersistentStore

    init(store: PersistentStore = .shared) {
        self.store = store
        fetchCoupons()
    }

    func fetchCoupons() {
        let request = NSFetchRequest<Coupon>(entityName: "Coupon")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            coupons = try store.context.fetch(request)
            errorMessage = nil
        } catch {
            errorMessage = "Gutscheine konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    // MARK: - Gutschein validieren & anwenden

    func validateCoupon(code: String, orderTotal: Double) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !trimmed.isEmpty else {
            couponMessage = nil
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        let request = NSFetchRequest<Coupon>(entityName: "Coupon")
        request.predicate = NSPredicate(format: "code ==[c] %@", trimmed)
        request.fetchLimit = 1

        guard let coupon = try? store.context.fetch(request).first else {
            couponMessage = "Gutscheincode nicht gefunden."
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        guard coupon.isActive else {
            couponMessage = "Dieser Gutschein ist nicht mehr aktiv."
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        if let expiry = coupon.expiryDate, expiry < Date() {
            couponMessage = "Dieser Gutschein ist abgelaufen."
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        if coupon.maxUsage > 0 && coupon.usageCount >= coupon.maxUsage {
            couponMessage = "Dieser Gutschein wurde bereits eingelöst."
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        if coupon.minimumOrderAmount > 0 && orderTotal < coupon.minimumOrderAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "de_DE")
            let minAmount = formatter.string(from: NSNumber(value: coupon.minimumOrderAmount)) ?? ""
            couponMessage = "Mindestbestellwert: \(minAmount)"
            couponIsValid = false
            appliedCoupon = nil
            return
        }

        appliedCoupon = coupon
        couponIsValid = true

        let discount = calculateDiscount(coupon: coupon, orderTotal: orderTotal)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        let discountStr = formatter.string(from: NSNumber(value: discount)) ?? ""
        couponMessage = "Gutschein angewendet! Du sparst \(discountStr)"
    }

    func calculateDiscount(coupon: Coupon, orderTotal: Double) -> Double {
        if coupon.discountType == "percent" {
            let discount = orderTotal * (coupon.discountValue / 100.0)
            return min(discount, orderTotal)
        } else {
            return min(coupon.discountValue, orderTotal)
        }
    }

    func discountForAppliedCoupon(orderTotal: Double) -> Double {
        guard let coupon = appliedCoupon else { return 0 }
        return calculateDiscount(coupon: coupon, orderTotal: orderTotal)
    }

    func markCouponUsed() {
        guard let coupon = appliedCoupon else { return }
        coupon.usageCount += 1
        store.save()
    }

    func resetCoupon() {
        appliedCoupon = nil
        couponMessage = nil
        couponIsValid = false
    }

    // MARK: - Admin: Gutscheine verwalten

    func createCoupon(
        code: String,
        discountType: String,
        discountValue: Double,
        minimumOrderAmount: Double = 0,
        maxUsage: Int32 = 0,
        expiryDate: Date? = nil
    ) {
        let coupon = Coupon(context: store.context)
        coupon.id = UUID()
        coupon.code = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        coupon.discountType = discountType
        coupon.discountValue = discountValue
        coupon.minimumOrderAmount = minimumOrderAmount
        coupon.maxUsage = maxUsage
        coupon.usageCount = 0
        coupon.isActive = true
        coupon.createdAt = Date()
        coupon.expiryDate = expiryDate

        if !store.save() {
            errorMessage = "Gutschein konnte nicht gespeichert werden."
        }
        fetchCoupons()
    }

    func toggleCouponActive(_ coupon: Coupon) {
        coupon.isActive.toggle()
        store.save()
        fetchCoupons()
    }

    func deleteCoupon(_ coupon: Coupon) {
        store.context.delete(coupon)
        store.save()
        fetchCoupons()
    }
}
