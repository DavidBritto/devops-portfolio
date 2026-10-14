import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Procesando evento de votacion entrante...")
    
    # Simular lectura de evento
    records_count = len(event.get('Records', []))
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Auditoria de voto procesada con exito',
            'records_processed': records_count
        })
    }
