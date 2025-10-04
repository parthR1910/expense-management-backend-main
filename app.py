# app.py
import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from db import Base, engine
from utils.logger import get_logger
from controllers import auth,company,expense,expense_approval,approval_workflow,approval_rule
from fastapi.security import OAuth2PasswordBearer
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Depends, FastAPI
LOGGER = get_logger("app")
from settings import MEDIA_DIR


def create_app():
    # OAuth2
    oauth2_scheme = OAuth2PasswordBearer(
        tokenUrl="auth/login",
        scheme_name="JWT"
    )
    
    app = FastAPI(
        title="Wedding Management API",
        description="""
        API for managing weddings, tasks, budgets, vendors, guests, schedules,
        collaborators, and chat messages.
        """,
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json"
    )

    # Create tables
    Base.metadata.create_all(bind=engine)

    # Mount media folder
    app.mount("/media", StaticFiles(directory=MEDIA_DIR), name="media")

    # Include routers
    app.include_router(auth.router, prefix="/auth", tags=["Auth"])
    app.include_router(company.router, prefix="/company", tags=["Company"])
    app.include_router(expense.router, prefix="/expenses", tags=["Expense"])
    app.include_router(expense_approval.router, prefix="/expense-approvals", tags=["Expense Approvals"])
    app.include_router(approval_workflow.router, prefix="/approval-workflows", tags=["Approval Workflows"])
    app.include_router(approval_rule.router, prefix="/approval-rules", tags=["Approval Rules"])
    

    # -------------------- CORS Setup --------------------
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # allow your frontend domain in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    # ------------------------------------------------------

    LOGGER.info("Application setup complete with Swagger UI enabled.")
    return app

