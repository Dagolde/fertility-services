from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body

from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_, case

from datetime import datetime, timedelta
import uuid

from ..database import get_db
from ..models import User, Hospital, Service, Appointment, Payment, Message, Notification, WalletTransaction, WalletTransactionType, PaymentStatus
from ..schemas import (
    UserResponse, HospitalResponse, ServiceResponse, 
    AppointmentResponse, PaymentResponse, NotificationCreate, PaymentStatusEnum
)


from ..auth import get_admin_user

router = APIRouter()

@router.get("/dashboard")
async def get_admin_dashboard(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get admin dashboard overview."""
    try:
        thirty_days_ago = datetime.now() - timedelta(days=30)

        # User statistics
        user_stats = db.query(
            func.count(User.id).label("total"),
            func.sum(case((User.is_active == True, 1), else_=0)).label("active"),
            func.sum(case((User.is_verified == True, 1), else_=0)).label("verified"),
            func.sum(case((User.created_at >= thirty_days_ago, 1), else_=0)).label("new_last_30_days"),
            func.sum(case((User.user_type == "patient", 1), else_=0)).label("patients"),
            func.sum(case((User.user_type == "sperm_donor", 1), else_=0)).label("sperm_donors"),
            func.sum(case((User.user_type == "egg_donor", 1), else_=0)).label("egg_donors"),
            func.sum(case((User.user_type == "surrogate", 1), else_=0)).label("surrogates"),
            func.sum(case((User.user_type == "hospital", 1), else_=0)).label("hospitals")
        ).one()

        # Hospital statistics
        hospital_stats = db.query(
            func.count(Hospital.id).label("total"),
            func.sum(case((Hospital.is_verified == True, 1), else_=0)).label("verified")
        ).one()

        # Service statistics
        service_stats = db.query(
            func.count(Service.id).label("total"),
            func.sum(case((Service.is_active == True, 1), else_=0)).label("active")
        ).one()

        # Appointment statistics
        appointment_stats = db.query(
            func.count(Appointment.id).label("total"),
            func.sum(case((Appointment.status == "pending", 1), else_=0)).label("pending"),
            func.sum(case((Appointment.status == "confirmed", 1), else_=0)).label("confirmed"),
            func.sum(case((Appointment.status == "completed", 1), else_=0)).label("completed"),
            func.sum(case((Appointment.created_at >= thirty_days_ago, 1), else_=0)).label("new_last_30_days")
        ).one()

        # Payment statistics
        payment_stats = db.query(
            func.count(Payment.id).label("total"),
            func.sum(case((Payment.status == "completed", 1), else_=0)).label("completed"),
            func.sum(case((Payment.status == "completed", Payment.amount), else_=0)).label("total_revenue")
        ).one()
        total_revenue = payment_stats.total_revenue or 0

        return {
            "users": {
                "total": user_stats.total or 0,
                "active": user_stats.active or 0,
                "verified": user_stats.verified or 0,
                "new_last_30_days": user_stats.new_last_30_days or 0,
                "by_type": {
                    "patients": user_stats.patients or 0,
                    "sperm_donors": user_stats.sperm_donors or 0,
                    "egg_donors": user_stats.egg_donors or 0,
                    "surrogates": user_stats.surrogates or 0,
                    "hospitals": user_stats.hospitals or 0
                }
            },
            "hospitals": {
                "total": hospital_stats.total or 0,
                "verified": hospital_stats.verified or 0,
                "pending_verification": (hospital_stats.total or 0) - (hospital_stats.verified or 0)
            },
            "services": {
                "total": service_stats.total or 0,
                "active": service_stats.active or 0,
                "inactive": (service_stats.total or 0) - (service_stats.active or 0)
            },
            "appointments": {
                "total": appointment_stats.total or 0,
                "pending": appointment_stats.pending or 0,
                "confirmed": appointment_stats.confirmed or 0,
                "completed": appointment_stats.completed or 0,
                "new_last_30_days": appointment_stats.new_last_30_days or 0
            },
            "payments": {
                "total": payment_stats.total or 0,
                "completed": payment_stats.completed or 0,
                "total_revenue": float(total_revenue),
                "success_rate": ((payment_stats.completed or 0) / (payment_stats.total or 1) * 100)
            }
        }
    except Exception as e:
        # Log the error here if you have a logger configured
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"An error occurred while fetching dashboard data: {str(e)}"
        )


@router.get("/users/recent", response_model=List[UserResponse])
async def get_recent_users(
    limit: int = 10,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get recently registered users."""
    users = db.query(User).order_by(User.created_at.desc()).limit(limit).all()
    return users

@router.get("/hospitals/pending", response_model=List[HospitalResponse])
async def get_pending_hospitals(
    limit: int = 20,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get hospitals pending verification."""
    hospitals = db.query(Hospital).filter(
        Hospital.is_verified == False
    ).order_by(Hospital.created_at.desc()).limit(limit).all()
    return hospitals

@router.get("/appointments/recent", response_model=List[AppointmentResponse])
async def get_recent_appointments(
    limit: int = 20,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get recent appointments."""
    appointments = db.query(Appointment).order_by(
        Appointment.created_at.desc()
    ).limit(limit).all()
    return appointments

@router.get("/payments/recent", response_model=List[PaymentResponse])
async def get_recent_payments(
    limit: int = 20,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get recent payments."""
    payments = db.query(Payment).order_by(
        Payment.created_at.desc()
    ).limit(limit).all()
    return payments

@router.get("/payments/all", response_model=List[PaymentResponse])
async def get_all_payments(
    skip: int = 0,
    limit: int = 100,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Get all payments."""
    payments = db.query(Payment).order_by(Payment.created_at.desc()).offset(skip).limit(limit).all()
    return payments


@router.put("/payments/{payment_id}/status", response_model=PaymentResponse)
async def update_payment_status(
    payment_id: int,
    status_data: dict = Body(...),
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Update payment status by admin."""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    
    new_status = status_data.get("status")
    if not new_status or new_status not in [item.value for item in PaymentStatusEnum]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status")


    payment.status = new_status
    payment.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(payment)
    return payment


@router.delete("/payments/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_payment(
    payment_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Delete a payment by admin."""
    payment = db.query(Payment).filter(Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")

    db.delete(payment)
    db.commit()
    return


@router.post("/notifications/broadcast")
async def broadcast_notification(
    title: str,
    message: str,
    user_type: str = None,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Broadcast notification to all users or specific user type."""
    query = db.query(User).filter(User.is_active == True)
    
    if user_type:
        query = query.filter(User.user_type == user_type)
    
    users = query.all()
    
    notifications = []
    for user in users:
        notification = Notification(
            user_id=user.id,
            title=title,
            message=message,
            notification_type="admin_broadcast"
        )
        notifications.append(notification)
    
    db.add_all(notifications)
    db.commit()
    
    return {
        "message": f"Notification sent to {len(notifications)} users",
        "recipients": len(notifications)
    }

@router.get("/analytics/user-growth")
async def get_user_growth_analytics(
    days: int = 30,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get user growth analytics."""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # Daily user registrations
    daily_registrations = []
    current_date = start_date
    
    while current_date <= end_date:
        next_date = current_date + timedelta(days=1)
        count = db.query(User).filter(
            and_(
                User.created_at >= current_date,
                User.created_at < next_date
            )
        ).count()
        
        daily_registrations.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "count": count
        })
        current_date = next_date
    
    return {
        "period": f"{days} days",
        "daily_registrations": daily_registrations,
        "total_new_users": sum(day["count"] for day in daily_registrations)
    }

@router.get("/analytics/appointment-trends")
async def get_appointment_trends(
    days: int = 30,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get appointment trends analytics."""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # Daily appointments
    daily_appointments = []
    current_date = start_date
    
    while current_date <= end_date:
        next_date = current_date + timedelta(days=1)
        count = db.query(Appointment).filter(
            and_(
                Appointment.created_at >= current_date,
                Appointment.created_at < next_date
            )
        ).count()
        
        daily_appointments.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "count": count
        })
        current_date = next_date
    
    # Appointments by service type
    service_stats = db.query(
        Service.service_type,
        func.count(Appointment.id).label('count')
    ).join(Appointment).filter(
        Appointment.created_at >= start_date
    ).group_by(Service.service_type).all()
    
    return {
        "period": f"{days} days",
        "daily_appointments": daily_appointments,
        "by_service_type": [
            {"service_type": stat.service_type, "count": stat.count}
            for stat in service_stats
        ],
        "total_appointments": sum(day["count"] for day in daily_appointments)
    }

@router.get("/analytics/revenue")
async def get_revenue_analytics(
    days: int = 30,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get revenue analytics."""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    # Daily revenue
    daily_revenue = []
    current_date = start_date
    
    while current_date <= end_date:
        next_date = current_date + timedelta(days=1)
        revenue = db.query(Payment).filter(
            and_(
                Payment.payment_date >= current_date,
                Payment.payment_date < next_date,
                Payment.status == "completed"
            )
        ).with_entities(func.sum(Payment.amount)).scalar() or 0
        
        daily_revenue.append({
            "date": current_date.strftime("%Y-%m-%d"),
            "revenue": float(revenue)
        })
        current_date = next_date
    
    # Total revenue
    total_revenue = sum(day["revenue"] for day in daily_revenue)
    
    # Average transaction value
    completed_payments = db.query(Payment).filter(
        and_(
            Payment.payment_date >= start_date,
            Payment.status == "completed"
        )
    ).count()
    
    avg_transaction = total_revenue / completed_payments if completed_payments > 0 else 0
    
    return {
        "period": f"{days} days",
        "daily_revenue": daily_revenue,
        "total_revenue": total_revenue,
        "total_transactions": completed_payments,
        "average_transaction_value": avg_transaction
    }

@router.get("/system/health")
async def get_system_health(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get system health status."""
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_status = "healthy"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    # Check for any critical issues
    inactive_users = db.query(User).filter(User.is_active == False).count()
    unverified_hospitals = db.query(Hospital).filter(Hospital.is_verified == False).count()
    failed_payments = db.query(Payment).filter(Payment.status == "failed").count()
    
    return {
        "database": db_status,
        "timestamp": datetime.now().isoformat(),
        "alerts": {
            "inactive_users": inactive_users,
            "unverified_hospitals": unverified_hospitals,
            "failed_payments": failed_payments
        }
    }

@router.post("/users/{user_id}/toggle-status")
async def toggle_user_status(
    user_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Toggle user active status."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    user.is_active = not user.is_active
    db.commit()
    
    # Create notification
    notification = Notification(
        user_id=user.id,
        title="Account Status Updated",
        message=f"Your account has been {'activated' if user.is_active else 'deactivated'}",
        notification_type="account_status"
    )
    db.add(notification)
    db.commit()
    
    return {
        "message": f"User {'activated' if user.is_active else 'deactivated'} successfully",
        "user_id": user_id,
        "is_active": user.is_active
    }

@router.post("/hospitals/{hospital_id}/toggle-verification")
async def toggle_hospital_verification(
    hospital_id: int,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Toggle hospital verification status."""
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )
    
    hospital.is_verified = not hospital.is_verified
    db.commit()
    
    # Create notification for hospital user
    notification = Notification(
        user_id=hospital.user_id,
        title="Hospital Verification Updated",
        message=f"Your hospital has been {'verified' if hospital.is_verified else 'unverified'}",
        notification_type="hospital_verification"
    )
    db.add(notification)
    db.commit()
    
    return {
        "message": f"Hospital {'verified' if hospital.is_verified else 'unverified'} successfully",
        "hospital_id": hospital_id,
        "is_verified": hospital.is_verified
    }

@router.get("/wallet/transactions")
async def get_all_wallet_transactions(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100,
    user_id: Optional[int] = None,
    transaction_type: Optional[str] = None,
    status: Optional[str] = None
):
    """Get all wallet transactions with optional filtering."""
    query = db.query(WalletTransaction).join(User)
    
    if user_id:
        query = query.filter(WalletTransaction.user_id == user_id)
    
    if transaction_type:
        query = query.filter(WalletTransaction.transaction_type == transaction_type)
    
    if status:
        query = query.filter(WalletTransaction.status == status)
    
    transactions = query.order_by(WalletTransaction.created_at.desc()).offset(skip).limit(limit).all()
    
    return [
        {
            "id": transaction.id,
            "user_id": transaction.user_id,
            "user_email": transaction.user.email,
            "user_name": f"{transaction.user.first_name} {transaction.user.last_name}",
            "transaction_type": transaction.transaction_type.value,
            "amount": float(transaction.amount),
            "currency": transaction.currency,
            "description": transaction.description,
            "reference": transaction.reference,
            "status": transaction.status.value,
            "payment_gateway": transaction.payment_gateway.value if transaction.payment_gateway else None,
            "created_at": transaction.created_at.isoformat(),
            "updated_at": transaction.updated_at.isoformat()
        }
        for transaction in transactions
    ]

@router.get("/wallet/users")
async def get_users_with_wallets(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    """Get all users with their wallet balances."""
    users = db.query(User).filter(User.wallet_balance > 0).offset(skip).limit(limit).all()
    
    return [
        {
            "user_id": user.id,
            "email": user.email,
            "name": f"{user.first_name} {user.last_name}",
            "wallet_balance": float(user.wallet_balance),
            "currency": "NGN",
            "is_active": user.is_active,
            "created_at": user.created_at.isoformat()
        }
        for user in users
    ]

@router.post("/wallet/users/{user_id}/adjust-balance")
async def adjust_user_wallet_balance(
    user_id: int,
    adjustment_data: dict = Body(...),
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Adjust user's wallet balance (add or subtract)."""
    try:
        print(f"Adjusting wallet balance for user {user_id}")
        print(f"Adjustment data: {adjustment_data}")
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            print(f"User {user_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        amount = adjustment_data.get("amount")
        operation = adjustment_data.get("operation")  # "add" or "subtract"
        reason = adjustment_data.get("reason", "Admin adjustment")
        
        print(f"Amount: {amount}, Operation: {operation}, Reason: {reason}")
        
        if not amount or amount <= 0:
            print(f"Invalid amount: {amount}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Amount must be greater than 0"
            )
        
        if operation not in ["add", "subtract"]:
            print(f"Invalid operation: {operation}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Operation must be 'add' or 'subtract'"
            )
        
        print(f"Current wallet balance: {user.wallet_balance}")
        
        if operation == "subtract" and user.wallet_balance < amount:
            print(f"Insufficient balance: {user.wallet_balance} < {amount}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient wallet balance"
            )
        
        # Create wallet transaction record
        transaction_type = WalletTransactionType.FUND if operation == "add" else WalletTransactionType.WITHDRAWAL
        reference = f"ADMIN_{datetime.now().strftime('%Y%m%d%H%M%S')}_{str(uuid.uuid4())[:8].upper()}"
        
        print(f"Creating transaction: {transaction_type}, {reference}")
        
        wallet_transaction = WalletTransaction(
            user_id=user.id,
            transaction_type=transaction_type,
            amount=amount,
            currency="NGN",
            description=f"Admin {operation}: {reason}",
            reference=reference,
            status=PaymentStatus.COMPLETED
        )
        
        # Convert amount to Decimal for consistent arithmetic operations
        from decimal import Decimal
        amount_decimal = Decimal(str(amount))
        
        # Update user's wallet balance
        if operation == "add":
            user.wallet_balance += amount_decimal
        else:
            user.wallet_balance -= amount_decimal
        
        print(f"New wallet balance: {user.wallet_balance}")
        
        db.add(wallet_transaction)
        db.commit()
        db.refresh(wallet_transaction)
        
        # Create notification for user
        notification = Notification(
            user_id=user.id,
            title="Wallet Balance Updated",
            message=f"Your wallet balance has been {operation}ed by {amount} NGN. Reason: {reason}",
            notification_type="wallet_update"
        )
        db.add(notification)
        db.commit()
        
        print(f"Wallet balance adjustment successful for user {user_id}")
        
        return {
            "message": f"Wallet balance {operation}ed successfully",
            "user_id": user_id,
            "amount": float(amount),
            "operation": operation,
            "new_balance": float(user.wallet_balance),
            "transaction_id": wallet_transaction.id,
            "reference": reference
        }
    except Exception as e:
        print(f"Error adjusting wallet balance: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to adjust wallet balance: {str(e)}"
        )

@router.get("/wallet/statistics")
async def get_wallet_statistics(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get wallet system statistics."""
    try:
        # Total wallet balance across all users
        total_balance = db.query(func.sum(User.wallet_balance)).scalar() or 0
        
        # Users with wallets
        users_with_wallets = db.query(func.count(User.id)).filter(User.wallet_balance > 0).scalar() or 0
        
        # Transaction statistics
        total_transactions = db.query(func.count(WalletTransaction.id)).scalar() or 0
        
        # Transaction type breakdown
        fund_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.transaction_type == WalletTransactionType.FUND
        ).scalar() or 0
        
        payment_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.transaction_type == WalletTransactionType.PAYMENT
        ).scalar() or 0
        
        withdrawal_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.transaction_type == WalletTransactionType.WITHDRAWAL
        ).scalar() or 0
        
        refund_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.transaction_type == WalletTransactionType.REFUND
        ).scalar() or 0
        
        # Status breakdown
        completed_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.status == PaymentStatus.COMPLETED
        ).scalar() or 0
        
        pending_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.status == PaymentStatus.PENDING
        ).scalar() or 0
        
        failed_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.status == PaymentStatus.FAILED
        ).scalar() or 0
        
        # Recent activity (last 30 days)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        recent_transactions = db.query(func.count(WalletTransaction.id)).filter(
            WalletTransaction.created_at >= thirty_days_ago
        ).scalar() or 0
        
        recent_balance_added = db.query(func.sum(WalletTransaction.amount)).filter(
            and_(
                WalletTransaction.transaction_type == WalletTransactionType.FUND,
                WalletTransaction.status == PaymentStatus.COMPLETED,
                WalletTransaction.created_at >= thirty_days_ago
            )
        ).scalar() or 0
        
        return {
            "total_balance": float(total_balance),
            "users_with_wallets": users_with_wallets,
            "total_transactions": total_transactions,
            "transaction_types": {
                "fund": fund_transactions,
                "payment": payment_transactions,
                "withdrawal": withdrawal_transactions,
                "refund": refund_transactions
            },
            "transaction_status": {
                "completed": completed_transactions,
                "pending": pending_transactions,
                "failed": failed_transactions
            },
            "recent_activity": {
                "transactions_last_30_days": recent_transactions,
                "balance_added_last_30_days": float(recent_balance_added)
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching wallet statistics: {str(e)}"
        )
