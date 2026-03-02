from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime
import uuid
from decimal import Decimal

from ..database import get_db
from ..models import User, Payment, Appointment, Notification, PaymentGateway, PaymentStatus
from ..schemas import PaymentCreate, PaymentResponse
from ..auth import get_current_active_user, get_admin_user
from ..services.paystack_service import PaystackService

router = APIRouter()

@router.post("/", response_model=PaymentResponse)
async def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Create a payment for an appointment."""
    # Verify appointment exists and belongs to current user
    appointment = db.query(Appointment).filter(
        Appointment.id == payment_data.appointment_id,
        Appointment.user_id == current_user.id
    ).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found or not authorized"
        )
    
    # Check if payment already exists for this appointment
    existing_payment = db.query(Payment).filter(
        Payment.appointment_id == payment_data.appointment_id
    ).first()
    
    if existing_payment:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment already exists for this appointment"
        )
    
    # Validate payment amount matches appointment price
    if appointment.price and payment_data.amount != float(appointment.price):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment amount does not match appointment price"
        )
    
    # Create payment record
    db_payment = Payment(
        user_id=current_user.id,
        appointment_id=payment_data.appointment_id,
        amount=payment_data.amount,
        payment_method=payment_data.payment_method if payment_data.payment_method in [m.value for m in PaymentGateway] else PaymentGateway.PAYSTACK.value,
        status=PaymentStatus.PENDING.value
    )
    
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    
    # TODO: Integrate with actual payment gateway (Stripe, PayPal, etc.)
    # For now, we'll simulate payment processing
    
    return db_payment

@router.post("/{payment_id}/process")
async def process_payment(
    payment_id: int,
    transaction_id: str = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Process payment (simulate payment gateway response)."""
    payment = db.query(Payment).filter(
        Payment.id == payment_id,
        Payment.user_id == current_user.id
    ).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    if payment.status != PaymentStatus.PENDING.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment is not in pending status"
        )
    
    # TODO: Implement actual payment processing logic
    # For simulation, we'll mark it as completed
    payment.status = PaymentStatus.COMPLETED.value
    payment.transaction_id = transaction_id or f"TXN_{payment_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    payment.payment_date = datetime.now()
    
    # Update appointment status to confirmed after successful payment
    appointment = db.query(Appointment).filter(Appointment.id == payment.appointment_id).first()
    if appointment:
        appointment.status = "confirmed"
    
    db.commit()
    
    # Create notification
    notification = Notification(
        user_id=current_user.id,
        title="Payment Successful",
        message=f"Payment of ${payment.amount} has been processed successfully",
        notification_type="payment_success"
    )
    db.add(notification)
    db.commit()
    
    return {"message": "Payment processed successfully", "transaction_id": payment.transaction_id}

@router.get("/my-payments", response_model=List[PaymentResponse])
async def get_my_payments(
    skip: int = 0,
    limit: int = 50,
    status: str = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get current user's payments."""
    import logging
    from pydantic import ValidationError
    try:
        query = db.query(Payment).filter(Payment.user_id == current_user.id)
        if status:
            query = query.filter(Payment.status == status)
        payments = query.order_by(Payment.created_at.desc()).offset(skip).limit(limit).all()
        return payments
    except ValidationError as ve:
        logging.error(f"Pydantic validation error in /my-payments: {ve}")
        raise HTTPException(status_code=500, detail=f"Validation error: {ve}")
    except Exception as e:
        logging.error(f"Unexpected error in /my-payments: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {e}")

@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment_by_id(
    payment_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get payment by ID."""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    # Check if user has access to this payment
    if payment.user_id != current_user.id and current_user.user_type.value != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this payment"
        )
    
    return payment

@router.post("/{payment_id}/refund")
async def refund_payment(
    payment_id: int,
    reason: str = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Request refund for a payment."""
    payment = db.query(Payment).filter(
        Payment.id == payment_id,
        Payment.user_id == current_user.id
    ).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    if payment.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only completed payments can be refunded"
        )
    
    # Check if appointment allows refund (e.g., not completed, within refund period)
    appointment = db.query(Appointment).filter(Appointment.id == payment.appointment_id).first()
    if appointment and appointment.status == "completed":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot refund payment for completed appointment"
        )
    
    # TODO: Implement actual refund processing with payment gateway
    # For simulation, we'll mark it as refunded
    payment.status = "refunded"
    db.commit()
    
    # Create notification
    notification = Notification(
        user_id=current_user.id,
        title="Refund Processed",
        message=f"Refund of ${payment.amount} has been processed",
        notification_type="refund_processed"
    )
    db.add(notification)
    db.commit()
    
    return {"message": "Refund processed successfully"}

