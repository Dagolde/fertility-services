import requests
import json
import uuid
from typing import Dict, Any, Optional
from decimal import Decimal
from ..models import PaymentGatewayConfig, PaymentGateway
from sqlalchemy.orm import Session

class PaystackService:
    def __init__(self, db: Session):
        self.db = db
        self.base_url = "https://api.paystack.co"
        self.config = self._get_config()
    
    def _get_config(self) -> Optional[PaymentGatewayConfig]:
        """Get Paystack configuration from database"""
        return self.db.query(PaymentGatewayConfig).filter(
            PaymentGatewayConfig.gateway == PaymentGateway.PAYSTACK,
            PaymentGatewayConfig.is_active == True
        ).first()
    
    def _get_headers(self) -> Dict[str, str]:
        """Get headers for Paystack API requests"""
        if not self.config or not self.config.secret_key:
            raise ValueError("Paystack not configured or secret key missing")
        
        return {
            "Authorization": f"Bearer {self.config.secret_key}",
            "Content-Type": "application/json"
        }
    
    def initialize_transaction(
        self,
        email: str,
        amount: Decimal,
        currency: str = "NGN",
        reference: Optional[str] = None,
        callback_url: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Initialize a payment transaction"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        if not reference:
            reference = f"tx_{uuid.uuid4().hex[:16]}"
        
        # Convert amount to kobo (smallest currency unit)
        amount_in_kobo = int(amount * 100)
        
        payload = {
            "email": email,
            "amount": amount_in_kobo,
            "currency": currency,
            "reference": reference,
            "callback_url": callback_url,
            "metadata": metadata or {}
        }
        
        response = requests.post(
            f"{self.base_url}/transaction/initialize",
            headers=self._get_headers(),
            json=payload
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def verify_transaction(self, reference: str) -> Dict[str, Any]:
        """Verify a payment transaction"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        response = requests.get(
            f"{self.base_url}/transaction/verify/{reference}",
            headers=self._get_headers()
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def list_transactions(
        self,
        per_page: int = 50,
        page: int = 1,
        customer: Optional[str] = None,
        status: Optional[str] = None,
        from_date: Optional[str] = None,
        to_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """List transactions"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        params = {
            "perPage": per_page,
            "page": page
        }
        
        if customer:
            params["customer"] = customer
        if status:
            params["status"] = status
        if from_date:
            params["from"] = from_date
        if to_date:
            params["to"] = to_date
        
        response = requests.get(
            f"{self.base_url}/transaction",
            headers=self._get_headers(),
            params=params
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def create_customer(
        self,
        email: str,
        first_name: str,
        last_name: str,
        phone: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create a customer"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        payload = {
            "email": email,
            "first_name": first_name,
            "last_name": last_name
        }
        
        if phone:
            payload["phone"] = phone
        
        response = requests.post(
            f"{self.base_url}/customer",
            headers=self._get_headers(),
            json=payload
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def charge_authorization(
        self,
        authorization_code: str,
        email: str,
        amount: Decimal,
        currency: str = "NGN",
        reference: Optional[str] = None
    ) -> Dict[str, Any]:
        """Charge an authorization (recurring payment)"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        if not reference:
            reference = f"tx_{uuid.uuid4().hex[:16]}"
        
        # Convert amount to kobo
        amount_in_kobo = int(amount * 100)
        
        payload = {
            "authorization_code": authorization_code,
            "email": email,
            "amount": amount_in_kobo,
            "currency": currency,
            "reference": reference
        }
        
        response = requests.post(
            f"{self.base_url}/transaction/charge_authorization",
            headers=self._get_headers(),
            json=payload
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def refund_transaction(
        self,
        transaction_id: str,
        amount: Optional[Decimal] = None,
        currency: str = "NGN",
        customer_note: Optional[str] = None,
        merchant_note: Optional[str] = None
    ) -> Dict[str, Any]:
        """Refund a transaction"""
        if not self.config:
            raise ValueError("Paystack not configured")
        
        payload = {
            "transaction": transaction_id,
            "currency": currency
        }
        
        if amount:
            payload["amount"] = int(amount * 100)  # Convert to kobo
        if customer_note:
            payload["customer_note"] = customer_note
        if merchant_note:
            payload["merchant_note"] = merchant_note
        
        response = requests.post(
            f"{self.base_url}/refund",
            headers=self._get_headers(),
            json=payload
        )
        
        if response.status_code != 200:
            raise Exception(f"Paystack API error: {response.text}")
        
        return response.json()
    
    def verify_webhook_signature(self, payload: str, signature: str) -> bool:
        """Verify webhook signature"""
        if not self.config or not self.config.webhook_secret:
            return False
        
        import hmac
        import hashlib
        
        expected_signature = hmac.new(
            self.config.webhook_secret.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha512
        ).hexdigest()
        
        return hmac.compare_digest(expected_signature, signature)
