#!/usr/bin/env bash
# Seeds a Kotlin checkout service; the uncommitted coupon change charges the discount instead of the discounted total.
set -euo pipefail

mkdir -p src/main/kotlin/cart src/test/kotlin/cart

cat > src/main/kotlin/cart/Models.kt <<'KT'
package cart

data class LineItem(val sku: String, val unitPrice: Long, val quantity: Int)
data class Cart(val id: String, val customerId: String, val items: List<LineItem>)
data class Coupon(val code: String, val percentOff: Int)
data class Receipt(val cartId: String, val total: Long)

interface CartRepository {
    fun load(cartId: String): Cart
    fun clear(cartId: String)
}

interface CouponRepository {
    fun find(code: String): Coupon?
}

interface PaymentGateway {
    fun charge(customerId: String, amount: Long)
}
KT

cat > src/main/kotlin/cart/CartService.kt <<'KT'
package cart

class CartService(
    private val carts: CartRepository,
    private val payments: PaymentGateway,
) {
    fun checkout(cartId: String): Receipt {
        val cart = carts.load(cartId)
        require(cart.items.isNotEmpty()) { "cart $cartId is empty" }
        val total = cart.items.sumOf { it.unitPrice * it.quantity }
        payments.charge(cart.customerId, total)
        carts.clear(cartId)
        return Receipt(cartId, total)
    }
}
KT

cat > src/test/kotlin/cart/CartServiceTest.kt <<'KT'
package cart

import kotlin.test.Test
import kotlin.test.assertEquals

class CartServiceTest {
    @Test
    fun chargesTheSumOfLineItems() {
        val cart = Cart("c1", "u1", listOf(LineItem("a", 1_000, 2), LineItem("b", 500, 1)))
        val payments = RecordingGateway()
        val service = CartService(FakeCarts(cart), payments)

        service.checkout("c1")

        assertEquals(listOf("u1" to 2_500L), payments.charges)
    }
}

private class FakeCarts(private val cart: Cart) : CartRepository {
    override fun load(cartId: String) = cart
    override fun clear(cartId: String) {}
}

private class RecordingGateway : PaymentGateway {
    val charges = mutableListOf<Pair<String, Long>>()
    override fun charge(customerId: String, amount: Long) {
        charges += customerId to amount
    }
}
KT

git init -q -b main
git add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "Add checkout"
git checkout -qb feature/cart-coupons

cat > src/main/kotlin/cart/CartService.kt <<'KT'
package cart

import java.time.Clock

class CartService(
    private val carts: CartRepository,
    private val coupons: CouponRepository,
    private val payments: PaymentGateway,
) {
    fun checkout(cartId: String, couponCode: String?): Receipt {
        val cart = carts.load(cartId)
        require(cart.items.isNotEmpty()) { "Cart $cartId is empty" }
        val subtotal = cart.items.sumOf { it.unitPrice * it.quantity }
        val total = if (couponCode == null) subtotal else applyCoupon(subtotal, couponCode)
        payments.charge(cart.customerId, total)
        carts.clear(cartId)
        return Receipt(cartId, total)
    }

    private fun applyCoupon(subtotal: Long, code: String): Long {
        val c = coupons.find(code) ?: return subtotal
        return subtotal * c.percentOff / 100
    }
}
KT

cat > src/test/kotlin/cart/CartServiceTest.kt <<'KT'
package cart

import kotlin.test.Test
import kotlin.test.assertEquals

class CartServiceTest {
    @Test
    fun chargesTheSumOfLineItems() {
        val cart = Cart("c1", "u1", listOf(LineItem("a", 1_000, 2), LineItem("b", 500, 1)))
        val payments = RecordingGateway()
        val service = CartService(FakeCarts(cart), NoCoupons, payments)

        service.checkout("c1", couponCode = null)

        assertEquals(listOf("u1" to 2_500L), payments.charges)
    }
}

private class FakeCarts(private val cart: Cart) : CartRepository {
    override fun load(cartId: String) = cart
    override fun clear(cartId: String) {}
}

private object NoCoupons : CouponRepository {
    override fun find(code: String): Coupon? = null
}

private class RecordingGateway : PaymentGateway {
    val charges = mutableListOf<Pair<String, Long>>()
    override fun charge(customerId: String, amount: Long) {
        charges += customerId to amount
    }
}
KT
