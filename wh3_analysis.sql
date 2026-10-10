-- wh3_analysis.sql
-- Schema-only setup for the Grafana Steam Review project (PostgreSQL 18).
-- Run with psql, connected initially to the maintenance database "postgres":
--   psql -X -v ON_ERROR_STOP=1 -U YOUR_POSTGRES_SUPERUSER -d postgres -f wh3_analysis.sql
--
-- IMPORTANT:
--   * This file uses psql meta-commands (\gexec and \connect); it is not
--     a single SQL statement suitable for generic SQL editors.
--   * Use a PostgreSQL role allowed to CREATE ROLE and CREATE DATABASE.
--   * Existing tables/data are never dropped, truncated, or replaced.
--   * An existing table with incompatible columns/types/nullability causes
--     an error instead of being silently accepted.
--   * Credentials are not embedded in this file. Optional passwords may be
--     exported as WH3_DB_PASSWORD and GRAFANA_DB_PASSWORD before running psql.
--     The default Docker POSTGRES_USER may already be wh3_user with a password.
--   * Data ingestion, including Unix-epoch to timestamptz conversion and
--     source CSV duplicate resolution, is handled separately by DataIngest.py.

\set ON_ERROR_STOP on

-- Roles are created only when absent. Existing role passwords are retained
-- unless a new password is explicitly passed through the environment.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'wh3_user') THEN
        CREATE ROLE wh3_user LOGIN;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'grafana_reader') THEN
        CREATE ROLE grafana_reader LOGIN;
    END IF;
END;
$$;

-- PostgreSQL cannot run CREATE DATABASE inside a DO block or transaction.
-- \gexec executes the generated CREATE DATABASE statement only when missing.
SELECT format('CREATE DATABASE %I OWNER %I ENCODING %L',
              'wh3_analysis', 'wh3_user', 'UTF8')
WHERE NOT EXISTS (
    SELECT FROM pg_catalog.pg_database WHERE datname = 'wh3_analysis'
) \gexec

-- Optional credentials for new (or existing) application roles.
-- These must be exported in the shell; Docker Compose does not automatically
-- export variables from the project's .env into the calling shell.
\getenv wh3_db_password WH3_DB_PASSWORD
\if :{?wh3_db_password}
ALTER ROLE wh3_user LOGIN PASSWORD :'wh3_db_password';
\endif
\getenv grafana_db_password GRAFANA_DB_PASSWORD
\if :{?grafana_db_password}
ALTER ROLE grafana_reader LOGIN PASSWORD :'grafana_db_password';
\endif

\connect wh3_analysis

-- Constrain schema resolution and grant access to the two project roles.
SET search_path = pg_catalog, public;
GRANT CONNECT ON DATABASE wh3_analysis TO wh3_user, grafana_reader;
GRANT USAGE ON SCHEMA public TO wh3_user, grafana_reader;
-- In a new database owned by wh3_user, public is managed by pg_database_owner.
-- Grant CREATE explicitly so an existing database with a different owner also
-- permits that role to manage project tables.
GRANT CREATE ON SCHEMA public TO wh3_user;

-- All timestamps represent UTC instants. Discount timestamps are taken from
-- SteamDB's UTC Price History display. Day-only values remain DATE, not synthetic
-- timestamps. CSV names remain unchanged in the SQL schema.

-- Check any existing tables BEFORE creating new ones. CREATE TABLE IF NOT
-- EXISTS only checks a name, not an existing object's structure. An incompatible
-- older schema is reported without adding partial new tables or altering data.
DO $schema_validation$
DECLARE
    mismatch text;
