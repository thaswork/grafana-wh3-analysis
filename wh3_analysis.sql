--
-- PostgreSQL database dump
--

\restrict DZa34H83D2cMJdVq8SX0mRH6aw98ABiHmTEDUZap9gczdGvvjcihxr1r046uIXP

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-1.pgdg24.04+2)

-- Started on 2026-10-11 15:17:15 EDT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 16706)
-- Name: Announcement; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Announcement" (
    "AnnouncementId" bigint NOT NULL,
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
    "TopicOther" boolean NOT NULL
);


ALTER TABLE public."Announcement" OWNER TO wh3_user;

--
-- TOC entry 219 (class 1259 OID 16705)
-- Name: Announcement_AnnouncementId_seq; Type: SEQUENCE; Schema: public; Owner: wh3_user
--

ALTER TABLE public."Announcement" ALTER COLUMN "AnnouncementId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Announcement_AnnouncementId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 222 (class 1259 OID 16744)
-- Name: Discount; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Discount" (
    "DiscountId" bigint NOT NULL,
    "DateTime" timestamp with time zone NOT NULL,
    "FinalPrice" numeric(6,2) NOT NULL,
    "DateTimeEnd" timestamp with time zone,
    "NormalDiscount" boolean NOT NULL,
    "SeasonalDiscount" boolean NOT NULL,
    "HolidayDiscount" boolean NOT NULL,
    "SpecialDiscount" boolean NOT NULL,
    "DiscountTitle" text NOT NULL,
    CONSTRAINT "DiscountPrice" CHECK (("FinalPrice" >= (0)::numeric)),
    CONSTRAINT "DiscountSingleType" CHECK (((((("NormalDiscount")::integer + ("SeasonalDiscount")::integer) + ("HolidayDiscount")::integer) + ("SpecialDiscount")::integer) = 1)),
    CONSTRAINT "DiscountTimeRange" CHECK ((("DateTimeEnd" IS NULL) OR ("DateTimeEnd" > "DateTime")))
);


ALTER TABLE public."Discount" OWNER TO wh3_user;

--
-- TOC entry 221 (class 1259 OID 16743)
-- Name: Discount_DiscountId_seq; Type: SEQUENCE; Schema: public; Owner: wh3_user
--

ALTER TABLE public."Discount" ALTER COLUMN "DiscountId" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."Discount_DiscountId_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 16762)
-- Name: PlayerActivity; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."PlayerActivity" (
    "Date" date NOT NULL,
    "High" integer,
    "Low" integer,
    CONSTRAINT "PlayerActivityHighLow" CHECK ((("High" IS NULL) OR ("Low" IS NULL) OR ("High" >= "Low"))),
    CONSTRAINT "PlayerActivityNonnegative" CHECK (((("High" IS NULL) OR ("High" >= 0)) AND (("Low" IS NULL) OR ("Low" >= 0))))
);


ALTER TABLE public."PlayerActivity" OWNER TO wh3_user;

--
-- TOC entry 224 (class 1259 OID 16771)
-- Name: Review; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Review" (
    "RecommendationId" bigint NOT NULL,
    "Language" text NOT NULL,
    "Review" text,
    "TimestampUpdated" timestamp with time zone NOT NULL,
    "VotedUp" boolean NOT NULL,
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
    "TopicOther" boolean NOT NULL
);


ALTER TABLE public."Review" OWNER TO wh3_user;

--
-- TOC entry 3309 (class 2606 OID 16742)
-- Name: Announcement Announcement_BuildId_key; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Announcement"
    ADD CONSTRAINT "Announcement_BuildId_key" UNIQUE ("BuildId");


--
-- TOC entry 3311 (class 2606 OID 16740)
-- Name: Announcement Announcement_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Announcement"
    ADD CONSTRAINT "Announcement_pkey" PRIMARY KEY ("AnnouncementId");


--
-- TOC entry 3314 (class 2606 OID 16761)
-- Name: Discount Discount_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT "Discount_pkey" PRIMARY KEY ("DiscountId");


--
-- TOC entry 3318 (class 2606 OID 16770)
-- Name: PlayerActivity PlayerActivity_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."PlayerActivity"
    ADD CONSTRAINT "PlayerActivity_pkey" PRIMARY KEY ("Date");


--
-- TOC entry 3321 (class 2606 OID 16817)
-- Name: Review Review_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Review"
    ADD CONSTRAINT "Review_pkey" PRIMARY KEY ("RecommendationId");


--
-- TOC entry 3312 (class 1259 OID 16818)
-- Name: IdxAnnouncementTimestamp; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxAnnouncementTimestamp" ON public."Announcement" USING btree ("Timestamp");


--
-- TOC entry 3315 (class 1259 OID 16819)
-- Name: IdxDiscountDateTime; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxDiscountDateTime" ON public."Discount" USING btree ("DateTime");


--
-- TOC entry 3316 (class 1259 OID 16820)
-- Name: IdxDiscountDateTimeEnd; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxDiscountDateTimeEnd" ON public."Discount" USING btree ("DateTimeEnd");


--
-- TOC entry 3319 (class 1259 OID 16822)
-- Name: IdxReviewTimestampUpdated; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxReviewTimestampUpdated" ON public."Review" USING btree ("TimestampUpdated");


--
-- TOC entry 3474 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO wh3_user;
GRANT USAGE ON SCHEMA public TO grafana_reader;


--
-- TOC entry 3475 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE "Announcement"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Announcement" TO grafana_reader;


--
-- TOC entry 3476 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE "Discount"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Discount" TO grafana_reader;


--
-- TOC entry 3477 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE "PlayerActivity"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."PlayerActivity" TO grafana_reader;


--
-- TOC entry 3478 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE "Review"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Review" TO grafana_reader;


--
-- TOC entry 2065 (class 826 OID 16824)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: wh3_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE wh3_user IN SCHEMA public GRANT SELECT ON TABLES TO grafana_reader;


-- Completed on 2026-10-11 15:17:15 EDT

--
-- PostgreSQL database dump complete
--

\unrestrict DZa34H83D2cMJdVq8SX0mRH6aw98ABiHmTEDUZap9gczdGvvjcihxr1r046uIXP

