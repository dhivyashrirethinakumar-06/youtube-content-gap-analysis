-- ============================================================
-- Content Investment Gap Analysis — India vs. US YouTube Markets
-- Analytical SQL queries (PostgreSQL)
-- Author: Dhivya Shri R
-- ============================================================


-- ============================================================
-- SECTION 1: TABLE SETUP
-- ============================================================

-- India trending data table
-- Populated via scripts/clean_and_load.py (handles NUL bytes + encoding errors)
CREATE TABLE youtube_trending (
    video_id          VARCHAR(20),
    title             TEXT,
    publishedAt       TIMESTAMP,
    channelId         VARCHAR(50),
    channelTitle      TEXT,
    categoryId        INTEGER,
    trending_date     TIMESTAMP,
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

-- US trending data table
-- trending_date stored as TEXT due to format inconsistency; cast inline where needed
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

-- Category lookup: maps numeric IDs to readable names
CREATE TABLE category_mapping (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT
);

INSERT INTO category_mapping (category_id, category_name) VALUES
(1,  'Film & Animation'),
(2,  'Autos & Vehicles'),
(10, 'Music'),
(15, 'Pets & Animals'),
(17, 'Sports'),
(18, 'Short Movies'),
(19, 'Travel & Events'),
(20, 'Gaming'),
(21, 'Videoblogging'),
(22, 'People & Blogs'),
(23, 'Comedy'),
(24, 'Entertainment'),
(25, 'News & Politics'),
(26, 'Howto & Style'),
(27, 'Education'),
(28, 'Science & Technology'),
(29, 'Nonprofits & Activism');


-- ============================================================
-- SECTION 2: SANITY CHECKS
-- Confirm row counts and date ranges after loading
-- ============================================================

SELECT COUNT(*) AS total_rows,
       MIN(trending_date) AS earliest_date,
       MAX(trending_date) AS latest_date
FROM youtube_trending;
-- Expected: ~251,277 rows | Aug 2020 - Apr 2024

SELECT COUNT(*) AS total_rows,
       MIN(trending_date) AS earliest_date,
       MAX(trending_date) AS latest_date
FROM youtube_trending_us;
-- Expected: ~268,787 rows | Aug 2020 - Apr 2024


-- ============================================================
-- SECTION 3: DEMAND VS. SUPPLY BY CATEGORY
-- Engagement Rate = (likes + comments) / views  [Demand proxy]
-- Video Count = trending appearances             [Supply proxy]
-- ============================================================

-- India: per-category demand and supply
SELECT
    cm.category_name,
    COUNT(*)                                                           AS video_count,
    ROUND(
        AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4)                   AS avg_engagement_rate,
    SUM(t.view_count)                                                  AS total_views
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

-- US: same query against US table
SELECT
    cm.category_name,
    COUNT(*)                                                           AS video_count,
    ROUND(
        AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4)                   AS avg_engagement_rate,
    SUM(t.view_count)                                                  AS total_views
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

-- Combined export: both countries in one result (used for Tableau data source)
SELECT 'India' AS country, cm.category_name,
    COUNT(*) AS video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4) AS avg_engagement_rate,
    SUM(t.view_count) AS total_views, SUM(t.likes) AS total_likes
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
UNION ALL
SELECT 'US' AS country, cm.category_name,
    COUNT(*) AS video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4) AS avg_engagement_rate,
    SUM(t.view_count) AS total_views, SUM(t.likes) AS total_likes
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY country, avg_engagement_rate DESC;

-- NOTE: Gap Score (Supply Rank - Demand Rank) was implemented as a
-- calculated field in Tableau, not in SQL, since ranking logic is more
-- naturally expressed in Tableau against its aggregated result set.
-- Tableau formula: IF SUM([Video Count]) >= 1000
--                 THEN [Supply Rank] - [Demand Rank]
--                 ELSE NULL END


-- ============================================================
-- SECTION 4: TIME-TREND VALIDATION
-- Monthly aggregation to confirm findings are structural,
-- not driven by a short-term spike
-- Note: trending_date cast to ::timestamp for US table (TEXT type)
-- ============================================================

SELECT 'India' AS country, cm.category_name,
    DATE_TRUNC('month', t.trending_date) AS month,
    COUNT(*) AS video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4) AS avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
WHERE cm.category_name = 'Gaming'
GROUP BY cm.category_name, DATE_TRUNC('month', t.trending_date)
UNION ALL
SELECT 'US' AS country, cm.category_name,
    DATE_TRUNC('month', t.trending_date::timestamp) AS month,
    COUNT(*) AS video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4) AS avg_engagement_rate
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
WHERE cm.category_name = 'Gaming'
GROUP BY cm.category_name, DATE_TRUNC('month', t.trending_date::timestamp)
ORDER BY country, month;


-- ============================================================
-- SECTION 5: CHANNEL CONCENTRATION CHECK (Gaming, India)
-- Assesses whether "invest more" category is already dominated
-- by a small number of incumbent creators
-- ============================================================

-- Top 30 Gaming channels in India by trending frequency
SELECT
    t.channelTitle,
    COUNT(*)  AS trending_appearances,
    SUM(t.view_count) AS total_views,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric)
        / NULLIF(AVG(t.view_count::numeric), 0), 4) AS avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
WHERE cm.category_name = 'Gaming'
GROUP BY t.channelTitle
ORDER BY trending_appearances DESC
LIMIT 30;

-- Total distinct Gaming channels in India (market breadth check)
SELECT COUNT(DISTINCT channelTitle) AS distinct_gaming_channels
FROM youtube_trending
WHERE categoryid = 20;
