"""Load prepared CSV datasets into the existing wh3_analysis database.

Run from the project root:
    python python/DataIngest.py

Only the prepared CSVs (without 'Raw') are ingestion-ready. The database and
its four tables must already exist, created by wh3_analysis.sql. This script
never creates or changes schema objects.

The entire refresh runs in a single transaction. A failure rolls back every
DELETE and COPY, leaving previously committed data intact. The CSV source
files are never modified.

Requirements: pip install 'psycopg[binary]' python-dotenv
Connection settings are read from the root .env file (or the environment).
"""

import csv
import math
import os
from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation
from pathlib import Path

from dotenv import load_dotenv


ROOT_DIR = Path( __file__ ).resolve().parent.parent
DATASETS_DIR = ROOT_DIR / "datasets"
DATABASE_NAME = "wh3_analysis"
TABLES = ( "Announcement", "Discount", "PlayerActivity", "Review" )

# Source fields not retained in PostgreSQL. CSV files remain unchanged.
# This is also where Review metadata is filtered before COPY.
EXCLUDED_CSV_COLUMNS = {
    "Discount": { "SourceUrl" },
    "Review": {
        "AuthorSteamId",
        "AuthorNumReviews",
        "AuthorPlaytimeForever",
        "AuthorPlaytimeLastTwoWeeks",
        "AuthorPlaytimeAtReview",
        "AuthorDeckPlaytimeAtReview",
        "AuthorLastPlayed",
        "TimestampCreated",
        "VotesUp",
        "VotesFunny",
        "WeightedVoteScore",
        "CommentCount",
        "SteamPurchase",
        "ReceivedForFree",
        "WrittenDuringEarlyAccess",
        "DeveloperResponse",
        "TimestampDevResponded",
        "PrimarilySteamDeck",
        "Refunded"
    }
}
PRIMARY_KEYS = {
    "Announcement": "BuildId",
    "PlayerActivity": "Date",
    "Review": "RecommendationId"
}


def database_settings():
    """Use existing environment settings, falling back to the project's .env."""
    load_dotenv( ROOT_DIR / ".env", override = False )

    settings = {
        "dbname": DATABASE_NAME,
        "host": os.getenv( "WH3_DB_HOST" ) or os.getenv( "POSTGRES_HOST" ) or "127.0.0.1",
        "port": os.getenv( "WH3_DB_PORT" ) or os.getenv( "POSTGRES_PORT" ) or "5432",
        "user": os.getenv( "WH3_DB_USER" ) or os.getenv( "POSTGRES_USER" ) or "wh3_user",
        "connect_timeout": 10
    }
    password = os.getenv( "WH3_DB_PASSWORD" ) or os.getenv( "POSTGRES_PASSWORD" ) or os.getenv( "PGPASSWORD" )
    if password:
        settings[ "password" ] = password
    return settings


def read_csv( path ):
    with path.open( "r", newline = "", encoding = "utf-8-sig" ) as file:
        reader = csv.DictReader( file )
        if not reader.fieldnames:
            raise ValueError( f"{path.name}: missing CSV header." )
        for row_number, row in enumerate( reader, start = 2 ):
            if None in row or any( value is None for value in row.values() ):
                raise ValueError( f"{path.name}: malformed CSV at line {row_number}." )
            yield row_number, row


def inspect_input( table ):
    """Check source files before any database rows are deleted."""
    path = DATASETS_DIR / f"{table}.csv"
    if not path.is_file():
        raise FileNotFoundError( f"Required prepared dataset not found: {path}" )

    with path.open( "r", newline = "", encoding = "utf-8-sig" ) as file:
        reader = csv.reader( file )
        header = next( reader, None )

    if not header or len( header ) != len( set( header ) ) or any( not h for h in header ):
        raise ValueError( f"{path.name}: missing or duplicate column names." )

    count = 0
    seen_keys = set()
    duplicate_dates = set()
    key = PRIMARY_KEYS.get( table )

    for row_number, row in read_csv( path ):
        count += 1
        if key:
            value = row[ key ] if key in row else None
            if value is None or not value.strip():
                raise ValueError( f"{path.name}: missing {key} at CSV line {row_number}." )
            if value in seen_keys:
                if table == "PlayerActivity":
                    duplicate_dates.add( value )
                else:
                    raise ValueError( f"{path.name}: duplicate {key}={value!r} at line {row_number}." )
            seen_keys.add( value )

    if count == 0:
        raise ValueError( f"{path.name}: refusing to replace database data with an empty CSV." )

    return { "path": path, "header": header, "count": count, "duplicate_dates": duplicate_dates }


