"""Collect Steam reviews and daily player activity for Total War: WARHAMMER III."""

import argparse
import csv
import json
import os
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

import requests


APP_ID = 1142710
START_DATE = "2024-01-19"

STEAM_REVIEWS_URL = "https://api.steampowered.com/IUserReviewsService/GetAppReviews/v1/"
PLAYER_ACTIVITY_URL = f"https://games-popularity.com/swagger/api/game/players/{APP_ID}"

DATASETS_DIR = Path( __file__ ).resolve().parent.parent / "datasets"
MAX_RETRIES = 5
REQUEST_TIMEOUT = 30

REVIEW_FIELDS = {
	"RecommendationId": ( "recommendationid", ),
	"AuthorSteamId": ( "author", "steamid" ),
	"AuthorNumReviews": ( "author", "num_reviews" ),
	"AuthorPlaytimeForever": ( "author", "playtime_forever" ),
	"AuthorPlaytimeLastTwoWeeks": ( "author", "playtime_last_two_weeks" ),
	"AuthorPlaytimeAtReview": ( "author", "playtime_at_review" ),
	"AuthorDeckPlaytimeAtReview": ( "author", "deck_playtime_at_review" ),
	"AuthorLastPlayed": ( "author", "last_played" ),
	"Language": ( "language", ),
	"Review": ( "review", ),
	"TimestampCreated": ( "timestamp_created", ),
	"TimestampUpdated": ( "timestamp_updated", ),
	"VotedUp": ( "voted_up", ),
	"VotesUp": ( "votes_up", ),
	"VotesFunny": ( "votes_funny", ),
	"WeightedVoteScore": ( "weighted_vote_score", ),
	"CommentCount": ( "comment_count", ),
	"SteamPurchase": ( "steam_purchase", ),
	"ReceivedForFree": ( "received_for_free", ),
	"WrittenDuringEarlyAccess": ( "written_during_early_access", ),
	"DeveloperResponse": ( "developer_response", ),
	"TimestampDevResponded": ( "timestamp_dev_responded", ),
	"PrimarilySteamDeck": ( "primarily_steam_deck", ),
	"Refunded": ( "refunded", )
}


def get_json( session, url, params, source ):
	"""Fetch a page, retrying rate limits and temporary failures."""
	for attempt in range( MAX_RETRIES ):
		try:
			response = session.get( url, params = params, timeout = REQUEST_TIMEOUT )
		except requests.RequestException:
			if attempt == MAX_RETRIES - 1:
				raise RuntimeError( f"{source}: network request failed after {MAX_RETRIES} attempts." ) from None
		else:
			if response.status_code == 429 or 500 <= response.status_code < 600:
				if attempt == MAX_RETRIES - 1:
					raise RuntimeError( f"{source}: HTTP {response.status_code} after {MAX_RETRIES} attempts." )

				if response.status_code == 429:
					retry_after = response.headers.get( "Retry-After", "" )
					wait_time = int( retry_after ) if retry_after.isdigit() else 10
				else:
					wait_time = min( 30, 2 ** ( attempt + 1 ) )

				print( f"{source}: HTTP {response.status_code}; retrying in {wait_time} seconds..." )
				time.sleep( wait_time )
				continue

			if not response.ok:
				raise RuntimeError( f"{source}: HTTP {response.status_code}." )

			try:
				return response.json()
			except ValueError:
				raise RuntimeError( f"{source}: API returned invalid JSON." ) from None

		wait_time = min( 30, 2 ** ( attempt + 1 ) )
		print( f"{source}: network error; retrying in {wait_time} seconds..." )
		time.sleep( wait_time )


def save_csv( output_file, fieldnames, write_rows ):
	"""Write a temporary CSV and replace the destination only on success."""
	output_file.parent.mkdir( parents = True, exist_ok = True )
	temp_path = None

	try:
		with tempfile.NamedTemporaryFile(
			mode = "w",
			newline = "",
			encoding = "utf-8",
			dir = output_file.parent,
			prefix = output_file.stem + "_",
			suffix = ".tmp",
			delete = False
		) as file:
			temp_path = Path( file.name )
			writer = csv.DictWriter( file, fieldnames = fieldnames )
			writer.writeheader()
			row_count = write_rows( writer )

		temp_path.replace( output_file )
		return row_count
	finally:
		if temp_path is not None:
			temp_path.unlink( missing_ok = True )


def flatten_review( review ):
	row = {}
	for column, path in REVIEW_FIELDS.items():
		value = review
		for key in path:
			value = value.get( key ) if isinstance( value, dict ) else None
		row[ column ] = "" if value is None else value
	return row


