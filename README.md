python3.12-venv
source .venv/bin/activate (run in terminal of the project's root)
python3 python/DataIngest.py (run to start the virtual evironment that has the plugins so .py scripts can run)
.venv/bin/python3 python/DataIngest.py (maybe an alternative)


Manual Activation
From running terminal at repository root:
source .venv/bin/activate

Then either script
python3 python/DataPull.py
python3 python/DataIngest.py

# Player Review and Activity Analysis for Warhammer 3 with Grafana

This project was born out of the previous Power BI analysis of player sentiment, and activity in Total Warhammer 3. Instead of Power BI, I wanted to shift things towards Grafana that would also include setting up a local data base, and use SQL for queries in Grafana.

In additiona to using Grafana I made use of discount events to be readily visible with start, and end dates. This added another layer of events to see their impact on players, and the data included a final price of the discount for comparison.

![Player Activity with Releases](docs/player_activity_overview.png)

## Project Questions
Similar questions are asked that were present in the previous project except with better integration of discount events markers in Grafana.

- What patterns appear in player activity and reviews over time?
- How does player sentiment and engagement change around developer build releases?
- How does player sentiment differ across common review topics?
- How much is player engagement affected by different types of build announcements?
- What impact do discount events have on player activity over a period of time?
- Does the final amount of the discount affect player activity?
- Do the discount events affect player sentiment topics, such as for price or monetization?
- What effect does having discounts events, and build announcements occuring in conjunction have on players?

## Tools
- Docker
- PostgreSQL
- Python
- SQL

## Data

- Steam player reviews from 2024 through 2026: (https://store.steampowered.com/appreviews/1142710)
- Historical player activity data from games-popularity: (https://games-popularity.com)
- Developer announcements, discount events and release information from SteamDB: (https://steamdb.info/app/1142710/patchnotes/)
- LLM assisted text filtering for player reviews, build announcements, and discount events
- Manual cleanup of player reviews, build announcements, and discount events

## Workflow

- Collected Steam review and player activity data through api with a Python script
- Used an LLM assisted process to identify common topics across +50,000 review texts
- Kept and organized recurring topics into their own columns
- Performed some manual clean up in LibreOffice Calc
- Established a local database with Docker and PostgreSQL
- Connected the local relational database to Grafana
- Used SQL to perform queries for interactive visuals in Grafana

### Player Review

I built the Player Review dashboard to look beyond the overall Steam rating and examine what players were actually discussing that included the following:

- Filter reviews by topic and date
- Compare review volume with positive recommendation percentage
- View developer build announcements alongside review activity
- Compare sentiment before and after selected updates
- Provide annotations for discount events and their final price

![Player Sentiment](docs/player_reviews_overview.png)

One example is "Hotfix 6.3.2" when filtering for Campaign and AI topics has the following:

- Positive recommendations in the previous 7 days: 5.37%
- Positive recommendations in the following 7 days: 52.97%

This implies the hotfix that addressed the player's feedback, and that it was received very positively over following the week.

![Player Sentiment](docs/player_reviews_campaign_ai.png)

### Player Activity

I also wanted to understand whether major updates and announcements were associated with changes in player engagement, so this dashboard includes the following:

- Daily player activity
- Daily highs and lows
- 7 day averages
- 30 day averages
- Announcement and release filters
- Comparisons between release dates and surrounding activity

![Player Engagement](docs/player_activity_events.png)

![Player Engagement](docs/player_activity_periodic_content.png)

## Key Findings

- Player activity follows a clear weekly cycle with stronger activity around weekends
  - Is there an opportunity here to improve engagement for the weekdays?
- Higher review volume does not always correspond with more positive sentiment
  - Does this reveal an issue in the QA process that results in negative player feedback?
  - How much does negative player feedback affect sales?
- Breaking reviews into specific topics provides more useful context than looking only at the overall review score
  - Are there any other topics or annoucements we can breakdown for analytics?
- Player Activity spiked around major discount events and major content releases
  - Is there way to strategically align your discounts to grow the player base?
  - Will that player base purchase subsequent content?

## Limitations

- Limited time span of data between 2024 to 2026
- The analysis is observational and does not prove that releases caused changes in sentiment or player activity
- Promotional events, seasonal effects, weekends, and unrelated events also influence the results
- LLM assisted topic classification can introduce inconsistent or ambiguous labels
- Steam reviewers may not represent the full player population
- Short analysis windows can overlap with other announcements or events