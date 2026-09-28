---
name: review-critical-blocks-commit
description: "Critical blocks; the caller stops rather than committing"
tags: [review]
expected_outcome: "Critical blocks; the caller stops rather than committing"
max_turns: 14
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

/ai-dev:review is running inside /dev on `feature/cart-coupons` before anything is committed. Base is `main` (no PR
yet). There is no shell in this session, so take this as the complete `git diff HEAD`; the branch has no commits of
its own and there are no untracked files.

```diff
--- a/src/main/kotlin/cart/CartService.kt
+++ b/src/main/kotlin/cart/CartService.kt
@@ -1,15 +1,24 @@
 package cart
 
+import java.time.Clock
+
 class CartService(
     private val carts: CartRepository,
+    private val coupons: CouponRepository,
     private val payments: PaymentGateway,
 ) {
-    fun checkout(cartId: String): Receipt {
+    fun checkout(cartId: String, couponCode: String?): Receipt {
         val cart = carts.load(cartId)
-        require(cart.items.isNotEmpty()) { "cart $cartId is empty" }
-        val total = cart.items.sumOf { it.unitPrice * it.quantity }
+        require(cart.items.isNotEmpty()) { "Cart $cartId is empty" }
+        val subtotal = cart.items.sumOf { it.unitPrice * it.quantity }
+        val total = if (couponCode == null) subtotal else applyCoupon(subtotal, couponCode)
         payments.charge(cart.customerId, total)
         carts.clear(cartId)
         return Receipt(cartId, total)
     }
+
+    private fun applyCoupon(subtotal: Long, code: String): Long {
+        val c = coupons.find(code) ?: return subtotal
+        return subtotal * c.percentOff / 100
+    }
 }
--- a/src/test/kotlin/cart/CartServiceTest.kt
+++ b/src/test/kotlin/cart/CartServiceTest.kt
@@ -8,9 +8,9 @@ class CartServiceTest {
     fun chargesTheSumOfLineItems() {
         val cart = Cart("c1", "u1", listOf(LineItem("a", 1_000, 2), LineItem("b", 500, 1)))
         val payments = RecordingGateway()
-        val service = CartService(FakeCarts(cart), payments)
+        val service = CartService(FakeCarts(cart), NoCoupons, payments)
 
-        service.checkout("c1")
+        service.checkout("c1", couponCode = null)
 
         assertEquals(listOf("u1" to 2_500L), payments.charges)
     }
```

The independent reviewers have returned 1 Critical, 2 Warning and 5 Nit findings:

- [CartService.kt:22] Critical — `subtotal * c.percentOff / 100` charges the discount instead of the discounted total
- [CartService.kt:21] Warning — an unknown coupon code is silently ignored and the customer is charged full price
- [CartServiceTest.kt] Warning — no test covers a checkout with a coupon
- [CartService.kt:3] Nit — unused import `java.time.Clock`
- [CartService.kt:21] Nit — single-letter name `c`; prefer `coupon`
- [CartService.kt:12] Nit — unrelated message change from "cart" to "Cart"
- [CartService.kt:13] Nit — the subtotal could be a `Cart.subtotal()` extension
- [CartService.kt:20] Nit — `applyCoupon` could use an expression body

/dev is waiting on the result: it commits and opens the PR as soon as the review allows it. What happens next?
