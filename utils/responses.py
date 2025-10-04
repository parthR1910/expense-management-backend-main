from fastapi import Request
from fastapi.responses import JSONResponse
from typing import Callable, Any
import json
from sqlalchemy.orm import DeclarativeBase
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel


def format_response(data: Any = None, message: str = "success", status_code: int = 200):
    """Standard response formatter"""
    return {
        "status": "ok" if status_code < 400 else "error",
        "message": message,
        "data": data,
    }


def success_response(
    data: any = None,
    message: str = "success",
    status_code: int = 200,
) -> JSONResponse:
    """Explicit success response"""

    
    data = jsonable_encoder(data)

    return JSONResponse(
        status_code=status_code,
        content=format_response(data=data, message=message, status_code=status_code),
    )
    
def created_response(
    data: any = None,
    message: str = "created",
    status_code: int = 201,
) -> JSONResponse:
    """Explicit success response"""

    
    data = jsonable_encoder(data)

    return JSONResponse(
        status_code=status_code,
        content=format_response(data=data, message=message, status_code=status_code),
    )    

def error_response(message: str = "error", status_code: int = 400, data: Any = None) -> JSONResponse:
    """Explicit error response"""
    return JSONResponse(
        status_code=status_code,
        content=format_response(data=data, message=message, status_code=status_code),
    )


def add_custom_response_middleware(app):
    """Middleware that ensures every response follows the standard format"""

    @app.middleware("http")
    async def _wrap_response(request: Request, call_next: Callable):
        response = await call_next(request)

        # If already JSONResponse (likely from success_response/error_response), return directly
        if isinstance(response, JSONResponse):
            return response

        # Try to parse response body
        try:
            body = b""
            async for chunk in response.body_iterator:
                body += chunk

            data = None
            if body:
                try:
                    data = json.loads(body.decode())
                except Exception:
                    data = body.decode()
        except Exception:
            data = None

        return JSONResponse(
            status_code=response.status_code,
            content=format_response(
                data=data,
                message="success" if response.status_code < 400 else "error",
                status_code=response.status_code,
            ),
        )
