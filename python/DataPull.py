import csv
import os
import requests
import json
from datetime import date, datetime, timedelta, timezone
from dotenv import load_dotenv
from pathlib import Path
from pydantic import BaseModel, Field
from tempfile import TemporaryDirectory

# Consts
ROOT = Path( __file__ ).resolve().parent.parent
load_dotenv( ROOT / ".env" )

APP_ID = int( os.environ[ "APP_ID" ] )
START_DATE = date.fromisoformat( os.environ[ "START_DATE" ] )
GAMES_POPULARITY_API_KEY = os.environ[ "GAMES_POPULARITY_API_KEY" ]

STEAM_URL = "https://api.steampowered.com/IUserReviewsService/GetAppReviews/v1/"
PLAYERS_URL = f"https://games-popularity.com/swagger/api/game/players/{APP_ID}"

# DTOs
class ReviewCSVRow( BaseModel ):
	ReviewId: int = Field( validation_alias = "recommendationid" )
	Language: str = Field( validation_alias = "language" )
	Text: str | None = Field( None, validation_alias = "review" )
	TimestampUpdated: datetime = Field( validation_alias = "timestamp_updated" )
	IsVotedUp: bool | None = Field( None, validation_alias = "voted_up" )
	# Blank topics to be classified downstream
	IsTopicAi: int = 0
	IsTopicBugs: int = 0
	IsTopicCrashes: int = 0
	IsTopicPerformance: int = 0
	IsTopicBalance: int = 0
	IsTopicCampaign: int = 0
	IsTopicBattles: int = 0
	IsTopicDlc: int = 0
	IsTopicPrice: int = 0
	IsTopicContent: int = 0
	IsTopicMultiplayer: int = 0
	IsTopicUi: int = 0
	IsTopicGraphics: int = 0
	IsTopicAudio: int = 0
	IsTopicMods: int = 0
	IsTopicDifficulty: int = 0
	IsTopicUpdate: int = 0
	IsTopicDeveloper: int = 0
	IsTopicMonetization: int = 0
	IsTopicOther: int = 0

class PlayerActivityCSVRow( BaseModel ):
	Date: date
	High: int | None = None
	Low: int | None = None

# Functions
def save_csv( path: Path, rows: list[ BaseModel ] ) -> int:
	if not rows:
		raise ValueError( f"No rows collected for {path.name}; existing CSV retained." )

	path.parent.mkdir( parents = True, exist_ok = True )

	with TemporaryDirectory( dir = path.parent ) as folder:
		temporary = Path( folder ) / path.name

		with temporary.open( "w", newline = "", encoding = "utf-8" ) as file:
			writer = csv.DictWriter( file, fieldnames = type( rows[ 0 ] ).model_fields )
			writer.writeheader()

			for row in rows:
				writer.writerow( row.model_dump( mode = "json" ) )

		temporary.replace( path )

	return len( rows )

def get_json( session: requests.Session, url: str, params: dict ) -> dict:
	response = session.get( url, params = params, timeout = 30 )
	response.raise_for_status()

	return response.json()

def get_player_activity( session: requests.Session ) -> list[ PlayerActivityCSVRow ]:
	daily: dict[ date, tuple[ int, int ] ] = {}
	cursor = None

	while True:
		params = { "apiKey": GAMES_POPULARITY_API_KEY }

		if cursor:
			params[ "cursor" ] = cursor

		data = get_json( session, PLAYERS_URL, params )
		history = data.get( "history", [] )

		if not history:
			break

		for item in history:
			day = date.fromisoformat( item[ "added" ][ :10 ] )
			players = item[ "players" ]

			if day >= START_DATE:
				high, low = daily.get( day, ( players, players ) )
				daily[ day ] = ( max( high, players ), min( low, players ) )

		if day < START_DATE:
			break

		next_cursor = data.get( "nextCursor" )

		if not next_cursor or next_cursor == cursor:
			break

		cursor = next_cursor

	if not daily:
		raise ValueError( "No player activity returned; existing CSV retained." )

	last_day = max( daily )
	total_days = ( last_day - START_DATE ).days + 1
	rows = []

	for day in sorted( daily ):
		high, low = daily[ day ]

		if high is not None and low is not None:
			rows.append( PlayerActivityCSVRow( Date = day, High = high, Low = low ) )

	return rows

def get_reviews( session: requests.Session ) -> list[ ReviewCSVRow ]:
	query = {
		"appid": APP_ID,
		"filter": 1,
		"languages": [ "all" ],
		"purchase_type": 1,
		"num_per_page": 100,
		"filter_offtopic_activity": False,
		"cursor": "*"
	}

	seen = set()
	rows = []

	while True:
		data = get_json( session, STEAM_URL, { "input_json": json.dumps( query ) } )[ "response" ]
		reviews = data.get( "reviews", [] )

		if not reviews:
			break

		for item in reviews:
			if datetime.fromtimestamp( item[ "timestamp_created" ], timezone.utc ).date() < START_DATE:
				return rows

			review = ReviewCSVRow.model_validate( item )

			if review.ReviewId not in seen:
				seen.add( review.ReviewId )
				rows.append( review )

		print( f"Steam reviews: {len( seen ):,}", end = "\r", flush = True )
		next_cursor = data.get( "cursor" )

		if not next_cursor or next_cursor == query[ "cursor" ]:
			break

		query[ "cursor" ] = next_cursor

	return rows

def main() -> None:
	with requests.Session() as session:
		activity = get_player_activity( session )
		count = save_csv( ROOT / "PlayerActivityRaw.csv", activity )
		missing = sum( row.High is None for row in activity )
		print( f"Player activity: {count:,} days ({missing:,} missing)." )

		reviews = get_reviews( session )
		count = save_csv( ROOT / "ReviewRaw.csv", reviews )
		print( f"\nSteam reviews saved: {count:,}." )

if __name__ == "__main__":
	main()
