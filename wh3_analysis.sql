-- Run with psql as wh3_user, connected initially to postgres.
-- Recreates wh3_analysis and deletes any existing data.
-- Database version 18.6 (Debian 18.6-1.pgdg13+2)

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'grafana_reader') THEN
        CREATE ROLE grafana_reader LOGIN;
    END IF;
END
$$;

ALTER ROLE grafana_reader WITH LOGIN PASSWORD 'grafana_password';

DROP DATABASE IF EXISTS wh3_analysis WITH (FORCE);
CREATE DATABASE wh3_analysis OWNER wh3_user;
\connect wh3_analysis

CREATE TABLE public."Build" (
    "BuildId" integer NOT NULL,
    "Timestamp" timestamp with time zone NOT NULL,
    "PatchTitle" text NOT NULL,
    "IsPatch" boolean NOT NULL,
    "IsHotfix" boolean NOT NULL,
    "IsFreeContent" boolean NOT NULL,
    "IsPaidContent" boolean NOT NULL,
    "IsTopicAi" boolean NOT NULL,
    "IsTopicBugs" boolean NOT NULL,
    "IsTopicCrashes" boolean NOT NULL,
    "IsTopicPerformance" boolean NOT NULL,
    "IsTopicBalance" boolean NOT NULL,
    "IsTopicCampaign" boolean NOT NULL,
    "IsTopicBattles" boolean NOT NULL,
    "IsTopicDlc" boolean NOT NULL,
    "IsTopicPrice" boolean NOT NULL,
    "IsTopicContent" boolean NOT NULL,
    "IsTopicMultiplayer" boolean NOT NULL,
    "IsTopicUi" boolean NOT NULL,
    "IsTopicGraphics" boolean NOT NULL,
    "IsTopicAudio" boolean NOT NULL,
    "IsTopicMods" boolean NOT NULL,
    "IsTopicDifficulty" boolean NOT NULL,
    "IsTopicUpdate" boolean NOT NULL,
    "IsTopicDeveloper" boolean NOT NULL,
    "IsTopicMonetization" boolean NOT NULL,
    "IsTopicOther" boolean NOT NULL
);

CREATE TABLE public."Discount" (
    "DateTime" timestamp with time zone NOT NULL,
    "FinalPrice" numeric(19,4) NOT NULL,
    "DateTimeEnd" timestamp with time zone,
    "IsNormalDiscount" boolean NOT NULL,
    "IsSeasonalDiscount" boolean NOT NULL,
    "IsHolidayDiscount" boolean NOT NULL,
    "IsSpecialDiscount" boolean NOT NULL,
    "DiscountTitle" text NOT NULL
);

CREATE TABLE public."PlayerActivity" (
    "Date" date NOT NULL,
    "High" integer NOT NULL,
    "Low" integer NOT NULL
);

CREATE TABLE public."Review" (
    "ReviewId" integer NOT NULL,
    "Language" text NOT NULL,
    "Text" text,
    "TimestampUpdated" timestamp with time zone NOT NULL,
    "IsVotedUp" boolean NOT NULL,
    "IsTopicAi" boolean NOT NULL,
    "IsTopicBugs" boolean NOT NULL,
    "IsTopicCrashes" boolean NOT NULL,
    "IsTopicPerformance" boolean NOT NULL,
    "IsTopicBalance" boolean NOT NULL,
    "IsTopicCampaign" boolean NOT NULL,
    "IsTopicBattles" boolean NOT NULL,
    "IsTopicDlc" boolean NOT NULL,
    "IsTopicPrice" boolean NOT NULL,
    "IsTopicContent" boolean NOT NULL,
    "IsTopicMultiplayer" boolean NOT NULL,
    "IsTopicUi" boolean NOT NULL,
    "IsTopicGraphics" boolean NOT NULL,
    "IsTopicAudio" boolean NOT NULL,
    "IsTopicMods" boolean NOT NULL,
    "IsTopicDifficulty" boolean NOT NULL,
    "IsTopicUpdate" boolean NOT NULL,
    "IsTopicDeveloper" boolean NOT NULL,
    "IsTopicMonetization" boolean NOT NULL,
    "IsTopicOther" boolean NOT NULL
);

ALTER TABLE ONLY public."Build"
    ADD CONSTRAINT "Build_pkey" PRIMARY KEY ("BuildId");
ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT "Discount_pkey" PRIMARY KEY ("DateTime");
ALTER TABLE ONLY public."PlayerActivity"
    ADD CONSTRAINT "PlayerActivity_pkey" PRIMARY KEY ("Date");
ALTER TABLE ONLY public."Review"
    ADD CONSTRAINT "Review_pkey" PRIMARY KEY ("ReviewId");

CREATE INDEX "IdxBuildTimestamp" ON public."Build" USING btree ("Timestamp");
CREATE INDEX "IdxDiscountDateTime" ON public."Discount" USING btree ("DateTime");
CREATE INDEX "IdxDiscountDateTimeEnd" ON public."Discount" USING btree ("DateTimeEnd");
CREATE INDEX "IdxReviewTimestampUpdated" ON public."Review" USING btree ("TimestampUpdated");

GRANT USAGE ON SCHEMA public TO grafana_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE wh3_user IN SCHEMA public
    GRANT SELECT ON TABLES TO grafana_reader;
