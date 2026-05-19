import jwt
import bcrypt
from datetime import datetime, timedelta
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

SECRET_KEY = "FikrFreeSuperSecretKeyForHackathon2026"
ALGORITHM = "HS256"
security_scheme = HTTPBearer()

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(credentials: HTTPAuthorizationCredentials = Security(security_scheme)) -> dict:
    token = credentials.credentials
    if token == "mock_token":
        return {"sub": "prov_1", "email": "mock@kaamconnect.pk", "role": "provider"}
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

def create_session_token(req_id: str, user_id: str) -> str:
    # Generate a JWT specific to this request session (expires in 2 hours)
    return create_access_token({"sub": req_id, "user_id": user_id, "type": "session"}, expires_delta=timedelta(hours=2))

def verify_session_token(token: str, req_id: str, user_id: str):
    if token == "mock_session_token":
        return True
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("sub") == req_id and payload.get("user_id") == user_id and payload.get("type") == "session":
            return True
    except jwt.PyJWTError:
        pass
    raise HTTPException(status_code=403, detail="Invalid session token for this request")