BEGIN
    WITH expected (table_name, column_name, data_type, required, identity_kind) AS (
        VALUES
            ('Announcement', 'AnnouncementId', 'bigint', true, 'a'),
            ('Announcement', 'BuildId', 'bigint', true, ''),
            ('Announcement', 'Timestamp', 'timestamp with time zone', true, ''),
            ('Announcement', 'PatchTitle', 'text', true, ''),
            ('Announcement', 'Patch', 'boolean', true, ''),
            ('Announcement', 'Hotfix', 'boolean', true, ''),
            ('Announcement', 'FreeContent', 'boolean', true, ''),
            ('Announcement', 'PaidContent', 'boolean', true, ''),
            ('Announcement', 'TopicAi', 'boolean', true, ''),
            ('Announcement', 'TopicBugs', 'boolean', true, ''),
            ('Announcement', 'TopicCrashes', 'boolean', true, ''),
            ('Announcement', 'TopicPerformance', 'boolean', true, ''),
            ('Announcement', 'TopicBalance', 'boolean', true, ''),
            ('Announcement', 'TopicCampaign', 'boolean', true, ''),
            ('Announcement', 'TopicBattles', 'boolean', true, ''),
            ('Announcement', 'TopicDlc', 'boolean', true, ''),
            ('Announcement', 'TopicPrice', 'boolean', true, ''),
            ('Announcement', 'TopicContent', 'boolean', true, ''),
            ('Announcement', 'TopicMultiplayer', 'boolean', true, ''),
            ('Announcement', 'TopicUi', 'boolean', true, ''),
            ('Announcement', 'TopicGraphics', 'boolean', true, ''),
            ('Announcement', 'TopicAudio', 'boolean', true, ''),
            ('Announcement', 'TopicMods', 'boolean', true, ''),
            ('Announcement', 'TopicDifficulty', 'boolean', true, ''),
            ('Announcement', 'TopicUpdate', 'boolean', true, ''),
            ('Announcement', 'TopicDeveloper', 'boolean', true, ''),
            ('Announcement', 'TopicMonetization', 'boolean', true, ''),
            ('Announcement', 'TopicOther', 'boolean', true, ''),
            ('Discount', 'DiscountId', 'bigint', true, 'a'),
            ('Discount', 'DateTime', 'timestamp with time zone', true, ''),
            ('Discount', 'FinalPrice', 'numeric(6,2)', true, ''),
            ('Discount', 'DateTimeEnd', 'timestamp with time zone', false, ''),
            ('Discount', 'NormalDiscount', 'boolean', true, ''),
            ('Discount', 'SeasonalDiscount', 'boolean', true, ''),
            ('Discount', 'HolidayDiscount', 'boolean', true, ''),
            ('Discount', 'SpecialDiscount', 'boolean', true, ''),
            ('Discount', 'DiscountTitle', 'text', true, ''),
            ('PlayerActivity', 'Date', 'date', true, ''),
            ('PlayerActivity', 'High', 'integer', false, ''),
            ('PlayerActivity', 'Low', 'integer', false, ''),
            ('Review', 'RecommendationId', 'bigint', true, ''),
            ('Review', 'AuthorSteamId', 'bigint', true, ''),
            ('Review', 'AuthorNumReviews', 'integer', true, ''),
            ('Review', 'AuthorPlaytimeForever', 'integer', true, ''),
            ('Review', 'AuthorPlaytimeLastTwoWeeks', 'integer', true, ''),
            ('Review', 'AuthorPlaytimeAtReview', 'integer', true, ''),
            ('Review', 'AuthorDeckPlaytimeAtReview', 'numeric', false, ''),
            ('Review', 'AuthorLastPlayed', 'timestamp with time zone', true, ''),
            ('Review', 'Language', 'text', true, ''),
            ('Review', 'Review', 'text', false, ''),
            ('Review', 'TimestampCreated', 'timestamp with time zone', true, ''),
            ('Review', 'TimestampUpdated', 'timestamp with time zone', true, ''),
            ('Review', 'VotedUp', 'boolean', true, ''),
            ('Review', 'VotesUp', 'integer', true, ''),
            ('Review', 'VotesFunny', 'integer', true, ''),
            ('Review', 'WeightedVoteScore', 'double precision', true, ''),
            ('Review', 'CommentCount', 'integer', true, ''),
            ('Review', 'SteamPurchase', 'boolean', true, ''),
            ('Review', 'ReceivedForFree', 'boolean', true, ''),
            ('Review', 'WrittenDuringEarlyAccess', 'boolean', true, ''),
            ('Review', 'DeveloperResponse', 'text', false, ''),
            ('Review', 'TimestampDevResponded', 'timestamp with time zone', false, ''),
            ('Review', 'PrimarilySteamDeck', 'boolean', true, ''),
            ('Review', 'Refunded', 'boolean', true, ''),
            ('Review', 'TopicAi', 'boolean', true, ''),
            ('Review', 'TopicBugs', 'boolean', true, ''),
            ('Review', 'TopicCrashes', 'boolean', true, ''),
            ('Review', 'TopicPerformance', 'boolean', true, ''),
            ('Review', 'TopicBalance', 'boolean', true, ''),
            ('Review', 'TopicCampaign', 'boolean', true, ''),
            ('Review', 'TopicBattles', 'boolean', true, ''),
            ('Review', 'TopicDlc', 'boolean', true, ''),
            ('Review', 'TopicPrice', 'boolean', true, ''),
            ('Review', 'TopicContent', 'boolean', true, ''),
            ('Review', 'TopicMultiplayer', 'boolean', true, ''),
            ('Review', 'TopicUi', 'boolean', true, ''),
            ('Review', 'TopicGraphics', 'boolean', true, ''),
            ('Review', 'TopicAudio', 'boolean', true, ''),
            ('Review', 'TopicMods', 'boolean', true, ''),
            ('Review', 'TopicDifficulty', 'boolean', true, ''),
            ('Review', 'TopicUpdate', 'boolean', true, ''),
            ('Review', 'TopicDeveloper', 'boolean', true, ''),
            ('Review', 'TopicMonetization', 'boolean', true, ''),
            ('Review', 'TopicOther', 'boolean', true, '')
    ),
    expected_active AS (
        SELECT e.* FROM expected AS e
        WHERE pg_catalog.to_regclass(pg_catalog.format('public.%I', e.table_name)) IS NOT NULL
    ),
    actual AS (
        SELECT cls.relname::text AS table_name,
               att.attname::text AS column_name,
               pg_catalog.format_type(att.atttypid, att.atttypmod) AS data_type,
               att.attnotnull AS required,
               att.attidentity::text AS identity_kind
        FROM pg_catalog.pg_attribute AS att
        JOIN pg_catalog.pg_class AS cls ON cls.oid = att.attrelid
        JOIN pg_catalog.pg_namespace AS ns ON ns.oid = cls.relnamespace
        WHERE ns.nspname = 'public'
          AND cls.relname IN ('Announcement', 'Discount', 'PlayerActivity', 'Review')
          AND cls.relkind IN ('r', 'p')
          AND att.attnum > 0
          AND NOT att.attisdropped
    ),
    changes AS (
        SELECT COALESCE(e.table_name, a.table_name) AS table_name,
               COALESCE(e.column_name, a.column_name) AS column_name,
               CASE
                   WHEN e.column_name IS NULL THEN 'unexpected column'
                   WHEN a.column_name IS NULL THEN 'missing column'
                   ELSE format('expected %s (NOT NULL=%s, identity=%s), found %s (NOT NULL=%s, identity=%s)',
                               e.data_type, e.required, e.identity_kind,
                               a.data_type, a.required, a.identity_kind)
               END AS problem
        FROM expected_active AS e
        FULL JOIN actual AS a
          ON a.table_name = e.table_name AND a.column_name = e.column_name
        WHERE e.column_name IS NULL
           OR a.column_name IS NULL
           OR e.data_type <> a.data_type
           OR e.required <> a.required
           OR e.identity_kind <> a.identity_kind
    )
    SELECT string_agg(format('%I.%I: %s', table_name, column_name, problem), E'\n')
      INTO mismatch
    FROM changes;

    IF mismatch IS NOT NULL THEN
        RAISE EXCEPTION 'Existing project schema differs from wh3_analysis.sql:%',
                        E'\n' || mismatch;
    END IF;
