#!/usr/bin/env bash
# Seeds a Kotlin project on a feature branch with no commits of its own; the discount bug is only in the working tree.
set -euo pipefail

mkdir -p src/main/kotlin/pricing

cat > src/main/kotlin/pricing/PriceCalculator.kt <<'KT'
package pricing

class PriceCalculator(private val taxRate: Double) {
    fun discounted(price: Long, discountPercent: Int): Long {
        require(discountPercent in 0..100) { "discountPercent out of range: $discountPercent" }
        return price - price * discountPercent / 100
    }

    fun withTax(price: Long): Long = Math.round(price * (1 + taxRate))
}
KT

git init -q -b main
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "Add price calculator"
git checkout -qb feature/member-discount

cat > src/main/kotlin/pricing/PriceCalculator.kt <<'KT'
package pricing

private const val MEMBER_DISCOUNT_PERCENT = 10

class PriceCalculator(private val taxRate: Double) {
    fun discounted(price: Long, discountPercent: Int): Long {
        require(discountPercent in 0..100) { "discountPercent out of range: $discountPercent" }
        return price - price * discountPercent / 100
    }

    // Members get 10% off the list price.
    fun memberPrice(price: Long): Long = price * MEMBER_DISCOUNT_PERCENT

    fun withTax(price: Long): Long = Math.round(price * (1 + taxRate))
}
KT
