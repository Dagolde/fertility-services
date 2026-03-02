import sys
sys.path.append('/app')

from app.database import get_db
from app.models import User, UserType
from app.auth import get_password_hash
from datetime import datetime

# Get database session
db = next(get_db())

# Create admin user
admin_user = User(
    email="admin@fertilityservices.com",
    password_hash=get_password_hash("admin123"),
    first_name="Admin",
    last_name="User",
    user_type=UserType.ADMIN,
    is_active=True,
    is_verified=True,
    profile_completed=True
)

# Add to database
db.add(admin_user)
db.commit()
db.refresh(admin_user)

print(f"Admin user created with ID: {admin_user.id}")
print(f"Password hash: {admin_user.password_hash}")