END;
$schema_validation$;

-- Existing tables must also retain the expected named constraints.
-- Their definitions are not rewritten by this schema-only setup.
DO $constraint_validation$
DECLARE
    missing_constraints text;
BEGIN
    WITH expected (table_name, constraint_name, constraint_kind) AS (
        VALUES
            ('Announcement', 'Announcement_pkey', 'p'),
            ('Announcement', 'Announcement_BuildId_key', 'u'),
            ('Discount', 'Discount_pkey', 'p'),
            ('Discount', 'DiscountPrice', 'c'),
            ('Discount', 'DiscountSingleType', 'c'),
            ('Discount', 'DiscountTimeRange', 'c'),
            ('PlayerActivity', 'PlayerActivity_pkey', 'p'),
            ('PlayerActivity', 'PlayerActivityHighLow', 'c'),
            ('PlayerActivity', 'PlayerActivityNonnegative', 'c'),
            ('Review', 'Review_pkey', 'p')
    )
    SELECT string_agg(format('%I: missing %I', e.table_name, e.constraint_name), E'\n')
      INTO missing_constraints
    FROM expected AS e
    WHERE pg_catalog.to_regclass(pg_catalog.format('public.%I', e.table_name)) IS NOT NULL
      AND NOT EXISTS (
          SELECT 1
          FROM pg_catalog.pg_constraint AS con
          JOIN pg_catalog.pg_class AS cls ON cls.oid = con.conrelid
          JOIN pg_catalog.pg_namespace AS ns ON ns.oid = cls.relnamespace
          WHERE ns.nspname = 'public'
            AND cls.relname = e.table_name
            AND con.conname = e.constraint_name
            AND con.contype::text = e.constraint_kind
      );

    IF missing_constraints IS NOT NULL THEN
        RAISE EXCEPTION 'Existing project schema is missing constraints:%',
                        E'\n' || missing_constraints;
    END IF;
