SELECT * 
FROM matches;
SELECT * 
FROM players;
SELECT * 
FROM match_participants;
SELECT *
FROM events;

SELECT COUNT(*) AS Total_Matches
FROM matches;
SELECT COUNT(*)  AS Total_Players
FROM players;
SELECT COUNT(*)  AS Total_Participants
FROM match_participants;

-- Truncate Table
TRUNCATE TABLE events;

-- Insert into the events table
-- Match Played
INSERT INTO events (event_name, event_timestamp, player_id, match_id, event_type)
SELECT 
    'match_played',
    m.match_date,
    mp.player_id,
    mp.match_id,
    'engagement'
FROM match_participants mp
JOIN matches m
    ON mp.match_id = m.match_id;

-- Match Won
INSERT INTO events (event_name, event_timestamp, player_id, match_id, event_type)
SELECT 
    'match_won',
    m.match_date,
    mp.player_id,
    mp.match_id,
    'outcome'
FROM match_participants mp
JOIN matches m
    ON mp.match_id = m.match_id
WHERE mp.win_flag = 1;

-- Match Lost
INSERT INTO events (event_name, event_timestamp, player_id, match_id, event_type)
SELECT 
    'match_lost',
    m.match_date,
    mp.player_id,
    mp.match_id,
    'outcome'
FROM match_participants mp
JOIN matches m
    ON mp.match_id = m.match_id
WHERE mp.win_flag = 0;

-- High Kill Game
INSERT INTO events (event_name, event_timestamp, player_id, match_id, event_type)
SELECT 
    'high_kill_game',
    m.match_date,
    mp.player_id,
    mp.match_id,
    'performance'
FROM match_participants mp
JOIN matches m
    ON mp.match_id = m.match_id
WHERE mp.kills >= 10;

SELECT event_name, event_type, COUNT(*) AS Total
FROM events
GROUP BY event_name, event_type
ORDER BY Total DESC;

-- ENGAGEMENT METRIC (Are users actually using the product)

-- 1. Daily Active User Over Time
SELECT
    CAST(event_timestamp AS DATE) AS Activity_Date,
    COUNT(DISTINCT player_id) AS DAU
FROM events
WHERE event_name = 'match_played'
GROUP BY CAST(event_timestamp AS DATE)
ORDER BY Activity_Date;

-- 2. Weekly Active User
SELECT
    DATEADD(WEEK, DATEDIFF(WEEK, 0, event_timestamp), 0) AS Week_Start,
    COUNT(DISTINCT player_id) AS WAU
FROM events
WHERE event_name = 'match_played'
GROUP BY DATEADD(WEEK, DATEDIFF(WEEK, 0, event_timestamp), 0)
ORDER BY Week_Start;

-- 3. Mothly Active User
SELECT
   DATEFROMPARTS(
            YEAR(event_timestamp),
            MONTH(event_timestamp),
            1
        ) AS Month_Start,
    COUNT(DISTINCT player_id) AS MAU
FROM events
WHERE event_name = 'match_played'
GROUP BY DATEFROMPARTS(
            YEAR(event_timestamp),
            MONTH(event_timestamp), 1)
ORDER BY Month_Start;

-- 4. Stickiness Ratio Over Time
WITH Daily AS (
                    SELECT
    CAST(event_timestamp AS DATE) AS Activity_Date,
    COUNT(DISTINCT player_id) AS DAU
FROM events
WHERE event_name = 'match_played'
GROUP BY CAST(event_timestamp AS DATE)
),
Monthly AS (
                SELECT
    DATEADD(MONTH, DATEDIFF(MONTH, 0, event_timestamp), 0) AS Month_Start,
    COUNT(DISTINCT player_id) AS MAU
FROM events
WHERE event_name = 'match_played'
GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, event_timestamp), 0)
)
SELECT 
        d.Activity_Date, d.DAU, m.MAU,
        CAST(d.DAU * 1.0 / m.MAU AS DECIMAL(5,2)) AS Stickiness_Ratio
FROM Daily d
JOIN Monthly m
    ON DATEFROMPARTS(
        YEAR(d.activity_date),
        MONTH(d.activity_date),
        1
    ) = m.Month_Start
ORDER BY d.Activity_Date;

