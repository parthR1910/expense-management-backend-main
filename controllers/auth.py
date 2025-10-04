# controllers/auth.py
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from fastapi.params import Form
from fastapi.security import OAuth2PasswordRequestForm
from requests import Session
from controllers.weddings import get_current_user
from db import SessionLocal
from schemas.auth import UserOut, UserUpdate
from services.auth_service import create_user, get_user_by_email, update_user_profile, verify_password, create_access_token
from services.collaborator_service import CollaboratorService
from services.device_service import upsert_device
from services.wedding_service import WeddingService
from schemas import UserCreate, UserLogin, Token,DeviceCreate,UserOutWithBearer,WeddingOut
from models.models import Wedding
from utils.logger import get_logger
import secrets
from fastapi import status
from utils.responses import success_response, error_response
from sqlalchemy.exc import SQLAlchemyError


router = APIRouter()
LOGGER = get_logger("auth")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def build_user_response(user, token: str) -> UserOutWithBearer:
    """Helper to build consistent response with bearer token"""
    return UserOutWithBearer(
        id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        bearer=Token(access_token=token, token_type="bearer"),
    )


@router.post(
    "/register",
    response_model=UserOutWithBearer,
    responses={201: {"message": "User registered successfully"}},
    status_code=status.HTTP_201_CREATED,
)
def register(payload: UserCreate, db=Depends(get_db)):
    existing = get_user_by_email(db, payload.email)
    if existing:
        return error_response(
            message="Email already registered",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    # 🔹 Create user with flexible auth
    user = create_user(
        db,
        email=payload.email,
        password=payload.password,
        google_uid=payload.google_uid,
        first_name=payload.first_name,
        last_name=payload.last_name,
        login_type=payload.login_type,
    )

    # 🔹 Create token
    token = create_access_token({"sub": str(user.id), "email": user.email})

    if payload.device:
        upsert_device(db, payload.device, user.id, token)


    # 🔹 Build response
    user_res = UserOutWithBearer(
        id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        bearer=Token(access_token=token, token_type="bearer"),
    )

    LOGGER.info(f"New user created: {user.email}")
    return success_response(
        data=user_res.dict(),
        message="User registered successfully",
        status_code=status.HTTP_201_CREATED,
    )
    
@router.post("/login", status_code=status.HTTP_200_OK)
def login(payload: UserLogin, db=Depends(get_db)):
    user = get_user_by_email(db, payload.email)
    if not user:
        return error_response(
            message="Invalid credentials",
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    # ------------------ Handle Google Login ------------------
    if payload.google_uid:
        if not user.google_uid or user.google_uid != payload.google_uid:
            return error_response(
                message="Invalid Google account",
                status_code=status.HTTP_401_UNAUTHORIZED
            )

    # ------------------ Handle Email/Password Login ------------------
    else:
        if not user.hashed_password or not payload.password:
            return error_response(
                message="Password login not available for this account",
                status_code=status.HTTP_401_UNAUTHORIZED
            )
        if not verify_password(payload.password, user.hashed_password):
            return error_response(
                message="Invalid email or password",
                status_code=status.HTTP_401_UNAUTHORIZED
            )

    # ------------------ Create Access Token ------------------
    token = create_access_token({"sub": str(user.id), "email": user.email})

    # ------------------ Device handling via service ------------------
    if payload.device:
        upsert_device(db, payload.device, user.id, token)

    getRole = CollaboratorService.getRole(user, db)
    if getRole:
        if isinstance(getRole, tuple):   # unpack tuple
            getRole = getRole[0]
    # ------------------ Fetch weddings via service ------------------
    weddings = WeddingService.get_weddings_for_user(user.id, db)
    wedding_out_list = [WeddingOut.model_validate(w) for w in weddings]

    # ------------------ Build response ------------------
    user_res = {
    "user": {
        "id": user.id,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "login_type": user.login_type,
        "bearer": Token(access_token=token, token_type="bearer").dict(),
        "last_active_wedding": (
            WeddingOut.model_validate(user.last_active_wedding).dict()
            if user.last_active_wedding else None
        ),
    },
    "role": getRole.value if getRole else None,
    }


    LOGGER.info(f"User logged in: {user.email}")
    return success_response(
        data=user_res,
        message="Login successful",
        status_code=status.HTTP_200_OK
    )
    
@router.post("/token", response_model=Token)
def login_for_token(form_data: OAuth2PasswordRequestForm = Depends(), db=Depends(get_db)):
    user = get_user_by_email(db, form_data.username)
    if not user or not user.hashed_password or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect credentials")
    token = create_access_token({"sub": str(user.id), "email": user.email})
    return {"access_token": token, "token_type": "bearer"}

# Google login placeholder:
@router.post("/google")
def google_login(token: str, db=Depends(get_db), device: DeviceCreate = None):
    # TODO: verify Google token properly
    # Fake email extraction from Google payload
    email = "google_user@example.com"

    user = get_user_by_email(db, email)
    if not user:
        user = create_user(db, email, password=secrets.token_urlsafe(8))  # random password for social login
    
    # If device data is provided, save it
    # if device:
    #     upsert_device(db, payload.device, user.id, token)

    return {"detail": "Google login successful", "user_id": user.id}

@router.put("/", response_model=UserOut)
async def update_task(
    first_name: str | None = Form(None),
    last_name: str | None = Form(None),
    photo: UploadFile | None = File(None),
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    try:
        
        payload = UserUpdate(
            first_name=first_name,
            last_name=last_name,
        )

       
        photo_url = None
        if photo:
            file_location = f"media/{photo.filename}"
            with open(file_location, "wb") as f:
                f.write(await photo.read())
            photo_url = file_location


        task = update_user_profile(db,current_user.id, payload, photo_url)

        if not task:
            return error_response(message="Task not found", status_code=404)

        return success_response(
            data=UserOut.model_validate(task),
            message="Task updated"
        )

    except SQLAlchemyError as e:
        return error_response(message=f"Database error: {str(e)}", status_code=500)
    except Exception as e:
        return error_response(message=f"Unexpected error: {str(e)}", status_code=500)
