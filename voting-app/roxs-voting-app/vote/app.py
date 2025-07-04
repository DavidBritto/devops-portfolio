import json
import logging
import os
import random
import socket
import time
import threading
import psycopg2
from flask import Flask, g, jsonify, make_response, render_template, request
from prometheus_client import Counter, Gauge, generate_latest, Histogram, CONTENT_TYPE_LATEST
from prometheus_flask_exporter import PrometheusMetrics
from redis import Redis

# Env vars
REDIS = os.getenv('REDIS_HOST', "localhost")

# App setup
option_a = os.getenv('OPTION_A', "Cats")
option_b = os.getenv('OPTION_B', "Dogs")
hostname = socket.gethostname()

app = Flask(__name__)

# Initialize Prometheus metrics with flask exporter
metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Vote service info', version='1.0.0')

# Custom Prometheus metrics
votes_counter = Counter(
    'votes_total',
    'Total number of votes casted',
    ['vote_type']
)

active_sessions = Gauge(
    'active_voting_sessions',
    'Number of active voting sessions'
)

redis_connection_status = Gauge(
    'redis_connection_status',
    'Redis connection status (1=connected, 0=disconnected)'
)

database_connection_status = Gauge(
    'database_connection_status',
    'Database connection status (1=connected, 0=disconnected)'
)

vote_processing_duration = Histogram(
    'vote_processing_duration_seconds',
    'Time spent processing a vote',
    buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0]
)

database_votes_by_option = Gauge(
    'database_votes_by_option',
    'Current votes in database by option',
    ['option']
)

total_votes_in_db = Gauge(
    'total_votes_in_database',
    'Total number of votes in database'
)

# Logging setup
gunicorn_error_logger = logging.getLogger('gunicorn.error')
app.logger.handlers.extend(gunicorn_error_logger.handlers)
app.logger.setLevel(logging.INFO)

# Track sessions
session_count = 0

# Redis connection
def get_redis():
    if not hasattr(g, 'redis'):
        try:
            g.redis = Redis(host=REDIS, db=0, socket_timeout=5)
            # Test connection
            g.redis.ping()
            redis_connection_status.set(1)
        except Exception as e:
            app.logger.error(f"Redis connection failed: {e}")
            redis_connection_status.set(0)
            raise
    return g.redis

def get_pg_conn():
    try:
        conn = psycopg2.connect(
            host=os.getenv('DATABASE_HOST', 'database'),
            user=os.getenv('DATABASE_USER', 'postgres'),
            password=os.getenv('DATABASE_PASSWORD', 'postgres'),
            dbname=os.getenv('DATABASE_NAME', 'votes')
        )
        database_connection_status.set(1)
        return conn
    except Exception as e:
        app.logger.error(f'Database connection failed: {e}')
        database_connection_status.set(0)
        return None

def update_database_metrics():
    """Update Prometheus metrics with current database state"""
    try:
        conn = get_pg_conn()
        if conn:
            cur = conn.cursor()
            # Usar la consulta correcta para contar votos
            cur.execute("SELECT vote, COUNT(*) FROM votes GROUP BY vote;")
            rows = cur.fetchall()
            
            cats_votes = 0
            dogs_votes = 0
            total_votes = 0
            
            for vote, count in rows:
                total_votes += count
                if vote == 'a':
                    cats_votes = count
                elif vote == 'b':
                    dogs_votes = count
            
            # Update Prometheus gauges - usar labels consistentes con votes_total
            database_votes_by_option.labels(option='a').set(cats_votes)
            database_votes_by_option.labels(option='b').set(dogs_votes)
            total_votes_in_db.set(total_votes)
            
            cur.close()
            conn.close()
            
            # Log para debug
            app.logger.info(f'Metrics updated: Cats={cats_votes}, Dogs={dogs_votes}, Total={total_votes}')
            
    except Exception as e:
        app.logger.error(f'Error updating database metrics: {e}')
        database_connection_status.set(0)

def metrics_updater():
    """Background thread to update metrics every 10 seconds"""
    while True:
        try:
            with app.app_context():
                update_database_metrics()
            time.sleep(10)  # Update every 10 seconds
        except Exception as e:
            app.logger.error(f'Error in metrics updater: {e}')
            time.sleep(10)

# Start background metrics updater
metrics_thread = threading.Thread(target=metrics_updater, daemon=True)
metrics_thread.start()

# Main route
@app.route("/", methods=['POST', 'GET'])
def hello():
    global session_count
    
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]
        session_count += 1
        active_sessions.set(session_count)

    vote = None

    if request.method == 'POST':
        # Use context manager for timing
        with vote_processing_duration.time():
            try:
                redis = get_redis()
                vote = request.form['vote']
                app.logger.info('Received vote for %s', vote)
                
                # Determine vote type for metrics - mantener consistencia
                vote_type = 'a' if vote == 'a' else 'b' if vote == 'b' else 'unknown'
                
                data = json.dumps({'voter_id': voter_id, 'vote': vote})
                redis.rpush('votes', data)
                
                # Increment vote counter
                votes_counter.labels(vote_type=vote_type).inc()
                
                app.logger.info(f'Vote processed: {vote_type}')
                
                # Force metrics update after vote
                update_database_metrics()
                
            except Exception as e:
                app.logger.error(f'Error processing vote: {e}')
                redis_connection_status.set(0)

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        hostname=hostname,
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp

# Metrics route
@app.route("/metrics")
def metrics_endpoint():
    try:
        # Update database metrics before serving
        update_database_metrics()
        return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}
    except Exception as e:
        app.logger.error(f'Error generating metrics: {e}')
        return "Error generating metrics", 500

@app.route("/stats")
def stats():
    """API endpoint to get current vote statistics"""
    try:
        conn = get_pg_conn()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT vote, COUNT(*) FROM votes GROUP BY vote;")
            rows = cur.fetchall()
            total_votes = 0
            cats_votes = 0
            dogs_votes = 0
            for vote, count in rows:
                total_votes += count
                if vote == 'a':
                    cats_votes = count
                elif vote == 'b':
                    dogs_votes = count
            cur.close()
            conn.close()
        else:
            total_votes = cats_votes = dogs_votes = 0
    except Exception as e:
        app.logger.error(f'Stats error: {e}')
        total_votes = cats_votes = dogs_votes = 0

    current_options = {'option_a': option_a, 'option_b': option_b}
    return jsonify({
        'total_votes': total_votes,
        'cats_votes': cats_votes,
        'dogs_votes': dogs_votes,
        'current_options': current_options
    })

@app.route("/healthz")
def healthz():
    """Health check endpoint"""
    try:
        # Test Redis connection
        redis = get_redis()
        redis.ping()
        redis_status = "OK"
        redis_connection_status.set(1)
    except:
        redis_status = "FAILED"
        redis_connection_status.set(0)
    
    try:
        # Test Database connection
        conn = get_pg_conn()
        if conn:
            conn.close()
            db_status = "OK"
        else:
            db_status = "FAILED"
    except:
        db_status = "FAILED"
    
    return jsonify({
        "status": "OK",
        "service": "vote-service",
        "hostname": hostname,
        "redis": redis_status,
        "database": db_status
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)