from fastapi import APIRouter, Depends, HTTPException, status, Query, Request
from sqlalchemy.orm import Session
from typing import Optional, List
from ..database import get_db
from ..models import User, Appointment, Payment, PaymentGateway, PaymentStatus, PaymentGatewayConfig, Service, WalletTransaction, WalletTransactionType, Hospital
from ..auth import get_current_active_user
from datetime import datetime
from ..services.paystack_service import PaystackService
import hmac
import hashlib
import os
import json

router = APIRouter()

@router.post("/initiate-booking")
async def initiate_booking(
    service_id: int,
    appointment_date: datetime,
    hospital_id: Optional[int] = Query(None),  # Optional hospital ID
    payment_method: Optional[str] = Query(None),  # 'wallet', 'paystack', 'stripe', etc.
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Initiate booking for an appointment with pre-payment.
    If payment_method is not provided, return available gateways.
    """
    # 1. Validate service
    service = db.query(Service).filter(Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if not service.is_active:
        raise HTTPException(status_code=400, detail="Service is not available")
    
    price = float(service.price)  # Get actual price from service
    
    # 2. Determine hospital
    if hospital_id:
        hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
        if not hospital:
            raise HTTPException(status_code=404, detail="Hospital not found")
        if not hospital.is_verified:
            raise HTTPException(status_code=400, detail="Hospital is not verified")
    else:
        # Get a default hospital for the appointment
        hospital = db.query(Hospital).filter(Hospital.is_verified == True).first()
        if not hospital:
            raise HTTPException(status_code=400, detail="No verified hospitals available")
        hospital_id = hospital.id

    if not payment_method:
        # Return all active gateways for frontend to display
        gateways: List[PaymentGatewayConfig] = db.query(PaymentGatewayConfig).filter(PaymentGatewayConfig.is_active == True).all()
        gateway_list = [
            {
                "gateway": g.gateway.value if hasattr(g.gateway, 'value') else str(g.gateway),
                "display_name": g.gateway.value.capitalize() if hasattr(g.gateway, 'value') else str(g.gateway).capitalize(),
                "is_test_mode": g.is_test_mode
            }
            for g in gateways
        ]
        # Always include wallet as an option
        gateway_list.insert(0, {"gateway": "wallet", "display_name": "Wallet", "is_test_mode": False})
        
        # If no gateways are configured, return a message
        if not gateways:
            return {
                "available_gateways": [{"gateway": "wallet", "display_name": "Wallet", "is_test_mode": False}],
                "message": "No payment gateways configured. Only wallet payment is available."
            }
        
        return {"available_gateways": gateway_list}

    if payment_method == 'wallet':
        # Fetch real wallet balance
        user = db.query(User).filter(User.id == current_user.id).with_for_update().first()
        
        # Convert price to Decimal for consistent comparison
        from decimal import Decimal
        price_decimal = Decimal(str(price))
        
        if user.wallet_balance < price_decimal:
            raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        
        # Create appointment first
        appointment = Appointment(
            user_id=current_user.id,
            hospital_id=hospital_id,
            service_id=service_id,
            appointment_date=appointment_date,
            status='confirmed',
            price=price
        )
        db.add(appointment)
        db.commit()
        db.refresh(appointment)
        
        # Create wallet transaction for payment
        import uuid
        reference = f"WAL_PAY_{datetime.now().strftime('%Y%m%d%H%M%S')}_{str(uuid.uuid4())[:8].upper()}"
        
        wallet_transaction = WalletTransaction(
            user_id=current_user.id,
            transaction_type=WalletTransactionType.PAYMENT,
            amount=price,
            currency="NGN",
            description=f"Payment for appointment #{appointment.id} - {service.name}",
            reference=reference,
            status=PaymentStatus.COMPLETED
        )
        db.add(wallet_transaction)
        
        # Create payment record
        payment = Payment(
            user_id=current_user.id,
            appointment_id=appointment.id,
            amount=price,
            payment_method='wallet',
            payment_gateway=PaymentGateway.MANUAL,
            status=PaymentStatus.COMPLETED,
            payment_date=datetime.now()
        )
        db.add(payment)
        
        # Use the already converted price_decimal
        
        # Deduct wallet balance
        user.wallet_balance -= price_decimal
        
        db.commit()
        db.refresh(payment)
        
        return {
            "message": "Appointment booked and paid from wallet", 
            "appointment_id": appointment.id, 
            "payment_id": payment.id,
            "wallet_transaction_id": wallet_transaction.id,
            "new_balance": float(user.wallet_balance)
        }
    else:
        # Multi-gateway logic
        gateway_config = db.query(PaymentGatewayConfig).filter(PaymentGatewayConfig.gateway == payment_method, PaymentGatewayConfig.is_active == True).first()
        if not gateway_config:
            raise HTTPException(status_code=400, detail=f"Payment gateway '{payment_method}' is not available.")
        # --- Gateway-specific logic ---
        if payment_method == 'paystack':
            # Use real Paystack API for live mode
            reference = f"booking_{service_id}_{current_user.id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            # Get Paystack config
            gateway_config = db.query(PaymentGatewayConfig).filter(PaymentGatewayConfig.gateway == 'paystack', PaymentGatewayConfig.is_active == True).first()
            if not gateway_config:
                raise HTTPException(status_code=400, detail="Paystack gateway is not available.")
            
            # Initialize Paystack payment
            paystack_service = PaystackService(db)
            paystack_response = paystack_service.initialize_transaction(
                email=current_user.email,
                amount=price,
                currency=gateway_config.supported_currencies[0] if gateway_config.supported_currencies else 'NGN',
                reference=reference,
                callback_url=f"https://yourdomain.com/payment/callback",
                metadata={
                    "service_id": service_id,
                    "hospital_id": hospital_id,
                    "user_id": current_user.id,
                    "user_name": f"{current_user.first_name} {current_user.last_name}",
                    "appointment_date": appointment_date.isoformat()
                }
            )
            # Create a Payment record with status PENDING
            payment = Payment(
                user_id=current_user.id,
                appointment_id=None,  # Will be set after confirmation
                amount=price,
                payment_method='paystack',
                status=PaymentStatus.PENDING.value,
                transaction_id=reference,
                gateway_reference=reference,
                gateway_response=paystack_response,
            )
            db.add(payment)
            db.commit()
            db.refresh(payment)
            return {
                "payment_url": paystack_response["data"]["authorization_url"],
                "reference": reference,
                "payment_id": payment.id
            }
        elif payment_method == 'stripe':
            # TODO: Integrate Stripe payment initialization here
            # Example: Use stripe.PaymentIntent.create(...) or stripe.checkout.Session.create(...)
            # Store the payment reference and status as PENDING
            # Return the payment URL and reference
            # For now, simulate
            reference = f"stripe_{service_id}_{current_user.id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            payment_url = "https://stripe.com/pay/xyz"  # Replace with real URL
            payment = Payment(
                user_id=current_user.id,
                appointment_id=None,
                amount=price,
                payment_method='stripe',
                status=PaymentStatus.PENDING.value,
                transaction_id=reference,
                gateway_reference=reference,
                gateway_response={},
            )
            db.add(payment)
            db.commit()
            db.refresh(payment)
            return {"payment_url": payment_url, "reference": reference, "payment_id": payment.id}
        elif payment_method == 'flutterwave':
            # TODO: Integrate Flutterwave payment initialization here
            # Example: Use Flutterwave API to create a payment link/transaction
            # Store the payment reference and status as PENDING
            # Return the payment URL and reference
            # For now, simulate
            reference = f"flutterwave_{service_id}_{current_user.id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            payment_url = "https://flutterwave.com/pay/xyz"  # Replace with real URL
            payment = Payment(
                user_id=current_user.id,
                appointment_id=None,
                amount=price,
                payment_method='flutterwave',
                status=PaymentStatus.PENDING.value,
                transaction_id=reference,
                gateway_reference=reference,
                gateway_response={},
            )
            db.add(payment)
            db.commit()
            db.refresh(payment)
            return {"payment_url": payment_url, "reference": reference, "payment_id": payment.id}
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported payment gateway: {payment_method}") 

@router.post("/verify-payment")
async def verify_payment(
    reference: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    Manually verify payment after redirect from gateway. If successful, create appointment and update payment.
    """
    payment = db.query(Payment).filter(Payment.transaction_id == reference, Payment.user_id == current_user.id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.status == PaymentStatus.COMPLETED.value:
        return {"message": "Payment already verified and appointment created."}
    # Real Paystack verification
    paystack_service = PaystackService(db)
    verification = paystack_service.verify_transaction(reference)
    if not verification.get('status') or verification['data']['status'] != 'success':
        raise HTTPException(status_code=400, detail="Payment not successful or not verified.")
    # Extract metadata for appointment creation
    metadata = verification['data'].get('metadata', {})
    service_id = metadata.get('service_id', 1)
    appointment_date = metadata.get('appointment_date', datetime.now())
    hospital_id = metadata.get('hospital_id')
    
    # Determine hospital
    if hospital_id:
        hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
        if not hospital:
            raise HTTPException(status_code=400, detail="Hospital not found")
    else:
        # Get a default hospital for the appointment
        hospital = db.query(Hospital).filter(Hospital.is_verified == True).first()
        if not hospital:
            raise HTTPException(status_code=400, detail="No verified hospitals available")
        hospital_id = hospital.id
    
    # Create appointment
    appointment = Appointment(
        user_id=current_user.id,
        hospital_id=hospital_id,
        service_id=service_id,
        appointment_date=appointment_date,
        status='confirmed',
        price=payment.amount
    )
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    payment.appointment_id = appointment.id
    payment.status = PaymentStatus.COMPLETED.value
    payment.payment_date = datetime.now()
    db.commit()
    db.refresh(payment)
    return {"message": "Payment verified, appointment booked.", "appointment_id": appointment.id}

@router.post("/webhook/paystack")
async def paystack_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Paystack webhook endpoint. Verifies signature and updates payment/appointment on success.
    """
    # Get raw body and signature
    body = await request.body()
    signature = request.headers.get('x-paystack-signature')
    # Get webhook secret from config or env
    webhook_secret = os.getenv('PAYSTACK_WEBHOOK_SECRET', None)
    if not webhook_secret:
        # Try to get from DB config
        config = db.query(PaymentGatewayConfig).filter(PaymentGatewayConfig.gateway == 'paystack', PaymentGatewayConfig.is_active == True).first()
        webhook_secret = config.webhook_secret if config else None
    if not webhook_secret:
        return {"error": "Webhook secret not configured"}
    # Verify signature
    computed_sig = hmac.new(webhook_secret.encode(), body, hashlib.sha512).hexdigest()
    if not hmac.compare_digest(computed_sig, signature):
        return {"error": "Invalid signature"}
    # Parse event
    event = json.loads(body)
    if event.get('event') == 'charge.success':
        data = event['data']
        reference = data['reference']
        payment = db.query(Payment).filter(Payment.transaction_id == reference).first()
        if payment and payment.status != PaymentStatus.COMPLETED.value:
            # Extract metadata for appointment creation
            metadata = data.get('metadata', {})
            service_id = metadata.get('service_id', 1)
            appointment_date = metadata.get('appointment_date', datetime.now())
            # Get a default hospital for the appointment
            default_hospital = db.query(Hospital).filter(Hospital.is_verified == True).first()
            if not default_hospital:
                return {"error": "No verified hospitals available"}
            
            # Create appointment
            appointment = Appointment(
                user_id=payment.user_id,
                hospital_id=default_hospital.id,
                service_id=service_id,
                appointment_date=appointment_date,
                status='confirmed',
                price=payment.amount
            )
            db.add(appointment)
            db.commit()
            db.refresh(appointment)
            payment.appointment_id = appointment.id
            payment.status = PaymentStatus.COMPLETED.value
            payment.payment_date = datetime.now()
            db.commit()
            db.refresh(payment)
    return {"message": "Webhook processed"} 

@router.post("/webhook/stripe")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Stripe webhook endpoint. Verifies event and updates payment/appointment on success.
    """
    body = await request.body()
    event = json.loads(body)
    # TODO: Use stripe.Webhook.construct_event(...) to verify signature
    # For now, assume event is valid
    if event.get('type') in ['payment_intent.succeeded', 'checkout.session.completed']:
        data = event['data']['object']
        reference = data.get('id') or data.get('client_reference_id')
        payment = db.query(Payment).filter(Payment.transaction_id == reference).first()
        if payment and payment.status != PaymentStatus.COMPLETED.value:
            # Extract metadata for appointment creation
            metadata = data.get('metadata', {})
            service_id = metadata.get('service_id', 1)
            appointment_date = metadata.get('appointment_date', datetime.now())
            appointment = Appointment(
                user_id=payment.user_id,
                service_id=service_id,
                appointment_date=appointment_date,
                status='confirmed',
                price=payment.amount
            )
            db.add(appointment)
            db.commit()
            db.refresh(appointment)
            payment.appointment_id = appointment.id
            payment.status = PaymentStatus.COMPLETED.value
            payment.payment_date = datetime.now()
            db.commit()
            db.refresh(payment)
    return {"message": "Stripe webhook processed"}

@router.post("/webhook/flutterwave")
async def flutterwave_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Flutterwave webhook endpoint. Verifies event and updates payment/appointment on success.
    """
    body = await request.body()
    event = json.loads(body)
    # TODO: Verify Flutterwave signature and event
    # For now, assume event is valid
    if event.get('event') == 'charge.completed' or event.get('status') == 'successful':
        data = event.get('data', event)
        reference = data.get('tx_ref') or data.get('reference')
        payment = db.query(Payment).filter(Payment.transaction_id == reference).first()
        if payment and payment.status != PaymentStatus.COMPLETED.value:
            # Extract metadata for appointment creation
            metadata = data.get('meta', {})
            service_id = metadata.get('service_id', 1)
            appointment_date = metadata.get('appointment_date', datetime.now())
            # Get a default hospital for the appointment
            default_hospital = db.query(Hospital).filter(Hospital.is_verified == True).first()
            if not default_hospital:
                return {"error": "No verified hospitals available"}
            
            appointment = Appointment(
                user_id=payment.user_id,
                hospital_id=default_hospital.id,
                service_id=service_id,
                appointment_date=appointment_date,
                status='confirmed',
                price=payment.amount
            )
            db.add(appointment)
            db.commit()
            db.refresh(appointment)
            payment.appointment_id = appointment.id
            payment.status = PaymentStatus.COMPLETED.value
            payment.payment_date = datetime.now()
            db.commit()
            db.refresh(payment)
    return {"message": "Flutterwave webhook processed"} 