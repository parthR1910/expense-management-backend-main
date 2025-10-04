from datetime import datetime
import pytz
 
india_tz = pytz.timezone("Asia/Kolkata")
 
def get_local_time():
    return datetime.now(india_tz)