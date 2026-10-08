BEGIN;


-- Create the three tables with primary keys
CREATE TABLE IF NOT EXISTS "PlayerActivity"
(
    "ActivityDate" DATE PRIMARY KEY,
    "HighPlayerCount" INTEGER,
    "LowPlayerCount" INTEGER,

    CONSTRAINT "PlayerActivityNonnegative"
        CHECK
        (
            ( "HighPlayerCount" IS NULL OR "HighPlayerCount" >= 0 )
            AND
            ( "LowPlayerCount" IS NULL OR "LowPlayerCount" >= 0 )
        ),

    CONSTRAINT "PlayerActivityHighLow"
        CHECK
        (
            "HighPlayerCount" IS NULL
            OR "LowPlayerCount" IS NULL
            OR "HighPlayerCount" >= "LowPlayerCount"
        )
);


CREATE TABLE IF NOT EXISTS "Announcement"
(
    "AnnouncementId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "BuildId" BIGINT NOT NULL UNIQUE,
    "EventTime" TIMESTAMPTZ NOT NULL,
    "PatchTitle" TEXT NOT NULL,

    "Patch" BOOLEAN NOT NULL,
    "Hotfix" BOOLEAN NOT NULL,
    "FreeContent" BOOLEAN NOT NULL,
    "PaidContent" BOOLEAN NOT NULL,

    "TopicAi" BOOLEAN NOT NULL,
    "TopicBugs" BOOLEAN NOT NULL,
    "TopicCrashes" BOOLEAN NOT NULL,
    "TopicPerformance" BOOLEAN NOT NULL,
    "TopicBalance" BOOLEAN NOT NULL,
    "TopicCampaign" BOOLEAN NOT NULL,
    "TopicBattles" BOOLEAN NOT NULL,
    "TopicDlc" BOOLEAN NOT NULL,
    "TopicContent" BOOLEAN NOT NULL,
    "TopicMultiplayer" BOOLEAN NOT NULL,
    "TopicUi" BOOLEAN NOT NULL,
    "TopicGraphics" BOOLEAN NOT NULL,
    "TopicAudio" BOOLEAN NOT NULL,
    "TopicMods" BOOLEAN NOT NULL,
    "TopicDifficulty" BOOLEAN NOT NULL,
    "TopicUpdate" BOOLEAN NOT NULL
);


CREATE TABLE IF NOT EXISTS "DiscountEvent"
(
    "DiscountEventId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    "StartTime" TIMESTAMPTZ NOT NULL,
    "EndTime" TIMESTAMPTZ,

    "FinalPrice" NUMERIC(6, 2) NOT NULL,

    "NormalDiscount" BOOLEAN NOT NULL,
    "SeasonalDiscount" BOOLEAN NOT NULL,
    "HolidayDiscount" BOOLEAN NOT NULL,
    "SpecialDiscount" BOOLEAN NOT NULL,

    "DiscountTitle" TEXT NOT NULL,
    "SourceUrl" TEXT,

    CONSTRAINT "DiscountEventTimeRange"
        CHECK
        (
            "EndTime" IS NULL
            OR "EndTime" > "StartTime"
        ),

    CONSTRAINT "DiscountEventPrice"
        CHECK ( "FinalPrice" >= 0 ),

    CONSTRAINT "DiscountEventSingleType"
        CHECK
        (
            "NormalDiscount"::INTEGER
            + "SeasonalDiscount"::INTEGER
            + "HolidayDiscount"::INTEGER
            + "SpecialDiscount"::INTEGER
            = 1
        )
);


-- Create index for each so individually they query faster in theory
CREATE INDEX IF NOT EXISTS "IdxAnnouncementEventTime"
    ON "Announcement" ( "EventTime" );

CREATE INDEX IF NOT EXISTS "IdxDiscountEventStartTime"
    ON "DiscountEvent" ( "StartTime" );

CREATE INDEX IF NOT EXISTS "IdxDiscountEventEndTime"
    ON "DiscountEvent" ( "EndTime" );


-- Creates three temp tables using snake_case like CSV and drops them afterward
CREATE TEMP TABLE staging_player_activity
(
    source_timestamp BIGINT,
    activity_date DATE,
    high_players INTEGER,
    low_players INTEGER
) ON COMMIT DROP;