def check_schema( cursor, table, header ):
    """Match input headers to the existing columns; never alter the schema."""
    cursor.execute(
        """SELECT column_name, data_type, is_nullable, is_identity
           FROM information_schema.columns
           WHERE table_schema = 'public' AND table_name = %s
           ORDER BY ordinal_position""",
        ( table, )
    )
    definitions = cursor.fetchall()
    if not definitions:
        raise ValueError( f"Missing public.\"{table}\" table. Run wh3_analysis.sql first." )

    columns = [ ( name, data_type, nullable == "YES" )
                for name, data_type, nullable, identity in definitions if identity != "YES" ]
    expected = [ name for name, _, _ in columns ]
    actual = [ name for name in header if name not in EXCLUDED_CSV_COLUMNS.get( table, set() ) ]
    excluded = set( header ) - set( actual )

    if expected != actual or excluded != EXCLUDED_CSV_COLUMNS.get( table, set() ):
        raise ValueError(
            f"{table}.csv does not match the existing table.\n"
            f"  CSV load columns: {actual}\n"
            f"  Database columns: {expected}\n"
            f"  Ignored reference fields: {sorted( excluded )}"
        )
    return columns


def convert_value( raw, data_type, nullable, table, column, line ):
    """Convert input CSV text to values suitable for PostgreSQL COPY."""
    if raw == "":
        if nullable:
            return None
        raise ValueError( f"{table}.csv line {line}: {column} cannot be blank." )

    try:
        if data_type == "boolean":
            if raw.lower() in ( "true", "t", "1" ):
                return True
            if raw.lower() in ( "false", "f", "0" ):
                return False
            raise ValueError( "expected True/False or 0/1" )

        if data_type in ( "integer", "bigint", "smallint" ):
            return int( raw )

        if data_type == "numeric":
            number = Decimal( raw )
            if not number.is_finite():
                raise ValueError( "non-finite numeric value" )
            return number

        if data_type in ( "double precision", "real" ):
            number = float( raw )
            if not math.isfinite( number ):
                raise ValueError( "non-finite floating-point value" )
            return number

        if data_type == "date":
            return date.fromisoformat( raw )

        if data_type == "timestamp with time zone":
            # Steam's review/announcement timestamps are Unix epoch seconds.
            # SteamDB's human-readable Price History timestamps are UTC.
            if raw.lstrip( "-" ).isdigit():
                return datetime.fromtimestamp( int( raw ), tz = timezone.utc )
            try:
                parsed = datetime.fromisoformat( raw )
            except ValueError:
                # Some SteamDB CSV exports omit the leading zero in the hour.
                parsed = datetime.strptime( raw, "%Y-%m-%d %H:%M:%S" )
            return parsed.replace( tzinfo = timezone.utc ) if parsed.tzinfo is None else parsed.astimezone( timezone.utc )

        if data_type in ( "text", "character varying", "character" ):
            return raw

        raise ValueError( f"unsupported PostgreSQL type {data_type}" )
    except ( ValueError, OverflowError, InvalidOperation ) as error:
        raise ValueError( f"{table}.csv line {line}, {column}: {raw!r} ({error})" ) from error


def load_rows( cursor, table, input_info, columns, sql ):
    """COPY prepared records; invalid duplicated player dates become NULL rows."""
    names = [ name for name, _, _ in columns ]
    copy_query = sql.SQL( "COPY {} ({}) FROM STDIN" ).format(
        sql.Identifier( "public", table ),
        sql.SQL( ", " ).join( sql.Identifier( name ) for name in names )
    )

    duplicate_dates = input_info[ "duplicate_dates" ]
    written = 0
    seen_dates = set()

    with cursor.copy( copy_query ) as copy:
        for row_number, row in read_csv( input_info[ "path" ] ):
            if table == "PlayerActivity":
                day = row[ "Date" ]
                if day in seen_dates:
                    continue
                seen_dates.add( day )
                if day in duplicate_dates or not row[ "High" ] or not row[ "Low" ]:
                    # An invalid/partial day must not be assigned invented counts.
                    row[ "High" ] = ""
                    row[ "Low" ] = ""

            values = [ convert_value( row[ name ], kind, nullable, table, name, row_number )
                       for name, kind, nullable in columns ]
            copy.write_row( values )
            written += 1

    return written


def ingest():
    try:
        import psycopg
        from psycopg import sql
    except ImportError as error:
        raise SystemExit( "Install dependencies: pip install 'psycopg[binary]' python-dotenv" ) from error

    sources = { table: inspect_input( table ) for table in TABLES }

    print( "Prepared datasets:" )
    for table, source in sources.items():
        print( f"  {table}: {source['count']:,} input rows" )
        if source[ "duplicate_dates" ]:
            print( f"    {len( source['duplicate_dates'] )} duplicate dates will have NULL High/Low." )

    # The connection context commits only after ALL deletes and loads succeed.
    # Any exception rolls back the entire reload across all four tables.
    with psycopg.connect( **database_settings() ) as connection:
        with connection.cursor() as cursor:
            columns = { table: check_schema( cursor, table, sources[ table ][ "header" ] )
                        for table in TABLES }

            for table in TABLES:
                cursor.execute( sql.SQL( "DELETE FROM {}" ).format( sql.Identifier( "public", table ) ) )

            for table in TABLES:
                written = load_rows( cursor, table, sources[ table ], columns[ table ], sql )
                print( f"  Loaded {written:,} rows into {table}." )

    print( "Ingestion completed. All four tables committed together." )


if __name__ == "__main__":
    try:
        ingest()
    except Exception as error:
        raise SystemExit( f"Data ingestion failed; database changes rolled back: {error}" ) from error
