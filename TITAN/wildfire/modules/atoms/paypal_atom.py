import sys
import json
import os
import requests
import base64
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

class PayPalAtom:
    def __init__(self):
        self.client_id = os.environ.get("PAYPAL_CLIENT_ID")
        self.client_secret = os.environ.get("PAYPAL_CLIENT_SECRET")
        # Default to Sandbox for safety until verified
        self.base_url = "https://api-m.sandbox.paypal.com" 
        if os.environ.get("TITAN_ENV") == "PROD":
             self.base_url = "https://api-m.paypal.com"

    def _get_access_token(self):
        url = f"{self.base_url}/v1/oauth2/token"
        headers = {
            "Accept": "application/json",
            "Accept-Language": "en_US"
        }
        data = {"grant_type": "client_credentials"}
        
        try:
            response = requests.post(
                url, 
                headers=headers, 
                data=data, 
                auth=(self.client_id, self.client_secret)
            )
            response.raise_for_status()
            return response.json()['access_token']
        except Exception as e:
            print(json.dumps({"error": f"Auth failed: {str(e)}"}))
            return None

    def create_payment_link(self, product_name: str, amount: float, currency: str = "USD"):
        """
        Creates a PayPal Order.
        Note: PayPal API doesn't generate a semi-permanent 'Link' like Stripe Payment Links 
        without a bit more UI work, but we can generate an 'approve' link for a specific transaction.
        """
        token = self._get_access_token()
        if not token:
            return {"status": "error", "message": "Could not authenticate with PayPal"}

        url = f"{self.base_url}/v2/checkout/orders"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}"
        }
        
        payload = {
            "intent": "CAPTURE",
            "purchase_units": [{
                "amount": {
                    "currency_code": currency,
                    "value": str(amount)
                },
                "description": product_name
            }],
            "application_context": {
                "return_url": "https://titansystems.world/success",
                "cancel_url": "https://titansystems.world/cancel"
            }
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            
            # Extract approval link
            approve_link = next((link['href'] for link in data['links'] if link['rel'] == 'approve'), None)
            
            return {
                "status": "success",
                "payment_url": approve_link, # User clicks this to pay
                "order_id": data['id'],
                "amount": amount,
                "currency": currency,
                "product": product_name,
                "provider": "paypal"
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

if __name__ == "__main__":
    # CLI Usage: python paypal_atom.py create "System Health Audit" 49.00
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: paypal_atom.py <action> [args]"})); sys.exit(1)
        
    action = sys.argv[1]
    
    atom = PayPalAtom()
    
    if action == "create":
        name = sys.argv[2]
        amount = float(sys.argv[3])
        print(json.dumps(atom.create_payment_link(name, amount)))
