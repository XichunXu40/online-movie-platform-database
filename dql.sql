-- A. Verification queries for screenshot evidence: table data
SELECT * FROM users;
SELECT * FROM user_profiles;
SELECT * FROM movies;
SELECT * FROM genres;
SELECT * FROM movie_genres;
SELECT * FROM reviews;
SELECT * FROM review_comments;
SELECT * FROM watchlist_items;
SELECT * FROM viewing_history;
SELECT * FROM user_genre_preferences;

-- B. Verification query: every table should contain at least 15 rows
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'user_profiles', COUNT(*) FROM user_profiles
UNION ALL SELECT 'movies', COUNT(*) FROM movies
UNION ALL SELECT 'genres', COUNT(*) FROM genres
UNION ALL SELECT 'movie_genres', COUNT(*) FROM movie_genres
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'review_comments', COUNT(*) FROM review_comments
UNION ALL SELECT 'watchlist_items', COUNT(*) FROM watchlist_items
UNION ALL SELECT 'viewing_history', COUNT(*) FROM viewing_history
UNION ALL SELECT 'user_genre_preferences', COUNT(*) FROM user_genre_preferences
ORDER BY table_name;

-- C. Structure screenshot helper: replace 'users' with each table name when taking screenshots
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- D. Search/filter query: movies in a selected genre with rating evidence
SELECT
    m.title,
    m.release_year,
    g.genre_name,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM movies m
JOIN movie_genres mg ON m.movie_id = mg.movie_id
JOIN genres g ON mg.genre_id = g.genre_id
LEFT JOIN reviews r ON m.movie_id = r.movie_id
WHERE g.genre_name IN ('Drama', 'Science Fiction', 'Animation')
GROUP BY m.movie_id, m.title, m.release_year, g.genre_name
HAVING COUNT(r.review_id) >= 1
ORDER BY average_rating DESC, m.title;

-- E. Business insight query: average rating and review count per movie
SELECT
    m.movie_id,
    m.title,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM movies m
LEFT JOIN reviews r ON m.movie_id = r.movie_id
GROUP BY m.movie_id, m.title
ORDER BY average_rating DESC NULLS LAST, review_count DESC;

-- F. Business insight query: movies with genre list
SELECT
    m.title,
    STRING_AGG(g.genre_name, ', ' ORDER BY g.genre_name) AS genres
FROM movies m
JOIN movie_genres mg ON m.movie_id = mg.movie_id
JOIN genres g ON mg.genre_id = g.genre_id
GROUP BY m.movie_id, m.title
ORDER BY m.title;

-- G. Business insight query: active users and their completed viewing counts
SELECT
    u.username,
    up.country,
    COUNT(vh.viewing_id) FILTER (WHERE vh.completed = TRUE) AS completed_views
FROM users u
JOIN user_profiles up ON u.user_id = up.user_id
LEFT JOIN viewing_history vh ON u.user_id = vh.user_id
WHERE u.account_status = 'active'
GROUP BY u.user_id, u.username, up.country
ORDER BY completed_views DESC, u.username;

-- H. Business insight query: most watched genres
SELECT
    g.genre_name,
    COUNT(vh.viewing_id) AS completed_viewing_events
FROM genres g
JOIN movie_genres mg ON g.genre_id = mg.genre_id
JOIN viewing_history vh ON mg.movie_id = vh.movie_id
WHERE vh.completed = TRUE
GROUP BY g.genre_id, g.genre_name
ORDER BY completed_viewing_events DESC, g.genre_name;

-- I. Business insight query: review discussion with comments
SELECT
    r.review_id,
    m.title,
    u.username AS reviewer,
    r.rating,
    COUNT(rc.comment_id) AS comment_count
FROM reviews r
JOIN movies m ON r.movie_id = m.movie_id
JOIN users u ON r.user_id = u.user_id
LEFT JOIN review_comments rc ON r.review_id = rc.review_id
GROUP BY r.review_id, m.title, u.username, r.rating
ORDER BY comment_count DESC, r.rating DESC;

-- J. Operational query: high-priority unwatched watchlist items
SELECT
    u.username,
    m.title,
    w.priority_level,
    w.added_date
FROM watchlist_items w
JOIN users u ON w.user_id = u.user_id
JOIN movies m ON w.movie_id = m.movie_id
WHERE w.watched = FALSE AND w.priority_level >= 4
ORDER BY w.priority_level DESC, w.added_date;

-- K. Recommendation-style query for user_id = 1
-- Recommend movies in preferred genres that the user has not completed yet.
SELECT DISTINCT
    m.movie_id,
    m.title,
    g.genre_name,
    ugp.preference_score
FROM user_genre_preferences ugp
JOIN movie_genres mg ON ugp.genre_id = mg.genre_id
JOIN movies m ON mg.movie_id = m.movie_id
JOIN genres g ON ugp.genre_id = g.genre_id
WHERE ugp.user_id = 1
  AND NOT EXISTS (
      SELECT 1
      FROM viewing_history vh
      WHERE vh.user_id = ugp.user_id
        AND vh.movie_id = m.movie_id
        AND vh.completed = TRUE
  )
ORDER BY ugp.preference_score DESC, m.title;

-- L. Privacy-aware operational query: show public profile data without exposing password_hash
SELECT
    u.user_id,
    u.username,
    up.display_name,
    up.country,
    u.account_status
FROM users u
JOIN user_profiles up ON u.user_id = up.user_id
ORDER BY u.user_id;
