# Player Review and Activity Analysis for Warhammer 3 with Grafana

This project was born out of the previous Power BI analysis of player sentiment, and activity in Total Warhammer 3. The project explores an existing dataset through a different toolset using PostgreSQL, and SQL. It introduces start, and end annotations for discount events using Grafana. These events provided another view on player trends, and also included a final price of the discount for comparison.

![Player Activity with Releases](docs/grafana_review_overview.png)

## Project Questions
Similar questions are asked that were present in the previous project except with better integration of discount events markers in Grafana.

- What patterns appear in player activity and reviews over time?
- How does player sentiment and engagement change around developer build releases?
- How does player sentiment differ across common review topics?
- How much is player engagement affected by different types of build announcements?
- What tendencies are revealed with discount events on player activity?
- Do player activity patterns differ across discount events with different final prices?
- Do the discount events influence player sentiment topics, such as for price or monetization?
- What does having discounts events, and build announcements occuring in conjunction show for engagement and sentiment?

## Tools

- Grafana
- SQL
- Python
- PostgreSQL
- Docker

## Data

- Steam player reviews from 2024 through 2026: (https://store.steampowered.com/appreviews/1142710)
- Historical player activity data from games-popularity: (https://games-popularity.com)
- Developer announcements, discount events and release information from SteamDB: (https://steamdb.info/app/1142710/patchnotes/)
- LLM assisted text filtering for player reviews (Review.csv), build announcements (Build.csv), and discount events (Discount.csv)
- Manual cleanup of Review.csv, Build.csv, and Discount.csv
- Activity.csv columns may have to be manually renamed to follow UpperPascal

## Workflow

- Collected Steam review and player activity data through api with a Python script
- Used an LLM assisted process to identify common topics across +50,000 review texts
- Classified, and organized topics into their own columns
- Performed some manual clean up in LibreOffice Calc for names and irrelevant data
- Established a local database with Docker and PostgreSQL
- Connected the local relational database to Grafana
- Used SQL to perform queries for interactive visuals in Grafana

### Player Review

The Player Review dashboard retained its core functionalty present in the previous project that looked beyond the overall Steam rating and examined what players were actually discussing. Integration of start/end dates for discount events improved visual analysis for player sentiment alongside build annoucnements.

- Filter reviews by topic and date
- Compare review volume with positive recommendation percentage
- View developer build announcements alongside review activity
- Compare sentiment before and after selected updates
- Provide annotations for discount events and their final price

![Player Sentiment](docs/grafana_review_overview.png)

In the sample time span filtering reviews by Monetization (payment practices) and Price (affordability) visibly shows that some peaks in these topics fall outside discount events. Visually there are small dips during discount events that suggests discounts may have limited influence on cost-related reviews relative to other factors during that time.

The "Related Build Announcements" panel correctly shows no build announcements since none are associated with either topic.

![Player Sentiment](docs/grafana_review_discount.png)

### Player Activity

The project has most of the features from before, in addition to annotations for Discount Events alongside Build Announcements.

- Daily player activity
- Daily highs and lows
- 7 day averages
- 30 day averages
- Interactive annotations for Build Announcements and Discount Events

![Player Engagement](docs/grafana_activity_overview.png)

![Player Engagement](docs/grafana_activity_discount.png)

## Key Findings and Further Investigations

Many of the findings were similar to the previous Power BI project, and inspire future anaylsis.

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

Similar limitations apply as from the previous project.

- Limited time span of data between 2024 to 2026 due to reliable historical data missing before 2024
- The analysis is observational and does not prove that releases caused changes in sentiment or player activity
- While promotional/seasonal discount events are included, there may still be other marketing campaigns, weekends, and unrelated events also influenced the results
- LLM assisted topic classification, but it can still introduce inconsistent categorization of the data
- The database retains the topic of "Other" if there are other use cases, while the provided Grafana visuals exclude it for this project to prevent data skewing too much into a catch all topic
- Steam reviewers may not represent the full player population
- Short analysis windows can overlap with other build announcements or events

## Local Setup

The repository includes 4 prepared .csv datasets, the PostgreSQL creation script, and both Grafana dashboards. The following can be used to recreate the project locally. VS Code with PostgreSQL and SQLTools extensions can optionally be used.

- Install Docker Engine or Docker Desktop, and Python
- Create .env using .env.example as a reference, such as for API keys, database credentials, and GRAFANA_READER_PASSWORD
- Start PostgreSQL and Grafana using applicable commands 
  - "docker compose up -d" in a terminal/PowerShell/CommandPrompt for the project directory
- Execute wh3_analysis.sql against PostgreSQL's postgres database to create the project database
  - "docker exec -i wh3-postgres psql -X -v ON_ERROR_STOP=1 -U wh3_user -d postgres < wh3_analysis.sql" in a terminal/CommandPrompt
  - Running the creation script again will delete the database, delete the data only in the database (not in the dataset directory), and recreate wh3_analysis database
- Create a Python virtual environment and install the dependencies listed in requirements.txt or optionally install the dependencies without the virtual environment
- Run DataIngest.py from a terminal to integrate the four prepared CSV datasets into PostgreSQL: Build.csv, Discount.csv, Activity.csv, and Review.csv
- Open Grafana at http://localhost:3000 and complete the initial administrator setup
- Configure a PostgreSQL data source using postgres:5432 as the host, wh3_analysis as the database, and grafana_reader with the password configured in .env
- Import PlayerActivity.json and PlayerReviews.json from the dashboard/ directory

## Data Collection

The prepared CSV datasets are included in the repository. The following steps are optional for recreating datasets.

- Run DataPull.py to collect player activity, and Steam reviews using the configured API settings
  - You will need your own API key for (https://games-popularity.com)
  - PlayerActivityRaw.csv will not include missing dates
  - ReviewRaw.csv requires topic classification for newly collected, or updated reviews
- Download the price history CSV from SteamDB to recreate Discount.csv and a SteamDB login may be required
  - Manually or with LLM assistance to clean data to match the provided CSV
- Collect build information from SteamDB's Patches page by copying the table into a spreadsheet application such as LibreOffice Calc
  - Remove irrelevant entries, including builds without titles, and prepare the topics to match Build.csv
- Save the four prepared datasets in datasets/, using the provided CSV files as references
- Run DataIngest.py again to replace the existing database records with the prepared datasets