@router.post("/{payment_id}/refund")
async def refund_payment_admin(
    payment_id: int,
    db: Session = Depends(get_db),
    admin_user = Depends(get_admin_user),
):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.status != PaymentStatus.COMPLETED.value:
        raise HTTPException(status_code=400, detail="Only completed payments can be refunded")
    # TODO: Optionally call gateway API to process refund
    payment.status = PaymentStatus.REFUNDED.value
    db.commit()
    db.refresh(payment)
    # Log action (optional)
    return {"message": f"Payment {payment_id} refunded."}

@router.post("/{payment_id}/cancel")
async def cancel_payment_admin(
    payment_id: int,
    db: Session = Depends(get_db),
    admin_user = Depends(get_admin_user),
):
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    if payment.status not in [PaymentStatus.PENDING.value, PaymentStatus.CONFIRMED.value]:
        raise HTTPException(status_code=400, detail="Only pending or confirmed payments can be cancelled")
    # TODO: Optionally call gateway API to cancel payment
    payment.status = PaymentStatus.CANCELLED.value
    db.commit()
    db.refresh(payment)
    # Log action (optional)
    return {"message": f"Payment {payment_id} cancelled."}

# Paystack Integration Endpoints
@router.post("/paystack/initialize")
async def initialize_paystack_payment(
    appointment_id: int,
    currency: str = "NGN",
    callback_url: str = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Initialize Paystack payment for an appointment."""
    try:
        # Verify appointment exists and belongs to current user
        appointment = db.query(Appointment).filter(
            Appointment.id == appointment_id,
            Appointment.user_id == current_user.id
        ).first()
        
        if not appointment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Appointment not found or not authorized"
            )
        
        if not appointment.price:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Appointment price not set"
            )
        
        # Check if payment already exists for this appointment
        existing_payment = db.query(Payment).filter(
            Payment.appointment_id == appointment_id
        ).first()
        
        if existing_payment and existing_payment.status in [PaymentStatus.COMPLETED, PaymentStatus.PENDING]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment already exists for this appointment"
            )
        
        # Initialize Paystack service
        paystack_service = PaystackService(db)
        
        # Generate unique reference
        reference = f"apt_{appointment_id}_{uuid.uuid4().hex[:8]}"
        
        # Initialize transaction with Paystack
        paystack_response = paystack_service.initialize_transaction(
            email=current_user.email,
            amount=Decimal(str(appointment.price)),
            currency=currency,
            reference=reference,
            callback_url=callback_url,
            metadata={
                "appointment_id": appointment_id,
                "user_id": current_user.id,
                "user_name": f"{current_user.first_name} {current_user.last_name}"
            }
        )
        
        # Create or update payment record
        if existing_payment:
            payment = existing_payment
            payment.gateway_reference = reference
            payment.status = PaymentStatus.PENDING
        else:
            payment = Payment(
                user_id=current_user.id,
                appointment_id=appointment_id,
                amount=appointment.price,
                currency=currency,
                payment_gateway=PaymentGateway.PAYSTACK,
                transaction_id=reference,
                gateway_reference=reference,
                status=PaymentStatus.PENDING,
                gateway_response=paystack_response
            )
            db.add(payment)
        
        db.commit()
        db.refresh(payment)
        
        return {
            "payment_id": payment.id,
            "reference": reference,
            "authorization_url": paystack_response["data"]["authorization_url"],
            "access_code": paystack_response["data"]["access_code"],
            "amount": float(appointment.price),
            "currency": currency
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initialize payment: {str(e)}"
        )

@router.post("/paystack/verify/{reference}")
async def verify_paystack_payment(
    reference: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Verify Paystack payment."""
    try:
        # Find payment by reference
        payment = db.query(Payment).filter(
            Payment.gateway_reference == reference,
            Payment.user_id == current_user.id
        ).first()
        
        if not payment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Payment not found"
            )
        
        # Initialize Paystack service
        paystack_service = PaystackService(db)
        
        # Verify transaction with Paystack
        verification_response = paystack_service.verify_transaction(reference)
        
        if verification_response["status"] and verification_response["data"]["status"] == "success":
            # Update payment record
            payment.status = PaymentStatus.COMPLETED
            payment.gateway_transaction_id = verification_response["data"]["id"]
            payment.payment_method = verification_response["data"]["channel"]
            payment.authorization_code = verification_response["data"]["authorization"]["authorization_code"]
            payment.payment_date = datetime.now()
            payment.gateway_response = verification_response
            
            # Update appointment status to confirmed
            appointment = db.query(Appointment).filter(Appointment.id == payment.appointment_id).first()
            if appointment:
                appointment.status = "confirmed"
            
            db.commit()
            
            # Create notification
            notification = Notification(
                user_id=current_user.id,
                title="Payment Successful",
                message=f"Payment of {payment.currency} {payment.amount} has been processed successfully via Paystack",
                notification_type="payment_success"
            )
            db.add(notification)
            db.commit()
            
            return {
                "status": "success",
                "message": "Payment verified successfully",
                "payment_id": payment.id,
                "transaction_id": payment.gateway_transaction_id,
                "amount": float(payment.amount),
                "currency": payment.currency
            }
        else:
            # Payment failed
            payment.status = PaymentStatus.FAILED
            payment.gateway_response = verification_response
            db.commit()
            
            return {
                "status": "failed",
                "message": "Payment verification failed",
                "payment_id": payment.id
            }
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to verify payment: {str(e)}"
        )