def fetch_player_activity( session, api_key ):
	"""Fetch historical player observations and aggregate daily highs/lows."""
	output_file = DATASETS_DIR / "PlayerActivity.csv"
	cursor = None
	seen_cursors = set()
	daily = {}

	print( f"Fetching player activity starting {START_DATE}..." )

	while True:
		params = { "apiKey": api_key }
		if cursor is not None:
			params[ "cursor" ] = cursor

		data = get_json( session, PLAYER_ACTIVITY_URL, params, "Player activity" )
		history = data.get( "history", [] )
		if not history:
			break

		for point in history:
			date = point[ "added" ][ :10 ]
			if date < START_DATE:
				continue

			players = point[ "players" ]
			if date not in daily:
				daily[ date ] = { "High": players, "Low": players }
			else:
				daily[ date ][ "High" ] = max( daily[ date ][ "High" ], players )
				daily[ date ][ "Low" ] = min( daily[ date ][ "Low" ], players )

		# The original API uses newest-to-oldest pages.
		if history[ -1 ][ "added" ][ :10 ] < START_DATE:
			break

		next_cursor = data.get( "nextCursor" )
		if not next_cursor:
			break
		if next_cursor == cursor or next_cursor in seen_cursors:
			raise RuntimeError( "Player activity: pagination cursor repeated." )

		seen_cursors.add( next_cursor )
		cursor = next_cursor

	def write_rows( writer ):
		for date in sorted( daily ):
			writer.writerow( { "Date": date, **daily[ date ] } )
		return len( daily )

	count = save_csv( output_file, [ "Date", "High", "Low" ], write_rows )
	print( f"Saved {count:,} days to {output_file}" )


def fetch_reviews( session ):
	"""Fetch unique Steam reviews and write one CSV row per recommendation."""
	output_file = DATASETS_DIR / "Review.csv"
	start_timestamp = int(
		datetime.strptime( START_DATE, "%Y-%m-%d" ).replace( tzinfo = timezone.utc ).timestamp()
	)
	end_timestamp = int( datetime.now( timezone.utc ).timestamp() )

	query = {
		"appid": APP_ID,
		"filter": 1,
		"languages": [ "all" ],
		"review_type": 0,
		"purchase_type": 1,
		"num_per_page": 100,
		"filter_offtopic_activity": False,
		"date_range_start": start_timestamp,
		"date_range_end": end_timestamp,
		"cursor": "*"
	}

	print( f"Fetching Steam reviews starting {START_DATE}..." )
	seen_reviews = set()
	seen_cursors = { "*" }

	def write_rows( writer ):
		total = 0
		while True:
			data = get_json(
				session,
				STEAM_REVIEWS_URL,
				{ "input_json": json.dumps( query ) },
				"Steam reviews"
			)
			if "response" not in data:
				raise RuntimeError( "Steam reviews: unexpected API response format." )

			response = data[ "response" ]
			reviews = response.get( "reviews", [] )
			if not reviews:
				break

			new_reviews = 0
			for review in reviews:
				recommendation_id = review.get( "recommendationid" )
				if not recommendation_id or recommendation_id in seen_reviews:
					continue

				seen_reviews.add( recommendation_id )
				writer.writerow( flatten_review( review ) )
				new_reviews += 1
				total += 1

			print( f"Collected {total:,} Steam reviews...", end = "\r", flush = True )
			if not new_reviews:
				break

			next_cursor = response.get( "cursor" )
			if not next_cursor:
				break
			if next_cursor in seen_cursors:
				break
			seen_cursors.add( next_cursor )
			query[ "cursor" ] = next_cursor

		return total

	count = save_csv( output_file, list( REVIEW_FIELDS ), write_rows )
	print( f"\nSaved {count:,} reviews to {output_file}" )


def main():
	parser = argparse.ArgumentParser( description = "Collect player activity and Steam review CSV datasets." )
	parser.add_argument(
		"api_key",
		nargs = "?",
		help = "Games Popularity API key (or set GAMES_POPULARITY_API_KEY)."
	)
	args = parser.parse_args()

	api_key = args.api_key or os.environ.get( "GAMES_POPULARITY_API_KEY" )
	if not api_key:
		parser.error( "Games Popularity API key required as an argument or GAMES_POPULARITY_API_KEY." )

	with requests.Session() as session:
		fetch_player_activity( session, api_key )
		fetch_reviews( session )


if __name__ == "__main__":
	main()
