# app.py
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from db import Base, engine
from utils.logger import get_logger
from controllers import auth, weddings, tasks, budgets, vendors, guests, schedules, collaborators, messages
from fastapi.security import OAuth2PasswordBearer
from fastapi import Depends, FastAPI
LOGGER = get_logger("app")
from settings import MEDIA_DIR


def create_app():
    # Create FastAPI app with metadata (Swagger UI config)
    oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="auth/login",   # adjust to your login endpoint
    scheme_name="JWT"
    )
    app = FastAPI(
        title="Wedding Management API",
        description="""
        API for managing weddings, tasks, budgets, vendors, guests, schedules,
        collaborators, and chat messages.
        """,
        version="1.0.0",
        docs_url="/docs",          # Swagger UI available here
        redoc_url="/redoc",        # ReDoc UI available here
        openapi_url="/openapi.json"  # OpenAPI schema
    )

    Base.metadata.create_all(bind=engine)
   

    app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")
    app.include_router(auth.router, prefix="/auth", tags=["Auth"])
    app.include_router(weddings.router, prefix="/weddings", tags=["Weddings"])
    app.include_router(tasks.router, prefix="/tasks", tags=["Tasks"])
    app.include_router(budgets.router, prefix="/budgets", tags=["Budgets"])
    app.include_router(vendors.router, prefix="/vendors", tags=["Vendors"])
    app.include_router(guests.router, prefix="/guests", tags=["Guests"])
    app.include_router(schedules.router, prefix="/schedules", tags=["Schedules"])
    app.include_router(collaborators.router, prefix="/collaborators", tags=["Collaborators"])
    app.include_router(messages.router, prefix="/messages", tags=["Messages"])

    LOGGER.info("Application setup complete with Swagger UI enabled.")
    return app