-- 5. How many matches does an average active user play per day?
WITH Daily AS (
    SELECT
        CAST(event_timestamp AS DATE) AS Activity_Date,
        player_id,
        COUNT(DISTINCT match_id) AS Matches_Played
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY
        CAST(event_timestamp AS DATE),
        player_id
)
SELECT
    Activity_Date,
    AVG(matches_played) AS Average_matches_per_active_user
FROM Daily
GROUP BY Activity_Date
ORDER BY Activity_Date;

-- 6. Engagement Difference between New & Experienced Players
WITH Daily AS (
    SELECT
        CAST(e.event_timestamp AS DATE) AS Activity_Date,
        e.player_id,
        COUNT(DISTINCT e.match_id) AS Matches_Played
    FROM events e
    WHERE e.event_name = 'match_played'
    GROUP BY
        CAST(e.event_timestamp AS DATE),
        e.player_id
),
Active_Users_14d AS (
    SELECT DISTINCT
        player_id
    FROM events
    WHERE event_name = 'match_played'
      AND event_timestamp >= DATEADD(day, -14, GETDATE())
),
Player_Segments AS (
    SELECT
        p.player_id,
        CASE
            WHEN p.join_date >= DATEADD(day, -30, GETDATE())
                 THEN 'New & Active'
            ELSE 'Experienced & Active'
        END AS Player_Segment
    FROM players p
    JOIN active_users_14d a
        ON p.player_id = a.player_id
)
SELECT
    ps.Player_Segment,
    AVG(d.matches_played) AS Average_matches_per_active_day
FROM Daily d
JOIN player_segments ps
    ON d.player_id = ps.player_id
GROUP BY ps.player_segment;

-- 7. What times/days show peak player activity?
-- Peak Activity by day of week
SELECT
    DATENAME(weekday, event_timestamp) AS Day_of_Week,
    COUNT(DISTINCT player_id) AS Active_Players
FROM events
WHERE event_name = 'match_played'
GROUP BY DATENAME(weekday, event_timestamp)
ORDER BY Active_Players DESC;

--Peak Activity By Hour of the Day
SELECT
    DATENAME(hour, event_timestamp) AS Hour_of_Day,
    COUNT(DISTINCT player_id) AS Active_Players
FROM events
WHERE event_name = 'match_played'
GROUP BY DATENAME(hour, event_timestamp)
ORDER BY active_players DESC;


-- RETENTION & CHURN METRIC (Do users come back)

-- 8. Day 1 (D1), Day 7 (D7), and Day 30 (D30) retention
WITH first_match AS (
    SELECT
        player_id,
        MIN(CAST(event_timestamp AS DATE)) AS Cohort_Date
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),
activity AS (
    SELECT DISTINCT
        player_id,
        CAST(event_timestamp AS DATE) AS Activity_Date
    FROM events
    WHERE event_name = 'match_played'
)
SELECT
    fm.cohort_date,
    COUNT(DISTINCT fm.player_id) AS Cohort_Size,

    COUNT(DISTINCT CASE
        WHEN a.activity_date = DATEADD(day, 1, fm.cohort_date)
        THEN fm.player_id
    END) * 1.0 / COUNT(DISTINCT fm.player_id) AS D1_Retention,

    COUNT(DISTINCT CASE
        WHEN a.activity_date = DATEADD(day, 7, fm.cohort_date)
        THEN fm.player_id
    END) * 1.0 / COUNT(DISTINCT fm.player_id) AS D7_Retention,

    COUNT(DISTINCT CASE
        WHEN a.activity_date = DATEADD(day, 30, fm.cohort_date)
        THEN fm.player_id
    END) * 1.0 / COUNT(DISTINCT fm.player_id) AS D30_Retention

FROM first_match fm
LEFT JOIN activity a
    ON fm.player_id = a.player_id
GROUP BY fm.cohort_date
ORDER BY fm.cohort_date;

