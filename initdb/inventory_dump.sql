--
-- PostgreSQL database dump
--

\restrict daFmt8R8o0Dtthv3e2DoLbpL6VXI9EvRTjjqxceYeIphsJtyhRvQrozZKrXkUeR

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bom; Type: TABLE; Schema: public; Owner: inventory_user
--

CREATE TABLE public.bom (
    id bigint NOT NULL,
    parent_item_id integer NOT NULL,
    component_item_id integer NOT NULL,
    notes text
);


ALTER TABLE public.bom OWNER TO inventory_user;

--
-- Name: bom_id_seq; Type: SEQUENCE; Schema: public; Owner: inventory_user
--

CREATE SEQUENCE public.bom_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bom_id_seq OWNER TO inventory_user;

--
-- Name: bom_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inventory_user
--

ALTER SEQUENCE public.bom_id_seq OWNED BY public.bom.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: inventory_user
--

CREATE TABLE public.items (
    id integer NOT NULL,
    part_number text NOT NULL,
    description text
);


ALTER TABLE public.items OWNER TO inventory_user;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: inventory_user
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_id_seq OWNER TO inventory_user;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: inventory_user
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: bom id; Type: DEFAULT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.bom ALTER COLUMN id SET DEFAULT nextval('public.bom_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Data for Name: bom; Type: TABLE DATA; Schema: public; Owner: inventory_user
--

COPY public.bom (id, parent_item_id, component_item_id, notes) FROM stdin;
1	3	4	basic component
2	3	5	basic component
3	3	9	basic component
4	10	11	basic component
5	10	12	basic component
6	10	13	basic component
7	10	14	basic component
8	1	12	basic component
9	15	1	basic component
10	1	16	basic component
11	1	17	basic component
12	1	18	basic component
13	1	19	basic component
14	1	20	basic component
15	1	21	basic component
16	1	22	basic component
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: inventory_user
--

COPY public.items (id, part_number, description) FROM stdin;
1	VMP1	Kontron CPU board
2	ROBO8777	Portwell CPU Board
3	LMN456	Foxconn Cooling Fan
4	RES-10K-0603	Resistor 10kΩ 0603
5	CAP-100UF-16V	Capacitor 100µF 16V
6	IC-ATMEGA328P	8-bit MCU ATmega328P
7	FAN-80MM-12V	80mm DC Fan 12V
8	HS-CPU-SMALL	Aluminum Heatsink small
9	ROTO-456	High Speed low voltage Rotor
10	MYM93LL/A	Apple Iphone 16 pro
11	GH82-31347A	Samsung OLED display
12	T8140	Apple APL1V07 A18 Pro Chip
13	rc-ip16pm	Apple Rear Camera Module
14	cp-ip16problk	USB Type-C Charging port
15	A197-94680	Trumpf TruMark Station 7000 laser marking machine
16	16C2850IM	EXAR Micro Controllers
17	48LC4M16A2	Micron Technology DRAM
18	ABT16245-A	Texas Instruments Integrated Circuit
19	ADM211	Analog Devices Interface integrated Circuit
20	CA91C142B-33CE	Tundra Universe Integrated Circuit
21	LX245B	Texas Instruments Octal Bus Transceivers
22	MD2200	M-Systems MD2200 Series DiskOnChip
\.


--
-- Name: bom_id_seq; Type: SEQUENCE SET; Schema: public; Owner: inventory_user
--

SELECT pg_catalog.setval('public.bom_id_seq', 16, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: inventory_user
--

SELECT pg_catalog.setval('public.items_id_seq', 22, true);


--
-- Name: bom bom_pkey; Type: CONSTRAINT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.bom
    ADD CONSTRAINT bom_pkey PRIMARY KEY (id);


--
-- Name: items items_part_number_key; Type: CONSTRAINT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_part_number_key UNIQUE (part_number);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: idx_bom_component; Type: INDEX; Schema: public; Owner: inventory_user
--

CREATE INDEX idx_bom_component ON public.bom USING btree (component_item_id);


--
-- Name: idx_bom_parent; Type: INDEX; Schema: public; Owner: inventory_user
--

CREATE INDEX idx_bom_parent ON public.bom USING btree (parent_item_id);


--
-- Name: idx_items_part_upper; Type: INDEX; Schema: public; Owner: inventory_user
--

CREATE INDEX idx_items_part_upper ON public.items USING btree (upper(part_number));


--
-- Name: bom bom_component_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.bom
    ADD CONSTRAINT bom_component_item_id_fkey FOREIGN KEY (component_item_id) REFERENCES public.items(id) ON DELETE RESTRICT;


--
-- Name: bom bom_parent_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: inventory_user
--

ALTER TABLE ONLY public.bom
    ADD CONSTRAINT bom_parent_item_id_fkey FOREIGN KEY (parent_item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict daFmt8R8o0Dtthv3e2DoLbpL6VXI9EvRTjjqxceYeIphsJtyhRvQrozZKrXkUeR

