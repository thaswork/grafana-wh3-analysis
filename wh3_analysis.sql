--
-- PostgreSQL database dump
--

\restrict LCFV3DL3BozdeKXpkiwqP8bwIkerjhNNoRcMBUOrRQQmrYR6L1bz9kxeHEISRkc

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.6 (Ubuntu 18.6-1.pgdg24.04+2)

-- Started on 2026-10-11 19:14:52 EDT

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
-- TOC entry 219 (class 1259 OID 16706)
-- Name: Build; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Build" (
    "BuildId" integer NOT NULL,
    "Timestamp" timestamp with time zone NOT NULL,
    "PatchTitle" text NOT NULL,
    "IsPatch" boolean,
    "IsHotfix" boolean,
    "IsFreeContent" boolean,
    "IsPaidContent" boolean,
    "IsTopicAi" boolean,
    "IsTopicBugs" boolean,
    "IsTopicCrashes" boolean,
    "IsTopicPerformance" boolean,
    "IsTopicBalance" boolean,
    "IsTopicCampaign" boolean,
    "IsTopicBattles" boolean,
    "IsTopicDlc" boolean,
    "IsTopicPrice" boolean,
    "IsTopicContent" boolean,
    "IsTopicMultiplayer" boolean,
    "IsTopicUi" boolean,
    "IsTopicGraphics" boolean,
    "IsTopicAudio" boolean,
    "IsTopicMods" boolean,
    "IsTopicDifficulty" boolean,
    "IsTopicUpdate" boolean,
    "IsTopicDeveloper" boolean,
    "IsTopicMonetization" boolean,
    "IsTopicOther" boolean
);


ALTER TABLE public."Build" OWNER TO wh3_user;

--
-- TOC entry 221 (class 1259 OID 16744)
-- Name: Discount; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Discount" (
    "DiscountId" integer NOT NULL,
    "DateTime" timestamp with time zone NOT NULL,
    "FinalPrice" numeric(19,4) NOT NULL,
    "DateTimeEnd" timestamp with time zone,
    "IsNormalDiscount" boolean,
    "IsSeasonalDiscount" boolean,
    "IsHolidayDiscount" boolean,
    "IsSpecialDiscount" boolean,
    "DiscountTitle" text NOT NULL
);


ALTER TABLE public."Discount" OWNER TO wh3_user;

--
-- TOC entry 220 (class 1259 OID 16743)
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
-- TOC entry 222 (class 1259 OID 16762)
-- Name: PlayerActivity; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."PlayerActivity" (
    "Date" date NOT NULL,
    "High" integer,
    "Low" integer
);


ALTER TABLE public."PlayerActivity" OWNER TO wh3_user;

--
-- TOC entry 223 (class 1259 OID 16771)
-- Name: Review; Type: TABLE; Schema: public; Owner: wh3_user
--

CREATE TABLE public."Review" (
    "ReviewId" integer NOT NULL,
    "Language" text NOT NULL,
    "Text" text,
    "TimestampUpdated" timestamp with time zone NOT NULL,
    "IsVotedUp" boolean,
    "IsTopicAi" boolean,
    "IsTopicBugs" boolean,
    "IsTopicCrashes" boolean,
    "IsTopicPerformance" boolean,
    "IsTopicBalance" boolean,
    "IsTopicCampaign" boolean,
    "IsTopicBattles" boolean,
    "IsTopicDlc" boolean,
    "IsTopicPrice" boolean,
    "IsTopicContent" boolean,
    "IsTopicMultiplayer" boolean,
    "IsTopicUi" boolean,
    "IsTopicGraphics" boolean,
    "IsTopicAudio" boolean,
    "IsTopicMods" boolean,
    "IsTopicDifficulty" boolean,
    "IsTopicUpdate" boolean,
    "IsTopicDeveloper" boolean,
    "IsTopicMonetization" boolean,
    "IsTopicOther" boolean
);


ALTER TABLE public."Review" OWNER TO wh3_user;

--
-- TOC entry 3303 (class 2606 OID 17958)
-- Name: Build Build_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Build"
    ADD CONSTRAINT "Build_pkey" PRIMARY KEY ("BuildId");


--
-- TOC entry 3306 (class 2606 OID 17408)
-- Name: Discount Discount_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT "Discount_pkey" PRIMARY KEY ("DiscountId");


--
-- TOC entry 3310 (class 2606 OID 16770)
-- Name: PlayerActivity PlayerActivity_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."PlayerActivity"
    ADD CONSTRAINT "PlayerActivity_pkey" PRIMARY KEY ("Date");


--
-- TOC entry 3313 (class 2606 OID 17953)
-- Name: Review Review_pkey; Type: CONSTRAINT; Schema: public; Owner: wh3_user
--

ALTER TABLE ONLY public."Review"
    ADD CONSTRAINT "Review_pkey" PRIMARY KEY ("ReviewId");


--
-- TOC entry 3304 (class 1259 OID 16818)
-- Name: IdxBuildTimestamp; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxBuildTimestamp" ON public."Build" USING btree ("Timestamp");


--
-- TOC entry 3307 (class 1259 OID 16819)
-- Name: IdxDiscountDateTime; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxDiscountDateTime" ON public."Discount" USING btree ("DateTime");


--
-- TOC entry 3308 (class 1259 OID 16820)
-- Name: IdxDiscountDateTimeEnd; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxDiscountDateTimeEnd" ON public."Discount" USING btree ("DateTimeEnd");


--
-- TOC entry 3311 (class 1259 OID 16822)
-- Name: IdxReviewTimestampUpdated; Type: INDEX; Schema: public; Owner: wh3_user
--

CREATE INDEX "IdxReviewTimestampUpdated" ON public."Review" USING btree ("TimestampUpdated");


--
-- TOC entry 3466 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO wh3_user;
GRANT USAGE ON SCHEMA public TO grafana_reader;


--
-- TOC entry 3467 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE "Build"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Build" TO grafana_reader;


--
-- TOC entry 3468 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE "Discount"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Discount" TO grafana_reader;


--
-- TOC entry 3469 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE "PlayerActivity"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."PlayerActivity" TO grafana_reader;


--
-- TOC entry 3470 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE "Review"; Type: ACL; Schema: public; Owner: wh3_user
--

GRANT SELECT ON TABLE public."Review" TO grafana_reader;


--
-- TOC entry 2064 (class 826 OID 16824)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: wh3_user
--

ALTER DEFAULT PRIVILEGES FOR ROLE wh3_user IN SCHEMA public GRANT SELECT ON TABLES TO grafana_reader;


-- Completed on 2026-10-11 19:14:52 EDT

--
-- PostgreSQL database dump complete
--

\unrestrict LCFV3DL3BozdeKXpkiwqP8bwIkerjhNNoRcMBUOrRQQmrYR6L1bz9kxeHEISRkc