END;
$constraint_validation$;

-- Newly created tables belong to wh3_user, regardless of which administrative
-- role executed the setup file. Existing object ownership is not changed.
SET ROLE wh3_user;

-- Announcement: schema columns track Announcement.csv, except for generated identity keys.
CREATE TABLE IF NOT EXISTS public."Announcement" (
    "AnnouncementId" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    "BuildId" bigint NOT NULL,
    "Timestamp" timestamp with time zone NOT NULL,
    "PatchTitle" text NOT NULL,
    "Patch" boolean NOT NULL,
    "Hotfix" boolean NOT NULL,
    "FreeContent" boolean NOT NULL,
    "PaidContent" boolean NOT NULL,
    "TopicAi" boolean NOT NULL,
    "TopicBugs" boolean NOT NULL,
    "TopicCrashes" boolean NOT NULL,
    "TopicPerformance" boolean NOT NULL,
    "TopicBalance" boolean NOT NULL,
    "TopicCampaign" boolean NOT NULL,
    "TopicBattles" boolean NOT NULL,
    "TopicDlc" boolean NOT NULL,
    "TopicPrice" boolean NOT NULL,
    "TopicContent" boolean NOT NULL,
    "TopicMultiplayer" boolean NOT NULL,
    "TopicUi" boolean NOT NULL,
    "TopicGraphics" boolean NOT NULL,
    "TopicAudio" boolean NOT NULL,
    "TopicMods" boolean NOT NULL,
    "TopicDifficulty" boolean NOT NULL,
    "TopicUpdate" boolean NOT NULL,
    "TopicDeveloper" boolean NOT NULL,
    "TopicMonetization" boolean NOT NULL,
    "TopicOther" boolean NOT NULL,
    CONSTRAINT "Announcement_pkey" PRIMARY KEY ("AnnouncementId"),
    CONSTRAINT "Announcement_BuildId_key" UNIQUE ("BuildId")
);

-- Discount: generated ID; SourceUrl remains in Discount.csv for human reference only.
CREATE TABLE IF NOT EXISTS public."Discount" (
    "DiscountId" bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    "DateTime" timestamp with time zone NOT NULL,
    "FinalPrice" numeric(6,2) NOT NULL,
    "DateTimeEnd" timestamp with time zone,
    "NormalDiscount" boolean NOT NULL,
    "SeasonalDiscount" boolean NOT NULL,
    "HolidayDiscount" boolean NOT NULL,
    "SpecialDiscount" boolean NOT NULL,
    "DiscountTitle" text NOT NULL,
    CONSTRAINT "Discount_pkey" PRIMARY KEY ("DiscountId"),
    CONSTRAINT "DiscountPrice" CHECK ("FinalPrice" >= 0),
    CONSTRAINT "DiscountSingleType" CHECK ("NormalDiscount"::int + "SeasonalDiscount"::int + "HolidayDiscount"::int + "SpecialDiscount"::int = 1),
    CONSTRAINT "DiscountTimeRange" CHECK ("DateTimeEnd" IS NULL OR "DateTimeEnd" > "DateTime")
);

