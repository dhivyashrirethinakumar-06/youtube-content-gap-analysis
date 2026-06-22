import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

def clean_value(val):
    """Aggressively clean any value before inserting into PostgreSQL"""
    if val is None:
        return None
    s = str(val)
    # Remove NUL and all non-printable characters
    s = ''.join(c for c in s if c.isprintable())
    # Remove any remaining NUL bytes explicitly
    s = s.replace('\x00', '')
    return s

# --- Read US CSV ---
print("Reading US CSV...")
df = pd.read_csv(
    r"C:\Users\dhivy\Downloads\youtube_media_project\data\US_youtube_trending_data.csv",
    engine='python',
    on_bad_lines='skip',
    encoding='utf-8-sig',
    dtype=str  # Read EVERYTHING as string first - prevents hidden byte issues
)

print(f"Rows loaded: {len(df)}")

# --- Clean every single cell in the entire dataframe ---
print("Cleaning data...")
df = df.map(clean_value)

# --- Fill nulls ---
df = df.fillna('')

# --- Convert numeric columns back to proper types ---
for col in ['view_count', 'likes', 'dislikes', 'comment_count', 'categoryId']:
    df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)

# --- Connect to PostgreSQL ---
print("Connecting to PostgreSQL...")
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="youtube_media",
    user="postgres",
    password="postgres"  # ← your postgres password
)
cur = conn.cursor()

# --- Create US table ---
print("Creating US table...")
cur.execute("DROP TABLE IF EXISTS youtube_trending_us;")
cur.execute("""
    CREATE TABLE youtube_trending_us (
        video_id          VARCHAR(20),
        title             TEXT,
        publishedAt       TEXT,
        channelId         VARCHAR(50),
        channelTitle      TEXT,
        categoryId        INTEGER,
        trending_date     TEXT,
        tags              TEXT,
        view_count        BIGINT,
        likes             BIGINT,
        dislikes          BIGINT,
        comment_count     BIGINT,
        thumbnail_link    TEXT,
        comments_disabled TEXT,
        ratings_disabled  TEXT,
        description       TEXT
    );
""")
conn.commit()

# --- Insert in small batches with per-row cleaning ---
print("Inserting rows...")
cols = ['video_id','title','publishedAt','channelId','channelTitle',
        'categoryId','trending_date','tags','view_count','likes',
        'dislikes','comment_count','thumbnail_link',
        'comments_disabled','ratings_disabled','description']

batch = []
batch_size = 500
total_inserted = 0

for _, row in df[cols].iterrows():
    # Clean every value one final time at row level
    cleaned_row = tuple(
        clean_value(v) if isinstance(v, str) else v 
        for v in row
    )
    batch.append(cleaned_row)
    
    if len(batch) >= batch_size:
        execute_values(
            cur,
            """INSERT INTO youtube_trending_us
               (video_id, title, publishedat, channelid, channeltitle,
                categoryid, trending_date, tags, view_count, likes,
                dislikes, comment_count, thumbnail_link,
                comments_disabled, ratings_disabled, description)
               VALUES %s""",
            batch
        )
        conn.commit()
        total_inserted += len(batch)
        batch = []
        print(f"  Inserted {total_inserted} rows so far...")

# Insert remaining rows
if batch:
    execute_values(
        cur,
        """INSERT INTO youtube_trending_us
           (video_id, title, publishedat, channelid, channeltitle,
            categoryid, trending_date, tags, view_count, likes,
            dislikes, comment_count, thumbnail_link,
            comments_disabled, ratings_disabled, description)
           VALUES %s""",
        batch
    )
    conn.commit()
    total_inserted += len(batch)

cur.close()
conn.close()

print(f"✓ Done! {total_inserted} US rows inserted successfully.")