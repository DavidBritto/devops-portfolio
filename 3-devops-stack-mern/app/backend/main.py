from fastapi import FastAPI, HTTPException, status, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel
from typing import List
from sqlalchemy import Column, Integer, String, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.exc import OperationalError
import time
import os
import logging
from datetime import datetime
from prometheus_client import Counter, Histogram, Gauge, Info, generate_latest, CONTENT_TYPE_LATEST

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 📊 MÉTRICAS DE PROMETHEUS - Definir métricas
http_requests_total = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint', 'status_code']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

database_items_total = Gauge(
    'database_items_total',
    'Total number of items in database'
)

database_status = Gauge(
    'database_status',
    'Database connection status (1=up, 0=down)'
)

app_uptime_seconds = Gauge(
    'app_uptime_seconds',
    'Application uptime in seconds'
)

app_info = Info(
    'app_info',
    'Application information'
)

app_info.info({
    'version': '1.0.0',
    'environment': 'development',
    'author': 'roxsross'
})

app_start_time = time.time()


DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://postgres:postgres@db:5432/app")

Base = declarative_base()

class Item(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)

# Inicializar SQLAlchemy con retry logic
MAX_RETRIES = 10
RETRY_DELAY = 3

def create_database_connection():
    for attempt in range(MAX_RETRIES):
        try:
            engine = create_engine(
                DATABASE_URL,
                pool_pre_ping=True,
                pool_recycle=3600,
                echo=False
            )
            SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
            Base.metadata.create_all(bind=engine)
            logger.info("✅ Connected to DB and created tables.")
            return engine, SessionLocal
        except OperationalError as e:
            logger.warning(f"❌ Attempt {attempt+1}: Database not ready. Retrying in {RETRY_DELAY}s... Error: {e}")
            time.sleep(RETRY_DELAY)
    else:
        logger.error("⛔ Could not connect to DB after multiple retries.")
        raise Exception("⛔ Could not connect to DB after multiple retries.")

engine, SessionLocal = create_database_connection()

# Pydantic schemas
class ItemSchema(BaseModel):
    name: str
    description: str

    class Config:
        json_schema_extra = {
            "example": {
                "name": "Ejemplo Item",
                "description": "Esta es una descripción de ejemplo"
            }
        }

class ItemOut(ItemSchema):
    id: int

    class Config:
        from_attributes = True

class HealthCheck(BaseModel):
    status: str
    timestamp: str
    version: str
    database: str

# Dependency para obtener DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# FastAPI app
app = FastAPI(
    title="Items API",
    description="API robusta para gestionar items con métricas de Prometheus",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# 🔄 MIDDLEWARE PARA MÉTRICAS AUTOMÁTICAS
@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    start_time = time.time()
    
    # Procesar request
    response = await call_next(request)
    
    # Calcular duración
    duration = time.time() - start_time
    
    # Extraer información del request
    method = request.method
    endpoint = request.url.path
    status_code = str(response.status_code)
    
    # Actualizar métricas automáticamente
    http_requests_total.labels(
        method=method,
        endpoint=endpoint, 
        status_code=status_code
    ).inc()
    
    http_request_duration_seconds.labels(
        method=method,
        endpoint=endpoint
    ).observe(duration)
    
    return response

# 📊 BACKGROUND TASK para actualizar métricas periódicamente
async def update_background_metrics():
    """Actualizar métricas que requieren consultas a BD"""
    try:
        db = next(get_db())
        
        # Actualizar contador de items
        total_items = db.query(Item).count()
        database_items_total.set(total_items)
        
        # Test de conexión a BD
        db.execute(text("SELECT 1"))
        database_status.set(1)
        
        db.close()
    except Exception as e:
        logger.error(f"Error updating background metrics: {e}")
        database_status.set(0)
    
    # Actualizar uptime
    uptime = time.time() - app_start_time
    app_uptime_seconds.set(uptime)

# Middleware de seguridad
app.add_middleware(
    TrustedHostMiddleware, 
    allowed_hosts=["*"]
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 📊 ENDPOINT DE MÉTRICAS DE PROMETHEUS (Oficial)
@app.get("/metrics")
async def get_metrics():
    """Endpoint de métricas en formato Prometheus oficial"""
    # Actualizar métricas antes de generar output
    await update_background_metrics()
    
    # Generar métricas en formato oficial
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

# Health check endpoint
@app.get("/health", response_model=HealthCheck)
async def health_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        db_status = "disconnected"
        
    return HealthCheck(
        status="healthy" if db_status == "connected" else "unhealthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0",
        database=db_status
    )

# Readiness probe
@app.get("/ready")
async def readiness_check(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")

# Liveness probe
@app.get("/live")
async def liveness_check():
    return {"status": "alive"}

# API Routes
@app.get("/", tags=["Root"])
def read_root():
    return {
        "message": "Items API - Backend con métricas de Prometheus!",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "metrics": "/metrics"
    }

@app.post("/items", response_model=ItemOut, status_code=status.HTTP_201_CREATED, tags=["Items"])
def create_item(item: ItemSchema, db: Session = Depends(get_db)):
    try:
        db_item = Item(name=item.name, description=item.description)
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        logger.info(f"Created item: {db_item.id}")
        return db_item
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating item: {e}")
        raise HTTPException(status_code=500, detail="Error creating item")

@app.get("/items", response_model=List[ItemOut], tags=["Items"])
def read_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    try:
        items = db.query(Item).offset(skip).limit(limit).all()
        return items
    except Exception as e:
        logger.error(f"Error fetching items: {e}")
        raise HTTPException(status_code=500, detail="Error fetching items")

@app.get("/items/{item_id}", response_model=ItemOut, tags=["Items"])
def read_item(item_id: int, db: Session = Depends(get_db)):
    try:
        item = db.query(Item).filter(Item.id == item_id).first()
        if item is None:
            raise HTTPException(status_code=404, detail="Item not found")
        return item
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching item {item_id}: {e}")
        raise HTTPException(status_code=500, detail="Error fetching item")

@app.put("/items/{item_id}", response_model=ItemOut, tags=["Items"])
def update_item(item_id: int, item: ItemSchema, db: Session = Depends(get_db)):
    try:
        db_item = db.query(Item).filter(Item.id == item_id).first()
        if db_item is None:
            raise HTTPException(status_code=404, detail="Item not found")
        
        db_item.name = item.name
        db_item.description = item.description
        db.commit()
        db.refresh(db_item)
        logger.info(f"Updated item: {item_id}")
        return db_item
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating item {item_id}: {e}")
        raise HTTPException(status_code=500, detail="Error updating item")

@app.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["Items"])
def delete_item(item_id: int, db: Session = Depends(get_db)):
    try:
        item = db.query(Item).filter(Item.id == item_id).first()
        if item is None:
            raise HTTPException(status_code=404, detail="Item not found")
        
        db.delete(item)
        db.commit()
        logger.info(f"Deleted item: {item_id}")
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting item {item_id}: {e}")
        raise HTTPException(status_code=500, detail="Error deleting item")

# Error handlers
@app.exception_handler(500)
async def internal_server_error_handler(request, exc):
    logger.error(f"Internal server error: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)