-- 9. Does retention differ between players who won their first match vs lost
WITH first_match AS (
    SELECT
        e.player_id,
        e.match_id,
        CAST(e.event_timestamp AS DATE) AS First_Match_Date,
        ROW_NUMBER() OVER (
            PARTITION BY e.player_id
            ORDER BY e.event_timestamp
        ) AS rn
    FROM events e
    WHERE e.event_name = 'match_played'
),
first_match_outcome AS (
    SELECT
        fm.player_id,
        fm.first_match_date,
        mp.win_flag
    FROM first_match fm
    JOIN match_participants mp
        ON fm.match_id = mp.match_id
       AND fm.player_id = mp.player_id
    WHERE fm.rn = 1
),
future_activity AS (
    SELECT DISTINCT
        player_id,
        CAST(event_timestamp AS DATE) AS activity_date
    FROM events
    WHERE event_name = 'match_played'
)
SELECT
    CASE
        WHEN fmo.win_flag = 1 THEN 'Won First Match'
        ELSE 'Lost First Match'
    END AS First_Match_Result,
    COUNT(DISTINCT fmo.player_id) AS Cohort_Size,
    COUNT(DISTINCT CASE
        WHEN fa.activity_date > fmo.first_match_date
         AND fa.activity_date <= DATEADD(day, 14, fmo.first_match_date)
        THEN fmo.player_id
    END) * 1.0 / COUNT(DISTINCT fmo.player_id) AS Retention_14d
FROM first_match_outcome fmo
LEFT JOIN future_activity fa
    ON fmo.player_id = fa.player_id
GROUP BY fmo.win_flag;

-- 10. What percentage of players churn after their first 3 matches
WITH player_match_counts AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
)
SELECT
    COUNT(CASE WHEN total_matches = 3 THEN 1 END) * 1.0
    / COUNT(CASE WHEN total_matches >= 3 THEN 1 END)
    AS Pct_Churn_After_3_Matches
FROM player_match_counts;

-- 11. How long does the average player stay active before churning
WITH player_activity_span AS (
    SELECT
        player_id,
        MIN(CAST(event_timestamp AS DATE)) AS first_play_date,
        MAX(CAST(event_timestamp AS DATE)) AS last_play_date
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
)
SELECT
    AVG(DATEDIFF(day, first_play_date, last_play_date)) AS avg_active_days_before_churn
FROM player_activity_span;

-- 12. Is there a noticeable drop-off point where most players stop playing
WITH player_match_counts AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS Total_Matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
)
SELECT
    Total_Matches,
    COUNT(*) AS Player_Count
FROM player_match_counts
GROUP BY Total_Matches
ORDER BY Total_Matches;

--13. Do high-engagement players (top 20%) retain better than low-engagement players
WITH player_match_counts AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS Total_Matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),
ranked_players AS (
    SELECT
        player_id,
        total_matches,
        NTILE(5) OVER (ORDER BY total_matches DESC) AS Engagement_Bucket
    FROM player_match_counts
),
retained_players AS (
    SELECT DISTINCT
        player_id
    FROM events
    WHERE event_name = 'match_played'
      AND event_timestamp >= DATEADD(day, -14, GETDATE())
)
SELECT
    CASE
        WHEN rp.engagement_bucket = 1 THEN 'High Engagement (Top 20%)'
        ELSE 'Low Engagement (Bottom 80%)'
    END AS Engagement_Segment,
    COUNT(DISTINCT rp.player_id) AS Cohort_Size,
    COUNT(DISTINCT r.player_id) * 1.0
        / COUNT(DISTINCT rp.player_id) AS Retention_14d
FROM ranked_players rp
LEFT JOIN retained_players r
    ON rp.player_id = r.player_id
GROUP BY
    CASE
        WHEN rp.engagement_bucket = 1 THEN 'High Engagement (Top 20%)'
        ELSE 'Low Engagement (Bottom 80%)'
    END;

    
-- PERFORMANCE & EXPERIENCE (How well are users doing, and does it matter?)

