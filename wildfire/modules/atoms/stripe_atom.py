import sys
import json
import os
try:
    import stripe
except ImportError:
    print(json.dumps({"error": "stripe_pkg_missing"}))
    sys.exit(1)

class StripeAtom:
    def __init__(self):
        self.api_key = os.environ.get("STRIPE_SECRET_KEY")
        if not self.api_key:
             # Fallback just for testing if user hasn't set it yet
             self.api_key = "sk_test_placeholder" 
        stripe.api_key = self.api_key
        
        self.webhook_secret = os.environ.get("STRIPE_WEBHOOK_SECRET")

    def create_payment_link(self, product_name: str, amount_cents: int, currency: str = "usd"):
        """
        Creates a Stripe Payment Link for a specific outcome.
        """
        if self.api_key == "sk_test_placeholder":
            return {
                "status": "error",
                "message": "STRIPE_SECRET_KEY not set in environment.",
                "provider": "stripe"
            }

        try:
            # 1. Create/Find Product (Simple)
            # In production, we might want to reuse existing products
            product = stripe.Product.create(name=product_name)
            
            # 2. Create Price
            price = stripe.Price.create(
                unit_amount=amount_cents,
                currency=currency,
                product=product.id,
            )
            
            # 3. Create Payment Link
            payment_link = stripe.PaymentLink.create(
                line_items=[{"price": price.id, "quantity": 1}],
                after_completion={"type": "redirect", "redirect": {"url": "https://titansystems.world/success"}} 
            )
            
            return {
                "status": "success",
                "payment_url": payment_link.url,
                "payment_link_id": payment_link.id,
                "amount": amount_cents / 100,
                "currency": currency,
                "product": product_name
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

    def check_payment_status(self, payment_link_id: str):
         # This usually requires checking sessions associated with the link
         # or listening to webhooks. For atom simplicity, we might check via API.
         # But Payment Links don't track status directly on the link obj easily without listing sessions.
         # Mocking retrieval for now or implementing list_sessions
         try:
            # list sessions
            # sessions = stripe.checkout.Session.list(payment_link=payment_link_id)
            # ...
            return {"status": "check_implemented_via_webhook_preferred"}
         except Exception as e:
            return {"status": "error", "error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: stripe_atom.py <action> [args]"})); sys.exit(1)
        
    action = sys.argv[1]
    atom = StripeAtom()
    
    if action == "create":
        name = sys.argv[2]
        amount = int(sys.argv[3])
        print(json.dumps(atom.create_payment_link(name, amount)))
        
    elif action == "check":
        sid = sys.argv[2]
        print(json.dumps(atom.check_payment_status(sid)))
