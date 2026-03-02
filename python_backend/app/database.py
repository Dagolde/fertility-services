from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from decouple import config
import os

# Database configuration with environment variable support
DB_HOST = config("DB_HOST", default="localhost")
DB_PORT = config("DB_PORT", default="3307", cast=int)
DB_USER = config("DB_USER", default="fertility_user")
DB_PASSWORD = config("DB_PASSWORD", default="fertility_password")
DB_NAME = config("DB_NAME", default="fertility_services")

# Construct DATABASE_URL
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=config("DEBUG", default=False, cast=bool)
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class
Base = declarative_base()

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