CREATE TEMP TABLE staging_announcements
(
    build_id BIGINT,
    source_timestamp BIGINT,
    patch_title TEXT,

    patch INTEGER,
    hotfix INTEGER,
    free_content INTEGER,
    paid_content INTEGER,

    topic_ai INTEGER,
    topic_bugs INTEGER,
    topic_crashes INTEGER,
    topic_performance INTEGER,
    topic_balance INTEGER,
    topic_campaign INTEGER,
    topic_battles INTEGER,
    topic_dlc INTEGER,
    topic_price INTEGER,
    topic_content INTEGER,
    topic_multiplayer INTEGER,
    topic_ui INTEGER,
    topic_graphics INTEGER,
    topic_audio INTEGER,
    topic_mods INTEGER,
    topic_difficulty INTEGER,
    topic_update INTEGER,
    topic_developer INTEGER,
    topic_monetization INTEGER,
    topic_other INTEGER,

    topic_count INTEGER,
    has_topic INTEGER
) ON COMMIT DROP;


CREATE TEMP TABLE staging_discount_events
(
    start_time TIMESTAMP,
    final_price NUMERIC(6, 2),
    end_time TIMESTAMP,

    normal_discount INTEGER,
    seasonal_discount INTEGER,
    holiday_discount INTEGER,
    special_discount INTEGER,

    discount_title TEXT,
    source_url TEXT
) ON COMMIT DROP;


-- Copies and imports the CSV data retaining snake_case
COPY staging_player_activity
FROM '/data/player_counts_2024plus_collected.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE
);


COPY staging_announcements
FROM '/data/patch_hotfix_flc_dlc_2024plus_collected.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE
);


COPY staging_discount_events
FROM '/data/discount_events_2024plus_collected.csv'
WITH
(
    FORMAT CSV,
    HEADER TRUE
);


-- Clears existing records without affecting struct before inserting refreshed CSV data
TRUNCATE TABLE
    "PlayerActivity",
    "Announcement",
    "DiscountEvent"
RESTART IDENTITY;


-- Loading logic for inserting the 3 new tables
INSERT INTO "PlayerActivity"
(
    "ActivityDate",
    "HighPlayerCount",
    "LowPlayerCount"
)
SELECT
    activity_date,
    MAX ( high_players ),
    MIN ( low_players )
FROM staging_player_activity
GROUP BY activity_date
ORDER BY activity_date;


INSERT INTO "Announcement"
(
    "BuildId",
    "EventTime",
    "PatchTitle",

    "Patch",
    "Hotfix",
    "FreeContent",
    "PaidContent",

    "TopicAi",
    "TopicBugs",
    "TopicCrashes",
    "TopicPerformance",
    "TopicBalance",
    "TopicCampaign",
    "TopicBattles",
    "TopicDlc",
    "TopicContent",
    "TopicMultiplayer",
    "TopicUi",
    "TopicGraphics",
    "TopicAudio",
    "TopicMods",
    "TopicDifficulty",
    "TopicUpdate"
)
SELECT
    build_id,
    TO_TIMESTAMP ( source_timestamp ),
    patch_title,

    patch::BOOLEAN,
    hotfix::BOOLEAN,
    free_content::BOOLEAN,
    paid_content::BOOLEAN,

    topic_ai::BOOLEAN,
    topic_bugs::BOOLEAN,
    topic_crashes::BOOLEAN,
    topic_performance::BOOLEAN,
    topic_balance::BOOLEAN,
    topic_campaign::BOOLEAN,
    topic_battles::BOOLEAN,
    topic_dlc::BOOLEAN,
    topic_content::BOOLEAN,
    topic_multiplayer::BOOLEAN,
    topic_ui::BOOLEAN,
    topic_graphics::BOOLEAN,
    topic_audio::BOOLEAN,
    topic_mods::BOOLEAN,
    topic_difficulty::BOOLEAN,
    topic_update::BOOLEAN
FROM staging_announcements
ORDER BY source_timestamp;


INSERT INTO "DiscountEvent"
(
    "StartTime",
    "EndTime",
    "FinalPrice",

    "NormalDiscount",
    "SeasonalDiscount",
    "HolidayDiscount",
    "SpecialDiscount",

    "DiscountTitle",
    "SourceUrl"
)
SELECT
    start_time AT TIME ZONE 'UTC',
    end_time AT TIME ZONE 'UTC',
    final_price,

    normal_discount::BOOLEAN,
    seasonal_discount::BOOLEAN,
    holiday_discount::BOOLEAN,
    special_discount::BOOLEAN,

    discount_title,
    source_url
FROM staging_discount_events
WHERE
    normal_discount
    + seasonal_discount
    + holiday_discount
    + special_discount > 0
ORDER BY start_time;


COMMIT;