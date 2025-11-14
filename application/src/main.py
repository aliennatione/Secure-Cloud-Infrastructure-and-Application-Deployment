import os
import logging
from fastapi import FastAPI
from vault_client import VaultClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Secure Application")

# Initialize Vault client
vault_client = VaultClient(
    vault_addr=os.getenv('VAULT_ADDR'),
    vault_token=os.getenv('VAULT_TOKEN'),
    mount_point='secret'
)

@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    try:
        # Retrieve secrets from Vault
        secrets = vault_client.get_secrets('app/prod')
        
        # Initialize database connection
        db_password = secrets.get('db_password')
        if not db_password:
            logger.error("❌ Database password not found in Vault")
            raise ValueError("Missing database credentials")
            
        logger.info("✅ Application started successfully with secure secrets")
        
    except Exception as e:
        logger.error(f"❌ Startup failed: {str(e)}")
        raise

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "environment": os.getenv('ENVIRONMENT', 'production'),
        "secure_mount": os.path.exists('/mnt/secure')
    }

@app.get("/secure-data")
async def get_secure_data():
    """Endpoint that uses encrypted data"""
    try:
        # Retrieve secrets on demand
        secrets = vault_client.get_secrets('app/prod')
        
        # Example of using encrypted data
        return {
            "message": "Access to secure data granted",
            "data_sample": "sensitive_data_encrypted",
            "timestamp": secrets.get('last_updated', 'unknown')
        }
    except Exception as e:
        logger.error(f"❌ Failed to retrieve secure data: {str(e)}")
        return {"error": "Failed to access secure data"}, 500

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