-- 14. Overall win rate across all matches
SELECT
    SUM(CASE WHEN win_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / COUNT(*) AS Overall_Win_Rate
FROM match_participants;

SELECT
    COUNT(*) AS total_participants,
    SUM(CASE WHEN win_flag = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN win_flag = 0 THEN 1 ELSE 0 END) AS losses
FROM match_participants;

-- 15. How does win rate vary by player level
SELECT
    CASE
        WHEN p.level BETWEEN 1 AND 10 THEN 'Level 1–10'
        WHEN p.level BETWEEN 11 AND 30 THEN 'Level 11–30'
        WHEN p.level BETWEEN 31 AND 60 THEN 'Level 31–60'
        WHEN p.level BETWEEN 61 AND 100 THEN 'Level 61–100'
        ELSE 'Level 100+'
    END AS Level_Band,
    COUNT(*) AS Total_Participations,
    SUM(CASE WHEN mp.win_flag = 1 THEN 1 ELSE 0 END) * 1.0
        / COUNT(*) AS Win_Rate
FROM match_participants mp
JOIN players p
    ON mp.player_id = p.player_id
GROUP BY
    CASE
        WHEN p.level BETWEEN 1 AND 10 THEN 'Level 1–10'
        WHEN p.level BETWEEN 11 AND 30 THEN 'Level 11–30'
        WHEN p.level BETWEEN 31 AND 60 THEN 'Level 31–60'
        WHEN p.level BETWEEN 61 AND 100 THEN 'Level 61–100'
        ELSE 'Level 100+'
    END
ORDER BY MIN(p.level);

-- 16. Is there a relationship between performance (kills) and retention
WITH player_kills AS (
    SELECT
        mp.player_id,
        AVG(mp.kills * 1.0) AS avg_kills
    FROM match_participants mp
    GROUP BY mp.player_id
),
ranked_players AS (
    SELECT
        player_id,
        avg_kills,
        NTILE(4) OVER (ORDER BY avg_kills DESC) AS kill_bucket
    FROM player_kills
),
retained_players AS (
    SELECT DISTINCT
        player_id
    FROM events
    WHERE event_name = 'match_played'
      AND event_timestamp >= DATEADD(day, -14, GETDATE())
)
SELECT
    CASE
        WHEN rp.kill_bucket = 1 THEN 'High Kill Players (Top 25%)'
        ELSE 'Other Players (Bottom 75%)'
    END AS Performance_Segment,
    COUNT(DISTINCT rp.player_id) AS Cohort_Size,
    COUNT(DISTINCT r.player_id) * 1.0
        / COUNT(DISTINCT rp.player_id) AS Retention_14d
FROM ranked_players rp
LEFT JOIN retained_players r
    ON rp.player_id = r.player_id
GROUP BY
    CASE
        WHEN rp.kill_bucket = 1 THEN 'High Kill Players (Top 25%)'
        ELSE 'Other Players (Bottom 75%)'
    END;

    -- 17. Are longer matches associated with higher or lower churn?
    WITH player_status AS (
    SELECT
        p.player_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM events e
                WHERE e.player_id = p.player_id
                  AND e.event_name = 'match_played'
                  AND e.event_timestamp >= DATEADD(day, -14, GETDATE())
            )
            THEN 'Retained'
            ELSE 'Churned'
        END AS Retention_Status
    FROM players p
)
, player_avg_duration AS (
    SELECT
        mp.player_id,
        AVG(m.duration * 1.0) AS avg_match_duration
    FROM match_participants mp
    JOIN matches m
        ON mp.match_id = m.match_id
    GROUP BY mp.player_id
)
SELECT
    ps.retention_status,
    COUNT(*) AS player_count,
    AVG(pad.avg_match_duration) AS avg_match_duration_minutes
FROM player_status ps
JOIN player_avg_duration pad
    ON ps.player_id = pad.player_id
GROUP BY ps.retention_status;

-- 18. Which Behavior predicts Retention
WITH player_status AS (
    SELECT
        p.player_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM events e
                WHERE e.player_id = p.player_id
                  AND e.event_name = 'match_played'
                  AND e.event_timestamp >= DATEADD(day, -14, GETDATE())
            )
            THEN 'Retained'
            ELSE 'Churned'
        END AS retention_status
    FROM players p
),
ranked_matches AS (
    SELECT
        e.player_id,
        e.match_id,
        CAST(e.event_timestamp AS DATE) AS match_date,
        mp.win_flag,
        mp.kills,
        m.duration,
        ROW_NUMBER() OVER (
            PARTITION BY e.player_id
            ORDER BY e.event_timestamp
        ) AS rn
    FROM events e
    JOIN match_participants mp
        ON e.match_id = mp.match_id
       AND e.player_id = mp.player_id
    JOIN matches m
        ON e.match_id = m.match_id
    WHERE e.event_name = 'match_played'
),
first_5_matches AS (
    SELECT *
    FROM ranked_matches
    WHERE rn <= 5
),
early_behavior AS (
    SELECT
        player_id,
        COUNT(*) AS first5_matches,
        AVG(win_flag * 1.0) AS first5_win_rate,
        AVG(kills * 1.0) AS first5_avg_kills,
        AVG(duration * 1.0) AS first5_avg_duration
    FROM first_5_matches
    GROUP BY player_id
)
SELECT
    ps.retention_status,
    COUNT(*) AS player_count,
    AVG(eb.first5_matches) AS avg_matches_first5,
    AVG(eb.first5_win_rate) AS avg_win_rate_first5,
    AVG(eb.first5_avg_kills) AS avg_kills_first5,
    AVG(eb.first5_avg_duration) AS avg_duration_first5