@router.post("/paystack/webhook")
async def paystack_webhook(
    request: Request,
    db: Session = Depends(get_db)
):
    """Handle Paystack webhook events."""
    try:
        # Get request body and signature
        body = await request.body()
        signature = request.headers.get("x-paystack-signature", "")
        
        # Initialize Paystack service
        paystack_service = PaystackService(db)
        
        # Verify webhook signature
        if not paystack_service.verify_webhook_signature(body.decode(), signature):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid webhook signature"
            )
        
        # Parse webhook data
        import json
        webhook_data = json.loads(body.decode())
        event = webhook_data.get("event")
        data = webhook_data.get("data", {})
        
        if event == "charge.success":
            # Handle successful payment
            reference = data.get("reference")
            if reference:
                payment = db.query(Payment).filter(Payment.gateway_reference == reference).first()
                if payment and payment.status == PaymentStatus.PENDING:
                    payment.status = PaymentStatus.COMPLETED
                    payment.gateway_transaction_id = data.get("id")
                    payment.payment_method = data.get("channel")
                    payment.authorization_code = data.get("authorization", {}).get("authorization_code")
                    payment.payment_date = datetime.now()
                    payment.gateway_response = webhook_data
                    
                    # Update appointment status
                    appointment = db.query(Appointment).filter(Appointment.id == payment.appointment_id).first()
                    if appointment:
                        appointment.status = "confirmed"
                    
                    db.commit()
        
        elif event == "charge.failed":
            # Handle failed payment
            reference = data.get("reference")
            if reference:
                payment = db.query(Payment).filter(Payment.gateway_reference == reference).first()
                if payment:
                    payment.status = PaymentStatus.FAILED
                    payment.gateway_response = webhook_data
                    db.commit()
        
        return {"status": "success"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Webhook processing failed: {str(e)}"
        )

@router.get("/appointment/{appointment_id}", response_model=PaymentResponse)
async def get_payment_by_appointment(
    appointment_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Get payment for a specific appointment."""
    # Verify appointment belongs to current user
    appointment = db.query(Appointment).filter(
        Appointment.id == appointment_id,
        Appointment.user_id == current_user.id
    ).first()
    
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found or not authorized"
        )
    
    payment = db.query(Payment).filter(Payment.appointment_id == appointment_id).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found for this appointment"
        )
    
    return payment

# Admin endpoints
@router.get("/admin/all", response_model=List[PaymentResponse])
async def get_all_payments(
    skip: int = 0,
    limit: int = 100,
    status: str = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all payments (admin only)."""
    query = db.query(Payment)
    
    if status:
        query = query.filter(Payment.status == status)
    
    payments = query.order_by(Payment.created_at.desc()).offset(skip).limit(limit).all()
    return payments

@router.put("/admin/{payment_id}/status")
async def update_payment_status(
    payment_id: int,
    new_status: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update payment status (admin only)."""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    
    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment not found"
        )
    
    valid_statuses = ["pending", "completed", "failed", "refunded"]
    if new_status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
        )
    
    payment.status = new_status
    if new_status == "completed" and not payment.payment_date:
        payment.payment_date = datetime.now()
    
    db.commit()
    
    return {"message": f"Payment status updated to {new_status}"}

@router.get("/stats/overview")
async def get_payment_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get payment statistics (admin only)."""
    total_payments = db.query(Payment).count()
    completed_payments = db.query(Payment).filter(Payment.status == "completed").count()
    pending_payments = db.query(Payment).filter(Payment.status == "pending").count()
    failed_payments = db.query(Payment).filter(Payment.status == "failed").count()
    refunded_payments = db.query(Payment).filter(Payment.status == "refunded").count()
    
    # Calculate total revenue
    total_revenue = db.query(Payment).filter(Payment.status == "completed").with_entities(
        db.func.sum(Payment.amount)
    ).scalar() or 0
    
    return {
        "total_payments": total_payments,
        "completed_payments": completed_payments,
        "pending_payments": pending_payments,
        "failed_payments": failed_payments,
        "refunded_payments": refunded_payments,
        "total_revenue": float(total_revenue),
        "success_rate": (completed_payments / total_payments * 100) if total_payments > 0 else 0
    }
