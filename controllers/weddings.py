# controllers/weddings.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from requests import Session
from db import SessionLocal
from schemas import WeddingCreate
from models.models import User
from schemas.wedding import WeddingListResponse, WeddingOut, WeddingOutBase
from services import auth_service
from services.auth_service import decode_token,set_last_active_wedding
from services.wedding_service import WeddingService   # ✅ use service layer
from utils.logger import get_logger
from utils.responses import error_response, created_response, success_response
from sqlalchemy.exc import SQLAlchemyError
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login") 
router = APIRouter()
LOGGER = get_logger("weddings")


def get_db():
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except:
        db.rollback()
        raise
    finally:
        db.close()


def get_current_user(token: str = Depends(oauth2_scheme), db=Depends(get_db)):
    """Decode JWT and return current user"""
    payload = decode_token(token)
    uid = payload.get("sub")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = db.query(User).filter(User.id == int(uid)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@router.post("/", response_model=WeddingOut)
def create_wedding(payload: WeddingCreate, current_user=Depends(get_current_user), db=Depends(get_db)):
    try:
        wedding = WeddingService.create_wedding(payload, current_user, db)
        set_last_active_wedding(current_user, wedding, db)

        return created_response(
            data=WeddingOut.model_validate(wedding),
            message="Wedding created"
        )
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


@router.post("/join/{code}", summary="Join Wedding by Code")
def join_wedding(
    code: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        print(current_user.first_name)
        result = WeddingService.join_wedding(code, current_user, db)
        
        wedding = result["wedding"]
        role = result["role"]
        message=result["messagge"]
        auth_service.set_last_active_wedding(current_user, wedding, db)
        return success_response(
            message=f"Joined wedding as {role}",
            data={
                "message":message,
                "role": role,
                "wedding": WeddingOutBase.model_validate(wedding)
            }
        )
    except ValueError as e:  
        return error_response(str(e))
    except Exception as e: 
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/switch/{wedding_id}", summary="Switch Active Wedding")
def switch_wedding(wedding_id: int, current_user: User = Depends(get_current_user)):
    """Switch active wedding context"""
    return WeddingService.switch_wedding(wedding_id, current_user)



@router.get("/", response_model=WeddingListResponse)
def list_weddings(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        weddings = WeddingService.list_weddings(current_user, db)
        return success_response(
            message="Weddings fetched successfully",
            data=weddings
        )
    except SQLAlchemyError as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")
