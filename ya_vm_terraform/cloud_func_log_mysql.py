import pymysql
import os

def handler(event, context):
    conn = pymysql.connect(
        host=os.environ['MYSQL_HOST'],
        user=os.environ['MYSQL_USER'],
        password=os.environ['MYSQL_PASS'],
        database=os.environ['MYSQL_DB'],
        port=3306,
        ssl={'ca': '/etc/ssl/certs/ca-certificates.crt'}
    )
    cur = conn.cursor()
    for msg in event['messages']:
        log_entry = msg['details']
        cur.execute("INSERT INTO alb_logs (log) VALUES (%s)", (str(log_entry),))
    conn.commit()
    return {'status': 'ok'}
