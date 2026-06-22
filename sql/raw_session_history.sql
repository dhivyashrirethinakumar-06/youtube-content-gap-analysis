
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





SELECT categoryId, COUNT(*) as video_count,
       ROUND(AVG(likes::numeric + comment_count::numeric) / NULLIF(AVG(view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending
GROUP BY categoryId
ORDER BY avg_engagement_rate DESC;

SELECT COUNT(*) as total_rows,
       MIN(trending_date) as earliest_date,
       MAX(trending_date) as latest_date
FROM youtube_trending;

SELECT COUNT(*) as total_rows,
       MIN(trending_date) as earliest_date,
       MAX(trending_date) as latest_date
FROM youtube_trending_us;

SELECT categoryId, COUNT(*) as video_count,
       ROUND(AVG(likes::numeric + comment_count::numeric) / NULLIF(AVG(view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending_us
GROUP BY categoryId
ORDER BY avg_engagement_rate DESC;


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

SELECT 
    cm.category_name,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

SELECT 
    cm.category_name,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

SELECT 
    cm.category_name,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

SELECT 
    'India' as country,
    cm.category_name,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate,
    SUM(t.view_count) as total_views,
    SUM(t.likes) as total_likes
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

SELECT 
    'US' as country,
    cm.category_name,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate,
    SUM(t.view_count) as total_views,
    SUM(t.likes) as total_likes
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name
ORDER BY avg_engagement_rate DESC;

SELECT 
    cm.category_name,
    DATE_TRUNC('month', t.trending_date) as month,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name, DATE_TRUNC('month', t.trending_date)
ORDER BY cm.category_name, month;

SELECT 
    'India' as country,
    cm.category_name,
    DATE_TRUNC('month', t.trending_date) as month,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name, DATE_TRUNC('month', t.trending_date)

UNION ALL

SELECT 
    'US' as country,
    cm.category_name,
    DATE_TRUNC('month', t.trending_date::timestamp) as month,
    COUNT(*) as video_count,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending_us t
JOIN category_mapping cm ON t.categoryid = cm.category_id
GROUP BY cm.category_name, DATE_TRUNC('month', t.trending_date::timestamp)

ORDER BY country, category_name, month;

SELECT 
    t.channelTitle,
    COUNT(*) as trending_appearances,
    SUM(t.view_count) as total_views,
    ROUND(AVG(t.likes::numeric + t.comment_count::numeric) / 
          NULLIF(AVG(t.view_count::numeric), 0), 4) as avg_engagement_rate
FROM youtube_trending t
JOIN category_mapping cm ON t.categoryid = cm.category_id
WHERE cm.category_name = 'Gaming'
GROUP BY t.channelTitle
ORDER BY trending_appearances DESC
LIMIT 30;

SELECT COUNT(DISTINCT channelTitle) FROM youtube_trending WHERE categoryid = 20