import os
import psycopg
from dotenv import load_dotenv
from pathlib import Path
from psycopg import sql

# Consts
ROOT = Path( __file__ ).resolve().parent.parent
load_dotenv( ROOT / ".env" )

DATASETS = ROOT / "datasets"
TABLES = ( "Build", "Discount", "PlayerActivity", "Review" )

# Functions
def delete_rows( cursor: psycopg.Cursor ) -> None:
	for table in TABLES:
		cursor.execute( sql.SQL( "DELETE FROM {}" ).format( sql.Identifier( "public", table ) ) )

def load_csv( cursor: psycopg.Cursor, table: str ) -> int:
	query = sql.SQL( "COPY {} FROM STDIN WITH (FORMAT CSV, HEADER TRUE)" ).format(
		sql.Identifier( "public", table )
	)

	with ( DATASETS / f"{table}.csv" ).open( "r", encoding = "utf-8-sig", newline = "" ) as file:
		with cursor.copy( query ) as copy:
			while chunk := file.read( 1024 * 1024 ):
				copy.write( chunk )

	cursor.execute( sql.SQL( "SELECT COUNT(*) FROM {}" ).format( sql.Identifier( "public", table ) ) )
	return cursor.fetchone()[ 0 ]

def main() -> None:
	counts = {}

	with psycopg.connect(
		dbname = "wh3_analysis",
		host = os.getenv( "POSTGRES_HOST", "127.0.0.1" ),
		port = os.getenv( "POSTGRES_PORT", "5432" ),
		user = os.getenv( "POSTGRES_USER", "wh3_user" ),
		password = os.getenv( "POSTGRES_PASSWORD" )
	) as connection:
		with connection.cursor() as cursor:
			cursor.execute( "SET TIME ZONE 'UTC'" )
			delete_rows( cursor )

			for table in TABLES:
				counts[ table ] = load_csv( cursor, table )

	for table, count in counts.items():
		print( f"{table}: {count:,} rows loaded." )

	print( "Data ingestion completed." )

if __name__ == "__main__":
	main()