FROM early_behavior eb
JOIN player_status ps
    ON eb.player_id = ps.player_id
GROUP BY ps.retention_status;


-- FUNNEL (Are users moving forward in the product)

-- 19. What percentage of players play a second match after their first
WITH player_match_counts AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS Total_Matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
)
SELECT
    COUNT(CASE WHEN total_matches >= 2 THEN 1 END) * 1.0
    / COUNT(CASE WHEN total_matches >= 1 THEN 1 END)
    AS Pct_Play_Second_Match
FROM player_match_counts;
--INSIGHT: Only about 3% of players go on to play a second match after their first. This shows that the largest drop off in the entire funnel happens after theit first match.

-- 20. Does winning early accelerate player progression
WITH ranked_matches AS (
    SELECT
        e.player_id,
        e.match_id,
        CAST(e.event_timestamp AS DATE) AS match_date,
        mp.win_flag,
        ROW_NUMBER() OVER (
            PARTITION BY e.player_id
            ORDER BY e.event_timestamp
        ) AS match_number
    FROM events e
    JOIN match_participants mp
        ON e.match_id = mp.match_id
       AND e.player_id = mp.player_id
    WHERE e.event_name = 'match_played'
),
first_win AS (
    SELECT
        player_id,
        MIN(match_number) AS first_win_match_number
    FROM ranked_matches
    WHERE win_flag = 1
    GROUP BY player_id
)
, matches_before_after AS (
    SELECT
        rm.player_id,
        CASE
            WHEN rm.match_number < fw.first_win_match_number THEN 'Before First Win'
            ELSE 'After First Win'
        END AS period,
        COUNT(*) AS match_count,
        COUNT(DISTINCT rm.match_date) AS active_days
    FROM ranked_matches rm
    JOIN first_win fw
        ON rm.player_id = fw.player_id
    GROUP BY
        rm.player_id,
        CASE
            WHEN rm.match_number < fw.first_win_match_number THEN 'Before First Win'
            ELSE 'After First Win'
        END
)
SELECT
    period,
    AVG(match_count * 1.0 / NULLIF(active_days, 0)) AS avg_matches_per_active_day
FROM matches_before_after
GROUP BY period;


-- SEGMENTATION & BEHAVIOURIAL DIFFERNCE (Are there distinct types of users?)

-- 21. Can players be segmented into casual vs core users based on activity?
WITH player_activity AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),
segmented_players AS (
    SELECT
        player_id,
        total_matches,
        NTILE(4) OVER (ORDER BY total_matches DESC) AS activity_quartile
    FROM player_activity
)
SELECT
    CASE
        WHEN activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END AS player_segment,
    COUNT(*) AS player_count,
    AVG(total_matches) AS avg_total_matches
FROM segmented_players
GROUP BY
    CASE
        WHEN activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END;

-- 22. How do engagement and win rates differ across player segments
WITH player_activity AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),
segmented_players AS (
    SELECT
        player_id,
        total_matches,
        NTILE(4) OVER (ORDER BY total_matches DESC) AS activity_quartile
    FROM player_activity
),
player_win_rate AS (
    SELECT
        player_id,
        AVG(win_flag * 1.0) AS win_rate
    FROM match_participants
    GROUP BY player_id
)
SELECT
    CASE
        WHEN sp.activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END AS player_segment,
    COUNT(*) AS player_count,
    AVG(sp.total_matches * 1.0) AS avg_total_matches,
    AVG(pwr.win_rate) AS avg_win_rate
FROM segmented_players sp
LEFT JOIN player_win_rate pwr
    ON sp.player_id = pwr.player_id
GROUP BY
    CASE
        WHEN sp.activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END;
--INSIGHT: Core players show higher engagement and higher win rate, but not so much difference un performance. In other words, Engagement preceeds performance. 

