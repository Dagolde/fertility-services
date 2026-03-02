from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid
import json

from app.database import get_db
from app.models import User, WalletTransaction, WalletTransactionType, PaymentStatus, PaymentGateway
from app.schemas import WalletFundRequest, WalletFundResponse, WalletBalanceResponse, WalletTransactionResponse
from app.auth import get_current_user
from app.services.paystack_service import PaystackService

router = APIRouter(tags=["Wallet"])

def generate_reference():
    """Generate unique reference for wallet transactions"""
    return f"WAL_{datetime.now().strftime('%Y%m%d%H%M%S')}_{str(uuid.uuid4())[:8].upper()}"

@router.get("/balance", response_model=WalletBalanceResponse)
async def get_wallet_balance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's wallet balance"""
    return {
        "user_id": current_user.id,
        "balance": float(current_user.wallet_balance),
        "currency": "NGN"
    }

@router.post("/fund", response_model=WalletFundResponse)
async def fund_wallet(
    request: WalletFundRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Fund user's wallet using payment gateway"""
    
    if request.amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Amount must be greater than 0"
        )
    
    # Generate unique reference
    reference = generate_reference()
    
    # Create wallet transaction record
    wallet_transaction = WalletTransaction(
        user_id=current_user.id,
        transaction_type=WalletTransactionType.FUND,
        amount=request.amount,
        currency=request.currency,
        description=f"Wallet funding - {request.description or 'Fund wallet'}",
        reference=reference,
        payment_gateway=request.payment_gateway,
        status=PaymentStatus.PENDING
    )
    
    db.add(wallet_transaction)
    db.commit()
    db.refresh(wallet_transaction)
    
    try:
        print(f"Payment gateway from request: {request.payment_gateway}")
        print(f"PaymentGateway.PAYSTACK: {PaymentGateway.PAYSTACK}")
        print(f"Are they equal? {request.payment_gateway == PaymentGateway.PAYSTACK}")
        
        # Initialize payment gateway service
        if request.payment_gateway == "paystack" or request.payment_gateway == PaymentGateway.PAYSTACK:
            # Use real Paystack API
            print(f"Using real Paystack API for live mode")
            
            paystack_service = PaystackService(db)
            paystack_response = paystack_service.initialize_transaction(
                email=current_user.email,
                amount=request.amount,
                currency=request.currency,
                reference=reference,
                callback_url=f"https://yourdomain.com/wallet/callback",
                metadata={
                    "user_id": current_user.id,
                    "user_name": f"{current_user.first_name} {current_user.last_name}",
                    "transaction_type": "wallet_funding"
                }
            )
            
            print(f"Paystack response: {paystack_response}")
            
            # Update wallet transaction with gateway reference
            wallet_transaction.gateway_reference = paystack_response["data"]["reference"]
            wallet_transaction.gateway_response = paystack_response
            db.commit()
            
            return {
                "transaction_id": wallet_transaction.id,
                "reference": reference,
                "amount": float(request.amount),
                "currency": request.currency,
                "payment_url": paystack_response["data"]["authorization_url"],
                "gateway_reference": paystack_response["data"]["reference"]
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported payment gateway"
            )
            
    except Exception as e:
        # Update transaction status to failed
        wallet_transaction.status = PaymentStatus.FAILED
        wallet_transaction.gateway_response = {"error": str(e)}
        db.commit()
        
        # Log the error for debugging
        print(f"Wallet funding error: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment initialization failed"
        )

@router.get("/transactions", response_model=List[WalletTransactionResponse])
async def get_wallet_transactions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 50
):
    """Get user's wallet transaction history"""
    
    transactions = db.query(WalletTransaction).filter(
        WalletTransaction.user_id == current_user.id
    ).order_by(
        WalletTransaction.created_at.desc()
    ).offset(skip).limit(limit).all()
    
    return [
        {
            "id": transaction.id,
            "transaction_type": transaction.transaction_type.value,
            "amount": float(transaction.amount),
            "currency": transaction.currency,
            "description": transaction.description,
            "reference": transaction.reference,
            "status": transaction.status.value,
            "created_at": transaction.created_at.isoformat(),
            "payment_gateway": transaction.payment_gateway.value if transaction.payment_gateway else None
        }
        for transaction in transactions
    ]

@router.post("/verify-payment/{reference}")
async def verify_wallet_payment(
    reference: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Verify wallet payment and update balance"""
    
    # Get wallet transaction
    wallet_transaction = db.query(WalletTransaction).filter(
        WalletTransaction.reference == reference,
        WalletTransaction.user_id == current_user.id
    ).first()
    
    if not wallet_transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found"
        )
    
    if wallet_transaction.status == PaymentStatus.COMPLETED:
        return {"message": "Payment already verified", "status": "completed"}
    
    try:
        # Verify payment with gateway
        if wallet_transaction.payment_gateway == PaymentGateway.PAYSTACK:
            paystack_service = PaystackService(db)
            verification_response = paystack_service.verify_transaction(reference)
            
            if verification_response.get("status") and verification_response["data"]["status"] == "success":
                # Update transaction status
                wallet_transaction.status = PaymentStatus.COMPLETED
                wallet_transaction.gateway_response = verification_response
                wallet_transaction.gateway_transaction_id = verification_response["data"]["id"]
                
                # Update user's wallet balance
                current_user.wallet_balance += wallet_transaction.amount
                
                db.commit()
                
                return {
                    "message": "Payment verified successfully",
                    "status": "completed",
                    "new_balance": float(current_user.wallet_balance)
                }
            else:
                # Update transaction status to failed
                wallet_transaction.status = PaymentStatus.FAILED
                wallet_transaction.gateway_response = verification_response
                db.commit()
                
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Payment verification failed"
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported payment gateway"
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Payment verification failed: {str(e)}"
        )

@router.post("/pay-from-wallet")
async def pay_from_wallet(
    amount: float,
    description: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Pay for services using wallet balance"""
    
    if amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Amount must be greater than 0"
        )
    
    if current_user.wallet_balance < amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance"
        )
    
    # Generate reference
    reference = generate_reference()
    
    # Create wallet transaction for payment
    wallet_transaction = WalletTransaction(
        user_id=current_user.id,
        transaction_type=WalletTransactionType.PAYMENT,
        amount=amount,
        currency="NGN",
        description=description,
        reference=reference,
        status=PaymentStatus.COMPLETED
    )
    
    # Update user's wallet balance
    current_user.wallet_balance -= amount
    
    db.add(wallet_transaction)
    db.commit()
    db.refresh(wallet_transaction)
    
    return {
        "message": "Payment successful",
        "transaction_id": wallet_transaction.id,
        "reference": reference,
        "amount": float(amount),
        "new_balance": float(current_user.wallet_balance)
    }
