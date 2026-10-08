import sys
import csv
import requests

APP_ID = 1142710
START_DATE = "2026-09-23"
URL = f"https://games-popularity.com/swagger/api/game/players/{APP_ID}"

def main():
	# Get API key and output CSV from command line
	if len( sys.argv ) != 3:
		raise SystemExit( f"Usage: python {sys.argv[ 0 ]} API_KEY OUTPUT_CSV" )

	api_key = sys.argv[ 1 ]
	output_file = sys.argv[ 2 ]
	cursor = None
	daily = {}

	while True:
		# Fetch history page
		params = { "apiKey": api_key }

		if cursor:
			params[ "cursor" ] = cursor

		response = requests.get( URL, params = params )
		response.raise_for_status()

		data = response.json()
		history = data.get( "history", [] )

		if not history:
			break

		# Process player counts
		for point in history:
			date = point[ "added" ][ :10 ]

			if date < START_DATE:
				continue

			players = point[ "players" ]

			if date not in daily:
				daily[ date ] = { "high": players, "low": players }
			else:
				daily[ date ][ "high" ] = max( daily[ date ][ "high" ], players )
				daily[ date ][ "low" ] = min( daily[ date ][ "low" ], players )

		if history[ -1 ][ "added" ][ :10 ] < START_DATE:
			break

		# Get next page
		cursor = data.get( "nextCursor" )

		if not cursor:
			break

	# Write daily high and low to CSV
	with open( output_file, "w", newline = "", encoding = "utf-8" ) as file:
		writer = csv.writer( file )
		writer.writerow( [ "date", "high", "low" ] )

		for date in sorted( daily ):
			writer.writerow( [
				date,
				daily[ date ][ "high" ],
				daily[ date ][ "low" ]
			] )

	print( f"Saved {len( daily )} days to {output_file}" )

if __name__ == "__main__":
	main()
