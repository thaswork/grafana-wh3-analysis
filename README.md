# Player Review and Activity Analysis for Warhammer 3 with Grafana

This project grew out of the [previous Power BI analysis](https://github.com/thaswork/powerbi-wh3-analysis) of player sentiment and activity in Total Warhammer 3. It explores an existing dataset through a different toolset using PostgreSQL and SQL. Grafana introduces start and end annotations for discount events, providing another view of player trends and including final discounted prices for comparison.

![Player Activity with Releases](docs/grafana_review_overview.png)

## Project Questions
These questions are similar to those from the previous project, but with better integration of discount event markers in Grafana.

- What patterns appear in player activity and reviews over time?
- How do player sentiment and engagement change around developer build releases?
- How does player sentiment differ across common review topics?
- How much is player engagement affected by different types of build announcements?
- What tendencies are revealed in player activity during discount events?
- How player activity patterns differ across discount events with different final prices?
- How discount events influence player sentiment on topics such as price or monetization?
- What do concurrent discount events and build announcements show about engagement and sentiment?

## Tools

- Grafana
- SQL
- Python
- PostgreSQL
- Docker

## Data

- Steam player reviews from 2024 through 2026: (https://store.steampowered.com/appreviews/1142710)
- Historical player activity data from games-popularity: (https://games-popularity.com)
- Developer announcements, discount events, and release information from SteamDB: (https://steamdb.info/app/1142710/patchnotes/)
- LLM-assisted text filtering for player reviews (Review.csv), build announcements (Build.csv), and discount events (Discount.csv)
- Manual cleanup of Review.csv, Build.csv, and Discount.csv
- PlayerActivity.csv columns may have to be manually renamed to follow UpperPascal

## Workflow

- Collected Steam review and player activity data through an API with a Python script
- Used an LLM-assisted process to identify common topics across more than 50,000 review texts
- Classified and organized topics into their own columns
- Performed some manual cleanup in LibreOffice Calc for names and irrelevant data
- Established a local database with Docker and PostgreSQL
- Connected the local relational database to Grafana
- Used SQL to perform queries for interactive visuals in Grafana

### Player Review

The [Player Review dashboard](https://enyo.outboundstudios.com:30095/d/adln5fk/player-reviews?from=2024-01-29T05:00:00.000Z&to=2026-10-06T03:59:59.000Z&timezone=browser&var-Topic=$__all) retained its core functionality from the previous project, looking beyond the overall Steam rating to examine what players were actually discussing. Integrating start and end dates for discount events improved the visual analysis of player sentiment alongside build announcements.

- Filter reviews by topic and date
- Compare review volume with positive recommendation percentage
- View developer build announcements alongside review activity
- Compare sentiment before and after selected updates
- Provide annotations for discount events and their final price

![Player Sentiment](docs/grafana_review_overview.png)

In the sample time span, filtering reviews by Monetization (payment practices) and Price (affordability) shows that some peaks in these topics fall outside discount events. Small dips are also visible during discount events, suggesting that discounts may have limited influence on cost-related reviews relative to other factors during that time.

The "Related Build Announcements" panel correctly shows no build announcements, since none are associated with either topic.

![Player Sentiment](docs/grafana_review_discount.png)

### Player Activity

The [Player Activity dashboard](https://enyo.outboundstudios.com:30095/d/ad6twdl/player-activity?from=2024-01-29T05:00:00.000Z&to=2026-10-06T03:59:59.000Z&timezone=browser) has most of the features from the last project, in addition to annotations for Discount Events alongside Build Announcements.

- Daily player activity
- Daily highs and lows
- 7-day averages
- 30-day averages
- Interactive annotations for Build Announcements and Discount Events

![Player Engagement](docs/grafana_activity_overview.png)

![Player Engagement](docs/grafana_activity_discount.png)

## Key Findings and Further Investigations

Many of the findings are similar to those from the previous Power BI project and inspire further analysis.

- Player activity follows a clear weekly cycle with stronger activity around weekends
  - Is there an opportunity to improve engagement on weekdays?
- Higher review volume does not always correspond with more positive sentiment
  - Does this reveal an issue in the QA process that results in negative player feedback?
  - How much does negative player feedback affect sales?
- Breaking reviews into specific topics provides more useful context than looking only at the overall review score
  - Are there any other topics or announcements we can break down for analytics?
- Player activity spiked around major discount events and major content releases
  - Is there a way to strategically align discounts to grow the player base?
  - Will that player base purchase subsequent content?

## Limitations

Similar limitations apply as in the previous project.

- Limited time span of data from 2024 to 2026 because reliable historical data before 2024 is unavailable
- The analysis is observational and does not prove that releases caused changes in sentiment or player activity
- While promotional and seasonal discount events are included, other marketing campaigns, weekends, and unrelated events may also have influenced the results
- LLM-assisted topic classification can still introduce inconsistent categorization of the data
- The database retains the topic "Other" for potential other uses, while the Grafana visuals exclude it to avoid skewing the results toward a catch-all topic
- Steam reviewers may not represent the full player population
- Short analysis windows can overlap with other build announcements or events

## Local Setup

The repository includes four prepared CSV datasets, the PostgreSQL creation script, and both Grafana dashboards. These can be used to recreate the project locally. VS Code with PostgreSQL and SQLTools extensions are optional.

- Install Python 3.13+
- Install Docker Desktop for Windows/macOS (includes Docker Engine and Docker Compose), or Docker Engine with the Docker Compose plugin for Linux
- Create `.env` using `.env.example` as a reference, including API keys, database credentials, and `GRAFANA_READER_PASSWORD`
- Start PostgreSQL and Grafana using the applicable command
  - Run `docker compose up -d` in a terminal, PowerShell, or Command Prompt from the project directory
- Execute `wh3_analysis.sql` against PostgreSQL's `postgres` database to create the project database
  - Run `docker exec -i wh3-postgres psql -X -v ON_ERROR_STOP=1 -U wh3_user -d postgres < wh3_analysis.sql` in a terminal or Command Prompt
  - Alternative for PowerShell `cmd /c "docker exec -i wh3-postgres psql -X -v ON_ERROR_STOP=1 -U wh3_user -d postgres < wh3_analysis.sql"`
  - Running the creation script again will delete and recreate the `wh3_analysis` database, removing its existing data but not the CSV files in the `datasets/` directory
- Create a Python virtual environment and install the dependencies listed in `requirements.txt`, or install them without a .venv
  - Example terminal commands for .venv from the project directory `python3 -m venv .venv` and then `source .venv/bin/activate` then install requirements `python -m pip install -r requirements.txt`
  - For Windows PowerShell if needing to use the .venv without activation `.\.venv\Scripts\python.exe -m pip install -r requirements.txt`
- Run `DataIngest.py` from a terminal to load the four prepared CSV datasets into PostgreSQL: `Build.csv`, `Discount.csv`, `PlayerActivity.csv`, and `Review.csv`
  - Alternative for Windows PowerShell if using a .venv `.\.venv\Scripts\python.exe python\DataIngest.py`
- Open Grafana at http://localhost:3000 and complete the initial administrator setup
- Configure a PostgreSQL data source using `postgres:5432` as the host, `wh3_analysis` as the database, and `grafana_reader` with the password configured in `.env`
- Import `PlayerActivity.json` and `PlayerReviews.json` from the `dashboard/` directory into Grafana's dashboards

## Data Collection

The prepared CSV datasets are included in the repository. The following steps are optional for recreating the datasets.

- Run `DataPull.py` to collect player activity and Steam reviews using the configured API settings
  - You will need your own API key for https://games-popularity.com
  - `PlayerActivityRaw.csv` will not include missing dates
  - `ReviewRaw.csv` requires topic classification for newly collected or updated reviews
- Download the price history CSV from SteamDB to recreate `Discount.csv`. A SteamDB login may be required
  - Clean the data manually or with LLM assistance to match the provided CSV
- Collect build information from SteamDB's Patches page by copying the table into a spreadsheet application such as LibreOffice Calc
  - Remove irrelevant entries, including builds without titles, and prepare the topics to match `Build.csv`
- Save the four prepared datasets in `datasets/`, using the provided CSV files as references
- Run `DataIngest.py` again to replace the existing database records with the prepared datasets