-- 23. How do core vs casual players differ in retention / churn
WITH player_activity AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),
segmented_players AS (
    SELECT
        player_id,
        total_matches,
        NTILE(4) OVER (ORDER BY total_matches DESC) AS activity_quartile
    FROM player_activity
),
retained_players AS (
    SELECT DISTINCT
        player_id
    FROM events
    WHERE event_name = 'match_played'
      AND event_timestamp >= DATEADD(day, -14, GETDATE())
)
SELECT
    CASE
        WHEN sp.activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END AS player_segment,
    COUNT(DISTINCT sp.player_id) AS player_count,
    COUNT(DISTINCT r.player_id) * 1.0
        / COUNT(DISTINCT sp.player_id) AS retention_14d,
    1 - (
        COUNT(DISTINCT r.player_id) * 1.0
        / COUNT(DISTINCT sp.player_id)
    ) AS churn_14d
FROM segmented_players sp
LEFT JOIN retained_players r
    ON sp.player_id = r.player_id
GROUP BY
    CASE
        WHEN sp.activity_quartile = 1 THEN 'Core Players'
        ELSE 'Casual Players'
    END;
--INSIGHT: Core players retain slightly better than casual players, but the difference is modest because even the core segment exhibits very low engagement.
--This indicates that the product currently lacks a strong habit-forming core, and retention improvements must focus on accelerating early activation. 


-- CONCLUSION: Churn in this product is driven almost entirely by early disengagement, particularly after the first match. Performance, win rate, kills,
--and match length do not meaningfully predict retention. Players who form an early habit by playing multiple matches are far more likely to stay, regardless of success.
--Therefore, the highest-impact retention improvements lie in accelerating early repetition (designing the product to minimize friction and maximize motivation 
-- for players to quickly play their second and third matches, since habit formation—not early success—is the primary driver of retention). 


--MACHINE LEARNING MODELS
--1. Logistic Regression
WITH ranked_matches AS (
    SELECT
        e.player_id,
        e.match_id,
        CAST(e.event_timestamp AS DATE) AS match_date,
        mp.win_flag,
        mp.kills,
        ROW_NUMBER() OVER (
            PARTITION BY e.player_id
            ORDER BY e.event_timestamp
        ) AS match_number
    FROM events e
    JOIN match_participants mp
        ON e.match_id = mp.match_id
       AND e.player_id = mp.player_id
    WHERE e.event_name = 'match_played'
),

first_5_matches AS (
    SELECT *
    FROM ranked_matches
    WHERE match_number <= 5
),

early_features AS (
    SELECT
        player_id,
        COUNT(*) AS matches_first5,
        AVG(win_flag * 1.0) AS win_rate_first5,
        AVG(kills * 1.0) AS avg_kills_first5,
        MAX(CASE WHEN match_number >= 2 THEN 1 ELSE 0 END) AS reached_second_match,
        MAX(CASE WHEN match_number >= 3 THEN 1 ELSE 0 END) AS activated_3_matches
    FROM first_5_matches
    GROUP BY player_id
),

retention_label AS (
    SELECT
        p.player_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM events e
                WHERE e.player_id = p.player_id
                  AND e.event_name = 'match_played'
                  AND e.event_timestamp >= DATEADD(day, -14, GETDATE())
            )
            THEN 1 ELSE 0
        END AS retained_14d
    FROM players p
)

SELECT
    ef.player_id,
    ef.matches_first5,
    ef.win_rate_first5,
    ef.avg_kills_first5,
    ef.reached_second_match,
    ef.activated_3_matches,
    rl.retained_14d
FROM early_features ef
JOIN retention_label rl
    ON ef.player_id = rl.player_id;

--2. Clustering
WITH player_activity AS (
    SELECT
        player_id,
        COUNT(DISTINCT match_id) AS total_matches,
        COUNT(DISTINCT CAST(event_timestamp AS DATE)) AS active_days
    FROM events
    WHERE event_name = 'match_played'
    GROUP BY player_id
),

player_frequency AS (
    SELECT
        player_id,
        CASE
            WHEN active_days = 0 THEN 0
            ELSE total_matches * 1.0 / active_days
        END AS matches_per_active_day
    FROM player_activity
)

SELECT
    pa.player_id,
    pa.total_matches,
    pa.active_days,
    pf.matches_per_active_day
FROM player_activity pa
JOIN player_frequency pf
    ON pa.player_id = pf.player_id;









        