-- PlayerActivity: schema columns track PlayerActivity.csv. Date is the natural key.
CREATE TABLE IF NOT EXISTS public."PlayerActivity" (
    "Date" date NOT NULL,
    "High" integer,
    "Low" integer,
    CONSTRAINT "PlayerActivity_pkey" PRIMARY KEY ("Date"),
    CONSTRAINT "PlayerActivityHighLow" CHECK ("High" IS NULL OR "Low" IS NULL OR "High" >= "Low"),
    CONSTRAINT "PlayerActivityNonnegative" CHECK (("High" IS NULL OR "High" >= 0) AND ("Low" IS NULL OR "Low" >= 0))
);

-- Review: prepared classification columns match Review.csv.
CREATE TABLE IF NOT EXISTS public."Review" (
    "RecommendationId" bigint NOT NULL,
    "AuthorSteamId" bigint NOT NULL,
    "AuthorNumReviews" integer NOT NULL,
    "AuthorPlaytimeForever" integer NOT NULL,
    "AuthorPlaytimeLastTwoWeeks" integer NOT NULL,
    "AuthorPlaytimeAtReview" integer NOT NULL,
    "AuthorDeckPlaytimeAtReview" numeric,
    "AuthorLastPlayed" timestamp with time zone NOT NULL,
    "Language" text NOT NULL,
    "Review" text,
    "TimestampCreated" timestamp with time zone NOT NULL,
    "TimestampUpdated" timestamp with time zone NOT NULL,
    "VotedUp" boolean NOT NULL,
    "VotesUp" integer NOT NULL,
    "VotesFunny" integer NOT NULL,
    "WeightedVoteScore" double precision NOT NULL,
    "CommentCount" integer NOT NULL,
    "SteamPurchase" boolean NOT NULL,
    "ReceivedForFree" boolean NOT NULL,
    "WrittenDuringEarlyAccess" boolean NOT NULL,
    "DeveloperResponse" text,
    "TimestampDevResponded" timestamp with time zone,
    "PrimarilySteamDeck" boolean NOT NULL,
    "Refunded" boolean NOT NULL,
    "TopicAi" boolean NOT NULL,
    "TopicBugs" boolean NOT NULL,
    "TopicCrashes" boolean NOT NULL,
    "TopicPerformance" boolean NOT NULL,
    "TopicBalance" boolean NOT NULL,
    "TopicCampaign" boolean NOT NULL,
    "TopicBattles" boolean NOT NULL,
    "TopicDlc" boolean NOT NULL,
    "TopicPrice" boolean NOT NULL,
    "TopicContent" boolean NOT NULL,
    "TopicMultiplayer" boolean NOT NULL,
    "TopicUi" boolean NOT NULL,
    "TopicGraphics" boolean NOT NULL,
    "TopicAudio" boolean NOT NULL,
    "TopicMods" boolean NOT NULL,
    "TopicDifficulty" boolean NOT NULL,
    "TopicUpdate" boolean NOT NULL,
    "TopicDeveloper" boolean NOT NULL,
    "TopicMonetization" boolean NOT NULL,
    "TopicOther" boolean NOT NULL,
    CONSTRAINT "Review_pkey" PRIMARY KEY ("RecommendationId")
);

RESET ROLE;

-- The database owner or administrative role executing this file grants access
-- regardless of whether each table was newly created or already present.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_reader;

-- Index names are stable and independent of the upstream CSV filenames.
CREATE INDEX IF NOT EXISTS "IdxAnnouncementTimestamp"
    ON public."Announcement" ("Timestamp");
CREATE INDEX IF NOT EXISTS "IdxDiscountDateTime"
    ON public."Discount" ("DateTime");
CREATE INDEX IF NOT EXISTS "IdxDiscountDateTimeEnd"
    ON public."Discount" ("DateTimeEnd");
CREATE INDEX IF NOT EXISTS "IdxReviewTimestampUpdated"
    ON public."Review" ("TimestampUpdated");
CREATE INDEX IF NOT EXISTS "IdxReviewTimestampCreated"
    ON public."Review" ("TimestampCreated");

-- Access also applies to future project tables created by wh3_user.
ALTER DEFAULT PRIVILEGES FOR ROLE wh3_user IN SCHEMA public
    GRANT SELECT ON TABLES TO grafana_reader;
-- Explicit DML and identity sequence access for DataIngest.py.
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA public TO wh3_user;
GRANT USAGE, SELECT
    ON ALL SEQUENCES IN SCHEMA public TO wh3_user;

-- This script defines database structure only. No rows are inserted.
