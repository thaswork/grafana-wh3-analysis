import sys
import csv
import json
import time
from datetime import datetime, timezone

import requests


APP_ID = 1142710
START_DATE = "2024-01-19"

URL = "https://api.steampowered.com/IUserReviewsService/GetAppReviews/v1/"

MAX_RETRIES = 5


CSV_FIELDS = [
	"recommendationid",
	"author.steamid",
	"author.num_reviews",
	"author.playtime_forever",
	"author.playtime_last_two_weeks",
	"author.playtime_at_review",
	"author.deck_playtime_at_review",
	"author.last_played",
	"language",
	"review",
	"timestamp_created",
	"timestamp_updated",
	"voted_up",
	"votes_up",
	"votes_funny",
	"weighted_vote_score",
	"comment_count",
	"steam_purchase",
	"received_for_free",
	"written_during_early_access",
	"developer_response",
	"timestamp_dev_responded",
	"primarily_steam_deck",
	"refunded"
]


def flatten_review( review ):
	author = review.get( "author", {} )

	return {
		"recommendationid": review.get( "recommendationid", "" ),
		"author.steamid": author.get( "steamid", "" ),
		"author.num_reviews": author.get( "num_reviews", "" ),
		"author.playtime_forever": author.get( "playtime_forever", "" ),
		"author.playtime_last_two_weeks": author.get( "playtime_last_two_weeks", "" ),
		"author.playtime_at_review": author.get( "playtime_at_review", "" ),
		"author.deck_playtime_at_review": author.get( "deck_playtime_at_review", "" ),
		"author.last_played": author.get( "last_played", "" ),
		"language": review.get( "language", "" ),
		"review": review.get( "review", "" ),
		"timestamp_created": review.get( "timestamp_created", "" ),
		"timestamp_updated": review.get( "timestamp_updated", "" ),
		"voted_up": review.get( "voted_up", "" ),
		"votes_up": review.get( "votes_up", "" ),
		"votes_funny": review.get( "votes_funny", "" ),
		"weighted_vote_score": review.get( "weighted_vote_score", "" ),
		"comment_count": review.get( "comment_count", "" ),
		"steam_purchase": review.get( "steam_purchase", "" ),
		"received_for_free": review.get( "received_for_free", "" ),
		"written_during_early_access": review.get( "written_during_early_access", "" ),
		"developer_response": review.get( "developer_response", "" ),
		"timestamp_dev_responded": review.get( "timestamp_dev_responded", "" ),
		"primarily_steam_deck": review.get( "primarily_steam_deck", "" ),
		"refunded": review.get( "refunded", "" )
	}


def main():
	# Get output CSV and JSONL from command line
	if len( sys.argv ) != 3:
		raise SystemExit(
			f"Usage: python {sys.argv[ 0 ]} OUTPUT_CSV OUTPUT_JSONL"
		)

	csv_output = sys.argv[ 1 ]
	jsonl_output = sys.argv[ 2 ]

	seen_reviews = set()
	total_written = 0

	start_timestamp = int(
		datetime.strptime(
			START_DATE,
			"%Y-%m-%d"
		).replace(
			tzinfo = timezone.utc
		).timestamp()
	)

	# Current UTC time when the script starts
	end_timestamp = int(
		datetime.now( timezone.utc ).timestamp()
	)

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

	print(
		f"Fetching reviews from {START_DATE} "
		f"through the current time..."
	)

	with requests.Session() as session:
		with (
			open(
				csv_output,
				"w",
				newline = "",
				encoding = "utf-8"
			) as csv_file,
			open(
				jsonl_output,
				"w",
				encoding = "utf-8"
			) as jsonl_file
		):
			writer = csv.DictWriter(
				csv_file,
				fieldnames = CSV_FIELDS
			)

			writer.writeheader()

			while True:
				for attempt in range( MAX_RETRIES ):
					response = session.get(
						URL,
						params = {
							"input_json": json.dumps( query )
						},
						timeout = 30
					)

					if response.status_code == 429:
						wait_time = int(
							response.headers.get(
								"Retry-After",
								10
							)
						)

						print(
							f"\nRate limited. "
							f"Waiting {wait_time} seconds..."
						)

						time.sleep( wait_time )
						continue

					try:
						response.raise_for_status()
						break

					except requests.RequestException:
						if attempt == MAX_RETRIES - 1:
							raise

						time.sleep(
							min(
								30,
								2 ** ( attempt + 1 )
							)
						)

				response_data = response.json()

				response_data = response.json()

				if "response" not in response_data:
					raise RuntimeError(
						f"Unexpected Steam API response: {response_data}"
					)

				data = response_data[ "response" ]

				reviews = data.get( "reviews", [] )

				if not reviews:
					break

				new_reviews = 0

				# Write unique reviews to both formats
				for review in reviews:
					recommendation_id = review.get(
						"recommendationid"
					)

					if (
						not recommendation_id
						or recommendation_id in seen_reviews
					):
						continue

					seen_reviews.add( recommendation_id )

					writer.writerow(
						flatten_review( review )
					)

					json.dump(
						review,
						jsonl_file,
						ensure_ascii = False,
						separators = ( ",", ":" )
					)

					jsonl_file.write( "\n" )

					new_reviews += 1
					total_written += 1

				print(
					f"Logged {total_written:,} reviews...",
					end = "\r",
					flush = True
				)

				if not new_reviews:
					break

				# Advance Steam cursor
				next_cursor = data.get( "cursor" )

				if (
					not next_cursor
					or next_cursor == query[ "cursor" ]
				):
					break

				query[ "cursor" ] = next_cursor

	print(
		f"\nSaved {total_written:,} reviews."
		f"\nCSV: {csv_output}"
		f"\nJSONL: {jsonl_output}"
	)


if __name__ == "__main__":
	main()