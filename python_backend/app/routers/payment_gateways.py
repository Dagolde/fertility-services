from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from ..database import get_db
from ..models import User, PaymentGatewayConfig, PaymentGateway
from ..auth import get_admin_user

router = APIRouter()

@router.get("/", response_model=List[Dict[str, Any]])
async def get_payment_gateways(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get all payment gateway configurations (admin only)."""
    configs = db.query(PaymentGatewayConfig).all()
    
    # Convert to dict and mask sensitive data
    result = []
    for config in configs:
        config_dict = {
            "id": config.id,
            "gateway": config.gateway.value,
            "is_active": config.is_active,
            "is_test_mode": config.is_test_mode,
            "public_key": config.public_key,
            "secret_key": "***" if config.secret_key else None,  # Mask secret key
            "webhook_secret": "***" if config.webhook_secret else None,  # Mask webhook secret
            "supported_currencies": config.supported_currencies,
            "config_data": config.config_data,
            "created_at": config.created_at,
            "updated_at": config.updated_at
        }
        result.append(config_dict)
    
    return result

@router.get("/{gateway}")
async def get_payment_gateway_config(
    gateway: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get specific payment gateway configuration (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    return {
        "id": config.id,
        "gateway": config.gateway.value,
        "is_active": config.is_active,
        "is_test_mode": config.is_test_mode,
        "public_key": config.public_key,
        "secret_key": "***" if config.secret_key else None,  # Mask secret key
        "webhook_secret": "***" if config.webhook_secret else None,  # Mask webhook secret
        "supported_currencies": config.supported_currencies,
        "config_data": config.config_data,
        "created_at": config.created_at,
        "updated_at": config.updated_at
    }

@router.post("/")
async def create_payment_gateway_config(
    gateway_data: Dict[str, Any],
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Create payment gateway configuration (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway_data["gateway"].lower())
    except (ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or missing payment gateway"
        )
    
    # Check if configuration already exists
    existing_config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if existing_config:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment gateway configuration already exists"
        )
    
    # Create new configuration
    config = PaymentGatewayConfig(
        gateway=gateway_enum,
        is_active=gateway_data.get("is_active", False),
        is_test_mode=gateway_data.get("is_test_mode", True),
        public_key=gateway_data.get("public_key"),
        secret_key=gateway_data.get("secret_key"),
        webhook_secret=gateway_data.get("webhook_secret"),
        supported_currencies=gateway_data.get("supported_currencies", ["NGN"]),
        config_data=gateway_data.get("config_data", {})
    )
    
    db.add(config)
    db.commit()
    db.refresh(config)
    
    return {
        "message": "Payment gateway configuration created successfully",
        "gateway": config.gateway.value,
        "id": config.id
    }

@router.put("/{gateway}")
async def update_payment_gateway_config(
    gateway: str,
    gateway_data: Dict[str, Any],
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Update payment gateway configuration (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    # Update configuration
    if "is_active" in gateway_data:
        config.is_active = gateway_data["is_active"]
    if "is_test_mode" in gateway_data:
        config.is_test_mode = gateway_data["is_test_mode"]
    if "public_key" in gateway_data:
        config.public_key = gateway_data["public_key"]
    if "secret_key" in gateway_data:
        config.secret_key = gateway_data["secret_key"]
    if "webhook_secret" in gateway_data:
        config.webhook_secret = gateway_data["webhook_secret"]
    if "supported_currencies" in gateway_data:
        config.supported_currencies = gateway_data["supported_currencies"]
    if "config_data" in gateway_data:
        config.config_data = gateway_data["config_data"]
    
    config.updated_at = datetime.now()
    db.commit()
    
    return {
        "message": "Payment gateway configuration updated successfully",
        "gateway": config.gateway.value
    }

@router.delete("/{gateway}")
async def delete_payment_gateway_config(
    gateway: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Delete payment gateway configuration (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    db.delete(config)
    db.commit()
    
    return {
        "message": "Payment gateway configuration deleted successfully",
        "gateway": gateway
    }

@router.post("/{gateway}/activate")
async def activate_payment_gateway(
    gateway: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Activate payment gateway (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    # Validate required fields
    if not config.public_key or not config.secret_key:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot activate gateway: missing required keys"
        )
    
    config.is_active = True
    config.updated_at = datetime.now()
    db.commit()
    
    return {
        "message": f"{gateway.title()} payment gateway activated successfully",
        "gateway": config.gateway.value,
        "is_active": config.is_active
    }

@router.post("/{gateway}/deactivate")
async def deactivate_payment_gateway(
    gateway: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Deactivate payment gateway (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    config.is_active = False
    config.updated_at = datetime.now()
    db.commit()
    
    return {
        "message": f"{gateway.title()} payment gateway deactivated successfully",
        "gateway": config.gateway.value,
        "is_active": config.is_active
    }

@router.post("/{gateway}/test")
async def test_payment_gateway(
    gateway: str,
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Test payment gateway connection (admin only)."""
    try:
        gateway_enum = PaymentGateway(gateway.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid payment gateway"
        )
    
    config = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.gateway == gateway_enum
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Payment gateway configuration not found"
        )
    
    if not config.public_key or not config.secret_key:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot test gateway: missing required keys"
        )
    
    try:
        if gateway_enum == PaymentGateway.PAYSTACK:
            from ..services.paystack_service import PaystackService
            paystack_service = PaystackService(db)
            
            # Test by trying to list transactions (this validates the API keys)
            test_response = paystack_service.list_transactions(per_page=1)
            
            return {
                "status": "success",
                "message": f"{gateway.title()} connection test successful",
                "gateway": config.gateway.value,
                "test_mode": config.is_test_mode
            }
        else:
            return {
                "status": "success",
                "message": f"{gateway.title()} test not implemented yet",
                "gateway": config.gateway.value
            }
            
    except Exception as e:
        return {
            "status": "failed",
            "message": f"{gateway.title()} connection test failed: {str(e)}",
            "gateway": config.gateway.value
        }

@router.get("/stats/overview")
async def get_payment_gateway_stats(
    admin_user: User = Depends(get_admin_user),
    db: Session = Depends(get_db)
):
    """Get payment gateway statistics (admin only)."""
    from ..models import Payment
    
    total_configs = db.query(PaymentGatewayConfig).count()
    active_configs = db.query(PaymentGatewayConfig).filter(
        PaymentGatewayConfig.is_active == True
    ).count()
    
    # Get payment statistics by gateway
    gateway_stats = {}
    for gateway in PaymentGateway:
        payment_count = db.query(Payment).filter(
            Payment.payment_gateway == gateway
        ).count()
        
        successful_payments = db.query(Payment).filter(
            Payment.payment_gateway == gateway,
            Payment.status == "completed"
        ).count()
        
        gateway_stats[gateway.value] = {
            "total_payments": payment_count,
            "successful_payments": successful_payments,
            "success_rate": (successful_payments / payment_count * 100) if payment_count > 0 else 0
        }
    
    return {
        "total_gateway_configs": total_configs,
        "active_gateway_configs": active_configs,
        "gateway_stats": gateway_stats
    }
