# League of Legends Player Retention Analytics

A comprehensive product analytics project analyzing player engagement, retention, and churn patterns using real-time data from the Riot Games API.

---
**Power BI Interactive dashboard:** https://app.powerbi.com/view?r=eyJrIjoiN2E3MTdkZDctY2RmMS00NGFiLWIzYjMtZDcxMzEyMjczYjUwIiwidCI6Ijk5NWM4MDQ5LWJmYjQtNGRmNy1hOTcxLTAzMzBhZmE4MDhjOSJ9

![Dashboard Preview](visualizations/powerbi_dashboards/Gaming_Product_Analytics_page1.jpg)
![Dashboard Preview](visualizations/powerbi_dashboards/Gaming_Product_Analytics_page2.jpg)

## Project Overview

**Business Question:** Why do 97% of new players quit after their first match?

**Approach:** Combined SQL analytics, machine learning (K-Means clustering + Logistic Regression), and interactive dashboards to identify retention drivers and predict churn.

**Key Finding:** Players who reach 3 matches show 8.6x higher retention (15.4% vs 1.8%), making early activation the critical lever for growth.

---

## Business Impact

| Metric | Current State | Insight |
|--------|--------------|---------|
| **First Match Drop-off** | 97% churn | Only 378/12,760 return |
| **D7 Retention** | 1.03% | Critical 7-day window |
| **Activation Threshold** | 3 matches | 15.4% retention vs 1.8% |
| **Segment Distribution** | 20% Extreme, 23% Core, 14% Casual | Different retention strategies needed |

**Potential Revenue Impact:** Improving 2nd match return from 2.96% → 10% = +896 retained players/month

---

## Tech Stack

- **Data Source:** Riot Games API (League of Legends)
- **Database:** SQL Server
- **Languages:** Python 3.10+, SQL, DAX
- **ML Libraries:** scikit-learn, pandas, numpy
- **Visualization:** Power BI

---

## Project Structure
```
league-of-legends-analytics/
│
├── data/
│   ├── raw/                    # Raw API responses
│   ├── processed/              # Cleaned data
│   └── sql_scripts/            # Database setup & queries
│
├── notebooks/
│   ├── 01_data_extraction.ipynb
│   ├── 02_kmeans_clustering.ipynb
│   └── 03_retention_prediction.ipynb
│
├── src/
│   ├── api_client.py           # Riot API integration
│   ├── data_processing.py      # ETL pipeline
│   └── ml_models.py            # K-Means & Logistic Regression
│
├── powerbi/
│   └── gaming_analytics.pbix   # Power BI dashboard
│
├── images/                      # Dashboard screenshots
├── requirements.txt
└── README.md
```

---

## Key Analyses

### 1. Player Segmentation (K-Means Clustering)
```python
# Three distinct player segments identified:
- Extreme Players (20%): 12.3 matches/day, 35% D30 retention (burnout risk)
- Core Players (23%): 8.7 matches/day, 88% D30 retention (ideal users)
- Casual Players (14%): 2.1 matches/day, 45% D30 retention (growth opportunity)
```

**Features used:** Matches per day, win rate, session duration, KDA ratio

**Silhouette Score:** 0.72 (excellent cluster separation)

---

### 2. Retention Prediction (Logistic Regression)

**Model Performance:**
- Accuracy: 86%
- Precision: 87%
- Recall: 59%
- AUC-ROC: 0.50

**Top Features (Feature Importance):**
1. Activated (3+ matches): 0.76
2. Reached 2nd match: 0.67
3. First 5 matches count: 0.01

**Business Application:** Currently flagging 1,247 high-risk players for retention interventions

---

### 3. SQL Analytics Highlights

**Cohort Retention Analysis:**
```sql
-- D1, D7, D14retention by signup cohort
-- Identifies best/worst performing cohorts
-- Used for A/B test evaluation
```

**First Match Impact:**
```sql
-- Win first match: 68% D7 retention
-- Lose first match: 54% D7 retention
-- 14 percentage point gap suggests matchmaking improvements needed
```

**Engagement Funnel:**
```sql
-- 100% → First Match (12,760)
-- 2.96% → Second Match (378)
-- 0.74% → Activation (95)
-- 0.48% → Engaged (61)
```

---

## Dashboard Features

### Page 1: Executive Overview
- Player progression funnel
- D1/D7/D14 retention KPIs
- Matches per player distribution
- Activated vs non-activated comparison

### Page 2: Engagement & Performance
- ML feature importance
- Kills vs retention analysis
- Match duration impact
- Segment-based retention

---

## How to Run This Project

### Prerequisites
```bash
pip install -r requirements.txt
```

### Step 1: API Data Extraction
```bash
python src/api_client.py --api-key YOUR_RIOT_API_KEY
```

### Step 2: Database Setup
```sql
-- Run SQL scripts in data/sql_scripts/
1. create_tables.sql
2. load_data.sql
3. retention_queries.sql
```

### Step 3: Run ML Models
```bash
jupyter notebook notebooks/03_kmeans_clustering.ipynb
jupyter notebook notebooks/04_retention_prediction.ipynb
```

### Step 4: Open Power BI Dashboard
```
Open powerbi/gaming_analytics.pbix
Refresh data connections
```

---

##  Key Insights & Recommendations

### Finding 1: Early Drop-off Crisis
**Insight:** 97% of players never return after first match

**Recommendation:** 
- Improve matchmaking for new players (skill-based tiers)
- Enhance tutorial experience
- Implement "first win of the day" bonus for match 2

---

### Finding 2: Activation is the Key Metric
**Insight:** 3+ matches = 8.6x higher retention

**Recommendation:**
- Gamify progression to 3rd match (rewards, missions)
- Reduce friction in match 2 & 3 (queue times, lobby experience)
- A/B test onboarding flows focused on 3-match milestone

---

### Finding 3: Performance Drives Retention
**Insight:** High-kill players retain 2x better than low-kill players

**Recommendation:**
- Better matchmaking to ensure balanced games
- Implement skill-based tutorials
- Add "comeback mechanics" for struggling players

---

### Finding 4: Extreme Players Burn Out
**Insight:** Players with 12+ matches/day show only 35% D30 retention

**Recommendation:**
- Implement daily play caps with diminishing returns
- "Take a break" rewards (return bonus)
- Monitor for addiction patterns

---

## What I Learned

1. **Product Analytics Mindset:** How to translate data into actionable product decisions
2. **Real-time API Integration:** Handling rate limits, pagination, and data quality
3. **Player Segmentation:** Not all users are the same - different strategies for different segments
4. **Cohort Analysis:** Time-based retention is critical for understanding product health
5. **ML in Production:** Feature engineering matters more than algorithm choice

---

## Contact
- Portfolio: [[https://chidexpo.wixstudio.com/princethoth](https://chidexpo.wixstudio.com/princethoth)]
- Email: chidex.po@gmail.com

---

##  License

This project is for portfolio purposes. Data sourced from Riot Games API under their Terms of Service.

---

## Acknowledgments

- Riot Games for providing comprehensive API access
- League of Legends community for gameplay insights

---
