--
-- PostgreSQL database dump
--

\restrict NaKzr4cvdvFTgdrgqTWN9D0jfDCyz2O4y84lhoiD1EpnH52pYmaYevEBLRMAO4e

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-09-28 23:55:33

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

--
-- TOC entry 230 (class 1255 OID 16630)
-- Name: fn_get_regional_sales(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_get_regional_sales(p_region character varying) RETURNS TABLE(city character varying, total_sales numeric, total_profit numeric, orders_count bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.city,
        SUM(f.sales) AS total_sales,
        SUM(f.profit) AS total_profit,
        COUNT(DISTINCT f.orderid) AS orders_count
    FROM public.fact_sales f
    JOIN public.dim_location l ON f.postalcode = l.postalcode
    WHERE LOWER(l.region) = LOWER(p_region)
    GROUP BY l.city
    ORDER BY total_sales DESC;
END;
$$;


ALTER FUNCTION public.fn_get_regional_sales(p_region character varying) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16627)
-- Name: sp_get_regional_performance(character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.sp_get_regional_performance(IN p_region character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_orders   BIGINT;
    v_total_sales    NUMERIC;
    v_total_profit   NUMERIC;
    v_avg_discount   NUMERIC;
BEGIN
    SELECT 
        COUNT(DISTINCT f.orderid),
        SUM(f.sales),
        SUM(f.profit),
        AVG(f.discount)
    INTO 
        v_total_orders,
        v_total_sales,
        v_total_profit,
        v_avg_discount
    FROM public.fact_sales f
    JOIN public.dim_location l ON f.postalcode = l.postalcode
    WHERE LOWER(l.region) = LOWER(p_region);

    IF v_total_orders IS NULL OR v_total_orders = 0 THEN
        RAISE NOTICE 'No data found for region: %', p_region;
    ELSE
        RAISE NOTICE 'Region: % | Orders: % | Sales: % | Profit: % | Avg Discount: %',
            p_region, v_total_orders, ROUND(v_total_sales, 2),
            ROUND(v_total_profit, 2), ROUND(v_avg_discount, 4);
    END IF;
END;
$$;


ALTER PROCEDURE public.sp_get_regional_performance(IN p_region character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16539)
-- Name: dim_customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_customer (
    customerid character varying(50) NOT NULL,
    customername character varying(100) NOT NULL,
    segment character varying(50)
);


ALTER TABLE public.dim_customer OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16559)
-- Name: dim_date; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_date (
    orderdate date NOT NULL,
    orderyear integer,
    ordermonth integer,
    orderquarter integer
);


ALTER TABLE public.dim_date OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16553)
-- Name: dim_location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_location (
    postalcode character varying(20) NOT NULL,
    city character varying(100),
    state character varying(100),
    region character varying(50),
    country character varying(50)
);


ALTER TABLE public.dim_location OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16546)
-- Name: dim_product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_product (
    product_id character varying(50) CONSTRAINT dim_product_productid_not_null NOT NULL,
    product_name character varying(255) CONSTRAINT dim_product_productname_not_null NOT NULL,
    category character varying(50),
    sub_category character varying(50)
);


ALTER TABLE public.dim_product OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16610)
-- Name: dim_ship_mode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_ship_mode (
    ship_mode_key integer NOT NULL,
    ship_mode character varying(50) NOT NULL
);


ALTER TABLE public.dim_ship_mode OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16609)
-- Name: dim_ship_mode_ship_mode_key_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.dim_ship_mode ALTER COLUMN ship_mode_key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.dim_ship_mode_ship_mode_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 16566)
-- Name: fact_sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fact_sales (
    rowid integer NOT NULL,
    orderid character varying(50) NOT NULL,
    customerid character varying(50),
    productid character varying(50),
    postalcode character varying(20),
    orderdate date,
    sales numeric(10,2),
    quantity integer,
    discount numeric(4,2),
    profit numeric(10,2),
    ship_mode_key integer,
    CONSTRAINT fact_sales_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT fact_sales_sales_check CHECK ((sales >= (0)::numeric))
);


ALTER TABLE public.fact_sales OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16565)
-- Name: fact_sales_rowid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fact_sales_rowid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fact_sales_rowid_seq OWNER TO postgres;

--
-- TOC entry 5082 (class 0 OID 0)
-- Dependencies: 223
-- Name: fact_sales_rowid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fact_sales_rowid_seq OWNED BY public.fact_sales.rowid;


--
-- TOC entry 225 (class 1259 OID 16597)
-- Name: staging_superstore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staging_superstore (
    row_id text,
    order_id text,
    order_date text,
    ship_date text,
    ship_mode text,
    customer_id text,
    customer_name text,
    segment text,
    country text,
    city text,
    state text,
    postal_code text,
    region text,
    product_id text,
    category text,
    sub_category text,
    product_name text,
    sales text,
    quantity text,
    discount text,
    profit text
);


ALTER TABLE public.staging_superstore OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16693)
-- Name: stg_superstore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stg_superstore (
    row_id text,
    order_id text,
    order_date text,
    ship_date text,
    ship_mode text,
    customer_id text,
    customer_name text,
    segment text,
    country text,
    city text,
    state text,
    postal_code text,
    region text,
    product_id text,
    category text,
    sub_category text,
    product_name text,
    sales text,
    quantity text,
    discount text,
    profit text
);


ALTER TABLE public.stg_superstore OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16620)
-- Name: vw_monthly_kpi_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_monthly_kpi_summary AS
 SELECT d.orderyear,
    d.ordermonth,
    count(DISTINCT f.orderid) AS total_orders,
    count(DISTINCT f.customerid) AS unique_customers,
    sum(f.sales) AS total_sales,
    sum(f.profit) AS total_profit,
    round(((sum(f.profit) / NULLIF(sum(f.sales), (0)::numeric)) * (100)::numeric), 2) AS profit_margin_pct
   FROM (public.fact_sales f
     JOIN public.dim_date d ON ((f.orderdate = d.orderdate)))
  GROUP BY d.orderyear, d.ordermonth;


ALTER VIEW public.vw_monthly_kpi_summary OWNER TO postgres;

--
-- TOC entry 4891 (class 2604 OID 16569)
-- Name: fact_sales rowid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales ALTER COLUMN rowid SET DEFAULT nextval('public.fact_sales_rowid_seq'::regclass);


--
-- TOC entry 5067 (class 0 OID 16539)
-- Dependencies: 219
-- Data for Name: dim_customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_customer (customerid, customername, segment) FROM stdin;
JC-15775	John Castell	Consumer
DR-12940	Daniel Raglin	Home Office
EB-13840	Ellis Ballard	Corporate
TS-21340	Toby Swindell	Consumer
XP-21865	Xylona Preis	Consumer
CK-12205	Chloris Kastensmidt	Consumer
VF-21715	Vicky Freymann	Home Office
JS-15595	Jill Stevenson	Corporate
BP-11230	Benjamin Patterson	Consumer
BN-11515	Bradley Nguyen	Consumer
RK-19300	Ralph Kennedy	Consumer
MS-17770	Maxwell Schwartz	Consumer
RD-19930	Russell D'Ascenzo	Consumer
MD-17350	Maribeth Dona	Consumer
YC-21895	Yoseph Carroll	Corporate
TB-21355	Todd Boyes	Corporate
FC-14335	Fred Chung	Corporate
AC-10450	Amy Cox	Consumer
KL-16645	Ken Lonsdale	Consumer
MG-17695	Maureen Gnade	Consumer
NR-18550	Nick Radford	Consumer
BM-11140	Becky Martin	Consumer
RP-19390	Resi Pölking	Consumer
JR-16210	Justin Ritter	Corporate
LD-17005	Lisa DeCherney	Consumer
AS-10090	Adam Shillingsburg	Consumer
DB-13660	Duane Benoit	Consumer
ES-14020	Erica Smith	Consumer
CH-12070	Cathy Hwang	Home Office
GM-14455	Gary Mitchum	Home Office
SG-20605	Speros Goranitis	Consumer
KD-16495	Keith Dawkins	Corporate
DW-13480	Dianna Wilson	Home Office
JF-15415	Jennifer Ferguson	Consumer
FG-14260	Frank Gastineau	Home Office
MC-17425	Mark Cousins	Corporate
DW-13195	David Wiener	Corporate
PR-18880	Patrick Ryan	Consumer
KE-16420	Katrina Edelman	Corporate
EM-14140	Eugene Moren	Home Office
SS-20140	Saphhira Shifley	Corporate
SV-20935	Susan Vittorini	Consumer
HW-14935	Helen Wasserman	Corporate
DM-13015	Darrin Martin	Consumer
LB-16735	Larry Blacks	Consumer
CL-12700	Craig Leslie	Home Office
TD-20995	Tamara Dahlen	Consumer
AC-10420	Alyssa Crouse	Corporate
PJ-18835	Patrick Jones	Corporate
SG-20890	Susan Gilcrest	Corporate
BC-11125	Becky Castell	Home Office
KH-16510	Keith Herrera	Consumer
BD-11620	Brian DeCherney	Consumer
SM-20005	Sally Matthias	Consumer
JE-15715	Joe Elijah	Consumer
CS-11845	Cari Sayre	Corporate
RB-19330	Randy Bradley	Consumer
AB-10255	Alejandro Ballentine	Home Office
CS-12400	Christopher Schild	Home Office
SS-20875	Sung Shariari	Consumer
NM-18445	Nathan Mautz	Home Office
NC-18535	Nick Crebassa	Corporate
SC-20230	Scot Coram	Corporate
CA-12055	Cathy Armstrong	Home Office
PF-19120	Peter Fuller	Consumer
SC-20380	Shahid Collister	Consumer
BF-11170	Ben Ferrer	Home Office
NZ-18565	Nick Zandusky	Home Office
RD-19480	Rick Duston	Consumer
AB-10165	Alan Barnes	Consumer
PO-18865	Patrick O'Donnell	Consumer
FH-14350	Fred Harton	Consumer
EB-13870	Emily Burns	Consumer
AC-10615	Ann Chong	Corporate
MH-17440	Mark Haberlin	Corporate
LS-16945	Linda Southworth	Corporate
CV-12295	Christina VanderZanden	Consumer
TR-21325	Toby Ritter	Consumer
JL-15850	John Lucas	Consumer
SG-20080	Sandra Glassco	Consumer
BP-11290	Beth Paige	Consumer
TB-21175	Thomas Boland	Corporate
SM-20320	Sean Miller	Home Office
GH-14410	Gary Hansen	Home Office
LC-16930	Linda Cazamias	Corporate
IM-15070	Irene Maddox	Consumer
JL-15505	Jeremy Lonsdale	Consumer
TS-21205	Thomas Seio	Corporate
SL-20155	Sara Luxemburg	Home Office
JC-16105	Julie Creighton	Corporate
BE-11335	Bill Eplett	Home Office
MS-17980	Michael Stewart	Corporate
RA-19915	Russell Applegate	Consumer
ML-18040	Michelle Lonsdale	Corporate
LS-17245	Lynn Smith	Consumer
RM-19375	Raymond Messe	Consumer
CS-12175	Charles Sheldon	Corporate
ME-17320	Maria Etezadi	Home Office
SW-20350	Sean Wendt	Home Office
PF-19165	Philip Fox	Consumer
RR-19315	Ralph Ritter	Consumer
EJ-13720	Ed Jacobs	Consumer
JM-15250	Janet Martin	Consumer
MC-17575	Matt Collins	Consumer
SB-20185	Sarah Brown	Consumer
HL-15040	Hunter Lopez	Consumer
CC-12610	Corey Catlett	Corporate
RD-19900	Ruben Dartt	Consumer
CC-12430	Chuck Clark	Home Office
EC-14050	Erin Creighton	Consumer
AC-10660	Anna Chung	Consumer
NF-18385	Natalie Fritzler	Consumer
DS-13180	David Smith	Corporate
ED-13885	Emily Ducich	Home Office
LB-16795	Laurel Beltran	Home Office
SW-20275	Scott Williamson	Consumer
LW-16825	Laurel Workman	Corporate
ER-13855	Elpida Rittenbach	Corporate
CK-12595	Clytie Kelty	Consumer
TH-21550	Tracy Hopkins	Home Office
TS-21430	Tom Stivers	Corporate
VT-21700	Valerie Takahito	Home Office
CR-12580	Clay Rozendal	Home Office
EN-13780	Edward Nazzal	Consumer
GZ-14470	Gary Zandusky	Consumer
BS-11365	Bill Shonely	Corporate
CS-12130	Chad Sievert	Consumer
DB-13210	Dean Braden	Consumer
KW-16570	Kelly Williams	Consumer
GT-14755	Guy Thornton	Consumer
MW-18220	Mitch Webber	Consumer
JL-15235	Janet Lee	Consumer
PS-18760	Pamela Stobb	Consumer
RC-19960	Ryan Crowe	Consumer
KN-16450	Kean Nguyen	Corporate
PV-18985	Paul Van Hugh	Home Office
RS-19870	Roy Skaria	Home Office
RA-19285	Ralph Arnett	Consumer
MC-17845	Michael Chen	Consumer
JP-15520	Jeremy Pistek	Consumer
MP-17470	Mark Packer	Home Office
EP-13915	Emily Phan	Consumer
HG-14965	Henry Goldwyn	Corporate
RE-19450	Richard Eichhorn	Consumer
LC-17050	Liz Carlisle	Consumer
RF-19345	Randy Ferguson	Corporate
BB-11545	Brenda Bowman	Corporate
MC-17635	Matthew Clasen	Corporate
EH-14125	Eugene Hildebrand	Home Office
DB-12970	Darren Budd	Corporate
DD-13570	Dorothy Dickinson	Consumer
AB-10600	Ann Blume	Corporate
VM-21685	Valerie Mitchum	Home Office
BO-11350	Bill Overfelt	Corporate
CC-12220	Chris Cortes	Consumer
FO-14305	Frank Olsen	Consumer
KT-16465	Kean Takahito	Consumer
DB-13405	Denny Blanton	Consumer
JP-16135	Julie Prescott	Home Office
MM-17920	Michael Moore	Consumer
PO-18850	Patrick O'Brill	Consumer
DP-13390	Dennis Pardue	Home Office
AF-10870	Art Ferguson	Consumer
GH-14485	Gene Hale	Corporate
MH-17785	Maya Herman	Corporate
SR-20425	Sharelle Roach	Home Office
HZ-14950	Henia Zydlo	Consumer
JD-16060	Julia Dunbar	Consumer
NC-18340	Nat Carroll	Consumer
BF-11005	Barry Franz	Home Office
AW-10840	Anthony Witt	Consumer
JB-16000	Joy Bell-	Consumer
NB-18655	Nona Balk	Corporate
VM-21835	Vivian Mathis	Consumer
TC-21295	Toby Carlisle	Consumer
TB-21520	Tracy Blumstein	Consumer
MC-17590	Matt Collister	Corporate
JD-16015	Joy Daniels	Consumer
Dl-13600	Dorris liebe	Corporate
MF-18250	Monica Federle	Corporate
DB-13060	Dave Brooks	Consumer
KC-16540	Kelly Collister	Consumer
MH-17620	Matt Hagelstein	Corporate
MN-17935	Michael Nguyen	Consumer
AH-10195	Alan Haines	Corporate
ON-18715	Odella Nelson	Corporate
DL-12925	Daniel Lacy	Consumer
JE-16165	Justin Ellison	Corporate
MB-18085	Mick Brown	Consumer
MO-17800	Meg O'Connel	Home Office
AH-10210	Alan Hwang	Consumer
HG-15025	Hunter Glantz	Consumer
CM-12160	Charles McCrossin	Consumer
FM-14290	Frank Merwin	Home Office
GM-14500	Gene McClure	Consumer
WB-21850	William Brown	Consumer
SJ-20125	Sanjit Jacobs	Home Office
SC-20050	Sample Company A	Home Office
MV-17485	Mark Van Huff	Consumer
TB-21595	Troy Blackwell	Consumer
CC-12475	Cindy Chapman	Consumer
AB-10105	Adrian Barton	Consumer
JS-15940	Joni Sundaresam	Home Office
AG-10900	Arthur Gainer	Consumer
BM-11785	Bryan Mills	Consumer
VW-21775	Victoria Wilson	Corporate
BB-10990	Barry Blumstein	Corporate
BD-11770	Bryan Davis	Consumer
DM-12955	Dario Medina	Corporate
VP-21760	Victoria Pisteka	Corporate
RS-19765	Roland Schwarz	Corporate
MY-17380	Maribeth Yedwab	Corporate
DK-13090	Dave Kipp	Consumer
PB-19210	Phillip Breyer	Corporate
CL-12565	Clay Ludtke	Consumer
JA-15970	Joseph Airdo	Consumer
VG-21805	Vivek Grady	Corporate
BW-11200	Ben Wallace	Consumer
MG-17650	Matthew Grinstein	Home Office
BK-11260	Berenike Kampe	Consumer
BF-11215	Benjamin Farhat	Home Office
BP-11185	Ben Peterman	Corporate
JL-15130	Jack Lebron	Consumer
TP-21130	Theone Pippenger	Consumer
SV-20365	Seth Vernon	Consumer
DP-13105	Dave Poirier	Corporate
DM-13525	Don Miller	Corporate
QJ-19255	Quincy Jones	Corporate
LP-17095	Liz Preis	Consumer
TM-21010	Tamara Manning	Consumer
SJ-20215	Sarah Jordon	Consumer
MA-17995	Michelle Arnett	Home Office
JG-15310	Jason Gross	Corporate
KM-16225	Kalyca Meade	Corporate
DB-13270	Deborah Brumfield	Home Office
LA-16780	Laura Armstrong	Corporate
CA-11965	Carol Adams	Corporate
RB-19795	Ross Baird	Home Office
EB-13705	Ed Braxton	Corporate
CM-11815	Candace McMahon	Corporate
MO-17950	Michael Oakman	Consumer
TT-21460	Tonja Turnell	Home Office
PS-18970	Paul Stevenson	Home Office
BG-11035	Barry Gonzalez	Consumer
HD-14785	Harold Dahlen	Home Office
EH-13945	Eric Hoffmann	Consumer
PW-19030	Pauline Webber	Corporate
JH-15910	Jonathan Howell	Consumer
LH-17155	Logan Haushalter	Consumer
LH-16900	Lena Hernandez	Consumer
BS-11590	Brendan Sweed	Corporate
EB-13930	Eric Barreto	Consumer
NH-18610	Nicole Hansen	Corporate
BT-11440	Bobby Trafton	Consumer
MK-17905	Michael Kennedy	Corporate
CA-12775	Cynthia Arntzen	Consumer
BP-11095	Bart Pistole	Corporate
TB-21625	Trudy Brown	Consumer
DK-13150	David Kendrick	Corporate
SP-20620	Stefania Perrino	Corporate
NG-18355	Nat Gilpin	Corporate
CW-11905	Carl Weiss	Home Office
NS-18640	Noel Staavos	Corporate
SZ-20035	Sam Zeldin	Home Office
SF-20065	Sandra Flanagan	Consumer
KB-16240	Karen Bern	Corporate
DL-12865	Dan Lawera	Consumer
LC-16870	Lena Cacioppo	Consumer
RR-19525	Rick Reed	Corporate
CR-12730	Craig Reiter	Consumer
KN-16390	Katherine Nockton	Corporate
SF-20200	Sarah Foster	Consumer
SC-20305	Sean Christensen	Consumer
TA-21385	Tom Ashbrook	Home Office
HF-14995	Herbert Flentye	Consumer
SC-20095	Sanjit Chand	Consumer
CS-11950	Carlos Soltero	Consumer
Dp-13240	Dean percer	Home Office
SB-20290	Sean Braxton	Corporate
MY-18295	Muhammed Yedwab	Corporate
RB-19360	Raymond Buch	Consumer
AA-10375	Allen Armold	Consumer
MH-18115	Mick Hernandez	Home Office
KW-16435	Katrina Willman	Consumer
RA-19945	Ryan Akin	Consumer
KD-16345	Katherine Ducich	Consumer
PG-18895	Paul Gonzalez	Consumer
MJ-17740	Max Jones	Consumer
CS-11860	Cari Schnelling	Consumer
HP-14815	Harold Pawlan	Home Office
AZ-10750	Annie Zypern	Consumer
JM-15265	Janet Molinari	Corporate
RD-19585	Rob Dowd	Consumer
DP-13165	David Philippe	Consumer
GA-14515	George Ashbrook	Consumer
SA-20830	Sue Ann Reed	Consumer
RD-19720	Roger Demir	Consumer
MS-17830	Melanie Seite	Consumer
AG-10330	Alex Grayson	Consumer
NW-18400	Natalie Webber	Consumer
ND-18370	Natalie DeCherney	Consumer
BV-11245	Benjamin Venier	Corporate
AH-10075	Adam Hart	Corporate
AH-10120	Adrian Hane	Home Office
ML-17410	Maris LaWare	Consumer
GG-14650	Greg Guthrie	Corporate
MC-18100	Mick Crebagga	Consumer
AB-10060	Adam Bellavance	Home Office
SC-20575	Sonia Cooley	Consumer
EH-14005	Erica Hernandez	Home Office
LT-17110	Liz Thompson	Consumer
KF-16285	Karen Ferguson	Home Office
DO-13645	Doug O'Connell	Consumer
AA-10480	Andrew Allen	Consumer
DL-13495	Dionis Lloyd	Corporate
BS-11665	Brian Stugart	Consumer
PK-19075	Pete Kriz	Consumer
RB-19435	Richard Bierner	Consumer
SC-20725	Steven Cartwright	Consumer
VB-21745	Victoria Brennan	Corporate
CC-12685	Craig Carroll	Consumer
JL-15835	John Lee	Consumer
AR-10345	Alex Russell	Corporate
CM-12385	Christopher Martinez	Consumer
SP-20650	Stephanie Phelps	Corporate
DR-12880	Dan Reichenbach	Corporate
GA-14725	Guy Armstrong	Consumer
JO-15550	Jesus Ocampo	Home Office
MP-18175	Mike Pelletier	Home Office
FM-14380	Fred McMath	Consumer
AH-10690	Anna Häberlin	Corporate
MB-17305	Maria Bertelson	Consumer
PP-18955	Paul Prost	Home Office
AJ-10945	Ashley Jarboe	Consumer
JO-15145	Jack O'Briant	Corporate
EA-14035	Erin Ashbrook	Corporate
Co-12640	Corey-Lock	Consumer
CT-11995	Carol Triggs	Consumer
MM-18280	Muhammed MacIntyre	Corporate
CR-12625	Corey Roper	Home Office
CK-12760	Cyma Kinney	Corporate
GB-14575	Giulietta Baptist	Consumer
BT-11305	Beth Thompson	Home Office
JG-15160	James Galang	Consumer
NG-18430	Nathan Gelder	Consumer
LE-16810	Laurel Elliston	Consumer
HK-14890	Heather Kirkland	Corporate
RF-19735	Roland Fjeld	Consumer
CY-12745	Craig Yedwab	Corporate
KB-16600	Ken Brennan	Corporate
IL-15100	Ivan Liston	Consumer
TS-21655	Trudy Schmidt	Consumer
CM-12235	Chris McAfee	Consumer
DP-13000	Darren Powers	Consumer
RO-19780	Rose O'Brian	Consumer
FA-14230	Frank Atkinson	Corporate
FP-14320	Frank Preis	Consumer
SM-20950	Suzanne McNair	Corporate
AM-10360	Alice McCarthy	Corporate
MR-17545	Mathew Reese	Home Office
RB-19705	Roger Barcio	Home Office
SF-20965	Sylvia Foulston	Corporate
AR-10825	Anthony Rawles	Corporate
AD-10180	Alan Dominguez	Home Office
LR-17035	Lisa Ryan	Corporate
JP-15460	Jennifer Patt	Corporate
CV-12805	Cynthia Voltz	Corporate
KH-16330	Katharine Harms	Corporate
CD-11920	Carlos Daly	Consumer
MT-18070	Michelle Tran	Home Office
AG-10675	Anna Gayman	Consumer
TP-21565	Tracy Poddar	Corporate
CC-12370	Christopher Conant	Consumer
AR-10540	Andy Reiter	Consumer
RC-19825	Roy Collins	Consumer
TT-21220	Thomas Thornton	Consumer
KL-16555	Kelly Lampkin	Corporate
LW-17215	Luke Weiss	Consumer
PM-18940	Paul MacIntyre	Consumer
RH-19510	Rick Huthwaite	Home Office
MG-18145	Mike Gockenbach	Consumer
ZD-21925	Zuschuss Donatelli	Consumer
MM-18055	Michelle Moray	Consumer
TC-20980	Tamara Chand	Corporate
HA-14920	Helen Andreada	Consumer
NF-18475	Neil Französisch	Home Office
HG-14845	Harry Greene	Consumer
EH-14185	Evan Henry	Consumer
CC-12145	Charles Crestani	Consumer
NC-18625	Noah Childs	Corporate
KA-16525	Kelly Andreada	Consumer
AR-10510	Andrew Roberts	Consumer
SC-20680	Steve Carroll	Home Office
BS-11380	Bill Stewart	Corporate
NM-18520	Neoma Murray	Consumer
EK-13795	Eileen Kiefer	Home Office
JJ-15445	Jennifer Jackson	Consumer
SC-20020	Sam Craven	Consumer
HJ-14875	Heather Jas	Home Office
SC-20800	Stuart Calhoun	Consumer
BG-11740	Bruce Geld	Consumer
VP-21730	Victor Preis	Home Office
BG-11695	Brooke Gillingham	Corporate
JD-16150	Justin Deggeller	Corporate
JH-15985	Joseph Holt	Consumer
JB-15400	Jennifer Braxton	Corporate
SU-20665	Stephanie Ulpright	Home Office
DC-12850	Dan Campbell	Consumer
DH-13075	Dave Hallsten	Corporate
MZ-17515	Mary Zewe	Corporate
JD-15790	John Dryer	Consumer
PA-19060	Pete Armstrong	Home Office
SC-20845	Sung Chung	Consumer
AG-10495	Andrew Gjertsen	Corporate
SE-20110	Sanjit Engle	Consumer
TN-21040	Tanja Norvell	Home Office
FC-14245	Frank Carlisle	Home Office
DN-13690	Duane Noonan	Consumer
MD-17860	Michael Dominguez	Corporate
LD-16855	Lela Donovan	Corporate
CB-12415	Christy Brittain	Consumer
KN-16705	Kristina Nunn	Home Office
DL-13315	Delfina Latchford	Consumer
RW-19540	Rick Wilson	Corporate
GK-14620	Grace Kelly	Corporate
EB-14170	Evan Bailliet	Consumer
DB-13120	David Bremer	Corporate
DC-13285	Debra Catini	Consumer
JE-15610	Jim Epp	Corporate
DV-13465	Dianna Vittorini	Consumer
TG-21640	Trudy Glocke	Consumer
PW-19240	Pierre Wener	Consumer
BT-11680	Brian Thompson	Consumer
BF-10975	Barbara Fisher	Corporate
EH-13765	Edward Hooks	Corporate
BM-11650	Brian Moss	Corporate
TS-21370	Todd Sumrall	Corporate
MC-17605	Matt Connell	Corporate
NC-18415	Nathan Cano	Consumer
NS-18505	Neola Schneider	Consumer
VD-21670	Valerie Dominguez	Consumer
VS-21820	Vivek Sundaresam	Consumer
RB-19570	Rob Beeghly	Consumer
RP-19855	Roy Phan	Corporate
TM-21490	Tony Molinari	Consumer
CC-12670	Craig Carreira	Consumer
CJ-12010	Caroline Jumper	Consumer
DL-13330	Denise Leinenbach	Consumer
ME-17725	Max Engle	Consumer
GW-14605	Giulietta Weimer	Consumer
PO-19180	Philisse Overcash	Home Office
PB-19105	Peter Bühler	Consumer
PT-19090	Pete Takahito	Consumer
JF-15565	Jill Fjeld	Consumer
CC-12550	Clay Cheatham	Consumer
TS-21160	Theresa Swint	Corporate
JB-15925	Joni Blumstein	Consumer
LC-16885	Lena Creighton	Consumer
LS-16975	Lindsay Shagiari	Home Office
BM-11575	Brendan Murry	Corporate
MO-17500	Mary O'Rourke	Consumer
EL-13735	Ed Ludwig	Home Office
JK-15730	Joe Kamberova	Consumer
GB-14530	George Bell	Corporate
CS-12250	Chris Selesnick	Corporate
DA-13450	Dianna Arnett	Home Office
PS-19045	Penelope Sewall	Home Office
RF-19840	Roy Französisch	Consumer
DB-13555	Dorothy Badders	Corporate
KH-16630	Ken Heidel	Corporate
BE-11410	Bobby Elias	Consumer
SP-20860	Sung Pak	Corporate
DW-13540	Don Weiss	Consumer
AP-10720	Anne Pryor	Home Office
HA-14905	Helen Abelman	Consumer
BD-11500	Bradley Drucker	Consumer
TB-21250	Tim Brockman	Consumer
RD-19660	Robert Dilbeck	Home Office
RB-19465	Rick Bensley	Home Office
SD-20485	Shirley Daniels	Home Office
EH-13990	Erica Hackney	Consumer
GH-14665	Greg Hansen	Consumer
JF-15490	Jeremy Farry	Consumer
SV-20815	Stuart Van	Corporate
BN-11470	Brad Norvell	Corporate
NP-18670	Nora Paige	Consumer
CM-12445	Chuck Magee	Consumer
DF-13135	David Flashing	Consumer
CS-12490	Cindy Schnelling	Corporate
MT-17815	Meg Tillman	Consumer
JE-15745	Joel Eaton	Consumer
EB-13750	Edward Becker	Corporate
KH-16360	Katherine Hughes	Consumer
FH-14275	Frank Hawley	Corporate
CC-12100	Chad Cunningham	Home Office
AG-10765	Anthony Garverick	Home Office
AA-10315	Alex Avila	Consumer
CA-12310	Christine Abelman	Corporate
CL-11890	Carl Ludwig	Consumer
TB-21400	Tom Boeckenhauer	Consumer
PL-18925	Paul Lucas	Home Office
LH-17020	Lisa Hazard	Consumer
JK-16120	Julie Kriz	Home Office
CD-12790	Cynthia Delaney	Home Office
MG-17875	Michael Grace	Home Office
SS-20515	Shirley Schmidt	Home Office
AS-10045	Aaron Smayling	Corporate
PG-18820	Patrick Gardner	Consumer
DM-13345	Denise Monton	Corporate
EM-14065	Erin Mull	Consumer
SH-19975	Sally Hughsby	Corporate
BE-11455	Brad Eason	Home Office
BW-11110	Bart Watters	Corporate
MH-17455	Mark Hamilton	Consumer
AS-10285	Alejandro Savely	Corporate
RD-19810	Ross DeVincentis	Home Office
NF-18595	Nicole Fjeld	Home Office
AB-10015	Aaron Bergman	Consumer
LF-17185	Luke Foster	Consumer
AS-10630	Ann Steele	Home Office
TS-21610	Troy Staebel	Consumer
JS-15880	John Stevenson	Consumer
MP-17965	Michael Paige	Corporate
AH-10465	Amy Hunt	Consumer
AA-10645	Anna Andreadi	Consumer
HM-14860	Harry Marie	Corporate
SN-20710	Steve Nguyen	Home Office
ZC-21910	Zuschuss Carroll	Consumer
JE-15475	Jeremy Ellison	Consumer
AT-10735	Annie Thurman	Consumer
ME-18010	Michelle Ellison	Corporate
HE-14800	Harold Engle	Corporate
SN-20560	Skye Norling	Home Office
LS-17200	Luke Schmidt	Corporate
RL-19615	Rob Lucas	Consumer
TC-21475	Tony Chapman	Home Office
KB-16315	Karl Braun	Consumer
BT-11395	Bill Tyler	Corporate
AG-10525	Andy Gerbode	Corporate
JW-16075	Julia West	Consumer
SC-20260	Scott Cohen	Corporate
CR-12820	Cyra Reiten	Home Office
TP-21415	Tom Prescott	Consumer
JK-15325	Jason Klamczynski	Corporate
SC-20695	Steve Chapman	Corporate
CP-12085	Cathy Prescott	Corporate
NP-18685	Nora Pelletier	Home Office
NP-18700	Nora Preis	Consumer
JH-15820	John Huston	Consumer
ML-17755	Max Ludwig	Home Office
JM-15865	John Murray	Consumer
SP-20545	Sibella Parks	Corporate
EG-13900	Emily Grady	Consumer
AG-10270	Alejandro Grove	Consumer
KT-16480	Kean Thornton	Consumer
MS-17365	Maribeth Schnelling	Consumer
JJ-15760	Joel Jenkins	Home Office
CB-12025	Cassandra Brandow	Consumer
KM-16720	Kunst Miller	Consumer
DB-12910	Daniel Byrd	Home Office
AW-10930	Arthur Wiediger	Home Office
TT-21265	Tim Taslimi	Corporate
DK-13225	Dean Katz	Corporate
CG-12520	Claire Gute	Consumer
AM-10705	Anne McFarland	Consumer
BF-11020	Barry Französisch	Corporate
DK-13375	Dennis Kane	Consumer
MG-17890	Michael Granlund	Home Office
SW-20245	Scot Wooten	Consumer
SS-20410	Shahid Shariari	Consumer
MH-18025	Michelle Huthwaite	Consumer
TH-21115	Thea Hudgings	Corporate
MS-17710	Maurice Satty	Consumer
DJ-13420	Denny Joy	Corporate
BP-11050	Barry Pond	Corporate
AR-10405	Allen Rosenblatt	Corporate
SB-20170	Sarah Bern	Consumer
CD-11980	Carol Darley	Consumer
TH-21235	Tiffany House	Corporate
JS-16030	Joy Smith	Consumer
NK-18490	Neil Knudson	Home Office
JF-15295	Jason Fortune-	Consumer
MA-17560	Matt Abelman	Home Office
SV-20785	Stewart Visinsky	Consumer
EM-13825	Elizabeth Moffitt	Corporate
CM-12655	Corinna Mitchell	Home Office
JG-15805	John Grady	Corporate
HR-14770	Hallie Redmond	Home Office
AH-10585	Angele Hood	Consumer
PN-18775	Parhena Norris	Home Office
RH-19600	Rob Haberlin	Consumer
SR-20740	Steven Roelle	Home Office
BH-11710	Brosina Hoffman	Consumer
EM-13960	Eric Murdock	Consumer
BS-11755	Bruce Stewart	Consumer
KM-16375	Katherine Murray	Home Office
OT-18730	Olvera Toch	Consumer
SS-20590	Sonia Sunley	Consumer
ST-20530	Shui Tom	Consumer
LS-17230	Lycoris Saunders	Consumer
DK-12985	Darren Koutras	Consumer
RW-19630	Rob Williams	Corporate
TB-21280	Toby Braunhardt	Consumer
SC-20770	Stewart Carmichael	Corporate
GT-14710	Greg Tran	Consumer
PO-19195	Phillina Ober	Home Office
CG-12040	Catherine Glotzbach	Home Office
KB-16585	Ken Black	Corporate
KD-16270	Karen Daniels	Consumer
SP-20920	Susan Pistek	Consumer
EM-14200	Evan Minnotte	Home Office
PM-19135	Peter McVee	Home Office
CA-12265	Christina Anderson	Consumer
JF-15355	Jay Fein	Consumer
DE-13255	Deanra Eno	Home Office
MV-18190	Mike Vittorini	Consumer
RW-19690	Robert Waldorf	Consumer
DK-12895	Dana Kaydos	Consumer
SJ-20500	Shirley Jackson	Consumer
DK-12835	Damala Kotsonis	Corporate
CM-12190	Charlotte Melton	Consumer
AB-10150	Aimee Bixby	Consumer
RP-19270	Rachel Payne	Corporate
LC-17140	Logan Currie	Consumer
JK-16090	Juliana Krohn	Consumer
RH-19495	Rick Hansen	Consumer
LO-17170	Lori Olson	Corporate
CM-12715	Craig Molinari	Corporate
BD-11320	Bill Donatelli	Consumer
\.


--
-- TOC entry 5070 (class 0 OID 16559)
-- Dependencies: 222
-- Data for Name: dim_date; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_date (orderdate, orderyear, ordermonth, orderquarter) FROM stdin;
2014-03-26	2014	3	1
2014-09-24	2014	9	3
2015-05-30	2015	5	2
2014-11-13	2014	11	4
2013-12-17	2013	12	4
2014-07-13	2014	7	3
2013-12-30	2013	12	4
2015-02-22	2015	2	1
2015-05-14	2015	5	2
2013-05-08	2013	5	2
2016-08-21	2016	8	3
2014-11-30	2014	11	4
2016-12-30	2016	12	4
2013-11-11	2013	11	4
2014-12-23	2014	12	4
2014-06-03	2014	6	2
2016-11-05	2016	11	4
2014-11-07	2014	11	4
2016-12-13	2016	12	4
2013-03-24	2013	3	1
2014-10-20	2014	10	4
2013-12-02	2013	12	4
2016-04-03	2016	4	2
2015-09-05	2015	9	3
2013-09-20	2013	9	3
2013-11-14	2013	11	4
2016-01-08	2016	1	1
2016-01-23	2016	1	1
2014-03-09	2014	3	1
2014-05-27	2014	5	2
2016-03-23	2016	3	1
2014-09-11	2014	9	3
2015-07-24	2015	7	3
2013-11-28	2013	11	4
2014-02-03	2014	2	1
2015-10-22	2015	10	4
2015-04-28	2015	4	2
2014-05-13	2014	5	2
2013-09-02	2013	9	3
2014-04-02	2014	4	2
2016-04-09	2016	4	2
2013-11-22	2013	11	4
2016-11-03	2016	11	4
2013-06-24	2013	6	2
2013-04-25	2013	4	2
2013-01-13	2013	1	1
2014-10-28	2014	10	4
2013-04-20	2013	4	2
2013-08-23	2013	8	3
2013-12-23	2013	12	4
2016-03-27	2016	3	1
2016-05-20	2016	5	2
2016-05-10	2016	5	2
2013-03-01	2013	3	1
2013-11-10	2013	11	4
2016-10-11	2016	10	4
2015-10-02	2015	10	4
2013-02-06	2013	2	1
2014-03-04	2014	3	1
2015-11-20	2015	11	4
2016-07-20	2016	7	3
2016-02-27	2016	2	1
2013-06-17	2013	6	2
2016-08-08	2016	8	3
2014-12-30	2014	12	4
2013-12-21	2013	12	4
2014-02-09	2014	2	1
2014-12-24	2014	12	4
2014-12-02	2014	12	4
2013-10-17	2013	10	4
2015-08-24	2015	8	3
2015-10-09	2015	10	4
2013-09-30	2013	9	3
2016-02-20	2016	2	1
2013-12-13	2013	12	4
2014-08-16	2014	8	3
2016-09-03	2016	9	3
2013-08-29	2013	8	3
2015-10-23	2015	10	4
2015-10-26	2015	10	4
2015-11-17	2015	11	4
2015-03-12	2015	3	1
2014-04-29	2014	4	2
2016-03-03	2016	3	1
2014-03-08	2014	3	1
2015-02-27	2015	2	1
2016-02-04	2016	2	1
2015-04-10	2015	4	2
2015-11-16	2015	11	4
2015-01-12	2015	1	1
2013-11-12	2013	11	4
2016-04-01	2016	4	2
2016-08-07	2016	8	3
2016-10-01	2016	10	4
2015-08-11	2015	8	3
2014-05-05	2014	5	2
2016-08-09	2016	8	3
2014-07-25	2014	7	3
2015-01-30	2015	1	1
2016-01-19	2016	1	1
2016-03-13	2016	3	1
2016-11-23	2016	11	4
2013-10-09	2013	10	4
2014-09-15	2014	9	3
2013-10-14	2013	10	4
2013-02-16	2013	2	1
2016-09-26	2016	9	3
2013-09-14	2013	9	3
2013-05-16	2013	5	2
2014-01-30	2014	1	1
2015-03-13	2015	3	1
2016-10-14	2016	10	4
2014-10-26	2014	10	4
2015-07-27	2015	7	3
2015-02-08	2015	2	1
2016-12-20	2016	12	4
2014-08-06	2014	8	3
2016-05-18	2016	5	2
2013-09-16	2013	9	3
2014-12-04	2014	12	4
2013-06-20	2013	6	2
2014-08-31	2014	8	3
2015-03-23	2015	3	1
2013-05-30	2013	5	2
2016-09-06	2016	9	3
2014-02-22	2014	2	1
2016-09-18	2016	9	3
2013-10-08	2013	10	4
2013-11-29	2013	11	4
2013-09-03	2013	9	3
2013-04-09	2013	4	2
2014-11-18	2014	11	4
2013-09-12	2013	9	3
2016-12-03	2016	12	4
2015-11-29	2015	11	4
2013-05-31	2013	5	2
2014-04-06	2014	4	2
2016-11-11	2016	11	4
2016-05-22	2016	5	2
2015-03-29	2015	3	1
2014-06-08	2014	6	2
2013-12-22	2013	12	4
2016-10-07	2016	10	4
2013-04-06	2013	4	2
2016-08-10	2016	8	3
2013-07-30	2013	7	3
2015-12-07	2015	12	4
2016-03-05	2016	3	1
2016-07-31	2016	7	3
2016-04-11	2016	4	2
2015-10-18	2015	10	4
2014-05-11	2014	5	2
2016-06-15	2016	6	2
2013-07-05	2013	7	3
2016-12-02	2016	12	4
2015-03-04	2015	3	1
2014-03-07	2014	3	1
2015-04-04	2015	4	2
2016-03-10	2016	3	1
2014-07-05	2014	7	3
2015-12-19	2015	12	4
2015-09-24	2015	9	3
2016-07-23	2016	7	3
2013-05-23	2013	5	2
2014-06-26	2014	6	2
2013-06-01	2013	6	2
2013-11-17	2013	11	4
2013-09-23	2013	9	3
2015-03-06	2015	3	1
2014-11-24	2014	11	4
2015-10-08	2015	10	4
2016-05-14	2016	5	2
2014-12-31	2014	12	4
2015-06-14	2015	6	2
2016-06-14	2016	6	2
2013-10-18	2013	10	4
2016-07-14	2016	7	3
2014-03-20	2014	3	1
2013-03-28	2013	3	1
2015-04-29	2015	4	2
2016-10-08	2016	10	4
2014-10-01	2014	10	4
2016-06-25	2016	6	2
2016-11-07	2016	11	4
2014-08-11	2014	8	3
2015-05-22	2015	5	2
2015-03-18	2015	3	1
2014-04-28	2014	4	2
2015-03-25	2015	3	1
2016-12-01	2016	12	4
2014-09-29	2014	9	3
2016-11-28	2016	11	4
2016-06-04	2016	6	2
2016-07-03	2016	7	3
2014-11-05	2014	11	4
2013-09-19	2013	9	3
2016-10-27	2016	10	4
2015-05-07	2015	5	2
2015-06-07	2015	6	2
2015-08-14	2015	8	3
2016-11-14	2016	11	4
2016-11-09	2016	11	4
2016-04-04	2016	4	2
2016-04-24	2016	4	2
2013-06-27	2013	6	2
2015-08-27	2015	8	3
2013-05-20	2013	5	2
2014-12-10	2014	12	4
2015-09-02	2015	9	3
2013-12-26	2013	12	4
2014-12-11	2014	12	4
2013-02-14	2013	2	1
2016-10-23	2016	10	4
2016-11-10	2016	11	4
2016-04-26	2016	4	2
2016-01-20	2016	1	1
2016-05-08	2016	5	2
2014-09-13	2014	9	3
2014-10-12	2014	10	4
2013-11-15	2013	11	4
2014-12-01	2014	12	4
2016-06-10	2016	6	2
2016-08-22	2016	8	3
2014-12-03	2014	12	4
2016-12-15	2016	12	4
2015-07-18	2015	7	3
2014-01-04	2014	1	1
2013-05-11	2013	5	2
2013-10-28	2013	10	4
2014-06-09	2014	6	2
2015-09-28	2015	9	3
2015-10-24	2015	10	4
2016-06-08	2016	6	2
2015-12-02	2015	12	4
2016-07-06	2016	7	3
2015-10-25	2015	10	4
2013-05-15	2013	5	2
2013-08-22	2013	8	3
2016-11-13	2016	11	4
2013-03-29	2013	3	1
2013-06-15	2013	6	2
2014-12-25	2014	12	4
2013-12-16	2013	12	4
2015-11-24	2015	11	4
2014-12-21	2014	12	4
2013-09-09	2013	9	3
2014-04-10	2014	4	2
2016-10-25	2016	10	4
2015-11-09	2015	11	4
2014-03-12	2014	3	1
2016-12-14	2016	12	4
2013-09-08	2013	9	3
2014-04-11	2014	4	2
2016-10-15	2016	10	4
2016-09-19	2016	9	3
2016-12-22	2016	12	4
2014-06-13	2014	6	2
2016-09-29	2016	9	3
2014-10-15	2014	10	4
2013-02-15	2013	2	1
2016-03-12	2016	3	1
2015-12-04	2015	12	4
2016-10-30	2016	10	4
2014-10-29	2014	10	4
2013-11-19	2013	11	4
2013-07-27	2013	7	3
2015-09-14	2015	9	3
2013-12-04	2013	12	4
2015-11-18	2015	11	4
2014-04-19	2014	4	2
2013-05-03	2013	5	2
2013-04-22	2013	4	2
2015-05-10	2015	5	2
2015-03-30	2015	3	1
2013-03-17	2013	3	1
2015-06-12	2015	6	2
2016-06-06	2016	6	2
2014-09-20	2014	9	3
2014-05-08	2014	5	2
2016-11-06	2016	11	4
2013-05-19	2013	5	2
2015-06-03	2015	6	2
2016-09-28	2016	9	3
2013-08-17	2013	8	3
2013-11-01	2013	11	4
2013-07-04	2013	7	3
2016-03-18	2016	3	1
2016-06-24	2016	6	2
2013-12-18	2013	12	4
2015-10-05	2015	10	4
2013-12-14	2013	12	4
2014-05-02	2014	5	2
2016-11-27	2016	11	4
2014-06-24	2014	6	2
2015-08-19	2015	8	3
2014-11-14	2014	11	4
2016-07-16	2016	7	3
2013-07-26	2013	7	3
2016-12-05	2016	12	4
2015-03-26	2015	3	1
2015-05-01	2015	5	2
2016-06-19	2016	6	2
2013-09-28	2013	9	3
2013-05-12	2013	5	2
2016-02-02	2016	2	1
2014-07-02	2014	7	3
2014-12-27	2014	12	4
2015-07-02	2015	7	3
2014-03-01	2014	3	1
2013-07-02	2013	7	3
2016-10-19	2016	10	4
2014-04-07	2014	4	2
2014-07-03	2014	7	3
2014-11-10	2014	11	4
2015-12-14	2015	12	4
2014-01-19	2014	1	1
2016-05-25	2016	5	2
2016-05-12	2016	5	2
2016-07-17	2016	7	3
2013-06-09	2013	6	2
2016-03-22	2016	3	1
2015-08-15	2015	8	3
2016-06-16	2016	6	2
2014-07-27	2014	7	3
2016-11-25	2016	11	4
2016-09-09	2016	9	3
2014-04-17	2014	4	2
2015-05-29	2015	5	2
2014-11-04	2014	11	4
2014-11-27	2014	11	4
2016-02-03	2016	2	1
2016-12-04	2016	12	4
2015-06-26	2015	6	2
2016-09-01	2016	9	3
2016-07-24	2016	7	3
2013-01-12	2013	1	1
2014-04-22	2014	4	2
2013-04-07	2013	4	2
2016-05-28	2016	5	2
2013-01-20	2013	1	1
2016-03-06	2016	3	1
2015-04-22	2015	4	2
2016-06-20	2016	6	2
2014-01-31	2014	1	1
2013-03-05	2013	3	1
2015-03-16	2015	3	1
2016-09-04	2016	9	3
2016-04-05	2016	4	2
2013-11-24	2013	11	4
2014-07-04	2014	7	3
2016-07-11	2016	7	3
2016-02-08	2016	2	1
2015-07-01	2015	7	3
2016-03-25	2016	3	1
2013-06-28	2013	6	2
2014-03-29	2014	3	1
2013-11-03	2013	11	4
2015-12-16	2015	12	4
2014-09-02	2014	9	3
2015-04-23	2015	4	2
2013-02-11	2013	2	1
2015-11-04	2015	11	4
2016-08-19	2016	8	3
2014-06-28	2014	6	2
2013-01-23	2013	1	1
2013-11-30	2013	11	4
2014-11-17	2014	11	4
2014-11-02	2014	11	4
2014-12-15	2014	12	4
2014-08-10	2014	8	3
2015-04-15	2015	4	2
2015-04-11	2015	4	2
2015-09-15	2015	9	3
2015-08-29	2015	8	3
2013-03-14	2013	3	1
2013-05-26	2013	5	2
2016-10-10	2016	10	4
2015-06-21	2015	6	2
2013-08-02	2013	8	3
2016-05-30	2016	5	2
2016-04-15	2016	4	2
2013-11-25	2013	11	4
2014-11-28	2014	11	4
2014-12-05	2014	12	4
2015-10-29	2015	10	4
2014-08-14	2014	8	3
2015-12-27	2015	12	4
2016-11-22	2016	11	4
2016-05-26	2016	5	2
2016-12-18	2016	12	4
2014-04-04	2014	4	2
2015-06-18	2015	6	2
2016-07-02	2016	7	3
2016-12-29	2016	12	4
2013-04-29	2013	4	2
2017-01-04	2017	1	1
2014-04-03	2014	4	2
2013-07-14	2013	7	3
2015-09-11	2015	9	3
2016-03-24	2016	3	1
2014-05-18	2014	5	2
2014-07-17	2014	7	3
2015-06-19	2015	6	2
2015-06-05	2015	6	2
2015-07-15	2015	7	3
2016-02-17	2016	2	1
2014-11-29	2014	11	4
2014-04-30	2014	4	2
2015-09-13	2015	9	3
2015-05-04	2015	5	2
2014-10-24	2014	10	4
2015-07-26	2015	7	3
2015-02-04	2015	2	1
2015-04-20	2015	4	2
2014-10-23	2014	10	4
2016-03-02	2016	3	1
2016-09-27	2016	9	3
2016-07-28	2016	7	3
2016-06-02	2016	6	2
2015-11-30	2015	11	4
2014-08-17	2014	8	3
2016-08-03	2016	8	3
2015-12-18	2015	12	4
2014-01-17	2014	1	1
2014-04-20	2014	4	2
2016-03-14	2016	3	1
2014-10-22	2014	10	4
2014-05-12	2014	5	2
2013-05-18	2013	5	2
2016-02-21	2016	2	1
2015-11-02	2015	11	4
2015-08-04	2015	8	3
2016-08-27	2016	8	3
2013-10-01	2013	10	4
2015-07-31	2015	7	3
2015-12-24	2015	12	4
2013-11-02	2013	11	4
2015-11-22	2015	11	4
2014-11-09	2014	11	4
2015-09-26	2015	9	3
2015-05-21	2015	5	2
2014-07-12	2014	7	3
2014-10-19	2014	10	4
2014-04-16	2014	4	2
2013-11-07	2013	11	4
2016-01-16	2016	1	1
2014-05-04	2014	5	2
2015-08-21	2015	8	3
2013-12-01	2013	12	4
2016-09-02	2016	9	3
2015-11-08	2015	11	4
2016-09-05	2016	9	3
2016-07-01	2016	7	3
2014-09-21	2014	9	3
2015-09-03	2015	9	3
2013-06-10	2013	6	2
2016-08-28	2016	8	3
2015-11-06	2015	11	4
2014-04-05	2014	4	2
2015-10-12	2015	10	4
2015-12-28	2015	12	4
2014-12-20	2014	12	4
2014-11-22	2014	11	4
2013-04-12	2013	4	2
2014-07-24	2014	7	3
2016-05-06	2016	5	2
2015-06-29	2015	6	2
2015-07-17	2015	7	3
2015-07-19	2015	7	3
2015-01-03	2015	1	1
2014-09-03	2014	9	3
2014-11-16	2014	11	4
2016-10-28	2016	10	4
2014-01-08	2014	1	1
2014-09-18	2014	9	3
2013-10-03	2013	10	4
2015-09-20	2015	9	3
2016-04-27	2016	4	2
2013-09-27	2013	9	3
2013-06-30	2013	6	2
2015-08-28	2015	8	3
2015-02-15	2015	2	1
2016-02-15	2016	2	1
2016-12-24	2016	12	4
2016-03-30	2016	3	1
2015-07-04	2015	7	3
2013-03-31	2013	3	1
2016-09-10	2016	9	3
2014-09-25	2014	9	3
2015-09-06	2015	9	3
2015-02-28	2015	2	1
2015-08-09	2015	8	3
2016-11-29	2016	11	4
2015-12-09	2015	12	4
2015-03-21	2015	3	1
2015-03-07	2015	3	1
2015-07-03	2015	7	3
2013-05-25	2013	5	2
2016-01-13	2016	1	1
2013-02-24	2013	2	1
2016-10-04	2016	10	4
2016-07-08	2016	7	3
2013-08-18	2013	8	3
2013-08-20	2013	8	3
2013-11-21	2013	11	4
2013-12-06	2013	12	4
2016-02-18	2016	2	1
2016-02-09	2016	2	1
2013-07-11	2013	7	3
2015-06-10	2015	6	2
2013-11-16	2013	11	4
2015-01-11	2015	1	1
2016-08-29	2016	8	3
2015-08-01	2015	8	3
2013-09-13	2013	9	3
2014-03-31	2014	3	1
2015-11-19	2015	11	4
2017-01-05	2017	1	1
2015-09-07	2015	9	3
2015-11-15	2015	11	4
2016-11-19	2016	11	4
2014-10-17	2014	10	4
2016-03-07	2016	3	1
2016-06-09	2016	6	2
2013-04-04	2013	4	2
2016-06-27	2016	6	2
2015-08-06	2015	8	3
2016-12-28	2016	12	4
2013-12-29	2013	12	4
2016-06-17	2016	6	2
2015-12-10	2015	12	4
2014-12-14	2014	12	4
2015-08-02	2015	8	3
2014-08-23	2014	8	3
2014-06-04	2014	6	2
2014-04-13	2014	4	2
2015-10-04	2015	10	4
2016-08-11	2016	8	3
2015-04-08	2015	4	2
2015-05-27	2015	5	2
2015-09-23	2015	9	3
2013-03-03	2013	3	1
2016-01-01	2016	1	1
2013-04-02	2013	4	2
2013-12-05	2013	12	4
2015-03-08	2015	3	1
2015-03-15	2015	3	1
2013-11-20	2013	11	4
2016-09-20	2016	9	3
2014-09-26	2014	9	3
2013-08-05	2013	8	3
2016-06-26	2016	6	2
2016-01-06	2016	1	1
2014-08-28	2014	8	3
2016-01-26	2016	1	1
2013-07-22	2013	7	3
2014-12-28	2014	12	4
2013-12-11	2013	12	4
2014-03-02	2014	3	1
2014-10-08	2014	10	4
2016-02-01	2016	2	1
2014-10-18	2014	10	4
2015-07-12	2015	7	3
2016-02-07	2016	2	1
2016-11-24	2016	11	4
2013-12-27	2013	12	4
2016-11-15	2016	11	4
2015-08-07	2015	8	3
2013-03-22	2013	3	1
2016-10-12	2016	10	4
2013-07-24	2013	7	3
2014-01-01	2014	1	1
2016-05-01	2016	5	2
2013-09-26	2013	9	3
2013-02-10	2013	2	1
2015-12-06	2015	12	4
2015-05-09	2015	5	2
2013-10-31	2013	10	4
2014-06-16	2014	6	2
2016-04-10	2016	4	2
2014-05-07	2014	5	2
2015-06-25	2015	6	2
2015-02-16	2015	2	1
2016-11-21	2016	11	4
2015-12-05	2015	12	4
2016-07-25	2016	7	3
2016-03-17	2016	3	1
2013-05-22	2013	5	2
2016-10-24	2016	10	4
2016-09-14	2016	9	3
2016-12-21	2016	12	4
2016-10-21	2016	10	4
2015-01-01	2015	1	1
2013-07-20	2013	7	3
2015-02-03	2015	2	1
2015-06-27	2015	6	2
2014-04-25	2014	4	2
2016-04-12	2016	4	2
2015-11-23	2015	11	4
2014-11-23	2014	11	4
2015-01-07	2015	1	1
2016-02-14	2016	2	1
2013-10-15	2013	10	4
2013-02-21	2013	2	1
2015-10-27	2015	10	4
2015-02-13	2015	2	1
2015-09-18	2015	9	3
2015-12-13	2015	12	4
2016-10-13	2016	10	4
2014-07-06	2014	7	3
2015-02-11	2015	2	1
2015-03-14	2015	3	1
2013-01-29	2013	1	1
2014-08-01	2014	8	3
2014-01-02	2014	1	1
2015-08-23	2015	8	3
2014-11-26	2014	11	4
2015-09-10	2015	9	3
2013-01-07	2013	1	1
2015-05-28	2015	5	2
2013-12-08	2013	12	4
2015-10-10	2015	10	4
2014-08-13	2014	8	3
2014-08-29	2014	8	3
2015-07-09	2015	7	3
2015-12-11	2015	12	4
2016-04-02	2016	4	2
2016-09-07	2016	9	3
2015-05-16	2015	5	2
2013-09-07	2013	9	3
2014-09-10	2014	9	3
2016-01-30	2016	1	1
2016-04-21	2016	4	2
2015-05-08	2015	5	2
2015-05-11	2015	5	2
2013-08-08	2013	8	3
2014-04-18	2014	4	2
2016-08-13	2016	8	3
2016-11-02	2016	11	4
2015-09-04	2015	9	3
2016-05-29	2016	5	2
2014-06-01	2014	6	2
2015-10-03	2015	10	4
2015-04-27	2015	4	2
2014-01-03	2014	1	1
2014-09-27	2014	9	3
2016-01-03	2016	1	1
2013-06-22	2013	6	2
2015-10-31	2015	10	4
2016-08-18	2016	8	3
2015-08-17	2015	8	3
2013-01-30	2013	1	1
2013-07-12	2013	7	3
2013-07-16	2013	7	3
2016-10-05	2016	10	4
2015-11-05	2015	11	4
2013-02-20	2013	2	1
2016-06-22	2016	6	2
2016-04-23	2016	4	2
2013-11-09	2013	11	4
2016-11-16	2016	11	4
2015-07-30	2015	7	3
2013-12-03	2013	12	4
2014-12-09	2014	12	4
2014-07-30	2014	7	3
2014-04-26	2014	4	2
2014-06-22	2014	6	2
2014-06-23	2014	6	2
2013-02-18	2013	2	1
2016-03-29	2016	3	1
2016-01-15	2016	1	1
2014-03-27	2014	3	1
2015-10-14	2015	10	4
2014-05-21	2014	5	2
2014-05-01	2014	5	2
2014-11-01	2014	11	4
2015-07-11	2015	7	3
2015-12-08	2015	12	4
2014-11-12	2014	11	4
2013-12-09	2013	12	4
2013-02-26	2013	2	1
2016-01-24	2016	1	1
2013-12-31	2013	12	4
2016-09-17	2016	9	3
2015-09-01	2015	9	3
2013-10-07	2013	10	4
2016-03-11	2016	3	1
2016-09-25	2016	9	3
2013-06-14	2013	6	2
2014-03-22	2014	3	1
2014-03-30	2014	3	1
2014-12-22	2014	12	4
2015-07-08	2015	7	3
2016-04-18	2016	4	2
2015-10-15	2015	10	4
2016-06-07	2016	6	2
2016-12-25	2016	12	4
2016-08-01	2016	8	3
2016-06-13	2016	6	2
2014-09-01	2014	9	3
2016-06-03	2016	6	2
2014-06-19	2014	6	2
2015-12-03	2015	12	4
2015-04-19	2015	4	2
2014-06-12	2014	6	2
2015-05-03	2015	5	2
2014-05-25	2014	5	2
2013-06-07	2013	6	2
2013-01-08	2013	1	1
2015-06-16	2015	6	2
2013-02-03	2013	2	1
2016-01-05	2016	1	1
2013-07-21	2013	7	3
2016-07-04	2016	7	3
2013-08-28	2013	8	3
2015-12-30	2015	12	4
2016-09-22	2016	9	3
2014-02-15	2014	2	1
2015-08-20	2015	8	3
2013-03-07	2013	3	1
2014-12-19	2014	12	4
2014-12-08	2014	12	4
2014-11-08	2014	11	4
2015-01-31	2015	1	1
2013-10-29	2013	10	4
2014-11-15	2014	11	4
2014-03-24	2014	3	1
2015-03-22	2015	3	1
2013-12-28	2013	12	4
2015-05-24	2015	5	2
2013-06-03	2013	6	2
2014-02-04	2014	2	1
2013-10-10	2013	10	4
2016-08-04	2016	8	3
2014-01-23	2014	1	1
2016-03-16	2016	3	1
2013-11-26	2013	11	4
2016-05-11	2016	5	2
2016-08-23	2016	8	3
2013-04-18	2013	4	2
2013-05-17	2013	5	2
2015-03-02	2015	3	1
2014-06-30	2014	6	2
2015-08-31	2015	8	3
2014-08-09	2014	8	3
2014-12-06	2014	12	4
2015-08-12	2015	8	3
2015-04-13	2015	4	2
2014-06-20	2014	6	2
2014-05-29	2014	5	2
2016-01-17	2016	1	1
2015-07-28	2015	7	3
2014-02-05	2014	2	1
2013-12-20	2013	12	4
2014-05-17	2014	5	2
2015-07-23	2015	7	3
2015-05-06	2015	5	2
2016-10-02	2016	10	4
2015-06-30	2015	6	2
2016-10-22	2016	10	4
2014-02-08	2014	2	1
2016-01-14	2016	1	1
2015-10-13	2015	10	4
2016-08-24	2016	8	3
2013-08-12	2013	8	3
2013-04-05	2013	4	2
2016-10-06	2016	10	4
2015-03-09	2015	3	1
2016-06-23	2016	6	2
2014-05-28	2014	5	2
2016-07-10	2016	7	3
2013-01-03	2013	1	1
2015-05-20	2015	5	2
2015-06-13	2015	6	2
2014-02-24	2014	2	1
2013-02-23	2013	2	1
2013-03-30	2013	3	1
2015-05-31	2015	5	2
2016-01-29	2016	1	1
2016-11-26	2016	11	4
2016-11-18	2016	11	4
2016-10-16	2016	10	4
2015-10-01	2015	10	4
2013-10-20	2013	10	4
2016-09-30	2016	9	3
2015-09-12	2015	9	3
2013-09-21	2013	9	3
2015-09-29	2015	9	3
2013-05-05	2013	5	2
2016-12-27	2016	12	4
2016-09-12	2016	9	3
2016-06-30	2016	6	2
2013-10-12	2013	10	4
2014-07-08	2014	7	3
2013-09-17	2013	9	3
2013-01-27	2013	1	1
2015-06-17	2015	6	2
2014-10-09	2014	10	4
2016-10-18	2016	10	4
2016-12-19	2016	12	4
2014-05-26	2014	5	2
2016-02-22	2016	2	1
2015-04-07	2015	4	2
2014-09-30	2014	9	3
2015-09-19	2015	9	3
2016-08-26	2016	8	3
2013-06-11	2013	6	2
2016-03-21	2016	3	1
2013-05-10	2013	5	2
2016-11-20	2016	11	4
2014-09-04	2014	9	3
2014-11-11	2014	11	4
2013-06-05	2013	6	2
2015-11-01	2015	11	4
2013-11-27	2013	11	4
2014-12-17	2014	12	4
2014-11-20	2014	11	4
2016-04-14	2016	4	2
2016-07-12	2016	7	3
2013-07-25	2013	7	3
2017-01-02	2017	1	1
2015-12-17	2015	12	4
2013-07-09	2013	7	3
2013-08-25	2013	8	3
2016-09-16	2016	9	3
2016-10-31	2016	10	4
2014-07-20	2014	7	3
2014-06-25	2014	6	2
2016-05-17	2016	5	2
2014-07-31	2014	7	3
2013-05-04	2013	5	2
2015-04-18	2015	4	2
2015-12-23	2015	12	4
2014-08-24	2014	8	3
2014-10-10	2014	10	4
2016-12-16	2016	12	4
2013-09-10	2013	9	3
2016-02-23	2016	2	1
2016-06-21	2016	6	2
2014-05-23	2014	5	2
2013-12-12	2013	12	4
2016-07-26	2016	7	3
2015-09-17	2015	9	3
2013-10-25	2013	10	4
2015-06-15	2015	6	2
2014-02-11	2014	2	1
2015-09-09	2015	9	3
2015-02-20	2015	2	1
2016-04-22	2016	4	2
2014-09-28	2014	9	3
2016-12-12	2016	12	4
2014-03-10	2014	3	1
2016-06-05	2016	6	2
2014-10-13	2014	10	4
2016-08-06	2016	8	3
2014-02-06	2014	2	1
2015-12-21	2015	12	4
2014-11-21	2014	11	4
2015-12-22	2015	12	4
2016-12-08	2016	12	4
2013-11-08	2013	11	4
2014-09-14	2014	9	3
2016-04-20	2016	4	2
2016-11-12	2016	11	4
2016-09-13	2016	9	3
2015-08-30	2015	8	3
2016-08-15	2016	8	3
2015-10-21	2015	10	4
2016-05-15	2016	5	2
2015-10-20	2015	10	4
2015-03-19	2015	3	1
2016-11-01	2016	11	4
2014-01-24	2014	1	1
2013-02-04	2013	2	1
2016-07-05	2016	7	3
2014-05-31	2014	5	2
2013-09-01	2013	9	3
2015-11-27	2015	11	4
2015-03-20	2015	3	1
2014-01-10	2014	1	1
2016-02-26	2016	2	1
2015-11-26	2015	11	4
2013-11-18	2013	11	4
2015-11-28	2015	11	4
2014-09-17	2014	9	3
2016-09-08	2016	9	3
2013-12-19	2013	12	4
2015-08-05	2015	8	3
2014-02-19	2014	2	1
2015-09-25	2015	9	3
2013-04-16	2013	4	2
2015-05-18	2015	5	2
2013-09-25	2013	9	3
2013-01-09	2013	1	1
2013-09-22	2013	9	3
2016-03-04	2016	3	1
2016-10-26	2016	10	4
2014-12-26	2014	12	4
2015-01-04	2015	1	1
2013-02-19	2013	2	1
2016-06-01	2016	6	2
2014-12-16	2014	12	4
2014-04-24	2014	4	2
2014-10-31	2014	10	4
2013-08-15	2013	8	3
2015-07-29	2015	7	3
2016-03-26	2016	3	1
2016-09-24	2016	9	3
2013-11-23	2013	11	4
2016-07-13	2016	7	3
2015-03-05	2015	3	1
2016-05-19	2016	5	2
2015-03-03	2015	3	1
2014-06-29	2014	6	2
2016-12-26	2016	12	4
2013-04-11	2013	4	2
2015-08-16	2015	8	3
2013-02-01	2013	2	1
2015-04-25	2015	4	2
2016-07-29	2016	7	3
2016-05-13	2016	5	2
2015-04-16	2015	4	2
2016-09-23	2016	9	3
2014-10-30	2014	10	4
2015-08-13	2015	8	3
2013-07-19	2013	7	3
2015-03-27	2015	3	1
2016-07-22	2016	7	3
2013-04-17	2013	4	2
2016-03-09	2016	3	1
2015-10-16	2015	10	4
2016-03-20	2016	3	1
2014-02-13	2014	2	1
2013-05-21	2013	5	2
2013-09-15	2013	9	3
2016-01-31	2016	1	1
2016-04-30	2016	4	2
2016-01-21	2016	1	1
2016-05-07	2016	5	2
2016-12-17	2016	12	4
2014-09-07	2014	9	3
2013-06-21	2013	6	2
2016-04-06	2016	4	2
2015-10-07	2015	10	4
2014-09-05	2014	9	3
2015-06-01	2015	6	2
2015-09-30	2015	9	3
2014-08-07	2014	8	3
2014-07-18	2014	7	3
2015-01-02	2015	1	1
2016-12-09	2016	12	4
2015-11-25	2015	11	4
2016-11-04	2016	11	4
2015-01-05	2015	1	1
2016-04-17	2016	4	2
2016-07-07	2016	7	3
2015-11-10	2015	11	4
2016-09-15	2016	9	3
2016-04-16	2016	4	2
2013-10-22	2013	10	4
2015-06-28	2015	6	2
2016-09-21	2016	9	3
2015-02-02	2015	2	1
2013-04-01	2013	4	2
2013-09-04	2013	9	3
2016-01-28	2016	1	1
2014-03-23	2014	3	1
2016-12-07	2016	12	4
2013-03-10	2013	3	1
2014-08-03	2014	8	3
2015-12-20	2015	12	4
2013-02-25	2013	2	1
2016-05-23	2016	5	2
2016-07-09	2016	7	3
2015-10-11	2015	10	4
2015-05-02	2015	5	2
2016-08-31	2016	8	3
2016-11-30	2016	11	4
2014-07-10	2014	7	3
2014-03-05	2014	3	1
2016-06-29	2016	6	2
2015-11-11	2015	11	4
2013-02-17	2013	2	1
2016-07-27	2016	7	3
2015-11-14	2015	11	4
2013-10-06	2013	10	4
2016-10-09	2016	10	4
2013-12-15	2013	12	4
2016-11-17	2016	11	4
2016-12-23	2016	12	4
2014-01-05	2014	1	1
2016-01-27	2016	1	1
2013-06-16	2013	6	2
2014-11-03	2014	11	4
2016-03-31	2016	3	1
2015-09-08	2015	9	3
2015-04-09	2015	4	2
2015-12-31	2015	12	4
2014-12-12	2014	12	4
2015-10-30	2015	10	4
2016-08-30	2016	8	3
2013-05-27	2013	5	2
2016-01-02	2016	1	1
2014-08-08	2014	8	3
2014-08-25	2014	8	3
2015-11-12	2015	11	4
2016-10-03	2016	10	4
2016-02-10	2016	2	1
2016-06-18	2016	6	2
2016-05-27	2016	5	2
2013-01-04	2013	1	1
2015-12-25	2015	12	4
2016-09-11	2016	9	3
2014-07-15	2014	7	3
2015-11-21	2015	11	4
2016-01-22	2016	1	1
2016-08-05	2016	8	3
2014-05-24	2014	5	2
2015-04-24	2015	4	2
2015-04-06	2015	4	2
2013-06-06	2013	6	2
2014-07-09	2014	7	3
2013-09-18	2013	9	3
2014-08-05	2014	8	3
2015-06-22	2015	6	2
2015-09-21	2015	9	3
2016-07-21	2016	7	3
2013-12-25	2013	12	4
2015-04-03	2015	4	2
2015-11-13	2015	11	4
2016-02-06	2016	2	1
2016-05-05	2016	5	2
2016-12-06	2016	12	4
2013-12-10	2013	12	4
2015-01-08	2015	1	1
2016-04-25	2016	4	2
2014-10-05	2014	10	4
2013-05-29	2013	5	2
2016-06-12	2016	6	2
2014-06-05	2014	6	2
2013-07-15	2013	7	3
2016-12-10	2016	12	4
2015-12-01	2015	12	4
2015-04-02	2015	4	2
2016-03-08	2016	3	1
2013-01-26	2013	1	1
2014-05-10	2014	5	2
2016-08-17	2016	8	3
2013-06-12	2013	6	2
2015-09-27	2015	9	3
2016-01-11	2016	1	1
2013-10-19	2013	10	4
2017-01-01	2017	1	1
2016-04-08	2016	4	2
2014-03-19	2014	3	1
2013-06-13	2013	6	2
2016-12-11	2016	12	4
2013-02-27	2013	2	1
\.


--
-- TOC entry 5069 (class 0 OID 16553)
-- Dependencies: 221
-- Data for Name: dim_location; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_location (postalcode, city, state, region, country) FROM stdin;
77536	Deer Park	Texas	Central	United States
48205	Detroit	Michigan	Central	United States
48601	Saginaw	Michigan	Central	United States
77642	Port Arthur	Texas	Central	United States
61701	Bloomington	Illinois	Central	United States
75019	Coppell	Texas	Central	United States
76903	San Angelo	Texas	Central	United States
56560	Moorhead	Minnesota	Central	United States
48104	Ann Arbor	Michigan	Central	United States
79605	Abilene	Texas	Central	United States
75007	Carrollton	Texas	Central	United States
77070	Houston	Texas	Central	United States
75220	Dallas	Texas	Central	United States
48307	Rochester Hills	Michigan	Central	United States
47150	New Albany	Indiana	Central	United States
65203	Columbia	Missouri	Central	United States
46614	South Bend	Indiana	Central	United States
79424	Lubbock	Texas	Central	United States
53209	Milwaukee	Wisconsin	Central	United States
74012	Broken Arrow	Oklahoma	Central	United States
46142	Greenwood	Indiana	Central	United States
75002	Allen	Texas	Central	United States
75217	Dallas	Texas	Central	United States
60016	Des Plaines	Illinois	Central	United States
53081	Sheboygan	Wisconsin	Central	United States
68104	Omaha	Nebraska	Central	United States
67212	Wichita	Kansas	Central	United States
65109	Jefferson City	Missouri	Central	United States
60025	Glenview	Illinois	Central	United States
60423	Frankfort	Illinois	Central	United States
76063	Mansfield	Texas	Central	United States
60477	Tinley Park	Illinois	Central	United States
61761	Normal	Illinois	Central	United States
66502	Manhattan	Kansas	Central	United States
49201	Jackson	Michigan	Central	United States
77581	Pearland	Texas	Central	United States
73120	Oklahoma City	Oklahoma	Central	United States
78415	Corpus Christi	Texas	Central	United States
46060	Noblesville	Indiana	Central	United States
60068	Park Ridge	Illinois	Central	United States
54401	Wausau	Wisconsin	Central	United States
76021	Bedford	Texas	Central	United States
47905	Lafayette	Indiana	Central	United States
77840	College Station	Texas	Central	United States
78501	Mcallen	Texas	Central	United States
53214	West Allis	Wisconsin	Central	United States
60462	Orland Park	Illinois	Central	United States
75080	Richardson	Texas	Central	United States
53142	Kenosha	Wisconsin	Central	United States
55016	Cottage Grove	Minnesota	Central	United States
60441	Romeoville	Illinois	Central	United States
55106	Saint Paul	Minnesota	Central	United States
77571	La Porte	Texas	Central	United States
60004	Arlington Heights	Illinois	Central	United States
52601	Burlington	Iowa	Central	United States
48066	Roseville	Michigan	Central	United States
78664	Round Rock	Texas	Central	United States
57701	Rapid City	South Dakota	Central	United States
47401	Bloomington	Indiana	Central	United States
61604	Peoria	Illinois	Central	United States
75051	Grand Prairie	Texas	Central	United States
75701	Tyler	Texas	Central	United States
50315	Des Moines	Iowa	Central	United States
60505	Aurora	Illinois	Central	United States
60653	Chicago	Illinois	Central	United States
48234	Detroit	Michigan	Central	United States
46368	Portage	Indiana	Central	United States
61032	Freeport	Illinois	Central	United States
64055	Independence	Missouri	Central	United States
77095	Houston	Texas	Central	United States
60067	Palatine	Illinois	Central	United States
46514	Elkhart	Indiana	Central	United States
75023	Plano	Texas	Central	United States
79109	Amarillo	Texas	Central	United States
60543	Oswego	Illinois	Central	United States
75056	The Colony	Texas	Central	United States
62521	Decatur	Illinois	Central	United States
60035	Highland Park	Illinois	Central	United States
63116	Saint Louis	Missouri	Central	United States
60174	Saint Charles	Illinois	Central	United States
79907	El Paso	Texas	Central	United States
60540	Naperville	Illinois	Central	United States
49505	Grand Rapids	Michigan	Central	United States
46544	Mishawaka	Indiana	Central	United States
75061	Irving	Texas	Central	United States
66062	Olathe	Kansas	Central	United States
60126	Elmhurst	Illinois	Central	United States
57401	Aberdeen	South Dakota	Central	United States
63301	Saint Charles	Missouri	Central	United States
62301	Quincy	Illinois	Central	United States
46350	La Porte	Indiana	Central	United States
79762	Odessa	Texas	Central	United States
68801	Grand Island	Nebraska	Central	United States
78745	Austin	Texas	Central	United States
75150	Mesquite	Texas	Central	United States
53132	Franklin	Wisconsin	Central	United States
48126	Dearborn	Michigan	Central	United States
77520	Baytown	Texas	Central	United States
48310	Sterling Heights	Michigan	Central	United States
60098	Woodstock	Illinois	Central	United States
56301	Saint Cloud	Minnesota	Central	United States
77573	League City	Texas	Central	United States
63122	Kirkwood	Missouri	Central	United States
78521	Brownsville	Texas	Central	United States
54703	Eau Claire	Wisconsin	Central	United States
50701	Waterloo	Iowa	Central	United States
48187	Canton	Michigan	Central	United States
52240	Iowa City	Iowa	Central	United States
78539	Edinburg	Texas	Central	United States
76017	Arlington	Texas	Central	United States
46203	Indianapolis	Indiana	Central	United States
48183	Trenton	Michigan	Central	United States
65807	Springfield	Missouri	Central	United States
54302	Green Bay	Wisconsin	Central	United States
78577	Pharr	Texas	Central	United States
46226	Lawrence	Indiana	Central	United States
60302	Oak Park	Illinois	Central	United States
78550	Harlingen	Texas	Central	United States
66212	Overland Park	Kansas	Central	United States
64118	Gladstone	Missouri	Central	United States
55124	Apple Valley	Minnesota	Central	United States
75104	Cedar Hill	Texas	Central	United States
48180	Taylor	Michigan	Central	United States
77590	Texas City	Texas	Central	United States
48073	Royal Oak	Michigan	Central	United States
47374	Richmond	Indiana	Central	United States
61821	Champaign	Illinois	Central	United States
55122	Eagan	Minnesota	Central	United States
53711	Madison	Wisconsin	Central	United States
76248	Keller	Texas	Central	United States
57103	Sioux Falls	South Dakota	Central	United States
61832	Danville	Illinois	Central	United States
77340	Huntsville	Texas	Central	United States
73071	Norman	Oklahoma	Central	United States
60610	Chicago	Illinois	Central	United States
78207	San Antonio	Texas	Central	United States
48127	Dearborn Heights	Michigan	Central	United States
74133	Tulsa	Oklahoma	Central	United States
48237	Oak Park	Michigan	Central	United States
55044	Lakeville	Minnesota	Central	United States
48185	Westland	Michigan	Central	United States
77036	Houston	Texas	Central	United States
60201	Evanston	Illinois	Central	United States
60089	Buffalo Grove	Illinois	Central	United States
48227	Detroit	Michigan	Central	United States
77803	Bryan	Texas	Central	United States
68025	Fremont	Nebraska	Central	United States
60440	Bolingbrook	Illinois	Central	United States
77041	Houston	Texas	Central	United States
63376	Saint Peters	Missouri	Central	United States
52001	Dubuque	Iowa	Central	United States
67846	Garden City	Kansas	Central	United States
55113	Roseville	Minnesota	Central	United States
77506	Pasadena	Texas	Central	United States
47201	Columbus	Indiana	Central	United States
54915	Appleton	Wisconsin	Central	United States
54601	La Crosse	Wisconsin	Central	United States
68701	Norfolk	Nebraska	Central	United States
74403	Muskogee	Oklahoma	Central	United States
76106	Fort Worth	Texas	Central	United States
55369	Maple Grove	Minnesota	Central	United States
60076	Skokie	Illinois	Central	United States
60090	Wheeling	Illinois	Central	United States
52402	Cedar Rapids	Iowa	Central	United States
53186	Waukesha	Wisconsin	Central	United States
77705	Beaumont	Texas	Central	United States
78666	San Marcos	Texas	Central	United States
77489	Missouri City	Texas	Central	United States
48146	Lincoln Park	Michigan	Central	United States
55901	Rochester	Minnesota	Central	United States
48911	Lansing	Michigan	Central	United States
73505	Lawton	Oklahoma	Central	United States
61107	Rockford	Illinois	Central	United States
75081	Dallas	Texas	Central	United States
76051	Grapevine	Texas	Central	United States
60623	Chicago	Illinois	Central	United States
75043	Garland	Texas	Central	United States
76706	Waco	Texas	Central	United States
78041	Laredo	Texas	Central	United States
54880	Superior	Wisconsin	Central	United States
55433	Coon Rapids	Minnesota	Central	United States
58103	Fargo	North Dakota	Central	United States
73034	Edmond	Oklahoma	Central	United States
75034	Frisco	Texas	Central	United States
77301	Conroe	Texas	Central	United States
49423	Holland	Michigan	Central	United States
48858	Mount Pleasant	Michigan	Central	United States
55125	Woodbury	Minnesota	Central	United States
48640	Midland	Michigan	Central	United States
52302	Marion	Iowa	Central	United States
50322	Urbandale	Iowa	Central	United States
76117	Haltom City	Texas	Central	United States
47362	New Castle	Indiana	Central	United States
60188	Carol Stream	Illinois	Central	United States
55407	Minneapolis	Minnesota	Central	United States
\.


--
-- TOC entry 5068 (class 0 OID 16546)
-- Dependencies: 220
-- Data for Name: dim_product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_product (product_id, product_name, category, sub_category) FROM stdin;
OFF-ST-10002214	X-Rack File for Hanging Folders	Office Supplies	Storage
TEC-AC-10001714	Logitech MX Performance Wireless Mouse	Technology	Accessories
TEC-PH-10003171	Plantronics Encore H101 Dual Earpieces Headset	Technology	Phones
TEC-PH-10001300	iKross Bluetooth Portable Keyboard + Cell Phone Stand Holder + Brush for Apple iPhone 5S 5C 5, 4S 4	Technology	Phones
OFF-PA-10001293	Xerox 1946	Office Supplies	Paper
FUR-FU-10000732	Eldon 200 Class Desk Accessories	Furniture	Furnishings
OFF-ST-10001128	Carina Mini System Audio Rack, Model AR050B	Office Supplies	Storage
FUR-FU-10003623	DataProducts Ampli Magnifier Task Lamp, Black,	Furniture	Furnishings
OFF-AP-10000938	Avanti 1.7 Cu. Ft. Refrigerator	Office Supplies	Appliances
OFF-PA-10002195	Xerox 1966	Office Supplies	Paper
OFF-SU-10001218	Fiskars Softgrip Scissors	Office Supplies	Supplies
OFF-PA-10001215	Xerox 1963	Office Supplies	Paper
OFF-BI-10003429	Cardinal HOLDit! Binder Insert Strips,Extra Strips	Office Supplies	Binders
OFF-ST-10004258	Portable Personal File Box	Office Supplies	Storage
FUR-TA-10001039	KI Adjustable-Height Table	Furniture	Tables
OFF-PA-10004353	Southworth 25% Cotton Premium Laser Paper and Envelopes	Office Supplies	Paper
TEC-MA-10002790	NeatDesk Desktop Scanner & Digital Filing System	Technology	Machines
OFF-EN-10003798	Recycled Interoffice Envelopes with Re-Use-A-Seal Closure, 10 x 13	Office Supplies	Envelopes
OFF-AP-10001293	Belkin 8 Outlet Surge Protector	Office Supplies	Appliances
TEC-AC-10004659	Imation Secure+ Hardware Encrypted USB 2.0 Flash Drive; 16GB	Technology	Accessories
OFF-BI-10003529	Avery Round Ring Poly Binders	Office Supplies	Binders
OFF-ST-10003208	Adjustable Depth Letter/Legal Cart	Office Supplies	Storage
OFF-PA-10000520	Xerox 201	Office Supplies	Paper
OFF-ST-10003327	Akro-Mils 12-Gallon Tote	Office Supplies	Storage
OFF-PA-10004239	Xerox 1953	Office Supplies	Paper
OFF-ST-10002574	SAFCO Commercial Wire Shelving, Black	Office Supplies	Storage
TEC-PH-10001817	Wilson Electronics DB Pro Signal Booster	Technology	Phones
OFF-ST-10002406	Pizazz Global Quick File	Office Supplies	Storage
OFF-BI-10003166	GBC Plasticlear Binding Covers	Office Supplies	Binders
FUR-TA-10001307	SAFCO PlanMaster Heigh-Adjustable Drafting Table Base, 43w x 30d x 30-37h, Black	Furniture	Tables
OFF-EN-10003862	Laser & Ink Jet Business Envelopes	Office Supplies	Envelopes
OFF-BI-10003527	Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind	Office Supplies	Binders
OFF-PA-10001745	Wirebound Message Books, 2 7/8" x 5", 3 Forms per Page	Office Supplies	Paper
OFF-AR-10004456	Panasonic KP-4ABK Battery-Operated Pencil Sharpener	Office Supplies	Art
OFF-PA-10000029	Xerox 224	Office Supplies	Paper
OFF-AR-10003405	Dixon My First Ticonderoga Pencil, #2	Office Supplies	Art
OFF-ST-10000129	Fellowes Recycled Storage Drawers	Office Supplies	Storage
FUR-TA-10003569	Bretford CR8500 Series Meeting Room Furniture	Furniture	Tables
FUR-CH-10003817	Global Value Steno Chair, Gray	Furniture	Chairs
OFF-PA-10001593	Xerox 1947	Office Supplies	Paper
OFF-ST-10004804	Belkin 19" Vented Equipment Shelf, Black	Office Supplies	Storage
FUR-TA-10004289	BoxOffice By Design Rectangular and Half-Moon Meeting Room Tables	Furniture	Tables
OFF-SU-10004661	Acme Titanium Bonded Scissors	Office Supplies	Supplies
OFF-BI-10000546	Avery Durable Binders	Office Supplies	Binders
OFF-PA-10000809	Xerox 206	Office Supplies	Paper
OFF-ST-10002485	Rogers Deluxe File Chest	Office Supplies	Storage
OFF-PA-10003424	"While you Were Out" Message Book, One Form per Page	Office Supplies	Paper
OFF-PA-10003936	Xerox 1994	Office Supplies	Paper
OFF-EN-10004483	#10 White Business Envelopes,4 1/8 x 9 1/2	Office Supplies	Envelopes
FUR-TA-10001889	Bush Advantage Collection Racetrack Conference Table	Furniture	Tables
OFF-PA-10000740	Xerox 1982	Office Supplies	Paper
TEC-AC-10003657	Lenovo 17-Key USB Numeric Keypad	Technology	Accessories
OFF-PA-10000955	Southworth 25% Cotton Granite Paper & Envelopes	Office Supplies	Paper
FUR-FU-10002030	Executive Impressions 14" Contract Wall Clock with Quartz Movement	Furniture	Furnishings
TEC-AC-10002305	KeyTronic E03601U1 - Keyboard - Beige	Technology	Accessories
OFF-EN-10003055	Blue String-Tie & Button Interoffice Envelopes, 10 x 13	Office Supplies	Envelopes
OFF-BI-10003650	GBC DocuBind 300 Electric Binding Machine	Office Supplies	Binders
OFF-BI-10002827	Avery Durable Poly Binders	Office Supplies	Binders
OFF-PA-10004733	Things To Do Today Spiral Book	Office Supplies	Paper
OFF-BI-10000605	Acco Pressboard Covers with Storage Hooks, 9 1/2" x 11", Executive Red	Office Supplies	Binders
TEC-AC-10001109	Logitech Trackman Marble Mouse	Technology	Accessories
OFF-ST-10004123	Safco Industrial Wire Shelving System	Office Supplies	Storage
OFF-PA-10003172	Xerox 1996	Office Supplies	Paper
OFF-ST-10002182	Iris 3-Drawer Stacking Bin, Black	Office Supplies	Storage
TEC-AC-10001465	SanDisk Cruzer 64 GB USB Flash Drive	Technology	Accessories
TEC-PH-10001750	Samsung Rugby III	Technology	Phones
FUR-BO-10001972	O'Sullivan 4-Shelf Bookcase in Odessa Pine	Furniture	Bookcases
FUR-FU-10004864	Howard Miller 14-1/2" Diameter Chrome Round Wall Clock	Furniture	Furnishings
OFF-FA-10000585	OIC Bulk Pack Metal Binder Clips	Office Supplies	Fasteners
OFF-BI-10000320	GBC Plastic Binding Combs	Office Supplies	Binders
OFF-AR-10002067	Newell 334	Office Supplies	Art
OFF-PA-10004888	Xerox 217	Office Supplies	Paper
OFF-BI-10001575	GBC Linen Binding Covers	Office Supplies	Binders
OFF-AR-10001026	Sanford Uni-Blazer View Highlighters, Chisel Tip, Yellow	Office Supplies	Art
FUR-TA-10002855	Bevis Round Conference Table Top & Single Column Base	Furniture	Tables
TEC-PH-10003357	Grandstream GXP2100 Mainstream Business Phone	Technology	Phones
FUR-CH-10000229	Global Enterprise Series Seating High-Back Swivel/Tilt Chairs	Furniture	Chairs
OFF-FA-10002815	Staples	Office Supplies	Fasteners
OFF-PA-10002923	Xerox 1942	Office Supplies	Paper
FUR-FU-10003489	Contemporary Borderless Frame	Furniture	Furnishings
OFF-PA-10004609	Xerox 221	Office Supplies	Paper
TEC-CO-10004202	Brother DCP1000 Digital 3 in 1 Multifunction Machine	Technology	Copiers
OFF-PA-10001609	Tops Wirebound Message Log Books	Office Supplies	Paper
TEC-PH-10000576	AT&T 1080 Corded phone	Technology	Phones
OFF-AP-10004336	Conquest 14 Commercial Heavy-Duty Upright Vacuum, Collection System, Accessory Kit	Office Supplies	Appliances
TEC-PH-10002726	netTALK DUO VoIP Telephone Service	Technology	Phones
OFF-PA-10001892	Rediform Wirebound "Phone Memo" Message Book, 11 x 5-3/4	Office Supplies	Paper
TEC-AC-10002718	Belkin Standard 104 key USB Keyboard	Technology	Accessories
FUR-FU-10004586	G.E. Longer-Life Indoor Recessed Floodlight Bulbs	Furniture	Furnishings
FUR-FU-10002597	C-Line Magnetic Cubicle Keepers, Clear Polypropylene	Furniture	Furnishings
FUR-TA-10003469	Balt Split Level Computer Training Table	Furniture	Tables
OFF-ST-10004180	Safco Commercial Shelving	Office Supplies	Storage
OFF-PA-10002986	Xerox 1898	Office Supplies	Paper
FUR-FU-10001185	Advantus Employee of the Month Certificate Frame, 11 x 13-1/2	Furniture	Furnishings
OFF-ST-10001496	Standard Rollaway File with Lock	Office Supplies	Storage
OFF-BI-10004519	GBC DocuBind P100 Manual Binding Machine	Office Supplies	Binders
OFF-AR-10003394	Newell 332	Office Supplies	Art
TEC-AC-10004855	V7 USB Numeric Keypad	Technology	Accessories
FUR-CH-10003379	Global Commerce Series High-Back Swivel/Tilt Chairs	Furniture	Chairs
OFF-AP-10002191	Belkin 8 Outlet SurgeMaster II Gold Surge Protector	Office Supplies	Appliances
OFF-BI-10001679	GBC Instant Index System for Binding Systems	Office Supplies	Binders
FUR-FU-10001473	DAX Wood Document Frame	Furniture	Furnishings
TEC-AC-10001990	Kensington Orbit Wireless Mobile Trackball for PC and Mac	Technology	Accessories
FUR-TA-10002228	Bevis Traditional Conference Table Top, Plinth Base	Furniture	Tables
TEC-AC-10000487	SanDisk Cruzer 4 GB USB Flash Drive	Technology	Accessories
TEC-PH-10004912	Cisco SPA112 2 Port Phone Adapter	Technology	Phones
TEC-AC-10002473	Maxell 4.7GB DVD-R	Technology	Accessories
OFF-AP-10001947	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	Office Supplies	Appliances
OFF-BI-10004410	C-Line Peel & Stick Add-On Filing Pockets, 8-3/4 x 5-1/8, 10/Pack	Office Supplies	Binders
OFF-AP-10001154	Bionaire Personal Warm Mist Humidifier/Vaporizer	Office Supplies	Appliances
OFF-AR-10002704	Boston 1900 Electric Pencil Sharpener	Office Supplies	Art
OFF-BI-10001107	GBC White Gloss Covers, Plain Front	Office Supplies	Binders
OFF-LA-10003923	Alphabetical Labels for Top Tab Filing	Office Supplies	Labels
TEC-AC-10001267	Imation 32GB Pocket Pro USB 3.0 Flash Drive - 32 GB - Black - 1 P ...	Technology	Accessories
OFF-PA-10004100	Xerox 216	Office Supplies	Paper
TEC-PH-10004924	SKILCRAFT Telephone Shoulder Rest, 2" x 6.5" x 2.5", Black	Technology	Phones
OFF-EN-10001219	#10- 4 1/8" x 9 1/2" Security-Tint Envelopes	Office Supplies	Envelopes
OFF-AP-10004136	Kensington 6 Outlet SmartSocket Surge Protector	Office Supplies	Appliances
TEC-PH-10000004	Belkin iPhone and iPad Lightning Cable	Technology	Phones
FUR-TA-10004147	Hon 4060 Series Tables	Furniture	Tables
OFF-BI-10001249	Avery Heavy-Duty EZD View Binder with Locking Rings	Office Supplies	Binders
OFF-PA-10003349	Xerox 1957	Office Supplies	Paper
TEC-AC-10002402	Razer Kraken PRO Over Ear PC and Music Headset	Technology	Accessories
FUR-TA-10003954	Hon 94000 Series Round Tables	Furniture	Tables
FUR-FU-10000260	6" Cubicle Wall Clock, Black	Furniture	Furnishings
OFF-LA-10000248	Avery 52	Office Supplies	Labels
TEC-AC-10003499	Memorex Mini Travel Drive 8 GB USB 2.0 Flash Drive	Technology	Accessories
OFF-BI-10002026	Avery Arch Ring Binders	Office Supplies	Binders
OFF-AP-10000240	Belkin F9G930V10-GRY 9 Outlet Surge	Office Supplies	Appliances
TEC-PH-10002597	Xblue XB-1670-86 X16 Small Office Telephone - Titanium	Technology	Phones
OFF-LA-10003714	Avery 510	Office Supplies	Labels
OFF-ST-10002301	Tennsco Commercial Shelving	Office Supplies	Storage
OFF-PA-10000806	Xerox 1934	Office Supplies	Paper
TEC-AC-10004761	Maxell 4.7GB DVD+RW 3/Pack	Technology	Accessories
FUR-FU-10003664	Electrix Architect's Clamp-On Swing Arm Lamp, Black	Furniture	Furnishings
FUR-FU-10002111	Master Caster Door Stop, Large Brown	Furniture	Furnishings
FUR-CH-10004997	Hon Every-Day Series Multi-Task Chairs	Furniture	Chairs
TEC-AC-10000158	Sony 64GB Class 10 Micro SDHC R40 Memory Card	Technology	Accessories
TEC-PH-10003963	GE 2-Jack Phone Line Splitter	Technology	Phones
OFF-AP-10004980	3M Replacement Filter for Office Air Cleaner for 20' x 33' Room	Office Supplies	Appliances
OFF-AR-10004042	BOSTON Model 1800 Electric Pencil Sharpeners, Putty/Woodgrain	Office Supplies	Art
OFF-PA-10004040	Universal Premium White Copier/Laser Paper (20Lb. and 87 Bright)	Office Supplies	Paper
OFF-AR-10000475	Hunt BOSTON Vista Battery-Operated Pencil Sharpener, Black	Office Supplies	Art
FUR-CH-10001802	Hon Every-Day Chair Series Swivel Task Chairs	Furniture	Chairs
TEC-PH-10002468	Plantronics CS 50-USB - headset - Convertible, Monaural	Technology	Phones
OFF-PA-10001534	Xerox 230	Office Supplies	Paper
OFF-BI-10001132	Acco PRESSTEX Data Binder with Storage Hooks, Dark Blue, 9 1/2" X 11"	Office Supplies	Binders
OFF-PA-10003256	Avery Personal Creations Heavyweight Cards	Office Supplies	Paper
OFF-EN-10001535	Grip Seal Envelopes	Office Supplies	Envelopes
OFF-FA-10000992	Acco Clips to Go Binder Clips, 24 Clips in Two Sizes	Office Supplies	Fasteners
OFF-ST-10002583	Fellowes Neat Ideas Storage Cubes	Office Supplies	Storage
FUR-FU-10004270	Eldon Image Series Desk Accessories, Burgundy	Furniture	Furnishings
OFF-AR-10000380	Hunt PowerHouse Electric Pencil Sharpener, Blue	Office Supplies	Art
OFF-PA-10004621	Xerox 212	Office Supplies	Paper
OFF-LA-10002043	Avery 489	Office Supplies	Labels
FUR-FU-10001085	3M Polarizing Light Filter Sleeves	Furniture	Furnishings
OFF-AR-10003696	Panasonic KP-350BK Electric Pencil Sharpener with Auto Stop	Office Supplies	Art
OFF-FA-10000134	Advantus Push Pins, Aluminum Head	Office Supplies	Fasteners
OFF-LA-10003510	Avery 4027 File Folder Labels for Dot Matrix Printers, 5000 Labels per Box, White	Office Supplies	Labels
FUR-BO-10004218	Bush Heritage Pine Collection 5-Shelf Bookcase, Albany Pine Finish, *Special Order	Furniture	Bookcases
OFF-BI-10004656	Peel & Stick Add-On Corner Pockets	Office Supplies	Binders
TEC-AC-10001114	Microsoft Wireless Mobile Mouse 4000	Technology	Accessories
TEC-PH-10000369	HTC One Mini	Technology	Phones
OFF-PA-10000659	TOPS Carbonless Receipt Book, Four 2-3/4 x 7-1/4 Money Receipts per Page	Office Supplies	Paper
OFF-ST-10001228	Fellowes Personal Hanging Folder Files, Navy	Office Supplies	Storage
OFF-LA-10002195	Avery 481	Office Supplies	Labels
OFF-FA-10003059	Assorted Color Push Pins	Office Supplies	Fasteners
OFF-PA-10001560	Adams Telephone Message Books, 5 1/4” x 11”	Office Supplies	Paper
OFF-LA-10002312	Avery 490	Office Supplies	Labels
OFF-BI-10004632	Ibico Hi-Tech Manual Binding System	Office Supplies	Binders
OFF-BI-10003638	GBC Durable Plastic Covers	Office Supplies	Binders
OFF-BI-10003094	Self-Adhesive Ring Binder Labels	Office Supplies	Binders
OFF-PA-10004519	Spiral Phone Message Books with Labels by Adams	Office Supplies	Paper
OFF-PA-10004355	Xerox 231	Office Supplies	Paper
OFF-PA-10001033	Xerox 1893	Office Supplies	Paper
FUR-CH-10003973	GuestStacker Chair with Chrome Finish Legs	Furniture	Chairs
FUR-CH-10001714	Global Leather & Oak Executive Chair, Burgundy	Furniture	Chairs
TEC-AC-10003911	NETGEAR AC1750 Dual Band Gigabit Smart WiFi Router	Technology	Accessories
OFF-AR-10004956	Newell 33	Office Supplies	Art
OFF-PA-10003591	Southworth 100% Cotton The Best Paper	Office Supplies	Paper
TEC-AC-10004127	SanDisk Cruzer 8 GB USB Flash Drive	Technology	Accessories
OFF-EN-10003040	Quality Park Security Envelopes	Office Supplies	Envelopes
OFF-BI-10002072	Cardinal Slant-D Ring Binders	Office Supplies	Binders
OFF-BI-10002976	ACCOHIDE Binder by Acco	Office Supplies	Binders
TEC-PH-10003691	BlackBerry Q10	Technology	Phones
OFF-AR-10000255	Newell 328	Office Supplies	Art
OFF-EN-10002504	Tyvek  Top-Opening Peel & Seel Envelopes, Plain White	Office Supplies	Envelopes
OFF-BI-10001525	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Executive Red	Office Supplies	Binders
TEC-AC-10004396	Logitech Keyboard K120	Technology	Accessories
TEC-PH-10002660	Nortel Networks T7316 E Nt8 B27	Technology	Phones
OFF-BI-10002867	GBC Recycled Regency Composition Covers	Office Supplies	Binders
FUR-TA-10004442	Riverside Furniture Stanwyck Manor Table Series	Furniture	Tables
OFF-EN-10002592	Peel & Seel Recycled Catalog Envelopes, Brown	Office Supplies	Envelopes
OFF-AR-10000369	Design Ebony Sketching Pencil	Office Supplies	Art
OFF-PA-10000587	Array Parchment Paper, Assorted Colors	Office Supplies	Paper
OFF-ST-10000321	Akro Stacking Bins	Office Supplies	Storage
OFF-AP-10000595	Disposable Triple-Filter Dust Bags	Office Supplies	Appliances
FUR-BO-10003450	Bush Westfield Collection Bookcases, Dark Cherry Finish	Furniture	Bookcases
OFF-BI-10002794	Avery Trapezoid Ring Binder, 3" Capacity, Black, 1040 sheets	Office Supplies	Binders
OFF-PA-10004965	Xerox 1921	Office Supplies	Paper
FUR-FU-10004622	Eldon Advantage Foldable Chair Mats for Low Pile Carpets	Furniture	Furnishings
OFF-PA-10002606	Xerox 1928	Office Supplies	Paper
OFF-AP-10002534	3.6 Cubic Foot Counter Height Office Refrigerator	Office Supplies	Appliances
OFF-ST-10000934	Contico 72"H Heavy-Duty Storage System	Office Supplies	Storage
FUR-CH-10000225	Global Geo Office Task Chair, Gray	Furniture	Chairs
TEC-PH-10001128	Motorola Droid Maxx	Technology	Phones
FUR-TA-10001705	Bush Advantage Collection Round Conference Table	Furniture	Tables
OFF-PA-10003441	Xerox 226	Office Supplies	Paper
TEC-PH-10000923	Belkin SportFit Armband For iPhone 5s/5c, Fuchsia	Technology	Phones
OFF-EN-10000461	#10- 4 1/8" x 9 1/2" Recycled Envelopes	Office Supplies	Envelopes
FUR-FU-10000820	Tensor Brushed Steel Torchiere Floor Lamp	Furniture	Furnishings
TEC-CO-10001449	Hewlett Packard LaserJet 3310 Copier	Technology	Copiers
TEC-AC-10000387	KeyTronic KT800P2 - Keyboard - Black	Technology	Accessories
OFF-LA-10001569	Avery 499	Office Supplies	Labels
TEC-AC-10003095	Logitech G35 7.1-Channel Surround Sound Headset	Technology	Accessories
TEC-PH-10000675	Panasonic KX TS3282B Corded phone	Technology	Phones
OFF-PA-10000552	Xerox 200	Office Supplies	Paper
FUR-FU-10002268	Ultra Door Push Plate	Furniture	Furnishings
OFF-ST-10001809	Fellowes Officeware Wire Shelving	Office Supplies	Storage
OFF-AR-10001547	Newell 311	Office Supplies	Art
OFF-BI-10002949	Prestige Round Ring Binders	Office Supplies	Binders
OFF-PA-10004101	Xerox 1894	Office Supplies	Paper
OFF-BI-10003981	Avery Durable Plastic 1" Binders	Office Supplies	Binders
OFF-BI-10003196	Accohide Poly Flexible Ring Binders	Office Supplies	Binders
OFF-BI-10001989	Premium Transparent Presentation Covers by GBC	Office Supplies	Binders
FUR-CH-10000513	High-Back Leather Manager's Chair	Furniture	Chairs
FUR-FU-10002501	Nu-Dell Executive Frame	Furniture	Furnishings
OFF-BI-10000285	XtraLife ClearVue Slant-D Ring Binders by Cardinal	Office Supplies	Binders
FUR-CH-10003535	Global Armless Task Chair, Royal Blue	Furniture	Chairs
OFF-EN-10003567	Inter-Office Recycled Envelopes, Brown Kraft, Button-String,10" x 13" , 100/Box	Office Supplies	Envelopes
FUR-FU-10002553	Electrix Incandescent Magnifying Lamp, Black	Furniture	Furnishings
OFF-FA-10000936	Acco Hot Clips Clips to Go	Office Supplies	Fasteners
FUR-FU-10003347	Coloredge Poster Frame	Furniture	Furnishings
OFF-PA-10003228	Xerox 1917	Office Supplies	Paper
FUR-CH-10004086	Hon 4070 Series Pagoda Armless Upholstered Stacking Chairs	Furniture	Chairs
FUR-CH-10004289	Global Super Steno Chair	Furniture	Chairs
OFF-AP-10004859	Acco 6 Outlet Guardian Premium Surge Suppressor	Office Supplies	Appliances
FUR-FU-10003026	Eldon Regeneration Recycled Desk Accessories, Black	Furniture	Furnishings
TEC-AC-10002550	Maxell 4.7GB DVD-RW 3/Pack	Technology	Accessories
OFF-ST-10003282	Advantus 10-Drawer Portable Organizer, Chrome Metal Frame, Smoke Drawers	Office Supplies	Storage
OFF-PA-10003845	Xerox 1987	Office Supplies	Paper
OFF-PA-10000477	Xerox 1952	Office Supplies	Paper
OFF-BI-10000494	Acco Economy Flexible Poly Round Ring Binder	Office Supplies	Binders
FUR-CH-10002335	Hon GuestStacker Chair	Furniture	Chairs
OFF-LA-10004484	Avery 476	Office Supplies	Labels
FUR-BO-10000112	Bush Birmingham Collection Bookcase, Dark Cherry	Furniture	Bookcases
TEC-AC-10003038	Kingston Digital DataTraveler 16GB USB 2.0	Technology	Accessories
TEC-AC-10003280	Belkin F8E887 USB Wired Ergonomic Keyboard	Technology	Accessories
OFF-AR-10002952	Stanley Contemporary Battery Pencil Sharpeners	Office Supplies	Art
OFF-BI-10003669	3M Organizer Strips	Office Supplies	Binders
TEC-AC-10002076	Microsoft Natural Keyboard Elite	Technology	Accessories
TEC-PH-10003505	Geemarc AmpliPOWER60	Technology	Phones
OFF-BI-10002071	Fellowes Black Plastic Comb Bindings	Office Supplies	Binders
OFF-AR-10004790	Staples in misc. colors	Office Supplies	Art
FUR-TA-10002356	Bevis Boat-Shaped Conference Table	Furniture	Tables
OFF-BI-10001787	Wilson Jones Four-Pocket Poly Binders	Office Supplies	Binders
OFF-ST-10003442	Eldon Portable Mobile Manager	Office Supplies	Storage
OFF-AR-10003478	Avery Hi-Liter EverBold Pen Style Fluorescent Highlighters, 4/Pack	Office Supplies	Art
OFF-AR-10004441	BIC Brite Liner Highlighters	Office Supplies	Art
OFF-AP-10002118	1.7 Cubic Foot Compact "Cube" Office Refrigerators	Office Supplies	Appliances
OFF-PA-10003823	Xerox 197	Office Supplies	Paper
OFF-LA-10001317	Avery 520	Office Supplies	Labels
FUR-TA-10001866	Bevis Round Conference Room Tables and Bases	Furniture	Tables
TEC-AC-10003023	Logitech G105 Gaming Keyboard	Technology	Accessories
TEC-MA-10003353	Xerox WorkCentre 6505DN Laser Multifunction Printer	Technology	Machines
OFF-BI-10001658	GBC Standard Therm-A-Bind Covers	Office Supplies	Binders
OFF-AR-10001860	BIC Liqua Brite Liner	Office Supplies	Art
FUR-BO-10001601	Sauder Mission Library with Doors, Fruitwood Finish	Furniture	Bookcases
OFF-BI-10001757	Pressboard Hanging Data Binders for Unburst Sheets	Office Supplies	Binders
FUR-FU-10003981	Eldon Wave Desk Accessories	Furniture	Furnishings
TEC-PH-10003885	Cisco SPA508G	Technology	Phones
OFF-FA-10001561	Stockwell Push Pins	Office Supplies	Fasteners
OFF-ST-10000563	Fellowes Bankers Box Stor/Drawer Steel Plus	Office Supplies	Storage
OFF-AR-10000823	Newell 307	Office Supplies	Art
FUR-BO-10004834	Riverside Palais Royal Lawyers Bookcase, Royale Cherry Finish	Furniture	Bookcases
FUR-FU-10000320	OIC Stacking Trays	Furniture	Furnishings
TEC-AC-10001908	Logitech Wireless Headset h800	Technology	Accessories
TEC-AC-10003832	Imation 16GB Mini TravelDrive USB 2.0 Flash Drive	Technology	Accessories
OFF-AP-10000055	Belkin F9S820V06 8 Outlet Surge	Office Supplies	Appliances
OFF-AR-10002804	Faber Castell Col-Erase Pencils	Office Supplies	Art
OFF-AR-10003481	Newell 348	Office Supplies	Art
FUR-BO-10001608	Hon Metal Bookcases, Black	Furniture	Bookcases
OFF-PA-10002222	Xerox Color Copier Paper, 11" x 17", Ream	Office Supplies	Paper
FUR-FU-10002088	Nu-Dell Float Frame 11 x 14 1/2	Furniture	Furnishings
TEC-PH-10001809	Panasonic KX T7736-B Digital phone	Technology	Phones
FUR-FU-10002703	Tenex Traditional Chairmats for Hard Floors, Average Lip, 36" x 48"	Furniture	Furnishings
FUR-FU-10001290	Executive Impressions Supervisor Wall Clock	Furniture	Furnishings
OFF-EN-10001137	#10 Gummed Flap White Envelopes, 100/Box	Office Supplies	Envelopes
TEC-PH-10003012	Nortel Meridian M3904 Professional Digital phone	Technology	Phones
OFF-AP-10001303	Holmes Cool Mist Humidifier for the Whole House with 8-Gallon Output per Day, Extended Life Filter	Office Supplies	Appliances
FUR-FU-10004006	Deflect-o DuraMat Lighweight, Studded, Beveled Mat for Low Pile Carpeting	Furniture	Furnishings
FUR-FU-10001037	DAX Charcoal/Nickel-Tone Document Frame, 5 x 7	Furniture	Furnishings
OFF-LA-10002787	Avery 480	Office Supplies	Labels
TEC-PH-10001557	Pyle PMP37LED	Technology	Phones
OFF-AR-10002221	12 Colored Short Pencils	Office Supplies	Art
FUR-FU-10002191	G.E. Halogen Desk Lamp Bulbs	Furniture	Furnishings
FUR-BO-10003034	O'Sullivan Elevations Bookcase, Cherry Finish	Furniture	Bookcases
FUR-FU-10001196	DAX Cubicle Frames - 8x10	Furniture	Furnishings
OFF-BI-10002012	Wilson Jones Easy Flow II Sheet Lifters	Office Supplies	Binders
OFF-ST-10003816	Fellowes High-Stak Drawer Files	Office Supplies	Storage
TEC-PH-10001448	Anker Astro 15000mAh USB Portable Charger	Technology	Phones
FUR-FU-10002396	DAX Copper Panel Document Frame, 5 x 7 Size	Furniture	Furnishings
OFF-AR-10003651	Newell 350	Office Supplies	Art
OFF-PA-10003036	Black Print Carbonless 8 1/2" x 8 1/4" Rapid Memo Book	Office Supplies	Paper
OFF-PA-10000349	Easy-staple paper	Office Supplies	Paper
FUR-FU-10002963	Master Caster Door Stop, Gray	Furniture	Furnishings
OFF-PA-10000167	Xerox 1925	Office Supplies	Paper
OFF-AP-10000828	Avanti 4.4 Cu. Ft. Refrigerator	Office Supplies	Appliances
OFF-ST-10003479	Eldon Base for stackable storage shelf, platinum	Office Supplies	Storage
FUR-TA-10002958	Bevis Oval Conference Table, Walnut	Furniture	Tables
OFF-EN-10003134	Staple envelope	Office Supplies	Envelopes
OFF-SU-10004115	Acme Stainless Steel Office Snips	Office Supplies	Supplies
TEC-AC-10004666	Maxell iVDR EX 500GB Cartridge	Technology	Accessories
OFF-AR-10004022	Panasonic KP-380BK Classic Electric Pencil Sharpener	Office Supplies	Art
OFF-AP-10003278	Belkin 7-Outlet SurgeMaster Home Series	Office Supplies	Appliances
TEC-AC-10004901	Kensington SlimBlade Notebook Wireless Mouse with Nano Receiver	Technology	Accessories
OFF-ST-10002276	Safco Steel Mobile File Cart	Office Supplies	Storage
OFF-AR-10003338	Eberhard Faber 3 1/2" Golf Pencils	Office Supplies	Art
OFF-PA-10000380	REDIFORM Incoming/Outgoing Call Register, 11" X 8 1/2", 100 Messages	Office Supplies	Paper
FUR-FU-10001935	3M Hangers With Command Adhesive	Furniture	Furnishings
FUR-FU-10001918	C-Line Cubicle Keepers Polyproplyene Holder With Velcro Backings	Furniture	Furnishings
OFF-BI-10003925	Fellowes PB300 Plastic Comb Binding Machine	Office Supplies	Binders
OFF-BI-10002103	Cardinal Slant-D Ring Binder, Heavy Gauge Vinyl	Office Supplies	Binders
OFF-PA-10002259	Geographics Note Cards, Blank, White, 8 1/2" x 11"	Office Supplies	Paper
OFF-PA-10004475	Xerox 1940	Office Supplies	Paper
FUR-TA-10001520	Lesro Sheffield Collection Coffee Table, End Table, Center Table, Corner Table	Furniture	Tables
OFF-BI-10001922	Storex Dura Pro Binders	Office Supplies	Binders
TEC-PH-10002293	Anker 36W 4-Port USB Wall Charger Travel Power Adapter for iPhone 5s 5c 5	Technology	Phones
OFF-AR-10001615	Newell 34	Office Supplies	Art
TEC-PH-10002365	Belkin Grip Candy Sheer Case / Cover for iPhone 5 and 5S	Technology	Phones
OFF-PA-10002615	Ampad Gold Fibre Wirebound Steno Books, 6" x 9", Gregg Ruled	Office Supplies	Paper
FUR-TA-10000688	Chromcraft Bull-Nose Wood Round Conference Table Top, Wood Base	Furniture	Tables
TEC-MA-10003626	Hewlett-Packard Deskjet 6540 Color Inkjet Printer	Technology	Machines
OFF-BI-10004001	GBC Recycled VeloBinder Covers	Office Supplies	Binders
OFF-AP-10002082	Holmes HEPA Air Purifier	Office Supplies	Appliances
OFF-AR-10001725	Boston Home & Office Model 2000 Electric Pencil Sharpeners	Office Supplies	Art
OFF-AR-10001897	Model L Table or Wall-Mount Pencil Sharpener	Office Supplies	Art
OFF-EN-10000927	Jet-Pak Recycled Peel 'N' Seal Padded Mailers	Office Supplies	Envelopes
OFF-ST-10001590	Tenex Personal Project File with Scoop Front Design, Black	Office Supplies	Storage
OFF-PA-10003001	Xerox 1986	Office Supplies	Paper
OFF-PA-10001497	Xerox 1914	Office Supplies	Paper
FUR-FU-10000550	Stacking Trays by OIC	Furniture	Furnishings
FUR-FU-10000723	Deflect-o EconoMat Studded, No Bevel Mat for Low Pile Carpeting	Furniture	Furnishings
OFF-FA-10002988	Ideal Clamps	Office Supplies	Fasteners
OFF-AP-10000576	Belkin 325VA UPS Surge Protector, 6'	Office Supplies	Appliances
OFF-ST-10001097	Office Impressions Heavy Duty Welded Shelving & Multimedia Storage Drawers	Office Supplies	Storage
OFF-AR-10000246	Newell 318	Office Supplies	Art
OFF-AP-10000027	Hoover Commercial SteamVac	Office Supplies	Appliances
FUR-FU-10002759	12-1/2 Diameter Round Wall Clock	Furniture	Furnishings
OFF-BI-10002429	Premier Elliptical Ring Binder, Black	Office Supplies	Binders
TEC-PH-10001254	Jabra BIZ 2300 Duo QD Duo Corded Headset	Technology	Phones
TEC-AC-10002217	Imation Clip USB flash drive - 8 GB	Technology	Accessories
OFF-PA-10004285	Xerox 1959	Office Supplies	Paper
OFF-PA-10004156	Xerox 188	Office Supplies	Paper
OFF-AR-10002257	Eldon Spacemaker Box, Quick-Snap Lid, Clear	Office Supplies	Art
OFF-BI-10000343	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	Office Supplies	Binders
OFF-PA-10001526	Xerox 1949	Office Supplies	Paper
FUR-TA-10003008	Lesro Round Back Collection Coffee Table, End Table	Furniture	Tables
FUR-FU-10001940	Staple-based wall hangings	Furniture	Furnishings
OFF-AR-10003158	Fluorescent Highlighters by Dixon	Office Supplies	Art
TEC-PH-10001552	I Need's 3d Hello Kitty Hybrid Silicone Case Cover for HTC One X 4g with 3d Hello Kitty Stylus Pen Green/pink	Technology	Phones
OFF-PA-10002109	Wirebound Voice Message Log Book	Office Supplies	Paper
TEC-PH-10004093	Panasonic Kx-TS550	Technology	Phones
OFF-BI-10001670	Vinyl Sectional Post Binders	Office Supplies	Binders
OFF-SU-10001664	Acme Office Executive Series Stainless Steel Trimmers	Office Supplies	Supplies
OFF-PA-10001826	Xerox 207	Office Supplies	Paper
TEC-PH-10002824	Jabra SPEAK 410 Multidevice Speakerphone	Technology	Phones
TEC-AC-10000199	Kingston Digital DataTraveler 8GB USB 2.0	Technology	Accessories
FUR-FU-10003773	Eldon Cleatmat Plus Chair Mats for High Pile Carpets	Furniture	Furnishings
FUR-FU-10000305	Tenex V2T-RE Standard Weight Series Chair Mat, 45" x 53", Lip 25" x 12"	Furniture	Furnishings
OFF-PA-10001815	Xerox 1885	Office Supplies	Paper
TEC-PH-10003442	Samsung Replacement EH64AVFWE Premium Headset	Technology	Phones
OFF-EN-10000781	#10- 4 1/8" x 9 1/2" Recycled Envelopes	Office Supplies	Envelopes
OFF-BI-10000545	GBC Ibimaster 500 Manual ProClick Binding System	Office Supplies	Binders
OFF-PA-10000528	Xerox 1981	Office Supplies	Paper
OFF-PA-10003022	Xerox 1992	Office Supplies	Paper
TEC-PH-10001363	Apple iPhone 5S	Technology	Phones
FUR-BO-10001337	O'Sullivan Living Dimensions 2-Shelf Bookcases	Furniture	Bookcases
OFF-PA-10001736	Xerox 1880	Office Supplies	Paper
OFF-BI-10002557	Presstex Flexible Ring Binders	Office Supplies	Binders
FUR-CH-10004495	Global Leather and Oak Executive Chair, Black	Furniture	Chairs
OFF-PA-10001846	Xerox 1899	Office Supplies	Paper
FUR-TA-10001768	Hon Racetrack Conference Tables	Furniture	Tables
TEC-AC-10003237	Memorex Micro Travel Drive 4 GB	Technology	Accessories
TEC-MA-10002981	I.R.I.S IRISCard Anywhere 5 Card Scanner	Technology	Machines
OFF-BI-10002225	Square Ring Data Binders, Rigid 75 Pt. Covers, 11" x 14-7/8"	Office Supplies	Binders
TEC-PH-10004977	GE 30524EE4	Technology	Phones
FUR-CH-10002758	Hon Deluxe Fabric Upholstered Stacking Chairs, Squared Back	Furniture	Chairs
OFF-AR-10000799	Col-Erase Pencils with Erasers	Office Supplies	Art
OFF-LA-10004345	Avery 493	Office Supplies	Labels
OFF-AR-10004582	BIC Brite Liner Grip Highlighters	Office Supplies	Art
TEC-PH-10002415	Polycom VoiceStation 500 Conference phone	Technology	Phones
OFF-PA-10003641	Xerox 1909	Office Supplies	Paper
FUR-FU-10003975	Eldon Advantage Chair Mats for Low to Medium Pile Carpets	Furniture	Furnishings
FUR-FU-10003194	Eldon Expressions Desk Accessory, Wood Pencil Holder, Oak	Furniture	Furnishings
OFF-SU-10000381	Acme Forged Steel Scissors with Black Enamel Handles	Office Supplies	Supplies
FUR-FU-10002456	Master Caster Door Stop, Large Neon Orange	Furniture	Furnishings
TEC-PH-10001835	Jawbone JAMBOX Wireless Bluetooth Speaker	Technology	Phones
OFF-PA-10000213	Xerox 198	Office Supplies	Paper
OFF-PA-10000357	White Dual Perf Computer Printout Paper, 2700 Sheets, 1 Part, Heavyweight, 20 lbs., 14 7/8 x 11	Office Supplies	Paper
OFF-PA-10004327	Xerox 1911	Office Supplies	Paper
OFF-ST-10000885	Fellowes Desktop Hanging File Manager	Office Supplies	Storage
OFF-AR-10003631	Staples in misc. colors	Office Supplies	Art
OFF-AR-10002656	Sanford Liquid Accent Highlighters	Office Supplies	Art
TEC-AC-10003614	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 10/Pack	Technology	Accessories
OFF-ST-10003656	Safco Industrial Wire Shelving	Office Supplies	Storage
OFF-ST-10003692	Recycled Steel Personal File for Hanging File Folders	Office Supplies	Storage
OFF-SU-10001935	Staple remover	Office Supplies	Supplies
OFF-PA-10002120	Xerox 1889	Office Supplies	Paper
OFF-AR-10004078	Newell 312	Office Supplies	Art
TEC-PH-10002624	Samsung Galaxy S4 Mini	Technology	Phones
OFF-EN-10001532	Brown Kraft Recycled Envelopes	Office Supplies	Envelopes
OFF-AP-10002403	Acco Smartsocket Color-Coded Six-Outlet AC Adapter Model Surge Protectors	Office Supplies	Appliances
OFF-LA-10004425	Staple-on labels	Office Supplies	Labels
OFF-BI-10000145	Zipper Ring Binder Pockets	Office Supplies	Binders
OFF-BI-10002414	GBC ProClick Spines for 32-Hole Punch	Office Supplies	Binders
FUR-TA-10004915	Office Impressions End Table, 20-1/2"H x 24"W x 20"D	Furniture	Tables
OFF-LA-10000262	Avery 494	Office Supplies	Labels
FUR-TA-10003748	Bevis 36 x 72 Conference Tables	Furniture	Tables
OFF-BI-10001071	GBC ProClick Punch Binding System	Office Supplies	Binders
OFF-ST-10004950	Acco Perma 3000 Stacking Storage Drawers	Office Supplies	Storage
TEC-AC-10000474	Kensington Expert Mouse Optical USB Trackball for PC or Mac	Technology	Accessories
OFF-BI-10001359	GBC DocuBind TL300 Electric Binding System	Office Supplies	Binders
OFF-AP-10002518	Kensington 7 Outlet MasterPiece Power Center	Office Supplies	Appliances
FUR-CH-10000785	Global Ergonomic Managers Chair	Furniture	Chairs
FUR-FU-10004665	3M Polarizing Task Lamp with Clamp Arm, Light Gray	Furniture	Furnishings
FUR-FU-10004020	Advantus Panel Wall Acrylic Frame	Furniture	Furnishings
OFF-ST-10003058	Eldon Mobile Mega Data Cart  Mega Stackable  Add-On Trays	Office Supplies	Storage
FUR-CH-10001146	Global Value Mid-Back Manager's Chair, Gray	Furniture	Chairs
TEC-AC-10001432	Enermax Aurora Lite Keyboard	Technology	Accessories
OFF-ST-10000877	Recycled Steel Personal File for Standard File Folders	Office Supplies	Storage
TEC-PH-10003095	Samsung HM1900 Bluetooth Headset	Technology	Phones
TEC-AC-10000990	Imation Bio 2GB USB Flash Drive Imation Corp	Technology	Accessories
TEC-MA-10003066	Wasp CCD Handheld Bar Code Reader	Technology	Machines
FUR-FU-10000193	Tenex Chairmats For Use with Hard Floors	Furniture	Furnishings
TEC-PH-10004531	OtterBox Commuter Series Case - iPhone 5 & 5s	Technology	Phones
OFF-BI-10003876	Green Canvas Binder for 8-1/2" x 14" Sheets	Office Supplies	Binders
OFF-ST-10000615	SimpliFile Personal File, Black Granite, 15w x 6-15/16d x 11-1/4h	Office Supplies	Storage
OFF-PA-10000308	Xerox 1901	Office Supplies	Paper
FUR-FU-10004848	Howard Miller 13-3/4" Diameter Brushed Chrome Round Wall Clock	Furniture	Furnishings
OFF-AP-10000179	Honeywell Enviracaire Portable HEPA Air Cleaner for up to 10 x 16 Room	Office Supplies	Appliances
TEC-CO-10001943	Canon PC-428 Personal Copier	Technology	Copiers
FUR-TA-10004086	KI Adjustable-Height Table	Furniture	Tables
FUR-CH-10001482	Office Star - Mesh Screen back chair with Vinyl seat	Furniture	Chairs
OFF-LA-10003498	Avery 475	Office Supplies	Labels
OFF-FA-10000304	Advantus Push Pins	Office Supplies	Fasteners
OFF-LA-10000305	Avery 495	Office Supplies	Labels
OFF-PA-10000474	Easy-staple paper	Office Supplies	Paper
FUR-FU-10001986	Dana Fluorescent Magnifying Lamp, White, 36"	Furniture	Furnishings
TEC-PH-10004614	AT&T 841000 Phone	Technology	Phones
OFF-PA-10004041	It's Hot Message Books with Stickers, 2 3/4" x 5"	Office Supplies	Paper
TEC-AC-10004633	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 3/Pack	Technology	Accessories
OFF-FA-10002676	Colored Push Pins	Office Supplies	Fasteners
FUR-CH-10000665	Global Airflow Leather Mesh Back Chair, Black	Furniture	Chairs
TEC-PH-10000148	Cyber Acoustics AC-202b Speech Recognition Stereo Headset	Technology	Phones
FUR-TA-10004256	Bretford “Just In Time” Height-Adjustable Multi-Task Work Tables	Furniture	Tables
TEC-AC-10002331	Maxell 74 Minute CDR, 10/Pack	Technology	Accessories
OFF-EN-10001141	Manila Recycled Extra-Heavyweight Clasp Envelopes, 6" x 9"	Office Supplies	Envelopes
FUR-TA-10000849	Bevis Rectangular Conference Tables	Furniture	Tables
TEC-AC-10001635	KeyTronic KT400U2 - Keyboard - Black	Technology	Accessories
OFF-PA-10002479	Xerox 4200 Series MultiUse Premium Copy Paper (20Lb. and 84 Bright)	Office Supplies	Paper
OFF-EN-10002831	Tyvek  Top-Opening Peel & Seel  Envelopes, Gray	Office Supplies	Envelopes
FUR-FU-10003849	DAX Metal Frame, Desktop, Stepped-Edge	Furniture	Furnishings
FUR-CH-10004675	Lifetime Advantage Folding Chairs, 4/Carton	Furniture	Chairs
TEC-PH-10004188	OtterBox Commuter Series Case - Samsung Galaxy S4	Technology	Phones
OFF-LA-10003930	Dot Matrix Printer Tape Reel Labels, White, 5000/Box	Office Supplies	Labels
OFF-BI-10004002	Wilson Jones International Size A4 Ring Binders	Office Supplies	Binders
OFF-PA-10000069	TOPS 4 x 6 Fluorescent Color Memo Sheets, 500 Sheets per Pack	Office Supplies	Paper
FUR-FU-10000175	DAX Wood Document Frame.	Furniture	Furnishings
FUR-TA-10001539	Chromcraft Rectangular Conference Tables	Furniture	Tables
TEC-PH-10002817	RCA ViSYS 25425RE1 Corded phone	Technology	Phones
OFF-PA-10000595	Xerox 1929	Office Supplies	Paper
FUR-FU-10003691	Eldon Image Series Desk Accessories, Ebony	Furniture	Furnishings
OFF-BI-10001617	GBC Wire Binding Combs	Office Supplies	Binders
OFF-PA-10001125	Xerox 1988	Office Supplies	Paper
OFF-FA-10003472	Bagged Rubber Bands	Office Supplies	Fasteners
OFF-ST-10001272	Mini 13-1/2 Capacity Data Binder Rack, Pearl	Office Supplies	Storage
TEC-MA-10003674	Hewlett-Packard Deskjet 5550 Printer	Technology	Machines
OFF-FA-10003021	Staples	Office Supplies	Fasteners
FUR-CH-10002320	Hon Pagoda Stacking Chairs	Furniture	Chairs
OFF-FA-10000611	Binder Clips by OIC	Office Supplies	Fasteners
OFF-AR-10003179	Dixon Ticonderoga Core-Lock Colored Pencils	Office Supplies	Art
TEC-PH-10002350	Apple EarPods with Remote and Mic	Technology	Phones
FUR-BO-10004409	Safco Value Mate Series Steel Bookcases, Baked Enamel Finish on Steel, Gray	Furniture	Bookcases
OFF-PA-10002005	Xerox 225	Office Supplies	Paper
TEC-PH-10004536	Avaya 5420 Digital phone	Technology	Phones
OFF-ST-10001490	Hot File 7-Pocket, Floor Stand	Office Supplies	Storage
OFF-AP-10000891	Kensington 7 Outlet MasterPiece HOMEOFFICE Power Control Center	Office Supplies	Appliances
OFF-BI-10001524	GBC Premium Transparent Covers with Diagonal Lined Pattern	Office Supplies	Binders
OFF-BI-10004364	Storex Dura Pro Binders	Office Supplies	Binders
OFF-ST-10001321	Decoflex Hanging Personal Folder File, Blue	Office Supplies	Storage
OFF-BI-10003291	Wilson Jones Leather-Like Binders with DublLock Round Rings	Office Supplies	Binders
FUR-BO-10004709	Bush Westfield Collection Bookcases, Medium Cherry Finish	Furniture	Bookcases
OFF-BI-10002799	SlimView Poly Binder, 3/8"	Office Supplies	Binders
FUR-FU-10003553	Howard Miller 13-1/2" Diameter Rosebrook Wall Clock	Furniture	Furnishings
TEC-CO-10003763	Canon PC1060 Personal Laser Copier	Technology	Copiers
FUR-FU-10000206	GE General Purpose, Extra Long Life, Showcase & Floodlight Incandescent Bulbs	Furniture	Furnishings
OFF-EN-10002986	#10-4 1/8" x 9 1/2" Premium Diagonal Seam Envelopes	Office Supplies	Envelopes
FUR-FU-10001025	Eldon Imàge Series Desk Accessories, Clear	Furniture	Furnishings
OFF-BI-10001718	GBC DocuBind P50 Personal Binding Machine	Office Supplies	Binders
TEC-PH-10002890	AT&T 17929 Lendline Telephone	Technology	Phones
OFF-FA-10003485	Staples	Office Supplies	Fasteners
OFF-BI-10002133	Wilson Jones Elliptical Ring 3 1/2" Capacity Binders, 800 sheets	Office Supplies	Binders
OFF-PA-10001569	Xerox 232	Office Supplies	Paper
OFF-BI-10003314	Tuff Stuff Recycled Round Ring Binders	Office Supplies	Binders
OFF-AR-10002255	Newell 346	Office Supplies	Art
FUR-FU-10003878	Linden 10" Round Wall Clock, Black	Furniture	Furnishings
OFF-AP-10002651	Hoover Upright Vacuum With Dirt Cup	Office Supplies	Appliances
OFF-BI-10001597	Wilson Jones Ledger-Size, Piano-Hinge Binder, 2", Blue	Office Supplies	Binders
OFF-BI-10004600	Ibico Ibimaster 300 Manual Binding System	Office Supplies	Binders
FUR-FU-10001424	Dax Clear Box Frame	Furniture	Furnishings
FUR-FU-10003806	Tenex Chairmat w/ Average Lip, 45" x 53"	Furniture	Furnishings
OFF-AR-10003183	Avery Fluorescent Highlighter Four-Color Set	Office Supplies	Art
OFF-BI-10004140	Avery Non-Stick Binders	Office Supplies	Binders
OFF-AR-10004602	Boston KS Multi-Size Manual Pencil Sharpener	Office Supplies	Art
OFF-SU-10003567	Stiletto Hand Letter Openers	Office Supplies	Supplies
FUR-FU-10001057	Tensor Track Tree Floor Lamp	Furniture	Furnishings
FUR-FU-10000758	DAX Natural Wood-Tone Poster Frame	Furniture	Furnishings
TEC-AC-10004353	Hypercom P1300 Pinpad	Technology	Accessories
OFF-BI-10004584	GBC ProClick 150 Presentation Binding System	Office Supplies	Binders
TEC-PH-10002564	OtterBox Defender Series Case - Samsung Galaxy S4	Technology	Phones
OFF-BI-10000301	GBC Instant Report Kit	Office Supplies	Binders
OFF-ST-10002011	Smead Adjustable Mobile File Trolley with Lockable Top	Office Supplies	Storage
OFF-BI-10001543	GBC VeloBinder Manual Binding System	Office Supplies	Binders
OFF-AR-10000634	Newell 320	Office Supplies	Art
OFF-EN-10003296	Tyvek Side-Opening Peel & Seel Expanding Envelopes	Office Supplies	Envelopes
FUR-FU-10000023	Eldon Wave Desk Accessories	Furniture	Furnishings
TEC-PH-10003215	Jackery Bar Premium Fast-charging Portable Charger	Technology	Phones
OFF-PA-10001804	Xerox 195	Office Supplies	Paper
OFF-SU-10004498	Martin-Yale Premier Letter Opener	Office Supplies	Supplies
OFF-AR-10001958	Stanley Bostitch Contemporary Electric Pencil Sharpeners	Office Supplies	Art
TEC-AC-10002323	SanDisk Ultra 32 GB MicroSDHC Class 10 Memory Card	Technology	Accessories
OFF-BI-10004182	Economy Binders	Office Supplies	Binders
FUR-FU-10004597	Eldon Cleatmat Chair Mats for Medium Pile Carpets	Furniture	Furnishings
FUR-CH-10004287	SAFCO Arco Folding Chair	Furniture	Chairs
OFF-BI-10004094	GBC Standard Plastic Binding Systems Combs	Office Supplies	Binders
OFF-PA-10000418	Xerox 189	Office Supplies	Paper
OFF-LA-10001982	Smead Alpha-Z Color-Coded Name Labels First Letter Starter Set	Office Supplies	Labels
OFF-BI-10000756	Storex DuraTech Recycled Plastic Frosted Binders	Office Supplies	Binders
OFF-AR-10001315	Newell 310	Office Supplies	Art
TEC-PH-10001336	Digium D40 VoIP phone	Technology	Phones
OFF-ST-10001837	SAFCO Mobile Desk Side File, Wire Frame	Office Supplies	Storage
TEC-AC-10001552	Logitech K350 2.4Ghz Wireless Keyboard	Technology	Accessories
OFF-PA-10003724	Wirebound Message Book, 4 per Page	Office Supplies	Paper
OFF-BI-10000977	Ibico Plastic Spiral Binding Combs	Office Supplies	Binders
FUR-FU-10000010	DAX Value U-Channel Document Frames, Easel Back	Furniture	Furnishings
OFF-FA-10000735	Staples	Office Supplies	Fasteners
TEC-PH-10002789	LG Exalt	Technology	Phones
FUR-BO-10003272	O'Sullivan Living Dimensions 5-Shelf Bookcases	Furniture	Bookcases
OFF-PA-10002230	Xerox 1897	Office Supplies	Paper
OFF-LA-10002762	Avery 485	Office Supplies	Labels
TEC-MA-10004241	Star Micronics TSP800 TSP847IIU Receipt Printer	Technology	Machines
OFF-BI-10001628	Acco Data Flex Cable Posts For Top & Bottom Load Binders, 6" Capacity	Office Supplies	Binders
OFF-ST-10001558	Acco Perma 4000 Stacking Storage Drawers	Office Supplies	Storage
OFF-BI-10002003	Ibico Presentation Index for Binding Systems	Office Supplies	Binders
OFF-BI-10004141	Insertable Tab Indexes For Data Binders	Office Supplies	Binders
FUR-FU-10004188	Luxo Professional Combination Clamp-On Lamps	Furniture	Furnishings
FUR-FU-10001588	Deflect-o SuperTray Unbreakable Stackable Tray, Letter, Black	Furniture	Furnishings
OFF-FA-10001332	Acco Banker's Clasps, 5 3/4"-Long	Office Supplies	Fasteners
FUR-CH-10000015	Hon Multipurpose Stacking Arm Chairs	Furniture	Chairs
FUR-BO-10004360	Rush Hierlooms Collection Rich Wood Bookcases	Furniture	Bookcases
TEC-CO-10001571	Sharp 1540cs Digital Laser Copier	Technology	Copiers
OFF-FA-10000254	Sterling Rubber Bands by Alliance	Office Supplies	Fasteners
FUR-CH-10000863	Novimex Swivel Fabric Task Chair	Furniture	Chairs
FUR-FU-10000293	Eldon Antistatic Chair Mats for Low to Medium Pile Carpets	Furniture	Furnishings
OFF-SU-10001225	Staple remover	Office Supplies	Supplies
TEC-AC-10000109	Sony Micro Vault Click 16 GB USB 2.0 Flash Drive	Technology	Accessories
OFF-BI-10001196	Avery Flip-Chart Easel Binder, Black	Office Supplies	Binders
OFF-AP-10002311	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	Office Supplies	Appliances
OFF-BI-10004970	ACCOHIDE 3-Ring Binder, Blue, 1"	Office Supplies	Binders
OFF-AR-10001468	Sanford Prismacolor Professional Thick Lead Art Pencils, 36-Color Set	Office Supplies	Art
FUR-BO-10004467	Bestar Classic Bookcase	Furniture	Bookcases
TEC-PH-10002200	Aastra 6757i CT Wireless VoIP phone	Technology	Phones
FUR-FU-10003930	Howard Miller 12-3/4 Diameter Accuwave DS  Wall Clock	Furniture	Furnishings
OFF-PA-10000697	TOPS Voice Message Log Book, Flash Format	Office Supplies	Paper
OFF-BI-10004828	GBC Poly Designer Binding Covers	Office Supplies	Binders
OFF-PA-10001725	Xerox 1892	Office Supplies	Paper
OFF-BI-10003091	GBC DocuBind TL200 Manual Binding Machine	Office Supplies	Binders
FUR-FU-10003247	36X48 HARDFLOOR CHAIRMAT	Furniture	Furnishings
OFF-FA-10002975	Staples	Office Supplies	Fasteners
OFF-ST-10000585	Economy Rollaway Files	Office Supplies	Storage
OFF-AR-10002578	Newell 335	Office Supplies	Art
OFF-BI-10000831	Storex Flexible Poly Binders with Double Pockets	Office Supplies	Binders
FUR-CH-10003298	Office Star - Contemporary Task Swivel chair with Loop Arms, Charcoal	Furniture	Chairs
TEC-AC-10001772	Memorex Mini Travel Drive 16 GB USB 2.0 Flash Drive	Technology	Accessories
OFF-PA-10001184	Xerox 1903	Office Supplies	Paper
OFF-PA-10003790	Xerox 1991	Office Supplies	Paper
TEC-PH-10001051	HTC One	Technology	Phones
TEC-PH-10002447	AT&T CL83451 4-Handset Telephone	Technology	Phones
OFF-BI-10002954	Newell 3-Hole Punched Plastic Slotted Magazine Holders for Binders	Office Supplies	Binders
TEC-PH-10001795	ClearOne CHATAttach 160 - speaker phone	Technology	Phones
OFF-ST-10000060	Fellowes Bankers Box Staxonsteel Drawer File/Stacking System	Office Supplies	Storage
TEC-MA-10002109	HP Officejet Pro 8600 e-All-In-One Printer, Copier, Scanner, Fax	Technology	Machines
OFF-LA-10004093	Avery 486	Office Supplies	Labels
TEC-PH-10003811	Jabra Supreme Plus Driver Edition Headset	Technology	Phones
FUR-FU-10002116	Tenex Carpeted, Granite-Look or Clear Contemporary Contour Shape Chair Mats	Furniture	Furnishings
FUR-FU-10003464	Seth Thomas 8 1/2" Cubicle Clock	Furniture	Furnishings
OFF-PA-10001838	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 300/Messages	Office Supplies	Paper
OFF-PA-10003134	Xerox 1937	Office Supplies	Paper
OFF-PA-10001289	White Computer Printout Paper by Universal	Office Supplies	Paper
FUR-CH-10001854	Office Star - Professional Matrix Back Chair with 2-to-1 Synchro Tilt and Mesh Fabric Seat	Furniture	Chairs
TEC-PH-10004539	Wireless Extenders zBoost YX545 SOHO Signal Booster	Technology	Phones
OFF-PA-10003953	Xerox 218	Office Supplies	Paper
TEC-PH-10004042	ClearOne Communications CHAT 70 OC Speaker Phone	Technology	Phones
TEC-PH-10004345	Cisco SPA 502G IP Phone	Technology	Phones
OFF-LA-10000134	Avery 511	Office Supplies	Labels
FUR-CH-10000422	Global Highback Leather Tilter in Burgundy	Furniture	Chairs
TEC-PH-10000526	Vtech CS6719	Technology	Phones
FUR-CH-10002017	SAFCO Optional Arm Kit for Workspace Cribbage Stacking Chair	Furniture	Chairs
FUR-FU-10003039	Howard Miller 11-1/2" Diameter Grantwood Wall Clock	Furniture	Furnishings
FUR-CH-10001215	Global Troy Executive Leather Low-Back Tilter	Furniture	Chairs
TEC-AC-10000844	Logitech Gaming G510s - Keyboard	Technology	Accessories
OFF-AP-10003842	Euro-Pro Shark Turbo Vacuum	Office Supplies	Appliances
OFF-PA-10001970	Xerox 1881	Office Supplies	Paper
OFF-BI-10001308	GBC Standard Plastic Binding Systems' Combs	Office Supplies	Binders
OFF-BI-10000666	Surelock Post Binders	Office Supplies	Binders
OFF-ST-10002205	File Shuttle I and Handi-File	Office Supplies	Storage
FUR-FU-10004091	Howard Miller 13" Diameter Goldtone Round Wall Clock	Furniture	Furnishings
OFF-AP-10003040	Fellowes 8 Outlet Superior Workstation Surge Protector w/o Phone/Fax/Modem Protection	Office Supplies	Appliances
FUR-BO-10002824	Bush Mission Pointe Library	Furniture	Bookcases
OFF-FA-10002280	Advantus Plastic Paper Clips	Office Supplies	Fasteners
FUR-CH-10004875	Harbour Creations 67200 Series Stacking Chairs	Furniture	Chairs
TEC-AC-10001013	Logitech ClearChat Comfort/USB Headset H390	Technology	Accessories
FUR-FU-10002671	Electrix 20W Halogen Replacement Bulb for Zoom-In Desk Lamp	Furniture	Furnishings
OFF-ST-10000689	Fellowes Strictly Business Drawer File, Letter/Legal Size	Office Supplies	Storage
OFF-AR-10004707	Staples in misc. colors	Office Supplies	Art
FUR-CH-10000988	Hon Olson Stacker Stools	Furniture	Chairs
FUR-FU-10000222	Seth Thomas 16" Steel Case Clock	Furniture	Furnishings
OFF-ST-10001522	Gould Plastics 18-Pocket Panel Bin, 34w x 5-1/4d x 20-1/2h	Office Supplies	Storage
OFF-BI-10004209	Fellowes Twister Kit, Gray/Clear, 3/pkg	Office Supplies	Binders
OFF-PA-10003302	Xerox 1906	Office Supplies	Paper
FUR-FU-10000308	Deflect-o Glass Clear Studded Chair Mats	Furniture	Furnishings
TEC-PH-10001527	Plantronics MX500i Earset	Technology	Phones
OFF-AR-10002135	Boston Heavy-Duty Trimline Electric Pencil Sharpeners	Office Supplies	Art
TEC-AC-10001314	Case Logic 2.4GHz Wireless Keyboard	Technology	Accessories
OFF-AR-10001221	Dixon Ticonderoga Erasable Colored Pencil Set, 12-Color	Office Supplies	Art
OFF-ST-10000532	Advantus Rolling Drawer Organizers	Office Supplies	Storage
TEC-PH-10001615	AT&T CL82213	Technology	Phones
OFF-BI-10004738	Flexible Leather- Look Classic Collection Ring Binder	Office Supplies	Binders
OFF-PA-10000605	Xerox 1950	Office Supplies	Paper
OFF-BI-10002412	Wilson Jones “Snap” Scratch Pad Binder Tool for Ring Binders	Office Supplies	Binders
TEC-PH-10003437	Blue Parrot B250XT Professional Grade Wireless Bluetooth Headset with	Technology	Phones
OFF-AP-10000026	Tripp Lite Isotel 6 Outlet Surge Protector with Fax/Modem Protection	Office Supplies	Appliances
FUR-CH-10004698	Padded Folding Chairs, Black, 4/Carton	Furniture	Chairs
FUR-TA-10001676	Hon 61000 Series Interactive Training Tables	Furniture	Tables
OFF-BI-10004492	Tuf-Vin Binders	Office Supplies	Binders
OFF-BI-10001267	Universal Recycled Hanging Pressboard Report Binders, Letter Size	Office Supplies	Binders
OFF-PA-10000174	Message Book, Wirebound, Four 5 1/2" X 4" Forms/Pg., 200 Dupl. Sets/Book	Office Supplies	Paper
OFF-ST-10004186	Stur-D-Stor Shelving, Vertical 5-Shelf: 72"H x 36"W x 18 1/2"D	Office Supplies	Storage
OFF-PA-10000289	Xerox 213	Office Supplies	Paper
OFF-LA-10001771	Avery 513	Office Supplies	Labels
OFF-ST-10004459	Tennsco Single-Tier Lockers	Office Supplies	Storage
FUR-FU-10000719	DAX Cubicle Frames, 8-1/2 x 11	Furniture	Furnishings
OFF-AP-10001205	Belkin 5 Outlet SurgeMaster Power Centers	Office Supplies	Appliances
TEC-MA-10001972	Okidata C331dn Printer	Technology	Machines
OFF-ST-10002743	SAFCO Boltless Steel Shelving	Office Supplies	Storage
TEC-AC-10003198	Enermax Acrylux Wireless Keyboard	Technology	Accessories
OFF-LA-10000973	Avery 502	Office Supplies	Labels
OFF-LA-10004853	Avery 483	Office Supplies	Labels
OFF-BI-10004965	Ibico Covers for Plastic or Wire Binding Elements	Office Supplies	Binders
OFF-AR-10002987	Prismacolor Color Pencil Set	Office Supplies	Art
FUR-FU-10000246	Aluminum Document Frame	Furniture	Furnishings
OFF-AR-10001868	Prang Dustless Chalk Sticks	Office Supplies	Art
OFF-LA-10003537	Avery 515	Office Supplies	Labels
TEC-AC-10003610	Logitech Illuminated - Keyboard	Technology	Accessories
OFF-AP-10004532	Kensington 6 Outlet Guardian Standard Surge Protector	Office Supplies	Appliances
OFF-PA-10001295	Computer Printout Paper with Letter-Trim Perforations	Office Supplies	Paper
OFF-PA-10002250	Things To Do Today Pad	Office Supplies	Paper
OFF-BI-10003305	Avery Hanging File Binders	Office Supplies	Binders
TEC-PH-10004447	Toshiba IPT2010-SD IP Telephone	Technology	Phones
TEC-PH-10001433	Cisco Small Business SPA 502G VoIP phone	Technology	Phones
FUR-CH-10002126	Hon Deluxe Fabric Upholstered Stacking Chairs	Furniture	Chairs
OFF-ST-10000649	Hanging Personal Folder File	Office Supplies	Storage
OFF-PA-10003883	Message Book, Phone, Wirebound Standard Line Memo, 2 3/4" X 5"	Office Supplies	Paper
TEC-PH-10001580	Logitech Mobile Speakerphone P710e - speaker phone	Technology	Phones
TEC-PH-10004896	Nokia Lumia 521 (T-Mobile)	Technology	Phones
OFF-AP-10001563	Belkin Premiere Surge Master II 8-outlet surge protector	Office Supplies	Appliances
OFF-BI-10002393	Binder Posts	Office Supplies	Binders
FUR-CH-10001545	Hon Comfortask Task/Swivel Chairs	Furniture	Chairs
OFF-PA-10002586	Xerox 1970	Office Supplies	Paper
OFF-AR-10001915	Peel-Off China Markers	Office Supplies	Art
OFF-AR-10003217	Newell 316	Office Supplies	Art
OFF-BI-10001634	Wilson Jones Active Use Binders	Office Supplies	Binders
OFF-AP-10004785	Holmes Replacement Filter for HEPA Air Cleaner, Medium Room	Office Supplies	Appliances
OFF-FA-10003467	Alliance Big Bands Rubber Bands, 12/Pack	Office Supplies	Fasteners
TEC-PH-10002496	Cisco SPA301	Technology	Phones
TEC-PH-10002185	QVS USB Car Charger 2-Port 2.1Amp for iPod/iPhone/iPad/iPad 2/iPad 3	Technology	Phones
OFF-ST-10003455	Tenex File Box, Personal Filing Tote with Lid, Black	Office Supplies	Storage
OFF-AR-10002445	SANFORD Major Accent Highlighters	Office Supplies	Art
TEC-PH-10002103	Jabra SPEAK 410	Technology	Phones
OFF-BI-10000404	Avery Printable Repositionable Plastic Tabs	Office Supplies	Binders
OFF-AR-10000657	Binney & Smith inkTank Desk Highlighter, Chisel Tip, Yellow, 12/Box	Office Supplies	Art
TEC-PH-10000560	Samsung Galaxy S III - 16GB - pebble blue (T-Mobile)	Technology	Phones
OFF-EN-10002600	Redi-Strip #10 Envelopes, 4 1/8 x 9 1/2	Office Supplies	Envelopes
FUR-CH-10002372	Office Star - Ergonomically Designed Knee Chair	Furniture	Chairs
FUR-BO-10003965	O'Sullivan Manor Hill 2-Door Library in Brianna Oak	Furniture	Bookcases
OFF-EN-10004955	Fashion Color Clasp Envelopes	Office Supplies	Envelopes
TEC-AC-10002926	Logitech Wireless Marathon Mouse M705	Technology	Accessories
OFF-BI-10000632	Satellite Sectional Post Binders	Office Supplies	Binders
OFF-FA-10004854	Vinyl Coated Wire Paper Clips in Organizer Box, 800/Box	Office Supplies	Fasteners
OFF-AP-10001058	Sanyo 2.5 Cubic Foot Mid-Size Office Refrigerators	Office Supplies	Appliances
OFF-PA-10002377	Xerox 1916	Office Supplies	Paper
OFF-AR-10001954	Newell 331	Office Supplies	Art
OFF-ST-10000078	Tennsco 6- and 18-Compartment Lockers	Office Supplies	Storage
FUR-CH-10002084	Hon Mobius Operator's Chair	Furniture	Chairs
OFF-BI-10003656	Fellowes PB200 Plastic Comb Binding Machine	Office Supplies	Binders
TEC-AC-10004595	First Data TMFD35 PIN Pad	Technology	Accessories
FUR-FU-10001468	Tenex Antistatic Computer Chair Mats	Furniture	Furnishings
TEC-AC-10002134	Rosewill 107 Normal Keys USB Wired Standard Keyboard	Technology	Accessories
OFF-AP-10003971	Belkin 6 Outlet Metallic Surge Strip	Office Supplies	Appliances
OFF-LA-10004544	Avery 505	Office Supplies	Labels
FUR-FU-10000221	Master Caster Door Stop, Brown	Furniture	Furnishings
OFF-AP-10000696	Holmes Odor Grabber	Office Supplies	Appliances
TEC-PH-10003988	LF Elite 3D Dazzle Designer Hard Case Cover, Lf Stylus Pen and Wiper For Apple Iphone 5c Mini Lite	Technology	Phones
OFF-LA-10003148	Avery 51	Office Supplies	Labels
TEC-AC-10002842	WD My Passport Ultra 2TB Portable External Hard Drive	Technology	Accessories
OFF-BI-10000315	Poly Designer Cover & Back	Office Supplies	Binders
FUR-CH-10002602	DMI Arturo Collection Mission-style Design Wood Chair	Furniture	Chairs
TEC-AC-10004803	Sony Micro Vault Click 4 GB USB 2.0 Flash Drive	Technology	Accessories
TEC-AC-10003133	Memorex Mini Travel Drive 4 GB USB 2.0 Flash Drive	Technology	Accessories
OFF-BI-10002609	Avery Hidden Tab Dividers for Binding Systems	Office Supplies	Binders
TEC-AC-10000521	Verbatim Slim CD and DVD Storage Cases, 50/Pack	Technology	Accessories
FUR-CH-10003061	Global Leather Task Chair, Black	Furniture	Chairs
OFF-ST-10000760	Eldon Fold 'N Roll Cart System	Office Supplies	Storage
FUR-FU-10002505	Eldon 100 Class Desk Accessories	Furniture	Furnishings
OFF-PA-10000482	Snap-A-Way Black Print Carbonless Ruled Speed Letter, Triplicate	Office Supplies	Paper
TEC-AC-10001606	Logitech Wireless Performance Mouse MX for PC and Mac	Technology	Accessories
FUR-FU-10003724	Westinghouse Clip-On Gooseneck Lamps	Furniture	Furnishings
OFF-AP-10003217	Eureka Sanitaire  Commercial Upright	Office Supplies	Appliances
TEC-AC-10004859	Maxell Pro 80 Minute CD-R, 10/Pack	Technology	Accessories
FUR-BO-10003159	Sauder Camden County Collection Libraries, Planked Cherry Finish	Furniture	Bookcases
FUR-FU-10002445	DAX Two-Tone Rosewood/Black Document Frame, Desktop, 5 x 7	Furniture	Furnishings
FUR-CH-10004477	Global Push Button Manager's Chair, Indigo	Furniture	Chairs
OFF-AP-10002350	Belkin F9H710-06 7 Outlet SurgeMaster Surge Protector	Office Supplies	Appliances
TEC-PH-10001079	Polycom SoundPoint Pro SE-225 Corded phone	Technology	Phones
FUR-CH-10003396	Global Deluxe Steno Chair	Furniture	Chairs
OFF-BI-10003707	Aluminum Screw Posts	Office Supplies	Binders
OFF-AR-10003514	4009 Highlighters by Sanford	Office Supplies	Art
FUR-FU-10004053	DAX Two-Tone Silver Metal Document Frame	Furniture	Furnishings
OFF-LA-10001613	Avery File Folder Labels	Office Supplies	Labels
OFF-LA-10001074	Round Specialty Laser Printer Labels	Office Supplies	Labels
OFF-ST-10002352	Iris Project Case	Office Supplies	Storage
TEC-PH-10002584	Samsung Galaxy S4	Technology	Phones
OFF-ST-10003572	Portfile Personal File Boxes	Office Supplies	Storage
OFF-LA-10002368	Avery 479	Office Supplies	Labels
OFF-ST-10004337	SAFCO Commercial Wire Shelving, 72h	Office Supplies	Storage
TEC-PH-10003875	KLD Oscar II Style Snap-on Ultra Thin Side Flip Synthetic Leather Cover Case for HTC One HTC M7	Technology	Phones
FUR-FU-10004904	Eldon "L" Workstation Diamond Chairmat	Furniture	Furnishings
OFF-AR-10003056	Newell 341	Office Supplies	Art
FUR-FU-10001215	Howard Miller 11-1/2" Diameter Brentwood Wall Clock	Furniture	Furnishings
OFF-EN-10003286	Staple envelope	Office Supplies	Envelopes
OFF-PA-10002581	Xerox 1951	Office Supplies	Paper
OFF-BI-10002706	Avery Premier Heavy-Duty Binder with Round Locking Rings	Office Supplies	Binders
TEC-AC-10001266	Memorex Micro Travel Drive 8 GB	Technology	Accessories
OFF-FA-10004248	Advantus T-Pin Paper Clips	Office Supplies	Fasteners
OFF-PA-10003893	Xerox 1962	Office Supplies	Paper
OFF-BI-10003727	Avery Durable Slant Ring Binders With Label Holder	Office Supplies	Binders
OFF-AP-10002203	Eureka Disposable Bags for Sanitaire Vibra Groomer I Upright Vac	Office Supplies	Appliances
OFF-EN-10001990	Staple envelope	Office Supplies	Envelopes
OFF-AR-10001953	Boston 1645 Deluxe Heavier-Duty Electric Pencil Sharpener	Office Supplies	Art
OFF-LA-10002271	Smead Alpha-Z Color-Coded Second Alphabetical Labels and Starter Set	Office Supplies	Labels
OFF-ST-10002957	Sterilite Show Offs Storage Containers	Office Supplies	Storage
OFF-ST-10004634	Personal Folder Holder, Ebony	Office Supplies	Storage
OFF-AP-10001962	Black & Decker Filter for Double Action Dustbuster Cordless Vac BLDV7210	Office Supplies	Appliances
OFF-BI-10003684	Wilson Jones Legal Size Ring Binders	Office Supplies	Binders
OFF-ST-10003470	Tennsco Snap-Together Open Shelving Units, Starter Sets and Add-On Units	Office Supplies	Storage
OFF-PA-10000466	Memo Book, 100 Message Capacity, 5 3/8” x 11”	Office Supplies	Paper
OFF-ST-10001511	Space Solutions Commercial Steel Shelving	Office Supplies	Storage
TEC-PH-10000011	PureGear Roll-On Screen Protector	Technology	Phones
OFF-ST-10002562	Staple magnet	Office Supplies	Storage
FUR-TA-10004534	Bevis 44 x 96 Conference Tables	Furniture	Tables
OFF-PA-10000300	Xerox 1936	Office Supplies	Paper
OFF-BI-10002982	Avery Self-Adhesive Photo Pockets for Polaroid Photos	Office Supplies	Binders
OFF-BI-10000474	Avery Recycled Flexi-View Covers for Binding Systems	Office Supplies	Binders
TEC-AC-10000290	Sabrent 4-Port USB 2.0 Hub	Technology	Accessories
OFF-BI-10001072	GBC Clear Cover, 8-1/2 x 11, unpunched, 25 covers per pack	Office Supplies	Binders
OFF-BI-10000136	Avery Non-Stick Heavy Duty View Round Locking Ring Binders	Office Supplies	Binders
OFF-AR-10003469	Nontoxic Chalk	Office Supplies	Art
OFF-PA-10003039	Xerox 1960	Office Supplies	Paper
FUR-FU-10001967	Telescoping Adjustable Floor Lamp	Furniture	Furnishings
TEC-PH-10000486	Plantronics HL10 Handset Lifter	Technology	Phones
OFF-PA-10001509	Recycled Desk Saver Line "While You Were Out" Book, 5 1/2" X 4"	Office Supplies	Paper
TEC-AC-10000682	Kensington K72356US Mouse-in-a-Box USB Desktop Mouse	Technology	Accessories
OFF-ST-10001505	Perma STOR-ALL Hanging File Box, 13 1/8"W x 12 1/4"D x 10 1/2"H	Office Supplies	Storage
OFF-BI-10003350	Acco Expandable Hanging Binders	Office Supplies	Binders
OFF-FA-10003112	Staples	Office Supplies	Fasteners
TEC-PH-10003931	JBL Micro Wireless Portable Bluetooth Speaker	Technology	Phones
OFF-AR-10001940	Sanford Colorific Eraseable Coloring Pencils, 12 Count	Office Supplies	Art
OFF-PA-10001878	Xerox 1891	Office Supplies	Paper
TEC-AC-10004571	Logitech G700s Rechargeable Gaming Mouse	Technology	Accessories
FUR-FU-10002918	Eldon ClusterMat Chair Mat with Cordless Antistatic Protection	Furniture	Furnishings
FUR-FU-10003708	Tenex Traditional Chairmats for Medium Pile Carpet, Standard Lip, 36" x 48"	Furniture	Furnishings
OFF-BI-10002082	GBC Twin Loop Wire Binding Elements	Office Supplies	Binders
OFF-ST-10003123	Fellowes Bases and Tops For Staxonsteel/High-Stak Systems	Office Supplies	Storage
OFF-SU-10002881	Martin Yale Chadless Opener Electric Letter Opener	Office Supplies	Supplies
OFF-AR-10001044	BOSTON Ranger #55 Pencil Sharpener, Black	Office Supplies	Art
OFF-PA-10003072	Eureka Recycled Copy Paper 8 1/2" x 11", Ream	Office Supplies	Paper
FUR-FU-10003535	Howard Miller Distant Time Traveler Alarm Clock	Furniture	Furnishings
OFF-AR-10001130	Quartet Alpha White Chalk, 12/Pack	Office Supplies	Art
OFF-LA-10001158	Avery Address/Shipping Labels for Typewriters, 4" x 2"	Office Supplies	Labels
OFF-BI-10004465	Avery Durable Slant Ring Binders	Office Supplies	Binders
OFF-AR-10003582	Boston Electric Pencil Sharpener, Model 1818, Charcoal Black	Office Supplies	Art
OFF-LA-10002475	Avery 519	Office Supplies	Labels
FUR-TA-10004575	Hon 5100 Series Wood Tables	Furniture	Tables
FUR-FU-10000277	Deflect-o DuraMat Antistatic Studded Beveled Mat for Medium Pile Carpeting	Furniture	Furnishings
OFF-BI-10000050	Angle-D Binders with Locking Rings, Label Holders	Office Supplies	Binders
TEC-PH-10001061	Apple iPhone 5C	Technology	Phones
FUR-TA-10004767	Safco Drafting Table	Furniture	Tables
OFF-EN-10004773	Staple envelope	Office Supplies	Envelopes
OFF-EN-10002230	Airmail Envelopes	Office Supplies	Envelopes
OFF-AR-10001683	Lumber Crayons	Office Supplies	Art
OFF-BI-10003676	GBC Standard Recycled Report Covers, Clear Plastic Sheets	Office Supplies	Binders
TEC-AC-10004171	Razer Kraken 7.1 Surround Sound Over Ear USB Gaming Headset	Technology	Accessories
TEC-MA-10003230	Okidata C610n Printer	Technology	Machines
OFF-AP-10002684	Acco 7-Outlet Masterpiece Power Center, Wihtout Fax/Phone Line Protection	Office Supplies	Appliances
OFF-BI-10004967	Round Ring Binders	Office Supplies	Binders
OFF-AP-10004233	Honeywell Enviracaire Portable Air Cleaner for up to 8 x 10 Room	Office Supplies	Appliances
TEC-AC-10003590	TRENDnet 56K USB 2.0 Phone, Internet and Fax Modem	Technology	Accessories
OFF-BI-10004817	GBC Personal VeloBind Strips	Office Supplies	Binders
OFF-ST-10000918	Crate-A-Files	Office Supplies	Storage
OFF-AP-10004249	Staple holder	Office Supplies	Appliances
OFF-PA-10000100	Xerox 1945	Office Supplies	Paper
OFF-AR-10001216	Newell 339	Office Supplies	Art
OFF-BI-10000279	Acco Recycled 2" Capacity Laser Printer Hanging Data Binders	Office Supplies	Binders
OFF-PA-10000994	Xerox 1915	Office Supplies	Paper
TEC-AC-10003441	Kingston Digital DataTraveler 32GB USB 2.0	Technology	Accessories
OFF-BI-10001765	Wilson Jones Heavy-Duty Casebound Ring Binders with Metal Hinges	Office Supplies	Binders
OFF-SU-10002573	Acme 10" Easy Grip Assistive Scissors	Office Supplies	Supplies
OFF-ST-10000876	Eldon Simplefile Box Office	Office Supplies	Storage
OFF-PA-10001752	Hammermill CopyPlus Copy Paper (20Lb. and 84 Bright)	Office Supplies	Paper
FUR-CH-10001708	Office Star - Contemporary Swivel Chair with Padded Adjustable Arms and Flex Back	Furniture	Chairs
OFF-LA-10003720	Avery 487	Office Supplies	Labels
TEC-AC-10002253	Imation Bio 8GB USB Flash Drive Imation Corp	Technology	Accessories
OFF-PA-10000061	Xerox 205	Office Supplies	Paper
FUR-CH-10002024	HON 5400 Series Task Chairs for Big and Tall	Furniture	Chairs
FUR-CH-10000847	Global Executive Mid-Back Manager's Chair	Furniture	Chairs
FUR-FU-10001861	Floodlight Indoor Halogen Bulbs, 1 Bulb per Pack, 60 Watts	Furniture	Furnishings
TEC-PH-10002310	Plantronics Calisto P620-M USB Wireless Speakerphone System	Technology	Phones
TEC-PH-10003072	Panasonic KX-TG9541B DECT 6.0 Digital 2-Line Expandable Cordless Phone With Digital Answering System	Technology	Phones
OFF-PA-10001952	Xerox 1902	Office Supplies	Paper
OFF-PA-10003129	Tops White Computer Printout Paper	Office Supplies	Paper
TEC-PH-10003601	Ativa D5772 2-Line 5.8GHz Digital Expandable Corded/Cordless Phone System with Answering & Caller ID/Call Waiting, Black/Silver	Technology	Phones
OFF-BI-10002353	GBC VeloBind Cover Sets	Office Supplies	Binders
FUR-FU-10004351	Staple-based wall hangings	Furniture	Furnishings
OFF-BI-10003460	Acco 3-Hole Punch	Office Supplies	Binders
FUR-FU-10002298	Rubbermaid ClusterMat Chairmats, Mat Size- 66" x 60", Lip 20" x 11" -90 Degree Angle	Furniture	Furnishings
TEC-PH-10000213	Seidio BD2-HK3IPH5-BK DILEX Case and Holster Combo for Apple iPhone 5/5s - Black	Technology	Phones
FUR-FU-10000965	Howard Miller 11-1/2" Diameter Ridgewood Wall Clock	Furniture	Furnishings
OFF-BI-10003655	Durable Pressboard Binders	Office Supplies	Binders
TEC-PH-10000562	Samsung Convoy 3	Technology	Phones
OFF-AR-10000940	Newell 343	Office Supplies	Art
FUR-CH-10001270	Harbour Creations Steel Folding Chair	Furniture	Chairs
OFF-PA-10001954	Xerox 1964	Office Supplies	Paper
FUR-TA-10002622	Bush Andora Conference Table, Maple/Graphite Gray Finish	Furniture	Tables
TEC-PH-10002923	Logitech B530 USB Headset - headset - Full size, Binaural	Technology	Phones
OFF-SU-10004261	Fiskars 8" Scissors, 2/Pack	Office Supplies	Supplies
OFF-BI-10003784	Computer Printout Index Tabs	Office Supplies	Binders
OFF-ST-10001370	Sensible Storage WireTech Storage Systems	Office Supplies	Storage
OFF-BI-10002215	Wilson Jones Hanging View Binder, White, 1"	Office Supplies	Binders
TEC-AC-10004708	Sony 32GB Class 10 Micro SDHC R40 Memory Card	Technology	Accessories
TEC-PH-10000038	Jawbone MINI JAMBOX Wireless Bluetooth Speaker	Technology	Phones
OFF-PA-10004675	Telephone Message Books with Fax/Mobile Section, 5 1/2" x 3 3/16"	Office Supplies	Paper
FUR-FU-10001756	Eldon Expressions Desk Accessory, Wood Photo Frame, Mahogany	Furniture	Furnishings
TEC-AC-10004864	Memorex Micro Travel Drive 32 GB	Technology	Accessories
OFF-AR-10000716	DIXON Ticonderoga Erasable Checking Pencils	Office Supplies	Art
OFF-PA-10002245	Xerox 1895	Office Supplies	Paper
FUR-CH-10003981	Global Commerce Series Low-Back Swivel/Tilt Chairs	Furniture	Chairs
OFF-BI-10003708	Acco Four Pocket Poly Ring Binder with Label Holder, Smoke, 1"	Office Supplies	Binders
OFF-AP-10001394	Harmony Air Purifier	Office Supplies	Appliances
TEC-AC-10002567	Logitech G602 Wireless Gaming Mouse	Technology	Accessories
OFF-PA-10001307	Important Message Pads, 50 4-1/4 x 5-1/2 Forms per Pad	Office Supplies	Paper
OFF-PA-10001763	Xerox 1896	Office Supplies	Paper
OFF-AR-10001246	Newell 317	Office Supplies	Art
FUR-CH-10002647	Situations Contoured Folding Chairs, 4/Set	Furniture	Chairs
OFF-ST-10001780	Tennsco 16-Compartment Lockers with Coat Rack	Office Supplies	Storage
OFF-FA-10003495	Staples	Office Supplies	Fasteners
OFF-SU-10000151	High Speed Automatic Electric Letter Opener	Office Supplies	Supplies
OFF-BI-10004022	Acco Suede Grain Vinyl Round Ring Binder	Office Supplies	Binders
TEC-PH-10000149	Cisco SPA525G2 IP Phone - Wireless	Technology	Phones
OFF-AR-10001374	BIC Brite Liner Highlighters, Chisel Tip	Office Supplies	Art
OFF-ST-10000991	Space Solutions HD Industrial Steel Shelving.	Office Supplies	Storage
OFF-EN-10001415	Staple envelope	Office Supplies	Envelopes
OFF-PA-10002713	Adams Phone Message Book, 200 Message Capacity, 8 1/16” x 11”	Office Supplies	Paper
FUR-CH-10002044	Office Star - Contemporary Task Swivel chair with 2-way adjustable arms, Plum	Furniture	Chairs
FUR-FU-10000755	Eldon Expressions Mahogany Wood Desk Collection	Furniture	Furnishings
OFF-PA-10003892	Xerox 1943	Office Supplies	Paper
TEC-PH-10001700	Panasonic KX-TG6844B Expandable Digital Cordless Telephone	Technology	Phones
OFF-BI-10000014	Heavy-Duty E-Z-D Binders	Office Supplies	Binders
OFF-PA-10001870	Xerox 202	Office Supplies	Paper
OFF-BI-10004995	GBC DocuBind P400 Electric Binding System	Office Supplies	Binders
OFF-EN-10002621	Staple envelope	Office Supplies	Envelopes
OFF-ST-10004835	Plastic Stacking Crates & Casters	Office Supplies	Storage
FUR-CH-10004983	Office Star - Mid Back Dual function Ergonomic High Back Chair with 2-Way Adjustable Arms	Furniture	Chairs
OFF-BI-10001120	Ibico EPK-21 Electric Binding System	Office Supplies	Binders
OFF-BI-10000773	Insertable Tab Post Binder Dividers	Office Supplies	Binders
OFF-AR-10004752	Blackstonian Pencils	Office Supplies	Art
OFF-EN-10000483	White Envelopes, White Envelopes with Clear Poly Window	Office Supplies	Envelopes
TEC-MA-10002930	Ricoh - Ink Collector Unit for GX3000 Series Printers	Technology	Machines
OFF-AP-10003590	Hoover WindTunnel Plus Canister Vacuum	Office Supplies	Appliances
OFF-PA-10002137	Southworth 100% Résumé Paper, 24lb.	Office Supplies	Paper
OFF-LA-10004545	Avery 50	Office Supplies	Labels
TEC-AC-10002942	WD My Passport Ultra 1TB Portable External Hard Drive	Technology	Accessories
TEC-PH-10002555	Nortel Meridian M5316 Digital phone	Technology	Phones
FUR-CH-10004853	Global Manager's Adjustable Task Chair, Storm	Furniture	Chairs
FUR-CH-10000553	Metal Folding Chairs, Beige, 4/Carton	Furniture	Chairs
OFF-BI-10001460	Plastic Binding Combs	Office Supplies	Binders
OFF-ST-10001713	Gould Plastics 9-Pocket Panel Bin, 18-3/8w x 5-1/4d x 20-1/2h, Black	Office Supplies	Storage
OFF-AP-10002472	3M Office Air Cleaner	Office Supplies	Appliances
FUR-CH-10002304	Global Stack Chair without Arms, Black	Furniture	Chairs
OFF-FA-10000053	Revere Boxed Rubber Bands by Revere	Office Supplies	Fasteners
FUR-FU-10004666	DAX Clear Channel Poster Frame	Furniture	Furnishings
FUR-FU-10003832	Eldon Expressions Punched Metal & Wood Desk Accessories, Black & Cherry	Furniture	Furnishings
OFF-AP-10002495	Acco Smartsocket Table Surge Protector, 6 Color-Coded Adapter Outlets	Office Supplies	Appliances
OFF-PA-10000232	Xerox 1975	Office Supplies	Paper
FUR-TA-10002533	BPI Conference Tables	Furniture	Tables
TEC-AC-10001542	SanDisk Cruzer 16 GB USB Flash Drive	Technology	Accessories
OFF-BI-10003910	DXL Angle-View Binders with Locking Rings by Samsill	Office Supplies	Binders
TEC-AC-10004877	Imation 30456 USB Flash Drive 8GB	Technology	Accessories
OFF-AP-10002439	Tripp Lite Isotel 8 Ultra 8 Outlet Metal Surge	Office Supplies	Appliances
OFF-PA-10004971	Xerox 196	Office Supplies	Paper
TEC-PH-10002262	LG Electronics Tone+ HBS-730 Bluetooth Headset	Technology	Phones
FUR-BO-10000780	O'Sullivan Plantations 2-Door Library in Landvery Oak	Furniture	Bookcases
OFF-AP-10001005	Honeywell Quietcare HEPA Air Cleaner	Office Supplies	Appliances
OFF-PA-10002036	Xerox 1930	Office Supplies	Paper
OFF-ST-10000777	Companion Letter/Legal File, Black	Office Supplies	Storage
TEC-PH-10001578	Polycom SoundStation2 EX Conference phone	Technology	Phones
OFF-BI-10001097	Avery Hole Reinforcements	Office Supplies	Binders
OFF-EN-10004459	Security-Tint Envelopes	Office Supplies	Envelopes
FUR-BO-10003893	Sauder Camden County Collection Library	Furniture	Bookcases
FUR-CH-10001973	Office Star Flex Back Scooter Chair with White Frame	Furniture	Chairs
OFF-ST-10001932	Fellowes Staxonsteel Drawer Files	Office Supplies	Storage
TEC-PH-10001644	BlueLounge Milo Smartphone Stand, White/Metallic	Technology	Phones
OFF-EN-10002500	Globe Weis Peel & Seel First Class Envelopes	Office Supplies	Envelopes
OFF-PA-10001260	TOPS Money Receipt Book, Consecutively Numbered in Red,	Office Supplies	Paper
OFF-AR-10004685	Binney & Smith Crayola Metallic Colored Pencils, 8-Color Set	Office Supplies	Art
TEC-AC-10002167	Imation 8gb Micro Traveldrive Usb 2.0 Flash Drive	Technology	Accessories
OFF-AR-10000127	Newell 321	Office Supplies	Art
FUR-TA-10002607	KI Conference Tables	Furniture	Tables
OFF-ST-10002790	Safco Industrial Shelving	Office Supplies	Storage
OFF-AR-10004010	Hunt Boston Vacuum Mount KS Pencil Sharpener	Office Supplies	Art
FUR-CH-10003846	Hon Valutask Swivel Chairs	Furniture	Chairs
FUR-BO-10000711	Hon Metal Bookcases, Gray	Furniture	Bookcases
OFF-AR-10001166	Staples in misc. colors	Office Supplies	Art
TEC-PH-10000307	Shocksock Galaxy S4 Armband	Technology	Phones
OFF-ST-10000636	Rogers Profile Extra Capacity Storage Tub	Office Supplies	Storage
OFF-BI-10001758	Wilson Jones 14 Line Acrylic Coated Pressboard Data Binders	Office Supplies	Binders
OFF-AR-10003087	Staples in misc. colors	Office Supplies	Art
OFF-EN-10001099	Staple envelope	Office Supplies	Envelopes
FUR-TA-10000198	Chromcraft Bull-Nose Wood Oval Conference Tables & Bases	Furniture	Tables
OFF-PA-10000249	Easy-staple paper	Office Supplies	Paper
TEC-PH-10001870	Lunatik TT5L-002 Taktik Strike Impact Protection System for iPhone 5	Technology	Phones
TEC-AC-10004568	Maxell LTO Ultrium - 800 GB	Technology	Accessories
OFF-SU-10004231	Acme Tagit Stainless Steel Antibacterial Scissors	Office Supplies	Supplies
TEC-AC-10000736	Logitech G600 MMO Gaming Mouse	Technology	Accessories
OFF-ST-10002344	Carina 42"Hx23 3/4"W Media Storage Unit	Office Supplies	Storage
OFF-PA-10000130	Xerox 199	Office Supplies	Paper
TEC-AC-10003174	Plantronics S12 Corded Telephone Headset System	Technology	Accessories
OFF-PA-10000726	Black Print Carbonless Snap-Off Rapid Letter, 8 1/2" x 7"	Office Supplies	Paper
TEC-AC-10004510	Logitech Desktop MK120 Mouse and keyboard Combo	Technology	Accessories
TEC-PH-10003092	Motorola L804	Technology	Phones
OFF-PA-10000483	Xerox 19	Office Supplies	Paper
OFF-EN-10001453	Tyvek Interoffice Envelopes, 9 1/2" x 12 1/2", 100/Box	Office Supplies	Envelopes
OFF-AP-10001564	Hoover Commercial Lightweight Upright Vacuum with E-Z Empty Dirt Cup	Office Supplies	Appliances
OFF-ST-10001580	Super Decoflex Portable Personal File	Office Supplies	Storage
OFF-BI-10004099	GBC VeloBinder Strips	Office Supplies	Binders
FUR-TA-10004154	Riverside Furniture Oval Coffee Table, Oval End Table, End Table with Drawer	Furniture	Tables
OFF-PA-10001950	Southworth 25% Cotton Antique Laid Paper & Envelopes	Office Supplies	Paper
OFF-PA-10004248	Xerox 1990	Office Supplies	Paper
FUR-CH-10003774	Global Wood Trimmed Manager's Task Chair, Khaki	Furniture	Chairs
OFF-AP-10002222	Staple holder	Office Supplies	Appliances
TEC-PH-10001760	Bose SoundLink Bluetooth Speaker	Technology	Phones
FUR-FU-10003601	Deflect-o RollaMat Studded, Beveled Mat for Medium Pile Carpeting	Furniture	Furnishings
OFF-ST-10003805	24 Capacity Maxi Data Binder Racks, Pearl	Office Supplies	Storage
FUR-BO-10002916	Rush Hierlooms Collection 1" Thick Stackable Bookcases	Furniture	Bookcases
TEC-AC-10000171	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 25/Pack	Technology	Accessories
FUR-TA-10001771	Bush Cubix Conference Tables, Fully Assembled	Furniture	Tables
OFF-AP-10004868	Hoover Commercial Soft Guard Upright Vacuum And Disposable Filtration Bags	Office Supplies	Appliances
FUR-CH-10002331	Hon 4700 Series Mobuis Mid-Back Task Chairs with Adjustable Arms	Furniture	Chairs
OFF-PA-10000223	Xerox 2000	Office Supplies	Paper
OFF-LA-10000240	Self-Adhesive Address Labels for Typewriters by Universal	Office Supplies	Labels
FUR-TA-10001932	Chromcraft 48" x 96" Racetrack Double Pedestal Table	Furniture	Tables
FUR-FU-10002240	Nu-Dell EZ-Mount Plastic Wall Frames	Furniture	Furnishings
FUR-BO-10001811	Atlantic Metals Mobile 5-Shelf Bookcases, Custom Colors	Furniture	Bookcases
OFF-BI-10002852	Ibico Standard Transparent Covers	Office Supplies	Binders
TEC-PH-10000441	VTech DS6151	Technology	Phones
OFF-PA-10000533	Southworth Parchment Paper & Envelopes	Office Supplies	Paper
TEC-PH-10003645	Aastra 57i VoIP phone	Technology	Phones
FUR-CH-10003746	Hon 4070 Series Pagoda Round Back Stacking Chairs	Furniture	Chairs
OFF-AP-10004655	Holmes Visible Mist Ultrasonic Humidifier with 2.3-Gallon Output per Day, Replacement Filter	Office Supplies	Appliances
OFF-ST-10000036	Recycled Data-Pak for Archival Bound Computer Printouts, 12-1/2 x 12-1/2 x 16	Office Supplies	Storage
OFF-EN-10004206	Multimedia Mailers	Office Supplies	Envelopes
OFF-PA-10000743	Xerox 1977	Office Supplies	Paper
TEC-AC-10003116	Memorex Froggy Flash Drive 8 GB	Technology	Accessories
OFF-AR-10003829	Newell 35	Office Supplies	Art
FUR-CH-10004754	Global Stack Chair with Arms, Black	Furniture	Chairs
FUR-CH-10002880	Global High-Back Leather Tilter, Burgundy	Furniture	Chairs
OFF-SU-10000432	Acco Side-Punched Conventional Columnar Pads	Office Supplies	Supplies
OFF-AR-10000034	BIC Brite Liner Grip Highlighters, Assorted, 5/Pack	Office Supplies	Art
FUR-FU-10004909	Contemporary Wood/Metal Frame	Furniture	Furnishings
TEC-MA-10004679	StarTech.com 10/100 VDSL2 Ethernet Extender Kit	Technology	Machines
OFF-PA-10001994	Ink Jet Note and Greeting Cards, 8-1/2" x 5-1/2" Card Size	Office Supplies	Paper
TEC-PH-10004667	Cisco 8x8 Inc. 6753i IP Business Phone System	Technology	Phones
TEC-AC-10002399	SanDisk Cruzer 32 GB USB Flash Drive	Technology	Accessories
OFF-LA-10000414	Avery 503	Office Supplies	Labels
OFF-PA-10003177	Xerox 1999	Office Supplies	Paper
OFF-AR-10001149	Avery Hi-Liter Comfort Grip Fluorescent Highlighter, Yellow Ink	Office Supplies	Art
OFF-SU-10000157	Compact Automatic Electric Letter Opener	Office Supplies	Supplies
OFF-SU-10003505	Premier Electric Letter Opener	Office Supplies	Supplies
OFF-ST-10000464	Multi-Use Personal File Cart and Caster Set, Three Stacking Bins	Office Supplies	Storage
TEC-PH-10000215	Plantronics Cordless Phone Headset with In-line Volume - M214C	Technology	Phones
OFF-BI-10003712	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Light Blue	Office Supplies	Binders
OFF-AR-10004269	Newell 31	Office Supplies	Art
FUR-FU-10003394	Tenex "The Solids" Textured Chair Mats	Furniture	Furnishings
FUR-FU-10004952	C-Line Cubicle Keepers Polyproplyene Holder w/Velcro Back, 8-1/2x11, 25/Bx	Furniture	Furnishings
TEC-PH-10004700	PowerGen Dual USB Car Charger	Technology	Phones
OFF-AP-10001626	Commercial WindTunnel Clean Air Upright Vacuum, Replacement Belts, Filtration Bags	Office Supplies	Appliances
FUR-TA-10002530	Iceberg OfficeWorks 42" Round Tables	Furniture	Tables
OFF-AR-10001955	Newell 319	Office Supplies	Art
OFF-PA-10000575	Wirebound Message Books, Four 2 3/4 x 5 White Forms per Page	Office Supplies	Paper
OFF-AR-10003190	Newell 32	Office Supplies	Art
OFF-ST-10000642	Tennsco Lockers, Gray	Office Supplies	Storage
OFF-ST-10004507	Advantus Rolling Storage Box	Office Supplies	Storage
FUR-CH-10003833	Novimex Fabric Task Chair	Furniture	Chairs
OFF-BI-10000088	GBC Imprintable Covers	Office Supplies	Binders
OFF-BI-10002571	Avery Framed View Binder, EZD Ring (Locking), Navy, 1 1/2"	Office Supplies	Binders
TEC-AC-10002049	Logitech G19 Programmable Gaming Keyboard	Technology	Accessories
OFF-LA-10002945	Permanent Self-Adhesive File Folder Labels for Typewriters, 1 1/8 x 3 1/2, White	Office Supplies	Labels
OFF-PA-10002262	Xerox 192	Office Supplies	Paper
FUR-BO-10003441	Bush Westfield Collection Bookcases, Fully Assembled	Furniture	Bookcases
TEC-PH-10000169	ARKON Windshield Dashboard Air Vent Car Mount Holder	Technology	Phones
FUR-TA-10001857	Balt Solid Wood Rectangular Table	Furniture	Tables
OFF-AR-10004999	Newell 315	Office Supplies	Art
OFF-PA-10004071	Eaton Premium Continuous-Feed Paper, 25% Cotton, Letter Size, White, 1000 Shts/Box	Office Supplies	Paper
OFF-BI-10002854	Performers Binder/Pad Holder, Black	Office Supplies	Binders
TEC-AC-10004001	Logitech Wireless Headset H600 Over-The-Head Design	Technology	Accessories
OFF-AR-10002766	Prang Drawing Pencil Set	Office Supplies	Art
OFF-PA-10003729	Xerox 1998	Office Supplies	Paper
TEC-CO-10002095	Hewlett Packard 610 Color Digital Copier / Printer	Technology	Copiers
FUR-FU-10003096	Master Giant Foot Doorstop, Safety Yellow	Furniture	Furnishings
OFF-BI-10001890	Avery Poly Binder Pockets	Office Supplies	Binders
OFF-AR-10003045	Prang Colored Pencils	Office Supplies	Art
OFF-PA-10001685	Easy-staple paper	Office Supplies	Paper
FUR-TA-10000577	Bretford CR4500 Series Slim Rectangular Table	Furniture	Tables
FUR-CH-10004218	Global Fabric Manager's Chair, Dark Gray	Furniture	Chairs
OFF-PA-10003673	Strathmore Photo Mount Cards	Office Supplies	Paper
OFF-ST-10000943	Eldon ProFile File 'N Store Portable File Tub Letter/Legal Size Black	Office Supplies	Storage
OFF-ST-10000419	Rogers Jumbo File, Granite	Office Supplies	Storage
TEC-PH-10002922	ShoreTel ShorePhone IP 230 VoIP phone	Technology	Phones
OFF-EN-10001028	Staple envelope	Office Supplies	Envelopes
OFF-ST-10003994	Belkin 19" Center-Weighted Shelf, Gray	Office Supplies	Storage
OFF-BI-10004233	GBC Pre-Punched Binding Paper, Plastic, White, 8-1/2" x 11"	Office Supplies	Binders
FUR-FU-10001706	Longer-Life Soft White Bulbs	Furniture	Furnishings
FUR-BO-10002202	Atlantic Metals Mobile 2-Shelf Bookcases, Custom Colors	Furniture	Bookcases
OFF-PA-10000551	Array Memo Cubes	Office Supplies	Paper
TEC-AC-10002018	AmazonBasics 3-Button USB Wired Mouse	Technology	Accessories
FUR-BO-10003894	Safco Value Mate Steel Bookcase, Baked Enamel Finish on Steel, Black	Furniture	Bookcases
TEC-MA-10000822	Lexmark MX611dhe Monochrome Laser Printer	Technology	Machines
OFF-PA-10000157	Xerox 191	Office Supplies	Paper
OFF-BI-10004040	Wilson Jones Impact Binders	Office Supplies	Binders
OFF-ST-10001172	Tennsco Lockers, Sand	Office Supplies	Storage
OFF-BI-10004224	Catalog Binders with Expanding Posts	Office Supplies	Binders
OFF-AR-10000390	Newell Chalk Holder	Office Supplies	Art
OFF-SU-10000898	Acme Hot Forged Carbon Steel Scissors with Nickel-Plated Handles, 3 7/8" Cut, 8"L	Office Supplies	Supplies
TEC-PH-10001299	Polycom CX300 Desktop Phone USB VoIP phone	Technology	Phones
OFF-PA-10004983	Xerox 23	Office Supplies	Paper
OFF-BI-10003007	Premium Transparent Presentation Covers, No Pattern/Clear, 8 1/2" x 11"	Office Supplies	Binders
OFF-AP-10001492	Acco Six-Outlet Power Strip, 4' Cord Length	Office Supplies	Appliances
OFF-PA-10003127	Easy-staple paper	Office Supplies	Paper
OFF-AP-10002457	Eureka The Boss Plus 12-Amp Hard Box Upright Vacuum, Red	Office Supplies	Appliances
OFF-AR-10003732	Newell 333	Office Supplies	Art
OFF-BI-10001036	Cardinal EasyOpen D-Ring Binders	Office Supplies	Binders
OFF-AR-10004344	Bulldog Vacuum Base Pencil Sharpener	Office Supplies	Art
FUR-FU-10001546	Dana Swing-Arm Lamps	Furniture	Furnishings
FUR-CH-10003606	SAFCO Folding Chair Trolley	Furniture	Chairs
OFF-AP-10001242	APC 7 Outlet Network SurgeArrest Surge Protector	Office Supplies	Appliances
OFF-AP-10004036	Bionaire 99.97% HEPA Air Cleaner	Office Supplies	Appliances
OFF-ST-10004340	Fellowes Mobile File Cart, Black	Office Supplies	Storage
FUR-FU-10004973	Flat Face Poster Frame	Furniture	Furnishings
OFF-PA-10002749	Wirebound Message Books, 5-1/2 x 4 Forms, 2 or 4 Forms per Page	Office Supplies	Paper
OFF-LA-10003663	Avery 498	Office Supplies	Labels
TEC-PH-10004897	Mediabridge Sport Armband iPhone 5s	Technology	Phones
OFF-PA-10000176	Xerox 1887	Office Supplies	Paper
OFF-ST-10000025	Fellowes Stor/Drawer Steel Plus Storage Drawers	Office Supplies	Storage
OFF-BI-10001116	Wilson Jones 1" Hanging DublLock Ring Binders	Office Supplies	Binders
OFF-PA-10004381	14-7/8 x 11 Blue Bar Computer Printout Paper	Office Supplies	Paper
FUR-TA-10002041	Bevis Round Conference Table Top, X-Base	Furniture	Tables
OFF-BI-10002735	GBC Prestige Therm-A-Bind Covers	Office Supplies	Binders
FUR-FU-10001379	Executive Impressions 16-1/2" Circular Wall Clock	Furniture	Furnishings
TEC-AC-10000580	Logitech G13 Programmable Gameboard with LCD Display	Technology	Accessories
TEC-MA-10001016	Canon PC170 Desktop Personal Copier	Technology	Machines
OFF-AR-10003156	50 Colored Long Pencils	Office Supplies	Art
OFF-PA-10004405	Rediform Voice Mail Log Books	Office Supplies	Paper
TEC-AC-10004227	SanDisk Ultra 16 GB MicroSDHC Class 10 Memory Card	Technology	Accessories
OFF-AR-10001446	Newell 309	Office Supplies	Art
FUR-FU-10000576	Luxo Professional Fluorescent Magnifier Lamp with Clamp-Mount Base	Furniture	Furnishings
FUR-TA-10001095	Chromcraft Round Conference Tables	Furniture	Tables
FUR-CH-10004063	Global Deluxe High-Back Manager's Chair	Furniture	Chairs
TEC-CO-10002313	Canon PC1080F Personal Copier	Technology	Copiers
TEC-PH-10004959	Classic Ivory Antique Telephone ZL1810	Technology	Phones
TEC-PH-10001494	Polycom CX600 IP Phone VoIP phone	Technology	Phones
FUR-CH-10002073	Hon Olson Stacker Chairs	Furniture	Chairs
FUR-TA-10004607	Hon 2111 Invitation Series Straight Table	Furniture	Tables
TEC-MA-10002210	Epson TM-T88V Direct Thermal Printer - Monochrome - Desktop	Technology	Machines
OFF-AR-10000588	Newell 345	Office Supplies	Art
OFF-BI-10002813	Avery Reinforcements for Hole-Punch Pages	Office Supplies	Binders
OFF-ST-10002444	Recycled Eldon Regeneration Jumbo File	Office Supplies	Storage
TEC-AC-10001539	Logitech G430 Surround Sound Gaming Headset with Dolby 7.1 Technology	Technology	Accessories
OFF-AP-10002867	Fellowes Command Center 5-outlet power strip	Office Supplies	Appliances
OFF-PA-10001790	Xerox 1910	Office Supplies	Paper
FUR-TA-10002645	Hon Rectangular Conference Tables	Furniture	Tables
TEC-AC-10001998	Logitech LS21 Speaker System - PC Multimedia - 2.1-CH - Wired	Technology	Accessories
FUR-TA-10000617	Hon Practical Foundations 30 x 60 Training Table, Light Gray/Charcoal	Furniture	Tables
FUR-FU-10003919	Eldon Executive Woodline II Cherry Finish Desk Accessories	Furniture	Furnishings
OFF-AP-10001634	Hoover Commercial Lightweight Upright Vacuum	Office Supplies	Appliances
OFF-PA-10003395	Xerox 1941	Office Supplies	Paper
FUR-FU-10004245	Career Cubicle Clock, 8 1/4", Black	Furniture	Furnishings
TEC-PH-10000376	Square Credit Card Reader	Technology	Phones
TEC-MA-10000488	Bady BDG101FRU Card Printer	Technology	Machines
OFF-PA-10000295	Xerox 229	Office Supplies	Paper
OFF-PA-10004735	Xerox 1905	Office Supplies	Paper
TEC-PH-10003484	Ooma Telo VoIP Home Phone System	Technology	Phones
OFF-PA-10000565	Easy-staple paper	Office Supplies	Paper
FUR-FU-10004963	Eldon 400 Class Desk Accessories, Black Carbon	Furniture	Furnishings
OFF-PA-10001937	Xerox 21	Office Supplies	Paper
OFF-BI-10004654	VariCap6 Expandable Binder	Office Supplies	Binders
FUR-BO-10000468	O'Sullivan 2-Shelf Heavy-Duty Bookcases	Furniture	Bookcases
TEC-PH-10004071	PayAnywhere Card Reader	Technology	Phones
TEC-PH-10001536	Spigen Samsung Galaxy S5 Case Wallet	Technology	Phones
FUR-BO-10004690	O'Sullivan Cherrywood Estates Traditional Barrister Bookcase	Furniture	Bookcases
OFF-PA-10001972	Xerox 214	Office Supplies	Paper
OFF-AP-10000804	Hoover Portapower Portable Vacuum	Office Supplies	Appliances
TEC-MA-10002937	Canon Color ImageCLASS MF8580Cdw Wireless Laser All-In-One Printer, Copier, Scanner	Technology	Machines
TEC-PH-10004120	AT&T 1080 Phone	Technology	Phones
FUR-FU-10002364	Eldon Expressions Wood Desk Accessories, Oak	Furniture	Furnishings
FUR-FU-10004306	Electrix Halogen Magnifier Lamp	Furniture	Furnishings
OFF-AR-10000658	Newell 324	Office Supplies	Art
OFF-BI-10001636	Ibico Plastic and Wire Spiral Binding Combs	Office Supplies	Binders
OFF-PA-10001019	Xerox 1884	Office Supplies	Paper
OFF-SU-10001574	Acme Value Line Scissors	Office Supplies	Supplies
FUR-CH-10000454	Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back	Furniture	Chairs
OFF-PA-10000791	Wirebound Message Books, Four 2 3/4 x 5 Forms per Page, 200 Sets per Book	Office Supplies	Paper
OFF-PA-10003543	Xerox 1985	Office Supplies	Paper
OFF-EN-10003160	Pastel Pink Envelopes	Office Supplies	Envelopes
OFF-ST-10003306	Letter Size Cart	Office Supplies	Storage
FUR-FU-10000672	Executive Impressions 10" Spectator Wall Clock	Furniture	Furnishings
TEC-PH-10003555	Motorola HK250 Universal Bluetooth Headset	Technology	Phones
OFF-EN-10003068	#6 3/4 Gummed Flap White Envelopes	Office Supplies	Envelopes
OFF-PA-10004665	Advantus Motivational Note Cards	Office Supplies	Paper
OFF-PA-10003270	Xerox 1954	Office Supplies	Paper
OFF-AP-10002906	Hoover Replacement Belt for Commercial Guardsman Heavy-Duty Upright Vacuum	Office Supplies	Appliances
FUR-FU-10004415	Stacking Tray, Side-Loading, Legal, Smoke	Furniture	Furnishings
OFF-BI-10002194	Cardinal Hold-It CD Pocket	Office Supplies	Binders
TEC-PH-10001305	Panasonic KX TS208W Corded phone	Technology	Phones
OFF-SU-10004782	Elite 5" Scissors	Office Supplies	Supplies
OFF-LA-10003223	Avery 508	Office Supplies	Labels
FUR-TA-10001950	Balt Solid Wood Round Tables	Furniture	Tables
TEC-AC-10001445	Imation USB 2.0 Swivel Flash Drive USB flash drive - 4 GB - Pink	Technology	Accessories
OFF-AP-10003281	Acco 6 Outlet Guardian Standard Surge Suppressor	Office Supplies	Appliances
FUR-CH-10004540	Global Chrome Stack Chair	Furniture	Chairs
OFF-AR-10004260	Boston 1799 Powerhouse Electric Pencil Sharpener	Office Supplies	Art
FUR-FU-10004671	Executive Impressions 12" Wall Clock	Furniture	Furnishings
TEC-AC-10002857	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 1/Pack	Technology	Accessories
OFF-AR-10000122	Newell 314	Office Supplies	Art
OFF-AR-10004817	Colorific Watercolor Pencils	Office Supplies	Art
OFF-PA-10000675	Xerox 1919	Office Supplies	Paper
TEC-PH-10004922	RCA Visys Integrated PBX 8-Line Router	Technology	Phones
OFF-AR-10001419	Newell 325	Office Supplies	Art
OFF-AR-10003602	Quartet Omega Colored Chalk, 12/Pack	Office Supplies	Art
OFF-EN-10003001	Ames Color-File Green Diamond Border X-ray Mailers	Office Supplies	Envelopes
OFF-PA-10000327	Xerox 1971	Office Supplies	Paper
TEC-PH-10000984	Panasonic KX-TG9471B	Technology	Phones
OFF-AP-10004708	Fellowes Superior 10 Outlet Split Surge Protector	Office Supplies	Appliances
TEC-AC-10003709	Maxell 4.7GB DVD-R 5/Pack	Technology	Accessories
OFF-BI-10003982	Wilson Jones Century Plastic Molded Ring Binders	Office Supplies	Binders
OFF-BI-10000948	GBC Laser Imprintable Binding System Covers, Desert Sand	Office Supplies	Binders
FUR-BO-10003546	Hon 4-Shelf Metal Bookcases	Furniture	Bookcases
TEC-PH-10000895	Polycom VVX 310 VoIP phone	Technology	Phones
TEC-AC-10004975	Plantronics Audio 995 Wireless Stereo Headset	Technology	Accessories
OFF-ST-10001418	Carina Media Storage Towers in Natural & Black	Office Supplies	Storage
FUR-BO-10000362	Sauder Inglewood Library Bookcases	Furniture	Bookcases
FUR-FU-10003799	Seth Thomas 13 1/2" Wall Clock	Furniture	Furnishings
OFF-BI-10000201	Avery Triangle Shaped Sheet Lifters, Black, 2/Pack	Office Supplies	Binders
TEC-AC-10001284	Enermax Briskie RF Wireless Keyboard and Mouse Combo	Technology	Accessories
TEC-AC-10001383	Logitech Wireless Touch Keyboard K400	Technology	Accessories
OFF-BI-10001721	Trimflex Flexible Post Binders	Office Supplies	Binders
FUR-FU-10004587	GE General Use Halogen Bulbs, 100 Watts, 1 Bulb per Pack	Furniture	Furnishings
TEC-PH-10004165	Mitel MiVoice 5330e IP Phone	Technology	Phones
OFF-PA-10000019	Xerox 1931	Office Supplies	Paper
TEC-AC-10002006	Memorex Micro Travel Drive 16 GB	Technology	Accessories
FUR-CH-10000595	Safco Contoured Stacking Chairs	Furniture	Chairs
TEC-PH-10002170	ClearSounds CSC500 Amplified Spirit Phone Corded phone	Technology	Phones
OFF-ST-10000107	Fellowes Super Stor/Drawer	Office Supplies	Storage
OFF-AR-10003876	Avery Hi-Liter GlideStik Fluorescent Highlighter, Yellow Ink	Office Supplies	Art
OFF-AR-10000203	Newell 336	Office Supplies	Art
OFF-AR-10002375	Newell 351	Office Supplies	Art
TEC-PH-10004100	Griffin GC17055 Auxiliary Audio Cable	Technology	Phones
OFF-PA-10001622	Ampad Poly Cover Wirebound Steno Book, 6" x 9" Assorted Colors, Gregg Ruled	Office Supplies	Paper
OFF-PA-10004082	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	Office Supplies	Paper
OFF-SU-10002557	Fiskars Spring-Action Scissors	Office Supplies	Supplies
OFF-EN-10001509	Poly String Tie Envelopes	Office Supplies	Envelopes
OFF-SU-10001165	Acme Elite Stainless Steel Scissors	Office Supplies	Supplies
OFF-AR-10003373	Boston School Pro Electric Pencil Sharpener, 1670	Office Supplies	Art
OFF-BI-10004728	Wilson Jones Turn Tabs Binder Tool for Ring Binders	Office Supplies	Binders
OFF-ST-10001291	Tenex Personal Self-Stacking Standard File Box, Black/Gray	Office Supplies	Storage
TEC-AC-10004469	Microsoft Sculpt Comfort Mouse	Technology	Accessories
FUR-FU-10004748	Howard Miller 16" Diameter Gallery Wall Clock	Furniture	Furnishings
TEC-AC-10004145	Logitech diNovo Edge Keyboard	Technology	Accessories
OFF-ST-10001328	Personal Filing Tote with Lid, Black/Gray	Office Supplies	Storage
TEC-PH-10003589	invisibleSHIELD by ZAGG Smudge-Free Screen Protector	Technology	Phones
OFF-AP-10004487	Kensington 4 Outlet MasterPiece Compact Power Control Center	Office Supplies	Appliances
OFF-AP-10002945	Honeywell Enviracaire Portable HEPA Air Cleaner for 17' x 22' Room	Office Supplies	Appliances
TEC-PH-10001819	Innergie mMini Combo Duo USB Travel Charging Kit	Technology	Phones
OFF-PA-10001204	Xerox 1972	Office Supplies	Paper
OFF-FA-10002763	Advantus Map Pennant Flags and Round Head Tacks	Office Supplies	Fasteners
FUR-BO-10002545	Atlantic Metals Mobile 3-Shelf Bookcases, Custom Colors	Furniture	Bookcases
OFF-PA-10000143	Astroparche Fine Business Paper	Office Supplies	Paper
OFF-PA-10003657	Xerox 1927	Office Supplies	Paper
OFF-LA-10002381	Avery 497	Office Supplies	Labels
OFF-ST-10000344	Neat Ideas Personal Hanging Folder Files, Black	Office Supplies	Storage
OFF-AP-10002578	Fellowes Premier Superior Surge Suppressor, 10-Outlet, With Phone and Remote	Office Supplies	Appliances
OFF-ST-10002756	Tennsco Stur-D-Stor Boltless Shelving, 5 Shelves, 24" Deep, Sand	Office Supplies	Storage
OFF-ST-10002615	Dual Level, Single-Width Filing Carts	Office Supplies	Storage
TEC-CO-10001766	Canon PC940 Copier	Technology	Copiers
OFF-ST-10001469	Fellowes Bankers Box Recycled Super Stor/Drawer	Office Supplies	Storage
FUR-BO-10002268	Sauder Barrister Bookcases	Furniture	Bookcases
OFF-PA-10001776	Wirebound Message Books, Four 2 3/4" x 5" Forms per Page, 600 Sets per Book	Office Supplies	Paper
OFF-PA-10000304	Xerox 1995	Office Supplies	Paper
TEC-PH-10004908	Panasonic KX TS3282W Corded phone	Technology	Phones
FUR-FU-10003577	Nu-Dell Leatherette Frames	Furniture	Furnishings
OFF-AR-10000937	Dixon Ticonderoga Core-Lock Colored Pencils, 48-Color Set	Office Supplies	Art
TEC-AC-10000303	Logitech M510 Wireless Mouse	Technology	Accessories
FUR-TA-10002774	Laminate Occasional Tables	Furniture	Tables
OFF-PA-10004022	Hammermill Color Copier Paper (28Lb. and 96 Bright)	Office Supplies	Paper
OFF-AP-10000390	Euro Pro Shark Stick Mini Vacuum	Office Supplies	Appliances
OFF-LA-10001045	Permanent Self-Adhesive File Folder Labels for Typewriters by Universal	Office Supplies	Labels
OFF-BI-10002049	UniKeep View Case Binders	Office Supplies	Binders
OFF-PA-10002160	Xerox 1978	Office Supplies	Paper
FUR-CH-10002965	Global Leather Highback Executive Chair with Pneumatic Height Adjustment, Black	Furniture	Chairs
OFF-PA-10002365	Xerox 1967	Office Supplies	Paper
OFF-ST-10000736	Carina Double Wide Media Storage Towers in Natural & Black	Office Supplies	Storage
OFF-EN-10000056	Cameo Buff Policy Envelopes	Office Supplies	Envelopes
OFF-ST-10000604	Home/Office Personal File Carts	Office Supplies	Storage
OFF-LA-10004178	Avery 491	Office Supplies	Labels
OFF-FA-10001843	Staples	Office Supplies	Fasteners
TEC-AC-10001767	SanDisk Ultra 64 GB MicroSDHC Class 10 Memory Card	Technology	Accessories
OFF-AR-10003759	Crayola Anti Dust Chalk, 12/Pack	Office Supplies	Art
OFF-AP-10004052	Hoover Replacement Belts For Soft Guard & Commercial Ltweight Upright Vacs, 2/Pk	Office Supplies	Appliances
TEC-PH-10002085	Clarity 53712	Technology	Phones
TEC-CO-10004722	Canon imageCLASS 2200 Advanced Copier	Technology	Copiers
OFF-LA-10000443	Avery 501	Office Supplies	Labels
OFF-BI-10000309	GBC Twin Loop Wire Binding Elements, 9/16" Spine, Black	Office Supplies	Binders
FUR-TA-10004619	Hon Non-Folding Utility Tables	Furniture	Tables
OFF-PA-10001461	HP Office Paper (20Lb. and 87 Bright)	Office Supplies	Paper
OFF-ST-10001031	Adjustable Personal File Tote	Office Supplies	Storage
TEC-AC-10003033	Plantronics CS510 - Over-the-Head monaural Wireless Headset System	Technology	Accessories
OFF-PA-10001471	Strathmore Photo Frame Cards	Office Supplies	Paper
OFF-BI-10003274	Avery Durable Slant Ring Binders, No Labels	Office Supplies	Binders
OFF-BI-10004236	XtraLife ClearVue Slant-D Ring Binder, White, 3"	Office Supplies	Binders
OFF-AR-10004648	Boston 19500 Mighty Mite Electric Pencil Sharpener	Office Supplies	Art
TEC-AC-10004518	Memorex Mini Travel Drive 32 GB USB 2.0 Flash Drive	Technology	Accessories
TEC-PH-10004241	Nokia Lumia 1020	Technology	Phones
OFF-BI-10004139	Fellowes Presentation Covers for Comb Binding Machines	Office Supplies	Binders
OFF-AR-10001761	Avery Hi-Liter Smear-Safe Highlighters	Office Supplies	Art
OFF-ST-10003716	Tennsco Double-Tier Lockers	Office Supplies	Storage
TEC-PH-10000673	Plantronics Voyager Pro HD - Bluetooth Headset	Technology	Phones
FUR-FU-10001475	Contract Clock, 14", Brown	Furniture	Furnishings
OFF-ST-10001325	Sterilite Officeware Hinged File Box	Office Supplies	Storage
OFF-AP-10000358	Fellowes Basic Home/Office Series Surge Protectors	Office Supplies	Appliances
OFF-PA-10001639	Xerox 203	Office Supplies	Paper
OFF-PA-10001357	Xerox 1886	Office Supplies	Paper
OFF-BI-10002160	Acco Hanging Data Binders	Office Supplies	Binders
OFF-BI-10000138	Acco Translucent Poly Ring Binders	Office Supplies	Binders
TEC-CO-10001046	Canon Imageclass D680 Copier / Fax	Technology	Copiers
OFF-PA-10004996	Speediset Carbonless Redi-Letter 7" x 8 1/2"	Office Supplies	Paper
TEC-AC-10003433	Maxell 4.7GB DVD+R 5/Pack	Technology	Accessories
OFF-PA-10003848	Xerox 1997	Office Supplies	Paper
OFF-AP-10003779	Kensington 7 Outlet MasterPiece Power Center with Fax/Phone Line Protection	Office Supplies	Appliances
TEC-AC-10003289	Anker Ultra-Slim Mini Bluetooth 3.0 Wireless Keyboard	Technology	Accessories
FUR-CH-10003199	Office Star - Contemporary Task Swivel Chair	Furniture	Chairs
OFF-PA-10001166	Xerox 2	Office Supplies	Paper
OFF-FA-10000840	OIC Thumb-Tacks	Office Supplies	Fasteners
OFF-BI-10002432	Wilson Jones Standard D-Ring Binders	Office Supplies	Binders
OFF-LA-10004559	Avery 49	Office Supplies	Labels
OFF-AP-10000124	Acco 6 Outlet Guardian Basic Surge Suppressor	Office Supplies	Appliances
OFF-AP-10003057	Honeywell Enviracaire Portable HEPA Air Cleaner for 16' x 20' Room	Office Supplies	Appliances
OFF-BI-10002824	Recycled Easel Ring Binders	Office Supplies	Binders
OFF-BI-10000962	Acco Flexible ACCOHIDE Square Ring Data Binder, Dark Blue, 11 1/2" X 14" 7/8"	Office Supplies	Binders
OFF-BI-10001294	Fellowes Binding Cases	Office Supplies	Binders
OFF-AP-10003287	Tripp Lite TLP810NET Broadband Surge for Modem/Fax	Office Supplies	Appliances
OFF-ST-10000046	Fellowes Super Stor/Drawer Files	Office Supplies	Storage
OFF-ST-10000617	Woodgrain Magazine Files by Perma	Office Supplies	Storage
OFF-ST-10000675	File Shuttle II and Handi-File, Black	Office Supplies	Storage
OFF-BI-10000778	GBC VeloBinder Electric Binding Machine	Office Supplies	Binders
OFF-ST-10000352	Acco Perma 2700 Stacking Storage Drawers	Office Supplies	Storage
FUR-FU-10001095	DAX Black Cherry Wood-Tone Poster Frame	Furniture	Furnishings
OFF-SU-10002537	Acme Box Cutter Scissors	Office Supplies	Supplies
OFF-BI-10001098	Acco D-Ring Binder w/DublLock	Office Supplies	Binders
OFF-AR-10000817	Manco Dry-Lighter Erasable Highlighter	Office Supplies	Art
OFF-BI-10001510	Deluxe Heavy-Duty Vinyl Round Ring Binder	Office Supplies	Binders
OFF-PA-10004610	Xerox 1900	Office Supplies	Paper
TEC-AC-10003628	Logitech 910-002974 M325 Wireless Mouse for Web Scrolling	Technology	Accessories
OFF-PA-10001934	Xerox 1993	Office Supplies	Paper
OFF-FA-10004395	Plymouth Boxed Rubber Bands by Plymouth	Office Supplies	Fasteners
OFF-SU-10000946	Staple remover	Office Supplies	Supplies
OFF-AP-10003849	Hoover Shoulder Vac Commercial Portable Vacuum	Office Supplies	Appliances
FUR-CH-10004626	Office Star Flex Back Scooter Chair with Aluminum Finish Frame	Furniture	Chairs
FUR-BO-10003966	Sauder Facets Collection Library, Sky Alder Finish	Furniture	Bookcases
TEC-PH-10001619	LG G3	Technology	Phones
FUR-FU-10001602	Eldon Delta Triangular Chair Mat, 52" x 58", Clear	Furniture	Furnishings
OFF-ST-10002974	Trav-L-File Heavy-Duty Shuttle II, Black	Office Supplies	Storage
\.


--
-- TOC entry 5075 (class 0 OID 16610)
-- Dependencies: 227
-- Data for Name: dim_ship_mode; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dim_ship_mode (ship_mode_key, ship_mode) FROM stdin;
1	Second Class
2	Standard Class
3	Same Day
4	First Class
\.


--
-- TOC entry 5072 (class 0 OID 16566)
-- Dependencies: 224
-- Data for Name: fact_sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fact_sales (rowid, orderid, customerid, productid, postalcode, orderdate, sales, quantity, discount, profit, ship_mode_key) FROM stdin;
41815	US-2012-123218	KD-16345	FUR-BO-10003966	60623	2014-12-20	359.06	3	0.30	-71.81	2
41816	CA-2014-102729	BF-11215	OFF-ST-10000464	75217	2016-10-26	55.62	2	0.20	5.56	2
41817	CA-2013-136434	RD-19480	FUR-FU-10001196	47374	2015-12-02	17.31	3	0.00	5.19	2
41818	CA-2011-127446	MC-17590	OFF-LA-10000248	76017	2013-11-25	5.90	2	0.20	1.99	2
41819	CA-2013-160136	PJ-18835	OFF-PA-10002160	75217	2015-11-04	9.25	2	0.20	3.35	2
41820	CA-2013-116526	JA-15970	OFF-BI-10000320	48227	2015-09-02	29.52	4	0.00	14.46	2
41821	CA-2013-169838	BB-11545	FUR-TA-10001095	49201	2015-11-26	1568.61	9	0.00	329.41	2
41822	CA-2012-137064	TS-21655	OFF-ST-10003470	77070	2014-02-06	670.75	3	0.20	-125.77	2
41823	CA-2012-162621	CA-12055	OFF-BI-10000962	77036	2014-09-05	16.27	5	0.80	-25.22	2
41824	CA-2011-121006	SC-20020	OFF-AR-10001149	48640	2013-11-10	3.90	2	0.00	1.52	2
41825	CA-2013-130393	JM-15865	OFF-AP-10004859	76903	2015-12-02	11.65	4	0.80	-30.87	1
41826	CA-2014-100223	LS-16945	OFF-PA-10000232	75220	2016-07-05	15.55	3	0.20	5.64	2
41827	US-2012-161991	SC-20725	TEC-PH-10001760	77070	2014-09-26	1114.40	7	0.20	376.11	1
41828	CA-2012-105627	DK-12895	FUR-BO-10002916	53142	2014-03-08	512.94	3	0.00	97.46	2
41829	CA-2013-140130	HW-14935	OFF-AR-10004269	74133	2015-11-01	12.39	3	0.00	3.47	2
41830	CA-2014-137596	BE-11335	OFF-ST-10003816	49201	2016-09-02	352.38	2	0.00	81.05	2
41831	US-2011-141215	KL-16555	FUR-TA-10001520	78207	2013-06-15	99.92	2	0.30	-18.56	2
41832	CA-2014-134194	GA-14725	OFF-SU-10000946	75081	2016-12-25	44.69	7	0.20	5.03	2
41833	CA-2012-130365	ZC-21910	FUR-CH-10003535	60505	2014-04-25	128.06	3	0.30	-23.78	2
41834	CA-2011-169019	LF-17185	OFF-BI-10001524	78207	2013-07-26	16.78	4	0.80	-26.85	2
41835	CA-2014-140326	HW-14935	OFF-PA-10004041	60653	2016-09-04	17.76	3	0.20	5.55	4
41836	CA-2014-110821	CK-12205	TEC-AC-10001552	75081	2016-08-07	119.45	3	0.20	-13.44	4
41837	CA-2011-116904	SC-20095	OFF-ST-10000736	55407	2013-09-23	404.90	5	0.00	16.20	2
41838	CA-2014-159506	JR-16210	OFF-PA-10003641	47201	2016-11-27	158.28	6	0.00	72.81	2
41839	CA-2014-136882	DN-13690	FUR-FU-10003664	74133	2016-05-27	477.30	5	0.00	138.42	2
41840	CA-2012-139731	JE-15745	TEC-AC-10004975	79109	2014-10-15	263.88	3	0.20	42.88	3
41841	CA-2011-124646	DV-13465	OFF-ST-10001469	55407	2013-06-22	161.94	3	0.00	9.72	4
41842	CA-2012-124499	FM-14380	OFF-AP-10002191	48227	2014-10-09	269.91	5	0.10	53.98	2
41843	CA-2013-120824	AW-10930	OFF-PA-10000232	77070	2015-06-13	15.55	3	0.20	5.64	1
41844	CA-2013-130225	RC-19960	OFF-EN-10000056	77041	2015-09-12	99.57	2	0.20	33.60	2
41845	CA-2012-153717	DL-13495	FUR-BO-10004360	48227	2014-12-25	160.98	1	0.00	20.93	2
41846	CA-2012-100685	SM-20950	OFF-FA-10003472	68104	2014-12-19	5.04	4	0.00	0.20	1
41847	US-2011-141215	KL-16555	OFF-BI-10002706	78207	2013-06-15	8.57	3	0.80	-14.57	2
41848	CA-2011-166863	SC-20020	TEC-MA-10001972	75023	2013-06-20	418.80	2	0.40	-97.72	2
41849	CA-2013-132017	MH-17620	OFF-BI-10004001	77041	2015-09-27	6.82	2	0.80	-11.59	4
41850	US-2011-119081	TA-21385	OFF-BI-10004519	66062	2013-09-12	331.96	2	0.00	149.38	2
41851	CA-2013-122014	CD-11920	FUR-FU-10000672	67212	2015-12-30	70.56	6	0.00	23.99	2
41852	US-2014-104661	TB-21250	TEC-AC-10003628	78745	2016-01-16	47.98	2	0.20	14.40	4
41853	US-2012-163433	MP-17965	OFF-AR-10003373	78501	2014-04-18	74.35	3	0.20	6.51	1
41854	US-2011-127635	SC-20260	FUR-FU-10000550	78415	2013-09-14	9.96	5	0.60	-6.72	1
41855	CA-2013-168956	EA-14035	OFF-FA-10000304	60623	2015-02-16	6.98	4	0.20	1.83	2
41856	CA-2014-141439	TT-21460	FUR-FU-10001473	47374	2016-11-26	27.46	2	0.00	9.89	2
41857	CA-2014-124191	TS-21610	FUR-FU-10002364	60610	2016-06-12	8.86	3	0.60	-6.86	1
41858	CA-2013-146682	KW-16435	FUR-FU-10002671	48911	2015-10-30	67.00	5	0.00	32.16	4
41859	CA-2013-165148	PM-19135	FUR-FU-10000732	48227	2015-10-23	31.40	5	0.00	10.05	4
41860	CA-2014-141439	TT-21460	TEC-PH-10002624	47374	2016-11-26	1879.96	4	0.00	545.19	2
41861	CA-2014-110905	RW-19690	OFF-BI-10002954	65807	2016-09-10	13.71	3	0.00	6.58	1
41862	CA-2014-142776	RS-19870	OFF-EN-10003160	52601	2016-12-11	7.28	1	0.00	3.49	1
41863	CA-2013-101791	BS-11665	FUR-FU-10003247	60623	2015-05-28	25.18	3	0.60	-33.36	2
41864	CA-2011-123498	TC-20980	OFF-BI-10000632	77041	2013-11-07	26.05	3	0.80	-44.28	4
41865	CA-2013-150483	BP-11290	OFF-PA-10001846	62521	2015-06-01	18.50	4	0.20	6.70	2
41866	CA-2014-117807	DK-13090	OFF-PA-10000994	68025	2016-10-01	104.85	1	0.00	50.33	2
41867	CA-2014-111647	RD-19585	TEC-PH-10002726	75023	2016-07-03	167.97	4	0.20	62.99	2
41868	US-2013-110170	HM-14860	FUR-BO-10000780	77340	2015-09-28	956.66	7	0.32	-225.10	2
41869	CA-2014-101077	DB-13660	OFF-PA-10004239	75081	2016-03-25	6.85	2	0.20	2.14	1
41870	CA-2013-149349	SP-20650	FUR-FU-10001037	60623	2015-11-13	22.75	6	0.60	-8.53	4
41871	US-2011-112914	MT-18070	FUR-BO-10003272	77041	2013-09-25	300.53	2	0.32	-97.23	2
41872	CA-2014-129833	HF-14995	OFF-BI-10004182	46203	2016-12-09	10.40	5	0.00	5.10	2
41873	CA-2014-131282	CB-12025	OFF-BI-10004632	76706	2016-02-06	243.99	4	0.80	-426.99	1
41874	CA-2012-126557	RL-19615	TEC-PH-10003963	60610	2014-07-12	659.17	4	0.20	49.44	1
41875	CA-2013-116799	JG-15310	FUR-CH-10004983	79762	2015-03-04	563.43	5	0.30	-56.34	4
41876	CA-2013-159940	BF-11020	FUR-CH-10000785	60505	2015-07-08	253.37	2	0.30	-14.48	1
41877	CA-2013-130078	CC-12145	OFF-PA-10003270	73120	2015-08-09	10.56	2	0.00	4.75	2
41878	CA-2013-150007	AS-10090	OFF-LA-10001982	60653	2015-09-12	6.00	2	0.20	2.10	2
41879	CA-2014-148411	RO-19780	FUR-CH-10003973	60623	2016-09-24	520.46	2	0.30	-14.87	4
41880	CA-2012-126557	RL-19615	OFF-AR-10003190	60610	2014-07-12	6.91	3	0.20	0.69	1
41881	CA-2014-154214	TB-21595	FUR-FU-10000206	47201	2016-03-20	2.91	1	0.00	1.37	1
41882	CA-2013-154018	HA-14920	FUR-FU-10003394	78041	2015-10-14	139.92	5	0.60	-150.41	2
41883	CA-2011-121006	SC-20020	OFF-PA-10000130	48640	2013-11-10	12.84	3	0.00	5.78	2
41884	CA-2013-110898	LC-16870	OFF-BI-10004656	60623	2015-03-07	1.73	4	0.80	-2.76	2
41885	CA-2011-134103	MV-18190	OFF-ST-10000991	48234	2013-01-30	229.94	2	0.00	6.90	2
41886	CA-2013-156251	TS-21160	OFF-BI-10003529	53214	2015-08-14	8.52	3	0.00	4.17	1
41887	CA-2013-121601	MO-17500	OFF-EN-10003862	75056	2015-10-05	59.75	7	0.20	19.42	3
41888	CA-2012-109190	CC-12685	TEC-CO-10001943	79424	2014-10-23	479.98	3	0.20	161.99	2
41889	CA-2013-145730	CC-12220	OFF-EN-10000483	78207	2015-03-04	36.60	3	0.20	11.90	2
41890	CA-2012-123155	NS-18640	TEC-AC-10002473	78207	2014-03-09	113.52	5	0.20	29.80	4
41891	CA-2013-129903	GZ-14470	OFF-PA-10004040	55901	2015-12-02	23.92	4	0.00	11.72	1
41892	CA-2012-135622	TT-21460	OFF-PA-10000100	76106	2014-12-08	360.71	11	0.20	130.76	1
41893	CA-2011-148761	PA-19060	OFF-BI-10000666	54703	2013-05-17	91.68	3	0.00	45.84	2
41894	CA-2014-144820	LW-16825	OFF-AR-10004817	77506	2016-10-03	20.64	5	0.20	2.32	1
41895	CA-2013-120824	AW-10930	OFF-ST-10002562	77070	2015-06-13	67.54	9	0.20	6.75	1
41896	CA-2014-145884	SL-20155	FUR-TA-10002356	74403	2016-10-21	262.11	1	0.00	62.91	3
41897	CA-2013-114601	AA-10480	OFF-AR-10002578	48234	2015-08-27	8.64	3	0.00	2.51	2
41898	CA-2014-106432	CA-12265	FUR-BO-10004360	76706	2016-10-19	328.40	3	0.32	-91.76	2
41899	CA-2011-138940	GM-14455	TEC-PH-10001835	78745	2013-04-11	758.35	6	0.20	265.42	1
41900	US-2014-155299	Dl-13600	OFF-AP-10002203	77506	2016-06-08	1.62	2	0.80	-4.47	2
41901	CA-2014-113278	HR-14770	TEC-AC-10001445	47374	2016-01-15	12.12	4	0.00	2.55	2
41902	CA-2012-100818	JM-15265	OFF-BI-10004364	60653	2014-05-31	3.56	3	0.80	-6.24	1
41903	CA-2013-161816	NB-18655	OFF-LA-10004345	75217	2015-04-29	15.71	4	0.20	5.70	4
41904	US-2013-132423	MY-18295	OFF-AR-10001221	76051	2015-04-16	33.49	7	0.20	5.86	2
41905	US-2012-117184	ON-18715	OFF-BI-10002082	77095	2014-05-17	33.28	5	0.80	-49.92	2
41906	CA-2011-120775	RD-19930	OFF-LA-10002271	75217	2013-10-03	4.93	2	0.20	1.72	2
41907	CA-2013-121377	TN-21040	TEC-PH-10001817	60068	2015-05-29	286.40	1	0.20	25.06	2
41908	CA-2012-141243	AH-10465	OFF-AR-10001246	75217	2014-01-03	7.06	3	0.20	0.79	1
41909	CA-2013-147109	AH-10075	TEC-AC-10002942	76017	2015-12-18	165.60	3	0.20	-6.21	2
41910	CA-2012-121132	VB-21745	OFF-LA-10002368	77041	2014-07-17	6.26	3	0.20	2.04	2
41911	CA-2013-160220	JS-16030	TEC-PH-10001557	48183	2015-10-21	191.98	2	0.00	51.83	2
41912	CA-2014-167381	EH-14005	OFF-LA-10000134	48911	2016-09-22	27.72	9	0.00	13.31	1
41913	CA-2013-128867	CL-12565	OFF-AR-10000380	50322	2015-11-04	75.96	2	0.00	22.79	2
41914	US-2014-148362	KF-16285	OFF-BI-10003656	46203	2016-07-01	169.99	1	0.00	78.20	2
41915	CA-2014-127026	MH-18115	TEC-PH-10003601	49201	2016-01-22	164.99	1	0.00	49.50	2
41916	CA-2013-144337	SG-20890	OFF-PA-10000249	79109	2015-08-02	19.65	2	0.20	6.63	1
41917	CA-2013-159695	GM-14455	OFF-ST-10003442	77095	2015-04-06	158.37	7	0.20	13.86	1
41918	CA-2012-137064	TS-21655	OFF-BI-10002049	77070	2014-02-06	2.93	3	0.80	-4.99	2
41919	CA-2011-108273	EJ-13720	FUR-FU-10002116	77340	2013-12-16	56.57	2	0.60	-74.95	2
41920	US-2013-133879	KT-16465	OFF-BI-10004465	60623	2015-03-22	3.17	2	0.80	-4.75	2
41921	US-2012-122784	RA-19915	FUR-BO-10002545	60035	2014-07-20	913.43	5	0.30	-52.20	2
41922	CA-2012-166219	BP-11185	TEC-PH-10004165	75081	2014-08-28	1099.96	5	0.20	82.50	2
41923	US-2011-147704	SR-20740	OFF-EN-10004483	47401	2013-11-16	78.35	5	0.00	36.82	2
41924	CA-2013-162313	VB-21745	OFF-AP-10003842	48146	2015-11-28	167.29	6	0.10	29.74	4
41925	CA-2014-135692	CV-12805	OFF-LA-10001158	76106	2016-04-27	33.12	4	0.20	11.59	2
41926	US-2012-122784	RA-19915	TEC-PH-10001557	60035	2014-07-20	153.58	2	0.20	13.44	2
41927	CA-2014-123071	CC-12550	OFF-PA-10003729	75023	2016-12-03	10.37	2	0.20	3.63	4
41928	CA-2013-114944	HE-14800	OFF-PA-10003892	60623	2015-01-30	156.51	4	0.20	52.82	2
41929	CA-2011-152905	AB-10015	OFF-ST-10000321	76017	2013-02-18	12.62	2	0.20	-2.52	2
41930	CA-2014-144680	SC-20260	OFF-AP-10003040	76017	2016-03-31	33.62	5	0.80	-90.77	4
41931	CA-2014-111717	SW-20245	FUR-CH-10001545	60505	2016-10-10	239.36	3	0.30	-47.87	2
41932	CA-2011-127166	KH-16360	OFF-PA-10001560	77070	2013-05-21	4.83	1	0.20	1.63	1
41933	CA-2012-111395	VB-21745	OFF-BI-10002867	78207	2014-11-23	23.91	2	0.80	-40.65	2
41934	CA-2012-132941	MM-18280	OFF-PA-10002160	76117	2014-05-25	32.37	7	0.20	11.73	4
41935	CA-2012-163090	GH-14665	OFF-SU-10002537	60610	2014-11-17	40.92	5	0.20	3.07	1
41936	CA-2014-139311	SF-20965	OFF-PA-10001776	76021	2016-08-11	29.66	4	0.20	10.01	4
41937	CA-2014-167017	DC-12850	OFF-SU-10001935	48066	2016-11-23	4.36	2	0.00	0.17	4
41938	CA-2012-163055	DS-13180	OFF-ST-10002485	48227	2014-08-09	21.98	1	0.00	0.22	2
41939	CA-2013-142335	MP-17965	FUR-TA-10000198	48205	2015-12-16	1652.94	3	0.00	231.41	2
41940	CA-2014-100314	AS-10630	OFF-EN-10000461	77506	2016-09-29	27.97	4	0.20	9.44	2
41941	CA-2014-158953	ML-18040	OFF-BI-10002557	77489	2016-06-04	6.37	7	0.80	-9.56	2
41942	CA-2013-159940	BF-11020	FUR-FU-10004973	60505	2015-07-08	60.29	8	0.60	-27.13	1
41943	CA-2012-168809	MC-18100	OFF-BI-10000315	77041	2014-08-25	3.80	1	0.80	-6.08	3
41944	CA-2012-110863	AA-10645	OFF-PA-10000474	73120	2014-11-17	106.32	3	0.00	49.97	2
41945	US-2011-151015	BD-11500	OFF-BI-10000343	60653	2013-10-14	2.95	3	0.80	-4.86	2
41946	US-2013-115441	SH-19975	FUR-FU-10001756	53209	2015-07-26	95.20	5	0.00	27.61	1
41947	CA-2012-135853	CA-12775	TEC-PH-10003691	48205	2014-12-11	125.99	1	0.00	31.50	4
41948	CA-2013-157749	KL-16645	OFF-PA-10003349	60610	2015-06-05	25.92	5	0.20	9.40	1
41949	CA-2013-136595	EM-13825	FUR-FU-10004671	77036	2015-09-06	21.20	3	0.60	-11.66	4
41950	CA-2014-110905	RW-19690	OFF-AP-10003281	65807	2016-09-10	24.18	2	0.00	7.25	1
41951	CA-2013-149965	BS-11365	TEC-AC-10004877	73120	2015-06-21	6.90	1	0.00	0.55	2
41952	CA-2014-125115	RD-19930	OFF-PA-10004101	78745	2016-04-10	10.37	2	0.20	3.63	3
41953	CA-2013-169971	IL-15100	OFF-AR-10001044	77041	2015-09-05	62.38	3	0.20	7.02	2
41954	CA-2014-121559	HW-14935	OFF-AP-10002945	46203	2016-06-01	2405.20	8	0.00	793.72	1
41955	CA-2014-102659	LW-17215	OFF-BI-10000088	49505	2016-12-09	54.90	5	0.00	26.90	2
41956	CA-2012-121132	VB-21745	OFF-FA-10004248	77041	2014-07-17	14.43	4	0.20	3.43	2
41957	CA-2011-105893	PK-19075	OFF-ST-10004186	53711	2013-11-11	665.88	6	0.00	13.32	2
41958	CA-2011-120278	MS-17365	OFF-AP-10001293	54401	2013-11-07	245.88	6	0.00	68.85	2
41959	CA-2012-103961	NG-18430	OFF-LA-10004484	62301	2014-11-05	19.82	6	0.20	6.44	2
41960	US-2013-124163	SC-20695	OFF-AR-10000817	54601	2015-09-26	3.04	1	0.00	1.03	2
41961	CA-2013-108644	SJ-20215	OFF-BI-10000343	62301	2015-10-01	1.96	2	0.80	-3.24	4
41962	CA-2013-145009	RF-19345	OFF-LA-10004853	60610	2015-12-06	11.95	3	0.20	3.88	1
41963	CA-2014-135860	JH-15985	OFF-ST-10000642	48601	2016-12-01	83.92	4	0.00	5.87	2
41964	CA-2011-113859	BC-11125	FUR-CH-10004698	79762	2013-09-13	340.12	6	0.30	-9.72	2
41965	CA-2014-120376	TP-21130	TEC-AC-10000844	48227	2016-12-22	84.99	1	0.00	30.60	4
41966	CA-2014-121559	HW-14935	OFF-BI-10002072	46203	2016-06-01	17.38	2	0.00	8.69	1
41967	CA-2011-128888	PB-19105	OFF-EN-10003001	77095	2013-11-15	604.66	9	0.20	204.07	2
41968	US-2011-119081	TA-21385	OFF-SU-10000157	66062	2013-09-12	357.93	3	0.00	7.16	2
41969	CA-2014-155558	PG-18895	OFF-LA-10000134	55901	2016-10-26	6.16	2	0.00	2.96	2
41970	CA-2014-155047	SE-20110	OFF-AR-10003338	75220	2016-08-27	5.95	1	0.20	0.37	4
41971	US-2011-134712	BS-11380	OFF-FA-10003112	60076	2013-11-29	12.62	2	0.20	3.95	2
41972	CA-2011-131002	TB-21400	FUR-FU-10004665	74133	2013-09-07	821.88	6	0.00	213.69	1
41973	CA-2013-129196	XP-21865	TEC-AC-10002473	60610	2015-11-02	68.11	3	0.20	17.88	2
41974	CA-2011-154627	SA-20830	TEC-PH-10001363	60610	2013-10-29	2735.95	6	0.20	341.99	4
41975	US-2013-160206	MY-18295	TEC-PH-10000148	53209	2015-04-02	12.99	1	0.00	0.26	2
41976	CA-2014-109960	DB-13210	OFF-BI-10001636	48234	2016-12-09	33.72	4	0.00	15.51	1
41977	CA-2014-113208	ML-18040	FUR-FU-10004245	48126	2016-03-26	60.84	3	0.00	23.12	2
41978	CA-2011-168368	GA-14725	OFF-BI-10004654	65203	2013-02-11	51.90	3	0.00	24.39	1
41979	US-2014-119816	TT-21460	FUR-FU-10004848	77095	2016-03-04	103.50	5	0.60	-77.63	1
41980	US-2013-132577	JE-15475	OFF-BI-10004040	77095	2015-11-23	6.22	6	0.80	-9.63	2
41981	CA-2012-121405	FC-14335	TEC-PH-10002890	60610	2014-03-30	180.96	5	0.20	13.57	2
41982	CA-2012-109169	OT-18730	OFF-EN-10003296	48234	2014-04-20	180.96	2	0.00	81.43	2
41983	CA-2012-119690	MV-17485	OFF-LA-10001613	77041	2014-06-25	4.61	2	0.20	1.67	4
41984	US-2014-169502	MG-17650	OFF-AP-10001947	53209	2016-08-28	91.60	5	0.00	26.56	2
41985	CA-2014-144491	CJ-12010	FUR-BO-10001811	77070	2016-03-27	1023.33	5	0.32	-30.10	2
41986	CA-2011-130960	KB-16600	OFF-AR-10003651	48180	2013-12-30	9.84	3	0.00	2.85	2
41987	CA-2013-149965	BS-11365	FUR-FU-10004270	73120	2015-06-21	57.69	3	0.00	23.65	2
41988	CA-2014-118773	TP-21415	FUR-FU-10000550	77070	2016-02-10	3.98	2	0.60	-2.69	2
41989	US-2014-141677	HK-14890	TEC-CO-10002313	77070	2016-03-26	2399.96	5	0.20	569.99	2
41990	US-2011-112200	TC-21475	OFF-BI-10002571	60440	2013-11-22	9.98	5	0.80	-16.47	2
41991	CA-2011-117709	PM-18940	OFF-BI-10001294	49201	2013-05-04	46.80	4	0.00	21.06	2
41992	CA-2011-103086	EB-14170	FUR-FU-10004586	77095	2013-10-17	5.31	2	0.60	-1.59	1
41993	US-2013-133879	KT-16465	FUR-CH-10000665	60623	2015-03-22	528.43	5	0.30	0.00	2
41994	CA-2011-139892	BM-11140	OFF-AR-10004441	78207	2013-09-08	9.94	3	0.20	2.73	2
41995	US-2011-102631	EB-13840	FUR-FU-10003930	60623	2013-12-13	94.43	3	0.60	-42.49	2
41996	CA-2013-100671	CS-12490	OFF-ST-10004950	77301	2015-11-02	111.67	9	0.20	6.98	4
41997	CA-2011-141173	JC-16105	OFF-ST-10000885	55407	2013-11-18	67.15	5	0.00	16.79	1
41998	CA-2012-146563	CB-12025	OFF-BI-10003981	76017	2014-08-24	2.72	3	0.80	-4.22	2
41999	CA-2013-116526	JA-15970	OFF-AR-10004999	48227	2015-09-02	11.96	2	0.00	2.99	2
42000	CA-2014-162474	FH-14275	TEC-PH-10004700	60505	2016-03-13	7.99	1	0.20	2.60	4
42001	CA-2014-145877	AS-10090	OFF-ST-10000649	65807	2016-04-01	94.20	6	0.00	23.55	1
42002	CA-2014-112900	KL-16645	OFF-BI-10002867	48205	2016-04-09	478.24	8	0.00	219.99	1
42003	CA-2011-151001	JG-15805	OFF-ST-10003455	62521	2013-04-05	49.63	4	0.20	3.72	4
42004	CA-2014-103765	JG-15310	OFF-AP-10002311	79762	2016-11-24	13.76	1	0.80	-24.77	2
42005	US-2013-165078	MA-17995	OFF-LA-10000414	46226	2015-11-06	51.75	5	0.00	24.84	2
42006	US-2013-162103	LB-16795	OFF-BI-10000285	60035	2015-11-14	3.14	2	0.80	-4.70	2
42007	CA-2013-104150	AG-10330	OFF-EN-10002504	74133	2015-08-04	81.54	3	0.00	38.32	1
42008	CA-2013-150007	AS-10090	OFF-BI-10004141	60653	2015-09-12	1.91	3	0.80	-3.24	2
42009	US-2014-106663	MO-17800	FUR-TA-10000688	60653	2016-06-09	108.93	1	0.50	-71.89	2
42010	US-2011-100279	SW-20275	OFF-PA-10002259	48073	2013-03-10	22.38	2	0.00	10.74	2
42011	CA-2013-150483	BP-11290	FUR-CH-10000422	62521	2015-06-01	191.08	3	0.30	-38.22	2
42012	CA-2012-123673	CH-12070	TEC-PH-10001809	48227	2014-10-30	299.90	2	0.00	74.98	1
42013	CA-2014-112536	SG-20890	OFF-BI-10002571	78501	2016-05-18	2.00	1	0.80	-3.29	2
42014	CA-2014-141992	FO-14305	OFF-ST-10003656	75220	2016-06-19	153.58	2	0.20	-32.64	2
42015	CA-2012-154284	SZ-20035	TEC-MA-10004241	60174	2014-12-21	600.53	2	0.30	137.26	1
42016	CA-2013-152170	FH-14275	OFF-BI-10002072	46350	2015-11-13	17.38	2	0.00	8.69	1
42017	US-2013-141264	CT-11995	OFF-SU-10003505	75061	2015-08-14	185.38	2	0.20	-34.76	2
42018	US-2013-163461	BT-11440	OFF-PA-10003134	60423	2015-06-19	76.86	2	0.20	26.90	4
42019	CA-2013-121671	AA-10480	OFF-PA-10001934	65807	2015-07-18	51.84	8	0.00	25.40	2
42020	CA-2013-143406	LR-17035	OFF-AP-10001564	77041	2015-09-27	93.03	2	0.80	-251.19	2
42021	CA-2012-162621	CA-12055	OFF-SU-10003567	77036	2014-09-05	69.12	9	0.20	-14.69	2
42022	CA-2013-139395	MG-17650	TEC-PH-10002103	49201	2015-12-13	657.93	7	0.00	184.22	2
42023	CA-2014-113278	HR-14770	OFF-ST-10002562	47374	2016-01-15	18.76	2	0.00	5.25	2
42024	CA-2014-134194	GA-14725	OFF-BI-10001116	75081	2016-12-25	3.17	3	0.80	-5.07	2
42025	CA-2012-130365	ZC-21910	OFF-ST-10002574	60505	2014-04-25	221.02	2	0.20	-55.26	2
42026	US-2014-151316	MC-17635	OFF-PA-10000327	62521	2016-06-24	10.27	3	0.20	3.21	2
42027	CA-2012-166219	BP-11185	FUR-TA-10004607	75081	2014-08-28	103.48	1	0.30	-16.26	2
42028	CA-2013-157749	KL-16645	FUR-FU-10000576	60610	2015-06-05	419.68	5	0.60	-356.73	1
42029	US-2012-163685	KE-16420	OFF-PA-10002606	78207	2014-06-01	42.24	10	0.20	13.20	2
42030	CA-2011-103744	MG-17875	OFF-BI-10000320	79907	2013-02-23	4.43	3	0.80	-6.86	2
42031	CA-2014-157966	SU-20665	TEC-PH-10001527	60610	2016-03-13	34.36	1	0.20	-7.30	3
42032	CA-2013-149195	DM-13525	OFF-FA-10001843	77070	2015-09-06	15.81	8	0.20	5.34	1
42033	CA-2013-169838	BB-11545	TEC-AC-10004518	49201	2015-11-26	160.00	8	0.00	62.40	2
42034	US-2013-132423	MY-18295	OFF-FA-10002988	76051	2015-04-16	8.04	5	0.20	2.91	2
42035	CA-2013-167682	ZD-21925	TEC-PH-10000673	47374	2015-04-04	259.96	4	0.00	124.78	2
42036	CA-2011-161032	MK-17905	FUR-CH-10001482	53132	2013-11-18	392.94	3	0.00	43.22	2
42037	CA-2013-110044	RF-19735	TEC-PH-10001299	60610	2015-06-29	359.98	3	0.20	36.00	1
42038	CA-2012-114468	TD-20995	OFF-PA-10000809	60440	2014-08-23	10.37	2	0.20	3.63	3
42039	CA-2011-154165	DL-13315	OFF-AR-10003631	60653	2013-02-17	54.21	14	0.20	8.81	2
42040	US-2014-147221	JS-16030	FUR-FU-10004020	77036	2016-12-02	8.75	4	0.60	-3.72	1
42041	CA-2012-113222	AG-10765	OFF-BI-10001890	46226	2014-11-09	10.74	3	0.00	5.16	3
42042	CA-2012-132941	MM-18280	TEC-AC-10003095	76117	2014-05-25	207.98	2	0.20	36.40	4
42043	CA-2014-119746	CM-12385	TEC-PH-10004447	60610	2016-11-23	222.38	2	0.20	16.68	2
42044	CA-2013-112256	CK-12205	OFF-SU-10001165	78501	2015-07-24	13.34	2	0.20	1.00	2
42045	CA-2012-130022	JK-16120	OFF-AR-10001915	55122	2014-08-10	29.79	3	0.00	12.51	2
42046	CA-2013-125318	RC-19825	TEC-PH-10001433	60610	2015-06-07	328.22	4	0.20	28.72	2
42047	CA-2013-152170	FH-14275	OFF-AR-10003394	46350	2015-11-13	20.58	7	0.00	5.56	1
42048	CA-2012-101007	MS-17980	TEC-AC-10001266	75220	2014-02-09	20.80	2	0.20	6.50	1
42049	CA-2011-113880	VF-21715	OFF-PA-10003036	60126	2013-03-01	17.47	3	0.20	5.68	2
42050	CA-2011-146997	SG-20605	OFF-FA-10003467	47905	2013-01-23	5.94	3	0.00	0.00	2
42051	CA-2014-114440	TB-21520	OFF-PA-10004675	49201	2016-09-14	19.05	3	0.00	8.76	1
42052	US-2012-138121	JL-15835	OFF-BI-10000320	48205	2014-12-17	29.52	4	0.00	14.46	3
42053	CA-2012-159863	DS-13180	TEC-AC-10000109	77095	2014-09-04	134.38	3	0.20	6.72	1
42054	CA-2011-124478	MA-17560	TEC-PH-10001128	48183	2013-08-08	299.98	2	0.00	83.99	2
42055	CA-2012-120397	RB-19435	OFF-AP-10001293	77070	2014-07-02	32.78	4	0.80	-85.24	3
42056	US-2014-118157	AW-10930	OFF-EN-10004459	55407	2016-11-14	15.28	2	0.00	7.49	4
42057	CA-2014-157091	DB-13405	FUR-FU-10000293	46350	2016-06-26	526.45	5	0.00	31.59	2
42058	CA-2013-158925	JP-15460	OFF-PA-10003072	77041	2015-10-25	15.55	3	0.20	5.44	2
42059	CA-2011-148950	JD-16015	OFF-BI-10001249	60610	2013-12-14	5.10	4	0.80	-8.68	2
42060	CA-2014-158876	AB-10150	OFF-AR-10003373	75007	2016-11-19	99.14	4	0.20	8.67	1
42061	CA-2014-135860	JH-15985	OFF-ST-10001522	48601	2016-12-01	91.99	1	0.00	3.68	2
42062	CA-2013-129847	TA-21385	FUR-FU-10000277	60653	2015-09-03	84.27	2	0.60	-75.84	4
42063	CA-2014-117324	JP-15520	OFF-AP-10003590	53711	2016-12-08	1089.75	3	0.00	305.13	2
42064	CA-2013-160108	AG-10900	FUR-BO-10003450	54703	2015-12-09	405.86	7	0.00	32.47	2
42065	CA-2011-166863	SC-20020	FUR-BO-10001608	75023	2013-06-20	193.07	4	0.32	-19.87	2
42066	CA-2014-163006	GH-14410	FUR-FU-10003799	60653	2016-06-30	14.22	2	0.60	-10.31	1
42067	CA-2014-164168	LS-16975	FUR-FU-10001756	75081	2016-11-12	22.85	3	0.60	-17.71	2
42068	US-2014-123834	GM-14500	FUR-TA-10001676	78577	2016-07-21	124.40	4	0.30	-21.33	2
42069	US-2013-157945	NF-18385	FUR-CH-10002331	62521	2015-09-27	747.56	3	0.30	-96.11	2
42070	CA-2013-119963	SN-20710	OFF-AR-10003514	77506	2015-11-19	6.37	2	0.20	1.03	2
42071	CA-2013-157749	KL-16645	FUR-FU-10004351	60610	2015-06-05	11.69	3	0.60	-4.68	1
42072	CA-2011-103100	AB-10105	OFF-BI-10004600	46203	2013-12-20	1103.97	3	0.00	496.79	4
42073	CA-2011-163867	RE-19450	FUR-FU-10001475	62521	2013-06-03	61.54	7	0.60	-40.00	4
42074	CA-2012-124107	BM-11650	TEC-AC-10002049	48104	2014-10-09	619.95	5	0.00	111.59	1
42075	CA-2011-158442	AZ-10750	OFF-PA-10002365	75217	2013-03-17	15.55	3	0.20	5.44	3
42076	CA-2014-166317	JE-15610	OFF-PA-10004475	53209	2016-09-22	219.84	4	0.00	107.72	2
42077	CA-2014-113278	HR-14770	TEC-PH-10000169	47374	2016-01-15	67.80	4	0.00	1.36	2
42078	CA-2013-166240	DH-13075	OFF-AP-10002082	77095	2015-06-25	8.71	2	0.80	-19.60	2
42079	CA-2011-165309	KD-16270	OFF-PA-10001033	77095	2013-11-11	262.34	8	0.20	95.10	2
42080	CA-2011-105417	VS-21820	OFF-BI-10003708	77340	2013-01-07	10.43	7	0.80	-18.25	2
42081	CA-2013-108364	BP-11050	OFF-BI-10002012	60623	2015-12-20	1.80	5	0.80	-2.88	2
42082	CA-2014-113278	HR-14770	OFF-ST-10001590	47374	2016-01-15	67.40	5	0.00	17.52	2
42083	US-2014-139969	AF-10870	FUR-CH-10001973	77840	2016-11-19	233.06	3	0.30	-53.27	2
42084	US-2011-112949	Co-12640	OFF-AP-10001005	73505	2013-06-20	471.90	6	0.00	155.73	2
42085	US-2013-131611	EP-13915	OFF-BI-10004364	77036	2015-11-06	3.56	3	0.80	-6.24	2
42086	US-2011-106299	NZ-18565	TEC-AC-10003237	65807	2013-08-02	21.20	2	0.00	9.12	2
42087	CA-2014-117324	JP-15520	FUR-BO-10003159	53711	2016-12-08	459.92	4	0.00	41.39	2
42088	CA-2013-101966	BM-11785	TEC-PH-10003437	77036	2015-07-15	419.94	7	0.20	52.49	1
42089	CA-2012-168809	MC-18100	FUR-FU-10002240	77041	2014-08-25	7.88	5	0.60	-3.94	3
42090	CA-2012-154326	RP-19855	TEC-PH-10001819	53142	2014-02-15	134.97	3	0.00	64.79	2
42091	CA-2012-118955	LS-17230	OFF-PA-10004156	75051	2014-06-16	27.22	3	0.20	9.87	2
42092	CA-2013-103982	AA-10315	TEC-PH-10000895	78664	2015-03-04	431.98	3	0.20	32.40	2
42093	CA-2011-130575	CS-11845	OFF-BI-10002353	60623	2013-12-14	9.26	3	0.80	-13.90	4
42094	CA-2011-101602	MC-18100	TEC-PH-10000169	79907	2013-12-15	40.68	3	0.20	-9.15	4
42095	US-2014-159562	JB-16000	OFF-EN-10000461	48066	2016-09-09	17.48	2	0.00	8.22	2
42096	CA-2014-135860	JH-15985	OFF-FA-10000134	48601	2016-12-01	52.29	9	0.00	16.21	2
42097	CA-2011-167927	XP-21865	OFF-ST-10003123	48185	2013-01-20	66.58	2	0.00	15.98	2
42098	CA-2014-140326	HW-14935	FUR-BO-10000112	60653	2016-09-04	825.17	9	0.30	-117.88	4
42099	CA-2011-131926	DW-13480	FUR-CH-10004063	55044	2013-06-01	2001.86	7	0.00	580.54	1
42100	CA-2011-132542	AM-10360	OFF-BI-10004099	68104	2013-10-06	15.36	2	0.00	7.68	1
42101	CA-2011-149104	RD-19900	OFF-BI-10004209	48127	2013-04-05	40.20	5	0.00	18.09	1
42102	CA-2011-126200	JE-15715	OFF-BI-10002225	77070	2013-08-25	12.38	3	0.80	-19.81	2
42103	CA-2014-117401	PP-18955	OFF-AP-10000938	65807	2016-05-18	706.86	7	0.00	197.92	1
42104	CA-2013-139395	MG-17650	OFF-ST-10000885	49201	2015-12-13	26.86	2	0.00	6.72	2
42105	CA-2014-118773	TP-21415	OFF-AP-10000055	77070	2016-02-10	12.99	2	0.80	-32.48	2
42106	CA-2014-130211	BD-11620	OFF-ST-10000129	73505	2016-10-22	333.09	3	0.00	23.32	3
42107	CA-2012-138009	SF-20965	OFF-AR-10004042	48126	2014-11-29	161.82	9	0.00	46.93	2
42108	CA-2013-159737	CS-11950	OFF-BI-10004236	60610	2015-09-04	8.81	3	0.80	-14.97	2
42109	US-2014-124926	ME-17320	OFF-AP-10004868	77095	2016-11-13	9.32	6	0.80	-24.71	1
42110	CA-2011-111150	RW-19630	OFF-AR-10000034	65203	2013-12-31	29.68	7	0.00	11.58	2
42111	CA-2013-126284	EN-13780	OFF-BI-10004828	49505	2015-09-21	83.70	5	0.00	41.01	2
42112	CA-2014-120999	LC-16930	TEC-PH-10004093	60540	2016-09-10	147.17	4	0.20	16.56	2
42113	CA-2014-164042	KL-16645	OFF-ST-10002301	77095	2016-05-23	48.82	3	0.20	-11.59	2
42114	CA-2013-147375	PO-19180	OFF-PA-10001970	60623	2015-06-13	313.49	7	0.20	113.64	1
42115	US-2014-125647	LC-16870	TEC-PH-10004188	60653	2016-09-23	39.98	2	0.20	-9.00	2
42116	CA-2014-118213	AB-10060	OFF-PA-10002615	46142	2016-11-05	4.41	1	0.00	2.03	4
42117	US-2013-124163	SC-20695	FUR-FU-10000755	54601	2015-09-26	68.64	11	0.00	17.16	2
42118	CA-2014-104108	RP-19855	OFF-AR-10000817	77095	2016-12-02	12.16	5	0.20	2.13	2
42119	CA-2012-121405	FC-14335	OFF-PA-10001838	60610	2014-03-30	23.52	5	0.20	8.53	2
42120	CA-2014-160122	RD-19930	OFF-EN-10002592	60623	2016-11-18	55.58	6	0.20	20.84	2
42121	CA-2013-163398	CB-12415	OFF-BI-10000014	60653	2015-05-04	2.18	1	0.80	-3.60	2
42122	CA-2014-112809	RA-19915	OFF-BI-10001636	75220	2016-08-18	6.74	4	0.80	-11.46	2
42123	CA-2011-104738	SP-20620	TEC-PH-10000576	78041	2013-12-30	328.78	3	0.20	28.77	1
42124	CA-2012-154956	IM-15070	TEC-PH-10004165	53209	2014-07-04	1099.96	4	0.00	285.99	2
42125	CA-2012-124107	BM-11650	OFF-EN-10003286	48104	2014-10-09	57.96	7	0.00	27.24	1
42126	CA-2012-160472	RK-19300	OFF-ST-10000464	46614	2014-07-20	34.76	1	0.00	9.73	1
42127	CA-2013-114489	JE-16165	TEC-PH-10001448	53132	2015-12-06	149.97	3	0.00	6.00	2
42128	CA-2014-144883	BO-11350	OFF-LA-10000305	55113	2016-08-15	50.40	8	0.00	23.18	2
42129	CA-2013-160815	TR-21325	TEC-PH-10003505	52402	2015-09-06	278.40	3	0.00	80.74	4
42130	US-2011-137869	CV-12295	OFF-EN-10001509	50315	2013-03-28	6.12	3	0.00	2.88	2
42131	CA-2014-126074	RF-19735	OFF-BI-10000546	48183	2016-10-02	2.88	1	0.00	1.41	2
42132	CA-2013-115756	PK-19075	OFF-ST-10003058	48227	2015-09-06	70.95	3	0.00	20.58	1
42133	CA-2013-116526	JA-15970	OFF-BI-10004728	48227	2015-09-02	24.10	5	0.00	11.09	2
42134	CA-2013-114104	NP-18670	OFF-LA-10002475	73034	2015-11-21	14.62	2	0.00	6.87	2
42135	US-2014-129203	BM-11575	OFF-ST-10001418	60653	2016-04-17	195.14	4	0.20	-43.91	2
42136	CA-2013-158806	NM-18520	OFF-PA-10004621	79109	2015-01-07	25.92	5	0.20	9.07	2
42137	CA-2014-142034	KB-16240	TEC-AC-10002305	56301	2016-09-24	72.00	4	0.00	12.96	2
42138	CA-2011-135405	MS-17830	TEC-AC-10001266	78041	2013-01-09	31.20	3	0.20	9.75	2
42139	CA-2012-121650	KD-16495	FUR-CH-10004289	49201	2014-12-10	191.96	2	0.00	32.63	2
42140	CA-2012-126697	SV-20815	TEC-PH-10002922	77041	2014-09-21	946.34	7	0.20	118.29	4
42141	CA-2011-148950	JD-16015	TEC-AC-10002718	60610	2013-12-14	35.02	3	0.20	-2.19	2
42142	CA-2014-163265	JS-16030	FUR-CH-10004063	62521	2016-02-17	600.56	3	0.30	-8.58	2
42143	CA-2013-163636	MP-18175	OFF-AR-10001547	60623	2015-12-06	3.54	2	0.20	0.31	1
42144	CA-2013-144540	GH-14410	OFF-AP-10002457	77070	2015-09-06	62.79	3	0.80	-166.39	2
42145	CA-2011-126802	ZC-21910	FUR-FU-10000193	60610	2013-12-29	38.98	3	0.60	-50.67	2
42146	CA-2013-160220	JS-16030	TEC-PH-10001300	48183	2015-10-21	125.70	6	0.00	35.20	2
42147	CA-2011-137274	MG-18145	FUR-TA-10001889	75023	2013-03-29	890.84	3	0.30	-152.72	2
42148	CA-2012-153717	DL-13495	OFF-PA-10002160	48227	2014-12-25	17.34	3	0.00	8.50	2
42149	CA-2013-162082	JS-15880	OFF-AR-10001044	78550	2015-03-15	145.54	7	0.20	16.37	4
42150	CA-2014-108294	LS-16975	OFF-BI-10004965	68104	2016-12-10	34.50	3	0.00	15.53	3
42151	CA-2014-100223	LS-16945	FUR-FU-10003601	75220	2016-07-05	332.03	9	0.60	-348.63	2
42152	CA-2014-102337	SD-20485	TEC-PH-10002564	60653	2016-06-13	47.98	2	0.20	6.00	4
42153	CA-2013-103037	KH-16630	OFF-LA-10004345	77070	2015-07-26	15.71	4	0.20	5.70	2
42154	CA-2013-168032	DF-13135	FUR-TA-10004256	61107	2015-01-30	626.10	3	0.50	-538.45	2
42155	US-2014-111920	PS-18970	OFF-AR-10003179	74133	2016-10-22	36.44	4	0.00	12.03	2
42156	CA-2014-109946	PL-18925	OFF-AR-10001419	60610	2016-04-16	16.52	5	0.20	2.07	2
42157	CA-2013-147970	AB-10150	OFF-PA-10003936	75220	2015-01-31	15.55	3	0.20	5.44	1
42158	CA-2012-100685	SM-20950	OFF-BI-10003094	68104	2014-12-19	7.04	2	0.00	3.31	1
42159	CA-2011-143903	KM-16375	OFF-ST-10003306	75217	2013-07-20	342.86	3	0.20	38.57	2
42160	CA-2011-121629	BT-11680	TEC-MA-10004679	77041	2013-11-28	998.85	5	0.40	-199.77	2
42161	CA-2012-153381	DE-13255	FUR-CH-10000988	52001	2014-09-24	1408.10	10	0.00	394.27	2
42162	CA-2013-100041	BF-10975	OFF-PA-10000418	47201	2015-11-21	314.55	3	0.00	150.98	2
42163	CA-2013-150483	BP-11290	FUR-FU-10001379	62521	2015-06-01	32.06	3	0.60	-12.83	2
42164	CA-2014-121160	FM-14290	OFF-BI-10004040	77803	2016-11-04	4.14	4	0.80	-6.42	3
42165	CA-2014-161739	EB-13750	FUR-FU-10001468	78664	2016-11-10	341.96	5	0.60	-427.45	1
42166	US-2013-117793	MA-17560	OFF-LA-10003537	53081	2015-08-24	37.59	3	0.00	17.67	2
42167	CA-2012-130022	JK-16120	OFF-LA-10002043	55122	2014-08-10	41.40	4	0.00	19.87	2
42168	CA-2013-105732	AG-10270	OFF-PA-10001838	68104	2015-09-14	17.64	3	0.00	8.64	2
42169	CA-2011-130673	MC-17590	OFF-PA-10000289	78666	2013-05-20	10.37	2	0.20	3.63	1
42170	CA-2011-101147	MC-17575	OFF-AP-10004249	60623	2013-12-02	2.39	1	0.80	-6.34	4
42171	CA-2013-110898	LC-16870	FUR-FU-10003773	60623	2015-03-07	159.04	5	0.60	-194.82	2
42172	CA-2013-113551	NF-18385	OFF-PA-10004665	78539	2015-08-19	83.84	8	0.20	30.39	4
42173	US-2014-141677	HK-14890	OFF-PA-10002581	77070	2016-03-26	74.35	3	0.20	23.24	2
42174	CA-2012-119690	MV-17485	OFF-BI-10000201	77041	2014-06-25	0.98	2	0.80	-1.48	4
42175	US-2013-146710	SS-20875	OFF-PA-10002615	75220	2015-08-28	3.53	1	0.20	1.15	2
42176	US-2011-103905	AW-10930	OFF-BI-10001098	60505	2013-07-14	29.93	7	0.80	-46.39	2
42177	CA-2014-145093	PT-19090	OFF-BI-10001116	60623	2016-07-21	2.11	2	0.80	-3.38	2
42178	CA-2013-128923	GB-14530	OFF-PA-10002250	76106	2015-12-10	9.39	2	0.20	3.29	2
42179	CA-2014-141719	EG-13900	TEC-AC-10003610	60540	2016-11-17	239.96	5	0.20	83.99	1
42180	CA-2011-131926	DW-13480	OFF-ST-10002276	55044	2013-06-01	166.72	2	0.00	41.68	1
42181	CA-2014-167549	EM-14200	FUR-TA-10004767	75217	2016-07-25	298.12	6	0.30	-4.26	4
42182	CA-2014-131016	DC-12850	OFF-ST-10000352	76017	2016-09-18	47.58	2	0.20	-2.97	4
42183	CA-2011-134572	SV-20365	FUR-TA-10004442	77070	2013-04-20	401.59	2	0.30	-131.95	1
42184	CA-2012-131856	JG-15160	FUR-FU-10000175	77041	2014-05-12	21.97	4	0.60	-15.93	2
42185	CA-2013-133340	LH-17155	TEC-PH-10003988	49201	2015-12-10	10.90	1	0.00	3.05	2
42186	CA-2011-127159	HL-15040	FUR-FU-10000010	53209	2013-05-12	34.79	7	0.00	10.78	4
42187	CA-2014-115651	NS-18640	OFF-AR-10001130	60610	2016-07-09	8.84	5	0.20	2.98	4
42188	CA-2013-137330	KB-16585	OFF-AP-10001492	68025	2015-12-10	60.34	7	0.00	15.69	2
42189	CA-2012-153878	TS-21655	OFF-AR-10000658	53209	2014-04-25	57.75	5	0.00	16.17	2
42190	CA-2011-100762	NG-18355	OFF-LA-10003930	49201	2013-11-24	196.62	2	0.00	96.34	2
42191	CA-2014-137449	ME-17725	FUR-TA-10002855	75220	2016-06-29	307.31	3	0.30	-39.51	4
42192	CA-2014-152079	ML-17410	OFF-LA-10001613	60653	2016-01-21	11.52	5	0.20	4.18	4
42193	CA-2014-152702	SN-20710	FUR-CH-10002304	61107	2016-10-12	254.60	14	0.30	-18.19	2
42194	CA-2014-154718	DL-12865	OFF-LA-10003714	76248	2016-01-20	6.00	2	0.20	2.10	1
42195	US-2011-140452	BK-11260	OFF-BI-10004965	60610	2013-12-06	4.60	2	0.80	-8.05	2
42196	CA-2014-143252	HE-14800	TEC-AC-10002331	53209	2016-12-18	29.34	3	0.00	10.86	2
42197	CA-2014-167227	NP-18670	OFF-PA-10001838	63116	2016-11-02	11.76	2	0.00	5.76	4
42198	CA-2013-168032	DF-13135	OFF-BI-10000546	61107	2015-01-30	1.73	3	0.80	-2.68	2
42199	US-2012-138121	JL-15835	FUR-FU-10002116	48205	2014-12-17	212.13	3	0.00	14.85	3
42200	CA-2011-167927	XP-21865	OFF-BI-10000605	48185	2013-01-20	19.05	5	0.00	8.95	2
42201	CA-2014-130351	RB-19570	TEC-AC-10003832	47201	2016-12-05	99.39	3	0.00	40.75	4
42202	CA-2014-128426	JK-15730	OFF-BI-10000756	77036	2016-10-07	4.24	5	0.80	-6.36	2
42203	CA-2012-168480	DM-12955	OFF-AR-10001044	48146	2014-09-21	25.99	1	0.00	7.54	2
42204	CA-2011-163468	JK-15730	FUR-BO-10003546	60016	2013-11-18	424.12	6	0.30	-30.29	4
42205	CA-2012-121650	KD-16495	OFF-LA-10001045	49201	2014-12-10	2.61	1	0.00	1.20	2
42206	CA-2011-146283	KT-16465	OFF-PA-10002259	77036	2013-09-08	17.90	2	0.20	6.27	2
42207	CA-2012-143077	SF-20965	FUR-FU-10003535	77041	2014-09-17	21.94	2	0.60	-10.42	2
42208	CA-2011-161508	PV-18985	OFF-AR-10003158	77573	2013-07-12	22.29	7	0.20	3.90	2
42209	CA-2011-107769	BT-11395	TEC-PH-10001336	67846	2013-10-28	257.98	2	0.00	74.81	2
42210	CA-2013-108987	AG-10675	TEC-AC-10000158	77036	2015-09-09	57.58	2	0.20	0.72	1
42211	CA-2014-122595	GM-14455	FUR-FU-10002963	60653	2016-12-14	2.03	1	0.60	-1.32	2
42212	CA-2013-139395	MG-17650	OFF-AR-10003732	49201	2015-12-13	13.90	5	0.00	3.61	2
42213	CA-2011-144029	MM-18055	OFF-ST-10001837	60623	2013-05-26	102.62	3	0.20	7.70	2
42214	CA-2011-149104	RD-19900	OFF-ST-10000991	48127	2013-04-05	689.82	6	0.00	20.69	1
42215	CA-2011-152618	RB-19465	OFF-PA-10001215	60653	2013-03-14	8.45	2	0.20	2.64	4
42216	CA-2014-100615	SJ-20215	FUR-CH-10002602	60653	2016-04-20	317.06	3	0.30	-18.12	2
42217	CA-2013-122063	MM-17920	FUR-CH-10004754	47374	2015-12-04	29.98	1	0.00	8.09	2
42218	US-2011-150924	PT-19090	OFF-BI-10004040	77070	2013-09-12	5.18	5	0.80	-8.03	1
42219	CA-2014-155642	BM-11575	FUR-FU-10001918	60653	2016-05-18	1.89	1	0.60	-0.99	2
42220	CA-2013-162726	MT-17815	OFF-PA-10001972	77642	2015-12-28	10.37	2	0.20	3.63	2
42221	CA-2014-117324	JP-15520	OFF-PA-10002713	53711	2016-12-08	27.52	4	0.00	12.66	2
42222	CA-2012-124541	TT-21220	OFF-BI-10004209	77041	2014-04-06	9.65	6	0.80	-16.88	2
42223	CA-2014-122077	JF-15295	TEC-PH-10003811	75023	2016-05-19	95.99	1	0.20	9.60	2
42224	CA-2014-149048	BM-11650	OFF-EN-10003296	47201	2016-05-13	180.96	2	0.00	81.43	2
42225	CA-2014-117653	MO-17500	FUR-TA-10003008	60623	2016-10-19	91.28	1	0.50	-67.54	2
42226	US-2013-115441	SH-19975	TEC-AC-10003116	53209	2015-07-26	124.25	7	0.00	48.46	1
42227	CA-2013-100041	BF-10975	OFF-PA-10001622	47201	2015-11-21	9.08	2	0.00	4.09	2
42228	CA-2012-135685	MP-18175	FUR-FU-10001185	53209	2014-11-16	185.58	6	0.00	76.09	1
42229	CA-2012-140921	AA-10375	FUR-FU-10003347	68104	2014-02-03	28.40	2	0.00	11.08	4
42230	CA-2013-104311	AS-10090	OFF-ST-10002957	75061	2015-05-03	12.67	3	0.20	-3.17	2
42231	US-2012-118983	HP-14815	OFF-AP-10002311	76106	2014-11-22	68.81	5	0.80	-123.86	2
42232	CA-2014-139311	SF-20965	OFF-AR-10004582	76021	2016-08-11	9.18	7	0.20	2.87	4
42233	US-2013-110156	EH-13945	OFF-BI-10002609	77041	2015-11-20	1.19	2	0.80	-2.03	2
42234	CA-2012-129700	LA-16780	FUR-FU-10001940	60477	2014-05-04	22.29	7	0.60	-8.92	4
42235	CA-2013-105732	AG-10270	OFF-ST-10004340	68104	2015-09-14	373.08	6	0.00	100.73	2
42236	CA-2013-144764	RL-19615	OFF-ST-10002485	60623	2015-09-03	35.17	2	0.20	-8.35	2
42237	CA-2014-132122	JH-15820	OFF-ST-10003692	60610	2016-07-09	228.92	5	0.20	14.31	2
42238	CA-2014-114370	BN-11470	TEC-PH-10000213	60623	2016-03-14	49.62	2	0.20	4.96	1
42239	CA-2014-142867	PO-19180	OFF-BI-10003166	77095	2016-03-17	13.78	6	0.80	-22.04	2
42240	CA-2013-143924	SC-20680	OFF-FA-10000735	49423	2015-07-29	20.44	7	0.00	9.20	2
42241	CA-2012-115742	DP-13000	OFF-LA-10002762	47150	2014-04-18	75.18	6	0.00	35.33	2
42242	CA-2013-112256	CK-12205	OFF-AR-10001953	78501	2015-07-24	175.92	5	0.20	15.39	2
42243	US-2011-139500	AB-10165	FUR-CH-10002017	62521	2013-11-16	37.30	2	0.30	-1.07	2
42244	CA-2011-169446	SG-20605	TEC-PH-10002817	60623	2013-12-19	323.98	3	0.20	36.45	2
42245	CA-2011-140473	MC-17425	TEC-CO-10004202	60623	2013-05-30	719.98	3	0.20	135.00	2
42246	CA-2013-157749	KL-16645	FUR-TA-10002607	60610	2015-06-05	177.23	5	0.50	-120.51	1
42247	CA-2011-162866	Co-12640	FUR-FU-10001473	60076	2013-12-27	32.95	6	0.60	-19.77	2
42248	CA-2011-108273	EJ-13720	OFF-PA-10000029	77340	2013-12-16	36.29	7	0.20	12.70	2
42249	CA-2011-158442	AZ-10750	OFF-PA-10002195	75217	2013-03-17	5.18	1	0.20	1.88	3
42250	CA-2011-120852	WB-21850	TEC-AC-10004510	75051	2013-12-20	65.44	5	0.20	-8.18	2
42251	US-2014-117247	CK-12760	FUR-TA-10001676	60505	2016-10-09	66.65	3	0.50	-42.65	2
42252	US-2012-138121	JL-15835	FUR-CH-10004875	48205	2014-12-17	142.36	2	0.00	38.44	3
42253	CA-2013-149195	DM-13525	OFF-PA-10001870	77070	2015-09-06	25.92	5	0.20	9.07	1
42254	CA-2013-168361	KB-16600	OFF-BI-10003727	60623	2015-06-22	0.84	1	0.80	-1.34	2
42255	CA-2013-128531	NS-18505	OFF-FA-10002676	75217	2015-11-25	4.34	3	0.20	0.87	1
42256	CA-2014-161774	GT-14710	TEC-PH-10004071	77041	2016-05-14	7.99	1	0.20	0.70	4
42257	CA-2012-157035	KB-16600	OFF-PA-10004156	47201	2014-12-09	34.02	3	0.00	16.67	4
42258	CA-2011-165379	BM-11650	OFF-PA-10003072	75217	2013-07-09	10.37	2	0.20	3.63	2
42259	US-2013-131611	EP-13915	FUR-TA-10002774	77036	2015-11-06	863.13	8	0.30	-160.30	2
42260	CA-2011-169446	SG-20605	OFF-PA-10000295	60623	2013-12-19	15.55	3	0.20	5.44	2
42261	CA-2011-112326	PO-19195	OFF-ST-10002743	60540	2013-01-04	272.74	3	0.20	-64.77	2
42262	CA-2014-110373	MA-17560	OFF-AR-10003045	60610	2016-10-27	7.06	3	0.20	2.21	1
42263	CA-2013-164938	PB-19210	TEC-PH-10004897	74133	2015-02-11	69.93	7	0.00	0.70	4
42264	CA-2013-143441	EB-14170	OFF-LA-10002312	78041	2015-11-06	11.84	1	0.20	4.44	3
42265	CA-2014-107825	NB-18655	OFF-ST-10001321	53209	2016-11-18	92.52	6	0.00	24.98	3
42266	CA-2011-161508	PV-18985	FUR-CH-10002126	77573	2013-07-12	512.36	3	0.30	-14.64	2
42267	CA-2012-118738	AG-10495	FUR-TA-10002607	77041	2014-10-24	347.36	7	0.30	-69.47	2
42268	CA-2011-142510	NP-18700	OFF-ST-10000585	60623	2013-12-22	132.16	1	0.20	9.91	2
42269	CA-2012-108532	CC-12100	TEC-AC-10004510	48234	2014-08-29	114.52	7	0.00	11.45	2
42270	US-2014-158218	AC-10420	OFF-BI-10002133	77041	2016-05-12	34.24	4	0.80	-53.07	1
42271	CA-2014-121580	ML-17410	FUR-FU-10003981	47201	2016-05-29	6.24	3	0.00	2.62	2
42272	CA-2011-165309	KD-16270	OFF-BI-10001359	77095	2013-11-11	896.99	5	0.80	-1480.03	2
42273	US-2013-146710	SS-20875	OFF-SU-10004261	75220	2015-08-28	55.17	4	0.20	6.21	2
42274	US-2013-131611	EP-13915	TEC-AC-10004001	77036	2015-11-06	171.96	5	0.20	45.14	2
42275	US-2014-103814	LH-16900	OFF-PA-10001019	60068	2016-12-09	143.86	9	0.20	48.55	2
42276	CA-2013-122903	LA-16780	OFF-PA-10000994	48205	2015-05-28	314.55	3	0.00	150.98	1
42277	CA-2014-121615	DL-12925	OFF-LA-10001771	55122	2016-11-03	14.94	3	0.00	6.87	2
42278	US-2013-117037	LW-17215	OFF-PA-10000791	60653	2015-05-18	30.53	8	0.20	9.54	4
42279	CA-2014-150497	SM-20950	OFF-BI-10004600	55369	2016-07-20	735.98	2	0.00	331.19	2
42280	CA-2013-119935	KM-16225	FUR-FU-10001085	65807	2015-11-11	37.30	2	0.00	17.16	2
42281	CA-2013-156748	BS-11755	FUR-CH-10000513	48227	2015-12-01	389.97	3	0.00	35.10	2
42282	CA-2013-112382	MB-18085	TEC-PH-10001552	77036	2015-05-10	19.14	2	0.20	1.91	2
42283	US-2012-163433	MP-17965	TEC-PH-10001870	78501	2014-04-18	97.97	2	0.20	6.12	1
42284	CA-2014-150959	TD-20995	OFF-LA-10001045	75043	2016-11-11	10.44	5	0.20	3.39	4
42285	US-2011-106992	SB-20290	TEC-MA-10000822	77036	2013-09-19	3059.98	3	0.40	-510.00	1
42286	CA-2011-120278	MS-17365	OFF-ST-10002214	54401	2013-11-07	22.58	2	0.00	5.87	2
42287	CA-2013-163398	CB-12415	OFF-AR-10003217	60653	2015-05-04	27.38	7	0.20	2.74	2
42288	CA-2014-102155	RR-19525	OFF-PA-10003673	66212	2016-07-13	13.56	2	0.00	6.24	2
42289	CA-2012-126697	SV-20815	TEC-AC-10004353	77041	2014-09-21	151.20	3	0.20	32.13	4
42290	CA-2012-132507	CC-12610	OFF-ST-10000943	77041	2014-07-30	61.79	4	0.20	6.18	1
42291	CA-2013-139878	LD-17005	TEC-PH-10001336	48234	2015-11-12	257.98	2	0.00	74.81	2
42292	CA-2011-139892	BM-11140	FUR-CH-10004287	78207	2013-09-08	1740.06	9	0.30	-24.86	2
42293	CA-2011-165309	KD-16270	OFF-PA-10003724	77095	2013-11-11	21.72	5	0.20	7.87	2
42294	CA-2012-157322	RH-19600	FUR-CH-10004086	60188	2014-07-02	408.42	2	0.30	-5.83	2
42295	US-2014-152569	JD-16015	OFF-PA-10001736	60653	2016-05-15	56.70	2	0.20	19.14	2
42296	CA-2011-116757	MS-17980	OFF-FA-10002815	77095	2013-06-30	21.31	6	0.20	7.19	2
42297	CA-2011-112326	PO-19195	OFF-LA-10003223	60540	2013-01-04	11.78	3	0.20	4.27	2
42298	CA-2013-128307	BE-11335	OFF-EN-10003040	77041	2015-07-26	20.94	1	0.20	7.07	2
42299	CA-2013-130050	MC-17425	FUR-FU-10001940	77036	2015-07-17	9.55	3	0.60	-3.82	1
42300	CA-2012-132374	PS-19045	OFF-AR-10001615	48310	2014-02-22	79.36	4	0.00	20.63	1
42301	CA-2013-121034	JF-15565	OFF-PA-10001994	75081	2015-08-09	53.95	3	0.20	17.53	1
42302	CA-2011-103191	VG-21805	OFF-ST-10002574	60653	2013-09-22	331.54	3	0.20	-82.88	2
42303	CA-2013-122014	CD-11920	OFF-AP-10001293	67212	2015-12-30	81.96	2	0.00	22.95	2
42304	CA-2011-120474	RP-19390	FUR-CH-10001854	53711	2013-12-01	2807.84	8	0.00	673.88	4
42305	US-2011-159618	DB-12970	TEC-AC-10003832	77036	2013-11-12	79.51	3	0.20	20.87	2
42306	CA-2013-129686	GG-14650	TEC-AC-10001266	60623	2015-11-28	62.40	6	0.20	19.50	1
42307	CA-2011-122609	DP-13000	FUR-FU-10004587	75007	2013-11-12	25.13	3	0.60	-6.91	2
42308	CA-2014-126956	GT-14710	OFF-EN-10004459	55044	2016-08-21	15.28	2	0.00	7.49	2
42309	CA-2012-141243	AH-10465	FUR-BO-10003272	75217	2014-01-03	1352.40	9	0.32	-437.54	1
42310	US-2012-123918	CG-12520	FUR-FU-10004952	75217	2014-10-15	131.38	6	0.60	-95.25	3
42311	US-2011-166828	JF-15415	OFF-PA-10001846	63301	2013-08-22	11.56	2	0.00	5.66	4
42312	CA-2012-105613	KN-16705	OFF-AP-10000026	78501	2014-10-18	73.16	6	0.80	-186.57	2
42313	CA-2013-137330	KB-16585	OFF-AR-10000246	68025	2015-12-10	19.46	7	0.00	5.06	2
42314	CA-2014-163265	JS-16030	OFF-AR-10004078	62521	2016-02-17	28.03	6	0.20	3.50	2
42315	CA-2012-139780	AH-10690	OFF-BI-10004139	48205	2014-12-31	116.40	8	0.00	52.38	1
42316	CA-2014-105669	SJ-20125	FUR-CH-10003774	77036	2016-09-17	318.43	5	0.30	-77.33	1
42317	US-2011-157406	DA-13450	OFF-AR-10002221	77095	2013-04-25	6.24	3	0.20	0.55	2
42318	CA-2014-137596	BE-11335	TEC-PH-10001494	49201	2016-09-02	1199.80	4	0.00	323.95	2
42319	CA-2014-122035	EM-13825	TEC-AC-10003095	57103	2016-07-20	389.97	3	0.00	132.59	2
42320	CA-2011-165309	KD-16270	TEC-PH-10003505	77095	2013-11-11	148.48	2	0.20	16.70	2
42321	US-2011-155894	CL-11890	OFF-ST-10004804	60623	2013-07-26	123.55	3	0.20	-29.34	1
42322	US-2014-119816	TT-21460	OFF-LA-10002381	77095	2016-03-04	2.46	1	0.20	0.86	1
42323	CA-2013-114482	DM-13345	TEC-PH-10001580	50315	2015-11-22	404.94	3	0.00	109.33	1
42324	CA-2012-127607	JK-15730	OFF-BI-10001308	75007	2014-03-20	2.51	2	0.80	-4.40	2
42325	CA-2014-163125	MB-17305	FUR-CH-10001802	77573	2016-10-09	254.06	3	0.30	-32.66	1
42326	CA-2014-152583	RA-19945	OFF-ST-10002214	75217	2016-10-30	54.19	6	0.20	4.06	3
42327	CA-2011-149104	RD-19900	OFF-AR-10002952	48127	2013-04-05	26.70	2	0.00	7.48	1
42328	CA-2014-144113	JF-15355	TEC-PH-10002170	78745	2016-09-16	55.99	1	0.20	5.60	2
42329	CA-2011-156993	RW-19630	OFF-FA-10003495	48234	2013-06-28	6.08	1	0.00	3.04	2
42330	CA-2013-114482	DM-13345	OFF-PA-10003845	50315	2015-11-22	40.46	7	0.00	19.83	1
42331	US-2014-133200	DB-13555	OFF-ST-10001932	76106	2016-05-06	772.68	5	0.20	-57.95	2
42332	CA-2014-152926	SC-20695	OFF-AP-10004708	77041	2016-10-02	15.22	2	0.80	-38.82	1
42333	CA-2013-156300	TB-21595	FUR-CH-10001714	53209	2015-12-30	754.45	5	0.00	60.36	2
42334	CA-2013-128867	CL-12565	OFF-BI-10003981	50322	2015-11-04	27.24	6	0.00	13.35	2
42335	US-2013-128195	RA-19285	OFF-BI-10002003	61604	2015-08-05	3.98	5	0.80	-6.57	4
42336	CA-2014-142489	TC-21295	OFF-BI-10003684	77095	2016-11-14	21.99	5	0.80	-32.99	1
42337	CA-2012-169537	JH-15820	OFF-LA-10001982	49423	2014-09-03	7.50	2	0.00	3.60	1
42338	US-2012-124219	KW-16570	OFF-BI-10002215	63122	2014-08-07	28.40	4	0.00	13.06	4
42339	CA-2013-140774	BE-11455	OFF-AR-10004022	66062	2015-09-06	107.94	3	0.00	26.99	2
42340	CA-2014-142867	PO-19180	OFF-PA-10004610	77095	2016-03-17	10.27	3	0.20	3.21	2
42341	CA-2013-118255	ON-18715	OFF-BI-10003291	55122	2015-03-12	17.46	2	0.00	8.21	4
42342	CA-2011-169019	LF-17185	OFF-BI-10004995	78207	2013-07-26	2177.58	8	0.80	-3701.89	2
42343	CA-2014-111262	KH-16510	OFF-PA-10001937	77095	2016-10-28	15.55	3	0.20	5.44	1
42344	CA-2014-120376	TP-21130	TEC-AC-10001114	48227	2016-12-22	199.95	5	0.00	63.98	4
42345	CA-2014-133102	ED-13885	OFF-AP-10001563	77095	2016-08-17	38.86	4	0.80	-99.10	2
42346	CA-2014-111332	NC-18340	OFF-AR-10001953	58103	2016-05-20	131.94	3	0.00	35.62	1
42347	CA-2012-105627	DK-12895	TEC-PH-10003012	53142	2014-03-08	769.95	5	0.00	223.29	2
42348	CA-2012-154284	SZ-20035	TEC-AC-10003198	60174	2014-12-21	637.44	8	0.20	135.46	1
42349	CA-2012-150441	RA-19285	OFF-BI-10003529	47374	2014-08-13	11.36	4	0.00	5.57	1
42350	CA-2012-104052	TP-21565	TEC-PH-10003215	75019	2014-03-01	95.84	4	0.20	34.74	4
42351	CA-2012-163181	AB-10105	OFF-ST-10000129	77041	2014-11-07	177.65	2	0.20	-28.87	2
42352	CA-2013-157749	KL-16645	FUR-FU-10002505	60610	2015-06-05	4.04	3	0.60	-2.83	1
42353	CA-2013-125087	TH-21115	OFF-ST-10001780	77070	2015-04-19	1554.94	3	0.20	77.75	2
42354	CA-2011-160738	KH-16330	OFF-ST-10003442	61032	2013-05-05	45.25	2	0.20	3.96	2
42355	CA-2011-103492	CM-12715	OFF-BI-10004817	77340	2013-10-10	11.98	5	0.80	-19.17	2
42356	CA-2014-121615	DL-12925	OFF-ST-10001325	55122	2016-11-03	52.40	5	0.00	14.15	2
42357	CA-2012-140221	MS-17365	OFF-BI-10002854	60653	2014-03-05	11.21	2	0.80	-16.82	1
42358	US-2013-146710	SS-20875	OFF-SU-10004498	75220	2015-08-28	51.52	5	0.20	-10.95	2
42359	US-2014-116491	PG-18820	TEC-PH-10004531	75081	2016-11-11	35.18	2	0.20	12.31	4
42360	CA-2013-124506	BB-11545	FUR-CH-10004540	60623	2015-11-12	47.99	2	0.30	-2.06	2
42361	CA-2013-140130	HW-14935	FUR-CH-10002084	74133	2015-11-01	368.97	3	0.00	81.17	2
42362	CA-2013-121671	AA-10480	OFF-ST-10000078	65807	2015-07-18	265.17	1	0.00	47.73	2
42363	US-2014-106705	PO-18850	OFF-PA-10001509	52601	2016-12-26	44.75	5	0.00	20.59	2
42364	CA-2014-121790	LP-17095	TEC-PH-10002584	60505	2016-01-31	2003.17	4	0.20	250.40	2
42365	CA-2014-104220	BV-11245	FUR-FU-10002597	50315	2016-01-31	34.58	7	0.00	14.52	2
42366	CA-2013-152730	EM-14140	OFF-AR-10000940	54880	2015-05-31	14.70	5	0.00	3.97	2
42367	CA-2014-121559	HW-14935	FUR-CH-10003746	46203	2016-06-01	1925.88	6	0.00	539.25	1
42368	CA-2013-122063	MM-17920	FUR-TA-10004575	47374	2015-12-04	581.96	2	0.00	104.75	2
42369	CA-2013-156748	BS-11755	OFF-ST-10001370	48227	2015-12-01	496.86	7	0.00	24.84	2
42370	US-2013-103646	SP-20545	OFF-BI-10002854	60623	2015-04-22	44.85	8	0.80	-67.27	2
42371	CA-2012-117898	TB-21250	OFF-EN-10004459	61701	2014-12-05	12.22	2	0.20	4.43	2
42372	CA-2011-118339	BN-11515	OFF-BI-10001758	55044	2013-03-17	53.40	10	0.00	25.10	2
42373	CA-2014-107629	DB-13060	TEC-AC-10004510	60076	2016-12-14	39.26	3	0.20	-4.91	3
42374	CA-2011-131009	SC-20380	OFF-FA-10004395	79907	2013-03-01	18.84	5	0.20	-3.53	2
42375	CA-2014-164168	LS-16975	TEC-PH-10004908	75081	2016-11-12	67.99	1	0.20	8.50	2
42376	CA-2011-123064	RA-19915	OFF-AR-10004582	60653	2013-06-30	5.25	4	0.20	1.64	4
42377	CA-2014-143063	IL-15100	OFF-EN-10003134	47201	2016-08-10	70.08	6	0.00	35.04	2
42378	CA-2014-112536	SG-20890	OFF-ST-10004835	78501	2016-05-18	8.93	2	0.20	0.67	2
42379	US-2014-108245	SH-19975	OFF-BI-10000773	77581	2016-09-22	11.23	7	0.80	-18.53	2
42380	CA-2012-121041	CS-12250	OFF-EN-10001137	76117	2014-11-03	6.61	2	0.20	2.15	2
42381	CA-2012-110877	JE-15715	TEC-PH-10002103	77041	2014-10-23	150.38	2	0.20	15.04	4
42382	CA-2013-157714	CS-12175	OFF-PA-10004022	52240	2015-09-27	9.99	1	0.00	4.50	1
42383	CA-2011-169649	TS-21205	OFF-PA-10000143	60653	2013-12-09	8.45	2	0.20	2.96	2
42384	CA-2014-154809	MH-17455	OFF-AP-10004785	55407	2016-02-14	90.64	8	0.00	38.98	2
42385	CA-2012-114468	TD-20995	OFF-FA-10003021	60440	2014-08-23	12.03	8	0.20	2.26	3
42386	CA-2014-158876	AB-10150	OFF-SU-10001165	75007	2016-11-19	6.67	1	0.20	0.50	1
42387	CA-2014-127474	RD-19810	OFF-PA-10000418	60610	2016-02-04	419.40	5	0.20	146.79	1
42388	CA-2012-109337	DL-13330	TEC-AC-10000990	46226	2014-11-21	393.54	3	0.00	165.29	1
42389	CA-2012-112452	NC-18340	OFF-AP-10003849	48911	2014-04-04	644.08	2	0.10	107.35	3
42390	CA-2013-133697	CM-12445	FUR-CH-10002372	77095	2015-10-21	56.69	1	0.30	-14.58	1
42391	CA-2014-163860	LO-17170	FUR-FU-10004586	61604	2016-12-28	7.97	3	0.60	-2.39	2
42392	US-2012-132836	AJ-10945	TEC-PH-10001299	48227	2014-06-01	299.98	2	0.00	83.99	2
42393	CA-2014-110940	AZ-10750	OFF-AR-10000380	60090	2016-07-23	121.54	4	0.20	15.19	2
42394	CA-2014-162481	CT-11995	FUR-CH-10003061	55901	2016-09-25	269.97	3	0.00	51.29	2
42395	CA-2013-139395	MG-17650	FUR-FU-10003724	49201	2015-12-13	33.48	4	0.00	8.70	2
42396	CA-2011-167927	XP-21865	FUR-FU-10002918	48185	2013-01-20	272.94	3	0.00	30.02	2
42397	US-2013-131149	LH-17155	OFF-AR-10002135	75081	2015-07-11	154.24	4	0.20	17.35	2
42398	CA-2014-117114	CY-12745	OFF-EN-10001137	60610	2016-10-31	9.91	3	0.20	3.22	2
42399	CA-2012-123155	NS-18640	TEC-PH-10001809	78207	2014-03-09	359.88	3	0.20	22.49	4
42400	CA-2011-109932	VP-21760	OFF-PA-10001804	78521	2013-12-09	10.69	2	0.20	3.74	4
42401	CA-2014-118773	TP-21415	TEC-AC-10002402	77070	2016-02-10	127.98	2	0.20	16.00	2
42402	US-2012-168704	FP-14320	FUR-TA-10000688	77340	2014-04-13	609.98	4	0.30	-113.28	2
42403	CA-2014-150266	RO-19780	FUR-CH-10002126	77070	2016-11-25	853.93	5	0.30	-24.40	2
42404	CA-2014-104220	BV-11245	OFF-BI-10000301	50315	2016-01-31	32.35	5	0.00	16.18	2
42405	CA-2011-167927	XP-21865	FUR-FU-10002268	48185	2013-01-20	14.73	3	0.00	4.86	2
42406	CA-2011-105417	VS-21820	FUR-FU-10004864	77340	2013-01-07	76.73	3	0.60	-53.71	2
42407	CA-2014-148411	RO-19780	OFF-PA-10002109	60623	2016-09-24	11.42	3	0.20	3.71	4
42408	US-2013-148110	AR-10825	FUR-CH-10002647	78745	2015-09-06	347.80	7	0.30	-24.84	2
42409	US-2013-152835	RP-19855	OFF-AR-10003056	47905	2015-05-20	21.40	5	0.00	6.21	2
42410	CA-2011-141299	RB-19795	OFF-EN-10004459	48640	2013-06-03	15.28	2	0.00	7.49	1
42411	CA-2014-125290	CC-12430	OFF-AR-10001216	55407	2016-11-06	13.90	5	0.00	3.61	1
42412	CA-2013-152555	ME-17320	OFF-PA-10001295	60653	2015-03-30	45.53	3	0.20	15.93	1
42413	US-2014-130603	SC-20050	OFF-BI-10000301	76017	2016-09-30	11.65	9	0.80	-17.47	2
42414	US-2014-165869	LS-17200	OFF-BI-10003460	53209	2016-07-31	17.52	4	0.00	8.41	2
42415	CA-2013-114601	AA-10480	FUR-TA-10004147	48234	2015-08-27	447.84	4	0.00	98.52	2
42416	CA-2012-168809	MC-18100	FUR-FU-10001473	77041	2014-08-25	20.10	2	0.60	-16.59	3
42417	CA-2011-163867	RE-19450	OFF-LA-10001771	62521	2013-06-03	15.94	4	0.20	5.18	4
42418	CA-2014-111332	NC-18340	OFF-ST-10003816	58103	2016-05-20	704.76	4	0.00	162.09	1
42419	CA-2013-105732	AG-10270	OFF-ST-10000419	68104	2015-09-14	40.74	3	0.00	0.41	2
42420	CA-2012-111990	DB-13660	OFF-BI-10003291	77095	2014-11-08	10.48	6	0.80	-17.29	2
42421	CA-2014-140802	KN-16390	TEC-AC-10001998	77070	2016-04-21	47.98	3	0.20	8.40	4
42422	CA-2011-124394	TB-21520	OFF-BI-10003676	77705	2013-10-17	10.78	5	0.80	-17.25	1
42423	CA-2012-162964	MF-18250	OFF-PA-10003349	77095	2014-11-12	15.55	3	0.20	5.64	2
42424	CA-2014-138618	MY-17380	OFF-PA-10000520	78207	2016-12-01	10.37	2	0.20	3.63	2
42425	US-2011-122959	CY-12745	OFF-BI-10003650	78207	2013-12-12	210.39	2	0.80	-336.63	3
42426	CA-2013-147375	PO-19180	TEC-MA-10002937	60623	2015-06-13	1007.98	3	0.30	43.20	1
42427	CA-2011-165428	JL-15130	OFF-PA-10004100	77036	2013-09-01	31.10	6	0.20	10.89	4
42428	CA-2014-128783	TG-21640	TEC-AC-10002473	63301	2016-09-07	113.52	4	0.00	46.54	3
42429	CA-2014-163860	LO-17170	FUR-CH-10004698	61604	2016-12-28	113.37	2	0.30	-3.24	2
42430	CA-2014-137456	RB-19465	FUR-FU-10001940	68025	2016-12-21	15.92	2	0.00	7.00	3
42431	CA-2013-149272	MY-18295	OFF-BI-10004233	77803	2015-03-16	22.39	7	0.80	-35.82	2
42432	CA-2012-140025	PF-19120	TEC-AC-10002402	78207	2014-04-07	383.95	6	0.20	47.99	2
42433	CA-2014-150959	TD-20995	OFF-BI-10001510	75043	2016-11-11	18.34	4	0.80	-32.09	4
42434	CA-2014-135860	JH-15985	OFF-BI-10003274	48601	2016-12-01	15.92	4	0.00	7.48	2
42435	CA-2012-135685	MP-18175	OFF-PA-10000157	53209	2014-11-16	179.82	9	0.00	84.52	1
42436	CA-2014-111262	KH-16510	TEC-AC-10002167	77095	2016-10-28	24.00	2	0.20	-2.70	1
42437	CA-2012-141250	PM-18940	FUR-CH-10004875	77590	2014-01-19	199.30	4	0.30	-8.54	2
42438	US-2012-123918	CG-12520	OFF-PA-10003001	75217	2014-10-15	5.34	1	0.20	1.87	3
42439	US-2014-104661	TB-21250	OFF-BI-10001098	78745	2016-01-16	4.28	1	0.80	-6.63	4
42440	CA-2014-130771	LA-16780	OFF-FA-10003059	78745	2016-07-29	2.90	2	0.20	0.47	2
42441	US-2014-124779	BF-11020	TEC-CO-10001943	76017	2016-09-08	319.98	2	0.20	107.99	4
42442	US-2013-131114	RW-19630	OFF-AP-10003971	60610	2015-12-10	4.36	2	0.80	-11.76	1
42443	CA-2014-106068	RB-19330	OFF-ST-10004507	78745	2016-10-23	13.72	1	0.20	1.20	2
42444	CA-2014-126788	AB-10105	TEC-PH-10001619	77581	2016-06-05	470.38	3	0.20	52.92	4
42445	CA-2013-105354	PW-19030	OFF-BI-10001107	52302	2015-12-03	115.84	8	0.00	54.44	2
42446	CA-2014-169810	RB-19360	OFF-LA-10003663	57103	2016-07-25	20.23	7	0.00	9.51	2
42447	CA-2013-105732	AG-10270	OFF-PA-10002250	68104	2015-09-14	17.61	3	0.00	8.45	2
42448	CA-2011-151897	VT-21700	OFF-LA-10001074	77070	2013-06-06	100.24	10	0.20	33.83	2
42449	CA-2013-128671	MT-18070	OFF-BI-10003305	74133	2015-08-12	41.86	7	0.00	19.26	2
42450	CA-2013-119025	PV-18985	OFF-AP-10001205	53209	2015-02-22	490.32	9	0.00	137.29	2
42451	CA-2012-163055	DS-13180	OFF-AR-10001026	48227	2014-08-09	2.20	1	0.00	0.97	2
42452	CA-2014-109778	VM-21685	OFF-AR-10003759	60098	2016-07-16	2.91	2	0.20	0.91	2
42453	US-2014-104661	TB-21250	TEC-AC-10002331	78745	2016-01-16	62.59	8	0.20	13.30	4
42454	CA-2013-113061	EL-13735	FUR-FU-10003975	65109	2015-04-23	86.62	2	0.00	8.66	2
42455	CA-2014-100314	AS-10630	TEC-MA-10003066	77506	2016-09-29	336.51	3	0.40	44.87	2
42456	US-2013-124163	SC-20695	FUR-CH-10004218	54601	2015-09-26	201.96	2	0.00	50.49	2
42457	CA-2014-137449	ME-17725	FUR-BO-10000780	75220	2016-06-29	410.00	3	0.32	-96.47	4
42458	CA-2011-125514	BM-11650	OFF-AP-10003281	68104	2013-09-21	36.27	3	0.00	10.88	4
42459	US-2012-149692	KW-16435	OFF-BI-10002813	78745	2014-12-06	2.77	7	0.80	-4.85	2
42460	CA-2012-151785	JJ-15445	OFF-FA-10000611	60623	2014-03-05	7.10	6	0.20	2.49	2
42461	CA-2014-130386	NG-18430	OFF-PA-10003823	78745	2016-11-12	223.06	9	0.20	69.71	2
42462	US-2014-106663	MO-17800	FUR-FU-10002759	60653	2016-06-09	23.98	3	0.60	-14.39	2
42463	CA-2012-135251	RP-19270	OFF-BI-10001097	77095	2014-08-06	6.23	5	0.80	-9.66	2
42464	US-2012-152128	NM-18445	OFF-AR-10002445	67212	2014-05-25	21.24	3	0.00	8.07	1
42465	CA-2014-131632	AH-10120	OFF-AR-10003651	75217	2016-10-31	5.25	2	0.20	0.59	2
42466	CA-2014-128328	PO-18865	TEC-AC-10001714	46203	2016-08-05	79.78	2	0.00	29.52	2
42467	CA-2014-141992	FO-14305	OFF-SU-10002557	75220	2016-06-19	11.18	1	0.20	0.84	2
42468	CA-2012-144302	ME-17320	OFF-BI-10001107	75081	2014-06-19	5.79	2	0.80	-9.56	2
42469	CA-2014-130386	NG-18430	OFF-PA-10002749	78745	2016-11-12	16.06	3	0.20	5.82	2
42470	CA-2013-135594	AH-10120	TEC-AC-10003038	60505	2015-07-01	50.12	7	0.20	-0.63	1
42471	CA-2012-126557	RL-19615	FUR-CH-10004477	60610	2014-07-12	383.61	9	0.30	-5.48	1
42472	CA-2011-132801	JG-15805	OFF-ST-10001228	75217	2013-10-07	107.44	10	0.20	10.74	2
42473	CA-2014-118346	PO-19180	TEC-AC-10000736	53142	2016-07-23	399.95	5	0.00	143.98	4
42474	CA-2013-161816	NB-18655	TEC-PH-10003012	75217	2015-04-29	369.58	3	0.20	41.58	4
42475	US-2012-130491	BH-11710	OFF-PA-10000791	67846	2014-02-08	9.54	2	0.00	4.29	4
42476	CA-2011-109932	VP-21760	OFF-ST-10000036	78521	2013-12-09	237.10	3	0.20	20.75	4
42477	CA-2012-135853	CA-12775	TEC-AC-10004761	48205	2014-12-11	175.23	11	0.00	61.33	4
42478	CA-2011-103744	MG-17875	OFF-LA-10004425	79907	2013-02-23	6.94	3	0.20	2.34	2
42479	CA-2012-120551	SS-20590	OFF-BI-10002071	68701	2014-04-13	17.43	3	0.00	8.02	2
42480	US-2013-131611	EP-13915	OFF-BI-10001989	77036	2015-11-06	12.59	3	0.80	-20.14	2
42481	CA-2011-150518	MW-18220	OFF-ST-10000877	55433	2013-11-19	221.16	4	0.00	57.50	2
42482	CA-2013-101791	BS-11665	FUR-FU-10002191	60623	2015-05-28	5.58	2	0.60	-1.68	2
42483	CA-2012-157322	RH-19600	OFF-ST-10003208	60188	2014-07-02	435.50	3	0.20	48.99	2
42484	CA-2012-119550	RB-19705	FUR-CH-10002044	77070	2014-12-26	275.06	3	0.30	-90.38	2
42485	CA-2014-104927	AG-10330	OFF-BI-10003429	77095	2016-12-22	6.33	5	0.80	-9.81	2
42486	US-2012-110261	PR-18880	TEC-PH-10001750	60025	2014-12-19	158.38	3	0.20	13.86	1
42487	CA-2013-146157	RD-19720	OFF-ST-10001590	60610	2015-11-22	21.57	2	0.20	1.62	2
42488	US-2014-165869	LS-17200	OFF-AP-10002472	53209	2016-07-31	155.88	6	0.00	54.56	2
42489	CA-2014-163265	JS-16030	OFF-ST-10000642	62521	2016-02-17	50.35	3	0.20	-8.18	2
42490	CA-2013-137743	KH-16360	OFF-ST-10001780	60623	2015-07-31	1036.62	2	0.20	51.83	2
42491	CA-2013-133550	KL-16645	OFF-AP-10001005	48205	2015-08-01	283.14	4	0.10	72.36	2
42492	CA-2012-137064	TS-21655	TEC-AC-10003499	77070	2014-02-06	18.53	2	0.20	4.40	2
42493	CA-2012-110324	MA-17560	OFF-PA-10001826	49201	2014-12-01	19.44	3	0.00	9.33	2
42494	CA-2012-115924	BE-11455	OFF-BI-10004040	50315	2014-09-14	25.90	5	0.00	12.69	1
42495	CA-2014-135650	AC-10660	OFF-ST-10001809	77340	2016-03-23	143.73	2	0.20	-32.34	2
42496	CA-2014-121503	FH-14275	TEC-MA-10003674	77041	2016-07-03	597.13	3	0.40	49.76	1
42497	US-2013-100566	JK-16120	FUR-FU-10003394	60505	2015-09-04	83.95	3	0.60	-90.25	2
42498	CA-2014-107727	MA-17560	OFF-PA-10000249	77095	2016-10-19	29.47	3	0.20	9.95	1
42499	CA-2014-127026	MH-18115	OFF-BI-10001196	49201	2016-01-22	89.52	4	0.00	42.07	2
42500	CA-2011-122567	MN-17935	OFF-BI-10002012	75220	2013-02-16	1.08	3	0.80	-1.73	2
42501	US-2013-162852	BG-11695	FUR-CH-10004853	60098	2015-12-28	845.49	8	0.30	-12.08	2
42502	CA-2014-152485	JD-15790	OFF-ST-10004950	75019	2016-09-04	16.78	1	0.20	-0.21	2
42503	CA-2014-109960	DB-13210	TEC-AC-10004859	48234	2016-12-09	104.88	6	0.00	41.95	1
42504	CA-2014-143434	ME-17320	FUR-FU-10002597	48601	2016-11-18	19.76	4	0.00	8.30	2
42505	CA-2011-110030	LF-17185	FUR-FU-10002759	77095	2013-12-06	23.98	3	0.60	-14.39	1
42506	CA-2013-131576	RD-19585	OFF-BI-10002852	48205	2015-11-23	49.44	3	0.00	24.23	2
42507	CA-2013-118689	TC-20980	OFF-ST-10001558	47905	2015-10-03	32.48	2	0.00	4.87	2
42508	CA-2012-129112	AW-10840	TEC-AC-10003038	75002	2014-11-29	21.48	3	0.20	-0.27	4
42509	CA-2014-157483	EP-13915	OFF-AR-10004260	48227	2016-11-11	181.86	7	0.00	50.92	2
42510	CA-2014-139311	SF-20965	TEC-PH-10001557	76021	2016-08-11	153.58	2	0.20	13.44	4
42511	CA-2014-138289	AR-10540	OFF-PA-10001260	49201	2016-01-17	56.07	7	0.00	25.23	1
42512	CA-2012-100818	JM-15265	OFF-LA-10000443	60653	2014-05-31	5.90	2	0.20	1.99	1
42513	CA-2014-155936	JK-15730	OFF-BI-10002432	60653	2016-06-22	3.04	3	0.80	-5.01	2
42514	CA-2014-147291	MJ-17740	OFF-BI-10003091	48227	2016-03-11	895.92	4	0.00	421.08	2
42515	CA-2014-112529	SC-20770	FUR-TA-10002622	78207	2016-11-19	718.12	6	0.30	-71.81	4
42516	US-2014-133200	DB-13555	FUR-BO-10001601	76106	2016-05-06	623.46	7	0.32	-119.19	2
42517	US-2013-157728	RC-19960	TEC-PH-10001305	49505	2015-09-23	97.98	2	0.00	27.43	2
42518	CA-2014-140508	PA-19060	OFF-EN-10000927	75220	2016-09-18	114.85	4	0.20	35.89	4
42519	US-2012-118766	LS-16975	OFF-EN-10001415	75217	2014-10-15	4.46	1	0.20	1.67	2
42520	CA-2014-145653	CA-12775	FUR-CH-10004875	48205	2016-09-01	498.26	7	0.00	134.53	3
42521	CA-2012-155761	SC-20800	TEC-AC-10001606	77041	2014-12-11	159.98	2	0.20	36.00	3
42522	CA-2011-139892	BM-11140	TEC-MA-10000822	78207	2013-09-08	8159.95	8	0.40	-1359.99	2
42523	CA-2013-162726	MT-17815	OFF-PA-10004041	77642	2015-12-28	23.68	4	0.20	7.40	2
42524	CA-2011-105165	SZ-20035	OFF-BI-10000050	77036	2013-09-07	2.92	2	0.80	-4.82	4
42525	CA-2011-127446	MC-17590	FUR-FU-10000221	76017	2013-11-25	6.10	3	0.60	-3.96	2
42526	US-2012-163433	MP-17965	OFF-PA-10003936	78501	2014-04-18	15.55	3	0.20	5.44	1
42527	CA-2013-114489	JE-16165	OFF-BI-10002735	53132	2015-12-06	171.55	5	0.00	80.63	2
42528	CA-2012-135251	RP-19270	OFF-LA-10004544	77095	2014-08-06	35.52	3	0.20	13.32	2
42529	CA-2011-167927	XP-21865	OFF-ST-10000760	48185	2013-01-20	13.98	1	0.00	4.05	2
42530	CA-2013-168774	RP-19855	OFF-ST-10001490	55125	2015-09-05	535.41	3	0.00	160.62	2
42531	CA-2011-163748	HG-15025	OFF-AP-10004052	76106	2013-10-14	3.16	4	0.80	-8.53	2
42532	CA-2014-168739	HZ-14950	FUR-FU-10003919	77095	2016-05-29	65.42	4	0.60	-52.34	2
42533	CA-2012-156104	NP-18685	TEC-CO-10002095	46203	2014-12-06	999.98	2	0.00	449.99	1
42534	CA-2011-117765	RB-19465	FUR-CH-10004698	74133	2013-09-07	161.96	2	0.00	45.35	2
42535	CA-2014-162691	AS-10045	OFF-PA-10003729	78745	2016-08-01	36.29	7	0.20	12.70	2
42536	CA-2014-154907	DS-13180	FUR-BO-10002824	79109	2016-03-31	205.33	2	0.32	-36.24	2
42537	US-2014-127341	CK-12595	OFF-BI-10001072	60653	2016-01-30	12.13	4	0.80	-20.62	2
42538	CA-2012-135251	RP-19270	OFF-PA-10003302	77095	2014-08-06	56.70	2	0.20	19.14	2
42539	CA-2012-157322	RH-19600	OFF-PA-10000659	60188	2014-07-02	11.17	2	0.20	3.77	2
42540	US-2011-157847	SC-20020	OFF-PA-10001593	77095	2013-04-02	33.49	7	0.20	10.47	1
42541	CA-2013-121671	AA-10480	OFF-PA-10001892	65807	2015-07-18	7.64	1	0.00	3.74	2
42542	CA-2013-154662	BF-11215	FUR-TA-10001771	55407	2015-06-10	692.94	3	0.00	173.24	2
42543	CA-2012-157322	RH-19600	FUR-CH-10003774	60188	2014-07-02	382.12	6	0.30	-92.80	2
42544	US-2013-115455	SE-20110	FUR-FU-10004671	60090	2015-09-09	14.14	2	0.60	-7.77	2
42545	US-2013-115455	SE-20110	FUR-TA-10003569	60090	2015-09-09	601.47	3	0.50	-300.74	2
42546	CA-2013-114209	AS-10285	OFF-BI-10000343	75081	2015-05-22	1.96	2	0.80	-3.24	2
42547	CA-2011-126193	SS-20410	OFF-FA-10000936	60543	2013-09-07	13.16	5	0.20	4.11	2
42548	CA-2014-126074	RF-19735	OFF-BI-10003638	48183	2016-10-02	58.05	3	0.00	26.70	2
42549	US-2013-163538	SS-20515	TEC-AC-10002006	53132	2015-08-27	47.97	3	0.00	14.87	2
42550	US-2011-130379	JL-15235	FUR-FU-10002553	60623	2013-05-25	29.32	2	0.60	-24.19	2
42551	CA-2013-144911	RW-19630	OFF-BI-10000977	66212	2015-11-28	152.00	5	0.00	69.92	4
42552	CA-2014-156622	JP-15460	OFF-PA-10000477	75220	2016-11-23	36.29	7	0.20	12.70	4
42553	CA-2014-169691	Dp-13240	OFF-ST-10001291	55369	2016-06-15	84.55	5	0.00	22.83	4
42554	CA-2012-131856	JG-15160	TEC-PH-10001336	77041	2014-05-12	619.15	6	0.20	69.65	2
42555	CA-2011-131009	SC-20380	FUR-CH-10001270	79907	2013-03-01	362.25	6	0.30	0.00	2
42556	CA-2014-140298	JK-16120	FUR-FU-10001967	78745	2016-05-11	8.00	1	0.60	-7.00	2
42557	CA-2014-132584	HJ-14875	OFF-ST-10000344	48234	2016-08-26	53.72	4	0.00	13.97	4
42558	CA-2011-168368	GA-14725	OFF-ST-10002583	65203	2013-02-11	64.96	2	0.00	2.60	1
42559	US-2012-168704	FP-14320	TEC-PH-10001061	77340	2014-04-13	239.98	3	0.20	18.00	2
42560	US-2012-100377	TS-21370	TEC-CO-10001046	60623	2014-08-28	2799.96	5	0.20	874.99	2
42561	CA-2014-142034	KB-16240	FUR-CH-10000665	56301	2016-09-24	603.92	4	0.00	181.18	2
42562	CA-2014-164168	LS-16975	OFF-ST-10002583	75081	2016-11-12	77.95	3	0.20	-15.59	2
42563	CA-2011-119466	SP-20860	FUR-FU-10001546	60623	2013-12-15	8.54	2	0.60	-7.48	2
42564	CA-2011-103100	AB-10105	OFF-LA-10003720	46203	2013-12-20	3.69	1	0.00	1.73	4
42565	US-2014-113992	LC-16885	FUR-TA-10000577	75023	2016-12-14	974.99	4	0.30	-97.50	2
42566	CA-2014-112809	RA-19915	OFF-BI-10001098	75220	2016-08-18	21.38	5	0.80	-33.14	2
42567	CA-2011-139283	BT-11440	OFF-BI-10002049	48227	2013-11-23	14.67	3	0.00	6.75	2
42568	CA-2013-144764	RL-19615	OFF-LA-10000240	60623	2015-09-03	29.24	5	0.20	9.87	2
42569	CA-2014-141733	RW-19540	FUR-CH-10002017	48234	2016-05-07	26.64	1	0.00	7.46	2
42570	CA-2014-157966	SU-20665	TEC-CO-10001449	60610	2016-03-13	959.98	2	0.20	335.99	3
42571	CA-2012-110548	AH-10690	TEC-PH-10002922	77095	2014-05-04	946.34	7	0.20	118.29	2
42572	CA-2013-169971	IL-15100	OFF-AR-10002804	77041	2015-09-05	3.91	1	0.20	1.03	2
42573	CA-2012-140221	MS-17365	OFF-ST-10000777	60653	2014-03-05	60.42	2	0.20	6.04	1
42574	CA-2014-107629	DB-13060	OFF-AR-10002987	60076	2016-12-14	95.23	6	0.20	25.00	3
42575	CA-2014-160045	LB-16735	FUR-FU-10000010	76106	2016-04-26	1.99	1	0.60	-1.44	4
42576	CA-2014-163006	GH-14410	FUR-CH-10000229	60653	2016-06-30	569.06	3	0.30	-178.85	1
42577	US-2014-104094	AG-10675	TEC-AC-10002134	53209	2016-09-07	13.48	1	0.00	1.89	2
42578	US-2011-166310	JS-15940	FUR-FU-10001546	75043	2013-09-21	8.54	2	0.60	-7.48	4
42579	US-2014-106663	MO-17800	OFF-PA-10002377	60653	2016-06-09	36.35	8	0.20	11.36	2
42580	US-2012-163685	KE-16420	OFF-BI-10001890	78207	2014-06-01	5.73	8	0.80	-9.16	2
42581	CA-2014-140298	JK-16120	OFF-PA-10003657	78745	2016-05-11	6.85	2	0.20	2.14	2
42582	CA-2013-128517	SW-20350	TEC-PH-10002555	48227	2015-04-10	517.90	2	0.00	134.65	1
42583	CA-2011-144029	MM-18055	OFF-AR-10000716	60623	2013-05-26	13.39	3	0.20	3.18	2
42584	CA-2013-133340	LH-17155	TEC-AC-10001109	49201	2015-12-10	59.98	2	0.00	25.19	2
42585	CA-2014-142461	KT-16480	FUR-BO-10001811	75217	2016-05-30	204.67	1	0.32	-6.02	1
42586	CA-2014-111220	JS-15595	OFF-FA-10002280	60653	2016-09-02	16.00	4	0.20	5.60	2
42587	US-2013-127971	DW-13195	FUR-FU-10000023	77095	2015-11-21	7.07	3	0.60	-2.83	2
42588	CA-2014-126221	CC-12430	OFF-AP-10002457	47201	2016-12-30	209.30	2	0.00	56.51	2
42589	CA-2013-162404	NF-18475	OFF-BI-10000948	61107	2015-07-24	11.42	4	0.80	-18.84	2
42590	CA-2014-162565	RR-19315	FUR-CH-10003973	60505	2016-12-11	520.46	2	0.30	-14.87	3
42591	US-2014-145863	RP-19390	OFF-BI-10004140	77041	2016-04-21	2.69	3	0.80	-4.71	2
42592	CA-2014-117044	HA-14920	OFF-PA-10003657	60623	2016-09-11	20.54	6	0.20	6.42	1
42593	CA-2013-140130	HW-14935	OFF-ST-10001128	74133	2015-11-01	332.94	3	0.00	9.99	2
42594	CA-2014-110905	RW-19690	OFF-AP-10004785	65807	2016-09-10	33.99	3	0.00	14.62	1
42595	CA-2014-155880	JD-16150	FUR-CH-10000422	53209	2016-03-25	90.99	1	0.00	14.56	2
42596	US-2012-122784	RA-19915	OFF-BI-10000546	60035	2014-07-20	2.88	5	0.80	-4.46	2
42597	CA-2011-134572	SV-20365	OFF-ST-10004634	77070	2013-04-20	44.84	5	0.20	5.61	1
42598	CA-2012-134747	DL-12925	TEC-PH-10002890	46060	2014-10-12	135.72	3	0.00	35.29	1
42599	CA-2012-151589	RE-19450	OFF-PA-10003228	54703	2014-12-27	195.64	4	0.00	91.95	4
42600	CA-2012-145394	MC-17605	TEC-PH-10001051	60610	2014-11-16	239.98	3	0.20	27.00	2
42601	CA-2013-111794	HG-15025	OFF-PA-10000474	79109	2015-10-02	28.35	1	0.20	9.57	3
42602	CA-2014-100223	LS-16945	OFF-BI-10003429	75220	2016-07-05	11.39	9	0.80	-17.66	2
42603	CA-2012-124541	TT-21220	OFF-AR-10004078	77041	2014-04-06	42.05	9	0.20	5.26	2
42604	CA-2014-111220	JS-15595	OFF-AP-10003278	60653	2016-09-02	5.59	2	0.80	-15.09	2
42605	US-2012-124219	KW-16570	FUR-FU-10000305	63122	2014-08-07	212.94	3	0.00	34.07	4
42606	CA-2014-150525	JP-16135	OFF-AR-10002375	74403	2016-02-21	6.56	2	0.00	1.90	2
42607	CA-2012-130610	VP-21730	OFF-BI-10003655	48310	2014-07-05	19.00	5	0.00	8.93	2
42608	CA-2011-106229	NR-18550	FUR-TA-10002041	60505	2013-06-07	268.94	3	0.50	-209.77	1
42609	CA-2014-135111	CS-12400	OFF-AR-10004707	58103	2016-12-28	2.48	1	0.00	0.87	2
42610	CA-2014-155558	PG-18895	TEC-AC-10001998	55901	2016-10-26	19.99	1	0.00	6.80	2
42611	CA-2013-158568	RB-19465	TEC-AC-10001767	60610	2015-08-30	95.98	3	0.20	-10.80	2
42612	CA-2013-114601	AA-10480	TEC-AC-10003911	48234	2015-08-27	479.97	3	0.00	163.19	2
42613	CA-2011-124478	MA-17560	OFF-AP-10002495	48183	2013-08-08	167.54	3	0.10	37.23	2
42614	CA-2012-111395	VB-21745	OFF-ST-10001291	78207	2014-11-23	27.06	2	0.20	2.37	2
42615	CA-2012-124541	TT-21220	OFF-PA-10001526	77041	2014-04-06	7.97	2	0.20	2.89	2
42616	US-2011-157406	DA-13450	OFF-PA-10003543	77095	2013-04-25	10.37	2	0.20	3.63	2
42617	CA-2014-128328	PO-18865	OFF-BI-10001989	46203	2016-08-05	125.88	6	0.00	60.42	2
42618	US-2014-107384	TP-21130	OFF-AR-10001315	55901	2016-12-04	8.80	5	0.00	2.55	2
42619	CA-2011-130421	SC-20020	OFF-AP-10002534	77095	2013-03-03	176.77	3	0.80	-459.61	2
42620	CA-2012-158659	SC-20695	OFF-ST-10003306	47374	2014-11-10	714.30	5	0.00	207.15	1
42621	CA-2013-163398	CB-12415	OFF-AP-10002403	60653	2015-05-04	26.41	3	0.80	-71.30	2
42622	CA-2012-163181	AB-10105	OFF-BI-10000474	77041	2014-11-07	32.06	10	0.80	-51.30	2
42623	CA-2012-108532	CC-12100	TEC-PH-10001750	48234	2014-08-29	131.98	2	0.00	35.63	2
42624	CA-2012-145835	BF-11170	OFF-FA-10002280	60623	2014-05-13	16.00	4	0.20	5.60	1
42625	CA-2011-122749	NG-18430	TEC-PH-10003811	73120	2013-12-03	479.96	4	0.00	134.39	2
42626	CA-2014-111220	JS-15595	OFF-ST-10003994	60653	2016-09-02	235.92	5	0.20	-44.24	2
42627	CA-2014-121741	YC-21895	OFF-ST-10004459	68025	2016-12-26	750.68	2	0.00	37.53	3
42628	CA-2012-160472	RK-19300	OFF-PA-10000528	46614	2014-07-20	26.40	5	0.00	11.88	1
42629	CA-2012-164007	MG-17695	TEC-AC-10003433	60610	2014-06-08	2.38	3	0.20	0.74	2
42630	CA-2012-121097	SF-20965	OFF-PA-10001937	77520	2014-01-03	10.37	2	0.20	3.63	2
42631	CA-2012-149587	KB-16315	OFF-PA-10003177	55407	2014-01-31	12.96	2	0.00	6.22	1
42632	CA-2011-165428	JL-15130	OFF-BI-10002949	77036	2013-09-01	3.65	3	0.80	-6.02	4
42633	US-2014-150595	LE-16810	FUR-CH-10000513	60653	2016-05-22	181.99	2	0.30	-54.60	2
42634	CA-2014-133102	ED-13885	OFF-AR-10003183	77095	2016-08-17	8.02	3	0.20	1.00	2
42635	CA-2013-141551	BP-11230	OFF-PA-10001569	74012	2015-09-25	6.48	1	0.00	3.11	2
42636	US-2014-106551	EB-13930	FUR-CH-10004997	60653	2016-07-22	526.34	4	0.30	-75.19	2
42637	CA-2012-141810	BB-10990	TEC-PH-10002200	78207	2014-11-02	344.70	2	0.20	38.78	2
42638	CA-2011-151001	JG-15805	OFF-ST-10001031	62521	2013-04-05	52.10	4	0.20	3.91	4
42639	CA-2012-145835	BF-11170	TEC-PH-10004447	60623	2014-05-13	222.38	2	0.20	16.68	1
42640	CA-2014-139444	GK-14620	OFF-LA-10000134	75023	2016-09-09	9.86	4	0.20	3.45	2
42641	CA-2013-159940	BF-11020	OFF-PA-10001609	60505	2015-07-08	23.69	9	0.20	7.70	1
42642	US-2013-148334	DD-13570	OFF-BI-10003676	77041	2015-08-23	4.31	2	0.80	-6.90	2
42643	US-2012-163783	DR-12940	OFF-ST-10002957	60610	2014-12-27	12.67	3	0.20	-3.17	2
42644	US-2012-118983	HP-14815	OFF-BI-10000756	76106	2014-11-22	2.54	3	0.80	-3.82	2
42645	CA-2014-121160	FM-14290	OFF-BI-10003094	77803	2016-11-04	1.41	2	0.80	-2.32	3
42646	CA-2013-142335	MP-17965	OFF-ST-10000036	48205	2015-12-16	296.37	3	0.00	80.02	2
42647	CA-2012-111017	SC-20695	OFF-SU-10002573	63116	2014-07-31	52.59	3	0.00	15.78	2
42648	CA-2014-113474	TM-21490	OFF-EN-10004206	73120	2016-03-30	325.86	2	0.00	149.90	4
42649	CA-2014-146164	CM-12190	OFF-ST-10001228	55901	2016-12-22	31.16	2	0.00	7.79	2
42650	CA-2013-145730	CC-12220	FUR-TA-10004915	78207	2015-03-04	637.90	3	0.30	-127.58	2
42651	US-2012-165512	VS-21820	FUR-CH-10002880	60540	2014-05-24	602.65	7	0.30	-163.58	1
42652	CA-2011-168312	GW-14605	OFF-ST-10003692	77036	2013-03-01	137.35	3	0.20	8.58	2
42653	CA-2014-137365	BP-11095	TEC-AC-10001767	79907	2016-11-30	95.98	3	0.20	-10.80	1
42654	CA-2011-169446	SG-20605	OFF-ST-10000419	60623	2013-12-19	32.59	3	0.20	-7.74	2
42655	CA-2013-113551	NF-18385	OFF-BI-10001617	78539	2015-08-19	2.07	1	0.80	-3.41	4
42656	CA-2012-135685	MP-18175	FUR-TA-10000688	53209	2014-11-16	653.55	3	0.00	111.10	1
42657	CA-2014-100951	NC-18625	OFF-ST-10001496	75217	2016-06-09	720.76	5	0.20	54.06	4
42658	US-2013-158708	AB-10255	TEC-AC-10003133	75023	2015-06-27	13.62	2	0.20	3.57	1
42659	CA-2012-105690	CA-11965	FUR-BO-10003965	77642	2014-11-21	246.13	2	0.32	-76.01	1
42660	CA-2014-119655	CV-12295	OFF-BI-10001036	48234	2016-04-20	36.56	4	0.00	18.28	2
42661	CA-2014-162565	RR-19315	FUR-FU-10004306	60505	2016-12-11	77.72	1	0.60	-66.06	3
42662	CA-2013-114209	AS-10285	OFF-PA-10003591	75081	2015-05-22	82.66	9	0.20	31.00	2
42663	CA-2011-133963	GA-14515	OFF-PA-10001526	75220	2013-05-18	3.98	1	0.20	1.44	1
42664	CA-2011-134103	MV-18190	OFF-PA-10001204	48234	2013-01-30	10.56	2	0.00	4.75	2
42665	CA-2013-143924	SC-20680	OFF-PA-10002120	49423	2015-07-29	109.92	2	0.00	53.86	2
42666	CA-2013-113803	VG-21805	OFF-PA-10001994	47374	2015-03-25	22.48	1	0.00	10.34	4
42667	CA-2012-143147	PS-18760	TEC-MA-10004679	78207	2014-05-26	399.54	2	0.40	-79.91	1
42668	CA-2011-118339	BN-11515	OFF-AR-10003829	55044	2013-03-17	19.68	6	0.00	5.71	2
42669	US-2013-144057	CV-12805	OFF-BI-10002852	78745	2015-05-10	13.18	4	0.80	-20.44	2
42670	CA-2014-152485	JD-15790	OFF-AR-10001940	75019	2016-09-04	13.12	5	0.20	3.77	2
42671	CA-2014-157966	SU-20665	OFF-AR-10003338	60610	2016-03-13	29.76	5	0.20	1.86	3
42672	CA-2012-127607	JK-15730	OFF-FA-10003485	75007	2014-03-20	18.86	9	0.20	6.13	2
42673	CA-2012-139738	DK-12895	OFF-AR-10004602	61107	2014-09-25	128.74	7	0.20	12.87	2
42674	CA-2011-154186	RA-19285	OFF-SU-10001574	77070	2013-12-13	2.92	1	0.20	0.37	1
42675	CA-2014-150525	JP-16135	OFF-AP-10000595	74403	2016-02-21	13.11	3	0.00	3.41	2
42676	US-2013-144547	MS-17770	TEC-AC-10004901	77036	2015-11-11	279.94	7	0.20	48.99	2
42677	US-2012-118766	LS-16975	OFF-BI-10002813	75217	2014-10-15	3.96	10	0.80	-6.93	2
42678	CA-2011-161508	PV-18985	OFF-FA-10001561	77573	2013-07-12	3.49	2	0.20	0.57	2
42679	CA-2012-164007	MG-17695	OFF-AP-10003849	60610	2014-06-08	143.13	2	0.80	-393.60	2
42680	CA-2011-107706	ST-20530	OFF-PA-10000466	77095	2013-02-14	16.18	3	0.20	6.07	1
42681	CA-2014-156622	JP-15460	OFF-PA-10002923	75220	2016-11-23	78.30	2	0.20	29.36	4
42682	CA-2012-124541	TT-21220	TEC-AC-10002550	77041	2014-04-06	25.49	2	0.20	4.46	2
42683	CA-2011-145926	MP-17470	FUR-CH-10004289	56560	2013-11-17	479.90	5	0.00	81.58	2
42684	CA-2014-149048	BM-11650	TEC-PH-10002310	47201	2016-05-13	587.97	3	0.00	158.75	2
42685	CA-2013-124352	CD-12790	OFF-LA-10003223	73120	2015-10-16	29.46	6	0.00	14.44	2
42686	CA-2013-116337	MC-17845	OFF-ST-10001272	75220	2015-11-08	314.09	3	0.20	19.63	2
42687	CA-2013-116526	JA-15970	OFF-AP-10002457	48227	2015-09-02	376.74	4	0.10	71.16	2
42688	CA-2011-119172	HD-14785	OFF-BI-10002026	60610	2013-05-11	104.58	9	0.80	-172.56	2
42689	CA-2014-121615	DL-12925	OFF-PA-10000327	55122	2016-11-03	8.56	2	0.00	3.85	2
42690	US-2012-163433	MP-17965	OFF-BI-10000320	78501	2014-04-18	1.48	1	0.80	-2.29	1
42691	US-2012-129637	MC-18100	OFF-ST-10003716	61701	2014-12-17	180.02	1	0.20	-15.75	2
42692	US-2011-103905	AW-10930	TEC-PH-10001552	60505	2013-07-14	38.27	4	0.20	3.83	2
42693	US-2013-131674	NC-18535	TEC-AC-10004864	75217	2015-11-30	58.42	2	0.20	16.79	1
42694	CA-2013-124352	CD-12790	OFF-AP-10002651	73120	2015-10-16	868.59	3	0.00	251.89	2
42695	CA-2014-152933	MG-17650	TEC-AC-10003033	75081	2016-10-12	791.88	3	0.20	128.68	2
42696	US-2012-132836	AJ-10945	OFF-BI-10004224	48227	2014-06-01	403.68	6	0.00	181.66	2
42697	CA-2014-113355	SJ-20215	TEC-PH-10004912	75051	2016-12-01	219.80	5	0.20	24.73	2
42698	CA-2012-150413	CS-11860	OFF-BI-10000404	75220	2014-10-19	1.72	1	0.80	-2.84	1
42699	CA-2014-122595	GM-14455	TEC-PH-10003095	60653	2016-12-14	52.68	3	0.20	19.76	2
42700	CA-2014-127922	SH-19975	OFF-EN-10003068	75081	2016-10-27	15.84	2	0.20	5.54	2
42701	CA-2014-126550	RD-19720	OFF-ST-10001031	47905	2016-03-29	81.40	5	0.00	21.16	1
42702	CA-2014-163160	TS-21610	OFF-BI-10000778	61032	2016-10-13	96.78	4	0.80	-145.18	4
42703	US-2011-159618	DB-12970	OFF-AR-10003183	77036	2013-11-12	2.67	1	0.20	0.33	2
42704	CA-2014-144113	JF-15355	OFF-EN-10001141	78745	2016-09-16	17.57	2	0.20	6.37	2
42705	US-2014-124968	MM-18055	FUR-TA-10004289	60610	2016-09-08	765.63	7	0.50	-566.56	1
42706	US-2014-122637	EP-13915	OFF-BI-10002429	60653	2016-09-03	42.62	7	0.80	-68.19	1
42707	CA-2013-105732	AG-10270	FUR-FU-10003664	68104	2015-09-14	1336.44	14	0.00	387.57	2
42708	CA-2012-149909	RA-19915	OFF-PA-10001790	47201	2014-11-13	96.08	2	0.00	46.12	2
42709	US-2012-168704	FP-14320	FUR-TA-10002530	77340	2014-04-13	211.37	2	0.30	-45.29	2
42710	CA-2014-146920	SC-20305	OFF-PA-10001461	60623	2016-08-28	26.72	5	0.20	9.35	2
42711	CA-2014-144568	JO-15550	OFF-FA-10004395	68104	2016-05-29	23.55	5	0.00	1.18	2
42712	CA-2014-146024	SC-20770	OFF-BI-10003291	75081	2016-03-02	12.22	7	0.80	-20.17	2
42713	CA-2014-159149	CR-12820	FUR-BO-10001601	77041	2016-02-18	89.07	1	0.32	-17.03	4
42714	US-2013-132577	JE-15475	TEC-AC-10000387	77095	2015-11-23	24.03	2	0.20	-0.60	2
42715	CA-2013-152289	LC-16930	TEC-AC-10004571	77506	2015-08-27	159.98	2	0.20	44.00	4
42716	CA-2014-148642	DW-13540	OFF-AR-10000588	75220	2016-03-06	63.49	4	0.20	4.76	2
42717	CA-2014-117485	BD-11320	TEC-AC-10004659	74133	2016-09-23	291.96	4	0.00	102.19	2
42718	CA-2014-163265	JS-16030	FUR-FU-10004270	62521	2016-02-17	7.69	1	0.60	-3.65	2
42719	CA-2014-102519	BM-11650	FUR-FU-10004091	53209	2016-11-27	46.94	1	0.00	19.25	4
42720	CA-2014-165386	CM-12190	FUR-BO-10003034	60623	2016-08-03	183.37	2	0.30	-36.67	4
42721	CA-2014-159457	RD-19480	TEC-PH-10002185	77095	2016-10-19	16.68	3	0.20	5.21	2
42722	CA-2014-104220	BV-11245	OFF-AR-10004648	50315	2016-01-31	40.30	2	0.00	10.88	2
42723	CA-2014-131254	NC-18415	FUR-CH-10003774	77095	2016-11-19	191.06	3	0.30	-46.40	4
42724	CA-2011-127446	MC-17590	TEC-AC-10001635	76017	2013-11-25	24.67	3	0.20	0.00	2
42725	CA-2014-117044	HA-14920	OFF-FA-10000936	60623	2016-09-11	10.53	4	0.20	3.29	1
42726	CA-2011-106971	BM-11785	TEC-AC-10000844	60089	2013-09-02	475.94	7	0.20	95.19	2
42727	CA-2013-154018	HA-14920	OFF-AR-10002067	78041	2015-10-14	15.87	1	0.20	1.19	2
42728	CA-2013-163048	MH-17440	FUR-CH-10001270	77036	2015-02-08	241.50	4	0.30	0.00	2
42729	US-2013-149790	SC-20380	OFF-BI-10002026	77095	2015-09-27	15.62	2	0.80	-25.00	2
42730	CA-2011-118339	BN-11515	OFF-BI-10000136	55044	2013-03-17	35.88	6	0.00	17.22	2
42731	CA-2014-100356	SP-20920	OFF-AP-10002191	60653	2016-10-21	23.99	2	0.80	-62.38	2
42732	CA-2012-160794	MS-17980	OFF-PA-10004156	77041	2014-08-06	27.22	3	0.20	9.87	4
42733	CA-2011-109491	LC-16930	TEC-AC-10001284	47374	2013-02-20	62.31	3	0.00	22.43	2
42734	US-2013-137547	EB-13705	TEC-PH-10002365	76106	2015-03-08	21.07	3	0.20	1.58	2
42735	CA-2014-112529	SC-20770	OFF-AR-10001915	78207	2016-11-19	31.78	4	0.20	8.74	4
42736	CA-2011-162866	Co-12640	OFF-ST-10002562	60076	2013-12-27	30.02	4	0.20	3.00	2
42737	US-2011-134971	BP-11095	OFF-BI-10003982	61604	2013-06-07	12.46	3	0.80	-20.56	1
42738	CA-2011-105340	EH-14185	OFF-BI-10001765	77506	2013-11-22	6.93	1	0.80	-11.08	4
42739	CA-2014-100783	JK-16120	OFF-AR-10000380	75043	2016-09-04	30.38	1	0.20	3.80	1
42740	CA-2014-160927	TM-21010	FUR-FU-10000010	52302	2016-01-30	14.91	3	0.00	4.62	1
42741	CA-2012-122259	HP-14815	OFF-SU-10002573	49201	2014-10-31	70.12	4	0.00	21.04	2
42742	CA-2014-154676	NZ-18565	OFF-ST-10001172	77070	2016-08-05	151.06	9	0.20	7.55	4
42743	CA-2013-118101	SN-20560	OFF-ST-10001837	48066	2015-06-27	171.04	4	0.00	44.47	3
42744	CA-2011-113257	SC-20305	FUR-FU-10001706	77705	2013-12-16	8.62	7	0.60	-2.59	1
42745	CA-2011-148782	PO-18850	TEC-PH-10002923	75061	2013-11-02	88.78	3	0.20	7.77	2
42746	CA-2012-121783	PO-19180	FUR-FU-10004351	55113	2014-11-10	29.22	3	0.00	12.86	2
42747	CA-2011-105165	SZ-20035	OFF-AR-10003179	77036	2013-09-07	21.86	3	0.20	3.55	4
42748	CA-2011-106803	DC-13285	OFF-ST-10002444	55016	2013-12-29	24.56	2	0.00	6.88	2
42749	US-2014-141698	SD-20485	OFF-PA-10001826	77041	2016-04-15	20.74	4	0.20	7.26	2
42750	CA-2014-169691	Dp-13240	OFF-LA-10002312	55369	2016-06-15	44.40	3	0.00	22.20	4
42751	CA-2013-124352	CD-12790	OFF-PA-10003177	73120	2015-10-16	12.96	2	0.00	6.22	2
42752	CA-2011-124807	ME-17725	OFF-PA-10001526	60610	2013-07-12	35.86	9	0.20	13.00	1
42753	CA-2014-168123	JD-16060	OFF-BI-10001097	55901	2016-03-05	18.69	3	0.00	9.16	3
42754	US-2011-158365	SV-20785	OFF-PA-10000289	47401	2013-04-12	32.40	5	0.00	15.55	2
42755	CA-2014-149048	BM-11650	OFF-BI-10004632	47201	2016-05-13	914.97	3	0.00	411.74	2
42756	CA-2013-120824	AW-10930	FUR-FU-10001424	77070	2015-06-13	6.98	2	0.60	-4.54	1
42757	CA-2013-115574	BP-11185	FUR-BO-10003441	60623	2015-12-24	141.37	2	0.30	-14.14	4
42758	US-2011-161613	MC-17605	FUR-CH-10003746	77070	2013-12-01	674.06	3	0.30	-19.26	1
42759	CA-2014-151750	JM-15250	OFF-AP-10004708	77340	2016-01-02	15.22	2	0.80	-38.82	2
42760	CA-2012-156608	MT-18070	OFF-BI-10004140	78207	2014-10-24	3.59	4	0.80	-6.29	2
42761	CA-2011-120411	SB-20185	TEC-PH-10002185	60653	2013-09-20	11.12	2	0.20	3.48	4
42762	US-2013-131114	RW-19630	TEC-AC-10000199	60610	2015-12-10	19.04	4	0.20	-1.43	1
42763	CA-2013-133725	KL-16645	TEC-PH-10004165	60623	2015-05-24	1979.93	9	0.20	148.49	2
42764	CA-2014-128783	TG-21640	FUR-FU-10003623	63301	2016-09-07	135.30	5	0.00	37.88	3
42765	US-2013-115441	SH-19975	TEC-PH-10002262	53209	2015-07-26	297.55	5	0.00	83.31	1
42766	CA-2014-142125	JB-15400	OFF-BI-10003460	53209	2016-10-21	21.90	5	0.00	10.51	2
42767	CA-2013-149195	DM-13525	OFF-PA-10002036	77070	2015-09-06	10.37	2	0.20	3.76	1
42768	CA-2013-102813	EA-14035	FUR-CH-10000665	77340	2015-07-03	528.43	5	0.30	0.00	4
42769	US-2011-104759	DD-13570	TEC-AC-10004901	60610	2013-03-31	79.98	2	0.20	14.00	2
42770	CA-2012-148873	EM-13960	TEC-AC-10003657	62301	2014-10-01	108.77	4	0.20	2.72	2
42771	CA-2011-131926	DW-13480	OFF-PA-10004082	55044	2013-06-01	47.88	6	0.00	23.94	1
42772	CA-2013-105900	BS-11590	OFF-AR-10002656	47201	2015-09-18	33.40	5	0.00	12.36	2
42773	CA-2013-154018	HA-14920	TEC-AC-10002402	78041	2015-10-14	191.98	3	0.20	24.00	2
42774	CA-2013-111318	IL-15100	TEC-PH-10004100	77041	2015-07-24	115.14	8	0.20	11.51	4
42775	CA-2012-121783	PO-19180	OFF-AP-10003849	55113	2014-11-10	715.64	2	0.00	178.91	2
42776	CA-2013-128916	MA-17560	FUR-FU-10000320	77070	2015-08-19	5.34	4	0.60	-2.14	1
42777	US-2012-159982	DR-12880	OFF-ST-10004804	60623	2014-11-28	82.37	2	0.20	-19.56	2
42778	CA-2014-131618	LS-17200	OFF-PA-10001892	60076	2016-06-17	12.22	2	0.20	4.43	4
42779	CA-2014-138289	AR-10540	FUR-CH-10004626	49201	2016-01-17	302.67	3	0.00	72.64	1
42780	US-2014-143028	SC-20050	OFF-BI-10004738	79424	2016-04-11	11.36	3	0.80	-17.05	2
42781	CA-2012-162621	CA-12055	OFF-BI-10003708	77036	2014-09-05	4.47	3	0.80	-7.82	2
42782	CA-2012-104871	DR-12940	FUR-CH-10003298	61761	2014-03-30	366.74	4	0.30	-110.02	2
42783	CA-2012-110016	BT-11395	OFF-PA-10000349	48227	2014-11-29	19.92	4	0.00	9.36	2
42784	CA-2011-144281	HK-14890	OFF-LA-10003930	48234	2013-06-10	491.55	5	0.00	240.86	1
42785	CA-2011-164861	MC-17635	OFF-PA-10001972	63116	2013-12-03	25.92	4	0.00	12.44	1
42786	CA-2014-138289	AR-10540	OFF-BI-10004995	49201	2016-01-17	5443.96	4	0.00	2504.22	1
42787	CA-2012-154284	SZ-20035	OFF-AR-10001468	60174	2014-12-21	59.90	2	0.20	14.23	1
42788	CA-2012-140221	MS-17365	OFF-AP-10000828	60653	2014-03-05	180.98	5	0.80	-470.55	1
42789	CA-2011-109890	PG-18820	TEC-PH-10004100	68104	2013-07-21	35.98	2	0.00	10.07	2
42790	CA-2012-115742	DP-13000	OFF-BI-10004410	47150	2014-04-18	38.22	6	0.00	17.96	2
42791	US-2013-117793	MA-17560	TEC-AC-10003433	53081	2015-08-24	1.98	2	0.00	0.89	2
42792	CA-2014-113278	HR-14770	TEC-AC-10004469	47374	2016-01-15	159.80	4	0.00	70.31	2
42793	CA-2014-162565	RR-19315	OFF-PA-10001937	60505	2016-12-11	10.37	2	0.20	3.63	3
42794	CA-2014-136609	TB-21355	OFF-PA-10004381	75104	2016-08-06	115.30	3	0.20	40.35	2
42795	US-2013-132577	JE-15475	OFF-BI-10003196	77095	2015-11-23	4.49	6	0.80	-6.73	2
42796	CA-2012-161767	GK-14620	TEC-MA-10002790	75217	2014-11-20	479.99	2	0.40	56.00	2
42797	CA-2012-146675	SB-20185	TEC-AC-10004396	60201	2014-04-16	43.56	3	0.20	-4.90	2
42798	US-2014-145863	RP-19390	OFF-BI-10002049	77041	2016-04-21	2.93	3	0.80	-4.99	2
42799	US-2014-124779	BF-11020	OFF-FA-10004854	76017	2016-09-08	45.92	5	0.20	15.50	4
42800	CA-2011-126907	SM-20950	OFF-PA-10000533	60610	2013-11-01	15.70	3	0.20	5.10	2
42801	US-2012-165449	AP-10720	TEC-AC-10004127	75034	2014-11-22	27.17	4	0.20	-1.36	2
42802	CA-2011-109491	LC-16930	FUR-FU-10000221	47374	2013-02-20	20.32	4	0.00	6.91	2
42803	CA-2012-162964	MF-18250	OFF-ST-10002344	77095	2014-11-12	64.78	1	0.20	-14.58	2
42804	CA-2012-105690	CA-11965	OFF-LA-10000240	77642	2014-11-21	11.70	2	0.20	3.95	1
42805	CA-2013-153577	KH-16330	OFF-PA-10000575	60035	2015-06-28	37.46	7	0.20	12.18	2
42806	CA-2012-124975	MG-17875	FUR-TA-10002645	60505	2014-06-22	796.43	7	0.50	-525.64	4
42807	CA-2014-115651	NS-18640	OFF-AP-10000055	60610	2016-07-09	58.46	9	0.80	-146.16	4
42808	CA-2013-168032	DF-13135	TEC-PH-10004241	61107	2015-01-30	1439.97	4	0.20	144.00	2
42809	US-2013-132577	JE-15475	OFF-LA-10000262	77095	2015-11-23	2.09	1	0.20	0.68	2
42810	CA-2014-113278	HR-14770	OFF-PA-10004156	47374	2016-01-15	11.34	1	0.00	5.56	2
42811	CA-2012-135251	RP-19270	FUR-BO-10003965	77095	2014-08-06	369.20	3	0.32	-114.02	2
42812	CA-2014-134285	DS-13180	OFF-PA-10000304	78207	2016-12-07	15.55	3	0.20	5.44	2
42813	CA-2014-164168	LS-16975	OFF-BI-10000666	75081	2016-11-12	30.56	5	0.80	-45.84	2
42814	CA-2014-162712	NK-18490	OFF-PA-10000167	78415	2016-06-18	74.35	3	0.20	23.24	1
42815	CA-2013-133550	KL-16645	TEC-PH-10004042	48205	2015-08-01	635.96	4	0.00	165.35	2
42816	CA-2012-105158	SP-20860	FUR-FU-10001706	55901	2014-09-05	6.16	2	0.00	2.96	2
42817	CA-2011-165393	NC-18415	OFF-BI-10001658	76106	2013-12-27	4.98	1	0.80	-8.47	4
42818	US-2012-130491	BH-11710	OFF-AR-10001149	67846	2014-02-08	5.76	2	0.00	1.73	4
42819	CA-2011-113257	SC-20305	TEC-AC-10004171	77705	2013-12-16	319.97	4	0.20	95.99	1
42820	CA-2012-137512	AG-10675	OFF-PA-10000213	75002	2014-05-07	15.94	4	0.20	5.38	2
42821	CA-2012-153108	SF-20200	TEC-PH-10001552	47362	2014-03-05	23.92	2	0.00	6.70	2
42822	CA-2011-122567	MN-17935	OFF-AP-10001303	75220	2013-02-16	7.96	2	0.80	-13.93	2
42823	CA-2013-130946	ZC-21910	FUR-CH-10004540	77041	2015-04-09	95.98	4	0.30	-4.11	2
42824	CA-2013-112739	RD-19810	TEC-AC-10001714	77070	2015-09-03	159.56	5	0.20	33.91	1
42825	CA-2013-163153	DM-12955	FUR-TA-10004767	77036	2015-03-22	99.37	2	0.30	-1.42	2
42826	CA-2014-167626	MY-18295	OFF-PA-10003424	60623	2016-09-03	8.90	3	0.20	3.34	2
42827	US-2014-108700	PJ-18835	OFF-PA-10004733	61107	2016-05-19	38.02	6	0.20	13.78	2
42828	CA-2012-122623	CC-12145	FUR-CH-10000553	79907	2014-09-07	47.52	2	0.30	-2.04	2
42829	CA-2014-150266	RO-19780	OFF-AR-10001761	77070	2016-11-25	18.69	4	0.20	3.74	2
42830	CA-2014-143294	JD-15790	OFF-PA-10000743	77070	2016-06-02	10.69	2	0.20	3.74	2
42831	US-2014-151316	MC-17635	OFF-BI-10004632	62521	2016-06-24	182.99	3	0.80	-320.24	2
42832	CA-2013-114489	JE-16165	TEC-PH-10000215	53132	2015-12-06	384.45	11	0.00	103.80	2
42833	US-2014-156356	ND-18370	OFF-BI-10000632	77095	2016-04-16	26.05	3	0.80	-44.28	2
42834	CA-2011-124478	MA-17560	TEC-CO-10001571	48183	2013-08-08	549.99	1	0.00	275.00	2
42835	CA-2013-152555	ME-17320	FUR-CH-10002965	60653	2015-03-30	844.12	6	0.30	-36.18	1
42836	CA-2014-105669	SJ-20125	TEC-PH-10002415	77036	2016-09-17	1415.76	6	0.20	88.49	1
42837	US-2012-104430	LT-17110	OFF-BI-10000301	61701	2014-10-22	5.18	4	0.80	-7.76	2
42838	CA-2012-137512	AG-10675	FUR-TA-10001095	75002	2014-05-07	244.01	2	0.30	-31.37	2
42839	CA-2012-163055	DS-13180	FUR-TA-10003748	48227	2014-08-09	622.45	5	0.00	136.94	2
42840	US-2013-133508	SW-20350	OFF-FA-10000134	68104	2015-04-18	29.05	5	0.00	9.01	2
42841	CA-2013-110898	LC-16870	FUR-TA-10000849	60623	2015-03-07	145.98	2	0.50	-99.27	2
42842	CA-2014-122035	EM-13825	OFF-LA-10004093	57103	2016-07-20	14.62	2	0.00	6.87	2
42843	CA-2013-153157	TB-21625	TEC-PH-10003171	67212	2015-09-12	224.75	5	0.00	62.93	4
42844	CA-2012-138009	SF-20965	OFF-AP-10000179	48126	2014-11-29	555.21	5	0.10	178.90	2
42845	CA-2014-168123	JD-16060	OFF-ST-10000877	55901	2016-03-05	221.16	4	0.00	57.50	3
42846	CA-2011-137092	LS-16975	OFF-LA-10003510	60653	2013-10-20	24.42	1	0.20	7.94	1
42847	CA-2012-146563	CB-12025	FUR-TA-10001768	76017	2014-08-24	918.79	5	0.30	-118.13	2
42848	CA-2013-152289	LC-16930	FUR-CH-10002126	77506	2015-08-27	1024.72	6	0.30	-29.28	4
42849	CA-2014-132682	TH-21235	TEC-PH-10004042	75081	2016-06-08	381.58	3	0.20	28.62	1
42850	CA-2013-108868	KB-16585	TEC-PH-10000923	75081	2015-09-09	59.96	5	0.20	21.74	2
42851	CA-2014-139311	SF-20965	OFF-BI-10004209	76021	2016-08-11	12.86	8	0.80	-22.51	4
42852	US-2013-110156	EH-13945	OFF-FA-10003495	77041	2015-11-20	58.37	12	0.20	21.89	2
42853	CA-2013-142524	MB-18085	OFF-EN-10003286	65807	2015-09-05	16.56	2	0.00	7.78	2
42854	US-2014-118556	TH-21235	FUR-CH-10001146	60653	2016-05-28	106.87	3	0.30	-29.01	1
42855	CA-2014-118640	CS-11950	FUR-FU-10001475	60610	2016-07-20	8.79	1	0.60	-5.71	2
42856	CA-2014-107797	EB-13705	OFF-PA-10003848	76063	2016-05-08	41.47	8	0.20	14.52	1
42857	CA-2013-120824	AW-10930	FUR-CH-10000229	77070	2015-06-13	379.37	2	0.30	-119.23	1
42858	CA-2012-144190	NC-18415	OFF-PA-10000304	48073	2014-06-09	12.96	2	0.00	6.22	2
42859	US-2011-106992	SB-20290	TEC-MA-10003353	77036	2013-09-19	2519.96	7	0.40	-252.00	1
42860	CA-2014-106068	RB-19330	TEC-AC-10002942	78745	2016-10-23	55.20	1	0.20	-2.07	2
42861	CA-2013-155992	CC-12220	TEC-PH-10000215	46350	2015-10-02	69.90	2	0.00	18.87	4
42862	CA-2011-103800	DP-13000	OFF-PA-10000174	77095	2013-01-03	16.45	2	0.20	5.55	2
42863	CA-2014-167976	JL-15505	OFF-SU-10004661	57401	2016-11-11	25.50	3	0.00	6.63	1
42864	CA-2014-135307	LS-17245	TEC-AC-10002399	64118	2016-11-26	38.04	2	0.00	12.17	4
42865	US-2011-127635	SC-20260	OFF-FA-10000053	78415	2013-09-14	6.05	4	0.20	-1.36	1
42866	CA-2013-159373	LT-17110	FUR-TA-10004619	78207	2015-03-14	557.59	5	0.30	0.00	2
42867	CA-2011-137092	LS-16975	TEC-AC-10001606	60653	2013-10-20	319.97	4	0.20	71.99	1
42868	CA-2014-166317	JE-15610	TEC-AC-10004510	53209	2016-09-22	98.16	6	0.00	9.82	2
42869	CA-2014-127474	RD-19810	OFF-PA-10001166	60610	2016-02-04	5.18	1	0.20	1.81	1
42870	US-2014-119438	CD-11980	TEC-AC-10003614	75701	2016-03-18	27.82	3	0.20	4.52	2
42871	CA-2013-125087	TH-21115	FUR-FU-10004748	77070	2015-04-19	127.88	5	0.60	-67.14	2
42872	CA-2013-119186	MS-17710	OFF-PA-10004040	76106	2015-05-27	14.35	3	0.20	5.20	3
42873	CA-2012-146829	TS-21340	OFF-BI-10004022	77041	2014-03-10	1.11	2	0.80	-1.89	3
42874	CA-2014-111808	AR-10510	OFF-BI-10004656	74133	2016-12-16	10.80	5	0.00	5.18	2
42875	US-2014-118556	TH-21235	OFF-BI-10004364	60653	2016-05-28	3.56	3	0.80	-6.24	1
42876	US-2011-160444	DC-12850	OFF-ST-10000563	77036	2013-07-05	281.42	11	0.20	-35.18	3
42877	CA-2014-107825	NB-18655	OFF-LA-10003720	53209	2016-11-18	7.38	2	0.00	3.47	3
42878	CA-2013-152730	EM-14140	OFF-AP-10002684	54880	2015-05-31	364.74	3	0.00	109.42	2
42879	CA-2011-129189	HM-14860	OFF-AP-10000124	75217	2013-07-21	4.99	3	0.80	-12.98	2
42880	US-2012-159982	DR-12880	OFF-ST-10001590	60623	2014-11-28	53.92	5	0.20	4.04	2
42881	CA-2014-106432	CA-12265	OFF-BI-10002799	76706	2016-10-19	2.07	2	0.80	-3.52	2
42882	US-2013-124163	SC-20695	TEC-AC-10001908	54601	2015-09-26	499.95	5	0.00	174.98	2
42883	CA-2011-104738	SP-20620	TEC-PH-10002468	78041	2013-12-30	217.58	2	0.20	19.04	1
42884	CA-2013-125087	TH-21115	FUR-CH-10002880	77070	2015-04-19	344.37	4	0.30	-93.47	2
42885	US-2011-140914	BH-11710	FUR-CH-10003379	60653	2013-11-11	797.94	4	0.30	-57.00	2
42886	CA-2014-147039	AA-10315	OFF-AP-10000576	55407	2016-06-29	362.94	3	0.00	90.74	2
42887	CA-2012-146563	CB-12025	OFF-ST-10001511	76017	2014-08-24	724.08	14	0.20	-135.77	2
42888	CA-2014-102267	SC-20800	OFF-FA-10000611	78539	2016-11-30	2.37	2	0.20	0.83	2
42889	CA-2012-112214	AH-10690	FUR-FU-10002364	75220	2014-08-05	14.76	5	0.60	-11.44	2
42890	CA-2011-120411	SB-20185	FUR-BO-10004218	60653	2013-09-20	493.43	5	0.30	-70.49	4
42891	US-2013-115441	SH-19975	OFF-PA-10004996	53209	2015-07-26	20.62	2	0.00	9.69	1
42892	CA-2012-142930	EB-14170	OFF-PA-10003395	78745	2014-11-28	335.52	4	0.20	117.43	2
42893	US-2011-100853	JB-15400	OFF-AP-10000891	60623	2013-09-14	52.45	2	0.80	-131.12	2
42894	CA-2014-132353	DB-13060	TEC-PH-10004536	60653	2016-09-15	323.98	3	0.20	20.25	4
42895	CA-2014-152499	EH-13765	OFF-FA-10002975	60623	2016-01-23	15.12	5	0.20	4.91	1
42896	CA-2014-133102	ED-13885	OFF-SU-10000432	77095	2016-08-17	5.55	2	0.20	-1.04	2
42897	US-2014-107384	TP-21130	TEC-AC-10001539	55901	2016-12-04	399.95	5	0.00	143.98	2
42898	CA-2014-106691	CC-12370	OFF-BI-10000145	77070	2016-11-06	1.25	2	0.80	-1.93	2
42899	CA-2013-132829	LA-16780	TEC-PH-10004539	77041	2015-12-24	453.58	3	0.20	39.69	1
42900	US-2011-140452	BK-11260	OFF-ST-10002485	60610	2013-12-06	35.17	2	0.20	-8.35	2
42901	CA-2011-144407	MS-17365	OFF-LA-10003923	48227	2013-09-09	103.60	7	0.00	51.80	2
42902	CA-2014-130771	LA-16780	TEC-PH-10002496	78745	2016-07-29	124.79	1	0.20	15.60	2
42903	CA-2014-169285	RW-19690	OFF-PA-10004971	47905	2016-03-21	5.78	1	0.00	2.83	2
42904	CA-2012-163181	AB-10105	TEC-MA-10001016	77041	2014-11-07	287.91	3	0.40	33.59	2
42905	CA-2012-120320	MV-18190	TEC-PH-10000149	77036	2014-03-05	31.92	2	0.20	2.39	2
42906	US-2011-113124	NC-18340	OFF-ST-10001511	55124	2013-03-30	129.30	2	0.00	6.47	2
42907	CA-2014-158876	AB-10150	FUR-FU-10001967	75007	2016-11-19	15.99	2	0.60	-13.99	1
42908	US-2011-140452	BK-11260	OFF-AP-10004036	60610	2013-12-06	14.02	4	0.80	-31.54	2
42909	CA-2011-126193	SS-20410	OFF-BI-10001249	60543	2013-09-07	3.83	3	0.80	-6.51	2
42910	CA-2013-124051	KA-16525	OFF-PA-10001289	60505	2015-12-30	186.05	6	0.20	67.44	4
42911	CA-2013-152555	ME-17320	TEC-PH-10001254	60653	2015-03-30	812.74	8	0.20	60.96	1
42912	CA-2012-134943	SU-20665	OFF-BI-10000666	48104	2014-12-05	152.80	5	0.00	76.40	4
42913	CA-2014-101945	GT-14710	OFF-FA-10004248	77070	2016-11-24	10.82	3	0.20	2.57	2
42914	CA-2014-125878	MH-18025	OFF-BI-10002609	60623	2016-02-26	1.79	3	0.80	-3.04	2
42915	CA-2011-159310	SC-20725	OFF-SU-10004115	77070	2013-11-07	40.71	7	0.20	3.56	2
42916	CA-2013-101448	EB-13930	OFF-BI-10004738	54601	2015-02-27	56.82	3	0.00	28.41	1
42917	CA-2011-146283	KT-16465	FUR-CH-10004287	77036	2013-09-08	966.70	5	0.30	-13.81	2
42918	CA-2014-169362	SP-20860	TEC-AC-10001383	75217	2016-10-12	39.98	2	0.20	-1.50	4
42919	CA-2014-141733	RW-19540	FUR-CH-10000595	48234	2016-05-07	476.80	2	0.00	119.20	2
42920	CA-2013-103982	AA-10315	OFF-FA-10001332	78664	2015-03-04	2.30	1	0.20	0.78	2
42921	CA-2011-163867	RE-19450	OFF-ST-10000877	62521	2013-06-03	132.70	3	0.20	9.95	4
42922	CA-2013-115756	PK-19075	FUR-FU-10000246	48227	2015-09-06	12.22	1	0.00	3.67	1
42923	US-2011-161305	SB-20170	OFF-EN-10000461	60623	2013-06-06	13.98	2	0.20	4.72	2
42924	CA-2013-149223	ER-13855	OFF-AP-10000358	55106	2015-09-07	77.88	6	0.00	22.59	2
42925	CA-2013-165218	RW-19630	OFF-ST-10001558	75220	2015-03-06	12.99	1	0.20	-0.81	2
42926	CA-2014-112039	JC-15775	TEC-PH-10000984	78207	2016-03-25	470.38	3	0.20	47.04	2
42927	CA-2011-113880	VF-21715	FUR-CH-10000863	60126	2013-03-01	634.12	6	0.30	-172.12	2
42928	CA-2011-109680	VP-21760	OFF-ST-10001932	46203	2013-10-06	386.34	2	0.00	54.09	4
42929	CA-2014-105669	SJ-20125	OFF-AR-10000390	77036	2016-09-17	9.91	3	0.20	3.22	1
42930	CA-2014-165099	DK-13375	OFF-AP-10001634	79605	2016-12-11	1.39	2	0.80	-3.76	4
42931	CA-2012-100818	JM-15265	OFF-PA-10001125	60653	2014-05-31	173.49	7	0.20	54.22	1
42932	CA-2014-152933	MG-17650	OFF-PA-10001934	75081	2016-10-12	10.37	2	0.20	3.76	2
42933	CA-2013-168956	EA-14035	OFF-AP-10004233	60623	2015-02-16	92.06	6	0.80	-225.56	2
42934	CA-2011-162089	MP-17470	TEC-PH-10001819	78521	2013-03-30	251.94	7	0.20	88.18	4
42935	CA-2011-110219	EB-13870	FUR-CH-10001146	78207	2013-05-05	127.87	3	0.30	-9.13	4
42936	CA-2011-126193	SS-20410	OFF-BI-10004632	60543	2013-09-07	304.99	5	0.80	-533.73	2
42937	CA-2012-153878	TS-21655	OFF-AP-10001205	53209	2014-04-25	272.40	5	0.00	76.27	2
42938	CA-2014-114524	EG-13900	OFF-BI-10002799	60623	2016-03-31	13.47	13	0.80	-22.90	1
42939	CA-2013-130946	ZC-21910	TEC-AC-10001990	77041	2015-04-09	431.93	9	0.20	64.79	2
42940	CA-2014-145128	SM-20320	FUR-FU-10000293	47905	2016-07-09	526.45	5	0.00	31.59	2
42941	US-2012-129637	MC-18100	FUR-FU-10000965	61701	2014-12-17	41.55	2	0.60	-19.74	2
42942	US-2012-107349	SL-20155	OFF-BI-10001765	77095	2014-07-13	41.57	6	0.80	-66.51	4
42943	CA-2012-133585	CM-12715	FUR-BO-10001811	77070	2014-03-01	1228.00	6	0.32	-36.12	4
42944	CA-2014-109960	DB-13210	OFF-AR-10001860	48234	2016-12-09	34.70	5	0.00	12.49	1
42945	CA-2013-146157	RD-19720	TEC-AC-10003657	60610	2015-11-22	81.58	3	0.20	2.04	2
42946	CA-2013-124352	CD-12790	TEC-PH-10003442	73120	2015-10-16	5.50	1	0.00	1.38	2
42947	CA-2012-120782	SD-20485	OFF-AP-10003779	48640	2014-04-28	186.73	1	0.10	41.50	4
42948	CA-2012-105970	PA-19060	OFF-EN-10001532	47374	2014-03-02	101.88	6	0.00	50.94	2
42949	CA-2012-130792	RA-19915	OFF-ST-10003327	77095	2014-04-28	23.83	3	0.20	2.68	2
42950	CA-2013-117625	GM-14500	OFF-EN-10001535	60610	2015-05-11	7.07	2	0.20	2.39	2
42951	CA-2012-105158	SP-20860	OFF-PA-10001970	55901	2014-09-05	36.84	3	0.00	17.31	2
42952	CA-2014-161774	GT-14710	OFF-PA-10003134	77041	2016-05-14	76.86	2	0.20	26.90	4
42953	CA-2013-108210	AT-10735	TEC-AC-10000109	77041	2015-05-31	223.96	5	0.20	11.20	3
42954	CA-2011-121006	SC-20020	OFF-ST-10004950	48640	2013-11-10	62.94	3	0.00	11.96	2
42955	CA-2011-139892	BM-11140	TEC-PH-10003931	78207	2013-09-08	143.98	3	0.20	9.00	2
42956	CA-2014-101637	AC-10615	OFF-ST-10002352	77705	2016-03-24	12.77	2	0.20	0.96	3
42957	CA-2012-130022	JK-16120	OFF-LA-10002787	55122	2014-08-10	3.75	1	0.00	1.80	2
42958	CA-2014-161774	GT-14710	OFF-PA-10000300	77041	2016-05-14	47.95	3	0.20	16.18	4
42959	CA-2014-100314	AS-10630	OFF-LA-10001569	77506	2016-09-29	7.97	2	0.20	2.59	2
42960	US-2013-111290	DK-13375	OFF-PA-10002262	48185	2015-07-23	32.40	5	0.00	15.55	2
42961	CA-2012-116687	NC-18625	OFF-LA-10000443	77095	2014-05-02	8.86	3	0.20	2.99	2
42962	CA-2012-136798	DL-12925	FUR-FU-10000723	55407	2014-05-08	123.96	3	0.00	11.16	2
42963	CA-2013-117121	AB-10105	OFF-BI-10000545	48205	2015-12-18	9892.74	13	0.00	4946.37	2
42964	CA-2013-167605	RB-19570	FUR-FU-10001602	60174	2015-04-29	30.34	2	0.60	-31.86	1
42965	CA-2014-110905	RW-19690	TEC-AC-10003023	65807	2016-09-10	296.85	5	0.00	53.43	1
42966	CA-2012-121650	KD-16495	OFF-AR-10001149	49201	2014-12-10	3.90	2	0.00	1.52	2
42967	CA-2014-121216	MM-17920	OFF-AP-10001947	77840	2016-12-23	29.31	8	0.80	-74.75	1
42968	CA-2014-146493	CV-12805	OFF-BI-10003676	68025	2016-06-01	53.90	5	0.00	25.87	2
42969	US-2014-136721	NH-18610	FUR-FU-10004665	48237	2016-04-08	273.96	2	0.00	71.23	2
42970	CA-2014-119746	CM-12385	OFF-LA-10001613	60610	2016-11-23	11.52	5	0.20	4.18	2
42971	CA-2014-102337	SD-20485	FUR-CH-10004289	60653	2016-06-13	470.30	7	0.30	-87.34	4
42972	CA-2011-136644	SC-20575	FUR-CH-10000225	46544	2013-06-16	647.84	8	0.00	32.39	2
42973	CA-2013-105732	AG-10270	OFF-LA-10004559	68104	2015-09-14	14.40	5	0.00	7.06	2
42974	US-2012-167220	JB-15925	TEC-AC-10002018	78745	2014-12-12	22.37	4	0.20	6.43	2
42975	CA-2013-152730	EM-14140	OFF-PA-10004888	54880	2015-05-31	45.36	7	0.00	21.77	2
42976	US-2011-159618	DB-12970	FUR-BO-10004467	77036	2013-11-12	67.99	1	0.32	-13.00	2
42977	CA-2013-132731	GA-14515	TEC-PH-10004120	75081	2015-11-25	657.55	6	0.20	49.32	2
42978	US-2014-112613	JH-15910	TEC-PH-10001536	77070	2016-05-28	54.37	4	0.20	4.08	2
42979	CA-2014-122763	HG-14845	OFF-PA-10002377	77041	2016-03-20	274.06	7	0.20	102.77	3
42980	CA-2012-112522	DP-13165	OFF-AR-10003183	60610	2014-10-10	8.02	3	0.20	1.00	2
42981	CA-2012-115168	BB-11545	OFF-PA-10000528	63301	2014-06-05	10.56	2	0.00	4.75	2
42982	CA-2011-108182	DL-13315	OFF-BI-10001196	60441	2013-02-06	8.95	2	0.80	-14.77	1
42983	CA-2014-105669	SJ-20125	OFF-BI-10002412	77036	2016-09-17	5.80	5	0.80	-10.15	1
42984	CA-2013-134110	BG-11035	OFF-PA-10000697	75056	2015-11-18	15.23	4	0.20	5.52	4
42985	CA-2013-163986	JJ-15445	OFF-ST-10000918	53186	2015-09-04	54.50	5	0.00	14.17	2
42986	CA-2012-137071	ED-13885	TEC-AC-10004353	77036	2014-12-20	100.80	2	0.20	21.42	4
42987	CA-2013-121671	AA-10480	OFF-PA-10001471	65807	2015-07-18	21.93	3	0.00	10.09	2
42988	CA-2012-139731	JE-15745	FUR-CH-10002024	79109	2014-10-15	2453.43	5	0.30	-350.49	3
42989	CA-2011-124478	MA-17560	OFF-EN-10002500	48183	2013-08-08	38.34	3	0.00	17.25	2
42990	CA-2012-153717	DL-13495	OFF-AR-10002375	48227	2014-12-25	3.28	1	0.00	0.95	2
42991	US-2013-115441	SH-19975	FUR-CH-10004626	53209	2015-07-26	403.56	4	0.00	96.85	1
42992	CA-2011-115049	MM-17920	TEC-AC-10004859	60623	2013-09-26	153.82	11	0.20	38.46	2
42993	US-2013-132577	JE-15475	OFF-AR-10003481	77095	2015-11-23	23.62	9	0.20	2.66	2
42994	US-2013-110156	EH-13945	OFF-BI-10003676	77041	2015-11-20	10.78	5	0.80	-17.25	2
42995	CA-2014-110905	RW-19690	OFF-BI-10003669	65807	2016-09-10	16.20	3	0.00	7.78	1
42996	CA-2014-127264	SA-20830	OFF-AR-10003045	60653	2016-04-03	7.06	3	0.20	2.21	4
42997	CA-2012-139374	AR-10345	FUR-CH-10003981	78745	2014-09-10	179.89	1	0.30	-2.57	2
42998	CA-2011-120544	SS-20140	OFF-AP-10004336	75150	2013-11-23	34.18	3	0.80	-87.15	2
42999	CA-2013-152730	EM-14140	TEC-PH-10000441	54880	2015-05-31	125.99	1	0.00	35.28	2
43000	CA-2011-105165	SZ-20035	FUR-TA-10004154	77036	2013-09-07	200.80	1	0.30	-22.95	4
43001	US-2014-105389	DM-13015	OFF-BI-10004364	78207	2016-10-23	3.56	3	0.80	-6.24	1
43002	CA-2014-163160	TS-21610	FUR-FU-10001424	61032	2016-10-13	10.48	3	0.60	-6.81	4
43003	US-2014-136679	XP-21865	TEC-AC-10004855	77506	2016-11-14	167.95	6	0.20	-27.29	2
43004	CA-2014-122035	EM-13825	OFF-BI-10000404	57103	2016-07-20	43.00	5	0.00	20.21	2
43005	CA-2011-139017	RM-19375	TEC-AC-10001013	77095	2013-05-11	46.86	2	0.20	7.62	2
43006	US-2013-111290	DK-13375	OFF-AR-10001761	48185	2015-07-23	29.20	5	0.00	10.51	2
43007	CA-2011-130673	MC-17590	OFF-ST-10000636	78666	2013-05-20	66.96	5	0.20	-13.39	1
43008	CA-2014-116358	KM-16225	OFF-FA-10003495	66212	2016-11-02	18.24	3	0.00	9.12	2
43009	CA-2014-157350	DP-13000	FUR-FU-10000222	60610	2016-08-26	64.96	5	0.60	-43.85	2
43010	US-2011-168501	JK-15325	OFF-EN-10001509	75220	2013-11-21	1.63	1	0.20	0.55	2
43011	US-2012-123218	KD-16345	TEC-PH-10001061	60623	2014-12-20	159.98	2	0.20	12.00	2
43012	US-2012-117184	ON-18715	OFF-PA-10002250	77095	2014-05-17	14.09	3	0.20	4.93	2
43013	US-2014-119438	CD-11980	OFF-AP-10000804	75701	2016-03-18	2.69	3	0.80	-7.39	2
43014	CA-2011-120474	RP-19390	OFF-AR-10000475	53711	2013-12-01	46.64	4	0.00	12.59	4
43015	CA-2014-107629	DB-13060	FUR-FU-10004091	60076	2016-12-14	56.33	3	0.60	-26.76	3
43016	CA-2012-136105	SZ-20035	OFF-ST-10002444	47201	2014-06-12	24.56	2	0.00	6.88	2
43017	CA-2014-143063	IL-15100	FUR-FU-10003708	47201	2016-08-10	121.30	2	0.00	25.47	2
43018	CA-2013-108210	AT-10735	TEC-PH-10002293	77041	2015-05-31	79.96	5	0.20	8.00	3
43019	US-2014-117247	CK-12760	FUR-TA-10002958	60505	2016-10-09	652.45	5	0.50	-430.62	2
43020	CA-2013-119186	MS-17710	FUR-CH-10001973	76106	2015-05-27	388.43	5	0.30	-88.78	3
43021	CA-2012-117415	SN-20710	FUR-BO-10002545	77041	2014-12-27	532.40	3	0.32	-46.98	2
43022	CA-2011-103849	PG-18895	TEC-AC-10001465	76106	2013-05-11	58.11	2	0.20	7.26	2
43023	CA-2011-167997	CA-11965	FUR-BO-10004409	57701	2013-01-26	141.96	2	0.00	39.75	4
43024	CA-2014-102337	SD-20485	OFF-ST-10004804	60653	2016-06-13	164.74	4	0.20	-39.12	4
43025	CA-2013-119186	MS-17710	OFF-PA-10004621	76106	2015-05-27	10.37	2	0.20	3.63	3
43026	US-2011-106299	NZ-18565	OFF-ST-10002011	65807	2013-08-02	838.38	2	0.00	226.36	2
43027	CA-2014-166317	JE-15610	TEC-PH-10001615	53209	2016-09-22	86.97	3	0.00	25.22	2
43028	CA-2012-138009	SF-20965	FUR-CH-10004853	48126	2014-11-29	301.96	2	0.00	87.57	2
43029	CA-2012-149811	CS-12250	OFF-BI-10003676	55125	2014-01-04	32.34	3	0.00	15.52	2
43030	CA-2012-130792	RA-19915	OFF-BI-10000309	77095	2014-04-28	12.18	4	0.80	-18.87	2
43031	US-2014-147984	GB-14575	OFF-PA-10000806	67212	2016-01-29	279.90	5	0.00	137.15	2
43032	CA-2014-155880	JD-16150	FUR-CH-10004675	53209	2016-03-25	1526.56	7	0.00	427.44	2
43033	CA-2012-112214	AH-10690	OFF-ST-10001505	75220	2014-08-05	33.49	7	0.20	-1.26	2
43034	US-2013-134656	MM-18280	OFF-PA-10003039	62301	2015-09-29	99.14	4	0.20	30.98	4
43035	US-2011-112795	CR-12625	OFF-PA-10001934	49505	2013-08-23	19.44	3	0.00	9.53	1
43036	CA-2013-118689	TC-20980	TEC-CO-10004722	47905	2015-10-03	17499.95	5	0.00	8399.98	2
43037	CA-2012-112452	NC-18340	OFF-FA-10000735	48911	2014-04-04	5.84	2	0.00	2.63	3
43038	CA-2013-101693	LC-17140	FUR-CH-10001146	77070	2015-06-26	85.25	2	0.30	-6.09	1
43039	CA-2013-169838	BB-11545	OFF-BI-10004002	49201	2015-11-26	17.30	1	0.00	8.30	2
43040	CA-2011-133228	MS-17710	OFF-AR-10001955	48205	2013-04-04	79.36	4	0.00	23.81	2
43041	CA-2013-121671	AA-10480	OFF-ST-10002344	65807	2015-07-18	242.94	3	0.00	4.86	2
43042	CA-2014-106103	SC-20305	TEC-AC-10003832	48307	2016-06-10	132.52	4	0.00	54.33	2
43043	CA-2011-118339	BN-11515	OFF-AP-10001154	55044	2013-03-17	93.78	2	0.00	36.57	2
43044	CA-2013-119935	KM-16225	OFF-BI-10001597	65807	2015-11-11	81.96	2	0.00	39.34	2
43045	CA-2012-118738	AG-10495	OFF-PA-10001166	77041	2014-10-24	10.37	2	0.20	3.63	2
43046	US-2011-159618	DB-12970	OFF-SU-10000432	77036	2013-11-12	16.66	6	0.20	-3.12	2
43047	CA-2014-121790	LP-17095	OFF-SU-10004231	60505	2016-01-31	31.68	4	0.20	2.77	2
43048	CA-2012-135622	TT-21460	TEC-PH-10001817	76106	2014-12-08	1718.40	6	0.20	150.36	1
43049	CA-2012-116687	NC-18625	TEC-PH-10001750	77095	2014-05-02	158.38	3	0.20	13.86	2
43050	CA-2012-110877	JE-15715	OFF-PA-10004621	77041	2014-10-23	36.29	7	0.20	12.70	4
43051	CA-2011-104773	TB-21175	OFF-ST-10000777	77041	2013-12-08	60.42	2	0.20	6.04	2
43052	CA-2013-128916	MA-17560	FUR-FU-10001940	77070	2015-08-19	9.55	3	0.60	-3.82	1
43053	CA-2013-152730	EM-14140	FUR-FU-10001037	54880	2015-05-31	47.40	5	0.00	21.33	2
43054	CA-2014-117443	JB-15400	OFF-BI-10004002	61107	2016-12-23	13.84	4	0.80	-22.14	1
43055	US-2013-140172	SP-20650	OFF-AR-10002766	49201	2015-03-09	13.90	5	0.00	3.75	2
43056	CA-2011-127166	KH-16360	OFF-EN-10003134	77070	2013-05-21	56.06	6	0.20	21.02	1
43057	US-2014-118038	KB-16600	OFF-ST-10000615	77041	2016-12-09	27.24	3	0.20	2.72	4
43058	US-2013-141264	CT-11995	OFF-AP-10002534	75061	2015-08-14	58.92	1	0.80	-153.20	2
43059	CA-2014-122035	EM-13825	OFF-BI-10002072	57103	2016-07-20	60.83	7	0.00	30.42	2
43060	CA-2014-146269	MH-17455	OFF-AR-10004790	60623	2016-10-06	19.15	2	0.20	1.20	3
43061	CA-2012-110324	MA-17560	OFF-AR-10000823	49201	2014-12-01	3.64	2	0.00	1.02	2
43062	CA-2011-100678	KM-16720	OFF-AR-10001868	77095	2013-04-18	2.69	2	0.20	1.01	2
43063	CA-2011-100678	KM-16720	OFF-EN-10000056	77095	2013-04-18	149.35	3	0.20	50.41	2
43064	US-2014-169502	MG-17650	OFF-SU-10004115	53209	2016-08-28	21.81	3	0.00	5.89	2
43065	CA-2014-149048	BM-11650	OFF-PA-10001752	47201	2016-05-13	14.94	3	0.00	7.32	2
43066	CA-2013-119963	SN-20710	OFF-PA-10001970	77506	2015-11-19	19.65	2	0.20	6.63	2
43067	US-2013-117037	LW-17215	OFF-FA-10000936	60653	2015-05-18	7.90	3	0.20	2.47	4
43068	CA-2014-131016	DC-12850	OFF-AR-10000122	76017	2016-09-18	8.93	2	0.20	0.56	4
43069	CA-2012-149909	RA-19915	OFF-PA-10000726	47201	2014-11-13	63.77	7	0.00	28.70	2
43070	CA-2014-110821	CK-12205	OFF-ST-10002790	75081	2016-08-07	118.16	2	0.20	-25.11	4
43071	CA-2013-105207	BO-11350	FUR-TA-10000617	74012	2015-01-03	1592.85	7	0.00	350.43	2
43072	CA-2014-156622	JP-15460	OFF-BI-10003707	75220	2016-11-23	6.10	2	0.80	-9.16	4
43073	CA-2014-145884	SL-20155	TEC-PH-10000895	74403	2016-10-21	1439.92	8	0.00	374.38	3
43074	CA-2011-169019	LF-17185	OFF-AP-10003281	78207	2013-07-26	4.84	2	0.80	-12.09	2
43075	CA-2013-128531	NS-18505	OFF-AR-10003405	75217	2015-11-25	14.04	3	0.20	1.58	1
43076	CA-2011-143903	KM-16375	FUR-FU-10003724	75217	2013-07-20	16.74	5	0.60	-14.23	2
43077	CA-2011-105165	SZ-20035	TEC-AC-10002718	77036	2013-09-07	46.69	4	0.20	-2.92	4
43078	US-2014-152380	JH-15910	FUR-TA-10002533	60623	2016-11-19	219.08	3	0.50	-131.45	2
43079	CA-2012-129392	DM-13015	OFF-PA-10004248	77070	2014-07-08	21.12	5	0.20	6.60	3
43080	US-2014-160836	CC-12475	OFF-AP-10001626	77070	2016-09-11	1.56	2	0.80	-4.20	2
43081	CA-2013-128531	NS-18505	TEC-AC-10002049	75217	2015-11-25	297.58	3	0.20	-7.44	1
43082	CA-2014-121580	ML-17410	OFF-PA-10004082	47201	2016-05-29	7.98	1	0.00	3.99	2
43083	CA-2011-103492	CM-12715	TEC-PH-10001128	77340	2013-10-10	719.95	6	0.20	72.00	2
43084	CA-2014-127026	MH-18115	TEC-MA-10002981	49201	2016-01-22	350.97	3	0.10	152.09	2
43085	US-2011-161305	SB-20170	OFF-BI-10002794	60623	2013-06-06	24.59	3	0.80	-38.11	2
43086	CA-2011-133753	CW-11905	TEC-PH-10000376	77340	2013-06-09	7.99	1	0.20	0.60	1
43087	CA-2014-140802	KN-16390	OFF-PA-10001534	77070	2016-04-21	20.74	4	0.20	7.26	4
43088	CA-2014-112536	SG-20890	OFF-BI-10003712	78501	2016-05-18	6.87	7	0.80	-10.65	2
43089	CA-2012-126557	RL-19615	TEC-PH-10000526	60610	2014-07-12	537.54	7	0.20	53.75	1
43090	CA-2012-126557	RL-19615	TEC-PH-10003505	60610	2014-07-12	148.48	2	0.20	16.70	1
43091	CA-2011-116904	SC-20095	OFF-PA-10004888	55407	2013-09-23	32.40	5	0.00	15.55	2
43092	CA-2014-155642	BM-11575	FUR-FU-10004973	60653	2016-05-18	22.61	3	0.60	-10.17	2
43093	CA-2014-157420	HZ-14950	TEC-PH-10003555	77095	2016-11-21	55.18	3	0.20	-12.41	3
43094	US-2014-106579	BW-11200	OFF-BI-10000309	60076	2016-06-08	12.18	4	0.80	-18.87	2
43095	US-2012-163433	MP-17965	TEC-PH-10003357	78501	2014-04-18	244.77	4	0.20	24.48	1
43096	CA-2013-111143	TT-21265	OFF-AP-10001947	46203	2015-11-20	54.96	3	0.00	15.94	4
43097	CA-2012-143147	PS-18760	FUR-CH-10004754	78207	2014-05-26	104.93	5	0.30	-4.50	1
43098	CA-2014-117401	PP-18955	TEC-PH-10003555	65807	2016-05-18	114.95	5	0.00	2.30	1
43099	CA-2013-154018	HA-14920	OFF-BI-10004140	78041	2015-10-14	6.29	7	0.80	-11.00	2
43100	CA-2012-136728	AG-10900	FUR-CH-10003817	60623	2014-09-13	170.07	4	0.30	-12.15	1
43101	CA-2012-113901	NH-18610	TEC-PH-10002564	48227	2014-10-19	149.95	5	0.00	44.99	2
43102	CA-2013-169922	MZ-17515	OFF-BI-10003784	76017	2015-06-12	1.34	4	0.80	-2.15	2
43103	CA-2012-120901	BG-11035	OFF-ST-10000025	78745	2014-12-31	152.69	2	0.20	-26.72	2
43104	CA-2014-111332	NC-18340	OFF-FA-10001843	58103	2016-05-20	7.41	3	0.00	3.48	1
43105	CA-2014-152660	CB-12415	OFF-ST-10000532	60610	2016-12-04	61.57	2	0.20	4.62	2
43106	CA-2014-126074	RF-19735	OFF-AR-10003478	48183	2016-10-02	56.98	7	0.00	22.79	2
43107	US-2012-132836	AJ-10945	TEC-PH-10001300	48227	2014-06-01	41.90	2	0.00	11.73	2
43108	CA-2014-146269	MH-17455	OFF-ST-10003208	60623	2016-10-06	290.34	2	0.20	32.66	3
43109	CA-2012-160472	RK-19300	OFF-PA-10003129	46614	2014-07-20	97.82	2	0.00	45.98	1
43110	CA-2014-141733	RW-19540	FUR-CH-10004086	48234	2016-05-07	1458.65	5	0.00	423.01	2
43111	CA-2012-117415	SN-20710	OFF-EN-10002986	77041	2014-12-27	113.33	9	0.20	35.42	2
43112	CA-2013-169922	MZ-17515	OFF-BI-10001617	76017	2015-06-12	8.27	4	0.80	-13.65	2
43113	CA-2013-128706	DW-13540	FUR-FU-10004053	77070	2015-02-27	16.19	2	0.60	-6.88	2
43114	CA-2011-121006	SC-20020	FUR-CH-10004997	48640	2013-11-10	563.94	3	0.00	112.79	2
43115	CA-2012-135391	FA-14230	FUR-FU-10001986	78207	2014-02-09	40.78	2	0.60	-30.59	1
43116	CA-2014-141439	TT-21460	TEC-PH-10001819	47374	2016-11-26	89.98	2	0.00	43.19	2
43117	US-2011-154655	BP-11050	OFF-SU-10000898	60623	2013-10-12	22.24	2	0.20	2.50	2
43118	CA-2012-157322	RH-19600	OFF-ST-10004507	60188	2014-07-02	68.60	5	0.20	6.00	2
43119	CA-2014-111815	EP-13915	FUR-CH-10000785	48127	2016-03-03	180.98	1	0.00	47.05	2
43120	US-2013-100461	JO-15145	OFF-BI-10001460	53132	2015-01-08	106.05	7	0.00	49.84	2
43121	CA-2014-106068	RB-19330	OFF-ST-10002344	78745	2016-10-23	259.14	4	0.20	-58.31	2
43122	CA-2014-147207	TS-21655	OFF-AP-10000027	79907	2016-01-03	5.43	2	0.80	-13.58	1
43123	US-2011-115987	LH-17020	OFF-BI-10001071	75701	2013-09-08	51.18	4	0.80	-79.34	1
43124	CA-2014-140326	HW-14935	OFF-AR-10001149	60653	2016-09-04	6.91	3	0.20	0.86	4
43125	CA-2012-123456	KN-16450	OFF-AP-10002684	75220	2014-07-09	48.63	2	0.80	-121.58	2
43126	CA-2013-115756	PK-19075	OFF-PA-10002222	48227	2015-09-06	91.36	4	0.00	42.03	1
43127	CA-2013-165484	HK-14890	FUR-FU-10001196	60610	2015-10-24	16.16	7	0.60	-12.12	2
43128	CA-2012-130183	PO-18850	FUR-BO-10001811	77041	2014-11-13	614.00	3	0.32	-18.06	2
43129	CA-2011-137092	LS-16975	OFF-BI-10000632	60653	2013-10-20	8.68	1	0.80	-14.76	1
43130	CA-2013-104311	AS-10090	OFF-LA-10000973	75061	2015-05-03	5.04	2	0.20	1.76	2
43131	CA-2012-110863	AA-10645	OFF-ST-10002756	73120	2014-11-17	541.24	4	0.00	5.41	2
43132	CA-2013-116799	JG-15310	OFF-PA-10001892	79762	2015-03-04	42.78	7	0.20	15.51	4
43133	CA-2012-153108	SF-20200	OFF-AP-10002222	47362	2014-03-05	60.69	7	0.00	16.39	2
43134	CA-2013-101693	LC-17140	FUR-FU-10003919	77070	2015-06-26	32.71	2	0.60	-26.17	1
43135	CA-2014-151750	JM-15250	FUR-FU-10002116	77340	2016-01-02	141.42	5	0.60	-187.38	2
43136	US-2014-107384	TP-21130	TEC-AC-10004595	55901	2016-12-04	142.80	1	0.00	29.99	2
43137	US-2013-105452	BF-11005	FUR-FU-10003806	77506	2015-07-29	302.72	5	0.60	-378.40	2
43138	CA-2014-140242	ML-17755	OFF-AR-10004752	60623	2016-05-06	6.41	3	0.20	0.64	2
43139	US-2014-136679	XP-21865	OFF-AR-10003582	77506	2016-11-14	45.04	2	0.20	4.50	2
43140	CA-2014-145877	AS-10090	OFF-EN-10001990	65807	2016-04-01	28.40	5	0.00	13.35	1
43141	CA-2014-163160	TS-21610	OFF-PA-10003127	61032	2016-10-13	63.31	3	0.20	20.58	4
43142	CA-2014-146024	SC-20770	OFF-SU-10001935	75081	2016-03-02	6.98	4	0.20	-1.40	2
43143	CA-2013-156685	SC-20230	OFF-AR-10000588	76017	2015-07-09	47.62	3	0.20	3.57	1
43144	CA-2013-115483	JS-15880	OFF-PA-10001497	75061	2015-07-15	219.84	5	0.20	79.69	1
43145	CA-2012-117415	SN-20710	FUR-CH-10004218	77041	2014-12-27	212.06	3	0.30	-15.15	2
43146	CA-2014-150504	HG-14845	OFF-ST-10000615	75220	2016-11-06	18.16	2	0.20	1.82	2
43147	CA-2014-163006	GH-14410	TEC-PH-10002584	60653	2016-06-30	1001.58	2	0.20	125.20	1
43148	US-2013-144057	CV-12805	OFF-BI-10002353	78745	2015-05-10	18.53	6	0.80	-27.79	2
43149	US-2013-156097	EH-14125	OFF-BI-10004654	60505	2015-09-20	2.31	2	0.80	-3.46	3
43150	US-2011-134614	PF-19165	FUR-TA-10004534	61701	2013-09-20	617.70	6	0.50	-407.68	2
43151	CA-2014-159149	CR-12820	TEC-PH-10000038	77041	2016-02-18	438.34	4	0.20	-87.67	4
43152	CA-2013-100041	BF-10975	OFF-BI-10000343	47201	2015-11-21	4.91	1	0.00	2.31	2
43153	CA-2014-155880	JD-16150	FUR-CH-10002880	53209	2016-03-25	368.97	3	0.00	40.59	2
43154	US-2014-130953	RF-19735	FUR-CH-10004626	73120	2016-07-29	302.67	3	0.00	72.64	2
43155	CA-2012-103954	HR-14770	FUR-BO-10004690	53209	2014-08-09	687.40	5	0.00	48.12	1
43156	CA-2011-120544	SS-20140	FUR-FU-10001940	75150	2013-11-23	6.37	2	0.60	-2.55	2
43157	CA-2013-166373	JF-15565	TEC-AC-10002323	78207	2015-10-22	106.08	6	0.20	-9.28	2
43158	CA-2012-134747	DL-12925	OFF-BI-10001308	46060	2014-10-12	12.56	2	0.00	5.65	1
43159	CA-2013-125220	BE-11410	TEC-AC-10003033	54915	2015-10-15	1649.75	5	0.00	544.42	2
43160	CA-2013-115756	PK-19075	OFF-LA-10001317	48227	2015-09-06	22.05	7	0.00	10.58	1
43161	US-2014-105389	DM-13015	TEC-PH-10002824	78207	2016-10-23	823.96	5	0.20	51.50	1
43162	CA-2011-142510	NP-18700	OFF-PA-10001289	60623	2013-12-22	124.03	4	0.20	44.96	2
43163	CA-2014-154732	AH-10195	OFF-BI-10000474	60623	2016-11-05	16.03	5	0.80	-25.65	4
43164	CA-2013-122903	LA-16780	FUR-CH-10002024	48205	2015-05-28	3504.90	5	0.00	700.98	1
43165	CA-2012-126557	RL-19615	FUR-FU-10001861	60610	2014-07-12	7.76	1	0.60	-2.13	1
43166	CA-2013-120824	AW-10930	OFF-AP-10001242	77070	2015-06-13	64.38	4	0.80	-160.96	1
43167	CA-2014-127922	SH-19975	OFF-PA-10001204	75081	2016-10-27	8.45	2	0.20	2.64	2
43168	US-2014-118038	KB-16600	FUR-FU-10000260	77041	2016-12-09	9.71	3	0.60	-5.82	4
43169	CA-2012-168186	AB-10150	OFF-PA-10000477	74133	2014-09-10	14.94	3	0.00	7.02	2
43170	CA-2013-150889	PB-19105	TEC-PH-10000004	60201	2015-03-21	11.99	1	0.20	0.90	1
43171	CA-2013-158806	NM-18520	FUR-FU-10004270	79109	2015-01-07	23.08	3	0.60	-10.96	2
43172	CA-2011-143903	KM-16375	FUR-CH-10002024	75217	2013-07-20	981.37	2	0.30	-140.20	2
43173	CA-2012-126697	SV-20815	FUR-FU-10001706	77041	2014-09-21	4.93	4	0.60	-1.48	4
43174	CA-2014-152933	MG-17650	TEC-PH-10002085	75081	2016-10-12	369.54	7	0.20	27.72	2
43175	CA-2012-140221	MS-17365	FUR-FU-10000023	60653	2014-03-05	4.71	2	0.60	-1.88	1
43176	CA-2014-122035	EM-13825	OFF-AP-10002118	57103	2016-07-20	416.32	2	0.00	112.41	2
43177	CA-2011-166863	SC-20020	OFF-ST-10004123	75023	2013-06-20	509.49	7	0.20	-127.37	2
43178	CA-2012-110016	BT-11395	FUR-CH-10002880	48227	2014-11-29	1106.91	9	0.00	121.76	2
43179	CA-2013-112256	CK-12205	OFF-BI-10004364	78501	2015-07-24	4.75	4	0.80	-8.32	2
43180	CA-2011-100678	KM-16720	TEC-AC-10000474	77095	2013-04-18	227.98	3	0.20	28.50	2
43181	CA-2014-121580	ML-17410	OFF-AP-10001564	47201	2016-05-29	465.16	2	0.00	120.94	2
43182	CA-2014-139199	DK-12835	OFF-BI-10003982	48234	2016-12-09	41.54	2	0.00	19.52	2
43183	US-2011-140914	BH-11710	FUR-FU-10000175	60653	2013-11-11	10.98	2	0.60	-7.96	2
43184	CA-2013-114601	AA-10480	OFF-PA-10000605	48234	2015-08-27	11.56	2	0.00	5.66	2
43185	CA-2012-146290	SV-20815	OFF-AR-10001897	46203	2014-05-04	125.93	7	0.00	35.26	2
43186	CA-2011-163748	HG-15025	TEC-CO-10002095	76106	2013-10-14	1999.96	5	0.20	624.99	2
43187	CA-2011-131002	TB-21400	OFF-BI-10000948	74133	2013-09-07	42.81	3	0.00	20.12	1
43188	CA-2014-129000	SZ-20035	OFF-ST-10001097	48187	2016-11-25	501.81	3	0.00	0.00	1
43189	US-2013-164196	AS-10285	FUR-TA-10001950	46060	2015-11-12	2678.94	6	0.00	241.10	2
43190	CA-2012-103205	JJ-15760	TEC-PH-10004896	77036	2014-12-08	119.96	5	0.20	12.00	1
43191	CA-2014-121195	NS-18505	OFF-ST-10000585	75220	2016-12-24	264.32	2	0.20	19.82	4
43192	CA-2014-122077	JF-15295	OFF-LA-10004178	75023	2016-05-19	13.22	4	0.20	4.30	2
43193	US-2011-143721	DK-12835	FUR-CH-10001973	77095	2013-11-23	155.37	2	0.30	-35.51	1
43194	CA-2012-168277	KB-16315	OFF-LA-10004484	46203	2014-05-29	12.39	3	0.00	5.70	2
43195	CA-2014-154466	DP-13390	OFF-BI-10002012	53132	2016-01-02	3.60	2	0.00	1.73	4
43196	CA-2012-111948	AG-10495	OFF-AP-10002311	48234	2014-11-11	123.86	2	0.10	46.79	3
43197	CA-2011-152618	RB-19465	TEC-MA-10003626	60653	2013-03-14	574.91	2	0.30	156.05	4
43198	US-2012-100531	NM-18520	OFF-BI-10001670	60610	2014-09-27	15.08	2	0.80	-22.62	4
43199	CA-2014-103478	KL-16555	OFF-BI-10004224	60505	2016-07-21	94.19	7	0.80	-164.84	1
43200	CA-2012-119690	MV-17485	OFF-PA-10001019	77041	2014-06-25	47.95	3	0.20	16.18	4
43201	CA-2013-146157	RD-19720	OFF-PA-10001790	60610	2015-11-22	38.43	1	0.20	13.45	2
43202	US-2013-131149	LH-17155	OFF-ST-10000689	75081	2015-07-11	338.04	3	0.20	-33.80	2
43203	CA-2014-149160	JM-15265	FUR-FU-10003347	48187	2016-11-23	28.40	2	0.00	11.08	1
43204	CA-2014-157966	SU-20665	OFF-AR-10000799	60610	2016-03-13	19.46	4	0.20	2.19	3
43205	CA-2013-117408	TP-21130	OFF-ST-10001580	76706	2015-09-01	23.97	2	0.20	2.40	2
43206	CA-2013-158617	AC-10660	OFF-PA-10002245	46226	2015-09-23	35.88	6	0.00	16.15	2
43207	CA-2012-133585	CM-12715	OFF-AR-10003696	77070	2014-03-01	55.33	2	0.20	6.22	4
43208	CA-2011-166590	NC-18625	TEC-AC-10003433	47201	2013-10-29	1.98	2	0.00	0.89	2
43209	CA-2013-144540	GH-14410	OFF-FA-10002763	77070	2015-09-06	28.44	9	0.20	4.27	2
43210	US-2013-133879	KT-16465	OFF-AR-10004956	60623	2015-03-22	13.39	3	0.20	1.51	2
43211	US-2011-120236	MR-17545	OFF-BI-10004099	77095	2013-09-03	7.68	5	0.80	-11.52	4
43212	CA-2013-136812	AW-10930	OFF-ST-10003470	73120	2015-11-19	1117.92	4	0.00	55.90	2
43213	CA-2011-121006	SC-20020	OFF-ST-10001490	48640	2013-11-10	535.41	3	0.00	160.62	2
43214	CA-2011-169649	TS-21205	OFF-AP-10003287	60653	2013-12-09	20.39	2	0.80	-53.01	2
43215	US-2014-148362	KF-16285	OFF-ST-10001128	46203	2016-07-01	443.92	4	0.00	13.32	2
43216	CA-2013-107790	EH-13990	TEC-PH-10004539	77041	2015-11-21	151.19	1	0.20	13.23	2
43217	US-2014-101721	MY-17380	OFF-PA-10003641	60623	2016-07-23	63.31	3	0.20	20.58	2
43218	CA-2012-118738	AG-10495	OFF-PA-10003177	77041	2014-10-24	15.55	3	0.20	5.44	2
43219	CA-2012-120782	SD-20485	OFF-BI-10003527	48640	2014-04-28	3812.97	3	0.00	1906.49	4
43220	US-2011-127635	SC-20260	OFF-BI-10001721	78415	2013-09-14	8.55	2	0.80	-13.68	1
43221	US-2013-110156	EH-13945	OFF-EN-10003798	77041	2015-11-20	40.97	3	0.20	13.83	2
43222	CA-2013-117590	GH-14485	FUR-FU-10003664	75080	2015-12-09	190.92	5	0.60	-147.96	4
43223	CA-2014-134194	GA-14725	OFF-BI-10003684	75081	2016-12-25	39.58	9	0.80	-59.37	2
43224	CA-2014-160927	TM-21010	OFF-PA-10003848	52302	2016-01-30	12.96	2	0.00	6.22	1
43225	CA-2014-107825	NB-18655	FUR-FU-10000206	53209	2016-11-18	5.82	2	0.00	2.74	3
43226	CA-2011-169019	LF-17185	TEC-AC-10002076	78207	2013-07-26	431.14	9	0.20	-26.95	2
43227	CA-2011-131926	DW-13480	OFF-AP-10002945	55044	2013-06-01	1503.25	5	0.00	496.07	1
43228	CA-2013-152730	EM-14140	OFF-PA-10000994	54880	2015-05-31	629.10	6	0.00	301.97	2
43229	CA-2011-100678	KM-16720	FUR-CH-10002602	77095	2013-04-18	317.06	3	0.30	-18.12	2
43230	CA-2014-125269	AF-10870	OFF-ST-10004123	60610	2016-04-24	72.78	1	0.20	-18.20	2
43231	CA-2013-105732	AG-10270	TEC-PH-10001644	68104	2015-09-14	149.95	5	0.00	41.99	2
43232	CA-2013-100153	KH-16630	TEC-AC-10001772	73071	2015-12-14	63.88	4	0.00	24.91	2
43233	CA-2011-131009	SC-20380	FUR-FU-10001095	79907	2013-03-01	63.55	6	0.60	-34.95	2
43234	CA-2014-133256	TH-21550	OFF-AR-10003158	48227	2016-06-26	15.92	4	0.00	5.41	4
43235	CA-2013-112025	LS-16975	OFF-BI-10002353	77070	2015-07-31	9.26	3	0.80	-13.90	2
43236	CA-2013-169922	MZ-17515	FUR-FU-10004415	76017	2015-06-12	12.54	7	0.60	-9.09	2
43237	CA-2014-158673	KB-16600	OFF-PA-10000994	49505	2016-12-29	209.70	2	0.00	100.66	2
43238	CA-2011-166863	SC-20020	TEC-PH-10000369	75023	2013-06-20	201.58	2	0.20	20.16	2
43239	US-2011-157847	SC-20020	OFF-PA-10002986	77095	2013-04-02	26.72	5	0.20	9.35	1
43240	CA-2014-134194	GA-14725	OFF-AR-10001615	75081	2016-12-25	31.74	2	0.20	2.38	2
43241	CA-2011-119172	HD-14785	OFF-PA-10003036	60610	2013-05-11	17.47	3	0.20	5.68	2
43242	US-2013-131611	EP-13915	FUR-BO-10000780	77036	2015-11-06	956.66	7	0.32	-225.10	2
43243	CA-2014-111262	KH-16510	TEC-AC-10004510	77095	2016-10-28	26.18	2	0.20	-3.27	1
43244	US-2011-127635	SC-20260	OFF-PA-10004610	78415	2013-09-14	6.85	2	0.20	2.14	1
43245	US-2013-157840	MC-17575	OFF-PA-10003673	68025	2015-12-21	33.90	5	0.00	15.59	1
43246	CA-2012-118955	LS-17230	FUR-CH-10001708	75051	2014-06-16	197.37	2	0.30	-25.38	2
43247	CA-2012-153612	BT-11305	OFF-AR-10000203	54880	2014-12-22	17.12	4	0.00	4.96	2
43248	CA-2012-142433	ES-14020	OFF-PA-10002377	77036	2014-04-20	117.46	3	0.20	44.05	2
43249	CA-2011-118276	MG-17890	FUR-FU-10002111	60174	2013-12-29	8.74	3	0.60	-4.80	2
43250	CA-2014-102519	BM-11650	TEC-AC-10001772	53209	2016-11-27	143.73	9	0.00	56.05	4
43251	CA-2012-106208	JW-16075	OFF-AP-10004980	60610	2014-12-10	53.09	7	0.80	-108.83	2
43252	US-2011-147606	JE-15745	FUR-FU-10003194	77070	2013-11-26	19.30	5	0.60	-14.48	1
43253	US-2011-107699	JH-15820	OFF-BI-10001249	48640	2013-05-19	57.42	9	0.00	26.41	2
43254	CA-2011-124646	DV-13465	OFF-ST-10001097	55407	2013-06-22	501.81	3	0.00	0.00	4
43255	US-2013-117037	LW-17215	FUR-FU-10004973	60653	2015-05-18	22.61	3	0.60	-10.17	4
43256	US-2012-159982	DR-12880	FUR-FU-10002505	60623	2014-11-28	12.13	9	0.60	-8.49	2
43257	CA-2011-149104	RD-19900	OFF-AR-10004685	48127	2013-04-05	13.89	3	0.00	4.58	1
43258	CA-2014-142125	JB-15400	OFF-BI-10000301	53209	2016-10-21	38.82	6	0.00	19.41	2
43259	US-2013-110156	EH-13945	TEC-PH-10003589	77041	2015-11-20	71.96	5	0.20	25.19	2
43260	CA-2013-117919	TB-21355	OFF-ST-10003572	77041	2015-08-28	14.16	1	0.20	1.06	1
43261	CA-2012-121783	PO-19180	OFF-ST-10000078	55113	2014-11-10	795.51	3	0.00	143.19	2
43262	CA-2013-143406	LR-17035	FUR-CH-10000513	77041	2015-09-27	454.97	5	0.30	-136.49	2
43263	CA-2011-166590	NC-18625	OFF-PA-10000482	47201	2013-10-29	75.88	2	0.00	35.66	2
43264	US-2014-141677	HK-14890	OFF-ST-10000344	77070	2016-03-26	32.23	3	0.20	2.42	2
43265	CA-2011-124723	GZ-14470	FUR-TA-10001307	77590	2013-08-05	489.23	2	0.30	41.93	2
43266	US-2014-105389	DM-13015	OFF-AR-10000634	78207	2016-10-23	10.27	3	0.20	0.90	1
43267	CA-2013-118101	SN-20560	OFF-BI-10000773	48066	2015-06-27	8.02	1	0.00	3.77	3
43268	CA-2011-100762	NG-18355	OFF-PA-10004082	49201	2013-11-24	15.96	2	0.00	7.98	2
43269	CA-2011-169019	LF-17185	FUR-FU-10004666	78207	2013-07-26	17.50	3	0.60	-10.06	2
43270	CA-2013-126627	WB-21850	OFF-BI-10001597	77571	2015-10-11	16.39	2	0.80	-26.23	4
43271	CA-2013-145240	BG-11740	OFF-ST-10001590	77070	2015-09-07	10.78	1	0.20	0.81	4
43272	CA-2011-122609	DP-13000	TEC-AC-10002567	75007	2013-11-12	127.98	2	0.20	25.60	2
43273	CA-2011-124394	TB-21520	TEC-AC-10001314	77705	2013-10-17	119.98	3	0.20	-18.00	1
43274	CA-2013-129686	GG-14650	OFF-ST-10004337	60623	2015-11-28	97.98	2	0.20	-24.50	1
43275	CA-2013-158568	RB-19465	OFF-PA-10003256	60610	2015-08-30	64.62	7	0.20	22.62	2
43276	CA-2013-130400	SJ-20125	OFF-BI-10001757	75217	2015-03-09	8.86	9	0.80	-14.17	2
43277	US-2014-118038	KB-16600	OFF-BI-10004182	77041	2016-12-09	1.25	3	0.80	-1.93	4
43278	CA-2013-148698	BD-11770	OFF-AR-10004022	77070	2015-05-03	86.35	3	0.20	5.40	2
43279	CA-2013-114489	JE-16165	FUR-CH-10000454	53132	2015-12-06	1951.84	8	0.00	585.55	2
43280	CA-2014-100615	SJ-20215	FUR-FU-10002456	60653	2016-04-20	14.56	5	0.60	-6.19	2
43281	CA-2014-100615	SJ-20215	OFF-AR-10001683	60653	2016-04-20	15.76	2	0.20	3.55	2
43282	US-2014-156356	ND-18370	OFF-BI-10001107	77095	2016-04-16	2.90	1	0.80	-4.78	2
43283	CA-2014-159604	CL-12700	OFF-BI-10003460	65807	2016-04-14	8.76	2	0.00	4.20	4
43284	CA-2012-153381	DE-13255	OFF-BI-10001525	52001	2014-09-24	15.24	4	0.00	6.86	2
43285	CA-2012-142377	MS-17980	OFF-PA-10001970	65807	2014-12-04	85.96	7	0.00	40.40	2
43286	US-2014-147221	JS-16030	OFF-AP-10002534	77036	2016-12-02	294.62	5	0.80	-766.01	1
43287	CA-2014-147039	AA-10315	OFF-BI-10004654	55407	2016-06-29	11.54	2	0.00	5.77	2
43288	CA-2014-103520	MH-17785	OFF-PA-10001846	79424	2016-09-23	9.25	2	0.20	3.35	4
43289	US-2013-157945	NF-18385	OFF-EN-10001415	62521	2015-09-27	8.93	2	0.20	3.35	2
43290	CA-2013-154235	RD-19900	FUR-FU-10004006	47401	2015-09-25	127.95	3	0.00	21.75	2
43291	US-2014-132206	MK-17905	OFF-BI-10000756	60653	2016-06-16	5.94	7	0.80	-8.90	2
43292	CA-2012-112214	AH-10690	OFF-SU-10003567	75220	2014-08-05	23.04	3	0.20	-4.90	2
43293	CA-2014-142776	RS-19870	OFF-BI-10002012	52601	2016-12-11	5.40	3	0.00	2.59	1
43294	CA-2014-114258	EM-13825	TEC-PH-10003012	75081	2016-11-05	492.77	4	0.20	55.44	1
43295	CA-2013-155551	CR-12580	OFF-PA-10001560	60126	2015-04-19	9.66	2	0.20	3.26	2
43296	CA-2012-112214	AH-10690	OFF-BI-10002982	75220	2014-08-05	1.36	1	0.80	-2.18	2
43297	CA-2013-128671	MT-18070	OFF-PA-10001870	74133	2015-08-12	32.40	5	0.00	15.55	2
43298	CA-2014-143217	CG-12040	OFF-BI-10002949	53209	2016-11-11	18.24	3	0.00	8.57	2
43299	CA-2013-155005	SC-20050	TEC-PH-10003484	49201	2015-06-14	377.97	3	0.00	94.49	1
43300	CA-2014-113873	KE-16420	OFF-ST-10000943	75220	2016-11-13	61.79	4	0.20	6.18	2
43301	CA-2014-162481	CT-11995	OFF-BI-10002976	55901	2016-09-25	8.26	2	0.00	3.88	2
43302	CA-2014-144036	FO-14305	OFF-AR-10000122	77070	2016-11-22	35.71	8	0.20	2.23	2
43303	US-2013-144057	CV-12805	OFF-ST-10001490	78745	2015-05-10	856.66	6	0.20	107.08	2
43304	CA-2014-130526	GT-14755	OFF-BI-10001524	61107	2016-11-26	33.57	8	0.80	-53.71	4
43305	CA-2013-109057	TT-21460	OFF-ST-10002406	60505	2015-04-23	23.95	2	0.20	2.40	2
43306	CA-2014-149720	EM-14065	FUR-FU-10002501	75034	2016-06-04	30.34	6	0.60	-17.44	1
43307	US-2013-144057	CV-12805	OFF-PA-10004327	78745	2015-05-10	76.64	2	0.20	26.82	2
43308	CA-2013-162082	JS-15880	OFF-PA-10001934	78550	2015-03-15	5.18	1	0.20	1.88	4
43309	CA-2012-163734	KM-16375	OFF-ST-10003692	77070	2014-06-19	228.92	5	0.20	14.31	2
43310	CA-2013-159940	BF-11020	OFF-FA-10000936	60505	2015-07-08	2.63	1	0.20	0.82	1
43311	CA-2012-113173	DK-13225	OFF-ST-10000604	60653	2014-11-15	250.27	9	0.20	15.64	1
43312	US-2014-124779	BF-11020	FUR-FU-10001095	76017	2016-09-08	21.18	2	0.60	-11.65	4
43313	CA-2013-160108	AG-10900	FUR-CH-10002335	54703	2015-12-09	680.01	3	0.00	176.80	2
43314	CA-2014-127621	RE-19450	OFF-PA-10001307	75081	2016-03-03	26.88	8	0.20	9.74	2
43315	CA-2014-107342	VF-21715	OFF-PA-10001745	47201	2016-12-17	28.16	4	0.00	13.24	2
43316	CA-2014-142034	KB-16240	TEC-AC-10000990	56301	2016-09-24	655.90	5	0.00	275.48	2
43317	CA-2013-119963	SN-20710	FUR-CH-10003817	77506	2015-11-19	255.11	6	0.30	-18.22	2
43318	CA-2014-159506	JR-16210	OFF-BI-10004519	47201	2016-11-27	497.94	3	0.00	224.07	2
43319	US-2013-103646	SP-20545	OFF-ST-10000563	60623	2015-04-22	102.34	4	0.20	-12.79	2
43320	CA-2012-157133	LC-16885	FUR-FU-10004904	61821	2014-11-28	151.96	5	0.60	-182.35	2
43321	CA-2012-145394	MC-17605	OFF-ST-10000344	60610	2014-11-16	21.49	2	0.20	1.61	2
43322	CA-2014-148642	DW-13540	OFF-LA-10000134	75220	2016-03-06	4.93	2	0.20	1.72	2
43323	CA-2014-105543	BG-11695	OFF-ST-10003123	67846	2016-11-24	33.29	1	0.00	7.99	3
43324	CA-2013-105207	BO-11350	OFF-BI-10004364	74012	2015-01-03	11.88	2	0.00	5.35	2
43325	CA-2014-127474	RD-19810	OFF-PA-10001033	60610	2016-02-04	65.58	2	0.20	23.77	1
43326	CA-2014-104927	AG-10330	OFF-PA-10000019	77095	2016-12-22	25.92	5	0.20	9.07	2
43327	CA-2011-168368	GA-14725	FUR-FU-10002298	65203	2013-02-11	332.94	3	0.00	53.27	1
43328	CA-2013-157000	AM-10360	OFF-ST-10001328	75051	2015-07-17	37.22	3	0.20	3.72	2
43329	CA-2012-110863	AA-10645	FUR-CH-10002073	73120	2014-11-17	1323.90	5	0.00	383.93	2
43330	CA-2014-118213	AB-10060	OFF-PA-10003673	46142	2016-11-05	67.80	10	0.00	31.19	4
43331	CA-2013-118689	TC-20980	OFF-AR-10001958	47905	2015-10-03	33.96	2	0.00	9.51	2
43332	CA-2012-127509	AS-10090	OFF-BI-10002393	65807	2014-11-09	17.22	3	0.00	7.92	2
43333	CA-2011-117765	RB-19465	FUR-TA-10001039	74133	2013-09-07	429.90	5	0.00	111.77	2
43334	CA-2011-120278	MS-17365	OFF-BI-10004970	54401	2013-11-07	12.39	3	0.00	5.82	2
43335	US-2011-164644	JL-15850	OFF-ST-10003123	77095	2013-07-22	26.63	1	0.20	1.33	1
43336	US-2014-124779	BF-11020	OFF-BI-10002429	76017	2016-09-08	42.62	7	0.80	-68.19	4
43337	CA-2014-133004	AJ-10945	OFF-AP-10002439	46226	2016-08-31	638.73	9	0.00	166.07	2
43338	CA-2013-145303	TP-21415	OFF-BI-10002414	75081	2015-08-29	10.02	4	0.80	-16.54	4
43339	US-2012-165512	VS-21820	OFF-BI-10001249	60540	2014-05-24	7.66	6	0.80	-13.02	1
43340	CA-2012-113173	DK-13225	OFF-SU-10001935	60653	2014-11-15	8.72	5	0.20	-1.74	1
43341	US-2012-114839	PW-19240	FUR-CH-10004086	77036	2014-04-26	408.42	2	0.30	-5.83	2
43342	CA-2013-121034	JF-15565	OFF-FA-10000585	75081	2015-08-09	11.17	4	0.20	3.63	1
43343	CA-2012-160472	RK-19300	TEC-AC-10002253	46614	2014-07-20	831.20	5	0.00	124.68	1
43344	CA-2014-130043	BB-11545	OFF-PA-10002230	77070	2016-09-15	31.87	8	0.20	11.55	2
43345	CA-2014-101728	SC-20575	OFF-BI-10002393	60653	2016-08-19	2.30	2	0.80	-3.90	2
43346	CA-2011-131002	TB-21400	OFF-PA-10000223	74133	2013-09-07	12.96	2	0.00	6.22	1
43347	CA-2014-120376	TP-21130	FUR-TA-10004534	48227	2016-12-22	411.80	2	0.00	70.01	4
43348	CA-2014-166849	SJ-20125	FUR-FU-10004597	60610	2016-04-20	44.40	2	0.60	-52.17	2
43349	CA-2014-140298	JK-16120	OFF-AR-10003481	78745	2016-05-11	5.25	2	0.20	0.59	2
43350	US-2011-117744	MD-17860	FUR-FU-10001588	78415	2013-12-02	58.36	5	0.60	-24.80	2
43351	US-2011-140452	BK-11260	FUR-TA-10004086	60610	2013-12-06	214.95	5	0.50	-120.37	2
43352	US-2012-120712	CS-12130	OFF-ST-10000107	78745	2014-12-20	88.80	4	0.20	-2.22	2
43353	CA-2011-100762	NG-18355	OFF-PA-10001815	49201	2013-11-24	144.12	3	0.00	69.18	2
43354	CA-2013-108987	AG-10675	FUR-BO-10004834	77036	2015-09-09	2396.27	4	0.32	-317.15	1
43355	CA-2012-126970	TP-21130	OFF-BI-10000138	60540	2014-09-20	2.81	3	0.80	-4.49	2
43356	CA-2014-155362	DP-13105	OFF-ST-10001031	54703	2016-12-17	32.56	2	0.00	8.47	2
43357	CA-2011-130869	CB-12025	OFF-EN-10002600	75104	2013-11-17	7.08	3	0.20	2.48	2
43358	US-2013-116365	CA-12310	TEC-AC-10002942	78207	2015-01-03	165.60	3	0.20	-6.21	2
43359	CA-2014-146367	HM-14860	OFF-BI-10002827	75007	2016-08-04	3.32	3	0.80	-5.64	2
43360	CA-2013-164490	SU-20665	OFF-PA-10004971	60653	2015-09-06	9.25	2	0.20	3.35	1
43361	US-2013-152373	PT-19090	OFF-ST-10003479	78207	2015-09-06	93.46	3	0.20	-17.52	2
43362	CA-2014-134285	DS-13180	OFF-FA-10000611	78207	2016-12-07	3.55	3	0.20	1.24	2
43363	US-2014-119319	LC-17050	FUR-FU-10003878	75217	2016-11-06	30.56	5	0.60	-19.86	1
43364	CA-2011-110352	ED-13885	OFF-LA-10003923	77036	2013-11-23	23.68	2	0.20	8.88	2
43365	CA-2014-163125	MB-17305	OFF-AR-10004344	77573	2016-10-09	67.14	7	0.20	5.88	1
43366	CA-2013-136287	SS-20590	OFF-LA-10003148	67212	2015-06-14	18.90	3	0.00	8.69	2
43367	CA-2011-139892	BM-11140	OFF-ST-10000991	78207	2013-09-08	275.93	3	0.20	-58.63	2
43368	US-2012-122140	MO-17950	OFF-AP-10001242	75220	2014-04-02	32.19	2	0.80	-80.48	2
43369	CA-2012-113173	DK-13225	OFF-BI-10004738	60653	2014-11-15	11.36	3	0.80	-17.05	1
43370	US-2014-102288	ZC-21910	OFF-AP-10004655	77095	2016-06-19	2.26	1	0.80	-5.21	2
43371	CA-2014-119655	CV-12295	OFF-BI-10001989	48234	2016-04-20	146.86	7	0.00	70.49	2
43372	CA-2011-151792	CV-12295	TEC-AC-10001606	60653	2013-09-02	239.98	3	0.20	53.99	1
43373	US-2014-136721	NH-18610	FUR-FU-10004188	48237	2016-04-08	306.90	3	0.00	79.79	2
43374	CA-2013-130393	JM-15865	FUR-CH-10004477	76903	2015-12-02	85.25	2	0.30	-1.22	1
43375	CA-2014-149160	JM-15265	OFF-BI-10001543	48187	2016-11-23	287.92	8	0.00	138.20	1
43376	CA-2011-144029	MM-18055	FUR-CH-10003981	60623	2013-05-26	359.77	2	0.30	-5.14	2
43377	CA-2012-125710	BT-11680	OFF-AR-10000657	77036	2014-10-08	3.44	2	0.20	0.56	2
43378	CA-2013-105732	AG-10270	OFF-SU-10004782	68104	2015-09-14	16.90	2	0.00	5.07	2
43379	CA-2011-161508	PV-18985	OFF-PA-10001804	77573	2013-07-12	16.03	3	0.20	5.61	2
43380	CA-2012-131856	JG-15160	OFF-PA-10001954	77041	2014-05-12	127.90	7	0.20	41.57	2
43381	CA-2011-120278	MS-17365	OFF-ST-10004258	54401	2013-11-07	36.63	3	0.00	9.89	2
43382	CA-2012-132136	FO-14305	OFF-BI-10002706	60623	2014-03-08	8.57	3	0.80	-14.57	2
43383	US-2011-124625	SP-20650	TEC-AC-10003280	68104	2013-11-03	89.97	3	0.00	18.89	2
43384	CA-2013-152170	FH-14275	OFF-EN-10002831	46350	2015-11-13	287.52	8	0.00	129.38	1
43385	CA-2014-168123	JD-16060	OFF-FA-10002763	55901	2016-03-05	7.90	2	0.00	2.53	3
43386	CA-2011-111150	RW-19630	TEC-AC-10000290	65203	2013-12-31	47.53	7	0.00	16.16	2
43387	CA-2014-140781	AB-10105	TEC-AC-10000682	61701	2016-08-03	39.82	3	0.20	7.47	2
43388	CA-2011-149643	RH-19510	TEC-PH-10000038	66502	2013-11-16	273.96	2	0.00	10.96	2
43389	CA-2013-139234	AF-10870	OFF-BI-10000773	60610	2015-05-07	3.21	2	0.80	-5.29	2
43390	CA-2014-160885	JK-16090	TEC-PH-10001795	68104	2016-12-02	2479.96	4	0.00	743.99	2
43391	CA-2013-164770	MY-18295	OFF-PA-10003893	77036	2015-12-03	30.82	9	0.20	9.63	1
43392	US-2014-167402	CP-12085	FUR-BO-10001608	65807	2016-01-14	212.94	3	0.00	53.24	1
43393	US-2014-169320	LH-16900	OFF-AR-10003602	46514	2016-07-23	11.68	2	0.00	5.49	1
43394	CA-2012-114468	TD-20995	OFF-AP-10000696	60440	2014-08-23	5.77	2	0.80	-13.55	3
43395	CA-2014-118640	CS-11950	OFF-ST-10002974	60610	2016-07-20	69.71	2	0.20	8.71	2
43396	CA-2011-123225	MN-17935	OFF-PA-10000552	79907	2013-07-11	10.37	2	0.20	3.63	4
43397	CA-2014-121503	FH-14275	OFF-PA-10001878	77041	2016-07-03	273.90	7	0.20	92.44	1
43398	CA-2013-108987	AG-10675	OFF-ST-10000934	77036	2015-09-09	131.14	4	0.20	-32.78	1
43399	CA-2013-128531	NS-18505	OFF-ST-10001325	75217	2015-11-25	41.92	5	0.20	3.67	1
43400	CA-2012-146563	CB-12025	OFF-ST-10001490	76017	2014-08-24	999.43	7	0.20	124.93	2
43401	CA-2011-127446	MC-17590	OFF-LA-10001317	76017	2013-11-25	2.52	1	0.20	0.88	2
43402	CA-2012-145849	CT-11995	OFF-ST-10000025	46203	2014-09-15	190.86	2	0.00	11.45	1
43403	CA-2013-110898	LC-16870	OFF-AP-10001626	60623	2015-03-07	2.33	3	0.80	-6.30	2
43404	CA-2014-126123	AG-10765	OFF-BI-10004224	60623	2016-10-14	13.46	1	0.80	-23.55	2
43405	CA-2012-168088	CM-12655	OFF-PA-10000675	77041	2014-03-19	65.58	2	0.20	23.77	4
43406	CA-2012-125395	LA-16780	TEC-AC-10004708	48180	2014-06-26	41.90	2	0.00	8.80	1
43407	CA-2011-125514	BM-11650	OFF-AP-10000358	68104	2013-09-21	25.96	2	0.00	7.53	4
43408	CA-2014-133256	TH-21550	OFF-PA-10001622	48227	2016-06-26	4.54	1	0.00	2.04	4
43409	CA-2014-109715	AH-10585	OFF-PA-10004965	60623	2016-12-09	15.98	2	0.20	5.00	2
43410	CA-2011-103492	CM-12715	OFF-BI-10004140	77340	2013-10-10	0.90	1	0.80	-1.57	2
43411	CA-2012-115567	ZC-21910	TEC-AC-10001314	47201	2014-09-13	199.96	4	0.00	16.00	2
43412	CA-2012-156377	TB-21625	FUR-FU-10002364	75051	2014-12-31	14.76	5	0.60	-11.44	2
43413	CA-2014-166919	AH-10210	TEC-PH-10001305	75220	2016-11-23	195.96	5	0.20	19.60	2
43414	CA-2011-111899	NC-18340	OFF-FA-10000840	77036	2013-05-04	5.47	6	0.20	1.85	4
43415	CA-2011-165540	TM-21010	OFF-BI-10004094	60098	2013-02-21	8.85	5	0.80	-13.72	2
43416	CA-2011-103492	CM-12715	TEC-PH-10004667	77340	2013-10-10	755.94	7	0.20	66.15	2
43417	US-2014-150595	LE-16810	OFF-SU-10000381	60653	2016-05-22	22.34	3	0.20	2.51	2
43418	CA-2011-131002	TB-21400	TEC-PH-10000215	74133	2013-09-07	104.85	3	0.00	28.31	1
43419	CA-2013-128972	TS-21430	FUR-FU-10003096	73120	2015-11-14	30.36	4	0.00	13.05	2
43420	CA-2014-155376	SG-20080	OFF-AP-10001058	64055	2016-12-22	839.43	3	0.00	218.25	2
43421	US-2011-168501	JK-15325	TEC-PH-10004922	75220	2013-11-21	267.96	5	0.20	16.75	2
43422	CA-2011-165309	KD-16270	OFF-BI-10001267	77095	2013-11-11	1.23	1	0.80	-1.97	2
43423	US-2013-127971	DW-13195	TEC-PH-10003095	77095	2015-11-21	122.92	7	0.20	46.10	2
43424	CA-2012-121783	PO-19180	OFF-BI-10001658	55113	2014-11-10	74.76	3	0.00	34.39	2
43425	CA-2011-123498	TC-20980	OFF-EN-10004773	77041	2013-11-07	74.35	3	0.20	26.95	4
43426	CA-2012-136805	NM-18445	OFF-AP-10001394	48234	2014-05-23	850.50	5	0.10	245.70	1
43427	US-2011-165589	TB-21595	FUR-FU-10002396	79424	2013-02-18	25.16	5	0.60	-11.32	3
43428	CA-2014-158106	CT-11995	OFF-AR-10002255	55124	2016-06-04	8.64	3	0.00	2.51	2
43429	CA-2012-134747	DL-12925	TEC-PH-10001750	46060	2014-10-12	263.96	4	0.00	71.27	1
43430	US-2011-111171	CA-12265	OFF-BI-10002103	60610	2013-12-26	8.69	5	0.80	-14.77	2
43431	CA-2012-100818	JM-15265	FUR-FU-10002703	60653	2014-05-31	51.56	2	0.60	-61.87	1
43432	CA-2014-154039	JK-16120	FUR-TA-10001932	60653	2016-02-18	480.96	3	0.50	-269.34	2
43433	CA-2012-103072	HW-14935	OFF-AR-10000127	48205	2014-09-27	16.40	5	0.00	4.76	1
43434	CA-2012-105627	DK-12895	OFF-AR-10002704	53142	2014-03-08	14.98	1	0.00	4.49	2
43435	CA-2013-130946	ZC-21910	OFF-BI-10004995	77041	2015-04-09	1088.79	4	0.80	-1850.95	2
43436	CA-2012-157812	DB-13210	TEC-AC-10000171	77041	2014-03-22	18.39	1	0.20	5.29	2
43437	CA-2012-112452	NC-18340	TEC-CO-10004202	48911	2014-04-04	599.98	2	0.00	209.99	3
43438	US-2014-152569	JD-16015	TEC-PH-10002185	60653	2016-05-15	11.12	2	0.20	3.48	2
43439	CA-2012-157812	DB-13210	OFF-ST-10000736	77041	2014-03-22	129.57	2	0.20	-25.91	2
43440	CA-2011-129189	HM-14860	OFF-EN-10003567	75217	2013-07-21	87.92	5	0.20	29.67	2
43441	CA-2014-117324	JP-15520	OFF-LA-10003510	53711	2016-12-08	61.06	2	0.00	28.09	2
43442	CA-2014-157966	SU-20665	FUR-CH-10003606	60610	2016-03-13	89.77	1	0.30	-2.56	3
43443	CA-2013-140935	AB-10015	TEC-PH-10000562	73120	2015-11-11	221.98	2	0.00	62.15	4
43444	CA-2012-118955	LS-17230	OFF-EN-10001028	75051	2014-06-16	28.75	3	0.20	9.34	2
43445	CA-2013-145730	CC-12220	TEC-MA-10001016	78207	2015-03-04	287.91	3	0.40	33.59	2
43446	US-2014-133200	DB-13555	OFF-BI-10002827	76106	2016-05-06	11.06	10	0.80	-18.80	2
43447	US-2011-112949	Co-12640	OFF-AR-10003469	73505	2013-06-20	3.52	2	0.00	1.69	2
43448	CA-2013-137176	DB-12910	FUR-FU-10003832	75220	2015-09-10	15.01	4	0.60	-12.01	1
43449	CA-2014-110905	RW-19690	OFF-ST-10000025	65807	2016-09-10	286.29	3	0.00	17.18	1
43450	CA-2012-115742	DP-13000	FUR-CH-10003061	47150	2014-04-18	89.99	1	0.00	17.10	2
43451	CA-2012-129217	DP-13390	OFF-AP-10002439	60505	2014-05-10	70.97	5	0.80	-191.62	3
43452	CA-2011-151379	SC-20695	OFF-PA-10000595	48227	2013-12-16	114.20	5	0.00	52.53	2
43453	CA-2014-160122	RD-19930	FUR-CH-10000422	60623	2016-11-18	127.39	2	0.30	-25.48	2
43454	CA-2012-112452	NC-18340	OFF-BI-10003350	48911	2014-04-04	12.76	2	0.00	5.87	3
43455	CA-2014-134796	FM-14380	TEC-PH-10003505	60440	2016-06-25	148.48	2	0.20	16.70	2
43456	CA-2013-116337	MC-17845	FUR-FU-10002030	75220	2015-11-08	44.46	5	0.60	-17.78	2
43457	CA-2013-109652	QJ-19255	OFF-AR-10000034	60653	2015-04-11	13.57	4	0.20	3.22	2
43458	CA-2011-127166	KH-16360	FUR-CH-10003396	77070	2013-05-21	107.77	2	0.30	-29.25	1
43459	CA-2011-127446	MC-17590	FUR-TA-10000577	76017	2013-11-25	1218.74	5	0.30	-121.87	2
43460	CA-2011-152100	VW-21775	FUR-CH-10000015	77340	2013-05-11	1212.96	8	0.30	-69.31	2
43461	CA-2013-125920	SH-19975	OFF-BI-10003429	60610	2015-05-22	3.80	3	0.80	-5.89	2
43462	CA-2012-145849	CT-11995	OFF-AR-10000817	46203	2014-09-15	24.32	8	0.00	8.27	1
43463	US-2013-165078	MA-17995	OFF-BI-10001989	46226	2015-11-06	104.90	5	0.00	50.35	2
43464	CA-2013-113390	EP-13915	OFF-AR-10003183	60610	2015-10-12	5.34	2	0.20	0.67	2
43465	CA-2012-109337	DL-13330	OFF-AP-10004052	46226	2014-11-21	19.75	5	0.00	5.14	1
43466	CA-2012-136798	DL-12925	TEC-PH-10000441	55407	2014-05-08	377.97	3	0.00	105.83	2
43467	CA-2014-136238	KB-16240	OFF-PA-10004285	79762	2016-12-26	16.03	3	0.20	5.61	2
43468	CA-2012-163181	AB-10105	FUR-FU-10000193	77041	2014-11-07	64.96	5	0.60	-84.45	2
43469	CA-2014-103415	MV-17485	FUR-FU-10000820	77041	2016-12-03	13.59	2	0.60	-14.27	2
43470	CA-2014-121580	ML-17410	OFF-BI-10000632	47201	2016-05-29	43.41	1	0.00	19.97	2
43471	CA-2011-126200	JE-15715	OFF-BI-10002133	77070	2013-08-25	25.68	3	0.80	-39.80	2
43472	US-2012-151407	RD-19585	TEC-PH-10003885	52001	2014-11-08	263.96	4	0.00	76.55	2
43473	CA-2014-133256	TH-21550	TEC-PH-10002660	48227	2016-06-26	543.92	8	0.00	135.98	4
43474	CA-2013-119641	CS-12250	FUR-FU-10002445	54302	2015-09-23	18.96	2	0.00	7.58	2
43475	US-2013-103646	SP-20545	OFF-AP-10004487	60623	2015-04-22	48.79	3	0.80	-126.86	2
43476	CA-2014-150266	RO-19780	OFF-AP-10002867	77070	2016-11-25	67.84	5	0.80	-179.78	2
43477	US-2012-153374	JF-15565	TEC-AC-10001908	62521	2014-02-09	479.95	6	0.20	89.99	1
43478	US-2014-152366	SJ-20500	OFF-AP-10002684	77036	2016-04-21	97.26	4	0.80	-243.16	1
43479	CA-2011-159310	SC-20725	OFF-BI-10000201	77070	2013-11-07	1.48	3	0.80	-2.21	2
43480	CA-2014-136063	SS-20140	OFF-AR-10000823	60302	2016-12-15	10.19	7	0.20	1.02	2
43481	US-2013-116365	CA-12310	TEC-PH-10002890	78207	2015-01-03	180.96	5	0.20	13.57	2
43482	CA-2012-106565	BW-11110	OFF-PA-10000061	53209	2014-03-20	51.84	8	0.00	24.88	4
43483	CA-2013-126627	WB-21850	FUR-FU-10004963	77571	2015-10-11	14.00	4	0.60	-6.30	4
43484	CA-2011-120775	RD-19930	OFF-BI-10002609	75217	2013-10-03	1.79	3	0.80	-3.04	2
43485	CA-2013-124352	CD-12790	OFF-BI-10000977	73120	2015-10-16	121.60	4	0.00	55.94	2
43486	CA-2011-150518	MW-18220	TEC-PH-10002103	55433	2013-11-19	281.97	3	0.00	78.95	2
43487	US-2014-119438	CD-11980	OFF-BI-10004632	75701	2016-03-18	182.99	3	0.80	-320.24	2
43488	CA-2014-151750	JM-15250	OFF-BI-10000343	77340	2016-01-02	13.75	14	0.80	-22.68	2
43489	CA-2013-117590	GH-14485	TEC-PH-10004977	75080	2015-12-09	1097.54	7	0.20	123.47	4
43490	CA-2011-156342	JF-15415	OFF-PA-10001725	60653	2013-06-17	62.02	2	0.20	22.48	1
43491	CA-2013-111794	HG-15025	TEC-AC-10003832	79109	2015-10-02	79.51	3	0.20	20.87	3
43492	CA-2013-147256	FC-14245	OFF-AP-10003057	65203	2015-10-18	1927.59	7	0.00	751.76	1
43493	CA-2013-115756	PK-19075	FUR-CH-10002372	48227	2015-09-06	242.94	3	0.00	29.15	1
43494	CA-2013-116540	SS-20590	OFF-BI-10004970	53711	2015-09-03	8.26	2	0.00	3.88	3
43495	CA-2011-145800	SS-20410	FUR-TA-10001539	60089	2013-05-30	355.46	3	0.50	-184.84	2
43496	CA-2011-120544	SS-20140	TEC-AC-10003709	75150	2013-11-23	5.54	7	0.20	1.66	2
43497	CA-2013-146206	KT-16480	TEC-PH-10000895	77095	2015-09-11	719.96	5	0.20	54.00	1
43498	CA-2011-151078	RF-19840	OFF-ST-10001328	78207	2013-11-12	49.63	4	0.20	4.96	3
43499	CA-2013-114601	AA-10480	TEC-PH-10002170	48234	2015-08-27	209.97	3	0.00	58.79	2
43500	US-2012-141453	DB-13270	OFF-BI-10000301	78745	2014-11-30	3.88	3	0.80	-5.82	1
43501	CA-2011-167927	XP-21865	OFF-AP-10002311	48185	2013-01-20	247.72	4	0.10	93.58	2
43502	CA-2014-164042	KL-16645	OFF-BI-10001922	77095	2016-05-23	1.19	1	0.80	-1.96	2
43503	CA-2013-133550	KL-16645	FUR-FU-10002918	48205	2015-08-01	272.94	3	0.00	30.02	2
43504	CA-2012-149587	KB-16315	OFF-BI-10002852	55407	2014-01-31	32.96	2	0.00	16.15	1
43505	CA-2012-128125	EB-13705	FUR-FU-10001085	77095	2014-03-31	22.38	3	0.60	-7.83	2
43506	CA-2012-142937	SF-20065	OFF-AR-10003582	75220	2014-12-05	45.04	2	0.20	4.50	4
43507	CA-2014-157903	AM-10705	TEC-PH-10004345	60016	2016-04-04	383.84	4	0.20	47.98	2
43508	CA-2014-127474	RD-19810	FUR-FU-10004597	60610	2016-02-04	22.20	1	0.60	-26.09	1
43509	CA-2011-166863	SC-20020	OFF-PA-10000587	75023	2013-06-20	11.65	2	0.20	4.08	2
43510	CA-2012-119690	MV-17485	FUR-FU-10004587	77041	2014-06-25	75.38	9	0.60	-20.73	4
43511	US-2013-131114	RW-19630	OFF-SU-10001664	60610	2015-12-10	20.57	3	0.20	1.54	1
43512	US-2012-138121	JL-15835	FUR-CH-10003846	48205	2014-12-17	302.94	3	0.00	48.47	3
43513	CA-2012-136798	DL-12925	OFF-BI-10003684	55407	2014-05-08	43.98	2	0.00	21.99	2
43514	CA-2012-154326	RP-19855	TEC-AC-10004568	53142	2014-02-15	139.95	5	0.00	26.59	2
43515	CA-2013-101791	BS-11665	OFF-ST-10001496	60623	2015-05-28	1297.37	9	0.20	97.30	2
43516	CA-2014-104927	AG-10330	OFF-PA-10000176	77095	2016-12-22	75.88	5	0.20	26.56	2
43517	CA-2013-134110	BG-11035	TEC-PH-10002350	75056	2015-11-18	67.18	3	0.20	6.72	4
43518	CA-2014-154039	JK-16120	TEC-PH-10002789	60653	2016-02-18	124.79	1	0.20	10.92	2
43519	CA-2014-120376	TP-21130	FUR-CH-10002335	48227	2016-12-22	1586.69	7	0.00	412.54	4
43520	US-2012-163433	MP-17965	OFF-AR-10003481	78501	2014-04-18	7.87	3	0.20	0.89	1
43521	CA-2014-144064	CP-12085	OFF-BI-10002012	62301	2016-08-29	3.24	9	0.80	-5.18	4
43522	CA-2014-157966	SU-20665	TEC-MA-10002109	60610	2016-03-13	209.99	2	0.30	9.00	3
43523	CA-2012-105690	CA-11965	TEC-CO-10001571	77642	2014-11-21	439.99	1	0.20	165.00	1
43524	CA-2011-126333	ME-18010	OFF-PA-10000223	77642	2013-12-23	5.18	1	0.20	1.81	2
43525	CA-2011-165379	BM-11650	OFF-PA-10002245	75217	2013-07-09	14.35	3	0.20	4.49	2
43526	CA-2014-122763	HG-14845	OFF-PA-10000474	77041	2016-03-20	56.70	2	0.20	19.14	3
43527	CA-2013-116526	JA-15970	OFF-BI-10001116	48227	2015-09-02	26.40	5	0.00	12.67	2
43528	US-2012-132836	AJ-10945	OFF-LA-10004178	48227	2014-06-01	28.91	7	0.00	13.30	2
43529	US-2011-151015	BD-11500	OFF-PA-10001184	60653	2013-10-14	19.14	4	0.20	6.94	2
43530	CA-2011-106803	DC-13285	TEC-AC-10001267	55016	2013-12-29	119.80	4	0.00	47.92	2
43531	CA-2011-165309	KD-16270	TEC-PH-10004959	77095	2013-11-11	241.18	3	0.20	15.07	2
43532	CA-2012-121699	BD-11320	OFF-BI-10004632	48227	2014-08-10	64.75	5	0.00	29.14	2
43533	CA-2011-121006	SC-20020	OFF-PA-10002479	48640	2013-11-10	15.84	3	0.00	7.13	2
43534	CA-2014-100335	NF-18595	OFF-PA-10001685	60610	2016-09-07	73.01	9	0.20	26.47	2
43535	CA-2014-113278	HR-14770	FUR-FU-10001037	47374	2016-01-15	18.96	2	0.00	8.53	2
43536	CA-2014-107825	NB-18655	OFF-ST-10000777	53209	2016-11-18	37.76	1	0.00	10.57	3
43537	CA-2011-130673	MC-17590	FUR-FU-10003489	78666	2013-05-20	10.33	3	0.60	-5.94	1
43538	CA-2011-139892	BM-11140	OFF-AP-10002518	78207	2013-09-08	177.98	5	0.80	-453.85	2
43539	CA-2011-158442	AZ-10750	OFF-AR-10003732	75217	2013-03-17	4.45	2	0.20	0.33	3
43540	US-2011-159618	DB-12970	OFF-PA-10004100	77036	2013-11-12	36.29	7	0.20	12.70	2
43541	CA-2013-152730	EM-14140	OFF-ST-10000876	54880	2015-05-31	49.76	4	0.00	13.93	2
43542	CA-2014-121160	FM-14290	OFF-ST-10002485	77803	2016-11-04	52.75	3	0.20	-12.53	3
43543	CA-2013-128671	MT-18070	OFF-BI-10003007	74133	2015-08-12	77.56	2	0.00	35.68	2
43544	CA-2013-108581	EA-14035	TEC-AC-10001109	75007	2015-06-21	95.97	4	0.20	26.39	2
43545	CA-2014-107265	ML-17755	OFF-PA-10000474	52302	2016-04-06	106.32	3	0.00	49.97	2
43546	US-2014-148362	KF-16285	OFF-PA-10003441	46203	2016-07-01	25.92	4	0.00	12.44	2
43547	CA-2011-131009	SC-20380	OFF-ST-10001469	79907	2013-03-01	129.55	3	0.20	-22.67	2
43548	CA-2014-149468	AR-10405	OFF-BI-10002225	48183	2016-05-20	41.28	2	0.00	19.81	3
43549	CA-2014-125290	CC-12430	OFF-PA-10003127	55407	2016-11-06	26.38	1	0.00	12.13	1
43550	CA-2014-156622	JP-15460	FUR-TA-10003008	75220	2016-11-23	127.79	1	0.30	-31.03	4
43551	US-2011-100853	JB-15400	OFF-LA-10003148	60623	2013-09-14	20.16	4	0.20	6.55	2
43552	CA-2014-167626	MY-18295	TEC-AC-10004353	60623	2016-09-03	100.80	2	0.20	21.42	2
43553	CA-2011-129189	HM-14860	OFF-BI-10000494	75217	2013-07-21	1.04	1	0.80	-1.83	2
43554	CA-2011-166716	CR-12730	FUR-CH-10004495	60610	2013-08-20	421.37	2	0.30	-6.02	1
43555	US-2014-125647	LC-16870	OFF-PA-10004888	60653	2016-09-23	20.74	4	0.20	7.26	2
43556	CA-2014-124674	JB-16000	FUR-BO-10002202	78521	2016-11-17	327.73	2	0.32	-14.46	2
43557	CA-2013-149237	CM-12235	FUR-FU-10002088	53209	2015-05-27	26.94	3	0.00	11.31	2
43558	CA-2014-104220	BV-11245	TEC-PH-10004614	50315	2016-01-31	207.00	3	0.00	51.75	2
43559	US-2013-146710	SS-20875	OFF-PA-10004971	75220	2015-08-28	4.62	1	0.20	1.68	2
43560	CA-2012-162964	MF-18250	OFF-EN-10003055	77095	2014-11-12	223.89	7	0.20	69.97	2
43561	CA-2012-141250	PM-18940	FUR-TA-10002855	77590	2014-01-19	102.44	1	0.30	-13.17	2
43562	CA-2013-130400	SJ-20125	OFF-EN-10001453	75217	2015-03-09	146.35	3	0.20	49.39	2
43563	CA-2014-111815	EP-13915	TEC-AC-10002926	48127	2016-03-03	99.98	2	0.00	42.99	2
43564	CA-2014-104745	GT-14755	OFF-PA-10002036	78550	2016-05-29	25.92	5	0.20	9.40	2
43565	US-2014-124779	BF-11020	FUR-CH-10003535	76017	2016-09-08	213.43	5	0.30	-39.64	4
43566	CA-2014-130351	RB-19570	OFF-AP-10004532	47201	2016-12-05	61.44	3	0.00	16.59	4
43567	CA-2014-112473	JL-15505	OFF-ST-10002182	77070	2016-05-25	50.14	3	0.20	-11.28	2
43568	US-2014-160836	CC-12475	FUR-TA-10002855	77070	2016-09-11	512.19	5	0.30	-65.85	2
43569	US-2013-110156	EH-13945	FUR-FU-10000206	77041	2015-11-20	2.33	2	0.60	-0.76	2
43570	CA-2013-105732	AG-10270	TEC-PH-10004897	68104	2015-09-14	29.97	3	0.00	0.30	2
43571	CA-2013-105732	AG-10270	OFF-AP-10001394	68104	2015-09-14	378.00	2	0.00	136.08	2
43572	CA-2011-140795	BD-11500	TEC-AC-10001432	54302	2013-02-01	468.90	6	0.00	206.32	4
43573	CA-2014-121216	MM-17920	OFF-PA-10004519	77840	2016-12-23	28.67	8	0.20	10.39	1
43574	CA-2013-132829	LA-16780	FUR-FU-10000206	77041	2015-12-24	2.33	2	0.60	-0.76	1
43575	CA-2014-166317	JE-15610	OFF-BI-10002976	53209	2016-09-22	33.04	8	0.00	15.53	2
43576	CA-2012-121783	PO-19180	TEC-CO-10001571	55113	2014-11-10	549.99	1	0.00	275.00	2
43577	CA-2014-151428	RH-19495	OFF-BI-10000546	55901	2016-09-21	20.16	7	0.00	9.88	2
43578	CA-2013-152170	FH-14275	OFF-AP-10002350	46350	2015-11-13	37.68	2	0.00	10.55	1
43579	CA-2013-120824	AW-10930	OFF-AR-10003469	77070	2015-06-13	11.26	8	0.20	3.94	1
43580	CA-2011-100762	NG-18355	OFF-AR-10000380	49201	2013-11-24	151.92	4	0.00	45.58	2
43581	CA-2014-113873	KE-16420	FUR-BO-10003441	75220	2016-11-13	206.00	3	0.32	-27.26	2
43582	CA-2013-118255	ON-18715	TEC-AC-10000171	55122	2015-03-12	45.98	2	0.00	19.77	4
43583	CA-2012-142139	SD-20485	OFF-PA-10003883	76021	2014-08-31	20.96	4	0.20	6.81	2
43584	CA-2013-144764	RL-19615	TEC-MA-10003230	60623	2015-09-03	1362.90	3	0.30	-19.47	2
43585	CA-2013-147067	JD-16150	FUR-FU-10000732	55407	2015-12-19	18.84	3	0.00	6.03	2
43586	US-2013-110156	EH-13945	OFF-ST-10000642	77041	2015-11-20	100.70	6	0.20	-16.36	2
43587	CA-2013-165484	HK-14890	OFF-PA-10000595	60610	2015-10-24	54.82	3	0.20	17.82	2
43588	CA-2011-120775	RD-19930	OFF-FA-10002676	75217	2013-10-03	4.34	3	0.20	0.87	2
43589	CA-2014-107958	AH-10120	OFF-BI-10001787	77036	2016-07-02	5.23	4	0.80	-8.11	4
43590	CA-2012-149811	CS-12250	OFF-PA-10004082	55125	2014-01-04	39.90	5	0.00	19.95	2
43591	CA-2013-144911	RW-19630	TEC-AC-10004633	66212	2015-11-28	34.95	5	0.00	15.38	4
43592	CA-2013-152331	LD-16855	OFF-AR-10001547	60653	2015-06-27	5.30	3	0.20	0.46	2
43593	US-2011-106299	NZ-18565	OFF-BI-10001758	65807	2013-08-02	26.70	5	0.00	12.55	2
43594	CA-2013-101987	HL-15040	TEC-PH-10001305	47374	2015-06-25	440.91	9	0.00	123.45	2
43595	CA-2014-106782	LP-17095	OFF-ST-10004459	47905	2016-12-21	375.34	1	0.00	18.77	2
43596	CA-2011-134572	SV-20365	FUR-TA-10001705	77070	2013-04-20	744.10	5	0.30	-95.67	1
43597	US-2012-122784	RA-19915	FUR-BO-10004690	60035	2014-07-20	384.94	4	0.30	-126.48	2
43598	US-2011-119081	TA-21385	TEC-AC-10001542	66062	2013-09-12	57.40	5	0.00	10.91	2
43599	CA-2014-122035	EM-13825	FUR-CH-10003833	57103	2016-07-20	182.94	3	0.00	27.44	2
43600	CA-2012-109190	CC-12685	OFF-BI-10000977	79424	2014-10-23	6.08	1	0.80	-10.34	2
43601	CA-2014-135860	JH-15985	TEC-PH-10001700	48601	2016-12-01	131.98	2	0.00	35.63	2
43602	US-2011-140452	BK-11260	FUR-FU-10002088	60610	2013-12-06	10.78	3	0.60	-4.85	2
43603	CA-2013-145303	TP-21415	FUR-BO-10003159	75081	2015-08-29	156.37	2	0.32	-52.89	4
43604	CA-2013-132829	LA-16780	TEC-PH-10004912	77041	2015-12-24	131.88	3	0.20	14.84	1
43605	CA-2011-148950	JD-16015	OFF-FA-10003059	60610	2013-12-14	2.90	2	0.20	0.47	2
43606	US-2013-160528	MH-18115	OFF-ST-10002743	78577	2015-08-24	727.30	8	0.20	-172.73	2
43607	CA-2014-149706	AS-10285	TEC-AC-10001284	60067	2016-12-11	116.31	7	0.20	23.26	4
43608	CA-2014-130386	NG-18430	OFF-ST-10003716	78745	2016-11-12	540.05	3	0.20	-47.25	2
43609	CA-2013-123932	YC-21895	TEC-PH-10002447	75217	2015-09-07	329.58	2	0.20	37.08	2
43610	CA-2014-163860	LO-17170	OFF-BI-10003784	61604	2016-12-28	1.68	5	0.80	-2.69	2
43611	CA-2011-129168	KB-16585	OFF-PA-10001639	77095	2013-08-17	15.55	3	0.20	5.44	2
43612	CA-2011-153976	BP-11290	FUR-CH-10002880	60201	2013-10-03	258.28	3	0.30	-70.10	1
43613	CA-2014-158876	AB-10150	OFF-PA-10000308	75007	2016-11-19	16.90	4	0.20	5.28	1
43614	CA-2012-163181	AB-10105	OFF-ST-10001713	77041	2014-11-07	84.78	2	0.20	-16.96	2
43615	CA-2014-117443	JB-15400	OFF-PA-10004475	61107	2016-12-23	175.87	4	0.20	63.75	1
43616	US-2014-130953	RF-19735	TEC-PH-10003012	73120	2016-07-29	461.97	3	0.00	133.97	2
43617	CA-2014-169691	Dp-13240	OFF-PA-10003022	55369	2016-06-15	17.94	3	0.00	8.79	4
43618	CA-2014-150266	RO-19780	TEC-PH-10003437	77070	2016-11-25	299.96	5	0.20	37.50	2
43619	CA-2014-164042	KL-16645	OFF-AP-10001947	77095	2016-05-23	18.32	5	0.80	-46.72	2
43620	CA-2012-112711	FM-14380	TEC-PH-10000526	79109	2014-07-12	307.17	4	0.20	30.72	2
43621	US-2011-152030	AD-10180	FUR-CH-10004063	77041	2013-12-26	600.56	3	0.30	-8.58	1
43622	CA-2014-103877	RD-19660	OFF-BI-10003650	64055	2016-09-07	1577.94	3	0.00	757.41	2
43623	CA-2013-161781	CC-12100	OFF-AR-10000255	47201	2015-09-30	40.88	7	0.00	10.63	4
43624	US-2013-117793	MA-17560	OFF-LA-10002945	53081	2015-08-24	25.20	4	0.00	11.59	2
43625	CA-2014-151190	GT-14710	OFF-PA-10000575	68104	2016-06-27	20.07	3	0.00	9.23	2
43626	US-2013-146857	BE-11455	OFF-AP-10001205	65807	2015-05-07	54.48	1	0.00	15.25	1
43627	CA-2012-112452	NC-18340	TEC-PH-10000307	48911	2014-04-04	10.95	1	0.00	0.44	3
43628	CA-2011-103849	PG-18895	FUR-FU-10000723	76106	2013-05-11	66.11	4	0.60	-84.29	2
43629	CA-2013-117226	KD-16495	OFF-BI-10004654	77536	2015-12-31	6.92	6	0.80	-10.39	4
43630	CA-2014-146920	SC-20305	OFF-PA-10002479	60623	2016-08-28	25.34	6	0.20	7.92	2
43631	CA-2013-149272	MY-18295	FUR-CH-10000863	77803	2015-03-16	528.43	5	0.30	-143.43	2
43632	CA-2011-131002	TB-21400	FUR-FU-10004270	74133	2013-09-07	57.69	3	0.00	23.65	1
43633	CA-2011-124807	ME-17725	TEC-AC-10002857	60610	2013-07-12	23.84	4	0.20	3.28	1
43634	CA-2013-157749	KL-16645	OFF-AR-10004685	60610	2015-06-05	7.41	2	0.20	1.20	1
43635	CA-2014-100223	LS-16945	OFF-BI-10004492	75220	2016-07-05	6.32	1	0.80	-10.42	2
43636	US-2013-117793	MA-17560	OFF-ST-10002406	53081	2015-08-24	14.97	1	0.00	4.19	2
43637	CA-2012-117415	SN-20710	TEC-PH-10000486	77041	2014-12-27	371.17	4	0.20	41.76	2
43638	CA-2012-148873	EM-13960	OFF-BI-10003196	62301	2014-10-01	2.99	4	0.80	-4.49	2
43639	US-2014-160836	CC-12475	OFF-PA-10004239	77070	2016-09-11	10.27	3	0.20	3.21	2
43640	CA-2013-155845	CM-12235	TEC-AC-10004145	75007	2015-08-13	1399.94	7	0.20	52.50	1
43641	CA-2014-147207	TS-21655	OFF-ST-10002615	79907	2016-01-03	372.14	3	0.20	27.91	1
43642	US-2011-112914	MT-18070	OFF-BI-10002982	77041	2013-09-25	2.72	2	0.80	-4.36	2
43643	CA-2011-167360	RB-19435	TEC-AC-10001772	63116	2013-11-24	111.79	7	0.00	43.60	1
43644	CA-2014-140298	JK-16120	OFF-ST-10004180	78745	2016-05-11	74.42	2	0.20	-14.88	2
43645	CA-2011-159310	SC-20725	FUR-CH-10002758	77070	2013-11-07	683.14	4	0.30	0.00	2
43646	CA-2014-130211	BD-11620	FUR-TA-10003748	73505	2016-10-22	248.98	2	0.00	54.78	3
43647	CA-2014-102155	RR-19525	OFF-ST-10001496	66212	2016-07-13	360.38	2	0.00	93.70	2
43648	CA-2013-152730	EM-14140	OFF-AR-10003732	54880	2015-05-31	5.56	2	0.00	1.45	2
43649	CA-2014-149048	BM-11650	OFF-ST-10000078	47201	2016-05-13	530.34	2	0.00	95.46	2
43650	US-2014-162124	JF-15490	TEC-AC-10001990	60653	2016-05-06	191.97	4	0.20	28.80	2
43651	CA-2013-108581	EA-14035	OFF-PA-10000809	75007	2015-06-21	10.37	2	0.20	3.63	2
43652	CA-2011-162362	JL-15505	OFF-BI-10000756	48640	2013-11-14	12.72	3	0.00	6.36	2
43653	CA-2014-118773	TP-21415	OFF-BI-10004584	77070	2016-02-10	252.78	4	0.80	-417.09	2
43654	CA-2013-118689	TC-20980	OFF-BI-10003712	47905	2015-10-03	34.37	7	0.00	16.84	2
43655	CA-2014-120327	WB-21850	OFF-FA-10004854	50322	2016-11-11	45.92	4	0.00	21.58	2
43656	US-2012-125374	JD-16060	FUR-CH-10003396	77095	2014-03-23	107.77	2	0.30	-29.25	2
43657	CA-2011-133753	CW-11905	OFF-AR-10001953	77340	2013-06-09	70.37	2	0.20	6.16	1
43658	CA-2012-156377	TB-21625	OFF-BI-10002954	75051	2014-12-31	3.66	4	0.80	-5.85	2
43659	US-2012-122140	MO-17950	TEC-AC-10003289	75220	2014-04-02	47.98	3	0.20	1.80	2
43660	CA-2011-131926	DW-13480	OFF-PA-10000061	55044	2013-06-01	25.92	4	0.00	12.44	1
43661	CA-2014-154011	DB-13270	OFF-BI-10003166	75081	2016-06-19	6.89	3	0.80	-11.02	2
43662	US-2011-117058	LE-16810	OFF-BI-10004139	60653	2013-05-27	17.46	6	0.80	-30.56	4
43663	CA-2012-109190	CC-12685	OFF-PA-10000069	79424	2014-10-23	60.74	8	0.20	20.50	2
43664	CA-2013-133697	CM-12445	OFF-PA-10000726	77095	2015-10-21	51.02	7	0.20	15.94	1
43665	CA-2011-117765	RB-19465	OFF-ST-10003327	74133	2013-09-07	19.86	2	0.00	5.76	2
43666	CA-2011-167927	XP-21865	OFF-AR-10004456	48185	2013-01-20	43.92	3	0.00	12.74	2
43667	US-2013-156097	EH-14125	FUR-CH-10001215	60505	2015-09-20	701.37	2	0.30	-50.10	3
43668	CA-2013-146206	KT-16480	FUR-TA-10004086	77095	2015-09-11	300.93	5	0.30	-34.39	1
43669	CA-2011-130673	MC-17590	TEC-AC-10004227	78666	2013-05-20	20.78	2	0.20	-3.64	1
43670	CA-2014-152709	DB-13210	OFF-ST-10001837	48234	2016-10-07	85.52	2	0.00	22.24	2
43671	CA-2011-130274	JS-15940	OFF-LA-10002195	54915	2013-05-03	21.56	7	0.00	10.35	4
43672	CA-2011-115980	VW-21775	OFF-FA-10000304	57103	2013-07-15	6.54	3	0.00	2.68	2
43673	US-2011-137869	CV-12295	FUR-TA-10003954	50315	2013-03-28	1184.72	4	0.00	106.62	2
43674	CA-2012-103072	HW-14935	OFF-PA-10003172	48205	2014-09-27	25.92	4	0.00	12.44	1
43675	CA-2012-105970	PA-19060	OFF-AR-10003156	47374	2014-03-02	10.16	1	0.00	2.64	2
43676	CA-2014-122595	GM-14455	TEC-AC-10000474	60653	2016-12-14	227.98	3	0.20	28.50	2
43677	CA-2013-165218	RW-19630	OFF-EN-10000056	75220	2015-03-06	149.35	3	0.20	50.41	2
43678	CA-2011-126963	PS-18760	OFF-PA-10001952	79907	2013-06-15	36.54	2	0.20	11.88	3
43679	CA-2014-154011	DB-13270	FUR-TA-10000688	75081	2016-06-19	457.49	3	0.30	-84.96	2
43680	US-2011-112914	MT-18070	OFF-PA-10003270	77041	2013-09-25	33.79	8	0.20	10.56	2
43681	CA-2011-125514	BM-11650	OFF-PA-10000029	68104	2013-09-21	6.48	1	0.00	3.11	4
43682	CA-2011-146703	PO-18865	OFF-ST-10001713	48185	2013-10-20	211.96	4	0.00	8.48	1
43683	US-2014-122714	HG-14965	OFF-BI-10001120	60653	2016-12-07	1889.99	5	0.80	-2929.48	2
43684	CA-2014-126956	GT-14710	OFF-SU-10000381	55044	2016-08-21	37.24	4	0.00	10.80	2
43685	CA-2013-145303	TP-21415	OFF-BI-10000050	75081	2015-08-29	13.14	9	0.80	-21.68	4
43686	CA-2012-139094	MO-17800	FUR-TA-10004607	78207	2014-11-22	206.96	2	0.30	-32.52	2
43687	CA-2011-115336	AB-10600	OFF-BI-10001107	60623	2013-11-18	14.48	5	0.80	-23.89	2
43688	CA-2014-159366	BW-11110	TEC-MA-10000822	48205	2016-01-08	3059.98	2	0.10	680.00	4
43689	CA-2014-145443	SC-20695	OFF-PA-10003302	47374	2016-08-10	177.20	5	0.00	83.28	1
43690	US-2014-169320	LH-16900	TEC-AC-10002550	46514	2016-07-23	159.75	5	0.00	11.18	1
43691	CA-2011-115980	VW-21775	TEC-AC-10003709	57103	2013-07-15	2.97	3	0.00	1.31	2
43692	CA-2011-120775	RD-19930	FUR-FU-10000758	75217	2013-10-03	31.78	3	0.60	-19.07	2
43693	CA-2014-143252	HE-14800	FUR-FU-10001057	53209	2016-12-18	99.95	5	0.00	22.99	2
43694	CA-2013-118101	SN-20560	OFF-PA-10000357	48066	2015-06-27	368.91	9	0.00	180.77	3
43695	CA-2012-129217	DP-13390	OFF-AR-10004602	60505	2014-05-10	36.78	2	0.20	3.68	3
43696	CA-2014-105823	RB-19465	FUR-CH-10000454	48227	2016-06-22	487.96	2	0.00	146.39	2
43697	CA-2011-168368	GA-14725	OFF-LA-10004853	65203	2013-02-11	14.94	3	0.00	6.87	1
43698	US-2012-101399	JS-15940	FUR-FU-10002918	60068	2014-01-17	254.74	7	0.60	-312.06	2
43699	CA-2013-128531	NS-18505	OFF-PA-10000167	75217	2015-11-25	74.35	3	0.20	23.24	1
43700	CA-2013-156748	BS-11755	OFF-PA-10000380	48227	2015-12-01	33.36	4	0.00	16.68	2
43701	CA-2014-139199	DK-12835	FUR-CH-10000847	48234	2016-12-09	872.94	3	0.00	226.96	2
43702	CA-2011-105165	SZ-20035	TEC-PH-10000675	77036	2013-09-07	196.78	3	0.20	14.76	4
43703	CA-2014-146164	CM-12190	FUR-TA-10004915	55901	2016-12-22	607.52	2	0.00	97.20	2
43704	US-2013-126844	BW-11110	FUR-FU-10004909	77070	2015-10-09	51.71	8	0.60	-32.32	2
43705	US-2014-116701	LC-17140	OFF-AP-10003217	75220	2016-12-17	66.28	2	0.80	-178.97	1
43706	CA-2014-132682	TH-21235	OFF-PA-10000474	75081	2016-06-08	85.06	3	0.20	28.71	1
43707	CA-2014-131618	LS-17200	OFF-BI-10000546	60076	2016-06-17	2.30	4	0.80	-3.57	4
43708	CA-2014-107958	AH-10120	OFF-PA-10000357	77036	2016-07-02	163.96	5	0.20	59.44	4
43709	CA-2012-109337	DL-13330	OFF-AR-10003759	46226	2014-11-21	10.92	6	0.00	4.91	1
43710	CA-2013-127670	RD-19660	FUR-TA-10001095	63376	2015-03-21	697.16	4	0.00	146.40	2
43711	CA-2011-140487	SR-20425	FUR-BO-10000711	48234	2013-06-14	212.94	3	0.00	57.49	2
43712	US-2014-150595	LE-16810	OFF-BI-10003274	60653	2016-05-22	1.59	2	0.80	-2.63	2
43713	CA-2014-157966	SU-20665	OFF-PA-10001934	60610	2016-03-13	15.55	3	0.20	5.64	3
43714	CA-2012-149587	KB-16315	FUR-FU-10003799	55407	2014-01-31	53.34	3	0.00	16.54	1
43715	CA-2012-127509	AS-10090	OFF-PA-10002160	65807	2014-11-09	17.34	3	0.00	8.50	2
43716	CA-2014-146185	CC-12145	OFF-AR-10002987	77095	2016-09-15	31.74	2	0.20	8.33	2
43717	CA-2013-116540	SS-20590	OFF-FA-10002676	53711	2015-09-03	1.81	1	0.00	0.65	3
43718	CA-2012-135685	MP-18175	TEC-AC-10004145	53209	2014-11-16	999.96	4	0.00	229.99	1
43719	CA-2012-126669	DO-13645	OFF-PA-10001357	77036	2014-11-07	76.64	2	0.20	26.82	2
43720	US-2012-123218	KD-16345	TEC-AC-10000736	60623	2014-12-20	255.97	4	0.20	51.19	2
43721	US-2011-112914	MT-18070	OFF-EN-10001509	77041	2013-09-25	3.26	2	0.20	1.10	2
43722	CA-2014-160087	EN-13780	OFF-AR-10001915	75220	2016-03-18	23.83	3	0.20	6.55	2
43723	CA-2014-125115	RD-19930	TEC-AC-10001714	78745	2016-04-10	95.74	3	0.20	20.34	3
43724	CA-2011-151554	CM-11815	OFF-PA-10004609	77506	2013-11-14	20.74	4	0.20	7.26	4
43725	CA-2011-166863	SC-20020	OFF-PA-10001166	75023	2013-06-20	15.55	3	0.20	5.44	2
43726	CA-2014-121559	HW-14935	TEC-AC-10004568	46203	2016-06-01	83.97	3	0.00	15.95	1
43727	CA-2014-143063	IL-15100	TEC-PH-10003645	47201	2016-08-10	1454.49	9	0.00	378.17	2
43728	CA-2012-153717	DL-13495	TEC-PH-10002923	48227	2014-12-25	73.98	2	0.00	19.97	2
43729	CA-2012-111395	VB-21745	OFF-PA-10000994	78207	2014-11-23	335.52	4	0.20	117.43	2
43730	US-2011-120145	MC-17635	OFF-EN-10003862	47374	2013-11-28	64.02	6	0.00	29.45	2
43731	CA-2014-152275	KH-16630	OFF-AR-10000369	78207	2016-10-01	6.67	6	0.20	0.50	2
43732	CA-2012-126557	RL-19615	OFF-BI-10003314	60610	2014-07-12	1.93	2	0.80	-2.99	1
43733	CA-2014-144064	CP-12085	OFF-LA-10004544	62301	2016-08-29	47.36	4	0.20	17.76	4
43734	CA-2012-140921	AA-10375	TEC-AC-10004901	68104	2014-02-03	149.97	3	0.00	50.99	4
43735	US-2013-157728	RC-19960	OFF-PA-10002195	49505	2015-09-23	35.56	7	0.00	16.71	2
43736	CA-2014-126074	RF-19735	FUR-FU-10003577	48183	2016-10-02	157.74	11	0.00	56.79	2
43737	CA-2013-164637	RD-19480	OFF-BI-10003876	46544	2015-03-05	128.40	3	0.00	64.20	2
43738	CA-2014-161774	GT-14710	OFF-AR-10001446	77041	2016-05-14	46.20	5	0.20	5.78	4
43739	US-2014-119816	TT-21460	OFF-ST-10000918	77095	2016-03-04	8.72	1	0.20	0.65	1
43740	CA-2012-145394	MC-17605	FUR-FU-10001215	60610	2014-11-16	34.50	2	0.60	-15.53	2
43741	CA-2014-115805	KW-16435	TEC-PH-10003092	60653	2016-07-31	36.79	1	0.20	4.14	3
43742	CA-2013-103919	TP-21565	FUR-FU-10001756	75051	2015-10-04	38.08	5	0.60	-29.51	2
43743	US-2012-168914	JE-15745	OFF-AP-10000358	60423	2014-05-21	20.77	8	0.80	-52.96	2
43744	US-2013-165078	MA-17995	OFF-AR-10002987	46226	2015-11-06	39.68	2	0.00	16.27	2
43745	CA-2014-136539	GH-14665	FUR-BO-10004709	78664	2016-12-28	78.85	2	0.32	-11.60	2
43746	CA-2014-137449	ME-17725	OFF-AP-10000240	75220	2016-06-29	21.39	2	0.80	-54.55	4
43747	CA-2012-130792	RA-19915	OFF-AP-10000696	77095	2014-04-28	8.65	3	0.80	-20.33	2
43748	CA-2011-168368	GA-14725	OFF-BI-10004728	65203	2013-02-11	9.64	2	0.00	4.43	1
43749	CA-2013-102813	EA-14035	OFF-PA-10000520	77340	2015-07-03	41.47	8	0.20	14.52	4
43750	CA-2013-168081	CA-12055	TEC-AC-10003174	77070	2015-04-25	258.70	3	0.20	64.67	1
43751	CA-2012-131352	GH-14485	FUR-FU-10003708	75081	2014-10-08	72.78	3	0.60	-70.96	2
43752	CA-2013-156748	BS-11755	OFF-PA-10002713	48227	2015-12-01	13.76	2	0.00	6.33	2
43753	US-2013-104815	RB-19570	FUR-BO-10003894	60610	2015-09-04	198.74	4	0.30	0.00	2
43754	CA-2013-123540	DJ-13420	FUR-CH-10000847	53209	2015-04-03	1454.90	5	0.00	378.27	1
43755	CA-2013-158568	RB-19465	OFF-BI-10002609	60610	2015-08-30	1.79	3	0.80	-3.04	2
43756	US-2014-108245	SH-19975	OFF-EN-10001415	77581	2016-09-22	13.39	3	0.20	5.02	2
43757	CA-2011-166191	DK-13150	OFF-ST-10003455	62521	2013-12-05	24.82	2	0.20	1.86	1
43758	CA-2014-162691	AS-10045	TEC-MA-10000488	78745	2016-08-01	1439.98	3	0.40	-264.00	2
43759	CA-2013-119186	MS-17710	TEC-AC-10000580	76106	2015-05-27	63.99	1	0.20	-7.20	3
43760	CA-2013-124506	BB-11545	TEC-AC-10003280	60623	2015-11-12	95.97	4	0.20	1.20	2
43761	CA-2012-124107	BM-11650	OFF-AP-10003971	48104	2014-10-09	29.40	3	0.10	5.23	1
43762	CA-2012-124107	BM-11650	TEC-PH-10003875	48104	2014-10-09	29.16	3	0.00	8.46	1
43763	CA-2011-127383	CM-11815	OFF-EN-10004773	79907	2013-12-31	49.57	2	0.20	17.97	2
43764	US-2014-130953	RF-19735	OFF-AP-10002311	73120	2016-07-29	137.62	2	0.00	60.55	2
43765	CA-2013-134425	QJ-19255	TEC-PH-10003555	55106	2015-12-09	114.95	5	0.00	2.30	1
43766	US-2011-157070	QJ-19255	OFF-BI-10001765	48234	2013-06-01	138.56	4	0.00	66.51	2
43767	CA-2014-158344	CC-12475	TEC-AC-10002006	56560	2016-08-07	63.96	4	0.00	19.83	2
43768	CA-2013-152765	LS-17245	OFF-PA-10000483	77036	2015-06-16	173.49	7	0.20	54.22	4
43769	CA-2014-151750	JM-15250	OFF-ST-10002743	77340	2016-01-02	454.56	5	0.20	-107.96	2
43770	US-2014-167402	CP-12085	OFF-SU-10002881	65807	2016-01-14	4164.05	5	0.00	83.28	1
43771	CA-2013-168956	EA-14035	OFF-PA-10000809	60623	2015-02-16	5.18	1	0.20	1.81	2
43772	US-2011-160444	DC-12850	OFF-ST-10001522	77036	2013-07-05	220.78	3	0.20	-44.16	3
43773	US-2013-111563	SM-20005	FUR-FU-10002445	77041	2015-11-05	11.38	3	0.60	-5.69	2
43774	CA-2013-167584	LC-16870	OFF-PA-10000029	50315	2015-08-13	6.48	1	0.00	3.11	3
43775	CA-2012-109113	EK-13795	TEC-AC-10004761	60610	2014-12-19	25.49	2	0.20	4.78	2
43776	CA-2014-163860	LO-17170	FUR-FU-10001935	61604	2016-12-28	2.96	2	0.60	-1.41	2
43777	CA-2014-105144	SZ-20035	OFF-LA-10003923	75051	2016-11-04	23.68	2	0.20	8.88	2
43778	CA-2012-148859	FH-14350	OFF-ST-10004950	60623	2014-12-28	24.82	2	0.20	1.55	2
43779	CA-2013-115378	AJ-10945	FUR-CH-10000863	48180	2015-11-19	301.96	2	0.00	33.22	1
43780	CA-2014-152499	EH-13765	OFF-AR-10003481	60623	2016-01-23	7.87	3	0.20	0.89	1
43781	CA-2011-166191	DK-13150	TEC-AC-10004659	62521	2013-12-05	408.74	7	0.20	76.64	1
43782	CA-2014-119452	CL-12565	FUR-CH-10004495	74133	2016-03-21	1805.88	6	0.00	523.71	2
43783	CA-2013-149685	PM-19135	OFF-LA-10004545	78207	2015-10-09	60.14	6	0.20	20.30	2
43784	CA-2012-163181	AB-10105	OFF-AR-10001683	77041	2014-11-07	23.64	3	0.20	5.32	2
43785	CA-2011-165309	KD-16270	OFF-AR-10003582	77095	2013-11-11	67.56	3	0.20	6.76	2
43786	CA-2014-152485	JD-15790	OFF-AR-10003759	75019	2016-09-04	10.19	7	0.20	3.19	2
43787	US-2014-125647	LC-16870	OFF-AP-10000390	60653	2016-09-23	73.18	6	0.80	-197.58	2
43788	CA-2011-103527	CC-12220	OFF-PA-10001622	60653	2013-09-09	10.90	3	0.20	3.41	1
43789	CA-2011-127446	MC-17590	OFF-PA-10000955	76017	2013-11-25	15.70	3	0.20	5.10	2
43790	CA-2014-129833	HF-14995	OFF-PA-10000575	46203	2016-12-09	33.45	5	0.00	15.39	2
43791	CA-2012-120901	BG-11035	OFF-SU-10001225	78745	2014-12-31	5.89	2	0.20	-1.32	2
43792	CA-2014-126396	AR-10345	TEC-AC-10003116	77070	2016-09-08	85.20	6	0.20	20.24	1
43793	CA-2014-111332	NC-18340	OFF-AR-10001374	58103	2016-05-20	25.92	4	0.00	8.29	1
43794	CA-2014-160927	TM-21010	OFF-ST-10001590	52302	2016-01-30	13.48	1	0.00	3.50	1
43795	CA-2013-140634	HL-15040	OFF-EN-10001099	77095	2015-10-04	15.65	2	0.20	5.09	1
43796	CA-2013-159373	LT-17110	OFF-PA-10000659	78207	2015-03-14	70.08	5	0.20	24.53	2
43797	CA-2011-163468	JK-15730	FUR-TA-10002533	60016	2013-11-18	292.10	4	0.50	-175.26	4
43798	CA-2013-134887	TB-21280	TEC-AC-10003832	73071	2015-03-26	1287.45	5	0.00	244.62	3
43799	CA-2011-167927	XP-21865	OFF-BI-10004364	48185	2013-01-20	29.70	5	0.00	13.37	2
43800	CA-2014-152583	RA-19945	FUR-TA-10002041	75217	2016-10-30	251.01	2	0.30	-68.13	3
43801	US-2011-147704	SR-20740	OFF-BI-10001634	47401	2013-11-16	29.12	4	0.00	14.27	2
43802	CA-2014-162075	TT-21220	TEC-PH-10001557	77041	2016-03-18	537.54	7	0.20	47.04	2
43803	CA-2014-104388	DK-12835	TEC-PH-10002293	68025	2016-07-05	79.96	4	0.00	22.39	4
43804	CA-2011-120852	WB-21850	OFF-AP-10001563	75051	2013-12-20	19.43	2	0.80	-49.55	2
43805	CA-2014-139199	DK-12835	OFF-PA-10001293	48234	2016-12-09	12.96	2	0.00	6.22	2
43806	CA-2014-121559	HW-14935	TEC-AC-10001714	46203	2016-06-01	39.89	1	0.00	14.76	1
43807	CA-2011-168312	GW-14605	FUR-TA-10001866	77036	2013-03-01	376.51	3	0.30	-43.03	2
43808	CA-2012-124499	FM-14380	FUR-CH-10000513	48227	2014-10-09	389.97	3	0.00	35.10	2
43809	US-2014-119438	CD-11980	FUR-FU-10003553	75701	2016-03-18	82.52	3	0.60	-41.26	2
43810	CA-2014-127026	MH-18115	TEC-AC-10002049	49201	2016-01-22	619.95	5	0.00	111.59	2
43811	CA-2012-136805	NM-18445	FUR-FU-10003724	48234	2014-05-23	75.33	9	0.00	19.59	1
43812	US-2012-128587	HM-14860	FUR-FU-10003026	65807	2014-12-24	9.68	2	0.00	3.78	2
43813	CA-2014-126956	GT-14710	OFF-FA-10002280	55044	2016-08-21	35.00	7	0.00	16.80	2
43814	CA-2011-163468	JK-15730	OFF-ST-10000025	60016	2013-11-18	381.72	5	0.20	-66.80	4
43815	CA-2014-147207	TS-21655	OFF-AR-10001955	79907	2016-01-03	31.74	2	0.20	3.97	1
43816	CA-2014-152093	SN-20560	OFF-BI-10003527	60653	2016-09-10	762.59	3	0.80	-1143.89	2
43817	CA-2012-107083	BB-11545	OFF-BI-10002194	76106	2014-11-21	7.98	5	0.80	-13.17	2
43818	CA-2013-162082	JS-15880	FUR-BO-10004409	78550	2015-03-15	241.33	5	0.32	-14.20	4
43819	CA-2014-131254	NC-18415	OFF-AR-10003876	77095	2016-11-19	13.04	5	0.20	3.91	4
43820	CA-2014-144491	CJ-12010	TEC-AC-10004901	77070	2016-03-27	39.99	1	0.20	7.00	2
43821	CA-2013-115756	PK-19075	OFF-ST-10000060	48227	2015-09-06	194.94	3	0.00	23.39	1
43822	US-2011-129609	VM-21835	OFF-AR-10003478	46368	2013-03-22	16.28	2	0.00	6.51	3
43823	CA-2013-152170	FH-14275	OFF-PA-10001763	46350	2015-11-13	19.98	2	0.00	8.99	1
43824	CA-2012-168088	CM-12655	FUR-BO-10004218	77041	2014-03-19	383.47	4	0.32	-67.67	4
43825	US-2013-105452	BF-11005	FUR-FU-10003691	77506	2015-07-29	24.70	5	0.60	-9.88	2
43826	CA-2012-128125	EB-13705	OFF-PA-10000357	77095	2014-03-31	98.38	3	0.20	35.66	2
43827	CA-2011-142314	SF-20200	OFF-AP-10002350	47374	2013-12-23	207.24	11	0.00	58.03	2
43828	CA-2011-111899	NC-18340	OFF-AR-10001725	77036	2013-05-04	37.84	2	0.20	2.84	4
43829	CA-2013-114104	NP-18670	TEC-PH-10004536	73034	2015-11-21	944.93	7	0.00	236.23	2
43830	CA-2014-137596	BE-11335	TEC-AC-10004666	49201	2016-09-02	1928.78	7	0.00	829.38	2
43831	CA-2014-124940	DK-13090	TEC-AC-10002076	75007	2016-02-22	47.90	1	0.20	-2.99	2
43832	CA-2013-156251	TS-21160	FUR-BO-10001337	53214	2015-08-14	241.96	2	0.00	24.20	1
43833	US-2011-104759	DD-13570	OFF-BI-10002071	60610	2013-03-31	8.13	7	0.80	-13.83	2
43834	CA-2014-128328	PO-18865	OFF-LA-10003498	46203	2016-08-05	133.20	9	0.00	66.60	2
43835	CA-2013-108987	AG-10675	OFF-ST-10001580	77036	2015-09-09	35.95	3	0.20	3.60	1
43836	CA-2012-127509	AS-10090	OFF-EN-10000781	65807	2014-11-09	26.22	3	0.00	12.32	2
43837	CA-2014-133102	ED-13885	FUR-FU-10003247	77095	2016-08-17	16.78	2	0.60	-22.24	2
43838	US-2012-128587	HM-14860	TEC-CO-10003763	65807	2014-12-24	4899.93	7	0.00	2302.97	2
43839	CA-2013-152457	SC-20695	OFF-PA-10003790	48066	2015-09-13	68.52	3	0.00	31.52	2
43840	US-2014-119662	CS-12400	OFF-ST-10003656	60623	2016-11-13	230.38	3	0.20	-48.95	4
43841	CA-2014-151750	JM-15250	FUR-CH-10003199	77340	2016-01-02	310.74	4	0.30	-26.64	2
43842	CA-2012-168480	DM-12955	FUR-BO-10000468	48146	2014-09-21	194.32	4	0.00	31.09	2
43843	US-2012-163433	MP-17965	FUR-CH-10000225	78501	2014-04-18	56.69	1	0.30	-20.25	1
43844	CA-2013-113390	EP-13915	OFF-AR-10001446	60610	2015-10-12	27.72	3	0.20	3.47	2
43845	CA-2013-155992	CC-12220	FUR-FU-10003724	46350	2015-10-02	41.85	5	0.00	10.88	4
43846	CA-2011-135405	MS-17830	OFF-AR-10004078	78041	2013-01-09	9.34	2	0.20	1.17	2
43847	CA-2014-135034	AT-10735	TEC-PH-10003931	60653	2016-08-01	95.98	2	0.20	6.00	4
43848	CA-2012-140025	PF-19120	OFF-AP-10002651	78207	2014-04-07	463.25	8	0.80	-1181.28	2
43849	US-2012-130491	BH-11710	OFF-FA-10000134	67846	2014-02-08	5.81	1	0.00	1.80	4
43850	CA-2014-104220	BV-11245	OFF-BI-10003910	50315	2016-01-31	7.71	1	0.00	3.47	2
43851	CA-2014-134194	GA-14725	OFF-BI-10001597	75081	2016-12-25	40.98	5	0.80	-65.57	2
43852	US-2014-144582	TC-21475	OFF-BI-10001575	61832	2016-04-30	43.37	7	0.80	-69.40	2
43853	CA-2014-135307	LS-17245	FUR-FU-10001290	64118	2016-11-26	126.30	3	0.00	40.42	4
43854	CA-2012-143147	PS-18760	FUR-CH-10000863	78207	2014-05-26	105.69	1	0.30	-28.69	1
43855	CA-2013-163153	DM-12955	OFF-AR-10001868	77036	2015-03-22	1.34	1	0.20	0.50	2
43856	US-2013-100461	JO-15145	FUR-BO-10002545	53132	2015-01-08	1565.88	6	0.00	407.13	2
43857	CA-2013-122903	LA-16780	OFF-PA-10001790	48205	2015-05-28	144.12	3	0.00	69.18	1
43858	US-2011-130379	JL-15235	OFF-AP-10001394	60623	2013-05-25	75.60	2	0.80	-166.32	2
43859	CA-2014-141782	BE-11410	OFF-EN-10002230	60505	2016-01-22	268.58	4	0.20	90.64	2
43860	CA-2012-113901	NH-18610	OFF-BI-10001249	48227	2014-10-19	38.28	6	0.00	17.61	2
43861	US-2011-141215	KL-16555	FUR-CH-10003379	78207	2013-06-15	797.94	4	0.30	-57.00	2
43862	US-2013-143448	MH-17455	FUR-CH-10003379	46142	2015-12-11	1424.90	5	0.00	356.23	3
43863	CA-2013-103128	SC-20845	OFF-AR-10003394	60004	2015-11-12	14.11	6	0.20	1.23	2
43864	US-2012-164308	SC-20680	TEC-PH-10004120	74012	2014-09-24	821.94	6	0.00	213.70	4
43865	CA-2014-103478	KL-16555	OFF-BI-10001890	60505	2016-07-21	2.86	4	0.80	-4.58	1
43866	CA-2014-131254	NC-18415	OFF-BI-10003527	77095	2016-11-19	1525.19	6	0.80	-2287.78	4
43867	CA-2013-167290	JF-15295	OFF-AR-10004078	48310	2015-10-31	11.68	2	0.00	3.50	2
43868	CA-2012-141243	AH-10465	TEC-AC-10003198	75217	2014-01-03	398.40	5	0.20	84.66	1
43869	CA-2012-107083	BB-11545	OFF-AR-10002257	76106	2014-11-21	5.34	2	0.20	0.73	2
43870	CA-2014-151750	JM-15250	OFF-BI-10000301	77340	2016-01-02	6.47	5	0.80	-9.71	2
43871	CA-2012-151589	RE-19450	TEC-PH-10004345	54703	2014-12-27	239.90	2	0.00	71.97	4
43872	CA-2011-120775	RD-19930	OFF-FA-10000254	75217	2013-10-03	15.07	4	0.20	-3.77	2
43873	CA-2011-104738	SP-20620	OFF-EN-10004955	78041	2013-12-30	12.98	3	0.20	4.71	1
43874	CA-2011-116904	SC-20095	OFF-BI-10000301	55407	2013-09-23	12.94	2	0.00	6.47	2
43875	CA-2011-168368	GA-14725	FUR-CH-10001146	65203	2013-02-11	60.89	1	0.00	15.22	1
43876	CA-2014-113075	MC-18100	TEC-AC-10003441	60623	2016-09-02	40.68	3	0.20	-7.12	2
43877	CA-2011-104738	SP-20620	OFF-BI-10002160	78041	2013-12-30	2.29	3	0.80	-3.66	1
43878	CA-2014-167381	EH-14005	FUR-BO-10001972	48911	2016-09-22	241.96	2	0.00	41.13	1
43879	US-2014-156356	ND-18370	OFF-ST-10002301	77095	2016-04-16	32.54	2	0.20	-7.73	2
43880	CA-2014-113278	HR-14770	OFF-FA-10003472	47374	2016-01-15	2.52	2	0.00	0.10	2
43881	CA-2014-104220	BV-11245	OFF-BI-10001036	50315	2016-01-31	18.28	2	0.00	9.14	2
43882	CA-2014-141439	TT-21460	FUR-CH-10004287	47374	2016-11-26	828.60	3	0.00	240.29	2
43883	CA-2013-124681	SV-20935	TEC-AC-10000487	75217	2015-07-19	15.58	3	0.20	3.31	1
43884	CA-2013-103982	AA-10315	OFF-SU-10000151	78664	2015-03-04	3930.07	3	0.20	-786.01	2
43885	CA-2012-129476	PA-19060	TEC-AC-10000844	60462	2014-10-15	339.96	5	0.20	67.99	2
43886	CA-2014-110905	RW-19690	OFF-PA-10002586	65807	2016-09-10	24.90	5	0.00	11.70	1
43887	CA-2014-164098	CG-12520	OFF-ST-10000615	77070	2016-01-27	18.16	2	0.20	1.82	4
43888	CA-2013-157749	KL-16645	TEC-PH-10000011	60610	2015-06-05	31.98	2	0.20	11.19	1
43889	CA-2014-107629	DB-13060	FUR-FU-10002298	60076	2016-12-14	266.35	6	0.60	-292.99	3
43890	US-2013-127971	DW-13195	FUR-CH-10003774	77095	2015-11-21	318.43	5	0.30	-77.33	2
43891	CA-2012-120901	BG-11035	OFF-FA-10001561	78745	2014-12-31	3.49	2	0.20	0.57	2
43892	CA-2013-151141	DW-13480	TEC-PH-10004924	48205	2015-08-21	14.78	2	0.00	3.99	4
43893	CA-2014-131618	LS-17200	OFF-BI-10001294	60076	2016-06-17	9.36	4	0.80	-16.38	4
43894	CA-2014-160927	TM-21010	OFF-PA-10000176	52302	2016-01-30	94.85	5	0.00	45.53	1
43895	CA-2011-124478	MA-17560	FUR-FU-10002088	48183	2013-08-08	53.88	6	0.00	22.63	2
43896	CA-2014-144491	CJ-12010	FUR-CH-10001714	77070	2016-03-27	211.25	2	0.30	-66.39	2
43897	CA-2013-153577	KH-16330	FUR-CH-10003981	60035	2015-06-28	539.66	3	0.30	-7.71	2
43898	CA-2012-146675	SB-20185	TEC-CO-10001766	60201	2014-04-16	1439.97	4	0.20	485.99	2
43899	CA-2011-162089	MP-17470	OFF-EN-10002230	78521	2013-03-30	335.72	5	0.20	113.31	4
43900	CA-2013-160220	JS-16030	OFF-ST-10000617	48183	2015-10-21	20.86	7	0.00	1.46	2
43901	CA-2011-167997	CA-11965	OFF-BI-10001758	57701	2013-01-26	10.68	2	0.00	5.02	4
43902	CA-2013-106915	GA-14515	OFF-AR-10000716	79907	2015-11-27	17.86	4	0.20	4.24	2
43903	CA-2014-169285	RW-19690	OFF-PA-10004071	47905	2016-03-21	277.40	5	0.00	133.15	2
43904	CA-2013-123932	YC-21895	OFF-PA-10004665	75217	2015-09-07	41.92	4	0.20	15.20	2
43905	CA-2013-147109	AH-10075	OFF-PA-10001972	76017	2015-12-18	51.84	10	0.20	18.14	2
43906	CA-2014-121160	FM-14290	OFF-BI-10001308	77803	2016-11-04	7.54	6	0.80	-13.19	3
43907	CA-2013-132829	LA-16780	TEC-PH-10004345	77041	2015-12-24	287.88	3	0.20	35.99	1
43908	CA-2012-145401	JP-15520	OFF-PA-10004405	77070	2014-01-30	14.30	6	0.20	5.01	2
43909	CA-2013-133550	KL-16645	TEC-PH-10001079	48205	2015-08-01	118.99	1	0.00	33.32	2
43910	CA-2013-167682	ZD-21925	FUR-FU-10003799	47374	2015-04-04	71.12	4	0.00	22.05	2
43911	CA-2014-141789	AC-10450	OFF-BI-10001359	55407	2016-10-03	1793.98	2	0.00	843.17	4
43912	US-2014-141677	HK-14890	TEC-AC-10000158	77070	2016-03-26	143.96	5	0.20	1.80	2
43913	CA-2011-116904	SC-20095	OFF-BI-10001120	55407	2013-09-23	9449.95	5	0.00	4630.48	2
43914	US-2014-141677	HK-14890	OFF-AP-10001205	77070	2016-03-26	87.17	8	0.80	-226.64	2
43915	CA-2013-139234	AF-10870	TEC-AC-10004510	60610	2015-05-07	26.18	2	0.20	-3.27	2
43916	CA-2013-144645	NS-18640	FUR-FU-10003601	77041	2015-02-02	73.78	2	0.60	-77.47	2
43917	US-2013-116365	CA-12310	TEC-AC-10002217	78207	2015-01-03	30.08	2	0.20	-5.26	2
43918	CA-2013-159373	LT-17110	OFF-BI-10004141	78207	2015-03-14	1.27	2	0.80	-2.16	2
43919	CA-2013-157868	MC-17590	OFF-FA-10000992	49505	2015-12-24	24.85	7	0.00	11.68	2
43920	CA-2013-112256	CK-12205	OFF-AR-10001216	78501	2015-07-24	4.45	2	0.20	0.33	2
43921	CA-2012-105627	DK-12895	FUR-CH-10002084	53142	2014-03-08	860.93	7	0.00	189.40	2
43922	US-2012-122140	MO-17950	TEC-AC-10003038	75220	2014-04-02	50.12	7	0.20	-0.63	2
43923	CA-2013-164770	MY-18295	FUR-BO-10003893	77036	2015-12-03	781.86	10	0.32	-137.98	1
43924	CA-2011-142510	NP-18700	OFF-BI-10002824	60623	2013-12-22	17.90	6	0.80	-31.33	2
43925	CA-2014-140242	ML-17755	TEC-AC-10004659	60623	2016-05-06	408.74	7	0.20	76.64	2
43926	CA-2013-168956	EA-14035	FUR-CH-10004754	60623	2015-02-16	62.96	3	0.30	-2.70	2
43927	CA-2012-129112	AW-10840	OFF-BI-10000088	75002	2014-11-29	8.78	4	0.80	-13.62	4
43928	US-2012-164175	PS-18970	FUR-CH-10001146	60610	2014-04-30	213.12	5	0.30	-15.22	2
43929	US-2014-167402	CP-12085	OFF-PA-10004983	65807	2016-01-14	32.40	5	0.00	15.55	1
43930	CA-2011-133228	MS-17710	FUR-FU-10004020	48205	2013-04-04	5.47	1	0.00	2.35	2
43931	CA-2013-138597	PN-18775	FUR-CH-10004997	68104	2015-12-19	563.94	3	0.00	112.79	4
43932	CA-2014-163188	EC-14050	OFF-BI-10000756	73120	2016-11-07	38.16	9	0.00	19.08	3
43933	CA-2013-104150	AG-10330	TEC-AC-10004803	74133	2015-08-04	167.28	12	0.00	23.42	1
43934	CA-2011-129189	HM-14860	FUR-CH-10004997	75217	2013-07-21	657.93	5	0.30	-93.99	2
43935	CA-2013-134691	KC-16540	OFF-BI-10002393	77041	2015-11-15	2.30	2	0.80	-3.90	2
43936	CA-2013-117919	TB-21355	OFF-PA-10004353	77041	2015-08-28	79.92	5	0.20	27.97	1
43937	CA-2014-154410	MD-17860	OFF-ST-10002743	46203	2016-10-21	909.12	8	0.00	9.09	4
43938	CA-2013-116526	JA-15970	TEC-PH-10002365	48227	2015-09-02	8.78	1	0.00	2.28	2
43939	CA-2013-112256	CK-12205	OFF-PA-10004355	78501	2015-07-24	5.18	1	0.20	1.81	2
43940	CA-2014-144064	CP-12085	OFF-ST-10004507	62301	2016-08-29	27.44	2	0.20	2.40	4
43941	US-2013-115952	JH-15910	OFF-BI-10004654	74133	2015-10-07	28.85	5	0.00	14.43	3
43942	CA-2012-160472	RK-19300	OFF-EN-10000483	46614	2014-07-20	106.75	7	0.00	49.11	1
43943	CA-2013-128517	SW-20350	OFF-BI-10000831	48227	2015-04-10	5.28	2	0.00	2.43	1
43944	CA-2014-146360	SC-20305	TEC-AC-10003590	46226	2016-04-23	155.34	6	0.00	55.92	1
43945	CA-2012-114468	TD-20995	OFF-SU-10004231	60440	2014-08-23	31.68	4	0.20	2.77	3
43946	CA-2012-115742	DP-13000	FUR-FU-10001706	47150	2014-04-18	6.16	2	0.00	2.96	2
43947	US-2013-100419	CC-12670	OFF-BI-10002194	60610	2015-12-17	4.79	3	0.80	-7.90	1
43948	CA-2011-163468	JK-15730	FUR-FU-10001546	60016	2013-11-18	8.54	2	0.60	-7.48	4
43949	CA-2011-138023	KH-16510	OFF-BI-10003638	75081	2013-08-15	30.96	8	0.80	-52.63	4
43950	US-2011-117744	MD-17860	OFF-AR-10000940	78415	2013-12-02	16.46	7	0.20	1.44	2
43951	US-2011-152723	HG-14965	OFF-BI-10003460	75150	2013-09-26	0.88	1	0.80	-1.40	3
43952	CA-2014-145142	MC-17605	FUR-TA-10001857	48234	2016-01-24	210.98	2	0.00	21.10	4
43953	US-2011-119081	TA-21385	FUR-FU-10003464	66062	2013-09-12	40.56	2	0.00	12.98	2
43954	CA-2011-146283	KT-16465	OFF-PA-10000482	77036	2013-09-08	182.11	6	0.20	61.46	2
43955	CA-2013-128531	NS-18505	TEC-AC-10003023	75217	2015-11-25	94.99	2	0.20	-2.37	1
43956	US-2012-138121	JL-15835	FUR-CH-10003817	48205	2014-12-17	546.66	9	0.00	136.67	3
43957	CA-2012-110324	MA-17560	OFF-PA-10001776	49201	2014-12-01	18.54	2	0.00	8.71	2
43958	CA-2014-164042	KL-16645	OFF-FA-10000840	77095	2016-05-23	1.82	2	0.20	0.62	2
43959	CA-2014-121790	LP-17095	FUR-TA-10003469	60505	2016-01-31	69.38	1	0.50	-47.18	2
43960	CA-2013-120824	AW-10930	OFF-BI-10001525	77070	2015-06-13	1.52	2	0.80	-2.67	1
43961	US-2012-155369	PG-18820	OFF-AP-10002578	75007	2014-04-19	19.57	2	0.80	-52.83	2
43962	CA-2011-127166	KH-16360	OFF-BI-10000977	77070	2013-05-21	18.24	3	0.80	-31.01	1
43963	CA-2013-157000	AM-10360	OFF-PA-10001950	75051	2015-07-17	20.02	3	0.20	6.26	2
43964	CA-2013-118689	TC-20980	OFF-BI-10004600	47905	2015-10-03	735.98	2	0.00	331.19	2
43965	US-2014-102288	ZC-21910	OFF-AP-10002906	77095	2016-06-19	0.44	1	0.80	-1.11	2
43966	CA-2014-104745	GT-14755	OFF-ST-10002205	78550	2016-05-29	53.42	3	0.20	4.67	2
43967	US-2012-152128	NM-18445	OFF-BI-10001718	67212	2014-05-25	127.96	2	0.00	60.14	1
43968	CA-2014-117324	JP-15520	TEC-AC-10003023	53711	2016-12-08	178.11	3	0.00	32.06	2
43969	CA-2011-123225	MN-17935	TEC-PH-10000895	79907	2013-07-11	575.97	4	0.20	43.20	4
43970	CA-2014-127026	MH-18115	OFF-BI-10000546	49201	2016-01-22	14.40	5	0.00	7.06	2
43971	CA-2014-133102	ED-13885	FUR-CH-10002017	77095	2016-08-17	74.59	4	0.30	-2.13	2
43972	US-2014-167402	CP-12085	OFF-AR-10004010	65807	2016-01-14	209.94	6	0.00	54.58	1
43973	CA-2011-162089	MP-17470	FUR-CH-10002304	78521	2013-03-30	127.30	7	0.30	-9.09	4
43974	CA-2013-103982	AA-10315	TEC-AC-10002857	78664	2015-03-04	41.72	7	0.20	5.74	2
43975	CA-2012-109337	DL-13330	TEC-MA-10002930	46226	2014-11-21	83.90	2	0.00	22.65	1
43976	US-2012-100069	NF-18475	TEC-PH-10004667	68104	2014-06-29	269.98	2	0.00	72.89	2
43977	US-2014-126081	FC-14335	OFF-PA-10003953	75150	2016-06-29	5.18	1	0.20	1.81	2
43978	CA-2011-163468	JK-15730	OFF-BI-10004728	60016	2013-11-18	2.89	3	0.80	-4.92	4
43979	CA-2014-152583	RA-19945	FUR-FU-10003849	75217	2016-10-30	16.19	2	0.60	-8.50	3
43980	CA-2012-138009	SF-20965	OFF-ST-10001272	48126	2014-11-29	523.48	4	0.00	130.87	2
43981	CA-2014-151750	JM-15250	OFF-AR-10003158	77340	2016-01-02	12.74	4	0.20	2.23	2
43982	CA-2014-148992	CS-12250	OFF-PA-10004285	60623	2016-11-23	10.69	2	0.20	3.74	2
43983	CA-2014-161774	GT-14710	FUR-CH-10003981	77041	2016-05-14	899.43	5	0.30	-12.85	4
43984	CA-2013-140130	HW-14935	OFF-SU-10001218	74133	2015-11-01	21.96	2	0.00	6.15	2
43985	US-2014-130953	RF-19735	OFF-BI-10004828	73120	2016-07-29	33.48	2	0.00	16.41	2
43986	CA-2014-131282	CB-12025	OFF-AR-10003087	76706	2016-02-06	7.12	5	0.20	0.71	1
43987	CA-2012-118423	DP-13390	FUR-BO-10000362	61604	2014-03-24	359.06	3	0.30	-35.91	4
43988	CA-2013-137743	KH-16360	OFF-LA-10003663	60623	2015-07-31	9.25	4	0.20	3.12	2
43989	CA-2014-125269	AF-10870	OFF-BI-10001628	60610	2016-04-24	10.43	5	0.80	-18.25	2
43990	CA-2012-132941	MM-18280	OFF-SU-10002557	76117	2014-05-25	22.37	2	0.20	1.68	4
43991	US-2014-158218	AC-10420	OFF-ST-10000563	77041	2016-05-12	127.92	5	0.20	-15.99	1
43992	CA-2013-140935	AB-10015	FUR-BO-10003966	73120	2015-11-11	341.96	2	0.00	54.71	4
43993	US-2011-117744	MD-17860	FUR-FU-10002759	78415	2013-12-02	39.96	5	0.60	-23.98	2
43994	CA-2011-112326	PO-19195	OFF-BI-10004094	60540	2013-01-04	3.54	2	0.80	-5.49	2
43995	CA-2014-132290	MD-17350	FUR-TA-10002228	75217	2016-03-10	933.41	4	0.30	-173.35	2
43996	CA-2013-112739	RD-19810	OFF-BI-10001132	77070	2015-09-03	8.61	8	0.80	-13.34	1
43997	CA-2014-110373	MA-17560	TEC-PH-10001536	60610	2016-10-27	27.18	2	0.20	2.04	1
43998	US-2014-124779	BF-11020	OFF-PA-10000061	76017	2016-09-08	20.74	4	0.20	7.26	4
43999	US-2013-144057	CV-12805	OFF-AP-10000390	78745	2015-05-10	48.78	4	0.80	-131.72	2
44000	US-2012-159982	DR-12880	TEC-PH-10001580	60623	2014-11-28	647.90	6	0.20	56.69	2
44001	US-2014-104661	TB-21250	OFF-BI-10001597	78745	2016-01-16	32.78	4	0.80	-52.45	4
44002	CA-2011-104738	SP-20620	TEC-AC-10003628	78041	2013-12-30	47.98	2	0.20	14.40	1
44003	US-2013-160528	MH-18115	FUR-FU-10004973	78577	2015-08-24	22.61	3	0.60	-10.17	2
44004	US-2012-163433	MP-17965	OFF-BI-10003676	78501	2014-04-18	4.31	2	0.80	-6.90	1
44005	CA-2014-134439	TM-21010	OFF-PA-10004082	68801	2016-09-18	15.96	2	0.00	7.98	1
44006	CA-2014-141733	RW-19540	OFF-AP-10001563	48234	2016-05-07	87.44	2	0.10	18.46	2
44007	US-2013-140172	SP-20650	OFF-AP-10004233	49201	2015-03-09	207.14	3	0.10	48.33	2
44008	CA-2014-132682	TH-21235	OFF-SU-10004231	75081	2016-06-08	23.76	3	0.20	2.08	1
44009	CA-2013-124352	CD-12790	OFF-LA-10004559	73120	2015-10-16	20.16	7	0.00	9.88	2
44010	CA-2014-136539	GH-14665	OFF-AR-10001958	78664	2016-12-28	27.17	2	0.20	2.72	2
44011	US-2011-140452	BK-11260	TEC-PH-10000307	60610	2013-12-06	35.04	4	0.20	-7.01	2
44012	CA-2012-121650	KD-16495	FUR-TA-10003569	49201	2014-12-10	801.96	2	0.00	200.49	2
44013	CA-2013-133697	CM-12445	OFF-FA-10003112	77095	2015-10-21	25.25	4	0.20	7.89	1
44014	CA-2014-117114	CY-12745	TEC-PH-10004042	60610	2016-10-31	508.77	4	0.20	38.16	2
44015	CA-2012-154326	RP-19855	TEC-PH-10000560	53142	2014-02-15	699.98	2	0.00	195.99	2
44016	CA-2013-109400	NR-18550	FUR-CH-10003298	79109	2015-05-03	366.74	4	0.30	-110.02	2
44017	CA-2013-130400	SJ-20125	TEC-AC-10004633	75217	2015-03-09	27.96	5	0.20	8.39	2
44018	CA-2014-144491	CJ-12010	FUR-CH-10004063	77070	2016-03-27	600.56	3	0.30	-8.58	2
44019	CA-2013-154018	HA-14920	OFF-PA-10000551	78041	2015-10-14	8.29	2	0.20	3.00	2
44020	CA-2012-143077	SF-20965	OFF-BI-10000088	77041	2014-09-17	6.59	3	0.80	-10.21	2
44021	US-2012-163433	MP-17965	TEC-AC-10003590	78501	2014-04-18	41.42	2	0.20	8.28	1
44022	CA-2012-135391	FA-14230	OFF-LA-10001074	78207	2014-02-09	40.10	4	0.20	13.53	1
44023	CA-2014-126123	AG-10765	OFF-BI-10000309	60623	2016-10-14	27.40	9	0.80	-42.46	2
44024	CA-2014-110905	RW-19690	TEC-AC-10002217	65807	2016-09-10	112.80	6	0.00	6.77	1
44025	CA-2014-167227	NP-18670	OFF-AP-10001962	63116	2016-11-02	83.90	10	0.00	20.98	4
44026	CA-2012-153073	HA-14905	FUR-FU-10001025	60610	2014-11-13	17.50	9	0.60	-7.44	3
44027	CA-2013-147256	FC-14245	TEC-PH-10003072	65203	2015-10-18	449.97	3	0.00	220.49	1
44028	CA-2013-130393	JM-15865	FUR-CH-10002647	76903	2015-12-02	248.43	5	0.30	-17.75	1
44029	CA-2014-121790	LP-17095	OFF-AR-10003602	60505	2016-01-31	9.34	2	0.20	3.15	2
44030	CA-2012-105613	KN-16705	TEC-AC-10000521	78501	2014-10-18	27.70	3	0.20	3.46	2
44031	CA-2014-147753	PK-19075	OFF-LA-10003537	53209	2016-03-05	25.06	2	0.00	11.78	3
44032	CA-2013-142524	MB-18085	TEC-AC-10000109	65807	2015-09-05	279.95	5	0.00	67.19	2
44033	CA-2014-111178	TD-20995	OFF-AR-10001954	62301	2016-06-15	19.56	5	0.20	1.71	2
44034	US-2011-151015	BD-11500	OFF-PA-10002581	60653	2013-10-14	322.19	13	0.20	100.69	2
44035	CA-2014-164168	LS-16975	OFF-EN-10001219	75081	2016-11-12	12.22	2	0.20	4.43	2
44036	CA-2012-158939	EA-14035	TEC-CO-10002313	65807	2014-11-26	599.99	1	0.00	234.00	2
44037	CA-2011-163034	DK-12985	OFF-ST-10000046	60610	2013-11-24	646.20	5	0.20	-8.08	2
44038	US-2014-148551	DB-13120	OFF-BI-10000545	75217	2016-01-13	760.98	5	0.80	-1141.47	2
44039	CA-2014-119746	CM-12385	FUR-FU-10004909	60610	2016-11-23	6.46	1	0.60	-4.04	2
44040	CA-2014-152926	SC-20695	OFF-AP-10001947	77041	2016-10-02	21.98	6	0.80	-56.06	1
44041	CA-2013-123722	NH-18610	OFF-LA-10001569	75061	2015-09-26	15.94	4	0.20	5.18	2
44042	CA-2013-108868	KB-16585	OFF-AR-10001953	75081	2015-09-09	70.37	2	0.20	6.16	2
44043	CA-2013-141551	BP-11230	OFF-BI-10001249	74012	2015-09-25	6.38	1	0.00	2.93	2
44044	CA-2014-163265	JS-16030	OFF-FA-10004854	62521	2016-02-17	18.37	2	0.20	6.20	2
44045	CA-2014-130351	RB-19570	OFF-PA-10002137	47201	2016-12-05	38.90	5	0.00	17.51	4
44046	US-2013-160528	MH-18115	TEC-AC-10002842	78577	2015-08-24	666.40	7	0.20	-33.32	2
44047	CA-2013-132829	LA-16780	OFF-LA-10002945	77041	2015-12-24	45.36	9	0.20	14.74	1
44048	US-2013-111290	DK-13375	OFF-ST-10001932	48185	2015-07-23	965.85	5	0.00	135.22	2
44049	CA-2012-135853	CA-12775	OFF-BI-10004965	48205	2014-12-11	23.00	2	0.00	10.35	4
44050	US-2011-147704	SR-20740	OFF-ST-10000675	47401	2013-11-16	169.45	5	0.00	42.36	2
44051	CA-2011-166863	SC-20020	OFF-BI-10000756	75023	2013-06-20	3.39	4	0.80	-5.09	2
44052	US-2013-117037	LW-17215	OFF-BI-10000279	60653	2015-05-18	2.89	1	0.80	-4.77	4
44053	CA-2012-100685	SM-20950	OFF-PA-10001289	68104	2014-12-19	116.28	3	0.00	56.98	1
44054	CA-2014-146724	HG-15025	OFF-AR-10001026	55044	2016-11-20	22.00	10	0.00	9.68	2
44055	CA-2013-155551	CR-12580	OFF-ST-10003656	60126	2015-04-19	230.38	3	0.20	-48.95	2
44056	CA-2011-133753	CW-11905	TEC-AC-10000303	77340	2013-06-09	63.98	2	0.20	10.40	1
44057	CA-2011-162362	JL-15505	OFF-BI-10000546	48640	2013-11-14	11.52	4	0.00	5.64	2
44058	CA-2014-106068	RB-19330	OFF-BI-10000962	78745	2016-10-23	9.76	3	0.80	-15.13	2
44059	CA-2011-137092	LS-16975	OFF-ST-10003805	60653	2013-10-20	505.32	3	0.20	31.58	1
44060	CA-2011-116757	MS-17980	OFF-PA-10002005	77095	2013-06-30	25.92	5	0.20	9.07	2
44061	CA-2012-135685	MP-18175	FUR-TA-10001520	53209	2014-11-16	214.11	3	0.00	36.40	1
44062	US-2013-120460	BF-11170	FUR-FU-10004973	75081	2015-05-01	22.61	3	0.60	-10.17	2
44063	CA-2012-124541	TT-21220	OFF-BI-10004965	77041	2014-04-06	6.90	3	0.80	-12.08	2
44064	CA-2014-112809	RA-19915	OFF-ST-10002276	75220	2016-08-18	200.06	3	0.20	12.50	2
44065	CA-2014-135111	CS-12400	OFF-BI-10004040	58103	2016-12-28	25.90	5	0.00	12.69	2
44066	CA-2014-100223	LS-16945	OFF-PA-10002195	75220	2016-07-05	31.10	6	0.20	11.28	2
44067	CA-2014-124114	RS-19765	OFF-BI-10004022	76706	2016-03-02	0.56	1	0.80	-0.95	3
44068	CA-2012-154284	SZ-20035	FUR-FU-10003039	60174	2014-12-21	51.76	3	0.60	-33.64	1
44069	CA-2014-141439	TT-21460	FUR-TA-10001039	47374	2016-11-26	257.94	3	0.00	67.06	2
44070	CA-2012-166583	VD-21670	TEC-PH-10001578	77070	2014-06-26	971.88	3	0.20	109.34	2
44071	CA-2012-157812	DB-13210	OFF-BI-10000285	77041	2014-03-22	14.11	9	0.80	-21.17	2
44072	CA-2013-119963	SN-20710	OFF-LA-10003510	77506	2015-11-19	48.85	2	0.20	15.88	2
44073	CA-2012-115567	ZC-21910	FUR-CH-10000015	47201	2014-09-13	1516.20	7	0.00	394.21	2
44074	CA-2013-132479	MK-17905	OFF-BI-10004584	61107	2015-09-25	442.37	7	0.80	-729.91	4
44075	CA-2014-141705	PO-18850	FUR-TA-10004607	76063	2016-10-24	517.41	5	0.30	-81.31	4
44076	CA-2012-111948	AG-10495	OFF-ST-10003282	48234	2014-11-11	418.32	7	0.00	117.13	3
44077	US-2012-129637	MC-18100	OFF-AR-10003829	61701	2014-12-17	13.12	5	0.20	1.48	2
44078	US-2012-126235	GA-14725	FUR-FU-10000719	48858	2014-10-15	17.14	2	0.00	6.17	3
44079	CA-2013-133340	LH-17155	OFF-AP-10002311	49201	2015-12-10	61.93	1	0.10	23.40	2
44080	US-2014-139955	CM-12160	OFF-SU-10001935	78521	2016-09-28	1.74	1	0.20	-0.35	1
44081	CA-2012-105627	DK-12895	FUR-FU-10000308	53142	2014-03-08	373.08	6	0.00	82.08	2
44082	US-2014-137491	LC-16930	FUR-CH-10004675	76903	2016-11-19	305.31	2	0.30	-8.72	2
44083	US-2012-164966	GH-14410	FUR-CH-10002304	55044	2014-07-30	155.88	6	0.00	38.97	4
44084	CA-2014-147207	TS-21655	FUR-TA-10002958	79907	2016-01-03	913.43	5	0.30	-169.64	1
44085	CA-2012-136728	AG-10900	OFF-EN-10002621	60623	2014-09-13	7.82	1	0.20	2.93	1
44086	CA-2014-168123	JD-16060	OFF-BI-10001071	55901	2016-03-05	127.96	2	0.00	62.70	3
44087	CA-2014-127656	NW-18400	OFF-AR-10001166	50701	2016-07-11	30.32	4	0.00	11.82	2
44088	US-2011-157070	QJ-19255	OFF-AP-10004859	48234	2013-06-01	65.52	5	0.10	12.38	2
44089	CA-2014-164168	LS-16975	TEC-AC-10004568	75081	2016-11-12	44.78	2	0.20	-0.56	2
44090	CA-2012-107083	BB-11545	OFF-BI-10000756	76106	2014-11-21	1.70	2	0.80	-2.54	2
44091	CA-2013-128923	GB-14530	OFF-AR-10000475	76106	2015-12-10	9.33	1	0.20	0.82	2
44092	CA-2011-137092	LS-16975	OFF-PA-10002109	60653	2013-10-20	3.81	1	0.20	1.24	1
44093	CA-2011-103849	PG-18895	TEC-PH-10002597	76106	2013-05-11	100.79	1	0.20	6.30	2
44094	CA-2011-158281	AG-10525	TEC-MA-10002210	77095	2013-09-02	559.71	3	0.40	-121.27	2
44095	US-2012-155369	PG-18820	OFF-BI-10003925	75007	2014-04-19	310.39	4	0.80	-512.15	2
44096	US-2011-147704	SR-20740	OFF-PA-10003270	47401	2013-11-16	31.68	6	0.00	14.26	2
44097	CA-2013-156685	SC-20230	TEC-PH-10004345	76017	2015-07-09	863.64	9	0.20	107.96	1
44098	CA-2012-120677	BD-11320	FUR-CH-10002320	55407	2014-05-31	2567.84	8	0.00	770.35	2
44099	US-2014-145597	GG-14650	OFF-AR-10001958	61701	2016-11-02	54.34	4	0.20	5.43	4
44100	US-2013-111563	SM-20005	FUR-FU-10000723	77041	2015-11-05	66.11	4	0.60	-84.29	2
44101	CA-2014-117401	PP-18955	OFF-BI-10001267	65807	2016-05-18	43.19	7	0.00	20.73	1
44102	CA-2011-139892	BM-11140	OFF-AR-10002656	78207	2013-09-08	32.06	6	0.20	6.81	2
44103	CA-2014-109960	DB-13210	OFF-PA-10000349	48234	2016-12-09	14.94	3	0.00	7.02	1
44104	CA-2012-160472	RK-19300	OFF-ST-10003442	46614	2014-07-20	141.40	5	0.00	38.18	1
44105	CA-2013-102134	SP-20545	FUR-FU-10003724	54302	2015-03-15	16.74	2	0.00	4.35	2
44106	CA-2014-111332	NC-18340	OFF-AR-10000657	58103	2016-05-20	21.50	10	0.00	7.10	1
44107	CA-2014-159149	CR-12820	OFF-AR-10000937	77041	2016-02-18	175.44	6	0.20	52.63	4
44108	US-2013-110156	EH-13945	OFF-PA-10004735	77041	2015-11-20	10.37	2	0.20	3.63	2
44109	CA-2012-136378	CS-11845	OFF-BI-10003707	77070	2014-04-02	9.16	3	0.80	-13.73	2
44110	CA-2011-169019	LF-17185	OFF-BI-10001679	78207	2013-07-26	8.88	5	0.80	-13.32	2
44111	CA-2014-135692	CV-12805	FUR-BO-10002268	76106	2016-04-27	220.27	4	0.32	-42.11	2
44112	CA-2013-167759	CC-12670	TEC-PH-10003171	47401	2015-03-04	134.85	3	0.00	37.76	1
44113	CA-2012-127509	AS-10090	FUR-TA-10002855	65807	2014-11-09	1024.38	7	0.00	215.12	2
44114	CA-2011-118339	BN-11515	OFF-PA-10000466	55044	2013-03-17	47.18	7	0.00	23.59	2
44115	US-2013-111290	DK-13375	TEC-AC-10004975	48185	2015-07-23	109.95	1	0.00	36.28	2
44116	CA-2014-161557	AG-10900	FUR-FU-10004622	75217	2016-09-03	108.40	5	0.60	-105.69	2
44117	CA-2013-164035	CR-12730	OFF-PA-10002160	60610	2015-06-13	23.12	5	0.20	8.38	2
44118	US-2012-161991	SC-20725	OFF-BI-10004967	77070	2014-09-26	2.08	5	0.80	-3.43	1
44119	CA-2011-101602	MC-18100	FUR-CH-10004675	79907	2013-12-15	763.28	5	0.30	-21.81	4
44120	CA-2013-150483	BP-11290	OFF-PA-10004621	62521	2015-06-01	10.37	2	0.20	3.63	2
44121	CA-2014-133333	BF-11020	OFF-PA-10002377	54302	2016-09-18	22.72	4	0.00	10.22	2
44122	CA-2013-104311	AS-10090	OFF-ST-10000321	75061	2015-05-03	18.94	3	0.20	-3.79	2
44123	CA-2014-113355	SJ-20215	FUR-CH-10002602	75051	2016-12-01	317.06	3	0.30	-18.12	2
44124	CA-2013-160241	DR-12940	FUR-FU-10003806	60505	2015-11-30	242.18	4	0.60	-302.72	1
44125	CA-2014-127460	FG-14260	OFF-ST-10004340	60505	2016-07-10	298.46	6	0.20	26.12	2
44126	US-2012-100531	NM-18520	FUR-FU-10003849	60610	2014-09-27	24.29	3	0.60	-12.75	4
44127	CA-2014-116358	KM-16225	OFF-AR-10004685	66212	2016-11-02	27.78	6	0.00	9.17	2
44128	CA-2011-117765	RB-19465	OFF-BI-10000474	74133	2013-09-07	32.06	2	0.00	15.39	2
44129	CA-2012-141810	BB-10990	OFF-BI-10001524	78207	2014-11-02	29.37	7	0.80	-47.00	2
44130	US-2014-102288	ZC-21910	OFF-PA-10000740	77095	2016-06-19	146.18	8	0.20	47.51	2
44131	CA-2013-162222	SR-20740	OFF-PA-10003893	75081	2015-04-04	10.27	3	0.20	3.21	3
44132	US-2012-105676	NM-18520	FUR-FU-10004270	77036	2014-12-01	6.69	4	0.60	-4.01	3
44133	CA-2012-155761	SC-20800	OFF-ST-10000943	77041	2014-12-11	46.34	3	0.20	4.63	3
44134	CA-2014-142174	DP-13000	OFF-PA-10000806	77041	2016-03-04	89.57	2	0.20	32.47	2
44135	CA-2012-149909	RA-19915	TEC-PH-10001536	47201	2014-11-13	50.97	3	0.00	13.25	2
44136	CA-2014-118213	AB-10060	OFF-PA-10000565	46142	2016-11-05	167.94	3	0.00	82.29	4
44137	CA-2012-107083	BB-11545	OFF-AP-10004136	76106	2014-11-21	24.59	3	0.80	-67.62	2
\.


--
-- TOC entry 5073 (class 0 OID 16597)
-- Dependencies: 225
-- Data for Name: staging_superstore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staging_superstore (row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit) FROM stdin;
\.


--
-- TOC entry 5076 (class 0 OID 16693)
-- Dependencies: 229
-- Data for Name: stg_superstore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stg_superstore (row_id, order_id, order_date, ship_date, ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, region, product_id, category, sub_category, product_name, sales, quantity, discount, profit) FROM stdin;
1724	US-2012-123218	12/20/2014	12/25/2014	Standard Class	KD-16345	Katherine Ducich	Consumer	United States	Chicago	Illinois	60623	Central	FUR-BO-10003966	Furniture	Bookcases	Sauder Facets Collection Library, Sky Alder Finish	359.058	3	0.3	-71.8116
9532	CA-2014-102729	10/26/2016	10/31/2016	Standard Class	BF-11215	Benjamin Farhat	Home Office	United States	Dallas	Texas	75217	Central	OFF-ST-10000464	Office Supplies	Storage	Multi-Use Personal File Cart and Caster Set, Three Stacking Bins	55.616	2	0.2	5.5616
2055	CA-2013-136434	12/2/2015	12/8/2015	Standard Class	RD-19480	Rick Duston	Consumer	United States	Richmond	Indiana	47374	Central	FUR-FU-10001196	Furniture	Furnishings	DAX Cubicle Frames - 8x10	17.31	3	0	5.193
2611	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	OFF-LA-10000248	Office Supplies	Labels	Avery 52	5.904	2	0.2	1.9926
7046	CA-2013-160136	11/4/2015	11/10/2015	Standard Class	PJ-18835	Patrick Jones	Corporate	United States	Dallas	Texas	75217	Central	OFF-PA-10002160	Office Supplies	Paper	Xerox 1978	9.248	2	0.2	3.3524
6986	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10000320	Office Supplies	Binders	GBC Plastic Binding Combs	29.52	4	0	14.4648
7687	CA-2013-169838	11/26/2015	11/30/2015	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Jackson	Michigan	49201	Central	FUR-TA-10001095	Furniture	Tables	Chromcraft Round Conference Tables	1568.61	9	0	329.4081
8128	CA-2012-137064	2/6/2014	2/13/2014	Standard Class	TS-21655	Trudy Schmidt	Consumer	United States	Houston	Texas	77070	Central	OFF-ST-10003470	Office Supplies	Storage	Tennsco Snap-Together Open Shelving Units, Starter Sets and Add-On Units	670.752	3	0.2	-125.766
4488	CA-2012-162621	9/5/2014	9/11/2014	Standard Class	CA-12055	Cathy Armstrong	Home Office	United States	Houston	Texas	77036	Central	OFF-BI-10000962	Office Supplies	Binders	Acco Flexible ACCOHIDE Square Ring Data Binder, Dark Blue, 11 1/2" X 14" 7/8"	16.27	5	0.8	-25.2185
5165	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	OFF-AR-10001149	Office Supplies	Art	Avery Hi-Liter Comfort Grip Fluorescent Highlighter, Yellow Ink	3.9	2	0	1.521
8113	CA-2013-130393	12/2/2015	12/4/2015	Second Class	JM-15865	John Murray	Consumer	United States	San Angelo	Texas	76903	Central	OFF-AP-10004859	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Surge Suppressor	11.648	4	0.8	-30.8672
4232	CA-2014-100223	7/5/2016	7/10/2016	Standard Class	LS-16945	Linda Southworth	Corporate	United States	Dallas	Texas	75220	Central	OFF-PA-10000232	Office Supplies	Paper	Xerox 1975	15.552	3	0.2	5.6376
282	US-2012-161991	9/26/2014	9/28/2014	Second Class	SC-20725	Steven Cartwright	Consumer	United States	Houston	Texas	77070	Central	TEC-PH-10001760	Technology	Phones	Bose SoundLink Bluetooth Speaker	1114.4	7	0.2	376.11
3995	CA-2012-105627	3/8/2014	3/12/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Kenosha	Wisconsin	53142	Central	FUR-BO-10002916	Furniture	Bookcases	Rush Hierlooms Collection 1" Thick Stackable Bookcases	512.94	3	0	97.4586
6421	CA-2013-140130	11/1/2015	11/6/2015	Standard Class	HW-14935	Helen Wasserman	Corporate	United States	Tulsa	Oklahoma	74133	Central	OFF-AR-10004269	Office Supplies	Art	Newell 31	12.39	3	0	3.4692
912	CA-2014-137596	9/2/2016	9/7/2016	Standard Class	BE-11335	Bill Eplett	Home Office	United States	Jackson	Michigan	49201	Central	OFF-ST-10003816	Office Supplies	Storage	Fellowes High-Stak Drawer Files	352.38	2	0	81.0474
916	US-2011-141215	6/15/2013	6/21/2013	Standard Class	KL-16555	Kelly Lampkin	Corporate	United States	San Antonio	Texas	78207	Central	FUR-TA-10001520	Furniture	Tables	Lesro Sheffield Collection Coffee Table, End Table, Center Table, Corner Table	99.918	2	0.3	-18.5562
7944	CA-2014-134194	12/25/2016	1/1/2017	Standard Class	GA-14725	Guy Armstrong	Consumer	United States	Dallas	Texas	75081	Central	OFF-SU-10000946	Office Supplies	Supplies	Staple remover	44.688	7	0.2	5.0274
6949	CA-2012-130365	4/25/2014	4/29/2014	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Aurora	Illinois	60505	Central	FUR-CH-10003535	Furniture	Chairs	Global Armless Task Chair, Royal Blue	128.058	3	0.3	-23.7822
9777	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	OFF-BI-10001524	Office Supplies	Binders	GBC Premium Transparent Covers with Diagonal Lined Pattern	16.784	4	0.8	-26.8544
3514	CA-2014-140326	9/4/2016	9/6/2016	First Class	HW-14935	Helen Wasserman	Corporate	United States	Chicago	Illinois	60653	Central	OFF-PA-10004041	Office Supplies	Paper	It's Hot Message Books with Stickers, 2 3/4" x 5"	17.76	3	0.2	5.55
7652	CA-2014-110821	8/7/2016	8/8/2016	First Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Dallas	Texas	75081	Central	TEC-AC-10001552	Technology	Accessories	Logitech K350 2.4Ghz Wireless Keyboard	119.448	3	0.2	-13.4379
4098	CA-2011-116904	9/23/2013	9/28/2013	Standard Class	SC-20095	Sanjit Chand	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-ST-10000736	Office Supplies	Storage	Carina Double Wide Media Storage Towers in Natural & Black	404.9	5	0	16.196
7557	CA-2014-159506	11/27/2016	12/2/2016	Standard Class	JR-16210	Justin Ritter	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10003641	Office Supplies	Paper	Xerox 1909	158.28	6	0	72.8088
9448	CA-2014-136882	5/27/2016	6/3/2016	Standard Class	DN-13690	Duane Noonan	Consumer	United States	Tulsa	Oklahoma	74133	Central	FUR-FU-10003664	Furniture	Furnishings	Electrix Architect's Clamp-On Swing Arm Lamp, Black	477.3	5	0	138.417
1438	CA-2012-139731	10/15/2014	10/15/2014	Same Day	JE-15745	Joel Eaton	Consumer	United States	Amarillo	Texas	79109	Central	TEC-AC-10004975	Technology	Accessories	Plantronics Audio 995 Wireless Stereo Headset	263.88	3	0.2	42.8805
2158	CA-2011-124646	6/22/2013	6/24/2013	First Class	DV-13465	Dianna Vittorini	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-ST-10001469	Office Supplies	Storage	Fellowes Bankers Box Recycled Super Stor/Drawer	161.94	3	0	9.7164
9264	CA-2012-124499	10/9/2014	10/13/2014	Standard Class	FM-14380	Fred McMath	Consumer	United States	Detroit	Michigan	48227	Central	OFF-AP-10002191	Office Supplies	Appliances	Belkin 8 Outlet SurgeMaster II Gold Surge Protector	269.91	5	0.1	53.982
8720	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	OFF-PA-10000232	Office Supplies	Paper	Xerox 1975	15.552	3	0.2	5.6376
9973	CA-2013-130225	9/12/2015	9/18/2015	Standard Class	RC-19960	Ryan Crowe	Consumer	United States	Houston	Texas	77041	Central	OFF-EN-10000056	Office Supplies	Envelopes	Cameo Buff Policy Envelopes	99.568	2	0.2	33.6042
4111	CA-2012-153717	12/25/2014	1/1/2015	Standard Class	DL-13495	Dionis Lloyd	Corporate	United States	Detroit	Michigan	48227	Central	FUR-BO-10004360	Furniture	Bookcases	Rush Hierlooms Collection Rich Wood Bookcases	160.98	1	0	20.9274
4078	CA-2012-100685	12/19/2014	12/21/2014	Second Class	SM-20950	Suzanne McNair	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-FA-10003472	Office Supplies	Fasteners	Bagged Rubber Bands	5.04	4	0	0.2016
918	US-2011-141215	6/15/2013	6/21/2013	Standard Class	KL-16555	Kelly Lampkin	Corporate	United States	San Antonio	Texas	78207	Central	OFF-BI-10002706	Office Supplies	Binders	Avery Premier Heavy-Duty Binder with Round Locking Rings	8.568	3	0.8	-14.5656
3511	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	TEC-MA-10001972	Technology	Machines	Okidata C331dn Printer	418.8	2	0.4	-97.72
9414	CA-2013-132017	9/27/2015	9/28/2015	First Class	MH-17620	Matt Hagelstein	Corporate	United States	Houston	Texas	77041	Central	OFF-BI-10004001	Office Supplies	Binders	GBC Recycled VeloBinder Covers	6.816	2	0.8	-11.5872
5451	US-2011-119081	9/12/2013	9/19/2013	Standard Class	TA-21385	Tom Ashbrook	Home Office	United States	Olathe	Kansas	66062	Central	OFF-BI-10004519	Office Supplies	Binders	GBC DocuBind P100 Manual Binding Machine	331.96	2	0	149.382
5363	CA-2013-122014	12/30/2015	1/3/2016	Standard Class	CD-11920	Carlos Daly	Consumer	United States	Wichita	Kansas	67212	Central	FUR-FU-10000672	Furniture	Furnishings	Executive Impressions 10" Spectator Wall Clock	70.56	6	0	23.9904
6385	US-2014-104661	1/16/2016	1/19/2016	First Class	TB-21250	Tim Brockman	Consumer	United States	Austin	Texas	78745	Central	TEC-AC-10003628	Technology	Accessories	Logitech 910-002974 M325 Wireless Mouse for Web Scrolling	47.984	2	0.2	14.3952
9299	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	OFF-AR-10003373	Office Supplies	Art	Boston School Pro Electric Pencil Sharpener, 1670	74.352	3	0.2	6.5058
8435	US-2011-127635	9/14/2013	9/18/2013	Second Class	SC-20260	Scott Cohen	Corporate	United States	Corpus Christi	Texas	78415	Central	FUR-FU-10000550	Furniture	Furnishings	Stacking Trays by OIC	9.96	5	0.6	-6.723
1822	CA-2013-168956	2/16/2015	2/20/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Chicago	Illinois	60623	Central	OFF-FA-10000304	Office Supplies	Fasteners	Advantus Push Pins	6.976	4	0.2	1.8312
7134	CA-2014-141439	11/26/2016	12/1/2016	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Richmond	Indiana	47374	Central	FUR-FU-10001473	Furniture	Furnishings	DAX Wood Document Frame	27.46	2	0	9.8856
9537	CA-2014-124191	6/12/2016	6/14/2016	Second Class	TS-21610	Troy Staebel	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10002364	Furniture	Furnishings	Eldon Expressions Wood Desk Accessories, Oak	8.856	3	0.6	-6.8634
3168	CA-2013-146682	10/30/2015	11/1/2015	First Class	KW-16435	Katrina Willman	Consumer	United States	Lansing	Michigan	48911	Central	FUR-FU-10002671	Furniture	Furnishings	Electrix 20W Halogen Replacement Bulb for Zoom-In Desk Lamp	67	5	0	32.16
884	CA-2013-165148	10/23/2015	10/25/2015	First Class	PM-19135	Peter McVee	Home Office	United States	Detroit	Michigan	48227	Central	FUR-FU-10000732	Furniture	Furnishings	Eldon 200 Class Desk Accessories	31.4	5	0	10.048
7133	CA-2014-141439	11/26/2016	12/1/2016	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Richmond	Indiana	47374	Central	TEC-PH-10002624	Technology	Phones	Samsung Galaxy S4 Mini	1879.96	4	0	545.1884
1963	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-BI-10002954	Office Supplies	Binders	Newell 3-Hole Punched Plastic Slotted Magazine Holders for Binders	13.71	3	0	6.5808
9210	CA-2014-142776	12/11/2016	12/14/2016	Second Class	RS-19870	Roy Skaria	Home Office	United States	Burlington	Iowa	52601	Central	OFF-EN-10003160	Office Supplies	Envelopes	Pastel Pink Envelopes	7.28	1	0	3.4944
7605	CA-2013-101791	5/28/2015	6/1/2015	Standard Class	BS-11665	Brian Stugart	Consumer	United States	Chicago	Illinois	60623	Central	FUR-FU-10003247	Furniture	Furnishings	36X48 HARDFLOOR CHAIRMAT	25.176	3	0.6	-33.3582
3186	CA-2011-123498	11/7/2013	11/9/2013	First Class	TC-20980	Tamara Chand	Corporate	United States	Houston	Texas	77041	Central	OFF-BI-10000632	Office Supplies	Binders	Satellite Sectional Post Binders	26.046	3	0.8	-44.2782
8902	CA-2013-150483	6/1/2015	6/5/2015	Standard Class	BP-11290	Beth Paige	Consumer	United States	Decatur	Illinois	62521	Central	OFF-PA-10001846	Office Supplies	Paper	Xerox 1899	18.496	4	0.2	6.7048
3582	CA-2014-117807	10/1/2016	10/7/2016	Standard Class	DK-13090	Dave Kipp	Consumer	United States	Fremont	Nebraska	68025	Central	OFF-PA-10000994	Office Supplies	Paper	Xerox 1915	104.85	1	0	50.328
1673	CA-2014-111647	7/3/2016	7/7/2016	Standard Class	RD-19585	Rob Dowd	Consumer	United States	Plano	Texas	75023	Central	TEC-PH-10002726	Technology	Phones	netTALK DUO VoIP Telephone Service	167.968	4	0.2	62.988
2404	US-2013-110170	9/28/2015	10/4/2015	Standard Class	HM-14860	Harry Marie	Corporate	United States	Huntsville	Texas	77340	Central	FUR-BO-10000780	Furniture	Bookcases	O'Sullivan Plantations 2-Door Library in Landvery Oak	956.6648	7	0.32	-225.0976
3391	CA-2014-101077	3/25/2016	3/30/2016	Second Class	DB-13660	Duane Benoit	Consumer	United States	Dallas	Texas	75081	Central	OFF-PA-10004239	Office Supplies	Paper	Xerox 1953	6.848	2	0.2	2.14
7331	CA-2013-149349	11/13/2015	11/14/2015	First Class	SP-20650	Stephanie Phelps	Corporate	United States	Chicago	Illinois	60623	Central	FUR-FU-10001037	Furniture	Furnishings	DAX Charcoal/Nickel-Tone Document Frame, 5 x 7	22.752	6	0.6	-8.532
2826	US-2011-112914	9/25/2013	9/30/2013	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Houston	Texas	77041	Central	FUR-BO-10003272	Furniture	Bookcases	O'Sullivan Living Dimensions 5-Shelf Bookcases	300.5328	2	0.32	-97.2312
1692	CA-2014-129833	12/9/2016	12/15/2016	Standard Class	HF-14995	Herbert Flentye	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-BI-10004182	Office Supplies	Binders	Economy Binders	10.4	5	0	5.096
6567	CA-2014-131282	2/6/2016	2/9/2016	Second Class	CB-12025	Cassandra Brandow	Consumer	United States	Waco	Texas	76706	Central	OFF-BI-10004632	Office Supplies	Binders	Ibico Hi-Tech Manual Binding System	243.992	4	0.8	-426.986
4550	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10003963	Technology	Phones	GE 2-Jack Phone Line Splitter	659.168	4	0.2	49.4376
3757	CA-2013-116799	3/4/2015	3/7/2015	First Class	JG-15310	Jason Gross	Corporate	United States	Odessa	Texas	79762	Central	FUR-CH-10004983	Furniture	Chairs	Office Star - Mid Back Dual function Ergonomic High Back Chair with 2-Way Adjustable Arms	563.43	5	0.3	-56.343
2375	CA-2013-159940	7/8/2015	7/12/2015	Second Class	BF-11020	Barry Französisch	Corporate	United States	Aurora	Illinois	60505	Central	FUR-CH-10000785	Furniture	Chairs	Global Ergonomic Managers Chair	253.372	2	0.3	-14.4784
5257	CA-2013-130078	8/9/2015	8/15/2015	Standard Class	CC-12145	Charles Crestani	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-PA-10003270	Office Supplies	Paper	Xerox 1954	10.56	2	0	4.752
6109	CA-2013-150007	9/12/2015	9/17/2015	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Chicago	Illinois	60653	Central	OFF-LA-10001982	Office Supplies	Labels	Smead Alpha-Z Color-Coded Name Labels First Letter Starter Set	6	2	0.2	2.1
9353	CA-2014-148411	9/24/2016	9/26/2016	First Class	RO-19780	Rose O'Brian	Consumer	United States	Chicago	Illinois	60623	Central	FUR-CH-10003973	Furniture	Chairs	GuestStacker Chair with Chrome Finish Legs	520.464	2	0.3	-14.8704
4548	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AR-10003190	Office Supplies	Art	Newell 32	6.912	3	0.2	0.6912
447	CA-2014-154214	3/20/2016	3/25/2016	Second Class	TB-21595	Troy Blackwell	Consumer	United States	Columbus	Indiana	47201	Central	FUR-FU-10000206	Furniture	Furnishings	GE General Purpose, Extra Long Life, Showcase & Floodlight Incandescent Bulbs	2.91	1	0	1.3677
2166	CA-2013-154018	10/14/2015	10/20/2015	Standard Class	HA-14920	Helen Andreada	Consumer	United States	Laredo	Texas	78041	Central	FUR-FU-10003394	Furniture	Furnishings	Tenex "The Solids" Textured Chair Mats	139.92	5	0.6	-150.414
5166	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	OFF-PA-10000130	Office Supplies	Paper	Xerox 199	12.84	3	0	5.778
8983	CA-2013-110898	3/7/2015	3/13/2015	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10004656	Office Supplies	Binders	Peel & Stick Add-On Corner Pockets	1.728	4	0.8	-2.7648
6389	CA-2011-134103	1/30/2013	2/4/2013	Standard Class	MV-18190	Mike Vittorini	Consumer	United States	Detroit	Michigan	48234	Central	OFF-ST-10000991	Office Supplies	Storage	Space Solutions HD Industrial Steel Shelving.	229.94	2	0	6.8982
3764	CA-2013-156251	8/14/2015	8/19/2015	Second Class	TS-21160	Theresa Swint	Corporate	United States	West Allis	Wisconsin	53214	Central	OFF-BI-10003529	Office Supplies	Binders	Avery Round Ring Poly Binders	8.52	3	0	4.1748
4304	CA-2013-121601	10/5/2015	10/5/2015	Same Day	MO-17500	Mary O'Rourke	Consumer	United States	The Colony	Texas	75056	Central	OFF-EN-10003862	Office Supplies	Envelopes	Laser & Ink Jet Business Envelopes	59.752	7	0.2	19.4194
8494	CA-2012-109190	10/23/2014	10/28/2014	Standard Class	CC-12685	Craig Carroll	Consumer	United States	Lubbock	Texas	79424	Central	TEC-CO-10001943	Technology	Copiers	Canon PC-428 Personal Copier	479.976	3	0.2	161.9919
4005	CA-2013-145730	3/4/2015	3/9/2015	Standard Class	CC-12220	Chris Cortes	Consumer	United States	San Antonio	Texas	78207	Central	OFF-EN-10000483	Office Supplies	Envelopes	White Envelopes, White Envelopes with Clear Poly Window	36.6	3	0.2	11.895
4767	CA-2012-123155	3/9/2014	3/12/2014	First Class	NS-18640	Noel Staavos	Corporate	United States	San Antonio	Texas	78207	Central	TEC-AC-10002473	Technology	Accessories	Maxell 4.7GB DVD-R	113.52	5	0.2	29.799
103	CA-2013-129903	12/2/2015	12/5/2015	Second Class	GZ-14470	Gary Zandusky	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-PA-10004040	Office Supplies	Paper	Universal Premium White Copier/Laser Paper (20Lb. and 87 Bright)	23.92	4	0	11.7208
1756	CA-2012-135622	12/8/2014	12/11/2014	Second Class	TT-21460	Tonja Turnell	Home Office	United States	Fort Worth	Texas	76106	Central	OFF-PA-10000100	Office Supplies	Paper	Xerox 1945	360.712	11	0.2	130.7581
3006	CA-2011-148761	5/17/2013	5/21/2013	Standard Class	PA-19060	Pete Armstrong	Home Office	United States	Eau Claire	Wisconsin	54703	Central	OFF-BI-10000666	Office Supplies	Binders	Surelock Post Binders	91.68	3	0	45.84
8115	CA-2014-144820	10/3/2016	10/7/2016	Second Class	LW-16825	Laurel Workman	Corporate	United States	Pasadena	Texas	77506	Central	OFF-AR-10004817	Office Supplies	Art	Colorific Watercolor Pencils	20.64	5	0.2	2.322
8722	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	OFF-ST-10002562	Office Supplies	Storage	Staple magnet	67.536	9	0.2	6.7536
1832	CA-2014-145884	10/21/2016	10/21/2016	Same Day	SL-20155	Sara Luxemburg	Home Office	United States	Muskogee	Oklahoma	74403	Central	FUR-TA-10002356	Furniture	Tables	Bevis Boat-Shaped Conference Table	262.11	1	0	62.9064
7707	CA-2013-114601	8/27/2015	9/3/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Detroit	Michigan	48234	Central	OFF-AR-10002578	Office Supplies	Art	Newell 335	8.64	3	0	2.5056
5176	CA-2014-106432	10/19/2016	10/24/2016	Standard Class	CA-12265	Christina Anderson	Consumer	United States	Waco	Texas	76706	Central	FUR-BO-10004360	Furniture	Bookcases	Rush Hierlooms Collection Rich Wood Bookcases	328.3992	3	0.32	-91.7586
4862	CA-2011-138940	4/11/2013	4/16/2013	Second Class	GM-14455	Gary Mitchum	Home Office	United States	Austin	Texas	78745	Central	TEC-PH-10001835	Technology	Phones	Jawbone JAMBOX Wireless Bluetooth Speaker	758.352	6	0.2	265.4232
262	US-2014-155299	6/8/2016	6/12/2016	Standard Class	Dl-13600	Dorris liebe	Corporate	United States	Pasadena	Texas	77506	Central	OFF-AP-10002203	Office Supplies	Appliances	Eureka Disposable Bags for Sanitaire Vibra Groomer I Upright Vac	1.624	2	0.8	-4.466
9863	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	TEC-AC-10001445	Technology	Accessories	Imation USB 2.0 Swivel Flash Drive USB flash drive - 4 GB - Pink	12.12	4	0	2.5452
9478	CA-2012-100818	5/31/2014	6/5/2014	Second Class	JM-15265	Janet Molinari	Corporate	United States	Chicago	Illinois	60653	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	3.564	3	0.8	-6.237
612	CA-2013-161816	4/29/2015	5/2/2015	First Class	NB-18655	Nona Balk	Corporate	United States	Dallas	Texas	75217	Central	OFF-LA-10004345	Office Supplies	Labels	Avery 493	15.712	4	0.2	5.6956
1591	US-2013-132423	4/16/2015	4/20/2015	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Grapevine	Texas	76051	Central	OFF-AR-10001221	Office Supplies	Art	Dixon Ticonderoga Erasable Colored Pencil Set, 12-Color	33.488	7	0.2	5.8604
4289	US-2012-117184	5/17/2014	5/21/2014	Standard Class	ON-18715	Odella Nelson	Corporate	United States	Houston	Texas	77095	Central	OFF-BI-10002082	Office Supplies	Binders	GBC Twin Loop Wire Binding Elements	33.28	5	0.8	-49.92
8220	CA-2011-120775	10/3/2013	10/7/2013	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Dallas	Texas	75217	Central	OFF-LA-10002271	Office Supplies	Labels	Smead Alpha-Z Color-Coded Second Alphabetical Labels and Starter Set	4.928	2	0.2	1.7248
7315	CA-2013-121377	5/29/2015	6/3/2015	Standard Class	TN-21040	Tanja Norvell	Home Office	United States	Park Ridge	Illinois	60068	Central	TEC-PH-10001817	Technology	Phones	Wilson Electronics DB Pro Signal Booster	286.4	1	0.2	25.06
5055	CA-2012-141243	1/3/2014	1/8/2014	Second Class	AH-10465	Amy Hunt	Consumer	United States	Dallas	Texas	75217	Central	OFF-AR-10001246	Office Supplies	Art	Newell 317	7.056	3	0.2	0.7938
8415	CA-2013-147109	12/18/2015	12/22/2015	Standard Class	AH-10075	Adam Hart	Corporate	United States	Arlington	Texas	76017	Central	TEC-AC-10002942	Technology	Accessories	WD My Passport Ultra 1TB Portable External Hard Drive	165.6	3	0.2	-6.21
8551	CA-2012-121132	7/17/2014	7/24/2014	Standard Class	VB-21745	Victoria Brennan	Corporate	United States	Houston	Texas	77041	Central	OFF-LA-10002368	Office Supplies	Labels	Avery 479	6.264	3	0.2	2.0358
6220	CA-2013-160220	10/21/2015	10/27/2015	Standard Class	JS-16030	Joy Smith	Consumer	United States	Trenton	Michigan	48183	Central	TEC-PH-10001557	Technology	Phones	Pyle PMP37LED	191.98	2	0	51.8346
2124	CA-2014-167381	9/22/2016	9/24/2016	Second Class	EH-14005	Erica Hernandez	Home Office	United States	Lansing	Michigan	48911	Central	OFF-LA-10000134	Office Supplies	Labels	Avery 511	27.72	9	0	13.3056
112	CA-2013-128867	11/4/2015	11/11/2015	Standard Class	CL-12565	Clay Ludtke	Consumer	United States	Urbandale	Iowa	50322	Central	OFF-AR-10000380	Office Supplies	Art	Hunt PowerHouse Electric Pencil Sharpener, Blue	75.96	2	0	22.788
3397	US-2014-148362	7/1/2016	7/8/2016	Standard Class	KF-16285	Karen Ferguson	Home Office	United States	Indianapolis	Indiana	46203	Central	OFF-BI-10003656	Office Supplies	Binders	Fellowes PB200 Plastic Comb Binding Machine	169.99	1	0	78.1954
2684	CA-2014-127026	1/22/2016	1/28/2016	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Jackson	Michigan	49201	Central	TEC-PH-10003601	Technology	Phones	Ativa D5772 2-Line 5.8GHz Digital Expandable Corded/Cordless Phone System with Answering & Caller ID/Call Waiting, Black/Silver	164.99	1	0	49.497
7102	CA-2013-144337	8/2/2015	8/6/2015	Second Class	SG-20890	Susan Gilcrest	Corporate	United States	Amarillo	Texas	79109	Central	OFF-PA-10000249	Office Supplies	Paper	Easy-staple paper	19.648	2	0.2	6.6312
89	CA-2013-159695	4/6/2015	4/11/2015	Second Class	GM-14455	Gary Mitchum	Home Office	United States	Houston	Texas	77095	Central	OFF-ST-10003442	Office Supplies	Storage	Eldon Portable Mobile Manager	158.368	7	0.2	13.8572
8126	CA-2012-137064	2/6/2014	2/13/2014	Standard Class	TS-21655	Trudy Schmidt	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10002049	Office Supplies	Binders	UniKeep View Case Binders	2.934	3	0.8	-4.9878
4714	CA-2011-108273	12/16/2013	12/21/2013	Standard Class	EJ-13720	Ed Jacobs	Consumer	United States	Huntsville	Texas	77340	Central	FUR-FU-10002116	Furniture	Furnishings	Tenex Carpeted, Granite-Look or Clear Contemporary Contour Shape Chair Mats	56.568	2	0.6	-74.9526
3172	US-2013-133879	3/22/2015	3/29/2015	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10004465	Office Supplies	Binders	Avery Durable Slant Ring Binders	3.168	2	0.8	-4.752
4386	US-2012-122784	7/20/2014	7/27/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Highland Park	Illinois	60035	Central	FUR-BO-10002545	Furniture	Bookcases	Atlantic Metals Mobile 3-Shelf Bookcases, Custom Colors	913.43	5	0.3	-52.196
9430	CA-2012-166219	8/28/2014	9/1/2014	Standard Class	BP-11185	Ben Peterman	Corporate	United States	Dallas	Texas	75081	Central	TEC-PH-10004165	Technology	Phones	Mitel MiVoice 5330e IP Phone	1099.96	5	0.2	82.497
4445	US-2011-147704	11/16/2013	11/21/2013	Standard Class	SR-20740	Steven Roelle	Home Office	United States	Bloomington	Indiana	47401	Central	OFF-EN-10004483	Office Supplies	Envelopes	#10 White Business Envelopes,4 1/8 x 9 1/2	78.35	5	0	36.8245
2212	CA-2013-162313	11/28/2015	12/1/2015	First Class	VB-21745	Victoria Brennan	Corporate	United States	Lincoln Park	Michigan	48146	Central	OFF-AP-10003842	Office Supplies	Appliances	Euro-Pro Shark Turbo Vacuum	167.292	6	0.1	29.7408
3098	CA-2014-135692	4/27/2016	5/1/2016	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-LA-10001158	Office Supplies	Labels	Avery Address/Shipping Labels for Typewriters, 4" x 2"	33.12	4	0.2	11.592
4385	US-2012-122784	7/20/2014	7/27/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Highland Park	Illinois	60035	Central	TEC-PH-10001557	Technology	Phones	Pyle PMP37LED	153.584	2	0.2	13.4386
7762	CA-2014-123071	12/3/2016	12/6/2016	First Class	CC-12550	Clay Cheatham	Consumer	United States	Plano	Texas	75023	Central	OFF-PA-10003729	Office Supplies	Paper	Xerox 1998	10.368	2	0.2	3.6288
8176	CA-2013-114944	1/30/2015	2/4/2015	Standard Class	HE-14800	Harold Engle	Corporate	United States	Chicago	Illinois	60623	Central	OFF-PA-10003892	Office Supplies	Paper	Xerox 1943	156.512	4	0.2	52.8228
8223	CA-2011-152905	2/18/2013	2/24/2013	Standard Class	AB-10015	Aaron Bergman	Consumer	United States	Arlington	Texas	76017	Central	OFF-ST-10000321	Office Supplies	Storage	Akro Stacking Bins	12.624	2	0.2	-2.5248
6562	CA-2014-144680	3/31/2016	4/2/2016	First Class	SC-20260	Scott Cohen	Corporate	United States	Arlington	Texas	76017	Central	OFF-AP-10003040	Office Supplies	Appliances	Fellowes 8 Outlet Superior Workstation Surge Protector w/o Phone/Fax/Modem Protection	33.62	5	0.8	-90.774
8944	CA-2014-111717	10/10/2016	10/16/2016	Standard Class	SW-20245	Scot Wooten	Consumer	United States	Aurora	Illinois	60505	Central	FUR-CH-10001545	Furniture	Chairs	Hon Comfortask Task/Swivel Chairs	239.358	3	0.3	-47.8716
9794	CA-2011-127166	5/21/2013	5/23/2013	Second Class	KH-16360	Katherine Hughes	Consumer	United States	Houston	Texas	77070	Central	OFF-PA-10001560	Office Supplies	Paper	Adams Telephone Message Books, 5 1/4” x 11”	4.832	1	0.2	1.6308
1548	CA-2012-111395	11/23/2014	11/27/2014	Standard Class	VB-21745	Victoria Brennan	Corporate	United States	San Antonio	Texas	78207	Central	OFF-BI-10002867	Office Supplies	Binders	GBC Recycled Regency Composition Covers	23.912	2	0.8	-40.6504
9109	CA-2012-132941	5/25/2014	5/28/2014	First Class	MM-18280	Muhammed MacIntyre	Corporate	United States	Haltom City	Texas	76117	Central	OFF-PA-10002160	Office Supplies	Paper	Xerox 1978	32.368	7	0.2	11.7334
4421	CA-2012-163090	11/17/2014	11/21/2014	Second Class	GH-14665	Greg Hansen	Consumer	United States	Chicago	Illinois	60610	Central	OFF-SU-10002537	Office Supplies	Supplies	Acme Box Cutter Scissors	40.92	5	0.2	3.069
4026	CA-2014-139311	8/11/2016	8/13/2016	First Class	SF-20965	Sylvia Foulston	Corporate	United States	Bedford	Texas	76021	Central	OFF-PA-10001776	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4" x 5" Forms per Page, 600 Sets per Book	29.664	4	0.2	10.0116
8428	CA-2014-167017	11/23/2016	11/25/2016	First Class	DC-12850	Dan Campbell	Consumer	United States	Roseville	Michigan	48066	Central	OFF-SU-10001935	Office Supplies	Supplies	Staple remover	4.36	2	0	0.1744
228	CA-2012-163055	8/9/2014	8/16/2014	Standard Class	DS-13180	David Smith	Corporate	United States	Detroit	Michigan	48227	Central	OFF-ST-10002485	Office Supplies	Storage	Rogers Deluxe File Chest	21.98	1	0	0.2198
722	CA-2013-142335	12/16/2015	12/20/2015	Standard Class	MP-17965	Michael Paige	Corporate	United States	Detroit	Michigan	48205	Central	FUR-TA-10000198	Furniture	Tables	Chromcraft Bull-Nose Wood Oval Conference Tables & Bases	1652.94	3	0	231.4116
986	CA-2014-100314	9/29/2016	10/5/2016	Standard Class	AS-10630	Ann Steele	Home Office	United States	Pasadena	Texas	77506	Central	OFF-EN-10000461	Office Supplies	Envelopes	#10- 4 1/8" x 9 1/2" Recycled Envelopes	27.968	4	0.2	9.4392
3193	CA-2014-158953	6/4/2016	6/8/2016	Standard Class	ML-18040	Michelle Lonsdale	Corporate	United States	Missouri City	Texas	77489	Central	OFF-BI-10002557	Office Supplies	Binders	Presstex Flexible Ring Binders	6.37	7	0.8	-9.555
2372	CA-2013-159940	7/8/2015	7/12/2015	Second Class	BF-11020	Barry Französisch	Corporate	United States	Aurora	Illinois	60505	Central	FUR-FU-10004973	Furniture	Furnishings	Flat Face Poster Frame	60.288	8	0.6	-27.1296
6798	CA-2012-168809	8/25/2014	8/25/2014	Same Day	MC-18100	Mick Crebagga	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10000315	Office Supplies	Binders	Poly Designer Cover & Back	3.798	1	0.8	-6.0768
8009	CA-2012-110863	11/17/2014	11/24/2014	Standard Class	AA-10645	Anna Andreadi	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-PA-10000474	Office Supplies	Paper	Easy-staple paper	106.32	3	0	49.9704
9065	US-2011-151015	10/14/2013	10/20/2013	Standard Class	BD-11500	Bradley Drucker	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10000343	Office Supplies	Binders	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	2.946	3	0.8	-4.8609
9895	US-2013-115441	7/26/2015	7/29/2015	Second Class	SH-19975	Sally Hughsby	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10001756	Furniture	Furnishings	Eldon Expressions Desk Accessory, Wood Photo Frame, Mahogany	95.2	5	0	27.608
8510	CA-2012-135853	12/11/2014	12/14/2014	First Class	CA-12775	Cynthia Arntzen	Consumer	United States	Detroit	Michigan	48205	Central	TEC-PH-10003691	Technology	Phones	BlackBerry Q10	125.99	1	0	31.4975
238	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	OFF-PA-10003349	Office Supplies	Paper	Xerox 1957	25.92	5	0.2	9.396
7550	CA-2013-136595	9/6/2015	9/8/2015	First Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Houston	Texas	77036	Central	FUR-FU-10004671	Furniture	Furnishings	Executive Impressions 12" Wall Clock	21.204	3	0.6	-11.6622
1966	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-AP-10003281	Office Supplies	Appliances	Acco 6 Outlet Guardian Standard Surge Suppressor	24.18	2	0	7.254
7287	CA-2013-149965	6/21/2015	6/26/2015	Standard Class	BS-11365	Bill Shonely	Corporate	United States	Oklahoma City	Oklahoma	73120	Central	TEC-AC-10004877	Technology	Accessories	Imation 30456 USB Flash Drive 8GB	6.9	1	0	0.552
3503	CA-2014-125115	4/10/2016	4/10/2016	Same Day	RD-19930	Russell D'Ascenzo	Consumer	United States	Austin	Texas	78745	Central	OFF-PA-10004101	Office Supplies	Paper	Xerox 1894	10.368	2	0.2	3.6288
3789	CA-2013-169971	9/5/2015	9/10/2015	Standard Class	IL-15100	Ivan Liston	Consumer	United States	Houston	Texas	77041	Central	OFF-AR-10001044	Office Supplies	Art	BOSTON Ranger #55 Pencil Sharpener, Black	62.376	3	0.2	7.0173
9949	CA-2014-121559	6/1/2016	6/3/2016	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-AP-10002945	Office Supplies	Appliances	Honeywell Enviracaire Portable HEPA Air Cleaner for 17' x 22' Room	2405.2	8	0	793.716
9768	CA-2014-102659	12/9/2016	12/15/2016	Standard Class	LW-17215	Luke Weiss	Consumer	United States	Grand Rapids	Michigan	49505	Central	OFF-BI-10000088	Office Supplies	Binders	GBC Imprintable Covers	54.9	5	0	26.901
8552	CA-2012-121132	7/17/2014	7/24/2014	Standard Class	VB-21745	Victoria Brennan	Corporate	United States	Houston	Texas	77041	Central	OFF-FA-10004248	Office Supplies	Fasteners	Advantus T-Pin Paper Clips	14.432	4	0.2	3.4276
17	CA-2011-105893	11/11/2013	11/18/2013	Standard Class	PK-19075	Pete Kriz	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-ST-10004186	Office Supplies	Storage	Stur-D-Stor Shelving, Vertical 5-Shelf: 72"H x 36"W x 18 1/2"D	665.88	6	0	13.3176
4831	CA-2011-120278	11/7/2013	11/12/2013	Standard Class	MS-17365	Maribeth Schnelling	Consumer	United States	Wausau	Wisconsin	54401	Central	OFF-AP-10001293	Office Supplies	Appliances	Belkin 8 Outlet Surge Protector	245.88	6	0	68.8464
3814	CA-2012-103961	11/5/2014	11/9/2014	Standard Class	NG-18430	Nathan Gelder	Consumer	United States	Quincy	Illinois	62301	Central	OFF-LA-10004484	Office Supplies	Labels	Avery 476	19.824	6	0.2	6.4428
5621	US-2013-124163	9/26/2015	10/1/2015	Standard Class	SC-20695	Steve Chapman	Corporate	United States	La Crosse	Wisconsin	54601	Central	OFF-AR-10000817	Office Supplies	Art	Manco Dry-Lighter Erasable Highlighter	3.04	1	0	1.0336
4225	CA-2013-108644	10/1/2015	10/4/2015	First Class	SJ-20215	Sarah Jordon	Consumer	United States	Quincy	Illinois	62301	Central	OFF-BI-10000343	Office Supplies	Binders	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	1.964	2	0.8	-3.2406
6872	CA-2013-145009	12/6/2015	12/9/2015	Second Class	RF-19345	Randy Ferguson	Corporate	United States	Chicago	Illinois	60610	Central	OFF-LA-10004853	Office Supplies	Labels	Avery 483	11.952	3	0.2	3.8844
207	CA-2014-135860	12/1/2016	12/7/2016	Standard Class	JH-15985	Joseph Holt	Consumer	United States	Saginaw	Michigan	48601	Central	OFF-ST-10000642	Office Supplies	Storage	Tennsco Lockers, Gray	83.92	4	0	5.8744
5278	CA-2011-113859	9/13/2013	9/17/2013	Standard Class	BC-11125	Becky Castell	Home Office	United States	Odessa	Texas	79762	Central	FUR-CH-10004698	Furniture	Chairs	Padded Folding Chairs, Black, 4/Carton	340.116	6	0.3	-9.7176
2058	CA-2014-120376	12/22/2016	12/25/2016	First Class	TP-21130	Theone Pippenger	Consumer	United States	Detroit	Michigan	48227	Central	TEC-AC-10000844	Technology	Accessories	Logitech Gaming G510s - Keyboard	84.99	1	0	30.5964
9952	CA-2014-121559	6/1/2016	6/3/2016	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-BI-10002072	Office Supplies	Binders	Cardinal Slant-D Ring Binders	17.38	2	0	8.69
2517	CA-2011-128888	11/15/2013	11/22/2013	Standard Class	PB-19105	Peter Bühler	Consumer	United States	Houston	Texas	77095	Central	OFF-EN-10003001	Office Supplies	Envelopes	Ames Color-File Green Diamond Border X-ray Mailers	604.656	9	0.2	204.0714
5449	US-2011-119081	9/12/2013	9/19/2013	Standard Class	TA-21385	Tom Ashbrook	Home Office	United States	Olathe	Kansas	66062	Central	OFF-SU-10000157	Office Supplies	Supplies	Compact Automatic Electric Letter Opener	357.93	3	0	7.1586
88	CA-2014-155558	10/26/2016	11/2/2016	Standard Class	PG-18895	Paul Gonzalez	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-LA-10000134	Office Supplies	Labels	Avery 511	6.16	2	0	2.9568
2918	CA-2014-155047	8/27/2016	8/30/2016	First Class	SE-20110	Sanjit Engle	Consumer	United States	Dallas	Texas	75220	Central	OFF-AR-10003338	Office Supplies	Art	Eberhard Faber 3 1/2" Golf Pencils	5.952	1	0.2	0.372
1643	US-2011-134712	11/29/2013	12/4/2013	Standard Class	BS-11380	Bill Stewart	Corporate	United States	Skokie	Illinois	60076	Central	OFF-FA-10003112	Office Supplies	Fasteners	Staples	12.624	2	0.2	3.945
2649	CA-2011-131002	9/7/2013	9/12/2013	Second Class	TB-21400	Tom Boeckenhauer	Consumer	United States	Tulsa	Oklahoma	74133	Central	FUR-FU-10004665	Furniture	Furnishings	3M Polarizing Task Lamp with Clamp Arm, Light Gray	821.88	6	0	213.6888
4061	CA-2013-129196	11/2/2015	11/8/2015	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10002473	Technology	Accessories	Maxell 4.7GB DVD-R	68.112	3	0.2	17.8794
488	CA-2011-154627	10/29/2013	10/31/2013	First Class	SA-20830	Sue Ann Reed	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10001363	Technology	Phones	Apple iPhone 5S	2735.952	6	0.2	341.994
8523	US-2013-160206	4/2/2015	4/8/2015	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-PH-10000148	Technology	Phones	Cyber Acoustics AC-202b Speech Recognition Stereo Headset	12.99	1	0	0.2598
3653	CA-2014-109960	12/9/2016	12/11/2016	Second Class	DB-13210	Dean Braden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-BI-10001636	Office Supplies	Binders	Ibico Plastic and Wire Spiral Binding Combs	33.72	4	0	15.5112
5638	CA-2014-113208	3/26/2016	4/2/2016	Standard Class	ML-18040	Michelle Lonsdale	Corporate	United States	Dearborn	Michigan	48126	Central	FUR-FU-10004245	Furniture	Furnishings	Career Cubicle Clock, 8 1/4", Black	60.84	3	0	23.1192
9259	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	OFF-BI-10004654	Office Supplies	Binders	VariCap6 Expandable Binder	51.9	3	0	24.393
6447	US-2014-119816	3/4/2016	3/6/2016	Second Class	TT-21460	Tonja Turnell	Home Office	United States	Houston	Texas	77095	Central	FUR-FU-10004848	Furniture	Furnishings	Howard Miller 13-3/4" Diameter Brushed Chrome Round Wall Clock	103.5	5	0.6	-77.625
6083	US-2013-132577	11/23/2015	11/28/2015	Standard Class	JE-15475	Jeremy Ellison	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10004040	Office Supplies	Binders	Wilson Jones Impact Binders	6.216	6	0.8	-9.6348
6435	CA-2012-121405	3/30/2014	4/4/2014	Standard Class	FC-14335	Fred Chung	Corporate	United States	Chicago	Illinois	60610	Central	TEC-PH-10002890	Technology	Phones	AT&T 17929 Lendline Telephone	180.96	5	0.2	13.572
8301	CA-2012-109169	4/20/2014	4/24/2014	Standard Class	OT-18730	Olvera Toch	Consumer	United States	Detroit	Michigan	48234	Central	OFF-EN-10003296	Office Supplies	Envelopes	Tyvek Side-Opening Peel & Seel Expanding Envelopes	180.96	2	0	81.432
8036	CA-2012-119690	6/25/2014	6/28/2014	First Class	MV-17485	Mark Van Huff	Consumer	United States	Houston	Texas	77041	Central	OFF-LA-10001613	Office Supplies	Labels	Avery File Folder Labels	4.608	2	0.2	1.6704
4599	US-2014-169502	8/28/2016	9/1/2016	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Milwaukee	Wisconsin	53209	Central	OFF-AP-10001947	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	91.6	5	0	26.564
9788	CA-2014-144491	3/27/2016	4/1/2016	Standard Class	CJ-12010	Caroline Jumper	Consumer	United States	Houston	Texas	77070	Central	FUR-BO-10001811	Furniture	Bookcases	Atlantic Metals Mobile 5-Shelf Bookcases, Custom Colors	1023.332	5	0.32	-30.098
306	CA-2011-130960	12/30/2013	1/4/2014	Standard Class	KB-16600	Ken Brennan	Corporate	United States	Taylor	Michigan	48180	Central	OFF-AR-10003651	Office Supplies	Art	Newell 350	9.84	3	0	2.8536
7288	CA-2013-149965	6/21/2015	6/26/2015	Standard Class	BS-11365	Bill Shonely	Corporate	United States	Oklahoma City	Oklahoma	73120	Central	FUR-FU-10004270	Furniture	Furnishings	Executive Impressions 13" Clairmont Wall Clock	57.69	3	0	23.6529
3087	CA-2014-118773	2/10/2016	2/15/2016	Standard Class	TP-21415	Tom Prescott	Consumer	United States	Houston	Texas	77070	Central	FUR-FU-10000550	Furniture	Furnishings	Stacking Trays by OIC	3.984	2	0.6	-2.6892
7174	US-2014-141677	3/26/2016	3/30/2016	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Houston	Texas	77070	Central	TEC-CO-10002313	Technology	Copiers	Canon PC1080F Personal Copier	2399.96	5	0.2	569.9905
3895	US-2011-112200	11/22/2013	11/28/2013	Standard Class	TC-21475	Tony Chapman	Home Office	United States	Bolingbrook	Illinois	60440	Central	OFF-BI-10002571	Office Supplies	Binders	Avery Framed View Binder, EZD Ring (Locking), Navy, 1 1/2"	9.98	5	0.8	-16.467
1166	CA-2011-117709	5/4/2013	5/8/2013	Standard Class	PM-18940	Paul MacIntyre	Consumer	United States	Jackson	Michigan	49201	Central	OFF-BI-10001294	Office Supplies	Binders	Fellowes Binding Cases	46.8	4	0	21.06
9558	CA-2011-103086	10/17/2013	10/19/2013	Second Class	EB-14170	Evan Bailliet	Consumer	United States	Houston	Texas	77095	Central	FUR-FU-10004586	Furniture	Furnishings	G.E. Longer-Life Indoor Recessed Floodlight Bulbs	5.312	2	0.6	-1.5936
3173	US-2013-133879	3/22/2015	3/29/2015	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Chicago	Illinois	60623	Central	FUR-CH-10000665	Furniture	Chairs	Global Airflow Leather Mesh Back Chair, Black	528.43	5	0.3	0
165	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AR-10004441	Office Supplies	Art	BIC Brite Liner Highlighters	9.936	3	0.2	2.7324
4226	US-2011-102631	12/13/2013	12/17/2013	Standard Class	EB-13840	Ellis Ballard	Corporate	United States	Chicago	Illinois	60623	Central	FUR-FU-10003930	Furniture	Furnishings	Howard Miller 12-3/4 Diameter Accuwave DS  Wall Clock	94.428	3	0.6	-42.4926
3378	CA-2013-100671	11/2/2015	11/5/2015	First Class	CS-12490	Cindy Schnelling	Corporate	United States	Conroe	Texas	77301	Central	OFF-ST-10004950	Office Supplies	Storage	Tenex Personal Filing Tote With Secure Closure Lid, Black/Frost	111.672	9	0.2	6.9795
8844	CA-2011-141173	11/18/2013	11/20/2013	Second Class	JC-16105	Julie Creighton	Corporate	United States	Minneapolis	Minnesota	55407	Central	OFF-ST-10000885	Office Supplies	Storage	Fellowes Desktop Hanging File Manager	67.15	5	0	16.7875
663	CA-2012-146563	8/24/2014	8/28/2014	Standard Class	CB-12025	Cassandra Brandow	Consumer	United States	Arlington	Texas	76017	Central	OFF-BI-10003981	Office Supplies	Binders	Avery Durable Plastic 1" Binders	2.724	3	0.8	-4.2222
6987	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	OFF-AR-10004999	Office Supplies	Art	Newell 315	11.96	2	0	2.99
9392	CA-2014-162474	3/13/2016	3/16/2016	First Class	FH-14275	Frank Hawley	Corporate	United States	Aurora	Illinois	60505	Central	TEC-PH-10004700	Technology	Phones	PowerGen Dual USB Car Charger	7.992	1	0.2	2.5974
2402	CA-2014-145877	4/1/2016	4/4/2016	Second Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	OFF-ST-10000649	Office Supplies	Storage	Hanging Personal Folder File	94.2	6	0	23.55
4418	CA-2014-112900	4/9/2016	4/12/2016	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Detroit	Michigan	48205	Central	OFF-BI-10002867	Office Supplies	Binders	GBC Recycled Regency Composition Covers	478.24	8	0	219.9904
3879	CA-2011-151001	4/5/2013	4/7/2013	First Class	JG-15805	John Grady	Corporate	United States	Decatur	Illinois	62521	Central	OFF-ST-10003455	Office Supplies	Storage	Tenex File Box, Personal Filing Tote with Lid, Black	49.632	4	0.2	3.7224
9217	CA-2014-103765	11/24/2016	11/30/2016	Standard Class	JG-15310	Jason Gross	Corporate	United States	Odessa	Texas	79762	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	13.762	1	0.8	-24.7716
4372	US-2013-165078	11/6/2015	11/11/2015	Standard Class	MA-17995	Michelle Arnett	Home Office	United States	Lawrence	Indiana	46226	Central	OFF-LA-10000414	Office Supplies	Labels	Avery 503	51.75	5	0	24.84
3260	US-2013-162103	11/14/2015	11/18/2015	Standard Class	LB-16795	Laurel Beltran	Home Office	United States	Highland Park	Illinois	60035	Central	OFF-BI-10000285	Office Supplies	Binders	XtraLife ClearVue Slant-D Ring Binders by Cardinal	3.136	2	0.8	-4.704
6158	CA-2013-104150	8/4/2015	8/6/2015	Second Class	AG-10330	Alex Grayson	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-EN-10002504	Office Supplies	Envelopes	Tyvek  Top-Opening Peel & Seel Envelopes, Plain White	81.54	3	0	38.3238
6110	CA-2013-150007	9/12/2015	9/17/2015	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10004141	Office Supplies	Binders	Insertable Tab Indexes For Data Binders	1.908	3	0.8	-3.2436
671	US-2014-106663	6/9/2016	6/13/2016	Standard Class	MO-17800	Meg O'Connel	Home Office	United States	Chicago	Illinois	60653	Central	FUR-TA-10000688	Furniture	Tables	Chromcraft Bull-Nose Wood Round Conference Table Top, Wood Base	108.925	1	0.5	-71.8905
1172	US-2011-100279	3/10/2013	3/14/2013	Standard Class	SW-20275	Scott Williamson	Consumer	United States	Royal Oak	Michigan	48073	Central	OFF-PA-10002259	Office Supplies	Paper	Geographics Note Cards, Blank, White, 8 1/2" x 11"	22.38	2	0	10.7424
8903	CA-2013-150483	6/1/2015	6/5/2015	Standard Class	BP-11290	Beth Paige	Consumer	United States	Decatur	Illinois	62521	Central	FUR-CH-10000422	Furniture	Chairs	Global Highback Leather Tilter in Burgundy	191.079	3	0.3	-38.2158
1919	CA-2012-123673	10/30/2014	11/1/2014	Second Class	CH-12070	Cathy Hwang	Home Office	United States	Detroit	Michigan	48227	Central	TEC-PH-10001809	Technology	Phones	Panasonic KX T7736-B Digital phone	299.9	2	0	74.975
4188	CA-2014-112536	5/18/2016	5/23/2016	Standard Class	SG-20890	Susan Gilcrest	Corporate	United States	Mcallen	Texas	78501	Central	OFF-BI-10002571	Office Supplies	Binders	Avery Framed View Binder, EZD Ring (Locking), Navy, 1 1/2"	1.996	1	0.8	-3.2934
2481	CA-2014-141992	6/19/2016	6/25/2016	Standard Class	FO-14305	Frank Olsen	Consumer	United States	Dallas	Texas	75220	Central	OFF-ST-10003656	Office Supplies	Storage	Safco Industrial Wire Shelving	153.584	2	0.2	-32.6366
8283	CA-2012-154284	12/21/2014	12/26/2014	Second Class	SZ-20035	Sam Zeldin	Home Office	United States	Saint Charles	Illinois	60174	Central	TEC-MA-10004241	Technology	Machines	Star Micronics TSP800 TSP847IIU Receipt Printer	600.53	2	0.3	137.264
1141	CA-2013-152170	11/13/2015	11/16/2015	Second Class	FH-14275	Frank Hawley	Corporate	United States	La Porte	Indiana	46350	Central	OFF-BI-10002072	Office Supplies	Binders	Cardinal Slant-D Ring Binders	17.38	2	0	8.69
8876	US-2013-141264	8/14/2015	8/20/2015	Standard Class	CT-11995	Carol Triggs	Consumer	United States	Irving	Texas	75061	Central	OFF-SU-10003505	Office Supplies	Supplies	Premier Electric Letter Opener	185.376	2	0.2	-34.758
6849	US-2013-163461	6/19/2015	6/22/2015	First Class	BT-11440	Bobby Trafton	Consumer	United States	Frankfort	Illinois	60423	Central	OFF-PA-10003134	Office Supplies	Paper	Xerox 1937	76.864	2	0.2	26.9024
3111	CA-2013-121671	7/18/2015	7/23/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Springfield	Missouri	65807	Central	OFF-PA-10001934	Office Supplies	Paper	Xerox 1993	51.84	8	0	25.4016
9087	CA-2013-143406	9/27/2015	10/1/2015	Standard Class	LR-17035	Lisa Ryan	Corporate	United States	Houston	Texas	77041	Central	OFF-AP-10001564	Office Supplies	Appliances	Hoover Commercial Lightweight Upright Vacuum with E-Z Empty Dirt Cup	93.032	2	0.8	-251.1864
4489	CA-2012-162621	9/5/2014	9/11/2014	Standard Class	CA-12055	Cathy Armstrong	Home Office	United States	Houston	Texas	77036	Central	OFF-SU-10003567	Office Supplies	Supplies	Stiletto Hand Letter Openers	69.12	9	0.2	-14.688
4574	CA-2013-139395	12/13/2015	12/19/2015	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Jackson	Michigan	49201	Central	TEC-PH-10002103	Technology	Phones	Jabra SPEAK 410	657.93	7	0	184.2204
9862	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	OFF-ST-10002562	Office Supplies	Storage	Staple magnet	18.76	2	0	5.2528
7947	CA-2014-134194	12/25/2016	1/1/2017	Standard Class	GA-14725	Guy Armstrong	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10001116	Office Supplies	Binders	Wilson Jones 1" Hanging DublLock Ring Binders	3.168	3	0.8	-5.0688
6948	CA-2012-130365	4/25/2014	4/29/2014	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Aurora	Illinois	60505	Central	OFF-ST-10002574	Office Supplies	Storage	SAFCO Commercial Wire Shelving, Black	221.024	2	0.2	-55.256
4084	US-2014-151316	6/24/2016	6/30/2016	Standard Class	MC-17635	Matthew Clasen	Corporate	United States	Decatur	Illinois	62521	Central	OFF-PA-10000327	Office Supplies	Paper	Xerox 1971	10.272	3	0.2	3.21
9431	CA-2012-166219	8/28/2014	9/1/2014	Standard Class	BP-11185	Ben Peterman	Corporate	United States	Dallas	Texas	75081	Central	FUR-TA-10004607	Furniture	Tables	Hon 2111 Invitation Series Straight Table	103.481	1	0.3	-16.2613
239	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10000576	Furniture	Furnishings	Luxo Professional Fluorescent Magnifier Lamp with Clamp-Mount Base	419.68	5	0.6	-356.728
3970	US-2012-163685	6/1/2014	6/5/2014	Standard Class	KE-16420	Katrina Edelman	Corporate	United States	San Antonio	Texas	78207	Central	OFF-PA-10002606	Office Supplies	Paper	Xerox 1928	42.24	10	0.2	13.2
6531	CA-2011-103744	2/23/2013	2/27/2013	Standard Class	MG-17875	Michael Grace	Home Office	United States	El Paso	Texas	79907	Central	OFF-BI-10000320	Office Supplies	Binders	GBC Plastic Binding Combs	4.428	3	0.8	-6.8634
5571	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	TEC-PH-10001527	Technology	Phones	Plantronics MX500i Earset	34.36	1	0.2	-7.3015
5383	CA-2013-149195	9/6/2015	9/8/2015	Second Class	DM-13525	Don Miller	Corporate	United States	Houston	Texas	77070	Central	OFF-FA-10001843	Office Supplies	Fasteners	Staples	15.808	8	0.2	5.3352
7689	CA-2013-169838	11/26/2015	11/30/2015	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Jackson	Michigan	49201	Central	TEC-AC-10004518	Technology	Accessories	Memorex Mini Travel Drive 32 GB USB 2.0 Flash Drive	160	8	0	62.4
1592	US-2013-132423	4/16/2015	4/20/2015	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Grapevine	Texas	76051	Central	OFF-FA-10002988	Office Supplies	Fasteners	Ideal Clamps	8.04	5	0.2	2.9145
5899	CA-2013-167682	4/4/2015	4/10/2015	Standard Class	ZD-21925	Zuschuss Donatelli	Consumer	United States	Richmond	Indiana	47374	Central	TEC-PH-10000673	Technology	Phones	Plantronics Voyager Pro HD - Bluetooth Headset	259.96	4	0	124.7808
9285	CA-2011-161032	11/18/2013	11/23/2013	Standard Class	MK-17905	Michael Kennedy	Corporate	United States	Franklin	Wisconsin	53132	Central	FUR-CH-10001482	Furniture	Chairs	Office Star - Mesh Screen back chair with Vinyl seat	392.94	3	0	43.2234
3922	CA-2013-110044	6/29/2015	7/3/2015	Second Class	RF-19735	Roland Fjeld	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10001299	Technology	Phones	Polycom CX300 Desktop Phone USB VoIP phone	359.976	3	0.2	35.9976
3095	CA-2012-114468	8/23/2014	8/23/2014	Same Day	TD-20995	Tamara Dahlen	Consumer	United States	Bolingbrook	Illinois	60440	Central	OFF-PA-10000809	Office Supplies	Paper	Xerox 206	10.368	2	0.2	3.6288
9516	CA-2011-154165	2/17/2013	2/24/2013	Standard Class	DL-13315	Delfina Latchford	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AR-10003631	Office Supplies	Art	Staples in misc. colors	54.208	14	0.2	8.8088
1997	US-2014-147221	12/2/2016	12/4/2016	Second Class	JS-16030	Joy Smith	Consumer	United States	Houston	Texas	77036	Central	FUR-FU-10004020	Furniture	Furnishings	Advantus Panel Wall Acrylic Frame	8.752	4	0.6	-3.7196
8742	CA-2012-113222	11/9/2014	11/9/2014	Same Day	AG-10765	Anthony Garverick	Home Office	United States	Lawrence	Indiana	46226	Central	OFF-BI-10001890	Office Supplies	Binders	Avery Poly Binder Pockets	10.74	3	0	5.1552
9110	CA-2012-132941	5/25/2014	5/28/2014	First Class	MM-18280	Muhammed MacIntyre	Corporate	United States	Haltom City	Texas	76117	Central	TEC-AC-10003095	Technology	Accessories	Logitech G35 7.1-Channel Surround Sound Headset	207.984	2	0.2	36.3972
4775	CA-2014-119746	11/23/2016	11/27/2016	Standard Class	CM-12385	Christopher Martinez	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10004447	Technology	Phones	Toshiba IPT2010-SD IP Telephone	222.384	2	0.2	16.6788
7076	CA-2013-112256	7/24/2015	7/29/2015	Standard Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Mcallen	Texas	78501	Central	OFF-SU-10001165	Office Supplies	Supplies	Acme Elite Stainless Steel Scissors	13.344	2	0.2	1.0008
1618	CA-2012-130022	8/10/2014	8/16/2014	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Eagan	Minnesota	55122	Central	OFF-AR-10001915	Office Supplies	Art	Peel-Off China Markers	29.79	3	0	12.5118
265	CA-2013-125318	6/7/2015	6/14/2015	Standard Class	RC-19825	Roy Collins	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10001433	Technology	Phones	Cisco Small Business SPA 502G VoIP phone	328.224	4	0.2	28.7196
1140	CA-2013-152170	11/13/2015	11/16/2015	Second Class	FH-14275	Frank Hawley	Corporate	United States	La Porte	Indiana	46350	Central	OFF-AR-10003394	Office Supplies	Art	Newell 332	20.58	7	0	5.5566
212	CA-2012-101007	2/9/2014	2/13/2014	Second Class	MS-17980	Michael Stewart	Corporate	United States	Dallas	Texas	75220	Central	TEC-AC-10001266	Technology	Accessories	Memorex Micro Travel Drive 8 GB	20.8	2	0.2	6.5
6549	CA-2011-113880	3/1/2013	3/5/2013	Standard Class	VF-21715	Vicky Freymann	Home Office	United States	Elmhurst	Illinois	60126	Central	OFF-PA-10003036	Office Supplies	Paper	Black Print Carbonless 8 1/2" x 8 1/4" Rapid Memo Book	17.472	3	0.2	5.6784
9887	CA-2011-146997	1/23/2013	1/27/2013	Standard Class	SG-20605	Speros Goranitis	Consumer	United States	Lafayette	Indiana	47905	Central	OFF-FA-10003467	Office Supplies	Fasteners	Alliance Big Bands Rubber Bands, 12/Pack	5.94	3	0	0
72	CA-2014-114440	9/14/2016	9/17/2016	Second Class	TB-21520	Tracy Blumstein	Consumer	United States	Jackson	Michigan	49201	Central	OFF-PA-10004675	Office Supplies	Paper	Telephone Message Books with Fax/Mobile Section, 5 1/2" x 3 3/16"	19.05	3	0	8.763
4695	US-2012-138121	12/17/2014	12/17/2014	Same Day	JL-15835	John Lee	Consumer	United States	Detroit	Michigan	48205	Central	OFF-BI-10000320	Office Supplies	Binders	GBC Plastic Binding Combs	29.52	4	0	14.4648
4617	CA-2012-159863	9/4/2014	9/7/2014	Second Class	DS-13180	David Smith	Corporate	United States	Houston	Texas	77095	Central	TEC-AC-10000109	Technology	Accessories	Sony Micro Vault Click 16 GB USB 2.0 Flash Drive	134.376	3	0.2	6.7188
5073	CA-2011-124478	8/8/2013	8/12/2013	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Trenton	Michigan	48183	Central	TEC-PH-10001128	Technology	Phones	Motorola Droid Maxx	299.98	2	0	83.9944
2508	CA-2012-120397	7/2/2014	7/2/2014	Same Day	RB-19435	Richard Bierner	Consumer	United States	Houston	Texas	77070	Central	OFF-AP-10001293	Office Supplies	Appliances	Belkin 8 Outlet Surge Protector	32.784	4	0.8	-85.2384
9218	US-2014-118157	11/14/2016	11/17/2016	First Class	AW-10930	Arthur Wiediger	Home Office	United States	Minneapolis	Minnesota	55407	Central	OFF-EN-10004459	Office Supplies	Envelopes	Security-Tint Envelopes	15.28	2	0	7.4872
2232	CA-2014-157091	6/26/2016	7/1/2016	Standard Class	DB-13405	Denny Blanton	Consumer	United States	La Porte	Indiana	46350	Central	FUR-FU-10000293	Furniture	Furnishings	Eldon Antistatic Chair Mats for Low to Medium Pile Carpets	526.45	5	0	31.587
7760	CA-2013-158925	10/25/2015	10/29/2015	Standard Class	JP-15460	Jennifer Patt	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10003072	Office Supplies	Paper	Eureka Recycled Copy Paper 8 1/2" x 11", Ream	15.552	3	0.2	5.4432
1973	CA-2011-148950	12/14/2013	12/19/2013	Standard Class	JD-16015	Joy Daniels	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	5.104	4	0.8	-8.6768
1600	CA-2014-158876	11/19/2016	11/21/2016	Second Class	AB-10150	Aimee Bixby	Consumer	United States	Carrollton	Texas	75007	Central	OFF-AR-10003373	Office Supplies	Art	Boston School Pro Electric Pencil Sharpener, 1670	99.136	4	0.2	8.6744
211	CA-2014-135860	12/1/2016	12/7/2016	Standard Class	JH-15985	Joseph Holt	Consumer	United States	Saginaw	Michigan	48601	Central	OFF-ST-10001522	Office Supplies	Storage	Gould Plastics 18-Pocket Panel Bin, 34w x 5-1/4d x 20-1/2h	91.99	1	0	3.6796
6937	CA-2013-129847	9/3/2015	9/5/2015	First Class	TA-21385	Tom Ashbrook	Home Office	United States	Chicago	Illinois	60653	Central	FUR-FU-10000277	Furniture	Furnishings	Deflect-o DuraMat Antistatic Studded Beveled Mat for Medium Pile Carpeting	84.272	2	0.6	-75.8448
5729	CA-2014-117324	12/8/2016	12/13/2016	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-AP-10003590	Office Supplies	Appliances	Hoover WindTunnel Plus Canister Vacuum	1089.75	3	0	305.13
9162	CA-2013-160108	12/9/2015	12/13/2015	Standard Class	AG-10900	Arthur Gainer	Consumer	United States	Eau Claire	Wisconsin	54703	Central	FUR-BO-10003450	Furniture	Bookcases	Bush Westfield Collection Bookcases, Dark Cherry Finish	405.86	7	0	32.4688
3508	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	FUR-BO-10001608	Furniture	Bookcases	Hon Metal Bookcases, Black	193.0656	4	0.32	-19.8744
5159	CA-2014-163006	6/30/2016	7/4/2016	Second Class	GH-14410	Gary Hansen	Home Office	United States	Chicago	Illinois	60653	Central	FUR-FU-10003799	Furniture	Furnishings	Seth Thomas 13 1/2" Wall Clock	14.224	2	0.6	-10.3124
3140	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	FUR-FU-10001756	Furniture	Furnishings	Eldon Expressions Desk Accessory, Wood Photo Frame, Mahogany	22.848	3	0.6	-17.7072
7845	US-2014-123834	7/21/2016	7/25/2016	Standard Class	GM-14500	Gene McClure	Consumer	United States	Pharr	Texas	78577	Central	FUR-TA-10001676	Furniture	Tables	Hon 61000 Series Interactive Training Tables	124.404	4	0.3	-21.3264
458	US-2013-157945	9/27/2015	10/2/2015	Standard Class	NF-18385	Natalie Fritzler	Consumer	United States	Decatur	Illinois	62521	Central	FUR-CH-10002331	Furniture	Chairs	Hon 4700 Series Mobuis Mid-Back Task Chairs with Adjustable Arms	747.558	3	0.3	-96.1146
3948	CA-2013-119963	11/19/2015	11/23/2015	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Pasadena	Texas	77506	Central	OFF-AR-10003514	Office Supplies	Art	4009 Highlighters by Sanford	6.368	2	0.2	1.0348
240	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10004351	Furniture	Furnishings	Staple-based wall hangings	11.688	3	0.6	-4.6752
4284	CA-2011-103100	12/20/2013	12/23/2013	First Class	AB-10105	Adrian Barton	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-BI-10004600	Office Supplies	Binders	Ibico Ibimaster 300 Manual Binding System	1103.97	3	0	496.7865
9845	CA-2011-163867	6/3/2013	6/6/2013	First Class	RE-19450	Richard Eichhorn	Consumer	United States	Decatur	Illinois	62521	Central	FUR-FU-10001475	Furniture	Furnishings	Contract Clock, 14", Brown	61.544	7	0.6	-40.0036
5716	CA-2012-124107	10/9/2014	10/12/2014	Second Class	BM-11650	Brian Moss	Corporate	United States	Ann Arbor	Michigan	48104	Central	TEC-AC-10002049	Technology	Accessories	Logitech G19 Programmable Gaming Keyboard	619.95	5	0	111.591
5103	CA-2011-158442	3/17/2013	3/17/2013	Same Day	AZ-10750	Annie Zypern	Consumer	United States	Dallas	Texas	75217	Central	OFF-PA-10002365	Office Supplies	Paper	Xerox 1967	15.552	3	0.2	5.4432
1784	CA-2014-166317	9/22/2016	9/26/2016	Standard Class	JE-15610	Jim Epp	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-PA-10004475	Office Supplies	Paper	Xerox 1940	219.84	4	0	107.7216
9861	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	TEC-PH-10000169	Technology	Phones	ARKON Windshield Dashboard Air Vent Car Mount Holder	67.8	4	0	1.356
4704	CA-2013-166240	6/25/2015	6/29/2015	Standard Class	DH-13075	Dave Hallsten	Corporate	United States	Houston	Texas	77095	Central	OFF-AP-10002082	Office Supplies	Appliances	Holmes HEPA Air Purifier	8.712	2	0.8	-19.602
3329	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10001033	Office Supplies	Paper	Xerox 1893	262.336	8	0.2	95.0968
7662	CA-2011-105417	1/7/2013	1/12/2013	Standard Class	VS-21820	Vivek Sundaresam	Consumer	United States	Huntsville	Texas	77340	Central	OFF-BI-10003708	Office Supplies	Binders	Acco Four Pocket Poly Ring Binder with Label Holder, Smoke, 1"	10.43	7	0.8	-18.2525
7792	CA-2013-108364	12/20/2015	12/25/2015	Standard Class	BP-11050	Barry Pond	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10002012	Office Supplies	Binders	Wilson Jones Easy Flow II Sheet Lifters	1.8	5	0.8	-2.88
9859	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	OFF-ST-10001590	Office Supplies	Storage	Tenex Personal Project File with Scoop Front Design, Black	67.4	5	0	17.524
2151	US-2014-139969	11/19/2016	11/26/2016	Standard Class	AF-10870	Art Ferguson	Consumer	United States	College Station	Texas	77840	Central	FUR-CH-10001973	Furniture	Chairs	Office Star Flex Back Scooter Chair with White Frame	233.058	3	0.3	-53.2704
8146	US-2011-112949	6/20/2013	6/27/2013	Standard Class	Co-12640	Corey-Lock	Consumer	United States	Lawton	Oklahoma	73505	Central	OFF-AP-10001005	Office Supplies	Appliances	Honeywell Quietcare HEPA Air Cleaner	471.9	6	0	155.727
4266	US-2013-131611	11/6/2015	11/10/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Houston	Texas	77036	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	3.564	3	0.8	-6.237
6174	US-2011-106299	8/2/2013	8/8/2013	Standard Class	NZ-18565	Nick Zandusky	Home Office	United States	Springfield	Missouri	65807	Central	TEC-AC-10003237	Technology	Accessories	Memorex Micro Travel Drive 4 GB	21.2	2	0	9.116
5731	CA-2014-117324	12/8/2016	12/13/2016	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Madison	Wisconsin	53711	Central	FUR-BO-10003159	Furniture	Bookcases	Sauder Camden County Collection Libraries, Planked Cherry Finish	459.92	4	0	41.3928
1306	CA-2013-101966	7/15/2015	7/17/2015	Second Class	BM-11785	Bryan Mills	Consumer	United States	Houston	Texas	77036	Central	TEC-PH-10003437	Technology	Phones	Blue Parrot B250XT Professional Grade Wireless Bluetooth Headset with	419.944	7	0.2	52.493
6799	CA-2012-168809	8/25/2014	8/25/2014	Same Day	MC-18100	Mick Crebagga	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10002240	Furniture	Furnishings	Nu-Dell EZ-Mount Plastic Wall Frames	7.88	5	0.6	-3.94
1788	CA-2012-154326	2/15/2014	2/19/2014	Standard Class	RP-19855	Roy Phan	Corporate	United States	Kenosha	Wisconsin	53142	Central	TEC-PH-10001819	Technology	Phones	Innergie mMini Combo Duo USB Travel Charging Kit	134.97	3	0	64.7856
3938	CA-2012-118955	6/16/2014	6/20/2014	Standard Class	LS-17230	Lycoris Saunders	Consumer	United States	Grand Prairie	Texas	75051	Central	OFF-PA-10004156	Office Supplies	Paper	Xerox 188	27.216	3	0.2	9.8658
5201	CA-2013-103982	3/4/2015	3/9/2015	Standard Class	AA-10315	Alex Avila	Consumer	United States	Round Rock	Texas	78664	Central	TEC-PH-10000895	Technology	Phones	Polycom VVX 310 VoIP phone	431.976	3	0.2	32.3982
9512	CA-2011-130575	12/14/2013	12/16/2013	First Class	CS-11845	Cari Sayre	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10002353	Office Supplies	Binders	GBC VeloBind Cover Sets	9.264	3	0.8	-13.896
1575	CA-2011-101602	12/15/2013	12/18/2013	First Class	MC-18100	Mick Crebagga	Consumer	United States	El Paso	Texas	79907	Central	TEC-PH-10000169	Technology	Phones	ARKON Windshield Dashboard Air Vent Car Mount Holder	40.68	3	0.2	-9.153
5217	US-2014-159562	9/9/2016	9/15/2016	Standard Class	JB-16000	Joy Bell-	Consumer	United States	Roseville	Michigan	48066	Central	OFF-EN-10000461	Office Supplies	Envelopes	#10- 4 1/8" x 9 1/2" Recycled Envelopes	17.48	2	0	8.2156
210	CA-2014-135860	12/1/2016	12/7/2016	Standard Class	JH-15985	Joseph Holt	Consumer	United States	Saginaw	Michigan	48601	Central	OFF-FA-10000134	Office Supplies	Fasteners	Advantus Push Pins, Aluminum Head	52.29	9	0	16.2099
6331	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-ST-10003123	Office Supplies	Storage	Fellowes Bases and Tops For Staxonsteel/High-Stak Systems	66.58	2	0	15.9792
3513	CA-2014-140326	9/4/2016	9/6/2016	First Class	HW-14935	Helen Wasserman	Corporate	United States	Chicago	Illinois	60653	Central	FUR-BO-10000112	Furniture	Bookcases	Bush Birmingham Collection Bookcase, Dark Cherry	825.174	9	0.3	-117.882
245	CA-2011-131926	6/1/2013	6/6/2013	Second Class	DW-13480	Dianna Wilson	Home Office	United States	Lakeville	Minnesota	55044	Central	FUR-CH-10004063	Furniture	Chairs	Global Deluxe High-Back Manager's Chair	2001.86	7	0	580.5394
5418	CA-2011-132542	10/6/2013	10/8/2013	Second Class	AM-10360	Alice McCarthy	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-BI-10004099	Office Supplies	Binders	GBC VeloBinder Strips	15.36	2	0	7.68
9508	CA-2011-149104	4/5/2013	4/7/2013	Second Class	RD-19900	Ruben Dartt	Consumer	United States	Dearborn Heights	Michigan	48127	Central	OFF-BI-10004209	Office Supplies	Binders	Fellowes Twister Kit, Gray/Clear, 3/pkg	40.2	5	0	18.09
8460	CA-2011-126200	8/25/2013	8/29/2013	Standard Class	JE-15715	Joe Elijah	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10002225	Office Supplies	Binders	Square Ring Data Binders, Rigid 75 Pt. Covers, 11" x 14-7/8"	12.384	3	0.8	-19.8144
5222	CA-2014-117401	5/18/2016	5/22/2016	Second Class	PP-18955	Paul Prost	Home Office	United States	Springfield	Missouri	65807	Central	OFF-AP-10000938	Office Supplies	Appliances	Avanti 1.7 Cu. Ft. Refrigerator	706.86	7	0	197.9208
4577	CA-2013-139395	12/13/2015	12/19/2015	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Jackson	Michigan	49201	Central	OFF-ST-10000885	Office Supplies	Storage	Fellowes Desktop Hanging File Manager	26.86	2	0	6.715
3088	CA-2014-118773	2/10/2016	2/15/2016	Standard Class	TP-21415	Tom Prescott	Consumer	United States	Houston	Texas	77070	Central	OFF-AP-10000055	Office Supplies	Appliances	Belkin F9S820V06 8 Outlet Surge	12.992	2	0.8	-32.48
4478	CA-2014-130211	10/22/2016	10/22/2016	Same Day	BD-11620	Brian DeCherney	Consumer	United States	Lawton	Oklahoma	73505	Central	OFF-ST-10000129	Office Supplies	Storage	Fellowes Recycled Storage Drawers	333.09	3	0	23.3163
626	CA-2012-138009	11/29/2014	12/3/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Dearborn	Michigan	48126	Central	OFF-AR-10004042	Office Supplies	Art	BOSTON Model 1800 Electric Pencil Sharpeners, Putty/Woodgrain	161.82	9	0	46.9278
2160	CA-2013-159737	9/4/2015	9/10/2015	Standard Class	CS-11950	Carlos Soltero	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10004236	Office Supplies	Binders	XtraLife ClearVue Slant-D Ring Binder, White, 3"	8.808	3	0.8	-14.9736
1551	US-2014-124926	11/13/2016	11/18/2016	Second Class	ME-17320	Maria Etezadi	Home Office	United States	Houston	Texas	77095	Central	OFF-AP-10004868	Office Supplies	Appliances	Hoover Commercial Soft Guard Upright Vacuum And Disposable Filtration Bags	9.324	6	0.8	-24.7086
2006	CA-2011-111150	12/31/2013	1/4/2014	Standard Class	RW-19630	Rob Williams	Corporate	United States	Columbia	Missouri	65203	Central	OFF-AR-10000034	Office Supplies	Art	BIC Brite Liner Grip Highlighters, Assorted, 5/Pack	29.68	7	0	11.5752
8484	CA-2013-126284	9/21/2015	9/25/2015	Standard Class	EN-13780	Edward Nazzal	Consumer	United States	Grand Rapids	Michigan	49505	Central	OFF-BI-10004828	Office Supplies	Binders	GBC Poly Designer Binding Covers	83.7	5	0	41.013
42	CA-2014-120999	9/10/2016	9/15/2016	Standard Class	LC-16930	Linda Cazamias	Corporate	United States	Naperville	Illinois	60540	Central	TEC-PH-10004093	Technology	Phones	Panasonic Kx-TS550	147.168	4	0.2	16.5564
4874	CA-2014-164042	5/23/2016	5/27/2016	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Houston	Texas	77095	Central	OFF-ST-10002301	Office Supplies	Storage	Tennsco Commercial Shelving	48.816	3	0.2	-11.5938
438	CA-2013-147375	6/13/2015	6/15/2015	Second Class	PO-19180	Philisse Overcash	Home Office	United States	Chicago	Illinois	60623	Central	OFF-PA-10001970	Office Supplies	Paper	Xerox 1908	313.488	7	0.2	113.6394
5417	US-2014-125647	9/23/2016	9/28/2016	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10004188	Technology	Phones	OtterBox Commuter Series Case - Samsung Galaxy S4	39.984	2	0.2	-8.9964
9498	CA-2014-118213	11/5/2016	11/7/2016	First Class	AB-10060	Adam Bellavance	Home Office	United States	Greenwood	Indiana	46142	Central	OFF-PA-10002615	Office Supplies	Paper	Ampad Gold Fibre Wirebound Steno Books, 6" x 9", Gregg Ruled	4.41	1	0	2.0286
5623	US-2013-124163	9/26/2015	10/1/2015	Standard Class	SC-20695	Steve Chapman	Corporate	United States	La Crosse	Wisconsin	54601	Central	FUR-FU-10000755	Furniture	Furnishings	Eldon Expressions Mahogany Wood Desk Collection	68.64	11	0	17.16
6690	CA-2014-104108	12/2/2016	12/9/2016	Standard Class	RP-19855	Roy Phan	Corporate	United States	Houston	Texas	77095	Central	OFF-AR-10000817	Office Supplies	Art	Manco Dry-Lighter Erasable Highlighter	12.16	5	0.2	2.128
6434	CA-2012-121405	3/30/2014	4/4/2014	Standard Class	FC-14335	Fred Chung	Corporate	United States	Chicago	Illinois	60610	Central	OFF-PA-10001838	Office Supplies	Paper	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 300/Messages	23.52	5	0.2	8.526
8110	CA-2014-160122	11/18/2016	11/23/2016	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Chicago	Illinois	60623	Central	OFF-EN-10002592	Office Supplies	Envelopes	Peel & Seel Recycled Catalog Envelopes, Brown	55.584	6	0.2	20.844
4436	CA-2013-163398	5/4/2015	5/9/2015	Standard Class	CB-12415	Christy Brittain	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10000014	Office Supplies	Binders	Heavy-Duty E-Z-D Binders	2.182	1	0.8	-3.6003
1515	CA-2014-112809	8/18/2016	8/22/2016	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Dallas	Texas	75220	Central	OFF-BI-10001636	Office Supplies	Binders	Ibico Plastic and Wire Spiral Binding Combs	6.744	4	0.8	-11.4648
3307	CA-2011-104738	12/30/2013	1/1/2014	Second Class	SP-20620	Stefania Perrino	Corporate	United States	Laredo	Texas	78041	Central	TEC-PH-10000576	Technology	Phones	AT&T 1080 Corded phone	328.776	3	0.2	28.7679
1253	CA-2012-154956	7/4/2014	7/9/2014	Standard Class	IM-15070	Irene Maddox	Consumer	United States	Milwaukee	Wisconsin	53209	Central	TEC-PH-10004165	Technology	Phones	Mitel MiVoice 5330e IP Phone	1099.96	4	0	285.9896
5718	CA-2012-124107	10/9/2014	10/12/2014	Second Class	BM-11650	Brian Moss	Corporate	United States	Ann Arbor	Michigan	48104	Central	OFF-EN-10003286	Office Supplies	Envelopes	Staple envelope	57.96	7	0	27.2412
1850	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	OFF-ST-10000464	Office Supplies	Storage	Multi-Use Personal File Cart and Caster Set, Three Stacking Bins	34.76	1	0	9.7328
149	CA-2013-114489	12/6/2015	12/10/2015	Standard Class	JE-16165	Justin Ellison	Corporate	United States	Franklin	Wisconsin	53132	Central	TEC-PH-10001448	Technology	Phones	Anker Astro 15000mAh USB Portable Charger	149.97	3	0	5.9988
5295	CA-2014-144883	8/15/2016	8/19/2016	Standard Class	BO-11350	Bill Overfelt	Corporate	United States	Roseville	Minnesota	55113	Central	OFF-LA-10000305	Office Supplies	Labels	Avery 495	50.4	8	0	23.184
1281	CA-2013-160815	9/6/2015	9/7/2015	First Class	TR-21325	Toby Ritter	Consumer	United States	Cedar Rapids	Iowa	52402	Central	TEC-PH-10003505	Technology	Phones	Geemarc AmpliPOWER60	278.4	3	0	80.736
7840	US-2011-137869	3/28/2013	4/2/2013	Standard Class	CV-12295	Christina VanderZanden	Consumer	United States	Des Moines	Iowa	50315	Central	OFF-EN-10001509	Office Supplies	Envelopes	Poly String Tie Envelopes	6.12	3	0	2.8764
753	CA-2014-126074	10/2/2016	10/6/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Trenton	Michigan	48183	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	2.88	1	0	1.4112
443	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	OFF-ST-10003058	Office Supplies	Storage	Eldon Mobile Mega Data Cart  Mega Stackable  Add-On Trays	70.95	3	0	20.5755
6983	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10004728	Office Supplies	Binders	Wilson Jones Turn Tabs Binder Tool for Ring Binders	24.1	5	0	11.086
159	CA-2013-114104	11/21/2015	11/25/2015	Standard Class	NP-18670	Nora Paige	Consumer	United States	Edmond	Oklahoma	73034	Central	OFF-LA-10002475	Office Supplies	Labels	Avery 519	14.62	2	0	6.8714
9588	US-2014-129203	4/17/2016	4/22/2016	Standard Class	BM-11575	Brendan Murry	Corporate	United States	Chicago	Illinois	60653	Central	OFF-ST-10001418	Office Supplies	Storage	Carina Media Storage Towers in Natural & Black	195.136	4	0.2	-43.9056
8032	CA-2013-158806	1/7/2015	1/11/2015	Standard Class	NM-18520	Neoma Murray	Consumer	United States	Amarillo	Texas	79109	Central	OFF-PA-10004621	Office Supplies	Paper	Xerox 212	25.92	5	0.2	9.072
3494	CA-2014-142034	9/24/2016	9/28/2016	Standard Class	KB-16240	Karen Bern	Corporate	United States	Saint Cloud	Minnesota	56301	Central	TEC-AC-10002305	Technology	Accessories	KeyTronic E03601U1 - Keyboard - Beige	72	4	0	12.96
594	CA-2011-135405	1/9/2013	1/13/2013	Standard Class	MS-17830	Melanie Seite	Consumer	United States	Laredo	Texas	78041	Central	TEC-AC-10001266	Technology	Accessories	Memorex Micro Travel Drive 8 GB	31.2	3	0.2	9.75
3585	CA-2012-121650	12/10/2014	12/16/2014	Standard Class	KD-16495	Keith Dawkins	Corporate	United States	Jackson	Michigan	49201	Central	FUR-CH-10004289	Furniture	Chairs	Global Super Steno Chair	191.96	2	0	32.6332
1417	CA-2012-126697	9/21/2014	9/24/2014	First Class	SV-20815	Stuart Van	Corporate	United States	Houston	Texas	77041	Central	TEC-PH-10002922	Technology	Phones	ShoreTel ShorePhone IP 230 VoIP phone	946.344	7	0.2	118.293
1975	CA-2011-148950	12/14/2013	12/19/2013	Standard Class	JD-16015	Joy Daniels	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10002718	Technology	Accessories	Belkin Standard 104 key USB Keyboard	35.016	3	0.2	-2.1885
8674	CA-2014-163265	2/17/2016	2/22/2016	Standard Class	JS-16030	Joy Smith	Consumer	United States	Decatur	Illinois	62521	Central	FUR-CH-10004063	Furniture	Chairs	Global Deluxe High-Back Manager's Chair	600.558	3	0.3	-8.5794
8776	CA-2013-163636	12/6/2015	12/10/2015	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Chicago	Illinois	60623	Central	OFF-AR-10001547	Office Supplies	Art	Newell 311	3.536	2	0.2	0.3094
4615	CA-2013-144540	9/6/2015	9/11/2015	Standard Class	GH-14410	Gary Hansen	Home Office	United States	Houston	Texas	77070	Central	OFF-AP-10002457	Office Supplies	Appliances	Eureka The Boss Plus 12-Amp Hard Box Upright Vacuum, Red	62.79	3	0.8	-166.3935
5678	CA-2011-126802	12/29/2013	1/5/2014	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10000193	Furniture	Furnishings	Tenex Chairmats For Use with Hard Floors	38.976	3	0.6	-50.6688
6219	CA-2013-160220	10/21/2015	10/27/2015	Standard Class	JS-16030	Joy Smith	Consumer	United States	Trenton	Michigan	48183	Central	TEC-PH-10001300	Technology	Phones	iKross Bluetooth Portable Keyboard + Cell Phone Stand Holder + Brush for Apple iPhone 5S 5C 5, 4S 4	125.7	6	0	35.196
7306	CA-2011-137274	3/29/2013	4/2/2013	Standard Class	MG-18145	Mike Gockenbach	Consumer	United States	Plano	Texas	75023	Central	FUR-TA-10001889	Furniture	Tables	Bush Advantage Collection Racetrack Conference Table	890.841	3	0.3	-152.7156
4112	CA-2012-153717	12/25/2014	1/1/2015	Standard Class	DL-13495	Dionis Lloyd	Corporate	United States	Detroit	Michigan	48227	Central	OFF-PA-10002160	Office Supplies	Paper	Xerox 1978	17.34	3	0	8.4966
3931	CA-2013-162082	3/15/2015	3/18/2015	First Class	JS-15880	John Stevenson	Consumer	United States	Harlingen	Texas	78550	Central	OFF-AR-10001044	Office Supplies	Art	BOSTON Ranger #55 Pencil Sharpener, Black	145.544	7	0.2	16.3737
1509	CA-2014-108294	12/10/2016	12/10/2016	Same Day	LS-16975	Lindsay Shagiari	Home Office	United States	Omaha	Nebraska	68104	Central	OFF-BI-10004965	Office Supplies	Binders	Ibico Covers for Plastic or Wire Binding Elements	34.5	3	0	15.525
4230	CA-2014-100223	7/5/2016	7/10/2016	Standard Class	LS-16945	Linda Southworth	Corporate	United States	Dallas	Texas	75220	Central	FUR-FU-10003601	Furniture	Furnishings	Deflect-o RollaMat Studded, Beveled Mat for Medium Pile Carpeting	332.028	9	0.6	-348.6294
1448	CA-2014-102337	6/13/2016	6/16/2016	First Class	SD-20485	Shirley Daniels	Home Office	United States	Chicago	Illinois	60653	Central	TEC-PH-10002564	Technology	Phones	OtterBox Defender Series Case - Samsung Galaxy S4	47.984	2	0.2	5.998
3106	CA-2013-103037	7/26/2015	7/30/2015	Standard Class	KH-16630	Ken Heidel	Corporate	United States	Houston	Texas	77070	Central	OFF-LA-10004345	Office Supplies	Labels	Avery 493	15.712	4	0.2	5.6956
8927	CA-2013-168032	1/30/2015	2/3/2015	Standard Class	DF-13135	David Flashing	Consumer	United States	Rockford	Illinois	61107	Central	FUR-TA-10004256	Furniture	Tables	Bretford “Just In Time” Height-Adjustable Multi-Task Work Tables	626.1	3	0.5	-538.446
4516	US-2014-111920	10/22/2016	10/26/2016	Standard Class	PS-18970	Paul Stevenson	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-AR-10003179	Office Supplies	Art	Dixon Ticonderoga Core-Lock Colored Pencils	36.44	4	0	12.0252
1521	CA-2014-109946	4/16/2016	4/21/2016	Standard Class	PL-18925	Paul Lucas	Home Office	United States	Chicago	Illinois	60610	Central	OFF-AR-10001419	Office Supplies	Art	Newell 325	16.52	5	0.2	2.065
5114	CA-2013-147970	1/31/2015	2/2/2015	Second Class	AB-10150	Aimee Bixby	Consumer	United States	Dallas	Texas	75220	Central	OFF-PA-10003936	Office Supplies	Paper	Xerox 1994	15.552	3	0.2	5.4432
4077	CA-2012-100685	12/19/2014	12/21/2014	Second Class	SM-20950	Suzanne McNair	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-BI-10003094	Office Supplies	Binders	Self-Adhesive Ring Binder Labels	7.04	2	0	3.3088
3076	CA-2011-143903	7/20/2013	7/24/2013	Standard Class	KM-16375	Katherine Murray	Home Office	United States	Dallas	Texas	75217	Central	OFF-ST-10003306	Office Supplies	Storage	Letter Size Cart	342.864	3	0.2	38.5722
8573	CA-2011-121629	11/28/2013	12/2/2013	Standard Class	BT-11680	Brian Thompson	Consumer	United States	Houston	Texas	77041	Central	TEC-MA-10004679	Technology	Machines	StarTech.com 10/100 VDSL2 Ethernet Extender Kit	998.85	5	0.4	-199.77
3427	CA-2012-153381	9/24/2014	9/28/2014	Standard Class	DE-13255	Deanra Eno	Home Office	United States	Dubuque	Iowa	52001	Central	FUR-CH-10000988	Furniture	Chairs	Hon Olson Stacker Stools	1408.1	10	0	394.268
4408	CA-2013-100041	11/21/2015	11/26/2015	Standard Class	BF-10975	Barbara Fisher	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10000418	Office Supplies	Paper	Xerox 189	314.55	3	0	150.984
8901	CA-2013-150483	6/1/2015	6/5/2015	Standard Class	BP-11290	Beth Paige	Consumer	United States	Decatur	Illinois	62521	Central	FUR-FU-10001379	Furniture	Furnishings	Executive Impressions 16-1/2" Circular Wall Clock	32.064	3	0.6	-12.8256
9226	CA-2014-121160	11/4/2016	11/4/2016	Same Day	FM-14290	Frank Merwin	Home Office	United States	Bryan	Texas	77803	Central	OFF-BI-10004040	Office Supplies	Binders	Wilson Jones Impact Binders	4.144	4	0.8	-6.4232
3317	CA-2014-161739	11/10/2016	11/15/2016	Second Class	EB-13750	Edward Becker	Corporate	United States	Round Rock	Texas	78664	Central	FUR-FU-10001468	Furniture	Furnishings	Tenex Antistatic Computer Chair Mats	341.96	5	0.6	-427.45
7989	US-2013-117793	8/24/2015	8/30/2015	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Sheboygan	Wisconsin	53081	Central	OFF-LA-10003537	Office Supplies	Labels	Avery 515	37.59	3	0	17.6673
1617	CA-2012-130022	8/10/2014	8/16/2014	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Eagan	Minnesota	55122	Central	OFF-LA-10002043	Office Supplies	Labels	Avery 489	41.4	4	0	19.872
7386	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-PA-10001838	Office Supplies	Paper	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 300/Messages	17.64	3	0	8.6436
8582	CA-2011-130673	5/20/2013	5/22/2013	Second Class	MC-17590	Matt Collister	Corporate	United States	San Marcos	Texas	78666	Central	OFF-PA-10000289	Office Supplies	Paper	Xerox 213	10.368	2	0.2	3.6288
6252	CA-2011-101147	12/2/2013	12/4/2013	First Class	MC-17575	Matt Collins	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AP-10004249	Office Supplies	Appliances	Staple holder	2.394	1	0.8	-6.3441
8984	CA-2013-110898	3/7/2015	3/13/2015	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60623	Central	FUR-FU-10003773	Furniture	Furnishings	Eldon Cleatmat Plus Chair Mats for High Pile Carpets	159.04	5	0.6	-194.824
6057	CA-2013-113551	8/19/2015	8/21/2015	First Class	NF-18385	Natalie Fritzler	Consumer	United States	Edinburg	Texas	78539	Central	OFF-PA-10004665	Office Supplies	Paper	Advantus Motivational Note Cards	83.84	8	0.2	30.392
7175	US-2014-141677	3/26/2016	3/30/2016	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Houston	Texas	77070	Central	OFF-PA-10002581	Office Supplies	Paper	Xerox 1951	74.352	3	0.2	23.235
8034	CA-2012-119690	6/25/2014	6/28/2014	First Class	MV-17485	Mark Van Huff	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10000201	Office Supplies	Binders	Avery Triangle Shaped Sheet Lifters, Black, 2/Pack	0.984	2	0.8	-1.476
744	US-2013-146710	8/28/2015	9/2/2015	Standard Class	SS-20875	Sung Shariari	Consumer	United States	Dallas	Texas	75220	Central	OFF-PA-10002615	Office Supplies	Paper	Ampad Gold Fibre Wirebound Steno Books, 6" x 9", Gregg Ruled	3.528	1	0.2	1.1466
2207	US-2011-103905	7/14/2013	7/20/2013	Standard Class	AW-10930	Arthur Wiediger	Home Office	United States	Aurora	Illinois	60505	Central	OFF-BI-10001098	Office Supplies	Binders	Acco D-Ring Binder w/DublLock	29.932	7	0.8	-46.3946
9809	CA-2014-145093	7/21/2016	7/26/2016	Standard Class	PT-19090	Pete Takahito	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10001116	Office Supplies	Binders	Wilson Jones 1" Hanging DublLock Ring Binders	2.112	2	0.8	-3.3792
2033	CA-2013-128923	12/10/2015	12/14/2015	Standard Class	GB-14530	George Bell	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-PA-10002250	Office Supplies	Paper	Things To Do Today Pad	9.392	2	0.2	3.2872
5038	CA-2014-141719	11/17/2016	11/21/2016	Second Class	EG-13900	Emily Grady	Consumer	United States	Naperville	Illinois	60540	Central	TEC-AC-10003610	Technology	Accessories	Logitech Illuminated - Keyboard	239.96	5	0.2	83.986
246	CA-2011-131926	6/1/2013	6/6/2013	Second Class	DW-13480	Dianna Wilson	Home Office	United States	Lakeville	Minnesota	55044	Central	OFF-ST-10002276	Office Supplies	Storage	Safco Steel Mobile File Cart	166.72	2	0	41.68
7930	CA-2014-167549	7/25/2016	7/27/2016	First Class	EM-14200	Evan Minnotte	Home Office	United States	Dallas	Texas	75217	Central	FUR-TA-10004767	Furniture	Tables	Safco Drafting Table	298.116	6	0.3	-4.2588
2824	CA-2014-131016	9/18/2016	9/20/2016	First Class	DC-12850	Dan Campbell	Consumer	United States	Arlington	Texas	76017	Central	OFF-ST-10000352	Office Supplies	Storage	Acco Perma 2700 Stacking Storage Drawers	47.584	2	0.2	-2.974
5078	CA-2011-134572	4/20/2013	4/22/2013	Second Class	SV-20365	Seth Vernon	Consumer	United States	Houston	Texas	77070	Central	FUR-TA-10004442	Furniture	Tables	Riverside Furniture Stanwyck Manor Table Series	401.59	2	0.3	-131.951
8662	CA-2012-131856	5/12/2014	5/17/2014	Standard Class	JG-15160	James Galang	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10000175	Furniture	Furnishings	DAX Wood Document Frame.	21.968	4	0.6	-15.9268
3739	CA-2013-133340	12/10/2015	12/14/2015	Standard Class	LH-17155	Logan Haushalter	Consumer	United States	Jackson	Michigan	49201	Central	TEC-PH-10003988	Technology	Phones	LF Elite 3D Dazzle Designer Hard Case Cover, Lf Stylus Pen and Wiper For Apple Iphone 5c Mini Lite	10.9	1	0	3.052
1658	CA-2011-127159	5/12/2013	5/15/2013	First Class	HL-15040	Hunter Lopez	Consumer	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10000010	Furniture	Furnishings	DAX Value U-Channel Document Frames, Easel Back	34.79	7	0	10.7849
1044	CA-2014-115651	7/9/2016	7/12/2016	First Class	NS-18640	Noel Staavos	Corporate	United States	Chicago	Illinois	60610	Central	OFF-AR-10001130	Office Supplies	Art	Quartet Alpha White Chalk, 12/Pack	8.84	5	0.2	2.9835
23	CA-2013-137330	12/10/2015	12/14/2015	Standard Class	KB-16585	Ken Black	Corporate	United States	Fremont	Nebraska	68025	Central	OFF-AP-10001492	Office Supplies	Appliances	Acco Six-Outlet Power Strip, 4' Cord Length	60.34	7	0	15.6884
6051	CA-2012-153878	4/25/2014	4/30/2014	Standard Class	TS-21655	Trudy Schmidt	Consumer	United States	Milwaukee	Wisconsin	53209	Central	OFF-AR-10000658	Office Supplies	Art	Newell 324	57.75	5	0	16.17
6316	CA-2011-100762	11/24/2013	11/29/2013	Standard Class	NG-18355	Nat Gilpin	Corporate	United States	Jackson	Michigan	49201	Central	OFF-LA-10003930	Office Supplies	Labels	Dot Matrix Printer Tape Reel Labels, White, 5000/Box	196.62	2	0	96.3438
9625	CA-2014-137449	6/29/2016	6/30/2016	First Class	ME-17725	Max Engle	Consumer	United States	Dallas	Texas	75220	Central	FUR-TA-10002855	Furniture	Tables	Bevis Round Conference Table Top & Single Column Base	307.314	3	0.3	-39.5118
7408	CA-2014-152079	1/21/2016	1/22/2016	First Class	ML-17410	Maris LaWare	Consumer	United States	Chicago	Illinois	60653	Central	OFF-LA-10001613	Office Supplies	Labels	Avery File Folder Labels	11.52	5	0.2	4.176
1046	CA-2014-152702	10/12/2016	10/16/2016	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Rockford	Illinois	61107	Central	FUR-CH-10002304	Furniture	Chairs	Global Stack Chair without Arms, Black	254.604	14	0.3	-18.186
1885	CA-2014-154718	1/20/2016	1/24/2016	Second Class	DL-12865	Dan Lawera	Consumer	United States	Keller	Texas	76248	Central	OFF-LA-10003714	Office Supplies	Labels	Avery 510	6	2	0.2	2.1
5098	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10004965	Office Supplies	Binders	Ibico Covers for Plastic or Wire Binding Elements	4.6	2	0.8	-8.05
8933	CA-2014-143252	12/18/2016	12/24/2016	Standard Class	HE-14800	Harold Engle	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10002331	Technology	Accessories	Maxell 74 Minute CDR, 10/Pack	29.34	3	0	10.8558
8021	CA-2014-167227	11/2/2016	11/5/2016	First Class	NP-18670	Nora Paige	Consumer	United States	Saint Louis	Missouri	63116	Central	OFF-PA-10001838	Office Supplies	Paper	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 300/Messages	11.76	2	0	5.7624
8926	CA-2013-168032	1/30/2015	2/3/2015	Standard Class	DF-13135	David Flashing	Consumer	United States	Rockford	Illinois	61107	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	1.728	3	0.8	-2.6784
4699	US-2012-138121	12/17/2014	12/17/2014	Same Day	JL-15835	John Lee	Consumer	United States	Detroit	Michigan	48205	Central	FUR-FU-10002116	Furniture	Furnishings	Tenex Carpeted, Granite-Look or Clear Contemporary Contour Shape Chair Mats	212.13	3	0	14.8491
6329	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-BI-10000605	Office Supplies	Binders	Acco Pressboard Covers with Storage Hooks, 9 1/2" x 11", Executive Red	19.05	5	0	8.9535
676	CA-2014-130351	12/5/2016	12/8/2016	First Class	RB-19570	Rob Beeghly	Consumer	United States	Columbus	Indiana	47201	Central	TEC-AC-10003832	Technology	Accessories	Imation 16GB Mini TravelDrive USB 2.0 Flash Drive	99.39	3	0	40.7499
4181	CA-2014-128426	10/7/2016	10/11/2016	Standard Class	JK-15730	Joe Kamberova	Consumer	United States	Houston	Texas	77036	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	4.24	5	0.8	-6.36
3032	CA-2012-168480	9/21/2014	9/27/2014	Standard Class	DM-12955	Dario Medina	Corporate	United States	Lincoln Park	Michigan	48146	Central	OFF-AR-10001044	Office Supplies	Art	BOSTON Ranger #55 Pencil Sharpener, Black	25.99	1	0	7.5371
7301	CA-2011-163468	11/18/2013	11/21/2013	First Class	JK-15730	Joe Kamberova	Consumer	United States	Des Plaines	Illinois	60016	Central	FUR-BO-10003546	Furniture	Bookcases	Hon 4-Shelf Metal Bookcases	424.116	6	0.3	-30.294
3586	CA-2012-121650	12/10/2014	12/16/2014	Standard Class	KD-16495	Keith Dawkins	Corporate	United States	Jackson	Michigan	49201	Central	OFF-LA-10001045	Office Supplies	Labels	Permanent Self-Adhesive File Folder Labels for Typewriters by Universal	2.61	1	0	1.2006
5290	CA-2011-146283	9/8/2013	9/15/2013	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10002259	Office Supplies	Paper	Geographics Note Cards, Blank, White, 8 1/2" x 11"	17.904	2	0.2	6.2664
1675	CA-2012-143077	9/17/2014	9/21/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Houston	Texas	77041	Central	FUR-FU-10003535	Furniture	Furnishings	Howard Miller Distant Time Traveler Alarm Clock	21.936	2	0.6	-10.4196
8316	CA-2011-161508	7/12/2013	7/16/2013	Standard Class	PV-18985	Paul Van Hugh	Home Office	United States	League City	Texas	77573	Central	OFF-AR-10003158	Office Supplies	Art	Fluorescent Highlighters by Dixon	22.288	7	0.2	3.9004
7371	CA-2011-107769	10/28/2013	11/1/2013	Standard Class	BT-11395	Bill Tyler	Corporate	United States	Garden City	Kansas	67846	Central	TEC-PH-10001336	Technology	Phones	Digium D40 VoIP phone	257.98	2	0	74.8142
402	CA-2013-108987	9/9/2015	9/11/2015	Second Class	AG-10675	Anna Gayman	Consumer	United States	Houston	Texas	77036	Central	TEC-AC-10000158	Technology	Accessories	Sony 64GB Class 10 Micro SDHC R40 Memory Card	57.584	2	0.2	0.7198
3334	CA-2014-122595	12/14/2016	12/20/2016	Standard Class	GM-14455	Gary Mitchum	Home Office	United States	Chicago	Illinois	60653	Central	FUR-FU-10002963	Furniture	Furnishings	Master Caster Door Stop, Gray	2.032	1	0.6	-1.3208
4576	CA-2013-139395	12/13/2015	12/19/2015	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Jackson	Michigan	49201	Central	OFF-AR-10003732	Office Supplies	Art	Newell 333	13.9	5	0	3.614
6740	CA-2011-144029	5/26/2013	5/31/2013	Standard Class	MM-18055	Michelle Moray	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10001837	Office Supplies	Storage	SAFCO Mobile Desk Side File, Wire Frame	102.624	3	0.2	7.6968
9510	CA-2011-149104	4/5/2013	4/7/2013	Second Class	RD-19900	Ruben Dartt	Consumer	United States	Dearborn Heights	Michigan	48127	Central	OFF-ST-10000991	Office Supplies	Storage	Space Solutions HD Industrial Steel Shelving.	689.82	6	0	20.6946
9407	CA-2011-152618	3/14/2013	3/17/2013	First Class	RB-19465	Rick Bensley	Home Office	United States	Chicago	Illinois	60653	Central	OFF-PA-10001215	Office Supplies	Paper	Xerox 1963	8.448	2	0.2	2.64
6766	CA-2014-100615	4/20/2016	4/24/2016	Standard Class	SJ-20215	Sarah Jordon	Consumer	United States	Chicago	Illinois	60653	Central	FUR-CH-10002602	Furniture	Chairs	DMI Arturo Collection Mission-style Design Wood Chair	317.058	3	0.3	-18.1176
5831	CA-2013-122063	12/4/2015	12/8/2015	Standard Class	MM-17920	Michael Moore	Consumer	United States	Richmond	Indiana	47374	Central	FUR-CH-10004754	Furniture	Chairs	Global Stack Chair with Arms, Black	29.98	1	0	8.0946
3161	US-2011-150924	9/12/2013	9/16/2013	Second Class	PT-19090	Pete Takahito	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10004040	Office Supplies	Binders	Wilson Jones Impact Binders	5.18	5	0.8	-8.029
8184	CA-2014-155642	5/18/2016	5/22/2016	Standard Class	BM-11575	Brendan Murry	Corporate	United States	Chicago	Illinois	60653	Central	FUR-FU-10001918	Furniture	Furnishings	C-Line Cubicle Keepers Polyproplyene Holder With Velcro Backings	1.892	1	0.6	-0.9933
4439	CA-2013-162726	12/28/2015	1/3/2016	Standard Class	MT-17815	Meg Tillman	Consumer	United States	Port Arthur	Texas	77642	Central	OFF-PA-10001972	Office Supplies	Paper	Xerox 214	10.368	2	0.2	3.6288
5732	CA-2014-117324	12/8/2016	12/13/2016	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-PA-10002713	Office Supplies	Paper	Adams Phone Message Book, 200 Message Capacity, 8 1/16” x 11”	27.52	4	0	12.6592
2528	CA-2012-124541	4/6/2014	4/10/2014	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10004209	Office Supplies	Binders	Fellowes Twister Kit, Gray/Clear, 3/pkg	9.648	6	0.8	-16.884
5939	CA-2014-122077	5/19/2016	5/25/2016	Standard Class	JF-15295	Jason Fortune-	Consumer	United States	Plano	Texas	75023	Central	TEC-PH-10003811	Technology	Phones	Jabra Supreme Plus Driver Edition Headset	95.992	1	0.2	9.5992
2595	CA-2014-149048	5/13/2016	5/17/2016	Standard Class	BM-11650	Brian Moss	Corporate	United States	Columbus	Indiana	47201	Central	OFF-EN-10003296	Office Supplies	Envelopes	Tyvek Side-Opening Peel & Seel Expanding Envelopes	180.96	2	0	81.432
4927	CA-2014-117653	10/19/2016	10/23/2016	Standard Class	MO-17500	Mary O'Rourke	Consumer	United States	Chicago	Illinois	60623	Central	FUR-TA-10003008	Furniture	Tables	Lesro Round Back Collection Coffee Table, End Table	91.275	1	0.5	-67.5435
9892	US-2013-115441	7/26/2015	7/29/2015	Second Class	SH-19975	Sally Hughsby	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10003116	Technology	Accessories	Memorex Froggy Flash Drive 8 GB	124.25	7	0	48.4575
4407	CA-2013-100041	11/21/2015	11/26/2015	Standard Class	BF-10975	Barbara Fisher	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10001622	Office Supplies	Paper	Ampad Poly Cover Wirebound Steno Book, 6" x 9" Assorted Colors, Gregg Ruled	9.08	2	0	4.086
2812	CA-2012-135685	11/16/2014	11/18/2014	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10001185	Furniture	Furnishings	Advantus Employee of the Month Certificate Frame, 11 x 13-1/2	185.58	6	0	76.0878
808	CA-2012-140921	2/3/2014	2/5/2014	First Class	AA-10375	Allen Armold	Consumer	United States	Omaha	Nebraska	68104	Central	FUR-FU-10003347	Furniture	Furnishings	Coloredge Poster Frame	28.4	2	0	11.076
7850	CA-2013-104311	5/3/2015	5/7/2015	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Irving	Texas	75061	Central	OFF-ST-10002957	Office Supplies	Storage	Sterilite Show Offs Storage Containers	12.672	3	0.2	-3.168
15	US-2012-118983	11/22/2014	11/26/2014	Standard Class	HP-14815	Harold Pawlan	Home Office	United States	Fort Worth	Texas	76106	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	68.81	5	0.8	-123.858
4027	CA-2014-139311	8/11/2016	8/13/2016	First Class	SF-20965	Sylvia Foulston	Corporate	United States	Bedford	Texas	76021	Central	OFF-AR-10004582	Office Supplies	Art	BIC Brite Liner Grip Highlighters	9.184	7	0.2	2.87
1113	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10002609	Office Supplies	Binders	Avery Hidden Tab Dividers for Binding Systems	1.192	2	0.8	-2.0264
3403	CA-2012-129700	5/4/2014	5/5/2014	First Class	LA-16780	Laura Armstrong	Corporate	United States	Tinley Park	Illinois	60477	Central	FUR-FU-10001940	Furniture	Furnishings	Staple-based wall hangings	22.288	7	0.6	-8.9152
7387	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-ST-10004340	Office Supplies	Storage	Fellowes Mobile File Cart, Black	373.08	6	0	100.7316
6764	CA-2013-144764	9/3/2015	9/9/2015	Standard Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10002485	Office Supplies	Storage	Rogers Deluxe File Chest	35.168	2	0.2	-8.3524
2233	CA-2014-132122	7/9/2016	7/14/2016	Standard Class	JH-15820	John Huston	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10003692	Office Supplies	Storage	Recycled Steel Personal File for Hanging File Folders	228.92	5	0.2	14.3075
8440	CA-2014-114370	3/14/2016	3/17/2016	Second Class	BN-11470	Brad Norvell	Corporate	United States	Chicago	Illinois	60623	Central	TEC-PH-10000213	Technology	Phones	Seidio BD2-HK3IPH5-BK DILEX Case and Holster Combo for Apple iPhone 5/5s - Black	49.616	2	0.2	4.9616
3379	CA-2014-142867	3/17/2016	3/21/2016	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Houston	Texas	77095	Central	OFF-BI-10003166	Office Supplies	Binders	GBC Plasticlear Binding Covers	13.776	6	0.8	-22.0416
5679	CA-2013-143924	7/29/2015	8/4/2015	Standard Class	SC-20680	Steve Carroll	Home Office	United States	Holland	Michigan	49423	Central	OFF-FA-10000735	Office Supplies	Fasteners	Staples	20.44	7	0	9.198
51	CA-2012-115742	4/18/2014	4/22/2014	Standard Class	DP-13000	Darren Powers	Consumer	United States	New Albany	Indiana	47150	Central	OFF-LA-10002762	Office Supplies	Labels	Avery 485	75.18	6	0	35.3346
7074	CA-2013-112256	7/24/2015	7/29/2015	Standard Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Mcallen	Texas	78501	Central	OFF-AR-10001953	Office Supplies	Art	Boston 1645 Deluxe Heavier-Duty Electric Pencil Sharpener	175.92	5	0.2	15.393
5304	US-2011-139500	11/16/2013	11/20/2013	Standard Class	AB-10165	Alan Barnes	Consumer	United States	Decatur	Illinois	62521	Central	FUR-CH-10002017	Furniture	Chairs	SAFCO Optional Arm Kit for Workspace Cribbage Stacking Chair	37.296	2	0.3	-1.0656
9522	CA-2011-169446	12/19/2013	12/25/2013	Standard Class	SG-20605	Speros Goranitis	Consumer	United States	Chicago	Illinois	60623	Central	TEC-PH-10002817	Technology	Phones	RCA ViSYS 25425RE1 Corded phone	323.976	3	0.2	36.4473
8553	CA-2011-140473	5/30/2013	6/3/2013	Standard Class	MC-17425	Mark Cousins	Corporate	United States	Chicago	Illinois	60623	Central	TEC-CO-10004202	Technology	Copiers	Brother DCP1000 Digital 3 in 1 Multifunction Machine	719.976	3	0.2	134.9955
242	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	FUR-TA-10002607	Furniture	Tables	KI Conference Tables	177.225	5	0.5	-120.513
2967	CA-2011-162866	12/27/2013	12/31/2013	Standard Class	Co-12640	Corey-Lock	Consumer	United States	Skokie	Illinois	60076	Central	FUR-FU-10001473	Furniture	Furnishings	DAX Wood Document Frame	32.952	6	0.6	-19.7712
4713	CA-2011-108273	12/16/2013	12/21/2013	Standard Class	EJ-13720	Ed Jacobs	Consumer	United States	Huntsville	Texas	77340	Central	OFF-PA-10000029	Office Supplies	Paper	Xerox 224	36.288	7	0.2	12.7008
5102	CA-2011-158442	3/17/2013	3/17/2013	Same Day	AZ-10750	Annie Zypern	Consumer	United States	Dallas	Texas	75217	Central	OFF-PA-10002195	Office Supplies	Paper	Xerox 1966	5.184	1	0.2	1.8792
6108	CA-2011-120852	12/20/2013	12/25/2013	Standard Class	WB-21850	William Brown	Consumer	United States	Grand Prairie	Texas	75051	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	65.44	5	0.2	-8.18
1396	US-2014-117247	10/9/2016	10/14/2016	Standard Class	CK-12760	Cyma Kinney	Corporate	United States	Aurora	Illinois	60505	Central	FUR-TA-10001676	Furniture	Tables	Hon 61000 Series Interactive Training Tables	66.645	3	0.5	-42.6528
4697	US-2012-138121	12/17/2014	12/17/2014	Same Day	JL-15835	John Lee	Consumer	United States	Detroit	Michigan	48205	Central	FUR-CH-10004875	Furniture	Chairs	Harbour Creations 67200 Series Stacking Chairs	142.36	2	0	38.4372
5382	CA-2013-149195	9/6/2015	9/8/2015	Second Class	DM-13525	Don Miller	Corporate	United States	Houston	Texas	77070	Central	OFF-PA-10001870	Office Supplies	Paper	Xerox 202	25.92	5	0.2	9.072
8659	CA-2013-168361	6/22/2015	6/26/2015	Standard Class	KB-16600	Ken Brennan	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10003727	Office Supplies	Binders	Avery Durable Slant Ring Binders With Label Holder	0.836	1	0.8	-1.3376
1666	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	OFF-FA-10002676	Office Supplies	Fasteners	Colored Push Pins	4.344	3	0.2	0.8688
6411	CA-2014-161774	5/14/2016	5/15/2016	First Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10004071	Technology	Phones	PayAnywhere Card Reader	7.992	1	0.2	0.6993
980	CA-2012-157035	12/9/2014	12/12/2014	First Class	KB-16600	Ken Brennan	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10004156	Office Supplies	Paper	Xerox 188	34.02	3	0	16.6698
3367	CA-2011-165379	7/9/2013	7/15/2013	Standard Class	BM-11650	Brian Moss	Corporate	United States	Dallas	Texas	75217	Central	OFF-PA-10003072	Office Supplies	Paper	Eureka Recycled Copy Paper 8 1/2" x 11", Ream	10.368	2	0.2	3.6288
4265	US-2013-131611	11/6/2015	11/10/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Houston	Texas	77036	Central	FUR-TA-10002774	Furniture	Tables	Laminate Occasional Tables	863.128	8	0.3	-160.2952
9523	CA-2011-169446	12/19/2013	12/25/2013	Standard Class	SG-20605	Speros Goranitis	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10000295	Office Supplies	Paper	Xerox 229	15.552	3	0.2	5.4432
741	CA-2011-112326	1/4/2013	1/8/2013	Standard Class	PO-19195	Phillina Ober	Home Office	United States	Naperville	Illinois	60540	Central	OFF-ST-10002743	Office Supplies	Storage	SAFCO Boltless Steel Shelving	272.736	3	0.2	-64.7748
3253	CA-2014-110373	10/27/2016	10/30/2016	Second Class	MA-17560	Matt Abelman	Home Office	United States	Chicago	Illinois	60610	Central	OFF-AR-10003045	Office Supplies	Art	Prang Colored Pencils	7.056	3	0.2	2.205
1809	CA-2013-164938	2/11/2015	2/13/2015	First Class	PB-19210	Phillip Breyer	Corporate	United States	Tulsa	Oklahoma	74133	Central	TEC-PH-10004897	Technology	Phones	Mediabridge Sport Armband iPhone 5s	69.93	7	0	0.6993
5699	CA-2013-143441	11/6/2015	11/6/2015	Same Day	EB-14170	Evan Bailliet	Consumer	United States	Laredo	Texas	78041	Central	OFF-LA-10002312	Office Supplies	Labels	Avery 490	11.84	1	0.2	4.44
9006	CA-2014-107825	11/18/2016	11/18/2016	Same Day	NB-18655	Nona Balk	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-ST-10001321	Office Supplies	Storage	Decoflex Hanging Personal Folder File, Blue	92.52	6	0	24.9804
8314	CA-2011-161508	7/12/2013	7/16/2013	Standard Class	PV-18985	Paul Van Hugh	Home Office	United States	League City	Texas	77573	Central	FUR-CH-10002126	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs	512.358	3	0.3	-14.6388
5374	CA-2012-118738	10/24/2014	10/30/2014	Standard Class	AG-10495	Andrew Gjertsen	Corporate	United States	Houston	Texas	77041	Central	FUR-TA-10002607	Furniture	Tables	KI Conference Tables	347.361	7	0.3	-69.4722
6915	CA-2011-142510	12/22/2013	12/29/2013	Standard Class	NP-18700	Nora Preis	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10000585	Office Supplies	Storage	Economy Rollaway Files	132.16	1	0.2	9.912
6472	CA-2012-108532	8/29/2014	9/2/2014	Standard Class	CC-12100	Chad Cunningham	Home Office	United States	Detroit	Michigan	48234	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	114.52	7	0	11.452
1858	US-2014-158218	5/12/2016	5/15/2016	Second Class	AC-10420	Alyssa Crouse	Corporate	United States	Houston	Texas	77041	Central	OFF-BI-10002133	Office Supplies	Binders	Wilson Jones Elliptical Ring 3 1/2" Capacity Binders, 800 sheets	34.24	4	0.8	-53.072
6249	CA-2014-121580	5/29/2016	6/4/2016	Standard Class	ML-17410	Maris LaWare	Consumer	United States	Columbus	Indiana	47201	Central	FUR-FU-10003981	Furniture	Furnishings	Eldon Wave Desk Accessories	6.24	3	0	2.6208
3325	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10001359	Office Supplies	Binders	GBC DocuBind TL300 Electric Binding System	896.99	5	0.8	-1480.0335
746	US-2013-146710	8/28/2015	9/2/2015	Standard Class	SS-20875	Sung Shariari	Consumer	United States	Dallas	Texas	75220	Central	OFF-SU-10004261	Office Supplies	Supplies	Fiskars 8" Scissors, 2/Pack	55.168	4	0.2	6.2064
4269	US-2013-131611	11/6/2015	11/10/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Houston	Texas	77036	Central	TEC-AC-10004001	Technology	Accessories	Logitech Wireless Headset H600 Over-The-Head Design	171.96	5	0.2	45.1395
5351	US-2014-103814	12/9/2016	12/16/2016	Standard Class	LH-16900	Lena Hernandez	Consumer	United States	Park Ridge	Illinois	60068	Central	OFF-PA-10001019	Office Supplies	Paper	Xerox 1884	143.856	9	0.2	48.5514
5173	CA-2013-122903	5/28/2015	5/30/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Detroit	Michigan	48205	Central	OFF-PA-10000994	Office Supplies	Paper	Xerox 1915	314.55	3	0	150.984
2909	CA-2014-121615	11/3/2016	11/9/2016	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Eagan	Minnesota	55122	Central	OFF-LA-10001771	Office Supplies	Labels	Avery 513	14.94	3	0	6.8724
7790	US-2013-117037	5/18/2015	5/21/2015	First Class	LW-17215	Luke Weiss	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10000791	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4 x 5 Forms per Page, 200 Sets per Book	30.528	8	0.2	9.54
3155	CA-2014-150497	7/20/2016	7/24/2016	Standard Class	SM-20950	Suzanne McNair	Corporate	United States	Maple Grove	Minnesota	55369	Central	OFF-BI-10004600	Office Supplies	Binders	Ibico Ibimaster 300 Manual Binding System	735.98	2	0	331.191
4511	CA-2013-119935	11/11/2015	11/15/2015	Standard Class	KM-16225	Kalyca Meade	Corporate	United States	Springfield	Missouri	65807	Central	FUR-FU-10001085	Furniture	Furnishings	3M Polarizing Light Filter Sleeves	37.3	2	0	17.158
8534	CA-2013-156748	12/1/2015	12/7/2015	Standard Class	BS-11755	Bruce Stewart	Consumer	United States	Detroit	Michigan	48227	Central	FUR-CH-10000513	Furniture	Chairs	High-Back Leather Manager's Chair	389.97	3	0	35.0973
7833	CA-2013-112382	5/10/2015	5/14/2015	Standard Class	MB-18085	Mick Brown	Consumer	United States	Houston	Texas	77036	Central	TEC-PH-10001552	Technology	Phones	I Need's 3d Hello Kitty Hybrid Silicone Case Cover for HTC One X 4g with 3d Hello Kitty Stylus Pen Green/pink	19.136	2	0.2	1.9136
9302	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	TEC-PH-10001870	Technology	Phones	Lunatik TT5L-002 Taktik Strike Impact Protection System for iPhone 5	97.968	2	0.2	6.123
901	CA-2014-150959	11/11/2016	11/13/2016	First Class	TD-20995	Tamara Dahlen	Consumer	United States	Garland	Texas	75043	Central	OFF-LA-10001045	Office Supplies	Labels	Permanent Self-Adhesive File Folder Labels for Typewriters by Universal	10.44	5	0.2	3.393
263	US-2011-106992	9/19/2013	9/21/2013	Second Class	SB-20290	Sean Braxton	Corporate	United States	Houston	Texas	77036	Central	TEC-MA-10000822	Technology	Machines	Lexmark MX611dhe Monochrome Laser Printer	3059.982	3	0.4	-509.997
4833	CA-2011-120278	11/7/2013	11/12/2013	Standard Class	MS-17365	Maribeth Schnelling	Consumer	United States	Wausau	Wisconsin	54401	Central	OFF-ST-10002214	Office Supplies	Storage	X-Rack File for Hanging Folders	22.58	2	0	5.8708
4437	CA-2013-163398	5/4/2015	5/9/2015	Standard Class	CB-12415	Christy Brittain	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AR-10003217	Office Supplies	Art	Newell 316	27.384	7	0.2	2.7384
5977	CA-2014-102155	7/13/2016	7/17/2016	Standard Class	RR-19525	Rick Reed	Corporate	United States	Overland Park	Kansas	66212	Central	OFF-PA-10003673	Office Supplies	Paper	Strathmore Photo Mount Cards	13.56	2	0	6.2376
1418	CA-2012-126697	9/21/2014	9/24/2014	First Class	SV-20815	Stuart Van	Corporate	United States	Houston	Texas	77041	Central	TEC-AC-10004353	Technology	Accessories	Hypercom P1300 Pinpad	151.2	3	0.2	32.13
2175	CA-2012-132507	7/30/2014	8/3/2014	Second Class	CC-12610	Corey Catlett	Corporate	United States	Houston	Texas	77041	Central	OFF-ST-10000943	Office Supplies	Storage	Eldon ProFile File 'N Store Portable File Tub Letter/Legal Size Black	61.792	4	0.2	6.1792
2783	CA-2013-139878	11/12/2015	11/17/2015	Standard Class	LD-17005	Lisa DeCherney	Consumer	United States	Detroit	Michigan	48234	Central	TEC-PH-10001336	Technology	Phones	Digium D40 VoIP phone	257.98	2	0	74.8142
168	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	FUR-CH-10004287	Furniture	Chairs	SAFCO Arco Folding Chair	1740.06	9	0.3	-24.858
3328	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10003724	Office Supplies	Paper	Wirebound Message Book, 4 per Page	21.72	5	0.2	7.8735
3489	CA-2012-157322	7/2/2014	7/6/2014	Standard Class	RH-19600	Rob Haberlin	Consumer	United States	Carol Stream	Illinois	60188	Central	FUR-CH-10004086	Furniture	Chairs	Hon 4070 Series Pagoda Armless Upholstered Stacking Chairs	408.422	2	0.3	-5.8346
5510	US-2014-152569	5/15/2016	5/20/2016	Standard Class	JD-16015	Joy Daniels	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10001736	Office Supplies	Paper	Xerox 1880	56.704	2	0.2	19.1376
4503	CA-2011-116757	6/30/2013	7/4/2013	Standard Class	MS-17980	Michael Stewart	Corporate	United States	Houston	Texas	77095	Central	OFF-FA-10002815	Office Supplies	Fasteners	Staples	21.312	6	0.2	7.1928
740	CA-2011-112326	1/4/2013	1/8/2013	Standard Class	PO-19195	Phillina Ober	Home Office	United States	Naperville	Illinois	60540	Central	OFF-LA-10003223	Office Supplies	Labels	Avery 508	11.784	3	0.2	4.2717
5446	CA-2013-128307	7/26/2015	7/30/2015	Standard Class	BE-11335	Bill Eplett	Home Office	United States	Houston	Texas	77041	Central	OFF-EN-10003040	Office Supplies	Envelopes	Quality Park Security Envelopes	20.936	1	0.2	7.0659
3365	CA-2013-130050	7/17/2015	7/19/2015	Second Class	MC-17425	Mark Cousins	Corporate	United States	Houston	Texas	77036	Central	FUR-FU-10001940	Furniture	Furnishings	Staple-based wall hangings	9.552	3	0.6	-3.8208
3972	CA-2012-132374	2/22/2014	2/24/2014	Second Class	PS-19045	Penelope Sewall	Home Office	United States	Sterling Heights	Michigan	48310	Central	OFF-AR-10001615	Office Supplies	Art	Newell 34	79.36	4	0	20.6336
1801	CA-2013-121034	8/9/2015	8/11/2015	Second Class	JF-15565	Jill Fjeld	Consumer	United States	Dallas	Texas	75081	Central	OFF-PA-10001994	Office Supplies	Paper	Ink Jet Note and Greeting Cards, 8-1/2" x 5-1/2" Card Size	53.952	3	0.2	17.5344
5725	CA-2011-103191	9/22/2013	9/27/2013	Standard Class	VG-21805	Vivek Grady	Corporate	United States	Chicago	Illinois	60653	Central	OFF-ST-10002574	Office Supplies	Storage	SAFCO Commercial Wire Shelving, Black	331.536	3	0.2	-82.884
5364	CA-2013-122014	12/30/2015	1/3/2016	Standard Class	CD-11920	Carlos Daly	Consumer	United States	Wichita	Kansas	67212	Central	OFF-AP-10001293	Office Supplies	Appliances	Belkin 8 Outlet Surge Protector	81.96	2	0	22.9488
1792	CA-2011-120474	12/1/2013	12/3/2013	First Class	RP-19390	Resi Pölking	Consumer	United States	Madison	Wisconsin	53711	Central	FUR-CH-10001854	Furniture	Chairs	Office Star - Professional Matrix Back Chair with 2-to-1 Synchro Tilt and Mesh Fabric Seat	2807.84	8	0	673.8816
5553	US-2011-159618	11/12/2013	11/16/2013	Standard Class	DB-12970	Darren Budd	Corporate	United States	Houston	Texas	77036	Central	TEC-AC-10003832	Technology	Accessories	Imation 16GB Mini TravelDrive USB 2.0 Flash Drive	79.512	3	0.2	20.8719
1773	CA-2013-129686	11/28/2015	11/30/2015	Second Class	GG-14650	Greg Guthrie	Corporate	United States	Chicago	Illinois	60623	Central	TEC-AC-10001266	Technology	Accessories	Memorex Micro Travel Drive 8 GB	62.4	6	0.2	19.5
9904	CA-2011-122609	11/12/2013	11/18/2013	Standard Class	DP-13000	Darren Powers	Consumer	United States	Carrollton	Texas	75007	Central	FUR-FU-10004587	Furniture	Furnishings	GE General Use Halogen Bulbs, 100 Watts, 1 Bulb per Pack	25.128	3	0.6	-6.9102
829	CA-2014-126956	8/21/2016	8/28/2016	Standard Class	GT-14710	Greg Tran	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-EN-10004459	Office Supplies	Envelopes	Security-Tint Envelopes	15.28	2	0	7.4872
5056	CA-2012-141243	1/3/2014	1/8/2014	Second Class	AH-10465	Amy Hunt	Consumer	United States	Dallas	Texas	75217	Central	FUR-BO-10003272	Furniture	Bookcases	O'Sullivan Living Dimensions 5-Shelf Bookcases	1352.3976	9	0.32	-437.5404
6878	US-2012-123918	10/15/2014	10/15/2014	Same Day	CG-12520	Claire Gute	Consumer	United States	Dallas	Texas	75217	Central	FUR-FU-10004952	Furniture	Furnishings	C-Line Cubicle Keepers Polyproplyene Holder w/Velcro Back, 8-1/2x11, 25/Bx	131.376	6	0.6	-95.2476
9366	US-2011-166828	8/22/2013	8/25/2013	First Class	JF-15415	Jennifer Ferguson	Consumer	United States	Saint Charles	Missouri	63301	Central	OFF-PA-10001846	Office Supplies	Paper	Xerox 1899	11.56	2	0	5.6644
6137	CA-2012-105613	10/18/2014	10/22/2014	Standard Class	KN-16705	Kristina Nunn	Home Office	United States	Mcallen	Texas	78501	Central	OFF-AP-10000026	Office Supplies	Appliances	Tripp Lite Isotel 6 Outlet Surge Protector with Fax/Modem Protection	73.164	6	0.8	-186.5682
22	CA-2013-137330	12/10/2015	12/14/2015	Standard Class	KB-16585	Ken Black	Corporate	United States	Fremont	Nebraska	68025	Central	OFF-AR-10000246	Office Supplies	Art	Newell 318	19.46	7	0	5.0596
8676	CA-2014-163265	2/17/2016	2/22/2016	Standard Class	JS-16030	Joy Smith	Consumer	United States	Decatur	Illinois	62521	Central	OFF-AR-10004078	Office Supplies	Art	Newell 312	28.032	6	0.2	3.504
7356	CA-2012-139780	12/31/2014	1/2/2015	Second Class	AH-10690	Anna Häberlin	Corporate	United States	Detroit	Michigan	48205	Central	OFF-BI-10004139	Office Supplies	Binders	Fellowes Presentation Covers for Comb Binding Machines	116.4	8	0	52.38
7451	CA-2014-105669	9/17/2016	9/22/2016	Second Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Houston	Texas	77036	Central	FUR-CH-10003774	Furniture	Chairs	Global Wood Trimmed Manager's Task Chair, Khaki	318.43	5	0.3	-77.333
1750	US-2011-157406	4/25/2013	4/29/2013	Standard Class	DA-13450	Dianna Arnett	Home Office	United States	Houston	Texas	77095	Central	OFF-AR-10002221	Office Supplies	Art	12 Colored Short Pencils	6.24	3	0.2	0.546
910	CA-2014-137596	9/2/2016	9/7/2016	Standard Class	BE-11335	Bill Eplett	Home Office	United States	Jackson	Michigan	49201	Central	TEC-PH-10001494	Technology	Phones	Polycom CX600 IP Phone VoIP phone	1199.8	4	0	323.946
2319	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	TEC-AC-10003095	Technology	Accessories	Logitech G35 7.1-Channel Surround Sound Headset	389.97	3	0	132.5898
3330	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	TEC-PH-10003505	Technology	Phones	Geemarc AmpliPOWER60	148.48	2	0.2	16.704
2344	US-2011-155894	7/26/2013	7/30/2013	Second Class	CL-11890	Carl Ludwig	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10004804	Office Supplies	Storage	Belkin 19" Vented Equipment Shelf, Black	123.552	3	0.2	-29.3436
6448	US-2014-119816	3/4/2016	3/6/2016	Second Class	TT-21460	Tonja Turnell	Home Office	United States	Houston	Texas	77095	Central	OFF-LA-10002381	Office Supplies	Labels	Avery 497	2.464	1	0.2	0.8624
3523	CA-2013-114482	11/22/2015	11/26/2015	Second Class	DM-13345	Denise Monton	Corporate	United States	Des Moines	Iowa	50315	Central	TEC-PH-10001580	Technology	Phones	Logitech Mobile Speakerphone P710e - speaker phone	404.94	3	0	109.3338
4958	CA-2012-127607	3/20/2014	3/26/2014	Standard Class	JK-15730	Joe Kamberova	Consumer	United States	Carrollton	Texas	75007	Central	OFF-BI-10001308	Office Supplies	Binders	GBC Standard Plastic Binding Systems' Combs	2.512	2	0.8	-4.396
4918	CA-2014-163125	10/9/2016	10/11/2016	Second Class	MB-17305	Maria Bertelson	Consumer	United States	League City	Texas	77573	Central	FUR-CH-10001802	Furniture	Chairs	Hon Every-Day Chair Series Swivel Task Chairs	254.058	3	0.3	-32.6646
3440	CA-2014-152583	10/30/2016	10/30/2016	Same Day	RA-19945	Ryan Akin	Consumer	United States	Dallas	Texas	75217	Central	OFF-ST-10002214	Office Supplies	Storage	X-Rack File for Hanging Folders	54.192	6	0.2	4.0644
9507	CA-2011-149104	4/5/2013	4/7/2013	Second Class	RD-19900	Ruben Dartt	Consumer	United States	Dearborn Heights	Michigan	48127	Central	OFF-AR-10002952	Office Supplies	Art	Stanley Contemporary Battery Pencil Sharpeners	26.7	2	0	7.476
727	CA-2014-144113	9/16/2016	9/20/2016	Standard Class	JF-15355	Jay Fein	Consumer	United States	Austin	Texas	78745	Central	TEC-PH-10002170	Technology	Phones	ClearSounds CSC500 Amplified Spirit Phone Corded phone	55.992	1	0.2	5.5992
2924	CA-2011-156993	6/28/2013	7/4/2013	Standard Class	RW-19630	Rob Williams	Corporate	United States	Detroit	Michigan	48234	Central	OFF-FA-10003495	Office Supplies	Fasteners	Staples	6.08	1	0	3.04
3522	CA-2013-114482	11/22/2015	11/26/2015	Second Class	DM-13345	Denise Monton	Corporate	United States	Des Moines	Iowa	50315	Central	OFF-PA-10003845	Office Supplies	Paper	Xerox 1987	40.46	7	0	19.8254
4671	US-2014-133200	5/6/2016	5/11/2016	Standard Class	DB-13555	Dorothy Badders	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-ST-10001932	Office Supplies	Storage	Fellowes Staxonsteel Drawer Files	772.68	5	0.2	-57.951
9420	CA-2014-152926	10/2/2016	10/4/2016	Second Class	SC-20695	Steve Chapman	Corporate	United States	Houston	Texas	77041	Central	OFF-AP-10004708	Office Supplies	Appliances	Fellowes Superior 10 Outlet Split Surge Protector	15.224	2	0.8	-38.8212
2415	CA-2013-156300	12/30/2015	1/3/2016	Standard Class	TB-21595	Troy Blackwell	Consumer	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10001714	Furniture	Chairs	Global Leather & Oak Executive Chair, Burgundy	754.45	5	0	60.356
113	CA-2013-128867	11/4/2015	11/11/2015	Standard Class	CL-12565	Clay Ludtke	Consumer	United States	Urbandale	Iowa	50322	Central	OFF-BI-10003981	Office Supplies	Binders	Avery Durable Plastic 1" Binders	27.24	6	0	13.3476
2688	US-2013-128195	8/5/2015	8/6/2015	First Class	RA-19285	Ralph Arnett	Consumer	United States	Peoria	Illinois	61604	Central	OFF-BI-10002003	Office Supplies	Binders	Ibico Presentation Index for Binding Systems	3.98	5	0.8	-6.567
8875	CA-2014-142489	11/14/2016	11/16/2016	Second Class	TC-21295	Toby Carlisle	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10003684	Office Supplies	Binders	Wilson Jones Legal Size Ring Binders	21.99	5	0.8	-32.985
8463	CA-2012-169537	9/3/2014	9/7/2014	Second Class	JH-15820	John Huston	Consumer	United States	Holland	Michigan	49423	Central	OFF-LA-10001982	Office Supplies	Labels	Smead Alpha-Z Color-Coded Name Labels First Letter Starter Set	7.5	2	0	3.6
5155	US-2012-124219	8/7/2014	8/8/2014	First Class	KW-16570	Kelly Williams	Consumer	United States	Kirkwood	Missouri	63122	Central	OFF-BI-10002215	Office Supplies	Binders	Wilson Jones Hanging View Binder, White, 1"	28.4	4	0	13.064
1795	CA-2013-140774	9/6/2015	9/11/2015	Standard Class	BE-11455	Brad Eason	Home Office	United States	Olathe	Kansas	66062	Central	OFF-AR-10004022	Office Supplies	Art	Panasonic KP-380BK Classic Electric Pencil Sharpener	107.94	3	0	26.985
3380	CA-2014-142867	3/17/2016	3/21/2016	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Houston	Texas	77095	Central	OFF-PA-10004610	Office Supplies	Paper	Xerox 1900	10.272	3	0.2	3.21
46	CA-2013-118255	3/12/2015	3/14/2015	First Class	ON-18715	Odella Nelson	Corporate	United States	Eagan	Minnesota	55122	Central	OFF-BI-10003291	Office Supplies	Binders	Wilson Jones Leather-Like Binders with DublLock Round Rings	17.46	2	0	8.2062
9775	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	OFF-BI-10004995	Office Supplies	Binders	GBC DocuBind P400 Electric Binding System	2177.584	8	0.8	-3701.8928
6496	CA-2014-111262	10/28/2016	11/1/2016	Second Class	KH-16510	Keith Herrera	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10001937	Office Supplies	Paper	Xerox 21	15.552	3	0.2	5.4432
2056	CA-2014-120376	12/22/2016	12/25/2016	First Class	TP-21130	Theone Pippenger	Consumer	United States	Detroit	Michigan	48227	Central	TEC-AC-10001114	Technology	Accessories	Microsoft Wireless Mobile Mouse 4000	199.95	5	0	63.984
7189	CA-2014-133102	8/17/2016	8/24/2016	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77095	Central	OFF-AP-10001563	Office Supplies	Appliances	Belkin Premiere Surge Master II 8-outlet surge protector	38.864	4	0.8	-99.1032
4363	CA-2014-111332	5/20/2016	5/22/2016	Second Class	NC-18340	Nat Carroll	Consumer	United States	Fargo	North Dakota	58103	Central	OFF-AR-10001953	Office Supplies	Art	Boston 1645 Deluxe Heavier-Duty Electric Pencil Sharpener	131.94	3	0	35.6238
3997	CA-2012-105627	3/8/2014	3/12/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Kenosha	Wisconsin	53142	Central	TEC-PH-10003012	Technology	Phones	Nortel Meridian M3904 Professional Digital phone	769.95	5	0	223.2855
8285	CA-2012-154284	12/21/2014	12/26/2014	Second Class	SZ-20035	Sam Zeldin	Home Office	United States	Saint Charles	Illinois	60174	Central	TEC-AC-10003198	Technology	Accessories	Enermax Acrylux Wireless Keyboard	637.44	8	0.2	135.456
6260	CA-2012-150441	8/13/2014	8/17/2014	Second Class	RA-19285	Ralph Arnett	Consumer	United States	Richmond	Indiana	47374	Central	OFF-BI-10003529	Office Supplies	Binders	Avery Round Ring Poly Binders	11.36	4	0	5.5664
9445	CA-2012-104052	3/1/2014	3/2/2014	First Class	TP-21565	Tracy Poddar	Corporate	United States	Coppell	Texas	75019	Central	TEC-PH-10003215	Technology	Phones	Jackery Bar Premium Fast-charging Portable Charger	95.84	4	0.2	34.742
9106	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	OFF-ST-10000129	Office Supplies	Storage	Fellowes Recycled Storage Drawers	177.648	2	0.2	-28.8678
243	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10002505	Furniture	Furnishings	Eldon 100 Class Desk Accessories	4.044	3	0.6	-2.8308
8454	CA-2013-125087	4/19/2015	4/24/2015	Standard Class	TH-21115	Thea Hudgings	Corporate	United States	Houston	Texas	77070	Central	OFF-ST-10001780	Office Supplies	Storage	Tennsco 16-Compartment Lockers with Coat Rack	1554.936	3	0.2	77.7468
4656	CA-2011-160738	5/5/2013	5/10/2013	Standard Class	KH-16330	Katharine Harms	Corporate	United States	Freeport	Illinois	61032	Central	OFF-ST-10003442	Office Supplies	Storage	Eldon Portable Mobile Manager	45.248	2	0.2	3.9592
7548	CA-2011-103492	10/10/2013	10/15/2013	Standard Class	CM-12715	Craig Molinari	Corporate	United States	Huntsville	Texas	77340	Central	OFF-BI-10004817	Office Supplies	Binders	GBC Personal VeloBind Strips	11.98	5	0.8	-19.168
2908	CA-2014-121615	11/3/2016	11/9/2016	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Eagan	Minnesota	55122	Central	OFF-ST-10001325	Office Supplies	Storage	Sterilite Officeware Hinged File Box	52.4	5	0	14.148
8250	CA-2012-140221	3/5/2014	3/9/2014	Second Class	MS-17365	Maribeth Schnelling	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10002854	Office Supplies	Binders	Performers Binder/Pad Holder, Black	11.212	2	0.8	-16.818
743	US-2013-146710	8/28/2015	9/2/2015	Standard Class	SS-20875	Sung Shariari	Consumer	United States	Dallas	Texas	75220	Central	OFF-SU-10004498	Office Supplies	Supplies	Martin-Yale Premier Letter Opener	51.52	5	0.2	-10.948
8997	US-2014-116491	11/11/2016	11/13/2016	First Class	PG-18820	Patrick Gardner	Consumer	United States	Dallas	Texas	75081	Central	TEC-PH-10004531	Technology	Phones	OtterBox Commuter Series Case - iPhone 5 & 5s	35.184	2	0.2	12.3144
2515	CA-2013-124506	11/12/2015	11/18/2015	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Chicago	Illinois	60623	Central	FUR-CH-10004540	Furniture	Chairs	Global Chrome Stack Chair	47.992	2	0.3	-2.0568
6420	CA-2013-140130	11/1/2015	11/6/2015	Standard Class	HW-14935	Helen Wasserman	Corporate	United States	Tulsa	Oklahoma	74133	Central	FUR-CH-10002084	Furniture	Chairs	Hon Mobius Operator's Chair	368.97	3	0	81.1734
3112	CA-2013-121671	7/18/2015	7/23/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Springfield	Missouri	65807	Central	OFF-ST-10000078	Office Supplies	Storage	Tennsco 6- and 18-Compartment Lockers	265.17	1	0	47.7306
1009	US-2014-106705	12/26/2016	1/1/2017	Standard Class	PO-18850	Patrick O'Brill	Consumer	United States	Burlington	Iowa	52601	Central	OFF-PA-10001509	Office Supplies	Paper	Recycled Desk Saver Line "While You Were Out" Book, 5 1/2" X 4"	44.75	5	0	20.585
8270	CA-2014-121790	1/31/2016	2/7/2016	Standard Class	LP-17095	Liz Preis	Consumer	United States	Aurora	Illinois	60505	Central	TEC-PH-10002584	Technology	Phones	Samsung Galaxy S4	2003.168	4	0.2	250.396
776	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	FUR-FU-10002597	Furniture	Furnishings	C-Line Magnetic Cubicle Keepers, Clear Polypropylene	34.58	7	0	14.5236
7259	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-AR-10000940	Office Supplies	Art	Newell 343	14.7	5	0	3.969
9948	CA-2014-121559	6/1/2016	6/3/2016	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Indianapolis	Indiana	46203	Central	FUR-CH-10003746	Furniture	Chairs	Hon 4070 Series Pagoda Round Back Stacking Chairs	1925.88	6	0	539.2464
5830	CA-2013-122063	12/4/2015	12/8/2015	Standard Class	MM-17920	Michael Moore	Consumer	United States	Richmond	Indiana	47374	Central	FUR-TA-10004575	Furniture	Tables	Hon 5100 Series Wood Tables	581.96	2	0	104.7528
8533	CA-2013-156748	12/1/2015	12/7/2015	Standard Class	BS-11755	Bruce Stewart	Consumer	United States	Detroit	Michigan	48227	Central	OFF-ST-10001370	Office Supplies	Storage	Sensible Storage WireTech Storage Systems	496.86	7	0	24.843
1273	US-2013-103646	4/22/2015	4/27/2015	Standard Class	SP-20545	Sibella Parks	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10002854	Office Supplies	Binders	Performers Binder/Pad Holder, Black	44.848	8	0.8	-67.272
9725	CA-2012-117898	12/5/2014	12/11/2014	Standard Class	TB-21250	Tim Brockman	Consumer	United States	Bloomington	Illinois	61701	Central	OFF-EN-10004459	Office Supplies	Envelopes	Security-Tint Envelopes	12.224	2	0.2	4.4312
1349	CA-2011-118339	3/17/2013	3/24/2013	Standard Class	BN-11515	Bradley Nguyen	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-BI-10001758	Office Supplies	Binders	Wilson Jones 14 Line Acrylic Coated Pressboard Data Binders	53.4	10	0	25.098
6715	CA-2014-107629	12/14/2016	12/14/2016	Same Day	DB-13060	Dave Brooks	Consumer	United States	Skokie	Illinois	60076	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	39.264	3	0.2	-4.908
7948	CA-2011-131009	3/1/2013	3/5/2013	Standard Class	SC-20380	Shahid Collister	Consumer	United States	El Paso	Texas	79907	Central	OFF-FA-10004395	Office Supplies	Fasteners	Plymouth Boxed Rubber Bands by Plymouth	18.84	5	0.2	-3.5325
3137	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	TEC-PH-10004908	Technology	Phones	Panasonic KX TS3282W Corded phone	67.992	1	0.2	8.499
2690	CA-2011-123064	6/30/2013	7/2/2013	First Class	RA-19915	Russell Applegate	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AR-10004582	Office Supplies	Art	BIC Brite Liner Grip Highlighters	5.248	4	0.2	1.64
2188	CA-2014-143063	8/10/2016	8/15/2016	Standard Class	IL-15100	Ivan Liston	Consumer	United States	Columbus	Indiana	47201	Central	OFF-EN-10003134	Office Supplies	Envelopes	Staple envelope	70.08	6	0	35.04
4189	CA-2014-112536	5/18/2016	5/23/2016	Standard Class	SG-20890	Susan Gilcrest	Corporate	United States	Mcallen	Texas	78501	Central	OFF-ST-10004835	Office Supplies	Storage	Plastic Stacking Crates & Casters	8.928	2	0.2	0.6696
3212	US-2014-108245	9/22/2016	9/27/2016	Standard Class	SH-19975	Sally Hughsby	Corporate	United States	Pearland	Texas	77581	Central	OFF-BI-10000773	Office Supplies	Binders	Insertable Tab Post Binder Dividers	11.228	7	0.8	-18.5262
2586	CA-2012-121041	11/3/2014	11/10/2014	Standard Class	CS-12250	Chris Selesnick	Corporate	United States	Haltom City	Texas	76117	Central	OFF-EN-10001137	Office Supplies	Envelopes	#10 Gummed Flap White Envelopes, 100/Box	6.608	2	0.2	2.1476
5420	CA-2012-110877	10/23/2014	10/26/2014	First Class	JE-15715	Joe Elijah	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10002103	Technology	Phones	Jabra SPEAK 410	150.384	2	0.2	15.0384
4190	CA-2013-157714	9/27/2015	10/2/2015	Second Class	CS-12175	Charles Sheldon	Corporate	United States	Iowa City	Iowa	52240	Central	OFF-PA-10004022	Office Supplies	Paper	Hammermill Color Copier Paper (28Lb. and 96 Bright)	9.99	1	0	4.4955
7852	CA-2011-169649	12/9/2013	12/15/2013	Standard Class	TS-21205	Thomas Seio	Corporate	United States	Chicago	Illinois	60653	Central	OFF-PA-10000143	Office Supplies	Paper	Astroparche Fine Business Paper	8.448	2	0.2	2.9568
9633	CA-2014-154809	2/14/2016	2/18/2016	Standard Class	MH-17455	Mark Hamilton	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-AP-10004785	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Medium Room	90.64	8	0	38.9752
3096	CA-2012-114468	8/23/2014	8/23/2014	Same Day	TD-20995	Tamara Dahlen	Consumer	United States	Bolingbrook	Illinois	60440	Central	OFF-FA-10003021	Office Supplies	Fasteners	Staples	12.032	8	0.2	2.256
1599	CA-2014-158876	11/19/2016	11/21/2016	Second Class	AB-10150	Aimee Bixby	Consumer	United States	Carrollton	Texas	75007	Central	OFF-SU-10001165	Office Supplies	Supplies	Acme Elite Stainless Steel Scissors	6.672	1	0.2	0.5004
7448	CA-2014-127474	2/4/2016	2/8/2016	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10000418	Office Supplies	Paper	Xerox 189	419.4	5	0.2	146.79
6678	CA-2012-109337	11/21/2014	11/23/2014	Second Class	DL-13330	Denise Leinenbach	Consumer	United States	Lawrence	Indiana	46226	Central	TEC-AC-10000990	Technology	Accessories	Imation Bio 2GB USB Flash Drive Imation Corp	393.54	3	0	165.2868
1147	CA-2012-112452	4/4/2014	4/4/2014	Same Day	NC-18340	Nat Carroll	Consumer	United States	Lansing	Michigan	48911	Central	OFF-AP-10003849	Office Supplies	Appliances	Hoover Shoulder Vac Commercial Portable Vacuum	644.076	2	0.1	107.346
6208	CA-2013-133697	10/21/2015	10/25/2015	Second Class	CM-12445	Chuck Magee	Consumer	United States	Houston	Texas	77095	Central	FUR-CH-10002372	Furniture	Chairs	Office Star - Ergonomically Designed Knee Chair	56.686	1	0.3	-14.5764
6820	CA-2014-163860	12/28/2016	1/1/2017	Standard Class	LO-17170	Lori Olson	Corporate	United States	Peoria	Illinois	61604	Central	FUR-FU-10004586	Furniture	Furnishings	G.E. Longer-Life Indoor Recessed Floodlight Bulbs	7.968	3	0.6	-2.3904
9094	US-2012-132836	6/1/2014	6/5/2014	Standard Class	AJ-10945	Ashley Jarboe	Consumer	United States	Detroit	Michigan	48227	Central	TEC-PH-10001299	Technology	Phones	Polycom CX300 Desktop Phone USB VoIP phone	299.98	2	0	83.9944
9589	CA-2014-110940	7/23/2016	7/28/2016	Standard Class	AZ-10750	Annie Zypern	Consumer	United States	Wheeling	Illinois	60090	Central	OFF-AR-10000380	Office Supplies	Art	Hunt PowerHouse Electric Pencil Sharpener, Blue	121.536	4	0.2	15.192
2036	CA-2014-162481	9/25/2016	9/29/2016	Standard Class	CT-11995	Carol Triggs	Consumer	United States	Rochester	Minnesota	55901	Central	FUR-CH-10003061	Furniture	Chairs	Global Leather Task Chair, Black	269.97	3	0	51.2943
4575	CA-2013-139395	12/13/2015	12/19/2015	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Jackson	Michigan	49201	Central	FUR-FU-10003724	Furniture	Furnishings	Westinghouse Clip-On Gooseneck Lamps	33.48	4	0	8.7048
6328	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	FUR-FU-10002918	Furniture	Furnishings	Eldon ClusterMat Chair Mat with Cordless Antistatic Protection	272.94	3	0	30.0234
1734	US-2013-131149	7/11/2015	7/15/2015	Standard Class	LH-17155	Logan Haushalter	Consumer	United States	Dallas	Texas	75081	Central	OFF-AR-10002135	Office Supplies	Art	Boston Heavy-Duty Trimline Electric Pencil Sharpeners	154.24	4	0.2	17.352
7828	CA-2014-117114	10/31/2016	11/5/2016	Standard Class	CY-12745	Craig Yedwab	Corporate	United States	Chicago	Illinois	60610	Central	OFF-EN-10001137	Office Supplies	Envelopes	#10 Gummed Flap White Envelopes, 100/Box	9.912	3	0.2	3.2214
4768	CA-2012-123155	3/9/2014	3/12/2014	First Class	NS-18640	Noel Staavos	Corporate	United States	San Antonio	Texas	78207	Central	TEC-PH-10001809	Technology	Phones	Panasonic KX T7736-B Digital phone	359.88	3	0.2	22.4925
7443	CA-2011-109932	12/9/2013	12/11/2013	First Class	VP-21760	Victoria Pisteka	Corporate	United States	Brownsville	Texas	78521	Central	OFF-PA-10001804	Office Supplies	Paper	Xerox 195	10.688	2	0.2	3.7408
3086	CA-2014-118773	2/10/2016	2/15/2016	Standard Class	TP-21415	Tom Prescott	Consumer	United States	Houston	Texas	77070	Central	TEC-AC-10002402	Technology	Accessories	Razer Kraken PRO Over Ear PC and Music Headset	127.984	2	0.2	15.998
8929	US-2012-168704	4/13/2014	4/17/2014	Standard Class	FP-14320	Frank Preis	Consumer	United States	Huntsville	Texas	77340	Central	FUR-TA-10000688	Furniture	Tables	Chromcraft Bull-Nose Wood Round Conference Table Top, Wood Base	609.98	4	0.3	-113.282
8961	CA-2014-150266	11/25/2016	11/30/2016	Standard Class	RO-19780	Rose O'Brian	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10002126	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs	853.93	5	0.3	-24.398
773	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	32.35	5	0	16.175
6333	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	FUR-FU-10002268	Furniture	Furnishings	Ultra Door Push Plate	14.73	3	0	4.8609
7661	CA-2011-105417	1/7/2013	1/12/2013	Standard Class	VS-21820	Vivek Sundaresam	Consumer	United States	Huntsville	Texas	77340	Central	FUR-FU-10004864	Furniture	Furnishings	Howard Miller 14-1/2" Diameter Chrome Round Wall Clock	76.728	3	0.6	-53.7096
9354	CA-2014-148411	9/24/2016	9/26/2016	First Class	RO-19780	Rose O'Brian	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10002109	Office Supplies	Paper	Wirebound Voice Message Log Book	11.424	3	0.2	3.7128
3145	US-2013-148110	9/6/2015	9/12/2015	Standard Class	AR-10825	Anthony Rawles	Corporate	United States	Austin	Texas	78745	Central	FUR-CH-10002647	Furniture	Chairs	Situations Contoured Folding Chairs, 4/Set	347.802	7	0.3	-24.843
3531	US-2013-152835	5/20/2015	5/24/2015	Standard Class	RP-19855	Roy Phan	Corporate	United States	Lafayette	Indiana	47905	Central	OFF-AR-10003056	Office Supplies	Art	Newell 341	21.4	5	0	6.206
6323	CA-2011-141299	6/3/2013	6/7/2013	Second Class	RB-19795	Ross Baird	Home Office	United States	Midland	Michigan	48640	Central	OFF-EN-10004459	Office Supplies	Envelopes	Security-Tint Envelopes	15.28	2	0	7.4872
3046	CA-2014-125290	11/6/2016	11/10/2016	Second Class	CC-12430	Chuck Clark	Home Office	United States	Minneapolis	Minnesota	55407	Central	OFF-AR-10001216	Office Supplies	Art	Newell 339	13.9	5	0	3.614
3551	CA-2013-152555	3/30/2015	4/3/2015	Second Class	ME-17320	Maria Etezadi	Home Office	United States	Chicago	Illinois	60653	Central	OFF-PA-10001295	Office Supplies	Paper	Computer Printout Paper with Letter-Trim Perforations	45.528	3	0.2	15.9348
9688	US-2014-130603	9/30/2016	10/6/2016	Standard Class	SC-20050	Sample Company A	Home Office	United States	Arlington	Texas	76017	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	11.646	9	0.8	-17.469
6691	US-2014-165869	7/31/2016	8/5/2016	Standard Class	LS-17200	Luke Schmidt	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-BI-10003460	Office Supplies	Binders	Acco 3-Hole Punch	17.52	4	0	8.4096
7705	CA-2013-114601	8/27/2015	9/3/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Detroit	Michigan	48234	Central	FUR-TA-10004147	Furniture	Tables	Hon 4060 Series Tables	447.84	4	0	98.5248
6797	CA-2012-168809	8/25/2014	8/25/2014	Same Day	MC-18100	Mick Crebagga	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10001473	Furniture	Furnishings	Eldon Executive Woodline II Desk Accessories, Mahogany	20.104	2	0.6	-16.5858
9844	CA-2011-163867	6/3/2013	6/6/2013	First Class	RE-19450	Richard Eichhorn	Consumer	United States	Decatur	Illinois	62521	Central	OFF-LA-10001771	Office Supplies	Labels	Avery 513	15.936	4	0.2	5.1792
4365	CA-2014-111332	5/20/2016	5/22/2016	Second Class	NC-18340	Nat Carroll	Consumer	United States	Fargo	North Dakota	58103	Central	OFF-ST-10003816	Office Supplies	Storage	Fellowes High-Stak Drawer Files	704.76	4	0	162.0948
7380	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-ST-10000419	Office Supplies	Storage	Rogers Jumbo File, Granite	40.74	3	0	0.4074
4569	CA-2012-111990	11/8/2014	11/13/2014	Standard Class	DB-13660	Duane Benoit	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10003291	Office Supplies	Binders	Wilson Jones Leather-Like Binders with DublLock Round Rings	10.476	6	0.8	-17.2854
7567	CA-2014-140802	4/21/2016	4/23/2016	First Class	KN-16390	Katherine Nockton	Corporate	United States	Houston	Texas	77070	Central	TEC-AC-10001998	Technology	Accessories	Logitech LS21 Speaker System - PC Multimedia - 2.1-CH - Wired	47.976	3	0.2	8.3958
6874	CA-2011-124394	10/17/2013	10/22/2013	Second Class	TB-21520	Tracy Blumstein	Consumer	United States	Beaumont	Texas	77705	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	10.78	5	0.8	-17.248
8379	CA-2012-162964	11/12/2014	11/18/2014	Standard Class	MF-18250	Monica Federle	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10003349	Office Supplies	Paper	Xerox 1957	15.552	3	0.2	5.6376
6864	CA-2014-138618	12/1/2016	12/8/2016	Standard Class	MY-17380	Maribeth Yedwab	Corporate	United States	San Antonio	Texas	78207	Central	OFF-PA-10000520	Office Supplies	Paper	Xerox 201	10.368	2	0.2	3.6288
3142	US-2011-122959	12/12/2013	12/12/2013	Same Day	CY-12745	Craig Yedwab	Corporate	United States	San Antonio	Texas	78207	Central	OFF-BI-10003650	Office Supplies	Binders	GBC DocuBind 300 Electric Binding Machine	210.392	2	0.8	-336.6272
437	CA-2013-147375	6/13/2015	6/15/2015	Second Class	PO-19180	Philisse Overcash	Home Office	United States	Chicago	Illinois	60623	Central	TEC-MA-10002937	Technology	Machines	Canon Color ImageCLASS MF8580Cdw Wireless Laser All-In-One Printer, Copier, Scanner	1007.979	3	0.3	43.1991
3195	CA-2011-165428	9/1/2013	9/4/2013	First Class	JL-15130	Jack Lebron	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10004100	Office Supplies	Paper	Xerox 216	31.104	6	0.2	10.8864
7141	CA-2014-128783	9/7/2016	9/7/2016	Same Day	TG-21640	Trudy Glocke	Consumer	United States	Saint Charles	Missouri	63301	Central	TEC-AC-10002473	Technology	Accessories	Maxell 4.7GB DVD-R	113.52	4	0	46.5432
6821	CA-2014-163860	12/28/2016	1/1/2017	Standard Class	LO-17170	Lori Olson	Corporate	United States	Peoria	Illinois	61604	Central	FUR-CH-10004698	Furniture	Chairs	Padded Folding Chairs, Black, 4/Carton	113.372	2	0.3	-3.2392
4104	CA-2014-137456	12/21/2016	12/21/2016	Same Day	RB-19465	Rick Bensley	Home Office	United States	Fremont	Nebraska	68025	Central	FUR-FU-10001940	Furniture	Furnishings	Staple-based wall hangings	15.92	2	0	7.0048
9921	CA-2013-149272	3/16/2015	3/20/2015	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Bryan	Texas	77803	Central	OFF-BI-10004233	Office Supplies	Binders	GBC Pre-Punched Binding Paper, Plastic, White, 8-1/2" x 11"	22.386	7	0.8	-35.8176
4822	CA-2012-140025	4/7/2014	4/11/2014	Standard Class	PF-19120	Peter Fuller	Consumer	United States	San Antonio	Texas	78207	Central	TEC-AC-10002402	Technology	Accessories	Razer Kraken PRO Over Ear PC and Music Headset	383.952	6	0.2	47.994
902	CA-2014-150959	11/11/2016	11/13/2016	First Class	TD-20995	Tamara Dahlen	Consumer	United States	Garland	Texas	75043	Central	OFF-BI-10001510	Office Supplies	Binders	Deluxe Heavy-Duty Vinyl Round Ring Binder	18.336	4	0.8	-32.088
209	CA-2014-135860	12/1/2016	12/7/2016	Standard Class	JH-15985	Joseph Holt	Consumer	United States	Saginaw	Michigan	48601	Central	OFF-BI-10003274	Office Supplies	Binders	Avery Durable Slant Ring Binders, No Labels	15.92	4	0	7.4824
2811	CA-2012-135685	11/16/2014	11/18/2014	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Milwaukee	Wisconsin	53209	Central	OFF-PA-10000157	Office Supplies	Paper	Xerox 191	179.82	9	0	84.5154
6495	CA-2014-111262	10/28/2016	11/1/2016	Second Class	KH-16510	Keith Herrera	Consumer	United States	Houston	Texas	77095	Central	TEC-AC-10002167	Technology	Accessories	Imation 8gb Micro Traveldrive Usb 2.0 Flash Drive	24	2	0.2	-2.7
6626	CA-2012-141250	1/19/2014	1/23/2014	Standard Class	PM-18940	Paul MacIntyre	Consumer	United States	Texas City	Texas	77590	Central	FUR-CH-10004875	Furniture	Chairs	Harbour Creations 67200 Series Stacking Chairs	199.304	4	0.3	-8.5416
6879	US-2012-123918	10/15/2014	10/15/2014	Same Day	CG-12520	Claire Gute	Consumer	United States	Dallas	Texas	75217	Central	OFF-PA-10003001	Office Supplies	Paper	Xerox 1986	5.344	1	0.2	1.8704
6387	US-2014-104661	1/16/2016	1/19/2016	First Class	TB-21250	Tim Brockman	Consumer	United States	Austin	Texas	78745	Central	OFF-BI-10001098	Office Supplies	Binders	Acco D-Ring Binder w/DublLock	4.276	1	0.8	-6.6278
2227	CA-2014-130771	7/29/2016	8/3/2016	Standard Class	LA-16780	Laura Armstrong	Corporate	United States	Austin	Texas	78745	Central	OFF-FA-10003059	Office Supplies	Fasteners	Assorted Color Push Pins	2.896	2	0.2	0.4706
6650	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	TEC-CO-10001943	Technology	Copiers	Canon PC-428 Personal Copier	319.984	2	0.2	107.9946
4981	US-2013-131114	12/10/2015	12/14/2015	Second Class	RW-19630	Rob Williams	Corporate	United States	Chicago	Illinois	60610	Central	OFF-AP-10003971	Office Supplies	Appliances	Belkin 6 Outlet Metallic Surge Strip	4.356	2	0.8	-11.7612
4149	CA-2014-106068	10/23/2016	10/28/2016	Standard Class	RB-19330	Randy Bradley	Consumer	United States	Austin	Texas	78745	Central	OFF-ST-10004507	Office Supplies	Storage	Advantus Rolling Storage Box	13.72	1	0.2	1.2005
3912	CA-2014-126788	6/5/2016	6/6/2016	First Class	AB-10105	Adrian Barton	Consumer	United States	Pearland	Texas	77581	Central	TEC-PH-10001619	Technology	Phones	LG G3	470.376	3	0.2	52.9173
9251	CA-2013-105354	12/3/2015	12/7/2015	Standard Class	PW-19030	Pauline Webber	Corporate	United States	Marion	Iowa	52302	Central	OFF-BI-10001107	Office Supplies	Binders	GBC White Gloss Covers, Plain Front	115.84	8	0	54.4448
2856	CA-2014-169810	7/25/2016	7/31/2016	Standard Class	RB-19360	Raymond Buch	Consumer	United States	Sioux Falls	South Dakota	57103	Central	OFF-LA-10003663	Office Supplies	Labels	Avery 498	20.23	7	0	9.5081
7384	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-PA-10002250	Office Supplies	Paper	Things To Do Today Pad	17.61	3	0	8.4528
6473	CA-2011-151897	6/6/2013	6/10/2013	Standard Class	VT-21700	Valerie Takahito	Home Office	United States	Houston	Texas	77070	Central	OFF-LA-10001074	Office Supplies	Labels	Round Specialty Laser Printer Labels	100.24	10	0.2	33.831
8307	CA-2013-128671	8/12/2015	8/17/2015	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10003305	Office Supplies	Binders	Avery Hanging File Binders	41.86	7	0	19.2556
2345	CA-2013-119025	2/22/2015	2/28/2015	Standard Class	PV-18985	Paul Van Hugh	Home Office	United States	Milwaukee	Wisconsin	53209	Central	OFF-AP-10001205	Office Supplies	Appliances	Belkin 5 Outlet SurgeMaster Power Centers	490.32	9	0	137.2896
226	CA-2012-163055	8/9/2014	8/16/2014	Standard Class	DS-13180	David Smith	Corporate	United States	Detroit	Michigan	48227	Central	OFF-AR-10001026	Office Supplies	Art	Sanford Uni-Blazer View Highlighters, Chisel Tip, Yellow	2.2	1	0	0.968
2572	CA-2014-109778	7/16/2016	7/21/2016	Standard Class	VM-21685	Valerie Mitchum	Home Office	United States	Woodstock	Illinois	60098	Central	OFF-AR-10003759	Office Supplies	Art	Crayola Anti Dust Chalk, 12/Pack	2.912	2	0.2	0.91
6386	US-2014-104661	1/16/2016	1/19/2016	First Class	TB-21250	Tim Brockman	Consumer	United States	Austin	Texas	78745	Central	TEC-AC-10002331	Technology	Accessories	Maxell 74 Minute CDR, 10/Pack	62.592	8	0.2	13.3008
1037	CA-2013-113061	4/23/2015	4/27/2015	Standard Class	EL-13735	Ed Ludwig	Home Office	United States	Jefferson City	Missouri	65109	Central	FUR-FU-10003975	Furniture	Furnishings	Eldon Advantage Chair Mats for Low to Medium Pile Carpets	86.62	2	0	8.662
987	CA-2014-100314	9/29/2016	10/5/2016	Standard Class	AS-10630	Ann Steele	Home Office	United States	Pasadena	Texas	77506	Central	TEC-MA-10003066	Technology	Machines	Wasp CCD Handheld Bar Code Reader	336.51	3	0.4	44.868
5622	US-2013-124163	9/26/2015	10/1/2015	Standard Class	SC-20695	Steve Chapman	Corporate	United States	La Crosse	Wisconsin	54601	Central	FUR-CH-10004218	Furniture	Chairs	Global Fabric Manager's Chair, Dark Gray	201.96	2	0	50.49
9626	CA-2014-137449	6/29/2016	6/30/2016	First Class	ME-17725	Max Engle	Consumer	United States	Dallas	Texas	75220	Central	FUR-BO-10000780	Furniture	Bookcases	O'Sullivan Plantations 2-Door Library in Landvery Oak	409.9992	3	0.32	-96.4704
2792	CA-2011-125514	9/21/2013	9/22/2013	First Class	BM-11650	Brian Moss	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-AP-10003281	Office Supplies	Appliances	Acco 6 Outlet Guardian Standard Surge Suppressor	36.27	3	0	10.881
1285	US-2012-149692	12/6/2014	12/12/2014	Standard Class	KW-16435	Katrina Willman	Consumer	United States	Austin	Texas	78745	Central	OFF-BI-10002813	Office Supplies	Binders	Avery Reinforcements for Hole-Punch Pages	2.772	7	0.8	-4.851
6446	CA-2012-151785	3/5/2014	3/10/2014	Standard Class	JJ-15445	Jennifer Jackson	Consumer	United States	Chicago	Illinois	60623	Central	OFF-FA-10000611	Office Supplies	Fasteners	Binder Clips by OIC	7.104	6	0.2	2.4864
1501	CA-2014-130386	11/12/2016	11/18/2016	Standard Class	NG-18430	Nathan Gelder	Consumer	United States	Austin	Texas	78745	Central	OFF-PA-10003823	Office Supplies	Paper	Xerox 197	223.056	9	0.2	69.705
670	US-2014-106663	6/9/2016	6/13/2016	Standard Class	MO-17800	Meg O'Connel	Home Office	United States	Chicago	Illinois	60653	Central	FUR-FU-10002759	Furniture	Furnishings	12-1/2 Diameter Round Wall Clock	23.976	3	0.6	-14.3856
9543	CA-2012-135251	8/6/2014	8/10/2014	Standard Class	RP-19270	Rachel Payne	Corporate	United States	Houston	Texas	77095	Central	OFF-BI-10001097	Office Supplies	Binders	Avery Hole Reinforcements	6.23	5	0.8	-9.6565
4571	US-2012-152128	5/25/2014	5/27/2014	Second Class	NM-18445	Nathan Mautz	Home Office	United States	Wichita	Kansas	67212	Central	OFF-AR-10002445	Office Supplies	Art	SANFORD Major Accent Highlighters	21.24	3	0	8.0712
6398	CA-2014-131632	10/31/2016	11/4/2016	Standard Class	AH-10120	Adrian Hane	Home Office	United States	Dallas	Texas	75217	Central	OFF-AR-10003651	Office Supplies	Art	Newell 350	5.248	2	0.2	0.5904
6642	CA-2014-128328	8/5/2016	8/9/2016	Standard Class	PO-18865	Patrick O'Donnell	Consumer	United States	Indianapolis	Indiana	46203	Central	TEC-AC-10001714	Technology	Accessories	Logitech MX Performance Wireless Mouse	79.78	2	0	29.5186
2480	CA-2014-141992	6/19/2016	6/25/2016	Standard Class	FO-14305	Frank Olsen	Consumer	United States	Dallas	Texas	75220	Central	OFF-SU-10002557	Office Supplies	Supplies	Fiskars Spring-Action Scissors	11.184	1	0.2	0.8388
5086	CA-2012-144302	6/19/2014	6/23/2014	Standard Class	ME-17320	Maria Etezadi	Home Office	United States	Dallas	Texas	75081	Central	OFF-BI-10001107	Office Supplies	Binders	GBC White Gloss Covers, Plain Front	5.792	2	0.8	-9.5568
1500	CA-2014-130386	11/12/2016	11/18/2016	Standard Class	NG-18430	Nathan Gelder	Consumer	United States	Austin	Texas	78745	Central	OFF-PA-10002749	Office Supplies	Paper	Wirebound Message Books, 5-1/2 x 4 Forms, 2 or 4 Forms per Page	16.056	3	0.2	5.8203
8882	CA-2013-135594	7/1/2015	7/4/2015	Second Class	AH-10120	Adrian Hane	Home Office	United States	Aurora	Illinois	60505	Central	TEC-AC-10003038	Technology	Accessories	Kingston Digital DataTraveler 16GB USB 2.0	50.12	7	0.2	-0.6265
4544	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	FUR-CH-10004477	Furniture	Chairs	Global Push Button Manager's Chair, Indigo	383.607	9	0.3	-5.4801
3827	CA-2011-132801	10/7/2013	10/12/2013	Standard Class	JG-15805	John Grady	Corporate	United States	Dallas	Texas	75217	Central	OFF-ST-10001228	Office Supplies	Storage	Fellowes Personal Hanging Folder Files, Navy	107.44	10	0.2	10.744
8639	CA-2014-118346	7/23/2016	7/24/2016	First Class	PO-19180	Philisse Overcash	Home Office	United States	Kenosha	Wisconsin	53142	Central	TEC-AC-10000736	Technology	Accessories	Logitech G600 MMO Gaming Mouse	399.95	5	0	143.982
611	CA-2013-161816	4/29/2015	5/2/2015	First Class	NB-18655	Nona Balk	Corporate	United States	Dallas	Texas	75217	Central	TEC-PH-10003012	Technology	Phones	Nortel Meridian M3904 Professional Digital phone	369.576	3	0.2	41.5773
7612	US-2012-130491	2/8/2014	2/11/2014	First Class	BH-11710	Brosina Hoffman	Consumer	United States	Garden City	Kansas	67846	Central	OFF-PA-10000791	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4 x 5 Forms per Page, 200 Sets per Book	9.54	2	0	4.293
7444	CA-2011-109932	12/9/2013	12/11/2013	First Class	VP-21760	Victoria Pisteka	Corporate	United States	Brownsville	Texas	78521	Central	OFF-ST-10000036	Office Supplies	Storage	Recycled Data-Pak for Archival Bound Computer Printouts, 12-1/2 x 12-1/2 x 16	237.096	3	0.2	20.7459
8509	CA-2012-135853	12/11/2014	12/14/2014	First Class	CA-12775	Cynthia Arntzen	Consumer	United States	Detroit	Michigan	48205	Central	TEC-AC-10004761	Technology	Accessories	Maxell 4.7GB DVD+RW 3/Pack	175.23	11	0	61.3305
6530	CA-2011-103744	2/23/2013	2/27/2013	Standard Class	MG-17875	Michael Grace	Home Office	United States	El Paso	Texas	79907	Central	OFF-LA-10004425	Office Supplies	Labels	Staple-on labels	6.936	3	0.2	2.3409
5539	CA-2012-120551	4/13/2014	4/20/2014	Standard Class	SS-20590	Sonia Sunley	Consumer	United States	Norfolk	Nebraska	68701	Central	OFF-BI-10002071	Office Supplies	Binders	Fellowes Black Plastic Comb Bindings	17.43	3	0	8.0178
4268	US-2013-131611	11/6/2015	11/10/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Houston	Texas	77036	Central	OFF-BI-10001989	Office Supplies	Binders	Premium Transparent Presentation Covers by GBC	12.588	3	0.8	-20.1408
9648	CA-2011-150518	11/19/2013	11/24/2013	Standard Class	MW-18220	Mitch Webber	Consumer	United States	Coon Rapids	Minnesota	55433	Central	OFF-ST-10000877	Office Supplies	Storage	Recycled Steel Personal File for Standard File Folders	221.16	4	0	57.5016
7606	CA-2013-101791	5/28/2015	6/1/2015	Standard Class	BS-11665	Brian Stugart	Consumer	United States	Chicago	Illinois	60623	Central	FUR-FU-10002191	Furniture	Furnishings	G.E. Halogen Desk Lamp Bulbs	5.584	2	0.6	-1.6752
3492	CA-2012-157322	7/2/2014	7/6/2014	Standard Class	RH-19600	Rob Haberlin	Consumer	United States	Carol Stream	Illinois	60188	Central	OFF-ST-10003208	Office Supplies	Storage	Adjustable Depth Letter/Legal Cart	435.504	3	0.2	48.9942
5690	CA-2012-119550	12/26/2014	12/31/2014	Standard Class	RB-19705	Roger Barcio	Home Office	United States	Houston	Texas	77070	Central	FUR-CH-10002044	Furniture	Chairs	Office Star - Contemporary Task Swivel chair with 2-way adjustable arms, Plum	275.058	3	0.3	-90.3762
6194	CA-2014-104927	12/22/2016	12/26/2016	Standard Class	AG-10330	Alex Grayson	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10003429	Office Supplies	Binders	Cardinal HOLDit! Binder Insert Strips,Extra Strips	6.33	5	0.8	-9.8115
6453	US-2012-110261	12/19/2014	12/23/2014	Second Class	PR-18880	Patrick Ryan	Consumer	United States	Glenview	Illinois	60025	Central	TEC-PH-10001750	Technology	Phones	Samsung Rugby III	158.376	3	0.2	13.8579
5892	CA-2013-146157	11/22/2015	11/27/2015	Standard Class	RD-19720	Roger Demir	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10001590	Office Supplies	Storage	Tenex Personal Project File with Scoop Front Design, Black	21.568	2	0.2	1.6176
6692	US-2014-165869	7/31/2016	8/5/2016	Standard Class	LS-17200	Luke Schmidt	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-AP-10002472	Office Supplies	Appliances	3M Office Air Cleaner	155.88	6	0	54.558
8675	CA-2014-163265	2/17/2016	2/22/2016	Standard Class	JS-16030	Joy Smith	Consumer	United States	Decatur	Illinois	62521	Central	OFF-ST-10000642	Office Supplies	Storage	Tennsco Lockers, Gray	50.352	3	0.2	-8.1822
7456	CA-2013-137743	7/31/2015	8/5/2015	Standard Class	KH-16360	Katherine Hughes	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10001780	Office Supplies	Storage	Tennsco 16-Compartment Lockers with Coat Rack	1036.624	2	0.2	51.8312
4672	CA-2013-133550	8/1/2015	8/7/2015	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Detroit	Michigan	48205	Central	OFF-AP-10001005	Office Supplies	Appliances	Honeywell Quietcare HEPA Air Cleaner	283.14	4	0.1	72.358
8127	CA-2012-137064	2/6/2014	2/13/2014	Standard Class	TS-21655	Trudy Schmidt	Consumer	United States	Houston	Texas	77070	Central	TEC-AC-10003499	Technology	Accessories	Memorex Mini Travel Drive 8 GB USB 2.0 Flash Drive	18.528	2	0.2	4.4004
9355	CA-2012-110324	12/1/2014	12/5/2014	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Jackson	Michigan	49201	Central	OFF-PA-10001826	Office Supplies	Paper	Xerox 207	19.44	3	0	9.3312
5948	CA-2012-115924	9/14/2014	9/18/2014	Second Class	BE-11455	Brad Eason	Home Office	United States	Des Moines	Iowa	50315	Central	OFF-BI-10004040	Office Supplies	Binders	Wilson Jones Impact Binders	25.9	5	0	12.691
2843	CA-2014-135650	3/23/2016	3/27/2016	Standard Class	AC-10660	Anna Chung	Consumer	United States	Huntsville	Texas	77340	Central	OFF-ST-10001809	Office Supplies	Storage	Fellowes Officeware Wire Shelving	143.728	2	0.2	-32.3388
1913	CA-2014-121503	7/3/2016	7/6/2016	Second Class	FH-14275	Frank Hawley	Corporate	United States	Houston	Texas	77041	Central	TEC-MA-10003674	Technology	Machines	Hewlett-Packard Deskjet 5550 Printer	597.132	3	0.4	49.761
1382	US-2013-100566	9/4/2015	9/10/2015	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Aurora	Illinois	60505	Central	FUR-FU-10003394	Furniture	Furnishings	Tenex "The Solids" Textured Chair Mats	83.952	3	0.6	-90.2484
35	CA-2014-107727	10/19/2016	10/23/2016	Second Class	MA-17560	Matt Abelman	Home Office	United States	Houston	Texas	77095	Central	OFF-PA-10000249	Office Supplies	Paper	Easy-staple paper	29.472	3	0.2	9.9468
2682	CA-2014-127026	1/22/2016	1/28/2016	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Jackson	Michigan	49201	Central	OFF-BI-10001196	Office Supplies	Binders	Avery Flip-Chart Easel Binder, Black	89.52	4	0	42.0744
1333	CA-2011-122567	2/16/2013	2/21/2013	Standard Class	MN-17935	Michael Nguyen	Consumer	United States	Dallas	Texas	75220	Central	OFF-BI-10002012	Office Supplies	Binders	Wilson Jones Easy Flow II Sheet Lifters	1.08	3	0.8	-1.728
2845	US-2013-162852	12/28/2015	1/1/2016	Standard Class	BG-11695	Brooke Gillingham	Corporate	United States	Woodstock	Illinois	60098	Central	FUR-CH-10004853	Furniture	Chairs	Global Manager's Adjustable Task Chair, Storm	845.488	8	0.3	-12.0784
1497	CA-2014-152485	9/4/2016	9/8/2016	Standard Class	JD-15790	John Dryer	Consumer	United States	Coppell	Texas	75019	Central	OFF-ST-10004950	Office Supplies	Storage	Acco Perma 3000 Stacking Storage Drawers	16.784	1	0.2	-0.2098
3651	CA-2014-109960	12/9/2016	12/11/2016	Second Class	DB-13210	Dean Braden	Consumer	United States	Detroit	Michigan	48234	Central	TEC-AC-10004859	Technology	Accessories	Maxell Pro 80 Minute CD-R, 10/Pack	104.88	6	0	41.952
2930	CA-2014-143434	11/18/2016	11/24/2016	Standard Class	ME-17320	Maria Etezadi	Home Office	United States	Saginaw	Michigan	48601	Central	FUR-FU-10002597	Furniture	Furnishings	C-Line Magnetic Cubicle Keepers, Clear Polypropylene	19.76	4	0	8.2992
2720	CA-2011-110030	12/6/2013	12/8/2013	Second Class	LF-17185	Luke Foster	Consumer	United States	Houston	Texas	77095	Central	FUR-FU-10002759	Furniture	Furnishings	12-1/2 Diameter Round Wall Clock	23.976	3	0.6	-14.3856
2774	CA-2013-131576	11/23/2015	11/27/2015	Standard Class	RD-19585	Rob Dowd	Consumer	United States	Detroit	Michigan	48205	Central	OFF-BI-10002852	Office Supplies	Binders	Ibico Standard Transparent Covers	49.44	3	0	24.2256
6826	CA-2013-118689	10/3/2015	10/10/2015	Standard Class	TC-20980	Tamara Chand	Corporate	United States	Lafayette	Indiana	47905	Central	OFF-ST-10001558	Office Supplies	Storage	Acco Perma 4000 Stacking Storage Drawers	32.48	2	0	4.872
1567	CA-2012-129112	11/29/2014	11/30/2014	First Class	AW-10840	Anthony Witt	Consumer	United States	Allen	Texas	75002	Central	TEC-AC-10003038	Technology	Accessories	Kingston Digital DataTraveler 16GB USB 2.0	21.48	3	0.2	-0.2685
3175	CA-2014-157483	11/11/2016	11/18/2016	Standard Class	EP-13915	Emily Phan	Consumer	United States	Detroit	Michigan	48227	Central	OFF-AR-10004260	Office Supplies	Art	Boston 1799 Powerhouse Electric Pencil Sharpener	181.86	7	0	50.9208
4028	CA-2014-139311	8/11/2016	8/13/2016	First Class	SF-20965	Sylvia Foulston	Corporate	United States	Bedford	Texas	76021	Central	TEC-PH-10001557	Technology	Phones	Pyle PMP37LED	153.584	2	0.2	13.4386
6523	CA-2014-138289	1/17/2016	1/19/2016	Second Class	AR-10540	Andy Reiter	Consumer	United States	Jackson	Michigan	49201	Central	OFF-PA-10001260	Office Supplies	Paper	TOPS Money Receipt Book, Consecutively Numbered in Red,	56.07	7	0	25.2315
9475	CA-2012-100818	5/31/2014	6/5/2014	Second Class	JM-15265	Janet Molinari	Corporate	United States	Chicago	Illinois	60653	Central	OFF-LA-10000443	Office Supplies	Labels	Avery 501	5.904	2	0.2	1.9926
7283	CA-2014-155936	6/22/2016	6/29/2016	Standard Class	JK-15730	Joe Kamberova	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10002432	Office Supplies	Binders	Wilson Jones Standard D-Ring Binders	3.036	3	0.8	-5.0094
2994	CA-2014-147291	3/11/2016	3/17/2016	Standard Class	MJ-17740	Max Jones	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10003091	Office Supplies	Binders	GBC DocuBind TL200 Manual Binding Machine	895.92	4	0	421.0824
3615	CA-2014-112529	11/19/2016	11/21/2016	First Class	SC-20770	Stewart Carmichael	Corporate	United States	San Antonio	Texas	78207	Central	FUR-TA-10002622	Furniture	Tables	Bush Andora Conference Table, Maple/Graphite Gray Finish	718.116	6	0.3	-71.8116
4670	US-2014-133200	5/6/2016	5/11/2016	Standard Class	DB-13555	Dorothy Badders	Corporate	United States	Fort Worth	Texas	76106	Central	FUR-BO-10001601	Furniture	Bookcases	Sauder Mission Library with Doors, Fruitwood Finish	623.4648	7	0.32	-119.1918
9984	US-2013-157728	9/23/2015	9/29/2015	Standard Class	RC-19960	Ryan Crowe	Consumer	United States	Grand Rapids	Michigan	49505	Central	TEC-PH-10001305	Technology	Phones	Panasonic KX TS208W Corded phone	97.98	2	0	27.4344
7732	CA-2014-140508	9/18/2016	9/21/2016	First Class	PA-19060	Pete Armstrong	Home Office	United States	Dallas	Texas	75220	Central	OFF-EN-10000927	Office Supplies	Envelopes	Jet-Pak Recycled Peel 'N' Seal Padded Mailers	114.848	4	0.2	35.89
7906	US-2012-118766	10/15/2014	10/22/2014	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75217	Central	OFF-EN-10001415	Office Supplies	Envelopes	Staple envelope	4.464	1	0.2	1.674
5220	CA-2014-145653	9/1/2016	9/1/2016	Same Day	CA-12775	Cynthia Arntzen	Consumer	United States	Detroit	Michigan	48205	Central	FUR-CH-10004875	Furniture	Chairs	Harbour Creations 67200 Series Stacking Chairs	498.26	7	0	134.5302
2012	CA-2012-155761	12/11/2014	12/11/2014	Same Day	SC-20800	Stuart Calhoun	Consumer	United States	Houston	Texas	77041	Central	TEC-AC-10001606	Technology	Accessories	Logitech Wireless Performance Mouse MX for PC and Mac	159.984	2	0.2	35.9964
166	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	TEC-MA-10000822	Technology	Machines	Lexmark MX611dhe Monochrome Laser Printer	8159.952	8	0.4	-1359.992
4440	CA-2013-162726	12/28/2015	1/3/2016	Standard Class	MT-17815	Meg Tillman	Consumer	United States	Port Arthur	Texas	77642	Central	OFF-PA-10004041	Office Supplies	Paper	It's Hot Message Books with Stickers, 2 3/4" x 5"	23.68	4	0.2	7.4
5262	CA-2011-105165	9/7/2013	9/10/2013	First Class	SZ-20035	Sam Zeldin	Home Office	United States	Houston	Texas	77036	Central	OFF-BI-10000050	Office Supplies	Binders	Angle-D Binders with Locking Rings, Label Holders	2.92	2	0.8	-4.818
2613	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	FUR-FU-10000221	Furniture	Furnishings	Master Caster Door Stop, Brown	6.096	3	0.6	-3.9624
9304	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	OFF-PA-10003936	Office Supplies	Paper	Xerox 1994	15.552	3	0.2	5.4432
151	CA-2013-114489	12/6/2015	12/10/2015	Standard Class	JE-16165	Justin Ellison	Corporate	United States	Franklin	Wisconsin	53132	Central	OFF-BI-10002735	Office Supplies	Binders	GBC Prestige Therm-A-Bind Covers	171.55	5	0	80.6285
9542	CA-2012-135251	8/6/2014	8/10/2014	Standard Class	RP-19270	Rachel Payne	Corporate	United States	Houston	Texas	77095	Central	OFF-LA-10004544	Office Supplies	Labels	Avery 505	35.52	3	0.2	13.32
6327	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-ST-10000760	Office Supplies	Storage	Eldon Fold 'N Roll Cart System	13.98	1	0	4.0542
8737	CA-2013-168774	9/5/2015	9/10/2015	Standard Class	RP-19855	Roy Phan	Corporate	United States	Woodbury	Minnesota	55125	Central	OFF-ST-10001490	Office Supplies	Storage	Hot File 7-Pocket, Floor Stand	535.41	3	0	160.623
5756	CA-2011-163748	10/14/2013	10/18/2013	Standard Class	HG-15025	Hunter Glantz	Consumer	United States	Fort Worth	Texas	76106	Central	OFF-AP-10004052	Office Supplies	Appliances	Hoover Replacement Belts For Soft Guard & Commercial Ltweight Upright Vacs, 2/Pk	3.16	4	0.8	-8.532
3404	CA-2014-168739	5/29/2016	6/5/2016	Standard Class	HZ-14950	Henia Zydlo	Consumer	United States	Houston	Texas	77095	Central	FUR-FU-10003919	Furniture	Furnishings	Eldon Executive Woodline II Cherry Finish Desk Accessories	65.424	4	0.6	-52.3392
4073	CA-2012-156104	12/6/2014	12/8/2014	Second Class	NP-18685	Nora Pelletier	Home Office	United States	Indianapolis	Indiana	46203	Central	TEC-CO-10002095	Technology	Copiers	Hewlett Packard 610 Color Digital Copier / Printer	999.98	2	0	449.991
5981	CA-2011-117765	9/7/2013	9/13/2013	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Tulsa	Oklahoma	74133	Central	FUR-CH-10004698	Furniture	Chairs	Padded Folding Chairs, Black, 4/Carton	161.96	2	0	45.3488
1835	CA-2014-162691	8/1/2016	8/7/2016	Standard Class	AS-10045	Aaron Smayling	Corporate	United States	Austin	Texas	78745	Central	OFF-PA-10003729	Office Supplies	Paper	Xerox 1998	36.288	7	0.2	12.7008
469	CA-2014-154907	3/31/2016	4/4/2016	Standard Class	DS-13180	David Smith	Corporate	United States	Amarillo	Texas	79109	Central	FUR-BO-10002824	Furniture	Bookcases	Bush Mission Pointe Library	205.3328	2	0.32	-36.2352
3886	US-2014-127341	1/30/2016	2/3/2016	Standard Class	CK-12595	Clytie Kelty	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10001072	Office Supplies	Binders	GBC Clear Cover, 8-1/2 x 11, unpunched, 25 covers per pack	12.128	4	0.8	-20.6176
9544	CA-2012-135251	8/6/2014	8/10/2014	Standard Class	RP-19270	Rachel Payne	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10003302	Office Supplies	Paper	Xerox 1906	56.704	2	0.2	19.1376
3493	CA-2012-157322	7/2/2014	7/6/2014	Standard Class	RH-19600	Rob Haberlin	Consumer	United States	Carol Stream	Illinois	60188	Central	OFF-PA-10000659	Office Supplies	Paper	Adams Phone Message Book, Professional, 400 Message Capacity, 5 3/6” x 11”	11.168	2	0.2	3.7692
8828	US-2011-157847	4/2/2013	4/6/2013	Second Class	SC-20020	Sam Craven	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10001593	Office Supplies	Paper	Xerox 1947	33.488	7	0.2	10.465
3110	CA-2013-121671	7/18/2015	7/23/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Springfield	Missouri	65807	Central	OFF-PA-10001892	Office Supplies	Paper	Rediform Wirebound "Phone Memo" Message Book, 11 x 5-3/4	7.64	1	0	3.7436
6047	CA-2013-154662	6/10/2015	6/17/2015	Standard Class	BF-11215	Benjamin Farhat	Home Office	United States	Minneapolis	Minnesota	55407	Central	FUR-TA-10001771	Furniture	Tables	Bush Cubix Conference Tables, Fully Assembled	692.94	3	0	173.235
3490	CA-2012-157322	7/2/2014	7/6/2014	Standard Class	RH-19600	Rob Haberlin	Consumer	United States	Carol Stream	Illinois	60188	Central	FUR-CH-10003774	Furniture	Chairs	Global Wood Trimmed Manager's Task Chair, Khaki	382.116	6	0.3	-92.7996
2591	US-2013-115455	9/9/2015	9/15/2015	Standard Class	SE-20110	Sanjit Engle	Consumer	United States	Wheeling	Illinois	60090	Central	FUR-FU-10004671	Furniture	Furnishings	Executive Impressions 12" Wall Clock	14.136	2	0.6	-7.7748
2592	US-2013-115455	9/9/2015	9/15/2015	Standard Class	SE-20110	Sanjit Engle	Consumer	United States	Wheeling	Illinois	60090	Central	FUR-TA-10003569	Furniture	Tables	Bretford CR8500 Series Meeting Room Furniture	601.47	3	0.5	-300.735
7068	CA-2013-114209	5/22/2015	5/27/2015	Standard Class	AS-10285	Alejandro Savely	Corporate	United States	Dallas	Texas	75081	Central	OFF-BI-10000343	Office Supplies	Binders	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	1.964	2	0.8	-3.2406
9479	CA-2011-126193	9/7/2013	9/14/2013	Standard Class	SS-20410	Shahid Shariari	Consumer	United States	Oswego	Illinois	60543	Central	OFF-FA-10000936	Office Supplies	Fasteners	Acco Hot Clips Clips to Go	13.16	5	0.2	4.1125
750	CA-2014-126074	10/2/2016	10/6/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Trenton	Michigan	48183	Central	OFF-BI-10003638	Office Supplies	Binders	GBC Durable Plastic Covers	58.05	3	0	26.703
6695	US-2013-163538	8/27/2015	8/31/2015	Standard Class	SS-20515	Shirley Schmidt	Home Office	United States	Franklin	Wisconsin	53132	Central	TEC-AC-10002006	Technology	Accessories	Memorex Micro Travel Drive 16 GB	47.97	3	0	14.8707
1820	US-2011-130379	5/25/2013	5/29/2013	Standard Class	JL-15235	Janet Lee	Consumer	United States	Chicago	Illinois	60623	Central	FUR-FU-10002553	Furniture	Furnishings	Electrix Incandescent Magnifying Lamp, Black	29.32	2	0.6	-24.189
3477	CA-2013-144911	11/28/2015	12/1/2015	First Class	RW-19630	Rob Williams	Corporate	United States	Overland Park	Kansas	66212	Central	OFF-BI-10000977	Office Supplies	Binders	Ibico Plastic Spiral Binding Combs	152	5	0	69.92
8975	CA-2014-156622	11/23/2016	11/26/2016	First Class	JP-15460	Jennifer Patt	Corporate	United States	Dallas	Texas	75220	Central	OFF-PA-10000477	Office Supplies	Paper	Xerox 22	36.288	7	0.2	12.7008
5477	CA-2014-169691	6/15/2016	6/18/2016	First Class	Dp-13240	Dean percer	Home Office	United States	Maple Grove	Minnesota	55369	Central	OFF-ST-10001291	Office Supplies	Storage	Tenex Personal Self-Stacking Standard File Box, Black/Gray	84.55	5	0	22.8285
8663	CA-2012-131856	5/12/2014	5/17/2014	Standard Class	JG-15160	James Galang	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10001336	Technology	Phones	Digium D40 VoIP phone	619.152	6	0.2	69.6546
7949	CA-2011-131009	3/1/2013	3/5/2013	Standard Class	SC-20380	Shahid Collister	Consumer	United States	El Paso	Texas	79907	Central	FUR-CH-10001270	Furniture	Chairs	Harbour Creations Steel Folding Chair	362.25	6	0.3	0
4703	CA-2014-140298	5/11/2016	5/17/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Austin	Texas	78745	Central	FUR-FU-10001967	Furniture	Furnishings	Telescoping Adjustable Floor Lamp	7.996	1	0.6	-6.9965
9585	CA-2014-132584	8/26/2016	8/27/2016	First Class	HJ-14875	Heather Jas	Home Office	United States	Detroit	Michigan	48234	Central	OFF-ST-10000344	Office Supplies	Storage	Neat Ideas Personal Hanging Folder Files, Black	53.72	4	0	13.9672
9260	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	OFF-ST-10002583	Office Supplies	Storage	Fellowes Neat Ideas Storage Cubes	64.96	2	0	2.5984
8931	US-2012-168704	4/13/2014	4/17/2014	Standard Class	FP-14320	Frank Preis	Consumer	United States	Huntsville	Texas	77340	Central	TEC-PH-10001061	Technology	Phones	Apple iPhone 5C	239.976	3	0.2	17.9982
3056	US-2012-100377	8/28/2014	9/1/2014	Standard Class	TS-21370	Todd Sumrall	Corporate	United States	Chicago	Illinois	60623	Central	TEC-CO-10001046	Technology	Copiers	Canon Imageclass D680 Copier / Fax	2799.96	5	0.2	874.9875
3496	CA-2014-142034	9/24/2016	9/28/2016	Standard Class	KB-16240	Karen Bern	Corporate	United States	Saint Cloud	Minnesota	56301	Central	FUR-CH-10000665	Furniture	Chairs	Global Airflow Leather Mesh Back Chair, Black	603.92	4	0	181.176
3136	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	OFF-ST-10002583	Office Supplies	Storage	Fellowes Neat Ideas Storage Cubes	77.952	3	0.2	-15.5904
7007	CA-2011-119466	12/15/2013	12/21/2013	Standard Class	SP-20860	Sung Pak	Corporate	United States	Chicago	Illinois	60623	Central	FUR-FU-10001546	Furniture	Furnishings	Dana Swing-Arm Lamps	8.544	2	0.6	-7.476
4283	CA-2011-103100	12/20/2013	12/23/2013	First Class	AB-10105	Adrian Barton	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-LA-10003720	Office Supplies	Labels	Avery 487	3.69	1	0	1.7343
6439	US-2014-113992	12/14/2016	12/19/2016	Standard Class	LC-16885	Lena Creighton	Consumer	United States	Plano	Texas	75023	Central	FUR-TA-10000577	Furniture	Tables	Bretford CR4500 Series Slim Rectangular Table	974.988	4	0.3	-97.4988
1514	CA-2014-112809	8/18/2016	8/22/2016	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Dallas	Texas	75220	Central	OFF-BI-10001098	Office Supplies	Binders	Acco D-Ring Binder w/DublLock	21.38	5	0.8	-33.139
9628	CA-2011-139283	11/23/2013	11/27/2013	Standard Class	BT-11440	Bobby Trafton	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10002049	Office Supplies	Binders	UniKeep View Case Binders	14.67	3	0	6.7482
6763	CA-2013-144764	9/3/2015	9/9/2015	Standard Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60623	Central	OFF-LA-10000240	Office Supplies	Labels	Self-Adhesive Address Labels for Typewriters by Universal	29.24	5	0.2	9.8685
3829	CA-2014-141733	5/7/2016	5/11/2016	Standard Class	RW-19540	Rick Wilson	Corporate	United States	Detroit	Michigan	48234	Central	FUR-CH-10002017	Furniture	Chairs	SAFCO Optional Arm Kit for Workspace Cribbage Stacking Chair	26.64	1	0	7.4592
5569	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	TEC-CO-10001449	Technology	Copiers	Hewlett Packard LaserJet 3310 Copier	959.984	2	0.2	335.9944
5727	CA-2012-110548	5/4/2014	5/8/2014	Standard Class	AH-10690	Anna Häberlin	Corporate	United States	Houston	Texas	77095	Central	TEC-PH-10002922	Technology	Phones	ShoreTel ShorePhone IP 230 VoIP phone	946.344	7	0.2	118.293
3788	CA-2013-169971	9/5/2015	9/10/2015	Standard Class	IL-15100	Ivan Liston	Consumer	United States	Houston	Texas	77041	Central	OFF-AR-10002804	Office Supplies	Art	Faber Castell Col-Erase Pencils	3.912	1	0.2	1.0269
8253	CA-2012-140221	3/5/2014	3/9/2014	Second Class	MS-17365	Maribeth Schnelling	Consumer	United States	Chicago	Illinois	60653	Central	OFF-ST-10000777	Office Supplies	Storage	Companion Letter/Legal File, Black	60.416	2	0.2	6.0416
6716	CA-2014-107629	12/14/2016	12/14/2016	Same Day	DB-13060	Dave Brooks	Consumer	United States	Skokie	Illinois	60076	Central	OFF-AR-10002987	Office Supplies	Art	Prismacolor Color Pencil Set	95.232	6	0.2	24.9984
1359	CA-2014-160045	4/26/2016	4/27/2016	First Class	LB-16735	Larry Blacks	Consumer	United States	Fort Worth	Texas	76106	Central	FUR-FU-10000010	Furniture	Furnishings	DAX Value U-Channel Document Frames, Easel Back	1.988	1	0.6	-1.4413
5158	CA-2014-163006	6/30/2016	7/4/2016	Second Class	GH-14410	Gary Hansen	Home Office	United States	Chicago	Illinois	60653	Central	FUR-CH-10000229	Furniture	Chairs	Global Enterprise Series Seating High-Back Swivel/Tilt Chairs	569.058	3	0.3	-178.8468
5280	US-2014-104094	9/7/2016	9/11/2016	Standard Class	AG-10675	Anna Gayman	Consumer	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10002134	Technology	Accessories	Rosewill 107 Normal Keys USB Wired Standard Keyboard	13.48	1	0	1.8872
5305	US-2011-166310	9/21/2013	9/23/2013	First Class	JS-15940	Joni Sundaresam	Home Office	United States	Garland	Texas	75043	Central	FUR-FU-10001546	Furniture	Furnishings	Dana Swing-Arm Lamps	8.544	2	0.6	-7.476
672	US-2014-106663	6/9/2016	6/13/2016	Standard Class	MO-17800	Meg O'Connel	Home Office	United States	Chicago	Illinois	60653	Central	OFF-PA-10002377	Office Supplies	Paper	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 200/Messages	36.352	8	0.2	11.36
3969	US-2012-163685	6/1/2014	6/5/2014	Standard Class	KE-16420	Katrina Edelman	Corporate	United States	San Antonio	Texas	78207	Central	OFF-BI-10001890	Office Supplies	Binders	Avery Poly Binder Pockets	5.728	8	0.8	-9.1648
4702	CA-2014-140298	5/11/2016	5/17/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Austin	Texas	78745	Central	OFF-PA-10003657	Office Supplies	Paper	Xerox 1927	6.848	2	0.2	2.14
3054	CA-2013-128517	4/10/2015	4/15/2015	Second Class	SW-20350	Sean Wendt	Home Office	United States	Detroit	Michigan	48227	Central	TEC-PH-10002555	Technology	Phones	Nortel Meridian M5316 Digital phone	517.9	2	0	134.654
6742	CA-2011-144029	5/26/2013	5/31/2013	Standard Class	MM-18055	Michelle Moray	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AR-10000716	Office Supplies	Art	DIXON Ticonderoga Erasable Checking Pencils	13.392	3	0.2	3.1806
3740	CA-2013-133340	12/10/2015	12/14/2015	Standard Class	LH-17155	Logan Haushalter	Consumer	United States	Jackson	Michigan	49201	Central	TEC-AC-10001109	Technology	Accessories	Logitech Trackman Marble Mouse	59.98	2	0	25.1916
9513	CA-2014-142461	5/30/2016	6/3/2016	Second Class	KT-16480	Kean Thornton	Consumer	United States	Dallas	Texas	75217	Central	FUR-BO-10001811	Furniture	Bookcases	Atlantic Metals Mobile 5-Shelf Bookcases, Custom Colors	204.6664	1	0.32	-6.0196
6903	CA-2014-111220	9/2/2016	9/8/2016	Standard Class	JS-15595	Jill Stevenson	Corporate	United States	Chicago	Illinois	60653	Central	OFF-FA-10002280	Office Supplies	Fasteners	Advantus Plastic Paper Clips	16	4	0.2	5.6
3241	US-2013-127971	11/21/2015	11/28/2015	Standard Class	DW-13195	David Wiener	Corporate	United States	Houston	Texas	77095	Central	FUR-FU-10000023	Furniture	Furnishings	Eldon Wave Desk Accessories	7.068	3	0.6	-2.8272
646	CA-2014-126221	12/30/2016	1/5/2017	Standard Class	CC-12430	Chuck Clark	Home Office	United States	Columbus	Indiana	47201	Central	OFF-AP-10002457	Office Supplies	Appliances	Eureka The Boss Plus 12-Amp Hard Box Upright Vacuum, Red	209.3	2	0	56.511
4237	CA-2013-162404	7/24/2015	7/28/2015	Standard Class	NF-18475	Neil Französisch	Home Office	United States	Rockford	Illinois	61107	Central	OFF-BI-10000948	Office Supplies	Binders	GBC Laser Imprintable Binding System Covers, Desert Sand	11.416	4	0.8	-18.8364
4360	CA-2014-162565	12/11/2016	12/11/2016	Same Day	RR-19315	Ralph Ritter	Consumer	United States	Aurora	Illinois	60505	Central	FUR-CH-10003973	Furniture	Chairs	GuestStacker Chair with Chrome Finish Legs	520.464	2	0.3	-14.8704
1103	US-2014-145863	4/21/2016	4/27/2016	Standard Class	RP-19390	Resi Pölking	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10004140	Office Supplies	Binders	Avery Non-Stick Binders	2.694	3	0.8	-4.7145
4369	CA-2014-117044	9/11/2016	9/13/2016	Second Class	HA-14920	Helen Andreada	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10003657	Office Supplies	Paper	Xerox 1927	20.544	6	0.2	6.42
6422	CA-2013-140130	11/1/2015	11/6/2015	Standard Class	HW-14935	Helen Wasserman	Corporate	United States	Tulsa	Oklahoma	74133	Central	OFF-ST-10001128	Office Supplies	Storage	Carina Mini System Audio Rack, Model AR050B	332.94	3	0	9.9882
1960	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-AP-10004785	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Medium Room	33.99	3	0	14.6157
2941	CA-2014-155880	3/25/2016	3/31/2016	Standard Class	JD-16150	Justin Deggeller	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10000422	Furniture	Chairs	Global Highback Leather Tilter in Burgundy	90.99	1	0	14.5584
4383	US-2012-122784	7/20/2014	7/27/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Highland Park	Illinois	60035	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	2.88	5	0.8	-4.464
5077	CA-2011-134572	4/20/2013	4/22/2013	Second Class	SV-20365	Seth Vernon	Consumer	United States	Houston	Texas	77070	Central	OFF-ST-10004634	Office Supplies	Storage	Personal Folder Holder, Ebony	44.84	5	0.2	5.605
2915	CA-2012-134747	10/12/2014	10/17/2014	Second Class	DL-12925	Daniel Lacy	Consumer	United States	Noblesville	Indiana	46060	Central	TEC-PH-10002890	Technology	Phones	AT&T 17929 Lendline Telephone	135.72	3	0	35.2872
4810	CA-2012-151589	12/27/2014	12/30/2014	First Class	RE-19450	Richard Eichhorn	Consumer	United States	Eau Claire	Wisconsin	54703	Central	OFF-PA-10003228	Office Supplies	Paper	Xerox 1917	195.64	4	0	91.9508
6795	CA-2012-145394	11/16/2014	11/20/2014	Standard Class	MC-17605	Matt Connell	Corporate	United States	Chicago	Illinois	60610	Central	TEC-PH-10001051	Technology	Phones	HTC One	239.976	3	0.2	26.9973
2668	CA-2013-111794	10/2/2015	10/2/2015	Same Day	HG-15025	Hunter Glantz	Consumer	United States	Amarillo	Texas	79109	Central	OFF-PA-10000474	Office Supplies	Paper	Easy-staple paper	28.352	1	0.2	9.5688
4231	CA-2014-100223	7/5/2016	7/10/2016	Standard Class	LS-16945	Linda Southworth	Corporate	United States	Dallas	Texas	75220	Central	OFF-BI-10003429	Office Supplies	Binders	Cardinal HOLDit! Binder Insert Strips,Extra Strips	11.394	9	0.8	-17.6607
2525	CA-2012-124541	4/6/2014	4/10/2014	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	OFF-AR-10004078	Office Supplies	Art	Newell 312	42.048	9	0.2	5.256
6904	CA-2014-111220	9/2/2016	9/8/2016	Standard Class	JS-15595	Jill Stevenson	Corporate	United States	Chicago	Illinois	60653	Central	OFF-AP-10003278	Office Supplies	Appliances	Belkin 7-Outlet SurgeMaster Home Series	5.588	2	0.8	-15.0876
5156	US-2012-124219	8/7/2014	8/8/2014	First Class	KW-16570	Kelly Williams	Consumer	United States	Kirkwood	Missouri	63122	Central	FUR-FU-10000305	Furniture	Furnishings	Tenex V2T-RE Standard Weight Series Chair Mat, 45" x 53", Lip 25" x 12"	212.94	3	0	34.0704
3286	CA-2014-150525	2/21/2016	2/26/2016	Standard Class	JP-16135	Julie Prescott	Home Office	United States	Muskogee	Oklahoma	74403	Central	OFF-AR-10002375	Office Supplies	Art	Newell 351	6.56	2	0	1.9024
3003	CA-2012-130610	7/5/2014	7/10/2014	Standard Class	VP-21730	Victor Preis	Home Office	United States	Sterling Heights	Michigan	48310	Central	OFF-BI-10003655	Office Supplies	Binders	Durable Pressboard Binders	19	5	0	8.93
4722	CA-2011-106229	6/7/2013	6/11/2013	Second Class	NR-18550	Nick Radford	Consumer	United States	Aurora	Illinois	60505	Central	FUR-TA-10002041	Furniture	Tables	Bevis Round Conference Table Top, X-Base	268.935	3	0.5	-209.7693
7485	CA-2014-135111	12/28/2016	1/2/2017	Standard Class	CS-12400	Christopher Schild	Home Office	United States	Fargo	North Dakota	58103	Central	OFF-AR-10004707	Office Supplies	Art	Staples in misc. colors	2.48	1	0	0.868
87	CA-2014-155558	10/26/2016	11/2/2016	Standard Class	PG-18895	Paul Gonzalez	Consumer	United States	Rochester	Minnesota	55901	Central	TEC-AC-10001998	Technology	Accessories	Logitech LS21 Speaker System - PC Multimedia - 2.1-CH - Wired	19.99	1	0	6.7966
101	CA-2013-158568	8/30/2015	9/3/2015	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Chicago	Illinois	60610	Central	TEC-AC-10001767	Technology	Accessories	SanDisk Ultra 64 GB MicroSDHC Class 10 Memory Card	95.976	3	0.2	-10.7973
7706	CA-2013-114601	8/27/2015	9/3/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Detroit	Michigan	48234	Central	TEC-AC-10003911	Technology	Accessories	NETGEAR AC1750 Dual Band Gigabit Smart WiFi Router	479.97	3	0	163.1898
5070	CA-2011-124478	8/8/2013	8/12/2013	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Trenton	Michigan	48183	Central	OFF-AP-10002495	Office Supplies	Appliances	Acco Smartsocket Table Surge Protector, 6 Color-Coded Adapter Outlets	167.535	3	0.1	37.23
1549	CA-2012-111395	11/23/2014	11/27/2014	Standard Class	VB-21745	Victoria Brennan	Corporate	United States	San Antonio	Texas	78207	Central	OFF-ST-10001291	Office Supplies	Storage	Tenex Personal Self-Stacking Standard File Box, Black/Gray	27.056	2	0.2	2.3674
2529	CA-2012-124541	4/6/2014	4/10/2014	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10001526	Office Supplies	Paper	Xerox 1949	7.968	2	0.2	2.8884
1749	US-2011-157406	4/25/2013	4/29/2013	Standard Class	DA-13450	Dianna Arnett	Home Office	United States	Houston	Texas	77095	Central	OFF-PA-10003543	Office Supplies	Paper	Xerox 1985	10.368	2	0.2	3.6288
6641	CA-2014-128328	8/5/2016	8/9/2016	Standard Class	PO-18865	Patrick O'Donnell	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-BI-10001989	Office Supplies	Binders	Premium Transparent Presentation Covers by GBC	125.88	6	0	60.4224
6532	US-2014-107384	12/4/2016	12/8/2016	Standard Class	TP-21130	Theone Pippenger	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-AR-10001315	Office Supplies	Art	Newell 310	8.8	5	0	2.552
7349	CA-2011-130421	3/3/2013	3/7/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Houston	Texas	77095	Central	OFF-AP-10002534	Office Supplies	Appliances	3.6 Cubic Foot Counter Height Office Refrigerator	176.772	3	0.8	-459.6072
5006	CA-2012-158659	11/10/2014	11/14/2014	Second Class	SC-20695	Steve Chapman	Corporate	United States	Richmond	Indiana	47374	Central	OFF-ST-10003306	Office Supplies	Storage	Letter Size Cart	714.3	5	0	207.147
4438	CA-2013-163398	5/4/2015	5/9/2015	Standard Class	CB-12415	Christy Brittain	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AP-10002403	Office Supplies	Appliances	Acco Smartsocket Color-Coded Six-Outlet AC Adapter Model Surge Protectors	26.406	3	0.8	-71.2962
9105	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10000474	Office Supplies	Binders	Avery Recycled Flexi-View Covers for Binding Systems	32.06	10	0.8	-51.296
6471	CA-2012-108532	8/29/2014	9/2/2014	Standard Class	CC-12100	Chad Cunningham	Home Office	United States	Detroit	Michigan	48234	Central	TEC-PH-10001750	Technology	Phones	Samsung Rugby III	131.98	2	0	35.6346
7161	CA-2012-145835	5/13/2014	5/18/2014	Second Class	BF-11170	Ben Ferrer	Home Office	United States	Chicago	Illinois	60623	Central	OFF-FA-10002280	Office Supplies	Fasteners	Advantus Plastic Paper Clips	16	4	0.2	5.6
1983	CA-2011-122749	12/3/2013	12/9/2013	Standard Class	NG-18430	Nathan Gelder	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	TEC-PH-10003811	Technology	Phones	Jabra Supreme Plus Driver Edition Headset	479.96	4	0	134.3888
6905	CA-2014-111220	9/2/2016	9/8/2016	Standard Class	JS-15595	Jill Stevenson	Corporate	United States	Chicago	Illinois	60653	Central	OFF-ST-10003994	Office Supplies	Storage	Belkin 19" Center-Weighted Shelf, Gray	235.92	5	0.2	-44.235
5475	CA-2014-121741	12/26/2016	12/26/2016	Same Day	YC-21895	Yoseph Carroll	Corporate	United States	Fremont	Nebraska	68025	Central	OFF-ST-10004459	Office Supplies	Storage	Tennsco Single-Tier Lockers	750.68	2	0	37.534
1852	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	OFF-PA-10000528	Office Supplies	Paper	Xerox 1981	26.4	5	0	11.88
9164	CA-2012-164007	6/8/2014	6/12/2014	Standard Class	MG-17695	Maureen Gnade	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10003433	Technology	Accessories	Maxell 4.7GB DVD+R 5/Pack	2.376	3	0.2	0.7425
3901	CA-2012-121097	1/3/2014	1/8/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Baytown	Texas	77520	Central	OFF-PA-10001937	Office Supplies	Paper	Xerox 21	10.368	2	0.2	3.6288
93	CA-2012-149587	1/31/2014	2/5/2014	Second Class	KB-16315	Karl Braun	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-PA-10003177	Office Supplies	Paper	Xerox 1999	12.96	2	0	6.2208
3194	CA-2011-165428	9/1/2013	9/4/2013	First Class	JL-15130	Jack Lebron	Consumer	United States	Houston	Texas	77036	Central	OFF-BI-10002949	Office Supplies	Binders	Prestige Round Ring Binders	3.648	3	0.8	-6.0192
5540	US-2014-150595	5/22/2016	5/26/2016	Standard Class	LE-16810	Laurel Elliston	Consumer	United States	Chicago	Illinois	60653	Central	FUR-CH-10000513	Furniture	Chairs	High-Back Leather Manager's Chair	181.986	2	0.3	-54.5958
7186	CA-2014-133102	8/17/2016	8/24/2016	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77095	Central	OFF-AR-10003183	Office Supplies	Art	Avery Fluorescent Highlighter Four-Color Set	8.016	3	0.2	1.002
5682	CA-2013-141551	9/25/2015	10/1/2015	Standard Class	BP-11230	Benjamin Patterson	Consumer	United States	Broken Arrow	Oklahoma	74012	Central	OFF-PA-10001569	Office Supplies	Paper	Xerox 232	6.48	1	0	3.1104
8119	US-2014-106551	7/22/2016	7/27/2016	Standard Class	EB-13930	Eric Barreto	Consumer	United States	Chicago	Illinois	60653	Central	FUR-CH-10004997	Furniture	Chairs	Hon Every-Day Series Multi-Task Chairs	526.344	4	0.3	-75.192
9194	CA-2012-141810	11/2/2014	11/7/2014	Standard Class	BB-10990	Barry Blumstein	Corporate	United States	San Antonio	Texas	78207	Central	TEC-PH-10002200	Technology	Phones	Aastra 6757i CT Wireless VoIP phone	344.704	2	0.2	38.7792
3880	CA-2011-151001	4/5/2013	4/7/2013	First Class	JG-15805	John Grady	Corporate	United States	Decatur	Illinois	62521	Central	OFF-ST-10001031	Office Supplies	Storage	Adjustable Personal File Tote	52.096	4	0.2	3.9072
7160	CA-2012-145835	5/13/2014	5/18/2014	Second Class	BF-11170	Ben Ferrer	Home Office	United States	Chicago	Illinois	60623	Central	TEC-PH-10004447	Technology	Phones	Toshiba IPT2010-SD IP Telephone	222.384	2	0.2	16.6788
6256	CA-2014-139444	9/9/2016	9/15/2016	Standard Class	GK-14620	Grace Kelly	Corporate	United States	Plano	Texas	75023	Central	OFF-LA-10000134	Office Supplies	Labels	Avery 511	9.856	4	0.2	3.4496
2374	CA-2013-159940	7/8/2015	7/12/2015	Second Class	BF-11020	Barry Französisch	Corporate	United States	Aurora	Illinois	60505	Central	OFF-PA-10001609	Office Supplies	Paper	Tops Wirebound Message Log Books	23.688	9	0.2	7.6986
4107	US-2013-148334	8/23/2015	8/27/2015	Standard Class	DD-13570	Dorothy Dickinson	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	4.312	2	0.8	-6.8992
3191	US-2012-163783	12/27/2014	1/1/2015	Standard Class	DR-12940	Daniel Raglin	Home Office	United States	Chicago	Illinois	60610	Central	OFF-ST-10002957	Office Supplies	Storage	Sterilite Show Offs Storage Containers	12.672	3	0.2	-3.168
16	US-2012-118983	11/22/2014	11/26/2014	Standard Class	HP-14815	Harold Pawlan	Home Office	United States	Fort Worth	Texas	76106	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	2.544	3	0.8	-3.816
9225	CA-2014-121160	11/4/2016	11/4/2016	Same Day	FM-14290	Frank Merwin	Home Office	United States	Bryan	Texas	77803	Central	OFF-BI-10003094	Office Supplies	Binders	Self-Adhesive Ring Binder Labels	1.408	2	0.8	-2.3232
723	CA-2013-142335	12/16/2015	12/20/2015	Standard Class	MP-17965	Michael Paige	Corporate	United States	Detroit	Michigan	48205	Central	OFF-ST-10000036	Office Supplies	Storage	Recycled Data-Pak for Archival Bound Computer Printouts, 12-1/2 x 12-1/2 x 16	296.37	3	0	80.0199
8732	CA-2012-111017	7/31/2014	8/6/2014	Standard Class	SC-20695	Steve Chapman	Corporate	United States	Saint Louis	Missouri	63116	Central	OFF-SU-10002573	Office Supplies	Supplies	Acme 10" Easy Grip Assistive Scissors	52.59	3	0	15.777
4543	CA-2014-113474	3/30/2016	3/31/2016	First Class	TM-21490	Tony Molinari	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-EN-10004206	Office Supplies	Envelopes	Multimedia Mailers	325.86	2	0	149.8956
8579	CA-2014-146164	12/22/2016	12/26/2016	Standard Class	CM-12190	Charlotte Melton	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-ST-10001228	Office Supplies	Storage	Personal File Boxes with Fold-Down Carry Handle	31.16	2	0	7.79
4003	CA-2013-145730	3/4/2015	3/9/2015	Standard Class	CC-12220	Chris Cortes	Consumer	United States	San Antonio	Texas	78207	Central	FUR-TA-10004915	Furniture	Tables	Office Impressions End Table, 20-1/2"H x 24"W x 20"D	637.896	3	0.3	-127.5792
6899	US-2012-165512	5/24/2014	5/26/2014	Second Class	VS-21820	Vivek Sundaresam	Consumer	United States	Naperville	Illinois	60540	Central	FUR-CH-10002880	Furniture	Chairs	Global High-Back Leather Tilter, Burgundy	602.651	7	0.3	-163.5767
8310	CA-2011-168312	3/1/2013	3/7/2013	Standard Class	GW-14605	Giulietta Weimer	Consumer	United States	Houston	Texas	77036	Central	OFF-ST-10003692	Office Supplies	Storage	Recycled Steel Personal File for Hanging File Folders	137.352	3	0.2	8.5845
6936	CA-2014-137365	11/30/2016	12/3/2016	Second Class	BP-11095	Bart Pistole	Corporate	United States	El Paso	Texas	79907	Central	TEC-AC-10001767	Technology	Accessories	SanDisk Ultra 64 GB MicroSDHC Class 10 Memory Card	95.976	3	0.2	-10.7973
9524	CA-2011-169446	12/19/2013	12/25/2013	Standard Class	SG-20605	Speros Goranitis	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10000419	Office Supplies	Storage	Rogers Jumbo File, Granite	32.592	3	0.2	-7.7406
6056	CA-2013-113551	8/19/2015	8/21/2015	First Class	NF-18385	Natalie Fritzler	Consumer	United States	Edinburg	Texas	78539	Central	OFF-BI-10001617	Office Supplies	Binders	GBC Wire Binding Combs	2.068	1	0.8	-3.4122
2815	CA-2012-135685	11/16/2014	11/18/2014	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Milwaukee	Wisconsin	53209	Central	FUR-TA-10000688	Furniture	Tables	Chromcraft Bull-Nose Wood Round Conference Table Top, Wood Base	653.55	3	0	111.1035
5362	CA-2014-100951	6/9/2016	6/10/2016	First Class	NC-18625	Noah Childs	Corporate	United States	Dallas	Texas	75217	Central	OFF-ST-10001496	Office Supplies	Storage	Standard Rollaway File with Lock	720.76	5	0.2	54.057
1694	US-2013-158708	6/27/2015	6/30/2015	Second Class	AB-10255	Alejandro Ballentine	Home Office	United States	Plano	Texas	75023	Central	TEC-AC-10003133	Technology	Accessories	Memorex Mini Travel Drive 4 GB USB 2.0 Flash Drive	13.616	2	0.2	3.5742
4285	CA-2012-105690	11/21/2014	11/26/2014	Second Class	CA-11965	Carol Adams	Corporate	United States	Port Arthur	Texas	77642	Central	FUR-BO-10003965	Furniture	Bookcases	O'Sullivan Manor Hill 2-Door Library in Brianna Oak	246.1328	2	0.32	-76.0116
7596	CA-2014-119655	4/20/2016	4/24/2016	Standard Class	CV-12295	Christina VanderZanden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-BI-10001036	Office Supplies	Binders	Cardinal EasyOpen D-Ring Binders	36.56	4	0	18.28
4359	CA-2014-162565	12/11/2016	12/11/2016	Same Day	RR-19315	Ralph Ritter	Consumer	United States	Aurora	Illinois	60505	Central	FUR-FU-10004306	Furniture	Furnishings	Electrix Halogen Magnifier Lamp	77.72	1	0.6	-66.062
7069	CA-2013-114209	5/22/2015	5/27/2015	Standard Class	AS-10285	Alejandro Savely	Corporate	United States	Dallas	Texas	75081	Central	OFF-PA-10003591	Office Supplies	Paper	Southworth 100% Cotton The Best Paper	82.656	9	0.2	30.996
9833	CA-2011-133963	5/18/2013	5/22/2013	Second Class	GA-14515	George Ashbrook	Consumer	United States	Dallas	Texas	75220	Central	OFF-PA-10001526	Office Supplies	Paper	Xerox 1949	3.984	1	0.2	1.4442
6388	CA-2011-134103	1/30/2013	2/4/2013	Standard Class	MV-18190	Mike Vittorini	Consumer	United States	Detroit	Michigan	48234	Central	OFF-PA-10001204	Office Supplies	Paper	Xerox 1972	10.56	2	0	4.752
5680	CA-2013-143924	7/29/2015	8/4/2015	Standard Class	SC-20680	Steve Carroll	Home Office	United States	Holland	Michigan	49423	Central	OFF-PA-10002120	Office Supplies	Paper	Xerox 1889	109.92	2	0	53.8608
4229	CA-2013-113803	3/25/2015	3/27/2015	First Class	VG-21805	Vivek Grady	Corporate	United States	Richmond	Indiana	47374	Central	OFF-PA-10001994	Office Supplies	Paper	Ink Jet Note and Greeting Cards, 8-1/2" x 5-1/2" Card Size	22.48	1	0	10.3408
9577	CA-2012-143147	5/26/2014	5/28/2014	Second Class	PS-18760	Pamela Stobb	Consumer	United States	San Antonio	Texas	78207	Central	TEC-MA-10004679	Technology	Machines	StarTech.com 10/100 VDSL2 Ethernet Extender Kit	399.54	2	0.4	-79.908
1348	CA-2011-118339	3/17/2013	3/24/2013	Standard Class	BN-11515	Bradley Nguyen	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-AR-10003829	Office Supplies	Art	Newell 35	19.68	6	0	5.7072
8916	US-2013-144057	5/10/2015	5/14/2015	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Austin	Texas	78745	Central	OFF-BI-10002852	Office Supplies	Binders	Ibico Standard Transparent Covers	13.184	4	0.8	-20.4352
1498	CA-2014-152485	9/4/2016	9/8/2016	Standard Class	JD-15790	John Dryer	Consumer	United States	Coppell	Texas	75019	Central	OFF-AR-10001940	Office Supplies	Art	Sanford Colorific Eraseable Coloring Pencils, 12 Count	13.12	5	0.2	3.772
5567	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	OFF-AR-10003338	Office Supplies	Art	Eberhard Faber 3 1/2" Golf Pencils	29.76	5	0.2	1.86
4959	CA-2012-127607	3/20/2014	3/26/2014	Standard Class	JK-15730	Joe Kamberova	Consumer	United States	Carrollton	Texas	75007	Central	OFF-FA-10003485	Office Supplies	Fasteners	Staples	18.864	9	0.2	6.1308
7590	CA-2012-139738	9/25/2014	9/29/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Rockford	Illinois	61107	Central	OFF-AR-10004602	Office Supplies	Art	Boston KS Multi-Size Manual Pencil Sharpener	128.744	7	0.2	12.8744
3592	CA-2011-154186	12/13/2013	12/15/2013	Second Class	RA-19285	Ralph Arnett	Consumer	United States	Houston	Texas	77070	Central	OFF-SU-10001574	Office Supplies	Supplies	Acme Value Line Scissors	2.92	1	0.2	0.365
3287	CA-2014-150525	2/21/2016	2/26/2016	Standard Class	JP-16135	Julie Prescott	Home Office	United States	Muskogee	Oklahoma	74403	Central	OFF-AP-10000595	Office Supplies	Appliances	Disposable Triple-Filter Dust Bags	13.11	3	0	3.4086
3894	US-2013-144547	11/11/2015	11/15/2015	Standard Class	MS-17770	Maxwell Schwartz	Consumer	United States	Houston	Texas	77036	Central	TEC-AC-10004901	Technology	Accessories	Kensington SlimBlade Notebook Wireless Mouse with Nano Receiver 	279.944	7	0.2	48.9902
7907	US-2012-118766	10/15/2014	10/22/2014	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75217	Central	OFF-BI-10002813	Office Supplies	Binders	Avery Reinforcements for Hole-Punch Pages	3.96	10	0.8	-6.93
8315	CA-2011-161508	7/12/2013	7/16/2013	Standard Class	PV-18985	Paul Van Hugh	Home Office	United States	League City	Texas	77573	Central	OFF-FA-10001561	Office Supplies	Fasteners	Stockwell Push Pins	3.488	2	0.2	0.5668
9165	CA-2012-164007	6/8/2014	6/12/2014	Standard Class	MG-17695	Maureen Gnade	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AP-10003849	Office Supplies	Appliances	Hoover Shoulder Vac Commercial Portable Vacuum	143.128	2	0.8	-393.602
5467	CA-2011-107706	2/14/2013	2/19/2013	Second Class	ST-20530	Shui Tom	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000466	Office Supplies	Paper	Memo Book, 100 Message Capacity, 5 3/8” x 11”	16.176	3	0.2	6.066
8976	CA-2014-156622	11/23/2016	11/26/2016	First Class	JP-15460	Jennifer Patt	Corporate	United States	Dallas	Texas	75220	Central	OFF-PA-10002923	Office Supplies	Paper	Xerox 1942	78.304	2	0.2	29.364
2526	CA-2012-124541	4/6/2014	4/10/2014	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	TEC-AC-10002550	Technology	Accessories	Maxell 4.7GB DVD-RW 3/Pack	25.488	2	0.2	4.4604
2093	CA-2011-145926	11/17/2013	11/21/2013	Standard Class	MP-17470	Mark Packer	Home Office	United States	Moorhead	Minnesota	56560	Central	FUR-CH-10004289	Furniture	Chairs	Global Super Steno Chair	479.9	5	0	81.583
2597	CA-2014-149048	5/13/2016	5/17/2016	Standard Class	BM-11650	Brian Moss	Corporate	United States	Columbus	Indiana	47201	Central	TEC-PH-10002310	Technology	Phones	Plantronics Calisto P620-M USB Wireless Speakerphone System	587.97	3	0	158.7519
2520	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-LA-10003223	Office Supplies	Labels	Avery 508	29.46	6	0	14.4354
8213	CA-2013-116337	11/8/2015	11/13/2015	Standard Class	MC-17845	Michael Chen	Consumer	United States	Dallas	Texas	75220	Central	OFF-ST-10001272	Office Supplies	Storage	Mini 13-1/2 Capacity Data Binder Rack, Pearl	314.088	3	0.2	19.6305
6985	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	OFF-AP-10002457	Office Supplies	Appliances	Eureka The Boss Plus 12-Amp Hard Box Upright Vacuum, Red	376.74	4	0.1	71.162
9591	CA-2011-119172	5/11/2013	5/15/2013	Standard Class	HD-14785	Harold Dahlen	Home Office	United States	Chicago	Illinois	60610	Central	OFF-BI-10002026	Office Supplies	Binders	Avery Arch Ring Binders	104.58	9	0.8	-172.557
2907	CA-2014-121615	11/3/2016	11/9/2016	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Eagan	Minnesota	55122	Central	OFF-PA-10000327	Office Supplies	Paper	Xerox 1971	8.56	2	0	3.852
9305	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	OFF-BI-10000320	Office Supplies	Binders	GBC Plastic Binding Combs	1.476	1	0.8	-2.2878
6685	US-2012-129637	12/17/2014	12/22/2014	Standard Class	MC-18100	Mick Crebagga	Consumer	United States	Bloomington	Illinois	61701	Central	OFF-ST-10003716	Office Supplies	Storage	Tennsco Double-Tier Lockers	180.016	1	0.2	-15.7514
2208	US-2011-103905	7/14/2013	7/20/2013	Standard Class	AW-10930	Arthur Wiediger	Home Office	United States	Aurora	Illinois	60505	Central	TEC-PH-10001552	Technology	Phones	I Need's 3d Hello Kitty Hybrid Silicone Case Cover for HTC One X 4g with 3d Hello Kitty Stylus Pen Green/pink	38.272	4	0.2	3.8272
3612	US-2013-131674	11/30/2015	12/2/2015	Second Class	NC-18535	Nick Crebassa	Corporate	United States	Dallas	Texas	75217	Central	TEC-AC-10004864	Technology	Accessories	Memorex Micro Travel Drive 32 GB	58.416	2	0.2	16.7946
2521	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-AP-10002651	Office Supplies	Appliances	Hoover Upright Vacuum With Dirt Cup	868.59	3	0	251.8911
9101	CA-2014-152933	10/12/2016	10/16/2016	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Dallas	Texas	75081	Central	TEC-AC-10003033	Technology	Accessories	Plantronics CS510 - Over-the-Head monaural Wireless Headset System	791.88	3	0.2	128.6805
9095	US-2012-132836	6/1/2014	6/5/2014	Standard Class	AJ-10945	Ashley Jarboe	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10004224	Office Supplies	Binders	Catalog Binders with Expanding Posts	403.68	6	0	181.656
3244	CA-2014-113355	12/1/2016	12/5/2016	Standard Class	SJ-20215	Sarah Jordon	Consumer	United States	Grand Prairie	Texas	75051	Central	TEC-PH-10004912	Technology	Phones	Cisco SPA112 2 Port Phone Adapter	219.8	5	0.2	24.7275
8980	CA-2012-150413	10/19/2014	10/24/2014	Second Class	CS-11860	Cari Schnelling	Consumer	United States	Dallas	Texas	75220	Central	OFF-BI-10000404	Office Supplies	Binders	Avery Printable Repositionable Plastic Tabs	1.72	1	0.8	-2.838
3333	CA-2014-122595	12/14/2016	12/20/2016	Standard Class	GM-14455	Gary Mitchum	Home Office	United States	Chicago	Illinois	60653	Central	TEC-PH-10003095	Technology	Phones	Samsung HM1900 Bluetooth Headset	52.68	3	0.2	19.755
5673	CA-2014-127922	10/27/2016	11/3/2016	Standard Class	SH-19975	Sally Hughsby	Corporate	United States	Dallas	Texas	75081	Central	OFF-EN-10003068	Office Supplies	Envelopes	#6 3/4 Gummed Flap White Envelopes	15.84	2	0.2	5.544
5720	CA-2014-126550	3/29/2016	4/2/2016	Second Class	RD-19720	Roger Demir	Consumer	United States	Lafayette	Indiana	47905	Central	OFF-ST-10001031	Office Supplies	Storage	Adjustable Personal File Tote	81.4	5	0	21.164
4256	CA-2014-163160	10/13/2016	10/16/2016	First Class	TS-21610	Troy Staebel	Consumer	United States	Freeport	Illinois	61032	Central	OFF-BI-10000778	Office Supplies	Binders	GBC VeloBinder Electric Binding Machine	96.784	4	0.8	-145.176
5551	US-2011-159618	11/12/2013	11/16/2013	Standard Class	DB-12970	Darren Budd	Corporate	United States	Houston	Texas	77036	Central	OFF-AR-10003183	Office Supplies	Art	Avery Fluorescent Highlighter Four-Color Set	2.672	1	0.2	0.334
726	CA-2014-144113	9/16/2016	9/20/2016	Standard Class	JF-15355	Jay Fein	Consumer	United States	Austin	Texas	78745	Central	OFF-EN-10001141	Office Supplies	Envelopes	Manila Recycled Extra-Heavyweight Clasp Envelopes, 6" x 9"	17.568	2	0.2	6.3684
1714	US-2014-124968	9/8/2016	9/13/2016	Second Class	MM-18055	Michelle Moray	Consumer	United States	Chicago	Illinois	60610	Central	FUR-TA-10004289	Furniture	Tables	BoxOffice By Design Rectangular and Half-Moon Meeting Room Tables	765.625	7	0.5	-566.5625
537	US-2014-122637	9/3/2016	9/8/2016	Second Class	EP-13915	Emily Phan	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10002429	Office Supplies	Binders	Premier Elliptical Ring Binder, Black	42.616	7	0.8	-68.1856
7388	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	FUR-FU-10003664	Furniture	Furnishings	Electrix Architect's Clamp-On Swing Arm Lamp, Black	1336.44	14	0	387.5676
6200	CA-2012-149909	11/13/2014	11/17/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Columbus	Indiana	47201	Central	OFF-PA-10001790	Office Supplies	Paper	Xerox 1910	96.08	2	0	46.1184
8930	US-2012-168704	4/13/2014	4/17/2014	Standard Class	FP-14320	Frank Preis	Consumer	United States	Huntsville	Texas	77340	Central	FUR-TA-10002530	Furniture	Tables	Iceberg OfficeWorks 42" Round Tables	211.372	2	0.3	-45.294
3924	CA-2014-146920	8/28/2016	9/1/2016	Standard Class	SC-20305	Sean Christensen	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10001461	Office Supplies	Paper	HP Office Paper (20Lb. and 87 Bright)	26.72	5	0.2	9.352
3717	CA-2014-144568	5/29/2016	6/2/2016	Standard Class	JO-15550	Jesus Ocampo	Home Office	United States	Omaha	Nebraska	68104	Central	OFF-FA-10004395	Office Supplies	Fasteners	Plymouth Boxed Rubber Bands by Plymouth	23.55	5	0	1.1775
1771	CA-2014-146024	3/2/2016	3/8/2016	Standard Class	SC-20770	Stewart Carmichael	Corporate	United States	Dallas	Texas	75081	Central	OFF-BI-10003291	Office Supplies	Binders	Wilson Jones Leather-Like Binders with DublLock Round Rings	12.222	7	0.8	-20.1663
8106	CA-2014-159149	2/18/2016	2/20/2016	First Class	CR-12820	Cyra Reiten	Home Office	United States	Houston	Texas	77041	Central	FUR-BO-10001601	Furniture	Bookcases	Sauder Mission Library with Doors, Fruitwood Finish	89.0664	1	0.32	-17.0274
6085	US-2013-132577	11/23/2015	11/28/2015	Standard Class	JE-15475	Jeremy Ellison	Consumer	United States	Houston	Texas	77095	Central	TEC-AC-10000387	Technology	Accessories	KeyTronic KT800P2 - Keyboard - Black	24.032	2	0.2	-0.6008
1463	CA-2013-152289	8/27/2015	8/29/2015	First Class	LC-16930	Linda Cazamias	Corporate	United States	Pasadena	Texas	77506	Central	TEC-AC-10004571	Technology	Accessories	Logitech G700s Rechargeable Gaming Mouse	159.984	2	0.2	43.9956
9313	CA-2014-148642	3/6/2016	3/12/2016	Standard Class	DW-13540	Don Weiss	Consumer	United States	Dallas	Texas	75220	Central	OFF-AR-10000588	Office Supplies	Art	Newell 345	63.488	4	0.2	4.7616
1970	CA-2014-117485	9/23/2016	9/29/2016	Standard Class	BD-11320	Bill Donatelli	Consumer	United States	Tulsa	Oklahoma	74133	Central	TEC-AC-10004659	Technology	Accessories	Imation Secure+ Hardware Encrypted USB 2.0 Flash Drive; 16GB	291.96	4	0	102.186
8677	CA-2014-163265	2/17/2016	2/22/2016	Standard Class	JS-16030	Joy Smith	Consumer	United States	Decatur	Illinois	62521	Central	FUR-FU-10004270	Furniture	Furnishings	Executive Impressions 13" Clairmont Wall Clock	7.692	1	0.6	-3.6537
914	CA-2014-102519	11/27/2016	11/29/2016	First Class	BM-11650	Brian Moss	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10004091	Furniture	Furnishings	Howard Miller 13" Diameter Goldtone Round Wall Clock	46.94	1	0	19.2454
2008	CA-2014-165386	8/3/2016	8/4/2016	First Class	CM-12190	Charlotte Melton	Consumer	United States	Chicago	Illinois	60623	Central	FUR-BO-10003034	Furniture	Bookcases	O'Sullivan Elevations Bookcase, Cherry Finish	183.372	2	0.3	-36.6744
1671	CA-2014-159457	10/19/2016	10/26/2016	Standard Class	RD-19480	Rick Duston	Consumer	United States	Houston	Texas	77095	Central	TEC-PH-10002185	Technology	Phones	QVS USB Car Charger 2-Port 2.1Amp for iPod/iPhone/iPad/iPad 2/iPad 3	16.68	3	0.2	5.2125
775	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	OFF-AR-10004648	Office Supplies	Art	Boston 19500 Mighty Mite Electric Pencil Sharpener	40.3	2	0	10.881
5309	CA-2014-131254	11/19/2016	11/21/2016	First Class	NC-18415	Nathan Cano	Consumer	United States	Houston	Texas	77095	Central	FUR-CH-10003774	Furniture	Chairs	Global Wood Trimmed Manager's Task Chair, Khaki	191.058	3	0.3	-46.3998
2608	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	TEC-AC-10001635	Technology	Accessories	KeyTronic KT400U2 - Keyboard - Black	24.672	3	0.2	0
4368	CA-2014-117044	9/11/2016	9/13/2016	Second Class	HA-14920	Helen Andreada	Consumer	United States	Chicago	Illinois	60623	Central	OFF-FA-10000936	Office Supplies	Fasteners	Acco Hot Clips Clips to Go	10.528	4	0.2	3.29
9140	CA-2011-106971	9/2/2013	9/8/2013	Standard Class	BM-11785	Bryan Mills	Consumer	United States	Buffalo Grove	Illinois	60089	Central	TEC-AC-10000844	Technology	Accessories	Logitech Gaming G510s - Keyboard	475.944	7	0.2	95.1888
2167	CA-2013-154018	10/14/2015	10/20/2015	Standard Class	HA-14920	Helen Andreada	Consumer	United States	Laredo	Texas	78041	Central	OFF-AR-10002067	Office Supplies	Art	Newell 334	15.872	1	0.2	1.1904
8383	CA-2013-163048	2/8/2015	2/15/2015	Standard Class	MH-17440	Mark Haberlin	Corporate	United States	Houston	Texas	77036	Central	FUR-CH-10001270	Furniture	Chairs	Harbour Creations Steel Folding Chair	241.5	4	0.3	0
8322	US-2013-149790	9/27/2015	10/2/2015	Standard Class	SC-20380	Shahid Collister	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10002026	Office Supplies	Binders	Ibico Recycled Linen-Style Covers	15.624	2	0.8	-24.9984
1350	CA-2011-118339	3/17/2013	3/24/2013	Standard Class	BN-11515	Bradley Nguyen	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-BI-10000136	Office Supplies	Binders	Avery Non-Stick Heavy Duty View Round Locking Ring Binders	35.88	6	0	17.2224
4047	CA-2014-100356	10/21/2016	10/25/2016	Standard Class	SP-20920	Susan Pistek	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AP-10002191	Office Supplies	Appliances	Belkin 8 Outlet SurgeMaster II Gold Surge Protector	23.992	2	0.8	-62.3792
2307	CA-2012-160794	8/6/2014	8/8/2014	First Class	MS-17980	Michael Stewart	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10004156	Office Supplies	Paper	Xerox 188	27.216	3	0.2	9.8658
4521	CA-2011-109491	2/20/2013	2/26/2013	Standard Class	LC-16930	Linda Cazamias	Corporate	United States	Richmond	Indiana	47374	Central	TEC-AC-10001284	Technology	Accessories	Enermax Briskie RF Wireless Keyboard and Mouse Combo	62.31	3	0	22.4316
839	US-2013-137547	3/8/2015	3/13/2015	Standard Class	EB-13705	Ed Braxton	Corporate	United States	Fort Worth	Texas	76106	Central	TEC-PH-10002365	Technology	Phones	Belkin Grip Candy Sheer Case / Cover for iPhone 5 and 5S	21.072	3	0.2	1.5804
3616	CA-2014-112529	11/19/2016	11/21/2016	First Class	SC-20770	Stewart Carmichael	Corporate	United States	San Antonio	Texas	78207	Central	OFF-AR-10001915	Office Supplies	Art	Peel-Off China Markers	31.776	4	0.2	8.7384
2968	CA-2011-162866	12/27/2013	12/31/2013	Standard Class	Co-12640	Corey-Lock	Consumer	United States	Skokie	Illinois	60076	Central	OFF-ST-10002562	Office Supplies	Storage	Staple magnet	30.016	4	0.2	3.0016
394	US-2011-134971	6/7/2013	6/10/2013	Second Class	BP-11095	Bart Pistole	Corporate	United States	Peoria	Illinois	61604	Central	OFF-BI-10003982	Office Supplies	Binders	Wilson Jones Century Plastic Molded Ring Binders	12.462	3	0.8	-20.5623
3394	CA-2011-105340	11/22/2013	11/25/2013	First Class	EH-14185	Evan Henry	Consumer	United States	Pasadena	Texas	77506	Central	OFF-BI-10001765	Office Supplies	Binders	Wilson Jones Heavy-Duty Casebound Ring Binders with Metal Hinges	6.928	1	0.8	-11.0848
7918	CA-2014-100783	9/4/2016	9/8/2016	Second Class	JK-16120	Julie Kriz	Home Office	United States	Garland	Texas	75043	Central	OFF-AR-10000380	Office Supplies	Art	Hunt PowerHouse Electric Pencil Sharpener, Blue	30.384	1	0.2	3.798
9918	CA-2014-160927	1/30/2016	2/1/2016	Second Class	TM-21010	Tamara Manning	Consumer	United States	Marion	Iowa	52302	Central	FUR-FU-10000010	Furniture	Furnishings	DAX Value U-Channel Document Frames, Easel Back	14.91	3	0	4.6221
398	CA-2012-122259	10/31/2014	11/4/2014	Standard Class	HP-14815	Harold Pawlan	Home Office	United States	Jackson	Michigan	49201	Central	OFF-SU-10002573	Office Supplies	Supplies	Acme 10" Easy Grip Assistive Scissors	70.12	4	0	21.036
6081	CA-2014-154676	8/5/2016	8/8/2016	First Class	NZ-18565	Nick Zandusky	Home Office	United States	Houston	Texas	77070	Central	OFF-ST-10001172	Office Supplies	Storage	Tennsco Lockers, Sand	151.056	9	0.2	7.5528
8262	CA-2013-118101	6/27/2015	6/27/2015	Same Day	SN-20560	Skye Norling	Home Office	United States	Roseville	Michigan	48066	Central	OFF-ST-10001837	Office Supplies	Storage	SAFCO Mobile Desk Side File, Wire Frame	171.04	4	0	44.4704
9832	CA-2011-113257	12/16/2013	12/18/2013	Second Class	SC-20305	Sean Christensen	Consumer	United States	Beaumont	Texas	77705	Central	FUR-FU-10001706	Furniture	Furnishings	Longer-Life Soft White Bulbs	8.624	7	0.6	-2.5872
6228	CA-2011-148782	11/2/2013	11/7/2013	Standard Class	PO-18850	Patrick O'Brill	Consumer	United States	Irving	Texas	75061	Central	TEC-PH-10002923	Technology	Phones	Logitech B530 USB Headset - headset - Full size, Binaural	88.776	3	0.2	7.7679
5853	CA-2012-121783	11/10/2014	11/14/2014	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Roseville	Minnesota	55113	Central	FUR-FU-10004351	Furniture	Furnishings	Staple-based wall hangings	29.22	3	0	12.8568
5265	CA-2011-105165	9/7/2013	9/10/2013	First Class	SZ-20035	Sam Zeldin	Home Office	United States	Houston	Texas	77036	Central	OFF-AR-10003179	Office Supplies	Art	Dixon Ticonderoga Core-Lock Colored Pencils	21.864	3	0.2	3.5529
757	CA-2011-106803	12/29/2013	1/2/2014	Standard Class	DC-13285	Debra Catini	Consumer	United States	Cottage Grove	Minnesota	55016	Central	OFF-ST-10002444	Office Supplies	Storage	Recycled Eldon Regeneration Jumbo File	24.56	2	0	6.8768
5953	US-2014-141698	4/15/2016	4/21/2016	Standard Class	SD-20485	Shirley Daniels	Home Office	United States	Houston	Texas	77041	Central	OFF-PA-10001826	Office Supplies	Paper	Xerox 207	20.736	4	0.2	7.2576
5476	CA-2014-169691	6/15/2016	6/18/2016	First Class	Dp-13240	Dean percer	Home Office	United States	Maple Grove	Minnesota	55369	Central	OFF-LA-10002312	Office Supplies	Labels	Avery 490	44.4	3	0	22.2
2522	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-PA-10003177	Office Supplies	Paper	Xerox 1999	12.96	2	0	6.2208
7399	CA-2011-124807	7/12/2013	7/15/2013	Second Class	ME-17725	Max Engle	Consumer	United States	Chicago	Illinois	60610	Central	OFF-PA-10001526	Office Supplies	Paper	Xerox 1949	35.856	9	0.2	12.9978
4747	CA-2014-168123	3/5/2016	3/5/2016	Same Day	JD-16060	Julia Dunbar	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-BI-10001097	Office Supplies	Binders	Avery Hole Reinforcements	18.69	3	0	9.1581
9098	US-2011-158365	4/12/2013	4/17/2013	Standard Class	SV-20785	Stewart Visinsky	Consumer	United States	Bloomington	Indiana	47401	Central	OFF-PA-10000289	Office Supplies	Paper	Xerox 213	32.4	5	0	15.552
2596	CA-2014-149048	5/13/2016	5/17/2016	Standard Class	BM-11650	Brian Moss	Corporate	United States	Columbus	Indiana	47201	Central	OFF-BI-10004632	Office Supplies	Binders	Ibico Hi-Tech Manual Binding System	914.97	3	0	411.7365
8718	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	FUR-FU-10001424	Furniture	Furnishings	Dax Clear Box Frame	6.984	2	0.6	-4.5396
2306	CA-2013-115574	12/24/2015	12/25/2015	First Class	BP-11185	Ben Peterman	Corporate	United States	Chicago	Illinois	60623	Central	FUR-BO-10003441	Furniture	Bookcases	Bush Westfield Collection Bookcases, Fully Assembled	141.372	2	0.3	-14.1372
4905	US-2011-161613	12/1/2013	12/3/2013	Second Class	MC-17605	Matt Connell	Corporate	United States	Houston	Texas	77070	Central	FUR-CH-10003746	Furniture	Chairs	Hon 4070 Series Pagoda Round Back Stacking Chairs	674.058	3	0.3	-19.2588
8076	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	OFF-AP-10004708	Office Supplies	Appliances	Fellowes Superior 10 Outlet Split Surge Protector	15.224	2	0.8	-38.8212
5487	CA-2012-156608	10/24/2014	10/29/2014	Standard Class	MT-18070	Michelle Tran	Home Office	United States	San Antonio	Texas	78207	Central	OFF-BI-10004140	Office Supplies	Binders	Avery Non-Stick Binders	3.592	4	0.8	-6.286
8868	CA-2011-120411	9/20/2013	9/23/2013	First Class	SB-20185	Sarah Brown	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10002185	Technology	Phones	QVS USB Car Charger 2-Port 2.1Amp for iPod/iPhone/iPad/iPad 2/iPad 3	11.12	2	0.2	3.475
4982	US-2013-131114	12/10/2015	12/14/2015	Second Class	RW-19630	Rob Williams	Corporate	United States	Chicago	Illinois	60610	Central	TEC-AC-10000199	Technology	Accessories	Kingston Digital DataTraveler 8GB USB 2.0	19.04	4	0.2	-1.428
1445	CA-2013-133725	5/24/2015	5/29/2015	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60623	Central	TEC-PH-10004165	Technology	Phones	Mitel MiVoice 5330e IP Phone	1979.928	9	0.2	148.4946
7142	CA-2014-128783	9/7/2016	9/7/2016	Same Day	TG-21640	Trudy Glocke	Consumer	United States	Saint Charles	Missouri	63301	Central	FUR-FU-10003623	Furniture	Furnishings	DataProducts Ampli Magnifier Task Lamp, Black,	135.3	5	0	37.884
9893	US-2013-115441	7/26/2015	7/29/2015	Second Class	SH-19975	Sally Hughsby	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-PH-10002262	Technology	Phones	LG Electronics Tone+ HBS-730 Bluetooth Headset	297.55	5	0	83.314
7351	CA-2014-142125	10/21/2016	10/27/2016	Standard Class	JB-15400	Jennifer Braxton	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-BI-10003460	Office Supplies	Binders	Acco 3-Hole Punch	21.9	5	0	10.512
5384	CA-2013-149195	9/6/2015	9/8/2015	Second Class	DM-13525	Don Miller	Corporate	United States	Houston	Texas	77070	Central	OFF-PA-10002036	Office Supplies	Paper	Xerox 1930	10.368	2	0.2	3.7584
8777	CA-2013-102813	7/3/2015	7/4/2015	First Class	EA-14035	Erin Ashbrook	Corporate	United States	Huntsville	Texas	77340	Central	FUR-CH-10000665	Furniture	Chairs	Global Airflow Leather Mesh Back Chair, Black	528.43	5	0.3	0
5050	US-2011-104759	3/31/2013	4/4/2013	Standard Class	DD-13570	Dorothy Dickinson	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10004901	Technology	Accessories	Kensington SlimBlade Notebook Wireless Mouse with Nano Receiver 	79.984	2	0.2	13.9972
9036	CA-2012-148873	10/1/2014	10/5/2014	Standard Class	EM-13960	Eric Murdock	Consumer	United States	Quincy	Illinois	62301	Central	TEC-AC-10003657	Technology	Accessories	Lenovo 17-Key USB Numeric Keypad	108.768	4	0.2	2.7192
247	CA-2011-131926	6/1/2013	6/6/2013	Second Class	DW-13480	Dianna Wilson	Home Office	United States	Lakeville	Minnesota	55044	Central	OFF-PA-10004082	Office Supplies	Paper	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	47.88	6	0	23.94
3720	CA-2013-105900	9/18/2015	9/24/2015	Standard Class	BS-11590	Brendan Sweed	Corporate	United States	Columbus	Indiana	47201	Central	OFF-AR-10002656	Office Supplies	Art	Sanford Liquid Accent Highlighters	33.4	5	0	12.358
2164	CA-2013-154018	10/14/2015	10/20/2015	Standard Class	HA-14920	Helen Andreada	Consumer	United States	Laredo	Texas	78041	Central	TEC-AC-10002402	Technology	Accessories	Razer Kraken PRO Over Ear PC and Music Headset	191.976	3	0.2	23.997
8705	CA-2013-111318	7/24/2015	7/27/2015	First Class	IL-15100	Ivan Liston	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10004100	Technology	Phones	Griffin GC17055 Auxiliary Audio Cable	115.136	8	0.2	11.5136
5849	CA-2012-121783	11/10/2014	11/14/2014	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Roseville	Minnesota	55113	Central	OFF-AP-10003849	Office Supplies	Appliances	Hoover Shoulder Vac Commercial Portable Vacuum	715.64	2	0	178.91
9126	CA-2013-128916	8/19/2015	8/21/2015	Second Class	MA-17560	Matt Abelman	Home Office	United States	Houston	Texas	77070	Central	FUR-FU-10000320	Furniture	Furnishings	OIC Stacking Trays	5.344	4	0.6	-2.1376
256	US-2012-159982	11/28/2014	12/4/2014	Standard Class	DR-12880	Dan Reichenbach	Corporate	United States	Chicago	Illinois	60623	Central	OFF-ST-10004804	Office Supplies	Storage	Belkin 19" Vented Equipment Shelf, Black	82.368	2	0.2	-19.5624
2501	CA-2014-131618	6/17/2016	6/20/2016	First Class	LS-17200	Luke Schmidt	Corporate	United States	Skokie	Illinois	60076	Central	OFF-PA-10001892	Office Supplies	Paper	Rediform Wirebound "Phone Memo" Message Book, 11 x 5-3/4	12.224	2	0.2	4.4312
6522	CA-2014-138289	1/17/2016	1/19/2016	Second Class	AR-10540	Andy Reiter	Consumer	United States	Jackson	Michigan	49201	Central	FUR-CH-10004626	Furniture	Chairs	Office Star Flex Back Scooter Chair with Aluminum Finish Frame	302.67	3	0	72.6408
2005	US-2014-143028	4/11/2016	4/18/2016	Standard Class	SC-20050	Sample Company A	Home Office	United States	Lubbock	Texas	79424	Central	OFF-BI-10004738	Office Supplies	Binders	Flexible Leather- Look Classic Collection Ring Binder	11.364	3	0.8	-17.046
4490	CA-2012-162621	9/5/2014	9/11/2014	Standard Class	CA-12055	Cathy Armstrong	Home Office	United States	Houston	Texas	77036	Central	OFF-BI-10003708	Office Supplies	Binders	Acco Four Pocket Poly Ring Binder with Label Holder, Smoke, 1"	4.47	3	0.8	-7.8225
7002	CA-2012-104871	3/30/2014	4/3/2014	Standard Class	DR-12940	Daniel Raglin	Home Office	United States	Normal	Illinois	61761	Central	FUR-CH-10003298	Furniture	Chairs	Office Star - Contemporary Task Swivel chair with Loop Arms, Charcoal	366.744	4	0.3	-110.0232
1081	CA-2012-110016	11/29/2014	12/4/2014	Standard Class	BT-11395	Bill Tyler	Corporate	United States	Detroit	Michigan	48227	Central	OFF-PA-10000349	Office Supplies	Paper	Easy-staple paper	19.92	4	0	9.3624
9697	CA-2011-144281	6/10/2013	6/15/2013	Second Class	HK-14890	Heather Kirkland	Corporate	United States	Detroit	Michigan	48234	Central	OFF-LA-10003930	Office Supplies	Labels	Dot Matrix Printer Tape Reel Labels, White, 5000/Box	491.55	5	0	240.8595
2623	CA-2011-164861	12/3/2013	12/6/2013	Second Class	MC-17635	Matthew Clasen	Corporate	United States	Saint Louis	Missouri	63116	Central	OFF-PA-10001972	Office Supplies	Paper	Xerox 214	25.92	4	0	12.4416
6521	CA-2014-138289	1/17/2016	1/19/2016	Second Class	AR-10540	Andy Reiter	Consumer	United States	Jackson	Michigan	49201	Central	OFF-BI-10004995	Office Supplies	Binders	GBC DocuBind P400 Electric Binding System	5443.96	4	0	2504.2216
8284	CA-2012-154284	12/21/2014	12/26/2014	Second Class	SZ-20035	Sam Zeldin	Home Office	United States	Saint Charles	Illinois	60174	Central	OFF-AR-10001468	Office Supplies	Art	Sanford Prismacolor Professional Thick Lead Art Pencils, 36-Color Set	59.904	2	0.2	14.2272
8252	CA-2012-140221	3/5/2014	3/9/2014	Second Class	MS-17365	Maribeth Schnelling	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AP-10000828	Office Supplies	Appliances	Avanti 4.4 Cu. Ft. Refrigerator	180.98	5	0.8	-470.548
8481	CA-2011-109890	7/21/2013	7/27/2013	Standard Class	PG-18820	Patrick Gardner	Consumer	United States	Omaha	Nebraska	68104	Central	TEC-PH-10004100	Technology	Phones	Griffin GC17055 Auxiliary Audio Cable	35.98	2	0	10.0744
50	CA-2012-115742	4/18/2014	4/22/2014	Standard Class	DP-13000	Darren Powers	Consumer	United States	New Albany	Indiana	47150	Central	OFF-BI-10004410	Office Supplies	Binders	C-Line Peel & Stick Add-On Filing Pockets, 8-3/4 x 5-1/8, 10/Pack	38.22	6	0	17.9634
7991	US-2013-117793	8/24/2015	8/30/2015	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Sheboygan	Wisconsin	53081	Central	TEC-AC-10003433	Technology	Accessories	Maxell 4.7GB DVD+R 5/Pack	1.98	2	0	0.891
9865	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	TEC-AC-10004469	Technology	Accessories	Microsoft Sculpt Comfort Mouse	159.8	4	0	70.312
4358	CA-2014-162565	12/11/2016	12/11/2016	Same Day	RR-19315	Ralph Ritter	Consumer	United States	Aurora	Illinois	60505	Central	OFF-PA-10001937	Office Supplies	Paper	Xerox 21	10.368	2	0.2	3.6288
5530	CA-2014-136609	8/6/2016	8/11/2016	Standard Class	TB-21355	Todd Boyes	Corporate	United States	Cedar Hill	Texas	75104	Central	OFF-PA-10004381	Office Supplies	Paper	14-7/8 x 11 Blue Bar Computer Printout Paper	115.296	3	0.2	40.3536
6087	US-2013-132577	11/23/2015	11/28/2015	Standard Class	JE-15475	Jeremy Ellison	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10003196	Office Supplies	Binders	Accohide Poly Flexible Ring Binders	4.488	6	0.8	-6.732
6952	CA-2012-161767	11/20/2014	11/24/2014	Standard Class	GK-14620	Grace Kelly	Corporate	United States	Dallas	Texas	75217	Central	TEC-MA-10002790	Technology	Machines	NeatDesk Desktop Scanner & Digital Filing System	479.988	2	0.4	55.9986
6202	CA-2012-146675	4/16/2014	4/20/2014	Standard Class	SB-20185	Sarah Brown	Consumer	United States	Evanston	Illinois	60201	Central	TEC-AC-10004396	Technology	Accessories	Logitech Keyboard K120	43.56	3	0.2	-4.9005
1104	US-2014-145863	4/21/2016	4/27/2016	Standard Class	RP-19390	Resi Pölking	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10002049	Office Supplies	Binders	UniKeep View Case Binders	2.934	3	0.8	-4.9878
6651	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	OFF-FA-10004854	Office Supplies	Fasteners	Vinyl Coated Wire Paper Clips in Organizer Box, 800/Box	45.92	5	0.2	15.498
4159	CA-2011-126907	11/1/2013	11/8/2013	Standard Class	SM-20950	Suzanne McNair	Corporate	United States	Chicago	Illinois	60610	Central	OFF-PA-10000533	Office Supplies	Paper	Southworth Parchment Paper & Envelopes	15.696	3	0.2	5.1012
2748	US-2012-165449	11/22/2014	11/26/2014	Standard Class	AP-10720	Anne Pryor	Home Office	United States	Frisco	Texas	75034	Central	TEC-AC-10004127	Technology	Accessories	SanDisk Cruzer 8 GB USB Flash Drive	27.168	4	0.2	-1.3584
4522	CA-2011-109491	2/20/2013	2/26/2013	Standard Class	LC-16930	Linda Cazamias	Corporate	United States	Richmond	Indiana	47374	Central	FUR-FU-10000221	Furniture	Furnishings	Master Caster Door Stop, Brown	20.32	4	0	6.9088
8378	CA-2012-162964	11/12/2014	11/18/2014	Standard Class	MF-18250	Monica Federle	Corporate	United States	Houston	Texas	77095	Central	OFF-ST-10002344	Office Supplies	Storage	Carina 42"Hx23 3/4"W Media Storage Unit	64.784	1	0.2	-14.5764
4286	CA-2012-105690	11/21/2014	11/26/2014	Second Class	CA-11965	Carol Adams	Corporate	United States	Port Arthur	Texas	77642	Central	OFF-LA-10000240	Office Supplies	Labels	Self-Adhesive Address Labels for Typewriters by Universal	11.696	2	0.2	3.9474
2904	CA-2013-153577	6/28/2015	7/2/2015	Standard Class	KH-16330	Katharine Harms	Corporate	United States	Highland Park	Illinois	60035	Central	OFF-PA-10000575	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4 x 5 White Forms per Page	37.464	7	0.2	12.1758
3520	CA-2012-124975	6/22/2014	6/25/2014	First Class	MG-17875	Michael Grace	Home Office	United States	Aurora	Illinois	60505	Central	FUR-TA-10002645	Furniture	Tables	Hon Rectangular Conference Tables	796.425	7	0.5	-525.6405
1045	CA-2014-115651	7/9/2016	7/12/2016	First Class	NS-18640	Noel Staavos	Corporate	United States	Chicago	Illinois	60610	Central	OFF-AP-10000055	Office Supplies	Appliances	Belkin F9S820V06 8 Outlet Surge	58.464	9	0.8	-146.16
8925	CA-2013-168032	1/30/2015	2/3/2015	Standard Class	DF-13135	David Flashing	Consumer	United States	Rockford	Illinois	61107	Central	TEC-PH-10004241	Technology	Phones	Nokia Lumia 1020	1439.968	4	0.2	143.9968
6086	US-2013-132577	11/23/2015	11/28/2015	Standard Class	JE-15475	Jeremy Ellison	Consumer	United States	Houston	Texas	77095	Central	OFF-LA-10000262	Office Supplies	Labels	Avery 494	2.088	1	0.2	0.6786
9864	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	OFF-PA-10004156	Office Supplies	Paper	Xerox 188	11.34	1	0	5.5566
9545	CA-2012-135251	8/6/2014	8/10/2014	Standard Class	RP-19270	Rachel Payne	Corporate	United States	Houston	Texas	77095	Central	FUR-BO-10003965	Furniture	Bookcases	O'Sullivan Manor Hill 2-Door Library in Brianna Oak	369.1992	3	0.32	-114.0174
3898	CA-2014-134285	12/7/2016	12/12/2016	Standard Class	DS-13180	David Smith	Corporate	United States	San Antonio	Texas	78207	Central	OFF-PA-10000304	Office Supplies	Paper	Xerox 1995	15.552	3	0.2	5.4432
3135	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	OFF-BI-10000666	Office Supplies	Binders	Surelock Post Binders	30.56	5	0.8	-45.84
6304	CA-2014-162712	6/18/2016	6/20/2016	Second Class	NK-18490	Neil Knudson	Home Office	United States	Corpus Christi	Texas	78415	Central	OFF-PA-10000167	Office Supplies	Paper	Xerox 1925	74.352	3	0.2	23.235
4673	CA-2013-133550	8/1/2015	8/7/2015	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Detroit	Michigan	48205	Central	TEC-PH-10004042	Technology	Phones	ClearOne Communications CHAT 70 OC Speaker Phone	635.96	4	0	165.3496
5282	CA-2012-105158	9/5/2014	9/10/2014	Standard Class	SP-20860	Sung Pak	Corporate	United States	Rochester	Minnesota	55901	Central	FUR-FU-10001706	Furniture	Furnishings	Longer-Life Soft White Bulbs	6.16	2	0	2.9568
8372	CA-2011-165393	12/27/2013	12/30/2013	First Class	NC-18415	Nathan Cano	Consumer	United States	Fort Worth	Texas	76106	Central	OFF-BI-10001658	Office Supplies	Binders	GBC Standard Therm-A-Bind Covers	4.984	1	0.8	-8.4728
7614	US-2012-130491	2/8/2014	2/11/2014	First Class	BH-11710	Brosina Hoffman	Consumer	United States	Garden City	Kansas	67846	Central	OFF-AR-10001149	Office Supplies	Art	Sanford Colorific Colored Pencils, 12/Box	5.76	2	0	1.728
9831	CA-2011-113257	12/16/2013	12/18/2013	Second Class	SC-20305	Sean Christensen	Consumer	United States	Beaumont	Texas	77705	Central	TEC-AC-10004171	Technology	Accessories	Razer Kraken 7.1 Surround Sound Over Ear USB Gaming Headset	319.968	4	0.2	95.9904
2976	CA-2012-137512	5/7/2014	5/12/2014	Standard Class	AG-10675	Anna Gayman	Consumer	United States	Allen	Texas	75002	Central	OFF-PA-10000213	Office Supplies	Paper	Xerox 198	15.936	4	0.2	5.3784
2284	CA-2012-153108	3/5/2014	3/9/2014	Standard Class	SF-20200	Sarah Foster	Consumer	United States	New Castle	Indiana	47362	Central	TEC-PH-10001552	Technology	Phones	I Need's 3d Hello Kitty Hybrid Silicone Case Cover for HTC One X 4g with 3d Hello Kitty Stylus Pen Green/pink	23.92	2	0	6.6976
1334	CA-2011-122567	2/16/2013	2/21/2013	Standard Class	MN-17935	Michael Nguyen	Consumer	United States	Dallas	Texas	75220	Central	OFF-AP-10001303	Office Supplies	Appliances	Holmes Cool Mist Humidifier for the Whole House with 8-Gallon Output per Day, Extended Life Filter	7.96	2	0.8	-13.93
1199	CA-2013-130946	4/9/2015	4/13/2015	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77041	Central	FUR-CH-10004540	Furniture	Chairs	Global Chrome Stack Chair	95.984	4	0.3	-4.1136
8680	CA-2013-112739	9/3/2015	9/8/2015	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Houston	Texas	77070	Central	TEC-AC-10001714	Technology	Accessories	Logitech MX Performance Wireless Mouse	159.56	5	0.2	33.9065
3766	CA-2013-163153	3/22/2015	3/26/2015	Standard Class	DM-12955	Dario Medina	Corporate	United States	Houston	Texas	77036	Central	FUR-TA-10004767	Furniture	Tables	Safco Drafting Table	99.372	2	0.3	-1.4196
7322	CA-2014-167626	9/3/2016	9/7/2016	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Chicago	Illinois	60623	Central	OFF-PA-10003424	Office Supplies	Paper	"While you Were Out" Message Book, One Form per Page	8.904	3	0.2	3.339
5454	US-2014-108700	5/19/2016	5/23/2016	Standard Class	PJ-18835	Patrick Jones	Corporate	United States	Rockford	Illinois	61107	Central	OFF-PA-10004733	Office Supplies	Paper	Things To Do Today Spiral Book	38.016	6	0.2	13.7808
2806	CA-2012-122623	9/7/2014	9/11/2014	Standard Class	CC-12145	Charles Crestani	Consumer	United States	El Paso	Texas	79907	Central	FUR-CH-10000553	Furniture	Chairs	Metal Folding Chairs, Beige, 4/Carton	47.516	2	0.3	-2.0364
8962	CA-2014-150266	11/25/2016	11/30/2016	Standard Class	RO-19780	Rose O'Brian	Consumer	United States	Houston	Texas	77070	Central	OFF-AR-10001761	Office Supplies	Art	Avery Hi-Liter Smear-Safe Highlighters	18.688	4	0.2	3.7376
7733	CA-2014-143294	6/2/2016	6/8/2016	Standard Class	JD-15790	John Dryer	Consumer	United States	Houston	Texas	77070	Central	OFF-PA-10000743	Office Supplies	Paper	Xerox 1977	10.688	2	0.2	3.7408
4083	US-2014-151316	6/24/2016	6/30/2016	Standard Class	MC-17635	Matthew Clasen	Corporate	United States	Decatur	Illinois	62521	Central	OFF-BI-10004632	Office Supplies	Binders	Ibico Hi-Tech Manual Binding System	182.994	3	0.8	-320.2395
148	CA-2013-114489	12/6/2015	12/10/2015	Standard Class	JE-16165	Justin Ellison	Corporate	United States	Franklin	Wisconsin	53132	Central	TEC-PH-10000215	Technology	Phones	Plantronics Cordless Phone Headset with In-line Volume - M214C	384.45	11	0	103.8015
3232	US-2014-156356	4/16/2016	4/22/2016	Standard Class	ND-18370	Natalie DeCherney	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10000632	Office Supplies	Binders	Satellite Sectional Post Binders	26.046	3	0.8	-44.2782
5069	CA-2011-124478	8/8/2013	8/12/2013	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Trenton	Michigan	48183	Central	TEC-CO-10001571	Technology	Copiers	Sharp 1540cs Digital Laser Copier	549.99	1	0	274.995
3552	CA-2013-152555	3/30/2015	4/3/2015	Second Class	ME-17320	Maria Etezadi	Home Office	United States	Chicago	Illinois	60653	Central	FUR-CH-10002965	Furniture	Chairs	Global Leather Highback Executive Chair with Pneumatic Height Adjustment, Black	844.116	6	0.3	-36.1764
7453	CA-2014-105669	9/17/2016	9/22/2016	Second Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Houston	Texas	77036	Central	TEC-PH-10002415	Technology	Phones	Polycom VoiceStation 500 Conference phone	1415.76	6	0.2	88.485
1174	US-2012-104430	10/22/2014	10/26/2014	Standard Class	LT-17110	Liz Thompson	Consumer	United States	Bloomington	Illinois	61701	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	5.176	4	0.8	-7.764
2975	CA-2012-137512	5/7/2014	5/12/2014	Standard Class	AG-10675	Anna Gayman	Consumer	United States	Allen	Texas	75002	Central	FUR-TA-10001095	Furniture	Tables	Chromcraft Round Conference Tables	244.006	2	0.3	-31.3722
227	CA-2012-163055	8/9/2014	8/16/2014	Standard Class	DS-13180	David Smith	Corporate	United States	Detroit	Michigan	48227	Central	FUR-TA-10003748	Furniture	Tables	Bevis 36 x 72 Conference Tables	622.45	5	0	136.939
3790	US-2013-133508	4/18/2015	4/22/2015	Standard Class	SW-20350	Sean Wendt	Home Office	United States	Omaha	Nebraska	68104	Central	OFF-FA-10000134	Office Supplies	Fasteners	Advantus Push Pins, Aluminum Head	29.05	5	0	9.0055
8985	CA-2013-110898	3/7/2015	3/13/2015	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60623	Central	FUR-TA-10000849	Furniture	Tables	Bevis Rectangular Conference Tables	145.98	2	0.5	-99.2664
2314	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	OFF-LA-10004093	Office Supplies	Labels	Avery 486	14.62	2	0	6.8714
5414	CA-2013-153157	9/12/2015	9/15/2015	First Class	TB-21625	Trudy Brown	Consumer	United States	Wichita	Kansas	67212	Central	TEC-PH-10003171	Technology	Phones	Plantronics Encore H101 Dual Earpieces Headset	224.75	5	0	62.93
624	CA-2012-138009	11/29/2014	12/3/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Dearborn	Michigan	48126	Central	OFF-AP-10000179	Office Supplies	Appliances	Honeywell Enviracaire Portable HEPA Air Cleaner for up to 10 x 16 Room	555.21	5	0.1	178.901
4745	CA-2014-168123	3/5/2016	3/5/2016	Same Day	JD-16060	Julia Dunbar	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-ST-10000877	Office Supplies	Storage	Recycled Steel Personal File for Standard File Folders	221.16	4	0	57.5016
6558	CA-2011-137092	10/20/2013	10/22/2013	Second Class	LS-16975	Lindsay Shagiari	Home Office	United States	Chicago	Illinois	60653	Central	OFF-LA-10003510	Office Supplies	Labels	Avery 4027 File Folder Labels for Dot Matrix Printers, 5000 Labels per Box, White	24.424	1	0.2	7.9378
662	CA-2012-146563	8/24/2014	8/28/2014	Standard Class	CB-12025	Cassandra Brandow	Consumer	United States	Arlington	Texas	76017	Central	FUR-TA-10001768	Furniture	Tables	Hon Racetrack Conference Tables	918.785	5	0.3	-118.1295
1464	CA-2013-152289	8/27/2015	8/29/2015	First Class	LC-16930	Linda Cazamias	Corporate	United States	Pasadena	Texas	77506	Central	FUR-CH-10002126	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs	1024.716	6	0.3	-29.2776
668	CA-2014-132682	6/8/2016	6/10/2016	Second Class	TH-21235	Tiffany House	Corporate	United States	Dallas	Texas	75081	Central	TEC-PH-10004042	Technology	Phones	ClearOne Communications CHAT 70 OC Speaker Phone	381.576	3	0.2	28.6182
4394	CA-2013-108868	9/9/2015	9/13/2015	Standard Class	KB-16585	Ken Black	Corporate	United States	Dallas	Texas	75081	Central	TEC-PH-10000923	Technology	Phones	Belkin SportFit Armband For iPhone 5s/5c, Fuchsia	59.96	5	0.2	21.7355
4029	CA-2014-139311	8/11/2016	8/13/2016	First Class	SF-20965	Sylvia Foulston	Corporate	United States	Bedford	Texas	76021	Central	OFF-BI-10004209	Office Supplies	Binders	Fellowes Twister Kit, Gray/Clear, 3/pkg	12.864	8	0.8	-22.512
1109	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-FA-10003495	Office Supplies	Fasteners	Staples	58.368	12	0.2	21.888
9073	CA-2013-142524	9/5/2015	9/9/2015	Standard Class	MB-18085	Mick Brown	Consumer	United States	Springfield	Missouri	65807	Central	OFF-EN-10003286	Office Supplies	Envelopes	Staple envelope	16.56	2	0	7.7832
8457	US-2014-118556	5/28/2016	6/2/2016	Second Class	TH-21235	Tiffany House	Corporate	United States	Chicago	Illinois	60653	Central	FUR-CH-10001146	Furniture	Chairs	Global Task Chair, Black	106.869	3	0.3	-29.0073
580	CA-2014-118640	7/20/2016	7/26/2016	Standard Class	CS-11950	Carlos Soltero	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10001475	Furniture	Furnishings	Contract Clock, 14", Brown	8.792	1	0.6	-5.7148
9601	CA-2014-107797	5/8/2016	5/11/2016	Second Class	EB-13705	Ed Braxton	Corporate	United States	Mansfield	Texas	76063	Central	OFF-PA-10003848	Office Supplies	Paper	Xerox 1997	41.472	8	0.2	14.5152
8721	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	FUR-CH-10000229	Furniture	Chairs	Global Enterprise Series Seating High-Back Swivel/Tilt Chairs	379.372	2	0.3	-119.2312
4952	CA-2012-144190	6/9/2014	6/13/2014	Standard Class	NC-18415	Nathan Cano	Consumer	United States	Royal Oak	Michigan	48073	Central	OFF-PA-10000304	Office Supplies	Paper	Xerox 1995	12.96	2	0	6.2208
264	US-2011-106992	9/19/2013	9/21/2013	Second Class	SB-20290	Sean Braxton	Corporate	United States	Houston	Texas	77036	Central	TEC-MA-10003353	Technology	Machines	Xerox WorkCentre 6505DN Laser Multifunction Printer	2519.958	7	0.4	-251.9958
4150	CA-2014-106068	10/23/2016	10/28/2016	Standard Class	RB-19330	Randy Bradley	Consumer	United States	Austin	Texas	78745	Central	TEC-AC-10002942	Technology	Accessories	WD My Passport Ultra 1TB Portable External Hard Drive	55.2	1	0.2	-2.07
1264	CA-2013-155992	10/2/2015	10/3/2015	First Class	CC-12220	Chris Cortes	Consumer	United States	La Porte	Indiana	46350	Central	TEC-PH-10000215	Technology	Phones	Plantronics Cordless Phone Headset with In-line Volume - M214C	69.9	2	0	18.873
7981	CA-2011-103800	1/3/2013	1/7/2013	Standard Class	DP-13000	Darren Powers	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000174	Office Supplies	Paper	Message Book, Wirebound, Four 5 1/2" X 4" Forms/Pg., 200 Dupl. Sets/Book	16.448	2	0.2	5.5512
9261	CA-2014-167976	11/11/2016	11/14/2016	Second Class	JL-15505	Jeremy Lonsdale	Consumer	United States	Aberdeen	South Dakota	57401	Central	OFF-SU-10004661	Office Supplies	Supplies	Acme Titanium Bonded Scissors	25.5	3	0	6.63
512	CA-2014-135307	11/26/2016	11/27/2016	First Class	LS-17245	Lynn Smith	Consumer	United States	Gladstone	Missouri	64118	Central	TEC-AC-10002399	Technology	Accessories	SanDisk Cruzer 32 GB USB Flash Drive	38.04	2	0	12.1728
8433	US-2011-127635	9/14/2013	9/18/2013	Second Class	SC-20260	Scott Cohen	Corporate	United States	Corpus Christi	Texas	78415	Central	OFF-FA-10000053	Office Supplies	Fasteners	Revere Boxed Rubber Bands by Revere	6.048	4	0.2	-1.3608
2348	CA-2013-159373	3/14/2015	3/19/2015	Standard Class	LT-17110	Liz Thompson	Consumer	United States	San Antonio	Texas	78207	Central	FUR-TA-10004619	Furniture	Tables	Hon Non-Folding Utility Tables	557.585	5	0.3	0
6554	CA-2011-137092	10/20/2013	10/22/2013	Second Class	LS-16975	Lindsay Shagiari	Home Office	United States	Chicago	Illinois	60653	Central	TEC-AC-10001606	Technology	Accessories	Logitech Wireless Performance Mouse MX for PC and Mac	319.968	4	0.2	71.9928
1785	CA-2014-166317	9/22/2016	9/26/2016	Standard Class	JE-15610	Jim Epp	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	98.16	6	0	9.816
7445	CA-2014-127474	2/4/2016	2/8/2016	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10001166	Office Supplies	Paper	Xerox 2	5.184	1	0.2	1.8144
678	US-2014-119438	3/18/2016	3/23/2016	Standard Class	CD-11980	Carol Darley	Consumer	United States	Tyler	Texas	75701	Central	TEC-AC-10003614	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 10/Pack	27.816	3	0.2	4.5201
8455	CA-2013-125087	4/19/2015	4/24/2015	Standard Class	TH-21115	Thea Hudgings	Corporate	United States	Houston	Texas	77070	Central	FUR-FU-10004748	Furniture	Furnishings	Howard Miller 16" Diameter Gallery Wall Clock	127.88	5	0.6	-67.137
1276	CA-2013-119186	5/27/2015	5/27/2015	Same Day	MS-17710	Maurice Satty	Consumer	United States	Fort Worth	Texas	76106	Central	OFF-PA-10004040	Office Supplies	Paper	Universal Premium White Copier/Laser Paper (20Lb. and 87 Bright)	14.352	3	0.2	5.2026
988	CA-2012-146829	3/10/2014	3/10/2014	Same Day	TS-21340	Toby Swindell	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10004022	Office Supplies	Binders	Acco Suede Grain Vinyl Round Ring Binder	1.112	2	0.8	-1.8904
2974	CA-2014-111808	12/16/2016	12/20/2016	Standard Class	AR-10510	Andrew Roberts	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10004656	Office Supplies	Binders	Peel & Stick Add-On Corner Pockets	10.8	5	0	5.184
8458	US-2014-118556	5/28/2016	6/2/2016	Second Class	TH-21235	Tiffany House	Corporate	United States	Chicago	Illinois	60653	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	3.564	3	0.8	-6.237
1357	US-2011-160444	7/5/2013	7/5/2013	Same Day	DC-12850	Dan Campbell	Consumer	United States	Houston	Texas	77036	Central	OFF-ST-10000563	Office Supplies	Storage	Fellowes Bankers Box Stor/Drawer Steel Plus	281.424	11	0.2	-35.178
9008	CA-2014-107825	11/18/2016	11/18/2016	Same Day	NB-18655	Nona Balk	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-LA-10003720	Office Supplies	Labels	Avery 487	7.38	2	0	3.4686
7254	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-AP-10002684	Office Supplies	Appliances	Acco 7-Outlet Masterpiece Power Center, Wihtout Fax/Phone Line Protection	364.74	3	0	109.422
8022	CA-2011-129189	7/21/2013	7/25/2013	Standard Class	HM-14860	Harry Marie	Corporate	United States	Dallas	Texas	75217	Central	OFF-AP-10000124	Office Supplies	Appliances	Acco 6 Outlet Guardian Basic Surge Suppressor	4.992	3	0.8	-12.9792
257	US-2012-159982	11/28/2014	12/4/2014	Standard Class	DR-12880	Dan Reichenbach	Corporate	United States	Chicago	Illinois	60623	Central	OFF-ST-10001590	Office Supplies	Storage	Tenex Personal Project File with Scoop Front Design, Black	53.92	5	0.2	4.044
5175	CA-2014-106432	10/19/2016	10/24/2016	Standard Class	CA-12265	Christina Anderson	Consumer	United States	Waco	Texas	76706	Central	OFF-BI-10002799	Office Supplies	Binders	SlimView Poly Binder, 3/8"	2.072	2	0.8	-3.5224
5620	US-2013-124163	9/26/2015	10/1/2015	Standard Class	SC-20695	Steve Chapman	Corporate	United States	La Crosse	Wisconsin	54601	Central	TEC-AC-10001908	Technology	Accessories	Logitech Wireless Headset h800	499.95	5	0	174.9825
3306	CA-2011-104738	12/30/2013	1/1/2014	Second Class	SP-20620	Stefania Perrino	Corporate	United States	Laredo	Texas	78041	Central	TEC-PH-10002468	Technology	Phones	Plantronics CS 50-USB - headset - Convertible, Monaural	217.584	2	0.2	19.0386
8453	CA-2013-125087	4/19/2015	4/24/2015	Standard Class	TH-21115	Thea Hudgings	Corporate	United States	Houston	Texas	77070	Central	FUR-CH-10002880	Furniture	Chairs	Global High-Back Leather Tilter, Burgundy	344.372	4	0.3	-93.4724
9749	US-2011-140914	11/11/2013	11/15/2013	Standard Class	BH-11710	Brosina Hoffman	Consumer	United States	Chicago	Illinois	60653	Central	FUR-CH-10003379	Furniture	Chairs	Global Commerce Series High-Back Swivel/Tilt Chairs	797.944	4	0.3	-56.996
1160	CA-2014-147039	6/29/2016	7/4/2016	Standard Class	AA-10315	Alex Avila	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-AP-10000576	Office Supplies	Appliances	Belkin 325VA UPS Surge Protector, 6'	362.94	3	0	90.735
661	CA-2012-146563	8/24/2014	8/28/2014	Standard Class	CB-12025	Cassandra Brandow	Consumer	United States	Arlington	Texas	76017	Central	OFF-ST-10001511	Office Supplies	Storage	Space Solutions Commercial Steel Shelving	724.08	14	0.2	-135.765
3899	CA-2014-102267	11/30/2016	12/4/2016	Standard Class	SC-20800	Stuart Calhoun	Consumer	United States	Edinburg	Texas	78539	Central	OFF-FA-10000611	Office Supplies	Fasteners	Binder Clips by OIC	2.368	2	0.2	0.8288
5858	CA-2012-112214	8/5/2014	8/11/2014	Standard Class	AH-10690	Anna Häberlin	Corporate	United States	Dallas	Texas	75220	Central	FUR-FU-10002364	Furniture	Furnishings	Eldon Expressions Wood Desk Accessories, Oak	14.76	5	0.6	-11.439
8867	CA-2011-120411	9/20/2013	9/23/2013	First Class	SB-20185	Sarah Brown	Consumer	United States	Chicago	Illinois	60653	Central	FUR-BO-10004218	Furniture	Bookcases	Bush Heritage Pine Collection 5-Shelf Bookcase, Albany Pine Finish, *Special Order	493.43	5	0.3	-70.49
9891	US-2013-115441	7/26/2015	7/29/2015	Second Class	SH-19975	Sally Hughsby	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-PA-10004996	Office Supplies	Paper	Speediset Carbonless Redi-Letter 7" x 8 1/2"	20.62	2	0	9.6914
8820	CA-2012-142930	11/28/2014	12/2/2014	Standard Class	EB-14170	Evan Bailliet	Consumer	United States	Austin	Texas	78745	Central	OFF-PA-10003395	Office Supplies	Paper	Xerox 1941	335.52	4	0.2	117.432
175	US-2011-100853	9/14/2013	9/19/2013	Standard Class	JB-15400	Jennifer Braxton	Corporate	United States	Chicago	Illinois	60623	Central	OFF-AP-10000891	Office Supplies	Appliances	Kensington 7 Outlet MasterPiece HOMEOFFICE Power Control Center	52.448	2	0.8	-131.12
903	CA-2014-132353	9/15/2016	9/17/2016	First Class	DB-13060	Dave Brooks	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10004536	Technology	Phones	Avaya 5420 Digital phone	323.976	3	0.2	20.2485
7984	CA-2014-152499	1/23/2016	1/26/2016	Second Class	EH-13765	Edward Hooks	Corporate	United States	Chicago	Illinois	60623	Central	OFF-FA-10002975	Office Supplies	Fasteners	Staples	15.12	5	0.2	4.914
7185	CA-2014-133102	8/17/2016	8/24/2016	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77095	Central	OFF-SU-10000432	Office Supplies	Supplies	Acco Side-Punched Conventional Columnar Pads	5.552	2	0.2	-1.041
6534	US-2014-107384	12/4/2016	12/8/2016	Standard Class	TP-21130	Theone Pippenger	Consumer	United States	Rochester	Minnesota	55901	Central	TEC-AC-10001539	Technology	Accessories	Logitech G430 Surround Sound Gaming Headset with Dolby 7.1 Technology	399.95	5	0	143.982
8966	CA-2014-106691	11/6/2016	11/12/2016	Standard Class	CC-12370	Christopher Conant	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10000145	Office Supplies	Binders	Zipper Ring Binder Pockets	1.248	2	0.8	-1.9344
8558	CA-2013-132829	12/24/2015	12/27/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Houston	Texas	77041	Central	TEC-PH-10004539	Technology	Phones	Wireless Extenders zBoost YX545 SOHO Signal Booster	453.576	3	0.2	39.6879
5099	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10002485	Office Supplies	Storage	Rogers Deluxe File Chest	35.168	2	0.2	-8.3524
898	CA-2011-144407	9/9/2013	9/15/2013	Standard Class	MS-17365	Maribeth Schnelling	Consumer	United States	Detroit	Michigan	48227	Central	OFF-LA-10003923	Office Supplies	Labels	Alphabetical Labels for Top Tab Filing	103.6	7	0	51.8
2228	CA-2014-130771	7/29/2016	8/3/2016	Standard Class	LA-16780	Laura Armstrong	Corporate	United States	Austin	Texas	78745	Central	TEC-PH-10002496	Technology	Phones	Cisco SPA301	124.792	1	0.2	15.599
2334	CA-2014-169285	3/21/2016	3/25/2016	Standard Class	RW-19690	Robert Waldorf	Consumer	United States	Lafayette	Indiana	47905	Central	OFF-PA-10004971	Office Supplies	Paper	Xerox 196	5.78	1	0	2.8322
9107	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	TEC-MA-10001016	Technology	Machines	Canon PC170 Desktop Personal Copier	287.91	3	0.4	33.5895
5329	CA-2012-120320	3/5/2014	3/9/2014	Standard Class	MV-18190	Mike Vittorini	Consumer	United States	Houston	Texas	77036	Central	TEC-PH-10000149	Technology	Phones	Cisco SPA525G2 IP Phone - Wireless	31.92	2	0.2	2.394
8431	US-2011-113124	3/30/2013	4/5/2013	Standard Class	NC-18340	Nat Carroll	Consumer	United States	Apple Valley	Minnesota	55124	Central	OFF-ST-10001511	Office Supplies	Storage	Space Solutions Commercial Steel Shelving	129.3	2	0	6.465
1601	CA-2014-158876	11/19/2016	11/21/2016	Second Class	AB-10150	Aimee Bixby	Consumer	United States	Carrollton	Texas	75007	Central	FUR-FU-10001967	Furniture	Furnishings	Telescoping Adjustable Floor Lamp	15.992	2	0.6	-13.993
5094	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AP-10004036	Office Supplies	Appliances	Bionaire 99.97% HEPA Air Cleaner	14.016	4	0.8	-31.536
9480	CA-2011-126193	9/7/2013	9/14/2013	Standard Class	SS-20410	Shahid Shariari	Consumer	United States	Oswego	Illinois	60543	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	3.828	3	0.8	-6.5076
2643	CA-2013-124051	12/30/2015	12/31/2015	First Class	KA-16525	Kelly Andreada	Consumer	United States	Aurora	Illinois	60505	Central	OFF-PA-10001289	Office Supplies	Paper	White Computer Printout Paper by Universal	186.048	6	0.2	67.4424
3553	CA-2013-152555	3/30/2015	4/3/2015	Second Class	ME-17320	Maria Etezadi	Home Office	United States	Chicago	Illinois	60653	Central	TEC-PH-10001254	Technology	Phones	Jabra BIZ 2300 Duo QD Duo Corded Headset	812.736	8	0.2	60.9552
5635	CA-2012-134943	12/5/2014	12/6/2014	First Class	SU-20665	Stephanie Ulpright	Home Office	United States	Ann Arbor	Michigan	48104	Central	OFF-BI-10000666	Office Supplies	Binders	Surelock Post Binders	152.8	5	0	76.4
554	CA-2014-101945	11/24/2016	11/28/2016	Standard Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77070	Central	OFF-FA-10004248	Office Supplies	Fasteners	Advantus T-Pin Paper Clips	10.824	3	0.2	2.5707
3765	CA-2014-125878	2/26/2016	3/2/2016	Standard Class	MH-18025	Michelle Huthwaite	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10002609	Office Supplies	Binders	Avery Hidden Tab Dividers for Binding Systems	1.788	3	0.8	-3.0396
4783	CA-2011-159310	11/7/2013	11/12/2013	Standard Class	SC-20725	Steven Cartwright	Consumer	United States	Houston	Texas	77070	Central	OFF-SU-10004115	Office Supplies	Supplies	Acme Stainless Steel Office Snips	40.712	7	0.2	3.5623
4555	CA-2013-101448	2/27/2015	3/2/2015	Second Class	EB-13930	Eric Barreto	Consumer	United States	La Crosse	Wisconsin	54601	Central	OFF-BI-10004738	Office Supplies	Binders	Flexible Leather- Look Classic Collection Ring Binder	56.82	3	0	28.41
5291	CA-2011-146283	9/8/2013	9/15/2013	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Houston	Texas	77036	Central	FUR-CH-10004287	Furniture	Chairs	SAFCO Arco Folding Chair	966.7	5	0.3	-13.81
7793	CA-2014-169362	10/12/2016	10/15/2016	First Class	SP-20860	Sung Pak	Corporate	United States	Dallas	Texas	75217	Central	TEC-AC-10001383	Technology	Accessories	Logitech Wireless Touch Keyboard K400	39.984	2	0.2	-1.4994
3830	CA-2014-141733	5/7/2016	5/11/2016	Standard Class	RW-19540	Rick Wilson	Corporate	United States	Detroit	Michigan	48234	Central	FUR-CH-10000595	Furniture	Chairs	Safco Contoured Stacking Chairs	476.8	2	0	119.2
5200	CA-2013-103982	3/4/2015	3/9/2015	Standard Class	AA-10315	Alex Avila	Consumer	United States	Round Rock	Texas	78664	Central	OFF-FA-10001332	Office Supplies	Fasteners	Acco Banker's Clasps, 5 3/4"-Long	2.304	1	0.2	0.7776
9846	CA-2011-163867	6/3/2013	6/6/2013	First Class	RE-19450	Richard Eichhorn	Consumer	United States	Decatur	Illinois	62521	Central	OFF-ST-10000877	Office Supplies	Storage	Recycled Steel Personal File for Standard File Folders	132.696	3	0.2	9.9522
441	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	FUR-FU-10000246	Furniture	Furnishings	Aluminum Document Frame	12.22	1	0	3.666
6302	US-2011-161305	6/6/2013	6/12/2013	Standard Class	SB-20170	Sarah Bern	Consumer	United States	Chicago	Illinois	60623	Central	OFF-EN-10000461	Office Supplies	Envelopes	#10- 4 1/8" x 9 1/2" Recycled Envelopes	13.984	2	0.2	4.7196
99	CA-2013-149223	9/7/2015	9/12/2015	Standard Class	ER-13855	Elpida Rittenbach	Corporate	United States	Saint Paul	Minnesota	55106	Central	OFF-AP-10000358	Office Supplies	Appliances	Fellowes Basic Home/Office Series Surge Protectors	77.88	6	0	22.5852
920	CA-2013-165218	3/6/2015	3/12/2015	Standard Class	RW-19630	Rob Williams	Corporate	United States	Dallas	Texas	75220	Central	OFF-ST-10001558	Office Supplies	Storage	Acco Perma 4000 Stacking Storage Drawers	12.992	1	0.2	-0.812
1877	CA-2014-112039	3/25/2016	3/29/2016	Standard Class	JC-15775	John Castell	Consumer	United States	San Antonio	Texas	78207	Central	TEC-PH-10000984	Technology	Phones	Panasonic KX-TG9471B	470.376	3	0.2	47.0376
6548	CA-2011-113880	3/1/2013	3/5/2013	Standard Class	VF-21715	Vicky Freymann	Home Office	United States	Elmhurst	Illinois	60126	Central	FUR-CH-10000863	Furniture	Chairs	Novimex Swivel Fabric Task Chair	634.116	6	0.3	-172.1172
8830	CA-2011-109680	10/6/2013	10/9/2013	First Class	VP-21760	Victoria Pisteka	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-ST-10001932	Office Supplies	Storage	Fellowes Staxonsteel Drawer Files	386.34	2	0	54.0876
7450	CA-2014-105669	9/17/2016	9/22/2016	Second Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Houston	Texas	77036	Central	OFF-AR-10000390	Office Supplies	Art	Newell Chalk Holder	9.912	3	0.2	3.2214
6990	CA-2014-165099	12/11/2016	12/13/2016	First Class	DK-13375	Dennis Kane	Consumer	United States	Abilene	Texas	79605	Central	OFF-AP-10001634	Office Supplies	Appliances	Hoover Commercial Lightweight Upright Vacuum	1.392	2	0.8	-3.7584
9476	CA-2012-100818	5/31/2014	6/5/2014	Second Class	JM-15265	Janet Molinari	Corporate	United States	Chicago	Illinois	60653	Central	OFF-PA-10001125	Office Supplies	Paper	Xerox 1988	173.488	7	0.2	54.215
9100	CA-2014-152933	10/12/2016	10/16/2016	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Dallas	Texas	75081	Central	OFF-PA-10001934	Office Supplies	Paper	Xerox 1993	10.368	2	0.2	3.7584
1821	CA-2013-168956	2/16/2015	2/20/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Chicago	Illinois	60623	Central	OFF-AP-10004233	Office Supplies	Appliances	Honeywell Enviracaire Portable Air Cleaner for up to 8 x 10 Room	92.064	6	0.8	-225.5568
7631	CA-2011-162089	3/30/2013	4/1/2013	First Class	MP-17470	Mark Packer	Home Office	United States	Brownsville	Texas	78521	Central	TEC-PH-10001819	Technology	Phones	Innergie mMini Combo Duo USB Travel Charging Kit	251.944	7	0.2	88.1804
4560	CA-2011-110219	5/5/2013	5/8/2013	First Class	EB-13870	Emily Burns	Consumer	United States	San Antonio	Texas	78207	Central	FUR-CH-10001146	Furniture	Chairs	Global Value Mid-Back Manager's Chair, Gray	127.869	3	0.3	-9.1335
9481	CA-2011-126193	9/7/2013	9/14/2013	Standard Class	SS-20410	Shahid Shariari	Consumer	United States	Oswego	Illinois	60543	Central	OFF-BI-10004632	Office Supplies	Binders	Ibico Hi-Tech Manual Binding System	304.99	5	0.8	-533.7325
6052	CA-2012-153878	4/25/2014	4/30/2014	Standard Class	TS-21655	Trudy Schmidt	Consumer	United States	Milwaukee	Wisconsin	53209	Central	OFF-AP-10001205	Office Supplies	Appliances	Belkin 5 Outlet SurgeMaster Power Centers	272.4	5	0	76.272
3243	CA-2014-114524	3/31/2016	4/5/2016	Second Class	EG-13900	Emily Grady	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10002799	Office Supplies	Binders	SlimView Poly Binder, 3/8"	13.468	13	0.8	-22.8956
1198	CA-2013-130946	4/9/2015	4/13/2015	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77041	Central	TEC-AC-10001990	Technology	Accessories	Kensington Orbit Wireless Mobile Trackball for PC and Mac	431.928	9	0.2	64.7892
2574	CA-2014-145128	7/9/2016	7/14/2016	Standard Class	SM-20320	Sean Miller	Home Office	United States	Lafayette	Indiana	47905	Central	FUR-FU-10000293	Furniture	Furnishings	Eldon Antistatic Chair Mats for Low to Medium Pile Carpets	526.45	5	0	31.587
6686	US-2012-129637	12/17/2014	12/22/2014	Standard Class	MC-18100	Mick Crebagga	Consumer	United States	Bloomington	Illinois	61701	Central	FUR-FU-10000965	Furniture	Furnishings	Howard Miller 11-1/2" Diameter Ridgewood Wall Clock	41.552	2	0.6	-19.7372
1758	US-2012-107349	7/13/2014	7/15/2014	First Class	SL-20155	Sara Luxemburg	Home Office	United States	Houston	Texas	77095	Central	OFF-BI-10001765	Office Supplies	Binders	Wilson Jones Heavy-Duty Casebound Ring Binders with Metal Hinges	41.568	6	0.8	-66.5088
8782	CA-2012-133585	3/1/2014	3/4/2014	First Class	CM-12715	Craig Molinari	Corporate	United States	Houston	Texas	77070	Central	FUR-BO-10001811	Furniture	Bookcases	Atlantic Metals Mobile 5-Shelf Bookcases, Custom Colors	1227.9984	6	0.32	-36.1176
3652	CA-2014-109960	12/9/2016	12/11/2016	Second Class	DB-13210	Dean Braden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-AR-10001860	Office Supplies	Art	BIC Liqua Brite Liner	34.7	5	0	12.492
5893	CA-2013-146157	11/22/2015	11/27/2015	Standard Class	RD-19720	Roger Demir	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10003657	Technology	Accessories	Lenovo 17-Key USB Numeric Keypad	81.576	3	0.2	2.0394
2523	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	TEC-PH-10003442	Technology	Phones	Samsung Replacement EH64AVFWE Premium Headset	5.5	1	0	1.375
7683	CA-2012-120782	4/28/2014	5/1/2014	First Class	SD-20485	Shirley Daniels	Home Office	United States	Midland	Michigan	48640	Central	OFF-AP-10003779	Office Supplies	Appliances	Kensington 7 Outlet MasterPiece Power Center with Fax/Phone Line Protection	186.732	1	0.1	41.496
1129	CA-2012-105970	3/2/2014	3/7/2014	Standard Class	PA-19060	Pete Armstrong	Home Office	United States	Richmond	Indiana	47374	Central	OFF-EN-10001532	Office Supplies	Envelopes	Brown Kraft Recycled Envelopes	101.88	6	0	50.94
380	CA-2012-130792	4/28/2014	5/5/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Houston	Texas	77095	Central	OFF-ST-10003327	Office Supplies	Storage	Akro-Mils 12-Gallon Tote	23.832	3	0.2	2.6811
9379	CA-2013-117625	5/11/2015	5/16/2015	Standard Class	GM-14500	Gene McClure	Consumer	United States	Chicago	Illinois	60610	Central	OFF-EN-10001535	Office Supplies	Envelopes	Grip Seal Envelopes	7.072	2	0.2	2.3868
5283	CA-2012-105158	9/5/2014	9/10/2014	Standard Class	SP-20860	Sung Pak	Corporate	United States	Rochester	Minnesota	55901	Central	OFF-PA-10001970	Office Supplies	Paper	Xerox 1881	36.84	3	0	17.3148
6412	CA-2014-161774	5/14/2016	5/15/2016	First Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10003134	Office Supplies	Paper	Xerox 1937	76.864	2	0.2	26.9024
9719	CA-2013-108210	5/31/2015	6/1/2015	Same Day	AT-10735	Annie Thurman	Consumer	United States	Houston	Texas	77041	Central	TEC-AC-10000109	Technology	Accessories	Sony Micro Vault Click 16 GB USB 2.0 Flash Drive	223.96	5	0.2	11.198
5169	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	OFF-ST-10004950	Office Supplies	Storage	Acco Perma 3000 Stacking Storage Drawers	62.94	3	0	11.9586
171	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	TEC-PH-10003931	Technology	Phones	JBL Micro Wireless Portable Bluetooth Speaker	143.976	3	0.2	8.9985
9530	CA-2014-101637	3/24/2016	3/25/2016	Same Day	AC-10615	Ann Chong	Corporate	United States	Beaumont	Texas	77705	Central	OFF-ST-10002352	Office Supplies	Storage	Iris Project Case	12.768	2	0.2	0.9576
1616	CA-2012-130022	8/10/2014	8/16/2014	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Eagan	Minnesota	55122	Central	OFF-LA-10002787	Office Supplies	Labels	Avery 480	3.75	1	0	1.8
6410	CA-2014-161774	5/14/2016	5/15/2016	First Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10000300	Office Supplies	Paper	Xerox 1936	47.952	3	0.2	16.1838
985	CA-2014-100314	9/29/2016	10/5/2016	Standard Class	AS-10630	Ann Steele	Home Office	United States	Pasadena	Texas	77506	Central	OFF-LA-10001569	Office Supplies	Labels	Avery 499	7.968	2	0.2	2.5896
4444	US-2013-111290	7/23/2015	7/27/2015	Standard Class	DK-13375	Dennis Kane	Consumer	United States	Westland	Michigan	48185	Central	OFF-PA-10002262	Office Supplies	Paper	Xerox 192	32.4	5	0	15.552
4114	CA-2012-116687	5/2/2014	5/7/2014	Standard Class	NC-18625	Noah Childs	Corporate	United States	Houston	Texas	77095	Central	OFF-LA-10000443	Office Supplies	Labels	Avery 501	8.856	3	0.2	2.9889
5064	CA-2012-136798	5/8/2014	5/12/2014	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Minneapolis	Minnesota	55407	Central	FUR-FU-10000723	Furniture	Furnishings	Deflect-o EconoMat Studded, No Bevel Mat for Low Pile Carpeting	123.96	3	0	11.1564
9040	CA-2013-117121	12/18/2015	12/22/2015	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Detroit	Michigan	48205	Central	OFF-BI-10000545	Office Supplies	Binders	GBC Ibimaster 500 Manual ProClick Binding System	9892.74	13	0	4946.37
7913	CA-2013-167605	4/29/2015	5/1/2015	Second Class	RB-19570	Rob Beeghly	Consumer	United States	Saint Charles	Illinois	60174	Central	FUR-FU-10001602	Furniture	Furnishings	Eldon Delta Triangular Chair Mat, 52" x 58", Clear	30.344	2	0.6	-31.8612
1961	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	TEC-AC-10003023	Technology	Accessories	Logitech G105 Gaming Keyboard	296.85	5	0	53.433
3583	CA-2012-121650	12/10/2014	12/16/2014	Standard Class	KD-16495	Keith Dawkins	Corporate	United States	Jackson	Michigan	49201	Central	OFF-AR-10001149	Office Supplies	Art	Avery Hi-Liter Comfort Grip Fluorescent Highlighter, Yellow Ink	3.9	2	0	1.521
3546	CA-2014-121216	12/23/2016	12/25/2016	Second Class	MM-17920	Michael Moore	Consumer	United States	College Station	Texas	77840	Central	OFF-AP-10001947	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	29.312	8	0.8	-74.7456
7660	CA-2014-146493	6/1/2016	6/5/2016	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Fremont	Nebraska	68025	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	53.9	5	0	25.872
5371	US-2014-136721	4/8/2016	4/12/2016	Standard Class	NH-18610	Nicole Hansen	Corporate	United States	Oak Park	Michigan	48237	Central	FUR-FU-10004665	Furniture	Furnishings	3M Polarizing Task Lamp with Clamp Arm, Light Gray	273.96	2	0	71.2296
4774	CA-2014-119746	11/23/2016	11/27/2016	Standard Class	CM-12385	Christopher Martinez	Consumer	United States	Chicago	Illinois	60610	Central	OFF-LA-10001613	Office Supplies	Labels	Avery File Folder Labels	11.52	5	0.2	4.176
1447	CA-2014-102337	6/13/2016	6/16/2016	First Class	SD-20485	Shirley Daniels	Home Office	United States	Chicago	Illinois	60653	Central	FUR-CH-10004289	Furniture	Chairs	Global Super Steno Chair	470.302	7	0.3	-87.3418
2496	CA-2011-136644	6/16/2013	6/22/2013	Standard Class	SC-20575	Sonia Cooley	Consumer	United States	Mishawaka	Indiana	46544	Central	FUR-CH-10000225	Furniture	Chairs	Global Geo Office Task Chair, Gray	647.84	8	0	32.392
7381	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-LA-10004559	Office Supplies	Labels	Avery 49	14.4	5	0	7.056
4754	US-2012-167220	12/12/2014	12/16/2014	Standard Class	JB-15925	Joni Blumstein	Consumer	United States	Austin	Texas	78745	Central	TEC-AC-10002018	Technology	Accessories	AmazonBasics 3-Button USB Wired Mouse	22.368	4	0.2	6.4308
7260	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-PA-10004888	Office Supplies	Paper	Xerox 217	45.36	7	0	21.7728
5555	US-2011-159618	11/12/2013	11/16/2013	Standard Class	DB-12970	Darren Budd	Corporate	United States	Houston	Texas	77036	Central	FUR-BO-10004467	Furniture	Bookcases	Bestar Classic Bookcase	67.9932	1	0.32	-12.9987
3525	CA-2013-132731	11/25/2015	11/29/2015	Standard Class	GA-14515	George Ashbrook	Consumer	United States	Dallas	Texas	75081	Central	TEC-PH-10004120	Technology	Phones	AT&T 1080 Phone	657.552	6	0.2	49.3164
2434	US-2014-112613	5/28/2016	6/1/2016	Standard Class	JH-15910	Jonathan Howell	Consumer	United States	Houston	Texas	77070	Central	TEC-PH-10001536	Technology	Phones	Spigen Samsung Galaxy S5 Case Wallet	54.368	4	0.2	4.0776
8999	CA-2014-122763	3/20/2016	3/20/2016	Same Day	HG-14845	Harry Greene	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10002377	Office Supplies	Paper	Xerox 1916	274.064	7	0.2	102.774
6833	CA-2012-112522	10/10/2014	10/17/2014	Standard Class	DP-13165	David Philippe	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AR-10003183	Office Supplies	Art	Avery Fluorescent Highlighter Four-Color Set	8.016	3	0.2	1.002
8829	CA-2012-115168	6/5/2014	6/9/2014	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Saint Charles	Missouri	63301	Central	OFF-PA-10000528	Office Supplies	Paper	Xerox 1981	10.56	2	0	4.752
8981	CA-2011-108182	2/6/2013	2/10/2013	Second Class	DL-13315	Delfina Latchford	Consumer	United States	Romeoville	Illinois	60441	Central	OFF-BI-10001196	Office Supplies	Binders	Avery Flip-Chart Easel Binder, Black	8.952	2	0.8	-14.7708
7452	CA-2014-105669	9/17/2016	9/22/2016	Second Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Houston	Texas	77036	Central	OFF-BI-10002412	Office Supplies	Binders	Wilson Jones “Snap” Scratch Pad Binder Tool for Ring Binders	5.8	5	0.8	-10.15
8567	CA-2013-134110	11/18/2015	11/19/2015	First Class	BG-11035	Barry Gonzalez	Consumer	United States	The Colony	Texas	75056	Central	OFF-PA-10000697	Office Supplies	Paper	TOPS Voice Message Log Book, Flash Format	15.232	4	0.2	5.5216
2772	CA-2013-163986	9/4/2015	9/11/2015	Standard Class	JJ-15445	Jennifer Jackson	Consumer	United States	Waukesha	Wisconsin	53186	Central	OFF-ST-10000918	Office Supplies	Storage	Crate-A-Files	54.5	5	0	14.17
9012	CA-2012-137071	12/20/2014	12/21/2014	First Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77036	Central	TEC-AC-10004353	Technology	Accessories	Hypercom P1300 Pinpad	100.8	2	0.2	21.42
3108	CA-2013-121671	7/18/2015	7/23/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Springfield	Missouri	65807	Central	OFF-PA-10001471	Office Supplies	Paper	Strathmore Photo Frame Cards	21.93	3	0	10.0878
1439	CA-2012-139731	10/15/2014	10/15/2014	Same Day	JE-15745	Joel Eaton	Consumer	United States	Amarillo	Texas	79109	Central	FUR-CH-10002024	Furniture	Chairs	HON 5400 Series Task Chairs for Big and Tall	2453.43	5	0.3	-350.49
5071	CA-2011-124478	8/8/2013	8/12/2013	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Trenton	Michigan	48183	Central	OFF-EN-10002500	Office Supplies	Envelopes	Globe Weis Peel & Seel First Class Envelopes	38.34	3	0	17.253
4113	CA-2012-153717	12/25/2014	1/1/2015	Standard Class	DL-13495	Dionis Lloyd	Corporate	United States	Detroit	Michigan	48227	Central	OFF-AR-10002375	Office Supplies	Art	Newell 351	3.28	1	0	0.9512
9894	US-2013-115441	7/26/2015	7/29/2015	Second Class	SH-19975	Sally Hughsby	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10004626	Furniture	Chairs	Office Star Flex Back Scooter Chair with Aluminum Finish Frame	403.56	4	0	96.8544
9896	CA-2011-115049	9/26/2013	10/1/2013	Standard Class	MM-17920	Michael Moore	Consumer	United States	Chicago	Illinois	60623	Central	TEC-AC-10004859	Technology	Accessories	Maxell Pro 80 Minute CD-R, 10/Pack	153.824	11	0.2	38.456
6084	US-2013-132577	11/23/2015	11/28/2015	Standard Class	JE-15475	Jeremy Ellison	Consumer	United States	Houston	Texas	77095	Central	OFF-AR-10003481	Office Supplies	Art	Newell 348	23.616	9	0.2	2.6568
1108	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	10.78	5	0.8	-17.248
1959	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-BI-10003669	Office Supplies	Binders	3M Organizer Strips	16.2	3	0	7.776
3725	CA-2014-127264	4/3/2016	4/5/2016	First Class	SA-20830	Sue Ann Reed	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AR-10003045	Office Supplies	Art	Prang Colored Pencils	7.056	3	0.2	2.205
7724	CA-2012-139374	9/10/2014	9/14/2014	Standard Class	AR-10345	Alex Russell	Corporate	United States	Austin	Texas	78745	Central	FUR-CH-10003981	Furniture	Chairs	Global Commerce Series Low-Back Swivel/Tilt Chairs	179.886	1	0.3	-2.5698
3709	CA-2011-120544	11/23/2013	11/27/2013	Standard Class	SS-20140	Saphhira Shifley	Corporate	United States	Mesquite	Texas	75150	Central	OFF-AP-10004336	Office Supplies	Appliances	Conquest 14 Commercial Heavy-Duty Upright Vacuum, Collection System, Accessory Kit	34.176	3	0.8	-87.1488
7261	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	TEC-PH-10000441	Technology	Phones	VTech DS6151	125.99	1	0	35.2772
5263	CA-2011-105165	9/7/2013	9/10/2013	First Class	SZ-20035	Sam Zeldin	Home Office	United States	Houston	Texas	77036	Central	FUR-TA-10004154	Furniture	Tables	Riverside Furniture Oval Coffee Table, Oval End Table, End Table with Drawer	200.795	1	0.3	-22.948
3856	US-2014-105389	10/23/2016	10/28/2016	Second Class	DM-13015	Darrin Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	3.564	3	0.8	-6.237
4257	CA-2014-163160	10/13/2016	10/16/2016	First Class	TS-21610	Troy Staebel	Consumer	United States	Freeport	Illinois	61032	Central	FUR-FU-10001424	Furniture	Furnishings	Dax Clear Box Frame	10.476	3	0.6	-6.8094
5190	US-2014-136679	11/14/2016	11/18/2016	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Pasadena	Texas	77506	Central	TEC-AC-10004855	Technology	Accessories	V7 USB Numeric Keypad	167.952	6	0.2	-27.2922
2316	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	OFF-BI-10000404	Office Supplies	Binders	Avery Printable Repositionable Plastic Tabs	43	5	0	20.21
1759	CA-2011-139017	5/11/2013	5/17/2013	Standard Class	RM-19375	Raymond Messe	Consumer	United States	Houston	Texas	77095	Central	TEC-AC-10001013	Technology	Accessories	Logitech ClearChat Comfort/USB Headset H390	46.864	2	0.2	7.6154
4443	US-2013-111290	7/23/2015	7/27/2015	Standard Class	DK-13375	Dennis Kane	Consumer	United States	Westland	Michigan	48185	Central	OFF-AR-10001761	Office Supplies	Art	Avery Hi-Liter Smear-Safe Highlighters	29.2	5	0	10.512
8584	CA-2011-130673	5/20/2013	5/22/2013	Second Class	MC-17590	Matt Collister	Corporate	United States	San Marcos	Texas	78666	Central	OFF-ST-10000636	Office Supplies	Storage	Rogers Profile Extra Capacity Storage Tub	66.96	5	0.2	-13.392
3275	CA-2014-116358	11/2/2016	11/6/2016	Standard Class	KM-16225	Kalyca Meade	Corporate	United States	Overland Park	Kansas	66212	Central	OFF-FA-10003495	Office Supplies	Fasteners	Staples	18.24	3	0	9.12
8129	CA-2014-157350	8/26/2016	9/1/2016	Standard Class	DP-13000	Darren Powers	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10000222	Furniture	Furnishings	Seth Thomas 16" Steel Case Clock	64.96	5	0.6	-43.848
5343	US-2011-168501	11/21/2013	11/27/2013	Standard Class	JK-15325	Jason Klamczynski	Corporate	United States	Dallas	Texas	75220	Central	OFF-EN-10001509	Office Supplies	Envelopes	Poly String Tie Envelopes	1.632	1	0.2	0.5508
1722	US-2012-123218	12/20/2014	12/25/2014	Standard Class	KD-16345	Katherine Ducich	Consumer	United States	Chicago	Illinois	60623	Central	TEC-PH-10001061	Technology	Phones	Apple iPhone 5C	159.984	2	0.2	11.9988
4290	US-2012-117184	5/17/2014	5/21/2014	Standard Class	ON-18715	Odella Nelson	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10002250	Office Supplies	Paper	Things To Do Today Pad	14.088	3	0.2	4.9308
677	US-2014-119438	3/18/2016	3/23/2016	Standard Class	CD-11980	Carol Darley	Consumer	United States	Tyler	Texas	75701	Central	OFF-AP-10000804	Office Supplies	Appliances	Hoover Portapower Portable Vacuum	2.688	3	0.8	-7.392
1793	CA-2011-120474	12/1/2013	12/3/2013	First Class	RP-19390	Resi Pölking	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-AR-10000475	Office Supplies	Art	Hunt BOSTON Vista Battery-Operated Pencil Sharpener, Black	46.64	4	0	12.5928
6714	CA-2014-107629	12/14/2016	12/14/2016	Same Day	DB-13060	Dave Brooks	Consumer	United States	Skokie	Illinois	60076	Central	FUR-FU-10004091	Furniture	Furnishings	Howard Miller 13" Diameter Goldtone Round Wall Clock	56.328	3	0.6	-26.7558
9072	CA-2012-136105	6/12/2014	6/16/2014	Standard Class	SZ-20035	Sam Zeldin	Home Office	United States	Columbus	Indiana	47201	Central	OFF-ST-10002444	Office Supplies	Storage	Recycled Eldon Regeneration Jumbo File	24.56	2	0	6.8768
2189	CA-2014-143063	8/10/2016	8/15/2016	Standard Class	IL-15100	Ivan Liston	Consumer	United States	Columbus	Indiana	47201	Central	FUR-FU-10003708	Furniture	Furnishings	Tenex Traditional Chairmats for Medium Pile Carpet, Standard Lip, 36" x 48"	121.3	2	0	25.473
9718	CA-2013-108210	5/31/2015	6/1/2015	Same Day	AT-10735	Annie Thurman	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10002293	Technology	Phones	Anker 36W 4-Port USB Wall Charger Travel Power Adapter for iPhone 5s 5c 5	79.96	5	0.2	7.996
1395	US-2014-117247	10/9/2016	10/14/2016	Standard Class	CK-12760	Cyma Kinney	Corporate	United States	Aurora	Illinois	60505	Central	FUR-TA-10002958	Furniture	Tables	Bevis Oval Conference Table, Walnut	652.45	5	0.5	-430.617
1275	CA-2013-119186	5/27/2015	5/27/2015	Same Day	MS-17710	Maurice Satty	Consumer	United States	Fort Worth	Texas	76106	Central	FUR-CH-10001973	Furniture	Chairs	Office Star Flex Back Scooter Chair with White Frame	388.43	5	0.3	-88.784
39	CA-2012-117415	12/27/2014	12/31/2014	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Houston	Texas	77041	Central	FUR-BO-10002545	Furniture	Bookcases	Atlantic Metals Mobile 3-Shelf Bookcases, Custom Colors	532.3992	3	0.32	-46.9764
544	CA-2011-103849	5/11/2013	5/16/2013	Standard Class	PG-18895	Paul Gonzalez	Consumer	United States	Fort Worth	Texas	76106	Central	TEC-AC-10001465	Technology	Accessories	SanDisk Cruzer 64 GB USB Flash Drive	58.112	2	0.2	7.264
8151	CA-2011-167997	1/26/2013	1/29/2013	First Class	CA-11965	Carol Adams	Corporate	United States	Rapid City	South Dakota	57701	Central	FUR-BO-10004409	Furniture	Bookcases	Safco Value Mate Series Steel Bookcases, Baked Enamel Finish on Steel, Gray	141.96	2	0	39.7488
1446	CA-2014-102337	6/13/2016	6/16/2016	First Class	SD-20485	Shirley Daniels	Home Office	United States	Chicago	Illinois	60653	Central	OFF-ST-10004804	Office Supplies	Storage	Belkin 19" Vented Equipment Shelf, Black	164.736	4	0.2	-39.1248
1274	CA-2013-119186	5/27/2015	5/27/2015	Same Day	MS-17710	Maurice Satty	Consumer	United States	Fort Worth	Texas	76106	Central	OFF-PA-10004621	Office Supplies	Paper	Xerox 212	10.368	2	0.2	3.6288
6175	US-2011-106299	8/2/2013	8/8/2013	Standard Class	NZ-18565	Nick Zandusky	Home Office	United States	Springfield	Missouri	65807	Central	OFF-ST-10002011	Office Supplies	Storage	Smead Adjustable Mobile File Trolley with Lockable Top	838.38	2	0	226.3626
1787	CA-2014-166317	9/22/2016	9/26/2016	Standard Class	JE-15610	Jim Epp	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-PH-10001615	Technology	Phones	AT&T CL82213	86.97	3	0	25.2213
623	CA-2012-138009	11/29/2014	12/3/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Dearborn	Michigan	48126	Central	FUR-CH-10004853	Furniture	Chairs	Global Manager's Adjustable Task Chair, Storm	301.96	2	0	87.5684
5349	CA-2012-149811	1/4/2014	1/10/2014	Standard Class	CS-12250	Chris Selesnick	Corporate	United States	Woodbury	Minnesota	55125	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	32.34	3	0	15.5232
381	CA-2012-130792	4/28/2014	5/5/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10000309	Office Supplies	Binders	GBC Twin Loop Wire Binding Elements, 9/16" Spine, Black	12.176	4	0.8	-18.8728
4784	US-2014-147984	1/29/2016	2/2/2016	Standard Class	GB-14575	Giulietta Baptist	Consumer	United States	Wichita	Kansas	67212	Central	OFF-PA-10000806	Office Supplies	Paper	Xerox 1934	279.9	5	0	137.151
2942	CA-2014-155880	3/25/2016	3/31/2016	Standard Class	JD-16150	Justin Deggeller	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10004675	Furniture	Chairs	Lifetime Advantage Folding Chairs, 4/Carton	1526.56	7	0	427.4368
5855	CA-2012-112214	8/5/2014	8/11/2014	Standard Class	AH-10690	Anna Häberlin	Corporate	United States	Dallas	Texas	75220	Central	OFF-ST-10001505	Office Supplies	Storage	Perma STOR-ALL Hanging File Box, 13 1/8"W x 12 1/4"D x 10 1/2"H	33.488	7	0.2	-1.2558
377	US-2013-134656	9/29/2015	10/2/2015	First Class	MM-18280	Muhammed MacIntyre	Corporate	United States	Quincy	Illinois	62301	Central	OFF-PA-10003039	Office Supplies	Paper	Xerox 1960	99.136	4	0.2	30.98
8695	US-2011-112795	8/23/2013	8/28/2013	Second Class	CR-12625	Corey Roper	Home Office	United States	Grand Rapids	Michigan	49505	Central	OFF-PA-10001934	Office Supplies	Paper	Xerox 1993	19.44	3	0	9.5256
6827	CA-2013-118689	10/3/2015	10/10/2015	Standard Class	TC-20980	Tamara Chand	Corporate	United States	Lafayette	Indiana	47905	Central	TEC-CO-10004722	Technology	Copiers	Canon imageCLASS 2200 Advanced Copier	17499.95	5	0	8399.976
1148	CA-2012-112452	4/4/2014	4/4/2014	Same Day	NC-18340	Nat Carroll	Consumer	United States	Lansing	Michigan	48911	Central	OFF-FA-10000735	Office Supplies	Fasteners	Staples	5.84	2	0	2.628
7426	CA-2013-101693	6/26/2015	6/28/2015	Second Class	LC-17140	Logan Currie	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10001146	Furniture	Chairs	Global Value Mid-Back Manager's Chair, Gray	85.246	2	0.3	-6.089
7688	CA-2013-169838	11/26/2015	11/30/2015	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Jackson	Michigan	49201	Central	OFF-BI-10004002	Office Supplies	Binders	Wilson Jones International Size A4 Ring Binders	17.3	1	0	8.304
3956	CA-2011-133228	4/4/2013	4/9/2013	Standard Class	MS-17710	Maurice Satty	Consumer	United States	Detroit	Michigan	48205	Central	OFF-AR-10001955	Office Supplies	Art	Newell 319	79.36	4	0	23.808
3109	CA-2013-121671	7/18/2015	7/23/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Springfield	Missouri	65807	Central	OFF-ST-10002344	Office Supplies	Storage	Carina 42"Hx23 3/4"W Media Storage Unit	242.94	3	0	4.8588
644	CA-2014-106103	6/10/2016	6/15/2016	Standard Class	SC-20305	Sean Christensen	Consumer	United States	Rochester Hills	Michigan	48307	Central	TEC-AC-10003832	Technology	Accessories	Imation 16GB Mini TravelDrive USB 2.0 Flash Drive	132.52	4	0	54.3332
1346	CA-2011-118339	3/17/2013	3/24/2013	Standard Class	BN-11515	Bradley Nguyen	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-AP-10001154	Office Supplies	Appliances	Bionaire Personal Warm Mist Humidifier/Vaporizer	93.78	2	0	36.5742
4512	CA-2013-119935	11/11/2015	11/15/2015	Standard Class	KM-16225	Kalyca Meade	Corporate	United States	Springfield	Missouri	65807	Central	OFF-BI-10001597	Office Supplies	Binders	Wilson Jones Ledger-Size, Piano-Hinge Binder, 2", Blue	81.96	2	0	39.3408
5375	CA-2012-118738	10/24/2014	10/30/2014	Standard Class	AG-10495	Andrew Gjertsen	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10001166	Office Supplies	Paper	Xerox 2	10.368	2	0.2	3.6288
5552	US-2011-159618	11/12/2013	11/16/2013	Standard Class	DB-12970	Darren Budd	Corporate	United States	Houston	Texas	77036	Central	OFF-SU-10000432	Office Supplies	Supplies	Acco Side-Punched Conventional Columnar Pads	16.656	6	0.2	-3.123
8269	CA-2014-121790	1/31/2016	2/7/2016	Standard Class	LP-17095	Liz Preis	Consumer	United States	Aurora	Illinois	60505	Central	OFF-SU-10004231	Office Supplies	Supplies	Acme Tagit Stainless Steel Antibacterial Scissors	31.68	4	0.2	2.772
1757	CA-2012-135622	12/8/2014	12/11/2014	Second Class	TT-21460	Tonja Turnell	Home Office	United States	Fort Worth	Texas	76106	Central	TEC-PH-10001817	Technology	Phones	Wilson Electronics DB Pro Signal Booster	1718.4	6	0.2	150.36
4115	CA-2012-116687	5/2/2014	5/7/2014	Standard Class	NC-18625	Noah Childs	Corporate	United States	Houston	Texas	77095	Central	TEC-PH-10001750	Technology	Phones	Samsung Rugby III	158.376	3	0.2	13.8579
5419	CA-2012-110877	10/23/2014	10/26/2014	First Class	JE-15715	Joe Elijah	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10004621	Office Supplies	Paper	Xerox 212	36.288	7	0.2	12.7008
1794	CA-2011-104773	12/8/2013	12/13/2013	Standard Class	TB-21175	Thomas Boland	Corporate	United States	Houston	Texas	77041	Central	OFF-ST-10000777	Office Supplies	Storage	Companion Letter/Legal File, Black	60.416	2	0.2	6.0416
9125	CA-2013-128916	8/19/2015	8/21/2015	Second Class	MA-17560	Matt Abelman	Home Office	United States	Houston	Texas	77070	Central	FUR-FU-10001940	Furniture	Furnishings	Staple-based wall hangings	9.552	3	0.6	-3.8208
7255	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	FUR-FU-10001037	Furniture	Furnishings	DAX Charcoal/Nickel-Tone Document Frame, 5 x 7	47.4	5	0	21.33
6997	CA-2014-117443	12/23/2016	12/25/2016	Second Class	JB-15400	Jennifer Braxton	Corporate	United States	Rockford	Illinois	61107	Central	OFF-BI-10004002	Office Supplies	Binders	Wilson Jones International Size A4 Ring Binders	13.84	4	0.8	-22.144
8813	US-2013-140172	3/9/2015	3/14/2015	Standard Class	SP-20650	Stephanie Phelps	Corporate	United States	Jackson	Michigan	49201	Central	OFF-AR-10002766	Office Supplies	Art	Prang Drawing Pencil Set	13.9	5	0	3.753
9792	CA-2011-127166	5/21/2013	5/23/2013	Second Class	KH-16360	Katherine Hughes	Consumer	United States	Houston	Texas	77070	Central	OFF-EN-10003134	Office Supplies	Envelopes	Staple envelope	56.064	6	0.2	21.024
78	US-2014-118038	12/9/2016	12/11/2016	First Class	KB-16600	Ken Brennan	Corporate	United States	Houston	Texas	77041	Central	OFF-ST-10000615	Office Supplies	Storage	SimpliFile Personal File, Black Granite, 15w x 6-15/16d x 11-1/4h	27.24	3	0.2	2.724
8877	US-2013-141264	8/14/2015	8/20/2015	Standard Class	CT-11995	Carol Triggs	Consumer	United States	Irving	Texas	75061	Central	OFF-AP-10002534	Office Supplies	Appliances	3.6 Cubic Foot Counter Height Office Refrigerator	58.924	1	0.8	-153.2024
2318	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	OFF-BI-10002072	Office Supplies	Binders	Cardinal Slant-D Ring Binders	60.83	7	0	30.415
9873	CA-2014-146269	10/6/2016	10/6/2016	Same Day	MH-17455	Mark Hamilton	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AR-10004790	Office Supplies	Art	Staples in misc. colors	19.152	2	0.2	1.197
9356	CA-2012-110324	12/1/2014	12/5/2014	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Jackson	Michigan	49201	Central	OFF-AR-10000823	Office Supplies	Art	Newell 307	3.64	2	0	1.0192
6569	CA-2011-100678	4/18/2013	4/22/2013	Standard Class	KM-16720	Kunst Miller	Consumer	United States	Houston	Texas	77095	Central	OFF-AR-10001868	Office Supplies	Art	Prang Dustless Chalk Sticks	2.688	2	0.2	1.008
6571	CA-2011-100678	4/18/2013	4/22/2013	Standard Class	KM-16720	Kunst Miller	Consumer	United States	Houston	Texas	77095	Central	OFF-EN-10000056	Office Supplies	Envelopes	Cameo Buff Policy Envelopes	149.352	3	0.2	50.4063
4598	US-2014-169502	8/28/2016	9/1/2016	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Milwaukee	Wisconsin	53209	Central	OFF-SU-10004115	Office Supplies	Supplies	Acme Stainless Steel Office Snips	21.81	3	0	5.8887
2599	CA-2014-149048	5/13/2016	5/17/2016	Standard Class	BM-11650	Brian Moss	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10001752	Office Supplies	Paper	Hammermill CopyPlus Copy Paper (20Lb. and 84 Bright)	14.94	3	0	7.3206
3950	CA-2013-119963	11/19/2015	11/23/2015	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Pasadena	Texas	77506	Central	OFF-PA-10001970	Office Supplies	Paper	Xerox 1881	19.648	2	0.2	6.6312
7788	US-2013-117037	5/18/2015	5/21/2015	First Class	LW-17215	Luke Weiss	Consumer	United States	Chicago	Illinois	60653	Central	OFF-FA-10000936	Office Supplies	Fasteners	Acco Hot Clips Clips to Go	7.896	3	0.2	2.4675
2823	CA-2014-131016	9/18/2016	9/20/2016	First Class	DC-12850	Dan Campbell	Consumer	United States	Arlington	Texas	76017	Central	OFF-AR-10000122	Office Supplies	Art	Newell 314	8.928	2	0.2	0.558
6198	CA-2012-149909	11/13/2014	11/17/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Columbus	Indiana	47201	Central	OFF-PA-10000726	Office Supplies	Paper	Black Print Carbonless Snap-Off Rapid Letter, 8 1/2" x 7"	63.77	7	0	28.6965
7653	CA-2014-110821	8/7/2016	8/8/2016	First Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Dallas	Texas	75081	Central	OFF-ST-10002790	Office Supplies	Storage	Safco Industrial Shelving	118.16	2	0.2	-25.109
9494	CA-2013-105207	1/3/2015	1/8/2015	Standard Class	BO-11350	Bill Overfelt	Corporate	United States	Broken Arrow	Oklahoma	74012	Central	FUR-TA-10000617	Furniture	Tables	Hon Practical Foundations 30 x 60 Training Table, Light Gray/Charcoal	1592.85	7	0	350.427
8978	CA-2014-156622	11/23/2016	11/26/2016	First Class	JP-15460	Jennifer Patt	Corporate	United States	Dallas	Texas	75220	Central	OFF-BI-10003707	Office Supplies	Binders	Aluminum Screw Posts	6.104	2	0.8	-9.156
1831	CA-2014-145884	10/21/2016	10/21/2016	Same Day	SL-20155	Sara Luxemburg	Home Office	United States	Muskogee	Oklahoma	74403	Central	TEC-PH-10000895	Technology	Phones	Polycom VVX 310 VoIP phone	1439.92	8	0	374.3792
9780	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AP-10003281	Office Supplies	Appliances	Acco 6 Outlet Guardian Standard Surge Suppressor	4.836	2	0.8	-12.09
1669	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	OFF-AR-10003405	Office Supplies	Art	Dixon My First Ticonderoga Pencil, #2	14.04	3	0.2	1.5795
3077	CA-2011-143903	7/20/2013	7/24/2013	Standard Class	KM-16375	Katherine Murray	Home Office	United States	Dallas	Texas	75217	Central	FUR-FU-10003724	Furniture	Furnishings	Westinghouse Clip-On Gooseneck Lamps	16.74	5	0.6	-14.229
5264	CA-2011-105165	9/7/2013	9/10/2013	First Class	SZ-20035	Sam Zeldin	Home Office	United States	Houston	Texas	77036	Central	TEC-AC-10002718	Technology	Accessories	Belkin Standard 104 key USB Keyboard	46.688	4	0.2	-2.918
304	US-2014-152380	11/19/2016	11/23/2016	Standard Class	JH-15910	Jonathan Howell	Consumer	United States	Chicago	Illinois	60623	Central	FUR-TA-10002533	Furniture	Tables	BPI Conference Tables	219.075	3	0.5	-131.445
4192	CA-2012-129392	7/8/2014	7/8/2014	Same Day	DM-13015	Darrin Martin	Consumer	United States	Houston	Texas	77070	Central	OFF-PA-10004248	Office Supplies	Paper	Xerox 1990	21.12	5	0.2	6.6
7495	US-2014-160836	9/11/2016	9/16/2016	Standard Class	CC-12475	Cindy Chapman	Consumer	United States	Houston	Texas	77070	Central	OFF-AP-10001626	Office Supplies	Appliances	Commercial WindTunnel Clean Air Upright Vacuum, Replacement Belts, Filtration Bags	1.556	2	0.8	-4.2012
1665	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	TEC-AC-10002049	Technology	Accessories	Logitech G19 Programmable Gaming Keyboard	297.576	3	0.2	-7.4394
6251	CA-2014-121580	5/29/2016	6/4/2016	Standard Class	ML-17410	Maris LaWare	Consumer	United States	Columbus	Indiana	47201	Central	OFF-PA-10004082	Office Supplies	Paper	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	7.98	1	0	3.99
7546	CA-2011-103492	10/10/2013	10/15/2013	Standard Class	CM-12715	Craig Molinari	Corporate	United States	Huntsville	Texas	77340	Central	TEC-PH-10001128	Technology	Phones	Motorola Droid Maxx	719.952	6	0.2	71.9952
2683	CA-2014-127026	1/22/2016	1/28/2016	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Jackson	Michigan	49201	Central	TEC-MA-10002981	Technology	Machines	I.R.I.S IRISCard Anywhere 5 Card Scanner	350.973	3	0.1	152.0883
6301	US-2011-161305	6/6/2013	6/12/2013	Standard Class	SB-20170	Sarah Bern	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10002794	Office Supplies	Binders	Avery Trapezoid Ring Binder, 3" Capacity, Black, 1040 sheets	24.588	3	0.8	-38.1114
489	CA-2011-133753	6/9/2013	6/13/2013	Second Class	CW-11905	Carl Weiss	Home Office	United States	Huntsville	Texas	77340	Central	TEC-PH-10000376	Technology	Phones	Square Credit Card Reader	7.992	1	0.2	0.5994
7568	CA-2014-140802	4/21/2016	4/23/2016	First Class	KN-16390	Katherine Nockton	Corporate	United States	Houston	Texas	77070	Central	OFF-PA-10001534	Office Supplies	Paper	Xerox 230	20.736	4	0.2	7.2576
4187	CA-2014-112536	5/18/2016	5/23/2016	Standard Class	SG-20890	Susan Gilcrest	Corporate	United States	Mcallen	Texas	78501	Central	OFF-BI-10003712	Office Supplies	Binders	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Light Blue	6.874	7	0.8	-10.6547
4546	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10000526	Technology	Phones	Vtech CS6719	537.544	7	0.2	53.7544
4545	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10003505	Technology	Phones	Geemarc AmpliPOWER60	148.48	2	0.2	16.704
4097	CA-2011-116904	9/23/2013	9/28/2013	Standard Class	SC-20095	Sanjit Chand	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-PA-10004888	Office Supplies	Paper	Xerox 217	32.4	5	0	15.552
8183	CA-2014-155642	5/18/2016	5/22/2016	Standard Class	BM-11575	Brendan Murry	Corporate	United States	Chicago	Illinois	60653	Central	FUR-FU-10004973	Furniture	Furnishings	Flat Face Poster Frame	22.608	3	0.6	-10.1736
9039	CA-2014-157420	11/21/2016	11/21/2016	Same Day	HZ-14950	Henia Zydlo	Consumer	United States	Houston	Texas	77095	Central	TEC-PH-10003555	Technology	Phones	Motorola HK250 Universal Bluetooth Headset	55.176	3	0.2	-12.4146
7506	US-2014-106579	6/8/2016	6/13/2016	Standard Class	BW-11200	Ben Wallace	Consumer	United States	Skokie	Illinois	60076	Central	OFF-BI-10000309	Office Supplies	Binders	GBC Twin Loop Wire Binding Elements, 9/16" Spine, Black	12.176	4	0.8	-18.8728
9298	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	TEC-PH-10003357	Technology	Phones	Grandstream GXP2100 Mainstream Business Phone	244.768	4	0.2	24.4768
5236	CA-2013-111143	11/20/2015	11/23/2015	First Class	TT-21265	Tim Taslimi	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-AP-10001947	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	54.96	3	0	15.9384
9578	CA-2012-143147	5/26/2014	5/28/2014	Second Class	PS-18760	Pamela Stobb	Consumer	United States	San Antonio	Texas	78207	Central	FUR-CH-10004754	Furniture	Chairs	Global Stack Chair with Arms, Black	104.93	5	0.3	-4.497
5223	CA-2014-117401	5/18/2016	5/22/2016	Second Class	PP-18955	Paul Prost	Home Office	United States	Springfield	Missouri	65807	Central	TEC-PH-10003555	Technology	Phones	Motorola HK250 Universal Bluetooth Headset	114.95	5	0	2.299
2168	CA-2013-154018	10/14/2015	10/20/2015	Standard Class	HA-14920	Helen Andreada	Consumer	United States	Laredo	Texas	78041	Central	OFF-BI-10004140	Office Supplies	Binders	Avery Non-Stick Binders	6.286	7	0.8	-11.0005
8187	CA-2012-136728	9/13/2014	9/17/2014	Second Class	AG-10900	Arthur Gainer	Consumer	United States	Chicago	Illinois	60623	Central	FUR-CH-10003817	Furniture	Chairs	Global Value Steno Chair, Gray	170.072	4	0.3	-12.148
3962	CA-2012-113901	10/19/2014	10/24/2014	Standard Class	NH-18610	Nicole Hansen	Corporate	United States	Detroit	Michigan	48227	Central	TEC-PH-10002564	Technology	Phones	OtterBox Defender Series Case - Samsung Galaxy S4	149.95	5	0	44.985
2428	CA-2013-169922	6/12/2015	6/18/2015	Standard Class	MZ-17515	Mary Zewe	Corporate	United States	Arlington	Texas	76017	Central	OFF-BI-10003784	Office Supplies	Binders	Computer Printout Index Tabs	1.344	4	0.8	-2.1504
6072	CA-2012-120901	12/31/2014	1/4/2015	Standard Class	BG-11035	Barry Gonzalez	Consumer	United States	Austin	Texas	78745	Central	OFF-ST-10000025	Office Supplies	Storage	Fellowes Stor/Drawer Steel Plus Storage Drawers	152.688	2	0.2	-26.7204
4366	CA-2014-111332	5/20/2016	5/22/2016	Second Class	NC-18340	Nat Carroll	Consumer	United States	Fargo	North Dakota	58103	Central	OFF-FA-10001843	Office Supplies	Fasteners	Staples	7.41	3	0	3.4827
6123	CA-2014-152660	12/4/2016	12/9/2016	Standard Class	CB-12415	Christy Brittain	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10000532	Office Supplies	Storage	Advantus Rolling Drawer Organizers	61.568	2	0.2	4.6176
752	CA-2014-126074	10/2/2016	10/6/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Trenton	Michigan	48183	Central	OFF-AR-10003478	Office Supplies	Art	Avery Hi-Liter EverBold Pen Style Fluorescent Highlighters, 4/Pack	56.98	7	0	22.792
9096	US-2012-132836	6/1/2014	6/5/2014	Standard Class	AJ-10945	Ashley Jarboe	Consumer	United States	Detroit	Michigan	48227	Central	TEC-PH-10001300	Technology	Phones	iKross Bluetooth Portable Keyboard + Cell Phone Stand Holder + Brush for Apple iPhone 5S 5C 5, 4S 4	41.9	2	0	11.732
9872	CA-2014-146269	10/6/2016	10/6/2016	Same Day	MH-17455	Mark Hamilton	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10003208	Office Supplies	Storage	Adjustable Depth Letter/Legal Cart	290.336	2	0.2	32.6628
1854	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	OFF-PA-10003129	Office Supplies	Paper	Tops White Computer Printout Paper	97.82	2	0	45.9754
3828	CA-2014-141733	5/7/2016	5/11/2016	Standard Class	RW-19540	Rick Wilson	Corporate	United States	Detroit	Michigan	48234	Central	FUR-CH-10004086	Furniture	Chairs	Hon 4070 Series Pagoda Armless Upholstered Stacking Chairs	1458.65	5	0	423.0085
38	CA-2012-117415	12/27/2014	12/31/2014	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Houston	Texas	77041	Central	OFF-EN-10002986	Office Supplies	Envelopes	#10-4 1/8" x 9 1/2" Premium Diagonal Seam Envelopes	113.328	9	0.2	35.415
2429	CA-2013-169922	6/12/2015	6/18/2015	Standard Class	MZ-17515	Mary Zewe	Corporate	United States	Arlington	Texas	76017	Central	OFF-BI-10001617	Office Supplies	Binders	GBC Wire Binding Combs	8.272	4	0.8	-13.6488
7848	CA-2013-128706	2/27/2015	3/3/2015	Standard Class	DW-13540	Don Weiss	Consumer	United States	Houston	Texas	77070	Central	FUR-FU-10004053	Furniture	Furnishings	DAX Two-Tone Silver Metal Document Frame	16.192	2	0.6	-6.8816
5168	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	FUR-CH-10004997	Furniture	Chairs	Hon Every-Day Series Multi-Task Chairs	563.94	3	0	112.788
1844	CA-2012-135391	2/9/2014	2/11/2014	Second Class	FA-14230	Frank Atkinson	Corporate	United States	San Antonio	Texas	78207	Central	FUR-FU-10001986	Furniture	Furnishings	Dana Fluorescent Magnifying Lamp, White, 36"	40.784	2	0.6	-30.588
7135	CA-2014-141439	11/26/2016	12/1/2016	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Richmond	Indiana	47374	Central	TEC-PH-10001819	Technology	Phones	Innergie mMini Combo Duo USB Travel Charging Kit	89.98	2	0	43.1904
9440	US-2011-154655	10/12/2013	10/17/2013	Standard Class	BP-11050	Barry Pond	Corporate	United States	Chicago	Illinois	60623	Central	OFF-SU-10000898	Office Supplies	Supplies	Acme Hot Forged Carbon Steel Scissors with Nickel-Plated Handles, 3 7/8" Cut, 8"L	22.24	2	0.2	2.502
3491	CA-2012-157322	7/2/2014	7/6/2014	Standard Class	RH-19600	Rob Haberlin	Consumer	United States	Carol Stream	Illinois	60188	Central	OFF-ST-10004507	Office Supplies	Storage	Advantus Rolling Storage Box	68.6	5	0.2	6.0025
3474	CA-2014-111815	3/3/2016	3/10/2016	Standard Class	EP-13915	Emily Phan	Consumer	United States	Dearborn Heights	Michigan	48127	Central	FUR-CH-10000785	Furniture	Chairs	Global Ergonomic Managers Chair	180.98	1	0	47.0548
6852	US-2013-100461	1/8/2015	1/12/2015	Standard Class	JO-15145	Jack O'Briant	Corporate	United States	Franklin	Wisconsin	53132	Central	OFF-BI-10001460	Office Supplies	Binders	Plastic Binding Combs	106.05	7	0	49.8435
4151	CA-2014-106068	10/23/2016	10/28/2016	Standard Class	RB-19330	Randy Bradley	Consumer	United States	Austin	Texas	78745	Central	OFF-ST-10002344	Office Supplies	Storage	Carina 42"Hx23 3/4"W Media Storage Unit	259.136	4	0.2	-58.3056
8362	CA-2014-147207	1/3/2016	1/5/2016	Second Class	TS-21655	Trudy Schmidt	Consumer	United States	El Paso	Texas	79907	Central	OFF-AP-10000027	Office Supplies	Appliances	Hoover Commercial SteamVac	5.432	2	0.8	-13.58
837	US-2011-115987	9/8/2013	9/13/2013	Second Class	LH-17020	Lisa Hazard	Consumer	United States	Tyler	Texas	75701	Central	OFF-BI-10001071	Office Supplies	Binders	GBC ProClick Punch Binding System	51.184	4	0.8	-79.3352
3515	CA-2014-140326	9/4/2016	9/6/2016	First Class	HW-14935	Helen Wasserman	Corporate	United States	Chicago	Illinois	60653	Central	OFF-AR-10001149	Office Supplies	Art	Sanford Colorific Colored Pencils, 12/Box	6.912	3	0.2	0.864
4276	CA-2012-123456	7/9/2014	7/13/2014	Standard Class	KN-16450	Kean Nguyen	Corporate	United States	Dallas	Texas	75220	Central	OFF-AP-10002684	Office Supplies	Appliances	Acco 7-Outlet Masterpiece Power Center, Wihtout Fax/Phone Line Protection	48.632	2	0.8	-121.58
444	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	OFF-PA-10002222	Office Supplies	Paper	Xerox Color Copier Paper, 11" x 17", Ream	91.36	4	0	42.0256
1810	CA-2013-165484	10/24/2015	10/30/2015	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Chicago	Illinois	60610	Central	FUR-FU-10001196	Furniture	Furnishings	DAX Cubicle Frames - 8x10	16.156	7	0.6	-12.117
9692	CA-2012-130183	11/13/2014	11/17/2014	Standard Class	PO-18850	Patrick O'Brill	Consumer	United States	Houston	Texas	77041	Central	FUR-BO-10001811	Furniture	Bookcases	Atlantic Metals Mobile 5-Shelf Bookcases, Custom Colors	613.9992	3	0.32	-18.0588
6557	CA-2011-137092	10/20/2013	10/22/2013	Second Class	LS-16975	Lindsay Shagiari	Home Office	United States	Chicago	Illinois	60653	Central	OFF-BI-10000632	Office Supplies	Binders	Satellite Sectional Post Binders	8.682	1	0.8	-14.7594
7851	CA-2013-104311	5/3/2015	5/7/2015	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Irving	Texas	75061	Central	OFF-LA-10000973	Office Supplies	Labels	Avery 502	5.04	2	0.2	1.764
8008	CA-2012-110863	11/17/2014	11/24/2014	Standard Class	AA-10645	Anna Andreadi	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-ST-10002756	Office Supplies	Storage	Tennsco Stur-D-Stor Boltless Shelving, 5 Shelves, 24" Deep, Sand	541.24	4	0	5.4124
3756	CA-2013-116799	3/4/2015	3/7/2015	First Class	JG-15310	Jason Gross	Corporate	United States	Odessa	Texas	79762	Central	OFF-PA-10001892	Office Supplies	Paper	Rediform Wirebound "Phone Memo" Message Book, 11 x 5-3/4	42.784	7	0.2	15.5092
2285	CA-2012-153108	3/5/2014	3/9/2014	Standard Class	SF-20200	Sarah Foster	Consumer	United States	New Castle	Indiana	47362	Central	OFF-AP-10002222	Office Supplies	Appliances	Staple holder	60.69	7	0	16.3863
7427	CA-2013-101693	6/26/2015	6/28/2015	Second Class	LC-17140	Logan Currie	Consumer	United States	Houston	Texas	77070	Central	FUR-FU-10003919	Furniture	Furnishings	Eldon Executive Woodline II Cherry Finish Desk Accessories	32.712	2	0.6	-26.1696
8071	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	FUR-FU-10002116	Furniture	Furnishings	Tenex Carpeted, Granite-Look or Clear Contemporary Contour Shape Chair Mats	141.42	5	0.6	-187.3815
6533	US-2014-107384	12/4/2016	12/8/2016	Standard Class	TP-21130	Theone Pippenger	Consumer	United States	Rochester	Minnesota	55901	Central	TEC-AC-10004595	Technology	Accessories	First Data TMFD35 PIN Pad	142.8	1	0	29.988
9593	US-2013-105452	7/29/2015	8/2/2015	Standard Class	BF-11005	Barry Franz	Home Office	United States	Pasadena	Texas	77506	Central	FUR-FU-10003806	Furniture	Furnishings	Tenex Chairmat w/ Average Lip, 45" x 53"	302.72	5	0.6	-378.4
1971	CA-2014-140242	5/6/2016	5/11/2016	Standard Class	ML-17755	Max Ludwig	Home Office	United States	Chicago	Illinois	60623	Central	OFF-AR-10004752	Office Supplies	Art	Blackstonian Pencils	6.408	3	0.2	0.6408
5191	US-2014-136679	11/14/2016	11/18/2016	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Pasadena	Texas	77506	Central	OFF-AR-10003582	Office Supplies	Art	Boston Electric Pencil Sharpener, Model 1818, Charcoal Black	45.04	2	0.2	4.504
2403	CA-2014-145877	4/1/2016	4/4/2016	Second Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	OFF-EN-10001990	Office Supplies	Envelopes	Staple envelope	28.4	5	0	13.348
4255	CA-2014-163160	10/13/2016	10/16/2016	First Class	TS-21610	Troy Staebel	Consumer	United States	Freeport	Illinois	61032	Central	OFF-PA-10003127	Office Supplies	Paper	Easy-staple paper	63.312	3	0.2	20.5764
1770	CA-2014-146024	3/2/2016	3/8/2016	Standard Class	SC-20770	Stewart Carmichael	Corporate	United States	Dallas	Texas	75081	Central	OFF-SU-10001935	Office Supplies	Supplies	Staple remover	6.976	4	0.2	-1.3952
1924	CA-2013-156685	7/9/2015	7/11/2015	Second Class	SC-20230	Scot Coram	Corporate	United States	Arlington	Texas	76017	Central	OFF-AR-10000588	Office Supplies	Art	Newell 345	47.616	3	0.2	3.5712
6666	CA-2013-115483	7/15/2015	7/19/2015	Second Class	JS-15880	John Stevenson	Consumer	United States	Irving	Texas	75061	Central	OFF-PA-10001497	Office Supplies	Paper	Xerox 1914	219.84	5	0.2	79.692
40	CA-2012-117415	12/27/2014	12/31/2014	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Houston	Texas	77041	Central	FUR-CH-10004218	Furniture	Chairs	Global Fabric Manager's Chair, Dark Gray	212.058	3	0.3	-15.147
9482	CA-2014-150504	11/6/2016	11/12/2016	Standard Class	HG-14845	Harry Greene	Consumer	United States	Dallas	Texas	75220	Central	OFF-ST-10000615	Office Supplies	Storage	SimpliFile Personal File, Black Granite, 15w x 6-15/16d x 11-1/4h	18.16	2	0.2	1.816
5157	CA-2014-163006	6/30/2016	7/4/2016	Second Class	GH-14410	Gary Hansen	Home Office	United States	Chicago	Illinois	60653	Central	TEC-PH-10002584	Technology	Phones	Samsung Galaxy S4	1001.584	2	0.2	125.198
8919	US-2013-144057	5/10/2015	5/14/2015	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Austin	Texas	78745	Central	OFF-BI-10002353	Office Supplies	Binders	GBC VeloBind Cover Sets	18.528	6	0.8	-27.792
659	US-2013-156097	9/20/2015	9/20/2015	Same Day	EH-14125	Eugene Hildebrand	Home Office	United States	Aurora	Illinois	60505	Central	OFF-BI-10004654	Office Supplies	Binders	Avery Binding System Hidden Tab Executive Style Index Sets	2.308	2	0.8	-3.462
126	US-2011-134614	9/20/2013	9/25/2013	Standard Class	PF-19165	Philip Fox	Consumer	United States	Bloomington	Illinois	61701	Central	FUR-TA-10004534	Furniture	Tables	Bevis 44 x 96 Conference Tables	617.7	6	0.5	-407.682
8108	CA-2014-159149	2/18/2016	2/20/2016	First Class	CR-12820	Cyra Reiten	Home Office	United States	Houston	Texas	77041	Central	TEC-PH-10000038	Technology	Phones	Jawbone MINI JAMBOX Wireless Bluetooth Speaker	438.336	4	0.2	-87.6672
4409	CA-2013-100041	11/21/2015	11/26/2015	Standard Class	BF-10975	Barbara Fisher	Corporate	United States	Columbus	Indiana	47201	Central	OFF-BI-10000343	Office Supplies	Binders	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	4.91	1	0	2.3077
2943	CA-2014-155880	3/25/2016	3/31/2016	Standard Class	JD-16150	Justin Deggeller	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10002880	Furniture	Chairs	Global High-Back Leather Tilter, Burgundy	368.97	3	0	40.5867
5028	US-2014-130953	7/29/2016	8/3/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	FUR-CH-10004626	Furniture	Chairs	Office Star Flex Back Scooter Chair with Aluminum Finish Frame	302.67	3	0	72.6408
5035	CA-2012-103954	8/9/2014	8/13/2014	Second Class	HR-14770	Hallie Redmond	Home Office	United States	Milwaukee	Wisconsin	53209	Central	FUR-BO-10004690	Furniture	Bookcases	O'Sullivan Cherrywood Estates Traditional Barrister Bookcase	687.4	5	0	48.118
3708	CA-2011-120544	11/23/2013	11/27/2013	Standard Class	SS-20140	Saphhira Shifley	Corporate	United States	Mesquite	Texas	75150	Central	FUR-FU-10001940	Furniture	Furnishings	Staple-based wall hangings	6.368	2	0.6	-2.5472
8030	CA-2013-166373	10/22/2015	10/26/2015	Standard Class	JF-15565	Jill Fjeld	Consumer	United States	San Antonio	Texas	78207	Central	TEC-AC-10002323	Technology	Accessories	SanDisk Ultra 32 GB MicroSDHC Class 10 Memory Card	106.08	6	0.2	-9.282
2916	CA-2012-134747	10/12/2014	10/17/2014	Second Class	DL-12925	Daniel Lacy	Consumer	United States	Noblesville	Indiana	46060	Central	OFF-BI-10001308	Office Supplies	Binders	GBC Standard Plastic Binding Systems' Combs	12.56	2	0	5.652
9514	CA-2013-125220	10/15/2015	10/20/2015	Standard Class	BE-11410	Bobby Elias	Consumer	United States	Appleton	Wisconsin	54915	Central	TEC-AC-10003033	Technology	Accessories	Plantronics CS510 - Over-the-Head monaural Wireless Headset System	1649.75	5	0	544.4175
446	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	OFF-LA-10001317	Office Supplies	Labels	Avery 520	22.05	7	0	10.584
3857	US-2014-105389	10/23/2016	10/28/2016	Second Class	DM-13015	Darrin Martin	Consumer	United States	San Antonio	Texas	78207	Central	TEC-PH-10002824	Technology	Phones	Jabra SPEAK 410 Multidevice Speakerphone	823.96	5	0.2	51.4975
6917	CA-2011-142510	12/22/2013	12/29/2013	Standard Class	NP-18700	Nora Preis	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10001289	Office Supplies	Paper	White Computer Printout Paper by Universal	124.032	4	0.2	44.9616
3349	CA-2014-154732	11/5/2016	11/7/2016	First Class	AH-10195	Alan Haines	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10000474	Office Supplies	Binders	Avery Recycled Flexi-View Covers for Binding Systems	16.03	5	0.8	-25.648
5171	CA-2013-122903	5/28/2015	5/30/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Detroit	Michigan	48205	Central	FUR-CH-10002024	Furniture	Chairs	HON 5400 Series Task Chairs for Big and Tall	3504.9	5	0	700.98
4549	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10001861	Furniture	Furnishings	Floodlight Indoor Halogen Bulbs, 1 Bulb per Pack, 60 Watts	7.76	1	0.6	-2.134
8717	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	OFF-AP-10001242	Office Supplies	Appliances	APC 7 Outlet Network SurgeArrest Surge Protector	64.384	4	0.8	-160.96
5674	CA-2014-127922	10/27/2016	11/3/2016	Standard Class	SH-19975	Sally Hughsby	Corporate	United States	Dallas	Texas	75081	Central	OFF-PA-10001204	Office Supplies	Paper	Xerox 1972	8.448	2	0.2	2.64
77	US-2014-118038	12/9/2016	12/11/2016	First Class	KB-16600	Ken Brennan	Corporate	United States	Houston	Texas	77041	Central	FUR-FU-10000260	Furniture	Furnishings	6" Cubicle Wall Clock, Black	9.708	3	0.6	-5.8248
2631	CA-2012-168186	9/10/2014	9/15/2014	Standard Class	AB-10150	Aimee Bixby	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-PA-10000477	Office Supplies	Paper	Xerox 1952	14.94	3	0	7.0218
749	CA-2013-150889	3/21/2015	3/23/2015	Second Class	PB-19105	Peter Bühler	Consumer	United States	Evanston	Illinois	60201	Central	TEC-PH-10000004	Technology	Phones	Belkin iPhone and iPad Lightning Cable	11.992	1	0.2	0.8994
8031	CA-2013-158806	1/7/2015	1/11/2015	Standard Class	NM-18520	Neoma Murray	Consumer	United States	Amarillo	Texas	79109	Central	FUR-FU-10004270	Furniture	Furnishings	Executive Impressions 13" Clairmont Wall Clock	23.076	3	0.6	-10.9611
3078	CA-2011-143903	7/20/2013	7/24/2013	Standard Class	KM-16375	Katherine Murray	Home Office	United States	Dallas	Texas	75217	Central	FUR-CH-10002024	Furniture	Chairs	HON 5400 Series Task Chairs for Big and Tall	981.372	2	0.3	-140.196
1419	CA-2012-126697	9/21/2014	9/24/2014	First Class	SV-20815	Stuart Van	Corporate	United States	Houston	Texas	77041	Central	FUR-FU-10001706	Furniture	Furnishings	Longer-Life Soft White Bulbs	4.928	4	0.6	-1.4784
9099	CA-2014-152933	10/12/2016	10/16/2016	Standard Class	MG-17650	Matthew Grinstein	Home Office	United States	Dallas	Texas	75081	Central	TEC-PH-10002085	Technology	Phones	Clarity 53712	369.544	7	0.2	27.7158
8251	CA-2012-140221	3/5/2014	3/9/2014	Second Class	MS-17365	Maribeth Schnelling	Consumer	United States	Chicago	Illinois	60653	Central	FUR-FU-10000023	Furniture	Furnishings	Eldon Wave Desk Accessories	4.712	2	0.6	-1.8848
2315	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	OFF-AP-10002118	Office Supplies	Appliances	1.7 Cubic Foot Compact "Cube" Office Refrigerators	416.32	2	0	112.4064
3512	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	OFF-ST-10004123	Office Supplies	Storage	Safco Industrial Wire Shelving System	509.488	7	0.2	-127.372
1082	CA-2012-110016	11/29/2014	12/4/2014	Standard Class	BT-11395	Bill Tyler	Corporate	United States	Detroit	Michigan	48227	Central	FUR-CH-10002880	Furniture	Chairs	Global High-Back Leather Tilter, Burgundy	1106.91	9	0	121.7601
7075	CA-2013-112256	7/24/2015	7/29/2015	Standard Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Mcallen	Texas	78501	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	4.752	4	0.8	-8.316
6572	CA-2011-100678	4/18/2013	4/22/2013	Standard Class	KM-16720	Kunst Miller	Consumer	United States	Houston	Texas	77095	Central	TEC-AC-10000474	Technology	Accessories	Kensington Expert Mouse Optical USB Trackball for PC or Mac	227.976	3	0.2	28.497
6250	CA-2014-121580	5/29/2016	6/4/2016	Standard Class	ML-17410	Maris LaWare	Consumer	United States	Columbus	Indiana	47201	Central	OFF-AP-10001564	Office Supplies	Appliances	Hoover Commercial Lightweight Upright Vacuum with E-Z Empty Dirt Cup	465.16	2	0	120.9416
1470	CA-2014-139199	12/9/2016	12/13/2016	Standard Class	DK-12835	Damala Kotsonis	Corporate	United States	Detroit	Michigan	48234	Central	OFF-BI-10003982	Office Supplies	Binders	Wilson Jones Century Plastic Molded Ring Binders	41.54	2	0	19.5238
9748	US-2011-140914	11/11/2013	11/15/2013	Standard Class	BH-11710	Brosina Hoffman	Consumer	United States	Chicago	Illinois	60653	Central	FUR-FU-10000175	Furniture	Furnishings	DAX Wood Document Frame.	10.984	2	0.6	-7.9634
7703	CA-2013-114601	8/27/2015	9/3/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Detroit	Michigan	48234	Central	OFF-PA-10000605	Office Supplies	Paper	Xerox 1950	11.56	2	0	5.6644
6595	CA-2012-146290	5/4/2014	5/11/2014	Standard Class	SV-20815	Stuart Van	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-AR-10001897	Office Supplies	Art	Model L Table or Wall-Mount Pencil Sharpener	125.93	7	0	35.2604
5757	CA-2011-163748	10/14/2013	10/18/2013	Standard Class	HG-15025	Hunter Glantz	Consumer	United States	Fort Worth	Texas	76106	Central	TEC-CO-10002095	Technology	Copiers	Hewlett Packard 610 Color Digital Copier / Printer	1999.96	5	0.2	624.9875
2647	CA-2011-131002	9/7/2013	9/12/2013	Second Class	TB-21400	Tom Boeckenhauer	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10000948	Office Supplies	Binders	GBC Laser Imprintable Binding System Covers, Desert Sand	42.81	3	0	20.1207
3848	CA-2014-129000	11/25/2016	11/27/2016	Second Class	SZ-20035	Sam Zeldin	Home Office	United States	Canton	Michigan	48187	Central	OFF-ST-10001097	Office Supplies	Storage	Office Impressions Heavy Duty Welded Shelving & Multimedia Storage Drawers	501.81	3	0	0
8469	US-2013-164196	11/12/2015	11/18/2015	Standard Class	AS-10285	Alejandro Savely	Corporate	United States	Noblesville	Indiana	46060	Central	FUR-TA-10001950	Furniture	Tables	Balt Solid Wood Round Tables	2678.94	6	0	241.1046
3768	CA-2012-103205	12/8/2014	12/10/2014	Second Class	JJ-15760	Joel Jenkins	Home Office	United States	Houston	Texas	77036	Central	TEC-PH-10004896	Technology	Phones	Nokia Lumia 521 (T-Mobile)	119.96	5	0.2	11.996
7608	CA-2014-121195	12/24/2016	12/27/2016	First Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75220	Central	OFF-ST-10000585	Office Supplies	Storage	Economy Rollaway Files	264.32	2	0.2	19.824
5940	CA-2014-122077	5/19/2016	5/25/2016	Standard Class	JF-15295	Jason Fortune-	Consumer	United States	Plano	Texas	75023	Central	OFF-LA-10004178	Office Supplies	Labels	Avery 491	13.216	4	0.2	4.2952
7266	US-2011-143721	11/23/2013	11/26/2013	Second Class	DK-12835	Damala Kotsonis	Corporate	United States	Houston	Texas	77095	Central	FUR-CH-10001973	Furniture	Chairs	Office Star Flex Back Scooter Chair with White Frame	155.372	2	0.3	-35.5136
9446	CA-2012-168277	5/29/2014	6/3/2014	Standard Class	KB-16315	Karl Braun	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-LA-10004484	Office Supplies	Labels	Avery 476	12.39	3	0	5.6994
6683	CA-2014-154466	1/2/2016	1/3/2016	First Class	DP-13390	Dennis Pardue	Home Office	United States	Franklin	Wisconsin	53132	Central	OFF-BI-10002012	Office Supplies	Binders	Wilson Jones Easy Flow II Sheet Lifters	3.6	2	0	1.728
9315	CA-2012-111948	11/11/2014	11/11/2014	Same Day	AG-10495	Andrew Gjertsen	Corporate	United States	Detroit	Michigan	48234	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	123.858	2	0.1	46.7908
9406	CA-2011-152618	3/14/2013	3/17/2013	First Class	RB-19465	Rick Bensley	Home Office	United States	Chicago	Illinois	60653	Central	TEC-MA-10003626	Technology	Machines	Hewlett-Packard Deskjet 6540 Color Inkjet Printer	574.91	2	0.3	156.047
3436	US-2012-100531	9/27/2014	9/29/2014	First Class	NM-18520	Neoma Murray	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10001670	Office Supplies	Binders	Vinyl Sectional Post Binders	15.08	2	0.8	-22.62
8328	CA-2014-103478	7/21/2016	7/24/2016	Second Class	KL-16555	Kelly Lampkin	Corporate	United States	Aurora	Illinois	60505	Central	OFF-BI-10004224	Office Supplies	Binders	Catalog Binders with Expanding Posts	94.192	7	0.8	-164.836
8033	CA-2012-119690	6/25/2014	6/28/2014	First Class	MV-17485	Mark Van Huff	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10001019	Office Supplies	Paper	Xerox 1884	47.952	3	0.2	16.1838
5891	CA-2013-146157	11/22/2015	11/27/2015	Standard Class	RD-19720	Roger Demir	Consumer	United States	Chicago	Illinois	60610	Central	OFF-PA-10001790	Office Supplies	Paper	Xerox 1910	38.432	1	0.2	13.4512
1733	US-2013-131149	7/11/2015	7/15/2015	Standard Class	LH-17155	Logan Haushalter	Consumer	United States	Dallas	Texas	75081	Central	OFF-ST-10000689	Office Supplies	Storage	Fellowes Strictly Business Drawer File, Letter/Legal Size	338.04	3	0.2	-33.804
426	CA-2014-149160	11/23/2016	11/26/2016	Second Class	JM-15265	Janet Molinari	Corporate	United States	Canton	Michigan	48187	Central	FUR-FU-10003347	Furniture	Furnishings	Coloredge Poster Frame	28.4	2	0	11.076
5565	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	OFF-AR-10000799	Office Supplies	Art	Col-Erase Pencils with Erasers	19.456	4	0.2	2.1888
5774	CA-2013-117408	9/1/2015	9/7/2015	Standard Class	TP-21130	Theone Pippenger	Consumer	United States	Waco	Texas	76706	Central	OFF-ST-10001580	Office Supplies	Storage	Super Decoflex Portable Personal File	23.968	2	0.2	2.3968
9447	CA-2013-158617	9/23/2015	9/29/2015	Standard Class	AC-10660	Anna Chung	Consumer	United States	Lawrence	Indiana	46226	Central	OFF-PA-10002245	Office Supplies	Paper	Xerox 1895	35.88	6	0	16.146
8781	CA-2012-133585	3/1/2014	3/4/2014	First Class	CM-12715	Craig Molinari	Corporate	United States	Houston	Texas	77070	Central	OFF-AR-10003696	Office Supplies	Art	Panasonic KP-350BK Electric Pencil Sharpener with Auto Stop	55.328	2	0.2	6.2244
9546	CA-2011-166590	10/29/2013	11/2/2013	Standard Class	NC-18625	Noah Childs	Corporate	United States	Columbus	Indiana	47201	Central	TEC-AC-10003433	Technology	Accessories	Maxell 4.7GB DVD+R 5/Pack	1.98	2	0	0.891
4616	CA-2013-144540	9/6/2015	9/11/2015	Standard Class	GH-14410	Gary Hansen	Home Office	United States	Houston	Texas	77070	Central	OFF-FA-10002763	Office Supplies	Fasteners	Advantus Map Pennant Flags and Round Head Tacks	28.44	9	0.2	4.266
3174	US-2013-133879	3/22/2015	3/29/2015	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AR-10004956	Office Supplies	Art	Newell 33	13.392	3	0.2	1.5066
8398	US-2011-120236	9/3/2013	9/4/2013	First Class	MR-17545	Mathew Reese	Home Office	United States	Houston	Texas	77095	Central	OFF-BI-10004099	Office Supplies	Binders	GBC VeloBinder Strips	7.68	5	0.8	-11.52
2511	CA-2013-136812	11/19/2015	11/24/2015	Standard Class	AW-10930	Arthur Wiediger	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-ST-10003470	Office Supplies	Storage	Tennsco Snap-Together Open Shelving Units, Starter Sets and Add-On Units	1117.92	4	0	55.896
5170	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	OFF-ST-10001490	Office Supplies	Storage	Hot File 7-Pocket, Floor Stand	535.41	3	0	160.623
7853	CA-2011-169649	12/9/2013	12/15/2013	Standard Class	TS-21205	Thomas Seio	Corporate	United States	Chicago	Illinois	60653	Central	OFF-AP-10003287	Office Supplies	Appliances	Tripp Lite TLP810NET Broadband Surge for Modem/Fax	20.388	2	0.8	-53.0088
3396	US-2014-148362	7/1/2016	7/8/2016	Standard Class	KF-16285	Karen Ferguson	Home Office	United States	Indianapolis	Indiana	46203	Central	OFF-ST-10001128	Office Supplies	Storage	Carina Mini System Audio Rack, Model AR050B	443.92	4	0	13.3176
5366	CA-2013-107790	11/21/2015	11/25/2015	Standard Class	EH-13990	Erica Hackney	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10004539	Technology	Phones	Wireless Extenders zBoost YX545 SOHO Signal Booster	151.192	1	0.2	13.2293
8185	US-2014-101721	7/23/2016	7/27/2016	Standard Class	MY-17380	Maribeth Yedwab	Corporate	United States	Chicago	Illinois	60623	Central	OFF-PA-10003641	Office Supplies	Paper	Xerox 1909	63.312	3	0.2	20.5764
5373	CA-2012-118738	10/24/2014	10/30/2014	Standard Class	AG-10495	Andrew Gjertsen	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10003177	Office Supplies	Paper	Xerox 1999	15.552	3	0.2	5.4432
7684	CA-2012-120782	4/28/2014	5/1/2014	First Class	SD-20485	Shirley Daniels	Home Office	United States	Midland	Michigan	48640	Central	OFF-BI-10003527	Office Supplies	Binders	Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind	3812.97	3	0	1906.485
8436	US-2011-127635	9/14/2013	9/18/2013	Second Class	SC-20260	Scott Cohen	Corporate	United States	Corpus Christi	Texas	78415	Central	OFF-BI-10001721	Office Supplies	Binders	Trimflex Flexible Post Binders	8.552	2	0.8	-13.6832
1110	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-EN-10003798	Office Supplies	Envelopes	Recycled Interoffice Envelopes with Re-Use-A-Seal Closure, 10 x 13	40.968	3	0.2	13.8267
37	CA-2013-117590	12/9/2015	12/11/2015	First Class	GH-14485	Gene Hale	Corporate	United States	Richardson	Texas	75080	Central	FUR-FU-10003664	Furniture	Furnishings	Electrix Architect's Clamp-On Swing Arm Lamp, Black	190.92	5	0.6	-147.963
7943	CA-2014-134194	12/25/2016	1/1/2017	Standard Class	GA-14725	Guy Armstrong	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10003684	Office Supplies	Binders	Wilson Jones Legal Size Ring Binders	39.582	9	0.8	-59.373
9915	CA-2014-160927	1/30/2016	2/1/2016	Second Class	TM-21010	Tamara Manning	Consumer	United States	Marion	Iowa	52302	Central	OFF-PA-10003848	Office Supplies	Paper	Xerox 1997	12.96	2	0	6.2208
9009	CA-2014-107825	11/18/2016	11/18/2016	Same Day	NB-18655	Nona Balk	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10000206	Furniture	Furnishings	GE General Purpose, Extra Long Life, Showcase & Floodlight Incandescent Bulbs	5.82	2	0	2.7354
9778	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	TEC-AC-10002076	Technology	Accessories	Microsoft Natural Keyboard Elite	431.136	9	0.2	-26.946
248	CA-2011-131926	6/1/2013	6/6/2013	Second Class	DW-13480	Dianna Wilson	Home Office	United States	Lakeville	Minnesota	55044	Central	OFF-AP-10002945	Office Supplies	Appliances	Honeywell Enviracaire Portable HEPA Air Cleaner for 17' x 22' Room	1503.25	5	0	496.0725
7258	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-PA-10000994	Office Supplies	Paper	Xerox 1915	629.1	6	0	301.968
6570	CA-2011-100678	4/18/2013	4/22/2013	Standard Class	KM-16720	Kunst Miller	Consumer	United States	Houston	Texas	77095	Central	FUR-CH-10002602	Furniture	Chairs	DMI Arturo Collection Mission-style Design Wood Chair	317.058	3	0.3	-18.1176
8201	CA-2014-125269	4/24/2016	4/30/2016	Standard Class	AF-10870	Art Ferguson	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10004123	Office Supplies	Storage	Safco Industrial Wire Shelving System	72.784	1	0.2	-18.196
7382	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	TEC-PH-10001644	Technology	Phones	BlueLounge Milo Smartphone Stand, White/Metallic	149.95	5	0	41.986
456	CA-2013-100153	12/14/2015	12/18/2015	Standard Class	KH-16630	Ken Heidel	Corporate	United States	Norman	Oklahoma	73071	Central	TEC-AC-10001772	Technology	Accessories	Memorex Mini Travel Drive 16 GB USB 2.0 Flash Drive	63.88	4	0	24.9132
7950	CA-2011-131009	3/1/2013	3/5/2013	Standard Class	SC-20380	Shahid Collister	Consumer	United States	El Paso	Texas	79907	Central	FUR-FU-10001095	Furniture	Furnishings	DAX Black Cherry Wood-Tone Poster Frame	63.552	6	0.6	-34.9536
893	CA-2014-133256	6/26/2016	6/27/2016	First Class	TH-21550	Tracy Hopkins	Home Office	United States	Detroit	Michigan	48227	Central	OFF-AR-10003158	Office Supplies	Art	Fluorescent Highlighters by Dixon	15.92	4	0	5.4128
2174	CA-2013-112025	7/31/2015	8/5/2015	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Houston	Texas	77070	Central	OFF-BI-10002353	Office Supplies	Binders	GBC VeloBind Cover Sets	9.264	3	0.8	-13.896
2430	CA-2013-169922	6/12/2015	6/18/2015	Standard Class	MZ-17515	Mary Zewe	Corporate	United States	Arlington	Texas	76017	Central	FUR-FU-10004415	Furniture	Furnishings	Stacking Tray, Side-Loading, Legal, Smoke	12.544	7	0.6	-9.0944
4240	CA-2014-158673	12/29/2016	1/4/2017	Standard Class	KB-16600	Ken Brennan	Corporate	United States	Grand Rapids	Michigan	49505	Central	OFF-PA-10000994	Office Supplies	Paper	Xerox 1915	209.7	2	0	100.656
3506	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	TEC-PH-10000369	Technology	Phones	HTC One Mini	201.584	2	0.2	20.1584
8827	US-2011-157847	4/2/2013	4/6/2013	Second Class	SC-20020	Sam Craven	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10002986	Office Supplies	Paper	Xerox 1898	26.72	5	0.2	9.352
7945	CA-2014-134194	12/25/2016	1/1/2017	Standard Class	GA-14725	Guy Armstrong	Consumer	United States	Dallas	Texas	75081	Central	OFF-AR-10001615	Office Supplies	Art	Newell 34	31.744	2	0.2	2.3808
9590	CA-2011-119172	5/11/2013	5/15/2013	Standard Class	HD-14785	Harold Dahlen	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10003036	Office Supplies	Paper	Black Print Carbonless 8 1/2" x 8 1/4" Rapid Memo Book	17.472	3	0.2	5.6784
4267	US-2013-131611	11/6/2015	11/10/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Houston	Texas	77036	Central	FUR-BO-10000780	Furniture	Bookcases	O'Sullivan Plantations 2-Door Library in Landvery Oak	956.6648	7	0.32	-225.0976
6497	CA-2014-111262	10/28/2016	11/1/2016	Second Class	KH-16510	Keith Herrera	Consumer	United States	Houston	Texas	77095	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	26.176	2	0.2	-3.272
8434	US-2011-127635	9/14/2013	9/18/2013	Second Class	SC-20260	Scott Cohen	Corporate	United States	Corpus Christi	Texas	78415	Central	OFF-PA-10004610	Office Supplies	Paper	Xerox 1900	6.848	2	0.2	2.14
7029	US-2013-157840	12/21/2015	12/24/2015	Second Class	MC-17575	Matt Collins	Consumer	United States	Fremont	Nebraska	68025	Central	OFF-PA-10003673	Office Supplies	Paper	Strathmore Photo Mount Cards	33.9	5	0	15.594
3939	CA-2012-118955	6/16/2014	6/20/2014	Standard Class	LS-17230	Lycoris Saunders	Consumer	United States	Grand Prairie	Texas	75051	Central	FUR-CH-10001708	Furniture	Chairs	Office Star - Contemporary Swivel Chair with Padded Adjustable Arms and Flex Back	197.372	2	0.3	-25.3764
4013	CA-2012-153612	12/22/2014	12/27/2014	Standard Class	BT-11305	Beth Thompson	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-AR-10000203	Office Supplies	Art	Newell 336	17.12	4	0	4.9648
6168	CA-2012-142433	4/20/2014	4/25/2014	Standard Class	ES-14020	Erica Smith	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10002377	Office Supplies	Paper	Xerox 1916	117.456	3	0.2	44.046
7204	CA-2011-118276	12/29/2013	1/2/2014	Standard Class	MG-17890	Michael Granlund	Home Office	United States	Saint Charles	Illinois	60174	Central	FUR-FU-10002111	Furniture	Furnishings	Master Caster Door Stop, Large Brown	8.736	3	0.6	-4.8048
915	CA-2014-102519	11/27/2016	11/29/2016	First Class	BM-11650	Brian Moss	Corporate	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10001772	Technology	Accessories	Memorex Mini Travel Drive 16 GB USB 2.0 Flash Drive	143.73	9	0	56.0547
7154	CA-2012-106208	12/10/2014	12/15/2014	Standard Class	JW-16075	Julia West	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AP-10004980	Office Supplies	Appliances	3M Replacement Filter for Office Air Cleaner for 20' x 33' Room	53.088	7	0.8	-108.8304
79	US-2011-147606	11/26/2013	12/1/2013	Second Class	JE-15745	Joel Eaton	Consumer	United States	Houston	Texas	77070	Central	FUR-FU-10003194	Furniture	Furnishings	Eldon Expressions Desk Accessory, Wood Pencil Holder, Oak	19.3	5	0.6	-14.475
4143	US-2011-107699	5/19/2013	5/23/2013	Standard Class	JH-15820	John Huston	Consumer	United States	Midland	Michigan	48640	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	57.42	9	0	26.4132
2157	CA-2011-124646	6/22/2013	6/24/2013	First Class	DV-13465	Dianna Vittorini	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-ST-10001097	Office Supplies	Storage	Office Impressions Heavy Duty Welded Shelving & Multimedia Storage Drawers	501.81	3	0	0
7789	US-2013-117037	5/18/2015	5/21/2015	First Class	LW-17215	Luke Weiss	Consumer	United States	Chicago	Illinois	60653	Central	FUR-FU-10004973	Furniture	Furnishings	Flat Face Poster Frame	22.608	3	0.6	-10.1736
255	US-2012-159982	11/28/2014	12/4/2014	Standard Class	DR-12880	Dan Reichenbach	Corporate	United States	Chicago	Illinois	60623	Central	FUR-FU-10002505	Furniture	Furnishings	Eldon 100 Class Desk Accessories	12.132	9	0.6	-8.4924
9509	CA-2011-149104	4/5/2013	4/7/2013	Second Class	RD-19900	Ruben Dartt	Consumer	United States	Dearborn Heights	Michigan	48127	Central	OFF-AR-10004685	Office Supplies	Art	Binney & Smith Crayola Metallic Colored Pencils, 8-Color Set	13.89	3	0	4.5837
7350	CA-2014-142125	10/21/2016	10/27/2016	Standard Class	JB-15400	Jennifer Braxton	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	38.82	6	0	19.41
1111	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10003589	Technology	Phones	invisibleSHIELD by ZAGG Smudge-Free Screen Protector	71.96	5	0.2	25.186
5603	CA-2013-117919	8/28/2015	8/30/2015	Second Class	TB-21355	Todd Boyes	Corporate	United States	Houston	Texas	77041	Central	OFF-ST-10003572	Office Supplies	Storage	Portfile Personal File Boxes	14.16	1	0.2	1.062
5850	CA-2012-121783	11/10/2014	11/14/2014	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Roseville	Minnesota	55113	Central	OFF-ST-10000078	Office Supplies	Storage	Tennsco 6- and 18-Compartment Lockers	795.51	3	0	143.1918
9088	CA-2013-143406	9/27/2015	10/1/2015	Standard Class	LR-17035	Lisa Ryan	Corporate	United States	Houston	Texas	77041	Central	FUR-CH-10000513	Furniture	Chairs	High-Back Leather Manager's Chair	454.965	5	0.3	-136.4895
9547	CA-2011-166590	10/29/2013	11/2/2013	Standard Class	NC-18625	Noah Childs	Corporate	United States	Columbus	Indiana	47201	Central	OFF-PA-10000482	Office Supplies	Paper	Snap-A-Way Black Print Carbonless Ruled Speed Letter, Triplicate	75.88	2	0	35.6636
7177	US-2014-141677	3/26/2016	3/30/2016	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Houston	Texas	77070	Central	OFF-ST-10000344	Office Supplies	Storage	Neat Ideas Personal Hanging Folder Files, Black	32.232	3	0.2	2.4174
8894	CA-2011-124723	8/5/2013	8/12/2013	Standard Class	GZ-14470	Gary Zandusky	Consumer	United States	Texas City	Texas	77590	Central	FUR-TA-10001307	Furniture	Tables	SAFCO PlanMaster Heigh-Adjustable Drafting Table Base, 43w x 30d x 30-37h, Black	489.23	2	0.3	41.934
3858	US-2014-105389	10/23/2016	10/28/2016	Second Class	DM-13015	Darrin Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AR-10000634	Office Supplies	Art	Newell 320	10.272	3	0.2	0.8988
8261	CA-2013-118101	6/27/2015	6/27/2015	Same Day	SN-20560	Skye Norling	Home Office	United States	Roseville	Michigan	48066	Central	OFF-BI-10000773	Office Supplies	Binders	Insertable Tab Post Binder Dividers	8.02	1	0	3.7694
6318	CA-2011-100762	11/24/2013	11/29/2013	Standard Class	NG-18355	Nat Gilpin	Corporate	United States	Jackson	Michigan	49201	Central	OFF-PA-10004082	Office Supplies	Paper	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	15.96	2	0	7.98
9776	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	FUR-FU-10004666	Furniture	Furnishings	DAX Clear Channel Poster Frame	17.496	3	0.6	-10.0602
9836	CA-2013-126627	10/11/2015	10/13/2015	First Class	WB-21850	William Brown	Consumer	United States	La Porte	Texas	77571	Central	OFF-BI-10001597	Office Supplies	Binders	Wilson Jones Ledger-Size, Piano-Hinge Binder, 2", Blue	16.392	2	0.8	-26.2272
4514	CA-2013-145240	9/7/2015	9/9/2015	First Class	BG-11740	Bruce Geld	Consumer	United States	Houston	Texas	77070	Central	OFF-ST-10001590	Office Supplies	Storage	Tenex Personal Project File with Scoop Front Design, Black	10.784	1	0.2	0.8088
9905	CA-2011-122609	11/12/2013	11/18/2013	Standard Class	DP-13000	Darren Powers	Consumer	United States	Carrollton	Texas	75007	Central	TEC-AC-10002567	Technology	Accessories	Logitech G602 Wireless Gaming Mouse	127.984	2	0.2	25.5968
6875	CA-2011-124394	10/17/2013	10/22/2013	Second Class	TB-21520	Tracy Blumstein	Consumer	United States	Beaumont	Texas	77705	Central	TEC-AC-10001314	Technology	Accessories	Case Logic 2.4GHz Wireless Keyboard	119.976	3	0.2	-17.9964
1772	CA-2013-129686	11/28/2015	11/30/2015	Second Class	GG-14650	Greg Guthrie	Corporate	United States	Chicago	Illinois	60623	Central	OFF-ST-10004337	Office Supplies	Storage	SAFCO Commercial Wire Shelving, 72h	97.984	2	0.2	-24.496
100	CA-2013-158568	8/30/2015	9/3/2015	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10003256	Office Supplies	Paper	Avery Personal Creations Heavyweight Cards	64.624	7	0.2	22.6184
8506	CA-2013-130400	3/9/2015	3/13/2015	Standard Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Dallas	Texas	75217	Central	OFF-BI-10001757	Office Supplies	Binders	Pressboard Hanging Data Binders for Unburst Sheets	8.856	9	0.8	-14.1696
76	US-2014-118038	12/9/2016	12/11/2016	First Class	KB-16600	Ken Brennan	Corporate	United States	Houston	Texas	77041	Central	OFF-BI-10004182	Office Supplies	Binders	Economy Binders	1.248	3	0.8	-1.9344
1278	CA-2013-148698	5/3/2015	5/8/2015	Standard Class	BD-11770	Bryan Davis	Consumer	United States	Houston	Texas	77070	Central	OFF-AR-10004022	Office Supplies	Art	Panasonic KP-380BK Classic Electric Pencil Sharpener	86.352	3	0.2	5.397
150	CA-2013-114489	12/6/2015	12/10/2015	Standard Class	JE-16165	Justin Ellison	Corporate	United States	Franklin	Wisconsin	53132	Central	FUR-CH-10000454	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back	1951.84	8	0	585.552
6768	CA-2014-100615	4/20/2016	4/24/2016	Standard Class	SJ-20215	Sarah Jordon	Consumer	United States	Chicago	Illinois	60653	Central	FUR-FU-10002456	Furniture	Furnishings	Master Caster Door Stop, Large Neon Orange	14.56	5	0.6	-6.188
6767	CA-2014-100615	4/20/2016	4/24/2016	Standard Class	SJ-20215	Sarah Jordon	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AR-10001683	Office Supplies	Art	Lumber Crayons	15.76	2	0.2	3.546
3233	US-2014-156356	4/16/2016	4/22/2016	Standard Class	ND-18370	Natalie DeCherney	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10001107	Office Supplies	Binders	GBC White Gloss Covers, Plain Front	2.896	1	0.8	-4.7784
2663	CA-2014-159604	4/14/2016	4/15/2016	First Class	CL-12700	Craig Leslie	Home Office	United States	Springfield	Missouri	65807	Central	OFF-BI-10003460	Office Supplies	Binders	Acco 3-Hole Punch	8.76	2	0	4.2048
3426	CA-2012-153381	9/24/2014	9/28/2014	Standard Class	DE-13255	Deanra Eno	Home Office	United States	Dubuque	Iowa	52001	Central	OFF-BI-10001525	Office Supplies	Binders	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Executive Red	15.24	4	0	6.858
3851	CA-2012-142377	12/4/2014	12/9/2014	Standard Class	MS-17980	Michael Stewart	Corporate	United States	Springfield	Missouri	65807	Central	OFF-PA-10001970	Office Supplies	Paper	Xerox 1881	85.96	7	0	40.4012
1996	US-2014-147221	12/2/2016	12/4/2016	Second Class	JS-16030	Joy Smith	Consumer	United States	Houston	Texas	77036	Central	OFF-AP-10002534	Office Supplies	Appliances	3.6 Cubic Foot Counter Height Office Refrigerator	294.62	5	0.8	-766.012
1161	CA-2014-147039	6/29/2016	7/4/2016	Standard Class	AA-10315	Alex Avila	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10004654	Office Supplies	Binders	Avery Binding System Hidden Tab Executive Style Index Sets	11.54	2	0	5.77
9627	CA-2014-103520	9/23/2016	9/25/2016	First Class	MH-17785	Maya Herman	Corporate	United States	Lubbock	Texas	79424	Central	OFF-PA-10001846	Office Supplies	Paper	Xerox 1899	9.248	2	0.2	3.3524
459	US-2013-157945	9/27/2015	10/2/2015	Standard Class	NF-18385	Natalie Fritzler	Consumer	United States	Decatur	Illinois	62521	Central	OFF-EN-10001415	Office Supplies	Envelopes	Staple envelope	8.928	2	0.2	3.348
5872	CA-2013-154235	9/25/2015	9/29/2015	Standard Class	RD-19900	Ruben Dartt	Consumer	United States	Bloomington	Indiana	47401	Central	FUR-FU-10004006	Furniture	Furnishings	Deflect-o DuraMat Lighweight, Studded, Beveled Mat for Low Pile Carpeting	127.95	3	0	21.7515
4542	US-2014-132206	6/16/2016	6/21/2016	Standard Class	MK-17905	Michael Kennedy	Corporate	United States	Chicago	Illinois	60653	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	5.936	7	0.8	-8.904
5856	CA-2012-112214	8/5/2014	8/11/2014	Standard Class	AH-10690	Anna Häberlin	Corporate	United States	Dallas	Texas	75220	Central	OFF-SU-10003567	Office Supplies	Supplies	Stiletto Hand Letter Openers	23.04	3	0.2	-4.896
9211	CA-2014-142776	12/11/2016	12/14/2016	Second Class	RS-19870	Roy Skaria	Home Office	United States	Burlington	Iowa	52601	Central	OFF-BI-10002012	Office Supplies	Binders	Wilson Jones Easy Flow II Sheet Lifters	5.4	3	0	2.592
3462	CA-2014-114258	11/5/2016	11/10/2016	Second Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Dallas	Texas	75081	Central	TEC-PH-10003012	Technology	Phones	Nortel Meridian M3904 Professional Digital phone	492.768	4	0.2	55.4364
2423	CA-2013-155551	4/19/2015	4/24/2015	Standard Class	CR-12580	Clay Rozendal	Home Office	United States	Elmhurst	Illinois	60126	Central	OFF-PA-10001560	Office Supplies	Paper	Adams Telephone Message Books, 5 1/4” x 11”	9.664	2	0.2	3.2616
5857	CA-2012-112214	8/5/2014	8/11/2014	Standard Class	AH-10690	Anna Häberlin	Corporate	United States	Dallas	Texas	75220	Central	OFF-BI-10002982	Office Supplies	Binders	Avery Self-Adhesive Photo Pockets for Polaroid Photos	1.362	1	0.8	-2.1792
8306	CA-2013-128671	8/12/2015	8/17/2015	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-PA-10001870	Office Supplies	Paper	Xerox 202	32.4	5	0	15.552
5079	CA-2014-143217	11/11/2016	11/17/2016	Standard Class	CG-12040	Catherine Glotzbach	Home Office	United States	Milwaukee	Wisconsin	53209	Central	OFF-BI-10002949	Office Supplies	Binders	Prestige Round Ring Binders	18.24	3	0	8.5728
3662	CA-2013-155005	6/14/2015	6/16/2015	Second Class	SC-20050	Sample Company A	Home Office	United States	Jackson	Michigan	49201	Central	TEC-PH-10003484	Technology	Phones	Ooma Telo VoIP Home Phone System	377.97	3	0	94.4925
5805	CA-2014-113873	11/13/2016	11/19/2016	Standard Class	KE-16420	Katrina Edelman	Corporate	United States	Dallas	Texas	75220	Central	OFF-ST-10000943	Office Supplies	Storage	Eldon ProFile File 'N Store Portable File Tub Letter/Legal Size Black	61.792	4	0.2	6.1792
2035	CA-2014-162481	9/25/2016	9/29/2016	Standard Class	CT-11995	Carol Triggs	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-BI-10002976	Office Supplies	Binders	ACCOHIDE Binder by Acco	8.26	2	0	3.8822
3723	CA-2014-144036	11/22/2016	11/26/2016	Standard Class	FO-14305	Frank Olsen	Consumer	United States	Houston	Texas	77070	Central	OFF-AR-10000122	Office Supplies	Art	Newell 314	35.712	8	0.2	2.232
8915	US-2013-144057	5/10/2015	5/14/2015	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Austin	Texas	78745	Central	OFF-ST-10001490	Office Supplies	Storage	Hot File 7-Pocket, Floor Stand	856.656	6	0.2	107.082
3853	CA-2014-130526	11/26/2016	11/29/2016	First Class	GT-14755	Guy Thornton	Consumer	United States	Rockford	Illinois	61107	Central	OFF-BI-10001524	Office Supplies	Binders	GBC Premium Transparent Covers with Diagonal Lined Pattern	33.568	8	0.8	-53.7088
1577	CA-2013-109057	4/23/2015	4/28/2015	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Aurora	Illinois	60505	Central	OFF-ST-10002406	Office Supplies	Storage	Pizazz Global Quick File	23.952	2	0.2	2.3952
8518	CA-2014-149720	6/4/2016	6/7/2016	Second Class	EM-14065	Erin Mull	Consumer	United States	Frisco	Texas	75034	Central	FUR-FU-10002501	Furniture	Furnishings	Nu-Dell Executive Frame	30.336	6	0.6	-17.4432
8918	US-2013-144057	5/10/2015	5/14/2015	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Austin	Texas	78745	Central	OFF-PA-10004327	Office Supplies	Paper	Xerox 1911	76.64	2	0.2	26.824
3930	CA-2013-162082	3/15/2015	3/18/2015	First Class	JS-15880	John Stevenson	Consumer	United States	Harlingen	Texas	78550	Central	OFF-PA-10001934	Office Supplies	Paper	Xerox 1993	5.184	1	0.2	1.8792
9391	CA-2012-163734	6/19/2014	6/24/2014	Standard Class	KM-16375	Katherine Murray	Home Office	United States	Houston	Texas	77070	Central	OFF-ST-10003692	Office Supplies	Storage	Recycled Steel Personal File for Hanging File Folders	228.92	5	0.2	14.3075
2373	CA-2013-159940	7/8/2015	7/12/2015	Second Class	BF-11020	Barry Französisch	Corporate	United States	Aurora	Illinois	60505	Central	OFF-FA-10000936	Office Supplies	Fasteners	Acco Hot Clips Clips to Go	2.632	1	0.2	0.8225
549	CA-2012-113173	11/15/2014	11/17/2014	Second Class	DK-13225	Dean Katz	Corporate	United States	Chicago	Illinois	60653	Central	OFF-ST-10000604	Office Supplies	Storage	Home/Office Personal File Carts	250.272	9	0.2	15.642
6652	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	FUR-FU-10001095	Furniture	Furnishings	DAX Black Cherry Wood-Tone Poster Frame	21.184	2	0.6	-11.6512
9163	CA-2013-160108	12/9/2015	12/13/2015	Standard Class	AG-10900	Arthur Gainer	Consumer	United States	Eau Claire	Wisconsin	54703	Central	FUR-CH-10002335	Furniture	Chairs	Hon GuestStacker Chair	680.01	3	0	176.8026
3062	CA-2014-127621	3/3/2016	3/7/2016	Standard Class	RE-19450	Richard Eichhorn	Consumer	United States	Dallas	Texas	75081	Central	OFF-PA-10001307	Office Supplies	Paper	Important Message Pads, 50 4-1/4 x 5-1/2 Forms per Pad	26.88	8	0.2	9.744
2852	CA-2014-107342	12/17/2016	12/22/2016	Standard Class	VF-21715	Vicky Freymann	Home Office	United States	Columbus	Indiana	47201	Central	OFF-PA-10001745	Office Supplies	Paper	Wirebound Message Books, 2 7/8" x 5", 3 Forms per Page	28.16	4	0	13.2352
3495	CA-2014-142034	9/24/2016	9/28/2016	Standard Class	KB-16240	Karen Bern	Corporate	United States	Saint Cloud	Minnesota	56301	Central	TEC-AC-10000990	Technology	Accessories	Imation Bio 2GB USB Flash Drive Imation Corp	655.9	5	0	275.478
3951	CA-2013-119963	11/19/2015	11/23/2015	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Pasadena	Texas	77506	Central	FUR-CH-10003817	Furniture	Chairs	Global Value Steno Chair, Gray	255.108	6	0.3	-18.222
7558	CA-2014-159506	11/27/2016	12/2/2016	Standard Class	JR-16210	Justin Ritter	Corporate	United States	Columbus	Indiana	47201	Central	OFF-BI-10004519	Office Supplies	Binders	GBC DocuBind P100 Manual Binding Machine	497.94	3	0	224.073
1271	US-2013-103646	4/22/2015	4/27/2015	Standard Class	SP-20545	Sibella Parks	Corporate	United States	Chicago	Illinois	60623	Central	OFF-ST-10000563	Office Supplies	Storage	Fellowes Bankers Box Stor/Drawer Steel Plus	102.336	4	0.2	-12.792
3865	CA-2012-157133	11/28/2014	12/3/2014	Standard Class	LC-16885	Lena Creighton	Consumer	United States	Champaign	Illinois	61821	Central	FUR-FU-10004904	Furniture	Furnishings	Eldon "L" Workstation Diamond Chairmat	151.96	5	0.6	-182.352
6794	CA-2012-145394	11/16/2014	11/20/2014	Standard Class	MC-17605	Matt Connell	Corporate	United States	Chicago	Illinois	60610	Central	OFF-ST-10000344	Office Supplies	Storage	Neat Ideas Personal Hanging Folder Files, Black	21.488	2	0.2	1.6116
9312	CA-2014-148642	3/6/2016	3/12/2016	Standard Class	DW-13540	Don Weiss	Consumer	United States	Dallas	Texas	75220	Central	OFF-LA-10000134	Office Supplies	Labels	Avery 511	4.928	2	0.2	1.7248
8117	CA-2014-105543	11/24/2016	11/24/2016	Same Day	BG-11695	Brooke Gillingham	Corporate	United States	Garden City	Kansas	67846	Central	OFF-ST-10003123	Office Supplies	Storage	Fellowes Bases and Tops For Staxonsteel/High-Stak Systems	33.29	1	0	7.9896
9495	CA-2013-105207	1/3/2015	1/8/2015	Standard Class	BO-11350	Bill Overfelt	Corporate	United States	Broken Arrow	Oklahoma	74012	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	11.88	2	0	5.346
7446	CA-2014-127474	2/4/2016	2/8/2016	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10001033	Office Supplies	Paper	Xerox 1893	65.584	2	0.2	23.7742
6193	CA-2014-104927	12/22/2016	12/26/2016	Standard Class	AG-10330	Alex Grayson	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000019	Office Supplies	Paper	Xerox 1931	25.92	5	0.2	9.072
9258	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	FUR-FU-10002298	Furniture	Furnishings	Rubbermaid ClusterMat Chairmats, Mat Size- 66" x 60", Lip 20" x 11" -90 Degree Angle	332.94	3	0	53.2704
188	CA-2013-157000	7/17/2015	7/23/2015	Standard Class	AM-10360	Alice McCarthy	Corporate	United States	Grand Prairie	Texas	75051	Central	OFF-ST-10001328	Office Supplies	Storage	Personal Filing Tote with Lid, Black/Gray	37.224	3	0.2	3.7224
8010	CA-2012-110863	11/17/2014	11/24/2014	Standard Class	AA-10645	Anna Andreadi	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	FUR-CH-10002073	Furniture	Chairs	Hon Olson Stacker Chairs	1323.9	5	0	383.931
9500	CA-2014-118213	11/5/2016	11/7/2016	First Class	AB-10060	Adam Bellavance	Home Office	United States	Greenwood	Indiana	46142	Central	OFF-PA-10003673	Office Supplies	Paper	Strathmore Photo Mount Cards	67.8	10	0	31.188
6830	CA-2013-118689	10/3/2015	10/10/2015	Standard Class	TC-20980	Tamara Chand	Corporate	United States	Lafayette	Indiana	47905	Central	OFF-AR-10001958	Office Supplies	Art	Stanley Bostitch Contemporary Electric Pencil Sharpeners	33.96	2	0	9.5088
1988	CA-2012-127509	11/9/2014	11/13/2014	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	OFF-BI-10002393	Office Supplies	Binders	Binder Posts	17.22	3	0	7.9212
5979	CA-2011-117765	9/7/2013	9/13/2013	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Tulsa	Oklahoma	74133	Central	FUR-TA-10001039	Furniture	Tables	KI Adjustable-Height Table	429.9	5	0	111.774
4834	CA-2011-120278	11/7/2013	11/12/2013	Standard Class	MS-17365	Maribeth Schnelling	Consumer	United States	Wausau	Wisconsin	54401	Central	OFF-BI-10004970	Office Supplies	Binders	ACCOHIDE 3-Ring Binder, Blue, 1"	12.39	3	0	5.8233
9675	US-2011-164644	7/22/2013	7/24/2013	Second Class	JL-15850	John Lucas	Consumer	United States	Houston	Texas	77095	Central	OFF-ST-10003123	Office Supplies	Storage	Fellowes Bases and Tops For Staxonsteel/High-Stak Systems	26.632	1	0.2	1.3316
6649	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	OFF-BI-10002429	Office Supplies	Binders	Premier Elliptical Ring Binder, Black	42.616	7	0.8	-68.1856
3655	CA-2014-133004	8/31/2016	9/5/2016	Standard Class	AJ-10945	Ashley Jarboe	Consumer	United States	Lawrence	Indiana	46226	Central	OFF-AP-10002439	Office Supplies	Appliances	Tripp Lite Isotel 8 Ultra 8 Outlet Metal Surge	638.73	9	0	166.0698
4071	CA-2013-145303	8/29/2015	9/1/2015	First Class	TP-21415	Tom Prescott	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10002414	Office Supplies	Binders	GBC ProClick Spines for 32-Hole Punch	10.024	4	0.8	-16.5396
6900	US-2012-165512	5/24/2014	5/26/2014	Second Class	VS-21820	Vivek Sundaresam	Consumer	United States	Naperville	Illinois	60540	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	7.656	6	0.8	-13.0152
551	CA-2012-113173	11/15/2014	11/17/2014	Second Class	DK-13225	Dean Katz	Corporate	United States	Chicago	Illinois	60653	Central	OFF-SU-10001935	Office Supplies	Supplies	Staple remover	8.72	5	0.2	-1.744
2899	US-2012-114839	4/26/2014	4/30/2014	Standard Class	PW-19240	Pierre Wener	Consumer	United States	Houston	Texas	77036	Central	FUR-CH-10004086	Furniture	Chairs	Hon 4070 Series Pagoda Armless Upholstered Stacking Chairs	408.422	2	0.3	-5.8346
1800	CA-2013-121034	8/9/2015	8/11/2015	Second Class	JF-15565	Jill Fjeld	Consumer	United States	Dallas	Texas	75081	Central	OFF-FA-10000585	Office Supplies	Fasteners	OIC Bulk Pack Metal Binder Clips	11.168	4	0.2	3.6296
1851	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	TEC-AC-10002253	Technology	Accessories	Imation Bio 8GB USB Flash Drive Imation Corp	831.2	5	0	124.68
439	CA-2014-130043	9/15/2016	9/19/2016	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Houston	Texas	77070	Central	OFF-PA-10002230	Office Supplies	Paper	Xerox 1897	31.872	8	0.2	11.5536
4921	CA-2014-101728	8/19/2016	8/23/2016	Standard Class	SC-20575	Sonia Cooley	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10002393	Office Supplies	Binders	Binder Posts	2.296	2	0.8	-3.9032
2648	CA-2011-131002	9/7/2013	9/12/2013	Second Class	TB-21400	Tom Boeckenhauer	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-PA-10000223	Office Supplies	Paper	Xerox 2000	12.96	2	0	6.2208
2059	CA-2014-120376	12/22/2016	12/25/2016	First Class	TP-21130	Theone Pippenger	Consumer	United States	Detroit	Michigan	48227	Central	FUR-TA-10004534	Furniture	Tables	Bevis 44 x 96 Conference Tables	411.8	2	0	70.006
2239	CA-2014-166849	4/20/2016	4/26/2016	Standard Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Chicago	Illinois	60610	Central	FUR-FU-10004597	Furniture	Furnishings	Eldon Cleatmat Chair Mats for Medium Pile Carpets	44.4	2	0.6	-52.17
4700	CA-2014-140298	5/11/2016	5/17/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Austin	Texas	78745	Central	OFF-AR-10003481	Office Supplies	Art	Newell 348	5.248	2	0.2	0.5904
2788	US-2011-117744	12/2/2013	12/6/2013	Standard Class	MD-17860	Michael Dominguez	Corporate	United States	Corpus Christi	Texas	78415	Central	FUR-FU-10001588	Furniture	Furnishings	Deflect-o SuperTray Unbreakable Stackable Tray, Letter, Black	58.36	5	0.6	-24.803
5095	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	FUR-TA-10004086	Furniture	Tables	KI Adjustable-Height Table	214.95	5	0.5	-120.372
345	US-2012-120712	12/20/2014	12/24/2014	Standard Class	CS-12130	Chad Sievert	Consumer	United States	Austin	Texas	78745	Central	OFF-ST-10000107	Office Supplies	Storage	Fellowes Super Stor/Drawer	88.8	4	0.2	-2.22
6317	CA-2011-100762	11/24/2013	11/29/2013	Standard Class	NG-18355	Nat Gilpin	Corporate	United States	Jackson	Michigan	49201	Central	OFF-PA-10001815	Office Supplies	Paper	Xerox 1885	144.12	3	0	69.1776
400	CA-2013-108987	9/9/2015	9/11/2015	Second Class	AG-10675	Anna Gayman	Consumer	United States	Houston	Texas	77036	Central	FUR-BO-10004834	Furniture	Bookcases	Riverside Palais Royal Lawyers Bookcase, Royale Cherry Finish	2396.2656	4	0.32	-317.1528
9146	CA-2012-126970	9/20/2014	9/24/2014	Standard Class	TP-21130	Theone Pippenger	Consumer	United States	Naperville	Illinois	60540	Central	OFF-BI-10000138	Office Supplies	Binders	Acco Translucent Poly Ring Binders	2.808	3	0.8	-4.4928
9378	CA-2014-155362	12/17/2016	12/21/2016	Standard Class	DP-13105	Dave Poirier	Corporate	United States	Eau Claire	Wisconsin	54703	Central	OFF-ST-10001031	Office Supplies	Storage	Adjustable Personal File Tote	32.56	2	0	8.4656
6023	CA-2011-130869	11/17/2013	11/21/2013	Standard Class	CB-12025	Cassandra Brandow	Consumer	United States	Cedar Hill	Texas	75104	Central	OFF-EN-10002600	Office Supplies	Envelopes	Redi-Strip #10 Envelopes, 4 1/8 x 9 1/2	7.08	3	0.2	2.478
8605	US-2013-116365	1/3/2015	1/8/2015	Standard Class	CA-12310	Christine Abelman	Corporate	United States	San Antonio	Texas	78207	Central	TEC-AC-10002942	Technology	Accessories	WD My Passport Ultra 1TB Portable External Hard Drive	165.6	3	0.2	-6.21
5243	CA-2014-146367	8/4/2016	8/8/2016	Standard Class	HM-14860	Harry Marie	Corporate	United States	Carrollton	Texas	75007	Central	OFF-BI-10002827	Office Supplies	Binders	Avery Durable Poly Binders	3.318	3	0.8	-5.6406
7071	CA-2013-164490	9/6/2015	9/11/2015	Second Class	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60653	Central	OFF-PA-10004971	Office Supplies	Paper	Xerox 196	9.248	2	0.2	3.3524
6777	US-2013-152373	9/6/2015	9/12/2015	Standard Class	PT-19090	Pete Takahito	Consumer	United States	San Antonio	Texas	78207	Central	OFF-ST-10003479	Office Supplies	Storage	Eldon Base for stackable storage shelf, platinum	93.456	3	0.2	-17.523
3897	CA-2014-134285	12/7/2016	12/12/2016	Standard Class	DS-13180	David Smith	Corporate	United States	San Antonio	Texas	78207	Central	OFF-FA-10000611	Office Supplies	Fasteners	Binder Clips by OIC	3.552	3	0.2	1.2432
8621	US-2014-119319	11/6/2016	11/9/2016	Second Class	LC-17050	Liz Carlisle	Consumer	United States	Dallas	Texas	75217	Central	FUR-FU-10003878	Furniture	Furnishings	Linden 10" Round Wall Clock, Black	30.56	5	0.6	-19.864
2084	CA-2011-110352	11/23/2013	11/29/2013	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77036	Central	OFF-LA-10003923	Office Supplies	Labels	Alphabetical Labels for Top Tab Filing	23.68	2	0.2	8.88
4917	CA-2014-163125	10/9/2016	10/11/2016	Second Class	MB-17305	Maria Bertelson	Consumer	United States	League City	Texas	77573	Central	OFF-AR-10004344	Office Supplies	Art	Bulldog Vacuum Base Pencil Sharpener	67.144	7	0.2	5.8751
4142	CA-2013-136287	6/14/2015	6/18/2015	Standard Class	SS-20590	Sonia Sunley	Consumer	United States	Wichita	Kansas	67212	Central	OFF-LA-10003148	Office Supplies	Labels	Avery 51	18.9	3	0	8.694
167	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-ST-10000991	Office Supplies	Storage	Space Solutions HD Industrial Steel Shelving.	275.928	3	0.2	-58.6347
2769	US-2012-122140	4/2/2014	4/7/2014	Standard Class	MO-17950	Michael Oakman	Consumer	United States	Dallas	Texas	75220	Central	OFF-AP-10001242	Office Supplies	Appliances	APC 7 Outlet Network SurgeArrest Surge Protector	32.192	2	0.8	-80.48
550	CA-2012-113173	11/15/2014	11/17/2014	Second Class	DK-13225	Dean Katz	Corporate	United States	Chicago	Illinois	60653	Central	OFF-BI-10004738	Office Supplies	Binders	Flexible Leather- Look Classic Collection Ring Binder	11.364	3	0.8	-17.046
4101	US-2014-102288	6/19/2016	6/23/2016	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77095	Central	OFF-AP-10004655	Office Supplies	Appliances	Holmes Visible Mist Ultrasonic Humidifier with 2.3-Gallon Output per Day, Replacement Filter	2.264	1	0.8	-5.2072
7595	CA-2014-119655	4/20/2016	4/24/2016	Standard Class	CV-12295	Christina VanderZanden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-BI-10001989	Office Supplies	Binders	Premium Transparent Presentation Covers by GBC	146.86	7	0	70.4928
5029	CA-2011-151792	9/2/2013	9/7/2013	Second Class	CV-12295	Christina VanderZanden	Consumer	United States	Chicago	Illinois	60653	Central	TEC-AC-10001606	Technology	Accessories	Logitech Wireless Performance Mouse MX for PC and Mac	239.976	3	0.2	53.9946
5372	US-2014-136721	4/8/2016	4/12/2016	Standard Class	NH-18610	Nicole Hansen	Corporate	United States	Oak Park	Michigan	48237	Central	FUR-FU-10004188	Furniture	Furnishings	Luxo Professional Combination Clamp-On Lamps	306.9	3	0	79.794
8114	CA-2013-130393	12/2/2015	12/4/2015	Second Class	JM-15865	John Murray	Consumer	United States	San Angelo	Texas	76903	Central	FUR-CH-10004477	Furniture	Chairs	Global Push Button Manager's Chair, Indigo	85.246	2	0.3	-1.2178
427	CA-2014-149160	11/23/2016	11/26/2016	Second Class	JM-15265	Janet Molinari	Corporate	United States	Canton	Michigan	48187	Central	OFF-BI-10001543	Office Supplies	Binders	GBC VeloBinder Manual Binding System	287.92	8	0	138.2016
6741	CA-2011-144029	5/26/2013	5/31/2013	Standard Class	MM-18055	Michelle Moray	Consumer	United States	Chicago	Illinois	60623	Central	FUR-CH-10003981	Furniture	Chairs	Global Commerce Series Low-Back Swivel/Tilt Chairs	359.772	2	0.3	-5.1396
6454	CA-2012-125710	10/8/2014	10/13/2014	Standard Class	BT-11680	Brian Thompson	Consumer	United States	Houston	Texas	77036	Central	OFF-AR-10000657	Office Supplies	Art	Binney & Smith inkTank Desk Highlighter, Chisel Tip, Yellow, 12/Box	3.44	2	0.2	0.559
7383	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-SU-10004782	Office Supplies	Supplies	Elite 5" Scissors	16.9	2	0	5.07
8317	CA-2011-161508	7/12/2013	7/16/2013	Standard Class	PV-18985	Paul Van Hugh	Home Office	United States	League City	Texas	77573	Central	OFF-PA-10001804	Office Supplies	Paper	Xerox 195	16.032	3	0.2	5.6112
8664	CA-2012-131856	5/12/2014	5/17/2014	Standard Class	JG-15160	James Galang	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10001954	Office Supplies	Paper	Xerox 1964	127.904	7	0.2	41.5688
4832	CA-2011-120278	11/7/2013	11/12/2013	Standard Class	MS-17365	Maribeth Schnelling	Consumer	United States	Wausau	Wisconsin	54401	Central	OFF-ST-10004258	Office Supplies	Storage	Portable Personal File Box	36.63	3	0	9.8901
7782	CA-2012-132136	3/8/2014	3/12/2014	Standard Class	FO-14305	Frank Olsen	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10002706	Office Supplies	Binders	Avery Premier Heavy-Duty Binder with Round Locking Rings	8.568	3	0.8	-14.5656
9078	US-2011-124625	11/3/2013	11/7/2013	Standard Class	SP-20650	Stephanie Phelps	Corporate	United States	Omaha	Nebraska	68104	Central	TEC-AC-10003280	Technology	Accessories	Belkin F8E887 USB Wired Ergonomic Keyboard	89.97	3	0	18.8937
1137	CA-2013-152170	11/13/2015	11/16/2015	Second Class	FH-14275	Frank Hawley	Corporate	United States	La Porte	Indiana	46350	Central	OFF-EN-10002831	Office Supplies	Envelopes	Tyvek  Top-Opening Peel & Seel  Envelopes, Gray	287.52	8	0	129.384
4744	CA-2014-168123	3/5/2016	3/5/2016	Same Day	JD-16060	Julia Dunbar	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-FA-10002763	Office Supplies	Fasteners	Advantus Map Pennant Flags and Round Head Tacks	7.9	2	0	2.528
2007	CA-2011-111150	12/31/2013	1/4/2014	Standard Class	RW-19630	Rob Williams	Corporate	United States	Columbia	Missouri	65203	Central	TEC-AC-10000290	Technology	Accessories	Sabrent 4-Port USB 2.0 Hub	47.53	7	0	16.1602
9208	CA-2014-140781	8/3/2016	8/7/2016	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Bloomington	Illinois	61701	Central	TEC-AC-10000682	Technology	Accessories	Kensington K72356US Mouse-in-a-Box USB Desktop Mouse	39.816	3	0.2	7.4655
3781	CA-2011-149643	11/16/2013	11/20/2013	Standard Class	RH-19510	Rick Huthwaite	Home Office	United States	Manhattan	Kansas	66502	Central	TEC-PH-10000038	Technology	Phones	Jawbone MINI JAMBOX Wireless Bluetooth Speaker	273.96	2	0	10.9584
3359	CA-2013-139234	5/7/2015	5/11/2015	Standard Class	AF-10870	Art Ferguson	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10000773	Office Supplies	Binders	Insertable Tab Post Binder Dividers	3.208	2	0.8	-5.2932
5531	CA-2014-160885	12/2/2016	12/6/2016	Standard Class	JK-16090	Juliana Krohn	Consumer	United States	Omaha	Nebraska	68104	Central	TEC-PH-10001795	Technology	Phones	ClearOne CHATAttach 160 - speaker phone	2479.96	4	0	743.988
9486	CA-2013-164770	12/3/2015	12/5/2015	Second Class	MY-18295	Muhammed Yedwab	Corporate	United States	Houston	Texas	77036	Central	OFF-PA-10003893	Office Supplies	Paper	Xerox 1962	30.816	9	0.2	9.63
6622	US-2014-167402	1/14/2016	1/19/2016	Second Class	CP-12085	Cathy Prescott	Corporate	United States	Springfield	Missouri	65807	Central	FUR-BO-10001608	Furniture	Bookcases	Hon Metal Bookcases, Black	212.94	3	0	53.235
4373	US-2014-169320	7/23/2016	7/25/2016	Second Class	LH-16900	Lena Hernandez	Consumer	United States	Elkhart	Indiana	46514	Central	OFF-AR-10003602	Office Supplies	Art	Quartet Omega Colored Chalk, 12/Pack	11.68	2	0	5.4896
3097	CA-2012-114468	8/23/2014	8/23/2014	Same Day	TD-20995	Tamara Dahlen	Consumer	United States	Bolingbrook	Illinois	60440	Central	OFF-AP-10000696	Office Supplies	Appliances	Holmes Odor Grabber	5.768	2	0.8	-13.5548
579	CA-2014-118640	7/20/2016	7/26/2016	Standard Class	CS-11950	Carlos Soltero	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10002974	Office Supplies	Storage	Trav-L-File Heavy-Duty Shuttle II, Black	69.712	2	0.2	8.714
5802	CA-2011-123225	7/11/2013	7/14/2013	First Class	MN-17935	Michael Nguyen	Consumer	United States	El Paso	Texas	79907	Central	OFF-PA-10000552	Office Supplies	Paper	Xerox 200	10.368	2	0.2	3.6288
1912	CA-2014-121503	7/3/2016	7/6/2016	Second Class	FH-14275	Frank Hawley	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10001878	Office Supplies	Paper	Xerox 1891	273.896	7	0.2	92.4399
401	CA-2013-108987	9/9/2015	9/11/2015	Second Class	AG-10675	Anna Gayman	Consumer	United States	Houston	Texas	77036	Central	OFF-ST-10000934	Office Supplies	Storage	Contico 72"H Heavy-Duty Storage System	131.136	4	0.2	-32.784
1664	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	OFF-ST-10001325	Office Supplies	Storage	Sterilite Officeware Hinged File Box	41.92	5	0.2	3.668
660	CA-2012-146563	8/24/2014	8/28/2014	Standard Class	CB-12025	Cassandra Brandow	Consumer	United States	Arlington	Texas	76017	Central	OFF-ST-10001490	Office Supplies	Storage	Hot File 7-Pocket, Floor Stand	999.432	7	0.2	124.929
2609	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	OFF-LA-10001317	Office Supplies	Labels	Avery 520	2.52	1	0.2	0.882
2236	CA-2012-145849	9/15/2014	9/17/2014	Second Class	CT-11995	Carol Triggs	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-ST-10000025	Office Supplies	Storage	Fellowes Stor/Drawer Steel Plus Storage Drawers	190.86	2	0	11.4516
8982	CA-2013-110898	3/7/2015	3/13/2015	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AP-10001626	Office Supplies	Appliances	Commercial WindTunnel Clean Air Upright Vacuum, Replacement Belts, Filtration Bags	2.334	3	0.8	-6.3018
5698	CA-2014-126123	10/14/2016	10/18/2016	Standard Class	AG-10765	Anthony Garverick	Home Office	United States	Chicago	Illinois	60623	Central	OFF-BI-10004224	Office Supplies	Binders	Catalog Binders with Expanding Posts	13.456	1	0.8	-23.548
9962	CA-2012-168088	3/19/2014	3/22/2014	First Class	CM-12655	Corinna Mitchell	Home Office	United States	Houston	Texas	77041	Central	OFF-PA-10000675	Office Supplies	Paper	Xerox 1919	65.584	2	0.2	23.7742
384	CA-2012-125395	6/26/2014	6/29/2014	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Taylor	Michigan	48180	Central	TEC-AC-10004708	Technology	Accessories	Sony 32GB Class 10 Micro SDHC R40 Memory Card	41.9	2	0	8.799
2791	CA-2011-125514	9/21/2013	9/22/2013	First Class	BM-11650	Brian Moss	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-AP-10000358	Office Supplies	Appliances	Fellowes Basic Home/Office Series Surge Protectors	25.96	2	0	7.5284
892	CA-2014-133256	6/26/2016	6/27/2016	First Class	TH-21550	Tracy Hopkins	Home Office	United States	Detroit	Michigan	48227	Central	OFF-PA-10001622	Office Supplies	Paper	Ampad Poly Cover Wirebound Steno Book, 6" x 9" Assorted Colors, Gregg Ruled	4.54	1	0	2.043
4211	CA-2014-109715	12/9/2016	12/14/2016	Standard Class	AH-10585	Angele Hood	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10004965	Office Supplies	Paper	Xerox 1921	15.984	2	0.2	4.995
7549	CA-2011-103492	10/10/2013	10/15/2013	Standard Class	CM-12715	Craig Molinari	Corporate	United States	Huntsville	Texas	77340	Central	OFF-BI-10004140	Office Supplies	Binders	Avery Non-Stick Binders	0.898	1	0.8	-1.5715
5188	CA-2012-115567	9/13/2014	9/18/2014	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Columbus	Indiana	47201	Central	TEC-AC-10001314	Technology	Accessories	Case Logic 2.4GHz Wireless Keyboard	199.96	4	0	15.9968
2137	CA-2012-156377	12/31/2014	1/5/2015	Standard Class	TB-21625	Trudy Brown	Consumer	United States	Grand Prairie	Texas	75051	Central	FUR-FU-10002364	Furniture	Furnishings	Eldon Expressions Wood Desk Accessories, Oak	14.76	5	0.6	-11.439
6303	CA-2014-166919	11/23/2016	11/27/2016	Standard Class	AH-10210	Alan Hwang	Consumer	United States	Dallas	Texas	75220	Central	TEC-PH-10001305	Technology	Phones	Panasonic KX TS208W Corded phone	195.96	5	0.2	19.596
7297	CA-2011-111899	5/4/2013	5/5/2013	First Class	NC-18340	Nat Carroll	Consumer	United States	Houston	Texas	77036	Central	OFF-FA-10000840	Office Supplies	Fasteners	OIC Thumb-Tacks	5.472	6	0.2	1.8468
2883	CA-2011-165540	2/21/2013	2/25/2013	Standard Class	TM-21010	Tamara Manning	Consumer	United States	Woodstock	Illinois	60098	Central	OFF-BI-10004094	Office Supplies	Binders	GBC Standard Plastic Binding Systems Combs	8.85	5	0.8	-13.7175
7547	CA-2011-103492	10/10/2013	10/15/2013	Standard Class	CM-12715	Craig Molinari	Corporate	United States	Huntsville	Texas	77340	Central	TEC-PH-10004667	Technology	Phones	Cisco 8x8 Inc. 6753i IP Business Phone System	755.944	7	0.2	66.1451
5542	US-2014-150595	5/22/2016	5/26/2016	Standard Class	LE-16810	Laurel Elliston	Consumer	United States	Chicago	Illinois	60653	Central	OFF-SU-10000381	Office Supplies	Supplies	Acme Forged Steel Scissors with Black Enamel Handles	22.344	3	0.2	2.5137
2650	CA-2011-131002	9/7/2013	9/12/2013	Second Class	TB-21400	Tom Boeckenhauer	Consumer	United States	Tulsa	Oklahoma	74133	Central	TEC-PH-10000215	Technology	Phones	Plantronics Cordless Phone Headset with In-line Volume - M214C	104.85	3	0	28.3095
5138	CA-2013-128972	11/14/2015	11/18/2015	Standard Class	TS-21430	Tom Stivers	Corporate	United States	Oklahoma City	Oklahoma	73120	Central	FUR-FU-10003096	Furniture	Furnishings	Master Giant Foot Doorstop, Safety Yellow	30.36	4	0	13.0548
145	CA-2014-155376	12/22/2016	12/27/2016	Standard Class	SG-20080	Sandra Glassco	Consumer	United States	Independence	Missouri	64055	Central	OFF-AP-10001058	Office Supplies	Appliances	Sanyo 2.5 Cubic Foot Mid-Size Office Refrigerators	839.43	3	0	218.2518
5344	US-2011-168501	11/21/2013	11/27/2013	Standard Class	JK-15325	Jason Klamczynski	Corporate	United States	Dallas	Texas	75220	Central	TEC-PH-10004922	Technology	Phones	RCA Visys Integrated PBX 8-Line Router	267.96	5	0.2	16.7475
3326	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10001267	Office Supplies	Binders	Universal Recycled Hanging Pressboard Report Binders, Letter Size	1.234	1	0.8	-1.9744
3240	US-2013-127971	11/21/2015	11/28/2015	Standard Class	DW-13195	David Wiener	Corporate	United States	Houston	Texas	77095	Central	TEC-PH-10003095	Technology	Phones	Samsung HM1900 Bluetooth Headset	122.92	7	0.2	46.095
5852	CA-2012-121783	11/10/2014	11/14/2014	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Roseville	Minnesota	55113	Central	OFF-BI-10001658	Office Supplies	Binders	GBC Standard Therm-A-Bind Covers	74.76	3	0	34.3896
3187	CA-2011-123498	11/7/2013	11/9/2013	First Class	TC-20980	Tamara Chand	Corporate	United States	Houston	Texas	77041	Central	OFF-EN-10004773	Office Supplies	Envelopes	Staple envelope	74.352	3	0.2	26.9526
7625	CA-2012-136805	5/23/2014	5/27/2014	Second Class	NM-18445	Nathan Mautz	Home Office	United States	Detroit	Michigan	48234	Central	OFF-AP-10001394	Office Supplies	Appliances	Harmony Air Purifier	850.5	5	0.1	245.7
6082	US-2011-165589	2/18/2013	2/18/2013	Same Day	TB-21595	Troy Blackwell	Consumer	United States	Lubbock	Texas	79424	Central	FUR-FU-10002396	Furniture	Furnishings	DAX Copper Panel Document Frame, 5 x 7 Size	25.16	5	0.6	-11.322
2928	CA-2014-158106	6/4/2016	6/10/2016	Standard Class	CT-11995	Carol Triggs	Consumer	United States	Apple Valley	Minnesota	55124	Central	OFF-AR-10002255	Office Supplies	Art	Newell 346	8.64	3	0	2.5056
2917	CA-2012-134747	10/12/2014	10/17/2014	Second Class	DL-12925	Daniel Lacy	Consumer	United States	Noblesville	Indiana	46060	Central	TEC-PH-10001750	Technology	Phones	Samsung Rugby III	263.96	4	0	71.2692
622	US-2011-111171	12/26/2013	12/31/2013	Standard Class	CA-12265	Christina Anderson	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10002103	Office Supplies	Binders	Cardinal Slant-D Ring Binder, Heavy Gauge Vinyl	8.69	5	0.8	-14.773
9477	CA-2012-100818	5/31/2014	6/5/2014	Second Class	JM-15265	Janet Molinari	Corporate	United States	Chicago	Illinois	60653	Central	FUR-FU-10002703	Furniture	Furnishings	Tenex Traditional Chairmats for Hard Floors, Average Lip, 36" x 48"	51.56	2	0.6	-61.872
3860	CA-2014-154039	2/18/2016	2/23/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Chicago	Illinois	60653	Central	FUR-TA-10001932	Furniture	Tables	Chromcraft 48" x 96" Racetrack Double Pedestal Table	480.96	3	0.5	-269.3376
7215	CA-2012-103072	9/27/2014	9/30/2014	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Detroit	Michigan	48205	Central	OFF-AR-10000127	Office Supplies	Art	Newell 321	16.4	5	0	4.756
3998	CA-2012-105627	3/8/2014	3/12/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Kenosha	Wisconsin	53142	Central	OFF-AR-10002704	Office Supplies	Art	Boston 1900 Electric Pencil Sharpener	14.98	1	0	4.494
1200	CA-2013-130946	4/9/2015	4/13/2015	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10004995	Office Supplies	Binders	GBC DocuBind P400 Electric Binding System	1088.792	4	0.8	-1850.9464
520	CA-2012-157812	3/22/2014	3/26/2014	Standard Class	DB-13210	Dean Braden	Consumer	United States	Houston	Texas	77041	Central	TEC-AC-10000171	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 25/Pack	18.392	1	0.2	5.2877
1151	CA-2012-112452	4/4/2014	4/4/2014	Same Day	NC-18340	Nat Carroll	Consumer	United States	Lansing	Michigan	48911	Central	TEC-CO-10004202	Technology	Copiers	Brother DCP1000 Digital 3 in 1 Multifunction Machine	599.98	2	0	209.993
5511	US-2014-152569	5/15/2016	5/20/2016	Standard Class	JD-16015	Joy Daniels	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10002185	Technology	Phones	QVS USB Car Charger 2-Port 2.1Amp for iPod/iPhone/iPad/iPad 2/iPad 3	11.12	2	0.2	3.475
521	CA-2012-157812	3/22/2014	3/26/2014	Standard Class	DB-13210	Dean Braden	Consumer	United States	Houston	Texas	77041	Central	OFF-ST-10000736	Office Supplies	Storage	Carina Double Wide Media Storage Towers in Natural & Black	129.568	2	0.2	-25.9136
8023	CA-2011-129189	7/21/2013	7/25/2013	Standard Class	HM-14860	Harry Marie	Corporate	United States	Dallas	Texas	75217	Central	OFF-EN-10003567	Office Supplies	Envelopes	Inter-Office Recycled Envelopes, Brown Kraft, Button-String,10" x 13" , 100/Box	87.92	5	0.2	29.673
5730	CA-2014-117324	12/8/2016	12/13/2016	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-LA-10003510	Office Supplies	Labels	Avery 4027 File Folder Labels for Dot Matrix Printers, 5000 Labels per Box, White	61.06	2	0	28.0876
5568	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	FUR-CH-10003606	Furniture	Chairs	SAFCO Folding Chair Trolley	89.768	1	0.3	-2.5648
8802	CA-2013-140935	11/11/2015	11/13/2015	First Class	AB-10015	Aaron Bergman	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	TEC-PH-10000562	Technology	Phones	Samsung Convoy 3	221.98	2	0	62.1544
3937	CA-2012-118955	6/16/2014	6/20/2014	Standard Class	LS-17230	Lycoris Saunders	Consumer	United States	Grand Prairie	Texas	75051	Central	OFF-EN-10001028	Office Supplies	Envelopes	Staple envelope	28.752	3	0.2	9.3444
4004	CA-2013-145730	3/4/2015	3/9/2015	Standard Class	CC-12220	Chris Cortes	Consumer	United States	San Antonio	Texas	78207	Central	TEC-MA-10001016	Technology	Machines	Canon PC170 Desktop Personal Copier	287.91	3	0.4	33.5895
4669	US-2014-133200	5/6/2016	5/11/2016	Standard Class	DB-13555	Dorothy Badders	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-BI-10002827	Office Supplies	Binders	Avery Durable Poly Binders	11.06	10	0.8	-18.802
8147	US-2011-112949	6/20/2013	6/27/2013	Standard Class	Co-12640	Corey-Lock	Consumer	United States	Lawton	Oklahoma	73505	Central	OFF-AR-10003469	Office Supplies	Art	Nontoxic Chalk	3.52	2	0	1.6896
3568	CA-2013-137176	9/10/2015	9/15/2015	Second Class	DB-12910	Daniel Byrd	Home Office	United States	Dallas	Texas	75220	Central	FUR-FU-10003832	Furniture	Furnishings	Eldon Expressions Punched Metal & Wood Desk Accessories, Black & Cherry	15.008	4	0.6	-12.0064
1965	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-ST-10000025	Office Supplies	Storage	Fellowes Stor/Drawer Steel Plus Storage Drawers	286.29	3	0	17.1774
53	CA-2012-115742	4/18/2014	4/22/2014	Standard Class	DP-13000	Darren Powers	Consumer	United States	New Albany	Indiana	47150	Central	FUR-CH-10003061	Furniture	Chairs	Global Leather Task Chair, Black	89.99	1	0	17.0981
8247	CA-2012-129217	5/10/2014	5/10/2014	Same Day	DP-13390	Dennis Pardue	Home Office	United States	Aurora	Illinois	60505	Central	OFF-AP-10002439	Office Supplies	Appliances	Tripp Lite Isotel 8 Ultra 8 Outlet Metal Surge	70.97	5	0.8	-191.619
4886	CA-2011-151379	12/16/2013	12/20/2013	Standard Class	SC-20695	Steve Chapman	Corporate	United States	Detroit	Michigan	48227	Central	OFF-PA-10000595	Office Supplies	Paper	Xerox 1929	114.2	5	0	52.532
8111	CA-2014-160122	11/18/2016	11/23/2016	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Chicago	Illinois	60623	Central	FUR-CH-10000422	Furniture	Chairs	Global Highback Leather Tilter in Burgundy	127.386	2	0.3	-25.4772
1149	CA-2012-112452	4/4/2014	4/4/2014	Same Day	NC-18340	Nat Carroll	Consumer	United States	Lansing	Michigan	48911	Central	OFF-BI-10003350	Office Supplies	Binders	Acco Expandable Hanging Binders	12.76	2	0	5.8696
7454	CA-2014-134796	6/25/2016	7/1/2016	Standard Class	FM-14380	Fred McMath	Consumer	United States	Bolingbrook	Illinois	60440	Central	TEC-PH-10003505	Technology	Phones	Geemarc AmpliPOWER60	148.48	2	0.2	16.704
8212	CA-2013-116337	11/8/2015	11/13/2015	Standard Class	MC-17845	Michael Chen	Consumer	United States	Dallas	Texas	75220	Central	FUR-FU-10002030	Furniture	Furnishings	Executive Impressions 14" Contract Wall Clock with Quartz Movement	44.46	5	0.6	-17.784
7474	CA-2013-109652	4/11/2015	4/16/2015	Standard Class	QJ-19255	Quincy Jones	Corporate	United States	Chicago	Illinois	60653	Central	OFF-AR-10000034	Office Supplies	Art	BIC Brite Liner Grip Highlighters, Assorted, 5/Pack	13.568	4	0.2	3.2224
9793	CA-2011-127166	5/21/2013	5/23/2013	Second Class	KH-16360	Katherine Hughes	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10003396	Furniture	Chairs	Global Deluxe Steno Chair	107.772	2	0.3	-29.2524
2610	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	FUR-TA-10000577	Furniture	Tables	Bretford CR4500 Series Slim Rectangular Table	1218.735	5	0.3	-121.8735
9429	CA-2011-152100	5/11/2013	5/16/2013	Standard Class	VW-21775	Victoria Wilson	Corporate	United States	Huntsville	Texas	77340	Central	FUR-CH-10000015	Furniture	Chairs	Hon Multipurpose Stacking Arm Chairs	1212.96	8	0.3	-69.312
9796	CA-2013-125920	5/22/2015	5/29/2015	Standard Class	SH-19975	Sally Hughsby	Corporate	United States	Chicago	Illinois	60610	Central	OFF-BI-10003429	Office Supplies	Binders	Cardinal HOLDit! Binder Insert Strips,Extra Strips	3.798	3	0.8	-5.8869
2237	CA-2012-145849	9/15/2014	9/17/2014	Second Class	CT-11995	Carol Triggs	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-AR-10000817	Office Supplies	Art	Manco Dry-Lighter Erasable Highlighter	24.32	8	0	8.2688
4370	US-2013-165078	11/6/2015	11/11/2015	Standard Class	MA-17995	Michelle Arnett	Home Office	United States	Lawrence	Indiana	46226	Central	OFF-BI-10001989	Office Supplies	Binders	Premium Transparent Presentation Covers by GBC	104.9	5	0	50.352
9751	CA-2013-113390	10/12/2015	10/16/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AR-10003183	Office Supplies	Art	Avery Fluorescent Highlighter Four-Color Set	5.344	2	0.2	0.668
6677	CA-2012-109337	11/21/2014	11/23/2014	Second Class	DL-13330	Denise Leinenbach	Consumer	United States	Lawrence	Indiana	46226	Central	OFF-AP-10004052	Office Supplies	Appliances	Hoover Replacement Belts For Soft Guard & Commercial Ltweight Upright Vacs, 2/Pk	19.75	5	0	5.135
5063	CA-2012-136798	5/8/2014	5/12/2014	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Minneapolis	Minnesota	55407	Central	TEC-PH-10000441	Technology	Phones	VTech DS6151	377.97	3	0	105.8316
8159	CA-2014-136238	12/26/2016	1/1/2017	Standard Class	KB-16240	Karen Bern	Corporate	United States	Odessa	Texas	79762	Central	OFF-PA-10004285	Office Supplies	Paper	Xerox 1959	16.032	3	0.2	5.6112
9104	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10000193	Furniture	Furnishings	Tenex Chairmats For Use with Hard Floors	64.96	5	0.6	-84.448
7537	CA-2014-103415	12/3/2016	12/8/2016	Standard Class	MV-17485	Mark Van Huff	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10000820	Furniture	Furnishings	Tensor Brushed Steel Torchiere Floor Lamp	13.592	2	0.6	-14.2716
6248	CA-2014-121580	5/29/2016	6/4/2016	Standard Class	ML-17410	Maris LaWare	Consumer	United States	Columbus	Indiana	47201	Central	OFF-BI-10000632	Office Supplies	Binders	Satellite Sectional Post Binders	43.41	1	0	19.9686
8459	CA-2011-126200	8/25/2013	8/29/2013	Standard Class	JE-15715	Joe Elijah	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10002133	Office Supplies	Binders	Wilson Jones Elliptical Ring 3 1/2" Capacity Binders, 800 sheets	25.68	3	0.8	-39.804
8001	US-2012-151407	11/8/2014	11/12/2014	Standard Class	RD-19585	Rob Dowd	Consumer	United States	Dubuque	Iowa	52001	Central	TEC-PH-10003885	Technology	Phones	Cisco SPA508G	263.96	4	0	76.5484
894	CA-2014-133256	6/26/2016	6/27/2016	First Class	TH-21550	Tracy Hopkins	Home Office	United States	Detroit	Michigan	48227	Central	TEC-PH-10002660	Technology	Phones	Nortel Networks T7316 E Nt8 B27	543.92	8	0	135.98
9721	CA-2013-119641	9/23/2015	9/27/2015	Standard Class	CS-12250	Chris Selesnick	Corporate	United States	Green Bay	Wisconsin	54302	Central	FUR-FU-10002445	Furniture	Furnishings	DAX Two-Tone Rosewood/Black Document Frame, Desktop, 5 x 7	18.96	2	0	7.584
1272	US-2013-103646	4/22/2015	4/27/2015	Standard Class	SP-20545	Sibella Parks	Corporate	United States	Chicago	Illinois	60623	Central	OFF-AP-10004487	Office Supplies	Appliances	Kensington 4 Outlet MasterPiece Compact Power Control Center	48.792	3	0.8	-126.8592
8960	CA-2014-150266	11/25/2016	11/30/2016	Standard Class	RO-19780	Rose O'Brian	Consumer	United States	Houston	Texas	77070	Central	OFF-AP-10002867	Office Supplies	Appliances	Fellowes Command Center 5-outlet power strip	67.84	5	0.8	-179.776
7095	US-2012-153374	2/9/2014	2/13/2014	Second Class	JF-15565	Jill Fjeld	Consumer	United States	Decatur	Illinois	62521	Central	TEC-AC-10001908	Technology	Accessories	Logitech Wireless Headset h800	479.952	6	0.2	89.991
177	US-2014-152366	4/21/2016	4/25/2016	Second Class	SJ-20500	Shirley Jackson	Consumer	United States	Houston	Texas	77036	Central	OFF-AP-10002684	Office Supplies	Appliances	Acco 7-Outlet Masterpiece Power Center, Wihtout Fax/Phone Line Protection	97.264	4	0.8	-243.16
4782	CA-2011-159310	11/7/2013	11/12/2013	Standard Class	SC-20725	Steven Cartwright	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10000201	Office Supplies	Binders	Avery Triangle Shaped Sheet Lifters, Black, 2/Pack	1.476	3	0.8	-2.214
4860	CA-2014-136063	12/15/2016	12/19/2016	Standard Class	SS-20140	Saphhira Shifley	Corporate	United States	Oak Park	Illinois	60302	Central	OFF-AR-10000823	Office Supplies	Art	Newell 307	10.192	7	0.2	1.0192
8606	US-2013-116365	1/3/2015	1/8/2015	Standard Class	CA-12310	Christine Abelman	Corporate	United States	San Antonio	Texas	78207	Central	TEC-PH-10002890	Technology	Phones	AT&T 17929 Lendline Telephone	180.96	5	0.2	13.572
816	CA-2012-106565	3/20/2014	3/23/2014	First Class	BW-11110	Bart Watters	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-PA-10000061	Office Supplies	Paper	Xerox 205	51.84	8	0	24.8832
9835	CA-2013-126627	10/11/2015	10/13/2015	First Class	WB-21850	William Brown	Consumer	United States	La Porte	Texas	77571	Central	FUR-FU-10004963	Furniture	Furnishings	Eldon 400 Class Desk Accessories, Black Carbon	14	4	0.6	-6.3
8221	CA-2011-120775	10/3/2013	10/7/2013	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Dallas	Texas	75217	Central	OFF-BI-10002609	Office Supplies	Binders	Avery Hidden Tab Dividers for Binding Systems	1.788	3	0.8	-3.0396
2524	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-BI-10000977	Office Supplies	Binders	Ibico Plastic Spiral Binding Combs	121.6	4	0	55.936
9649	CA-2011-150518	11/19/2013	11/24/2013	Standard Class	MW-18220	Mitch Webber	Consumer	United States	Coon Rapids	Minnesota	55433	Central	TEC-PH-10002103	Technology	Phones	Jabra SPEAK 410	281.97	3	0	78.9516
680	US-2014-119438	3/18/2016	3/23/2016	Standard Class	CD-11980	Carol Darley	Consumer	United States	Tyler	Texas	75701	Central	OFF-BI-10004632	Office Supplies	Binders	Ibico Hi-Tech Manual Binding System	182.994	3	0.8	-320.2395
8075	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	OFF-BI-10000343	Office Supplies	Binders	Pressboard Covers with Storage Hooks, 9 1/2" x 11", Light Blue	13.748	14	0.8	-22.6842
36	CA-2013-117590	12/9/2015	12/11/2015	First Class	GH-14485	Gene Hale	Corporate	United States	Richardson	Texas	75080	Central	TEC-PH-10004977	Technology	Phones	GE 30524EE4	1097.544	7	0.2	123.4737
9897	CA-2011-156342	6/17/2013	6/20/2013	Second Class	JF-15415	Jennifer Ferguson	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10001725	Office Supplies	Paper	Xerox 1892	62.016	2	0.2	22.4808
2667	CA-2013-111794	10/2/2015	10/2/2015	Same Day	HG-15025	Hunter Glantz	Consumer	United States	Amarillo	Texas	79109	Central	TEC-AC-10003832	Technology	Accessories	Imation 16GB Mini TravelDrive USB 2.0 Flash Drive	79.512	3	0.2	20.8719
8891	CA-2013-147256	10/18/2015	10/22/2015	Second Class	FC-14245	Frank Carlisle	Home Office	United States	Columbia	Missouri	65203	Central	OFF-AP-10003057	Office Supplies	Appliances	Honeywell Enviracaire Portable HEPA Air Cleaner for 16' x 20' Room	1927.59	7	0	751.7601
445	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	FUR-CH-10002372	Furniture	Chairs	Office Star - Ergonomically Designed Knee Chair	242.94	3	0	29.1528
3417	CA-2013-116540	9/3/2015	9/3/2015	Same Day	SS-20590	Sonia Sunley	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-BI-10004970	Office Supplies	Binders	ACCOHIDE 3-Ring Binder, Blue, 1"	8.26	2	0	3.8822
5751	CA-2011-145800	5/30/2013	6/5/2013	Standard Class	SS-20410	Shahid Shariari	Consumer	United States	Buffalo Grove	Illinois	60089	Central	FUR-TA-10001539	Furniture	Tables	Chromcraft Rectangular Conference Tables	355.455	3	0.5	-184.8366
3710	CA-2011-120544	11/23/2013	11/27/2013	Standard Class	SS-20140	Saphhira Shifley	Corporate	United States	Mesquite	Texas	75150	Central	TEC-AC-10003709	Technology	Accessories	Maxell 4.7GB DVD-R 5/Pack	5.544	7	0.2	1.6632
2495	CA-2013-146206	9/11/2015	9/15/2015	Second Class	KT-16480	Kean Thornton	Consumer	United States	Houston	Texas	77095	Central	TEC-PH-10000895	Technology	Phones	Polycom VVX 310 VoIP phone	719.96	5	0.2	53.997
1863	CA-2011-151078	11/12/2013	11/12/2013	Same Day	RF-19840	Roy Französisch	Consumer	United States	San Antonio	Texas	78207	Central	OFF-ST-10001328	Office Supplies	Storage	Personal Filing Tote with Lid, Black/Gray	49.632	4	0.2	4.9632
7704	CA-2013-114601	8/27/2015	9/3/2015	Standard Class	AA-10480	Andrew Allen	Consumer	United States	Detroit	Michigan	48234	Central	TEC-PH-10002170	Technology	Phones	ClearSounds CSC500 Amplified Spirit Phone Corded phone	209.97	3	0	58.7916
2923	US-2012-141453	11/30/2014	12/3/2014	Second Class	DB-13270	Deborah Brumfield	Home Office	United States	Austin	Texas	78745	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	3.882	3	0.8	-5.823
6330	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	247.716	4	0.1	93.5816
4875	CA-2014-164042	5/23/2016	5/27/2016	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10001922	Office Supplies	Binders	Storex Dura Pro Binders	1.188	1	0.8	-1.9602
4675	CA-2013-133550	8/1/2015	8/7/2015	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Detroit	Michigan	48205	Central	FUR-FU-10002918	Furniture	Furnishings	Eldon ClusterMat Chair Mat with Cordless Antistatic Protection	272.94	3	0	30.0234
95	CA-2012-149587	1/31/2014	2/5/2014	Second Class	KB-16315	Karl Braun	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10002852	Office Supplies	Binders	Ibico Standard Transparent Covers	32.96	2	0	16.1504
6809	CA-2012-128125	3/31/2014	4/5/2014	Standard Class	EB-13705	Ed Braxton	Corporate	United States	Houston	Texas	77095	Central	FUR-FU-10001085	Furniture	Furnishings	3M Polarizing Light Filter Sleeves	22.38	3	0.6	-7.833
8321	CA-2012-142937	12/5/2014	12/6/2014	First Class	SF-20065	Sandra Flanagan	Consumer	United States	Dallas	Texas	75220	Central	OFF-AR-10003582	Office Supplies	Art	Boston Electric Pencil Sharpener, Model 1818, Charcoal Black	45.04	2	0.2	4.504
6190	CA-2014-157903	4/4/2016	4/8/2016	Standard Class	AM-10705	Anne McFarland	Consumer	United States	Des Plaines	Illinois	60016	Central	TEC-PH-10004345	Technology	Phones	Cisco SPA 502G IP Phone	383.84	4	0.2	47.98
7447	CA-2014-127474	2/4/2016	2/8/2016	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Chicago	Illinois	60610	Central	FUR-FU-10004597	Furniture	Furnishings	Eldon Cleatmat Chair Mats for Medium Pile Carpets	22.2	1	0.6	-26.085
3510	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	OFF-PA-10000587	Office Supplies	Paper	Array Parchment Paper, Assorted Colors	11.648	2	0.2	4.0768
8035	CA-2012-119690	6/25/2014	6/28/2014	First Class	MV-17485	Mark Van Huff	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10004587	Furniture	Furnishings	GE General Use Halogen Bulbs, 100 Watts, 1 Bulb per Pack	75.384	9	0.6	-20.7306
4980	US-2013-131114	12/10/2015	12/14/2015	Second Class	RW-19630	Rob Williams	Corporate	United States	Chicago	Illinois	60610	Central	OFF-SU-10001664	Office Supplies	Supplies	Acme Office Executive Series Stainless Steel Trimmers	20.568	3	0.2	1.5426
4696	US-2012-138121	12/17/2014	12/17/2014	Same Day	JL-15835	John Lee	Consumer	United States	Detroit	Michigan	48205	Central	FUR-CH-10003846	Furniture	Chairs	Hon Valutask Swivel Chairs	302.94	3	0	48.4704
5062	CA-2012-136798	5/8/2014	5/12/2014	Standard Class	DL-12925	Daniel Lacy	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10003684	Office Supplies	Binders	Wilson Jones Legal Size Ring Binders	43.98	2	0	21.99
1790	CA-2012-154326	2/15/2014	2/19/2014	Standard Class	RP-19855	Roy Phan	Corporate	United States	Kenosha	Wisconsin	53142	Central	TEC-AC-10004568	Technology	Accessories	Maxell LTO Ultrium - 800 GB	139.95	5	0	26.5905
7607	CA-2013-101791	5/28/2015	6/1/2015	Standard Class	BS-11665	Brian Stugart	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10001496	Office Supplies	Storage	Standard Rollaway File with Lock	1297.368	9	0.2	97.3026
6195	CA-2014-104927	12/22/2016	12/26/2016	Standard Class	AG-10330	Alex Grayson	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000176	Office Supplies	Paper	Xerox 1887	75.88	5	0.2	26.558
8566	CA-2013-134110	11/18/2015	11/19/2015	First Class	BG-11035	Barry Gonzalez	Consumer	United States	The Colony	Texas	75056	Central	TEC-PH-10002350	Technology	Phones	Apple EarPods with Remote and Mic	67.176	3	0.2	6.7176
3861	CA-2014-154039	2/18/2016	2/23/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Chicago	Illinois	60653	Central	TEC-PH-10002789	Technology	Phones	LG Exalt	124.792	1	0.2	10.9193
2057	CA-2014-120376	12/22/2016	12/25/2016	First Class	TP-21130	Theone Pippenger	Consumer	United States	Detroit	Michigan	48227	Central	FUR-CH-10002335	Furniture	Chairs	Hon GuestStacker Chair	1586.69	7	0	412.5394
9303	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	OFF-AR-10003481	Office Supplies	Art	Newell 348	7.872	3	0.2	0.8856
1944	CA-2014-144064	8/29/2016	9/1/2016	First Class	CP-12085	Cathy Prescott	Corporate	United States	Quincy	Illinois	62301	Central	OFF-BI-10002012	Office Supplies	Binders	Wilson Jones Easy Flow II Sheet Lifters	3.24	9	0.8	-5.184
5566	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	TEC-MA-10002109	Technology	Machines	HP Officejet Pro 8600 e-All-In-One Printer, Copier, Scanner, Fax	209.986	2	0.3	8.9994
4287	CA-2012-105690	11/21/2014	11/26/2014	Second Class	CA-11965	Carol Adams	Corporate	United States	Port Arthur	Texas	77642	Central	TEC-CO-10001571	Technology	Copiers	Sharp 1540cs Digital Laser Copier	439.992	1	0.2	164.997
7005	CA-2011-126333	12/23/2013	12/28/2013	Standard Class	ME-18010	Michelle Ellison	Corporate	United States	Port Arthur	Texas	77642	Central	OFF-PA-10000223	Office Supplies	Paper	Xerox 2000	5.184	1	0.2	1.8144
3368	CA-2011-165379	7/9/2013	7/15/2013	Standard Class	BM-11650	Brian Moss	Corporate	United States	Dallas	Texas	75217	Central	OFF-PA-10002245	Office Supplies	Paper	Xerox 1895	14.352	3	0.2	4.485
8998	CA-2014-122763	3/20/2016	3/20/2016	Same Day	HG-14845	Harry Greene	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10000474	Office Supplies	Paper	Easy-staple paper	56.704	2	0.2	19.1376
6988	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10001116	Office Supplies	Binders	Wilson Jones 1" Hanging DublLock Ring Binders	26.4	5	0	12.672
9097	US-2012-132836	6/1/2014	6/5/2014	Standard Class	AJ-10945	Ashley Jarboe	Consumer	United States	Detroit	Michigan	48227	Central	OFF-LA-10004178	Office Supplies	Labels	Avery 491	28.91	7	0	13.2986
9066	US-2011-151015	10/14/2013	10/20/2013	Standard Class	BD-11500	Bradley Drucker	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10001184	Office Supplies	Paper	Xerox 1903	19.136	4	0.2	6.9368
758	CA-2011-106803	12/29/2013	1/2/2014	Standard Class	DC-13285	Debra Catini	Consumer	United States	Cottage Grove	Minnesota	55016	Central	TEC-AC-10001267	Technology	Accessories	Imation 32GB Pocket Pro USB 3.0 Flash Drive - 32 GB - Black - 1 P ...	119.8	4	0	47.92
3331	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	TEC-PH-10004959	Technology	Phones	Classic Ivory Antique Telephone ZL1810	241.176	3	0.2	15.0735
7311	CA-2012-121699	8/10/2014	8/14/2014	Standard Class	BD-11320	Bill Donatelli	Consumer	United States	Detroit	Michigan	48227	Central	OFF-BI-10004632	Office Supplies	Binders	GBC Binding covers	64.75	5	0	29.1375
5167	CA-2011-121006	11/10/2013	11/16/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Midland	Michigan	48640	Central	OFF-PA-10002479	Office Supplies	Paper	Xerox 4200 Series MultiUse Premium Copy Paper (20Lb. and 84 Bright)	15.84	3	0	7.128
3358	CA-2014-100335	9/7/2016	9/13/2016	Standard Class	NF-18595	Nicole Fjeld	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10001685	Office Supplies	Paper	Easy-staple paper	73.008	9	0.2	26.4654
9866	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	FUR-FU-10001037	Furniture	Furnishings	DAX Charcoal/Nickel-Tone Document Frame, 5 x 7	18.96	2	0	8.532
9007	CA-2014-107825	11/18/2016	11/18/2016	Same Day	NB-18655	Nona Balk	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-ST-10000777	Office Supplies	Storage	Companion Letter/Legal File, Black	37.76	1	0	10.5728
8581	CA-2011-130673	5/20/2013	5/22/2013	Second Class	MC-17590	Matt Collister	Corporate	United States	San Marcos	Texas	78666	Central	FUR-FU-10003489	Furniture	Furnishings	Contemporary Borderless Frame	10.332	3	0.6	-5.9409
170	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AP-10002518	Office Supplies	Appliances	Kensington 7 Outlet MasterPiece Power Center	177.98	5	0.8	-453.849
5101	CA-2011-158442	3/17/2013	3/17/2013	Same Day	AZ-10750	Annie Zypern	Consumer	United States	Dallas	Texas	75217	Central	OFF-AR-10003732	Office Supplies	Art	Newell 333	4.448	2	0.2	0.3336
5554	US-2011-159618	11/12/2013	11/16/2013	Standard Class	DB-12970	Darren Budd	Corporate	United States	Houston	Texas	77036	Central	OFF-PA-10004100	Office Supplies	Paper	Xerox 216	36.288	7	0.2	12.7008
7256	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-ST-10000876	Office Supplies	Storage	Eldon Simplefile Box Office	49.76	4	0	13.9328
9227	CA-2014-121160	11/4/2016	11/4/2016	Same Day	FM-14290	Frank Merwin	Home Office	United States	Bryan	Texas	77803	Central	OFF-ST-10002485	Office Supplies	Storage	Rogers Deluxe File Chest	52.752	3	0.2	-12.5286
8308	CA-2013-128671	8/12/2015	8/17/2015	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10003007	Office Supplies	Binders	Premium Transparent Presentation Covers, No Pattern/Clear, 8 1/2" x 11"	77.56	2	0	35.6776
1945	CA-2013-108581	6/21/2015	6/27/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Carrollton	Texas	75007	Central	TEC-AC-10001109	Technology	Accessories	Logitech Trackman Marble Mouse	95.968	4	0.2	26.3912
8416	CA-2014-107265	4/6/2016	4/12/2016	Standard Class	ML-17755	Max Ludwig	Home Office	United States	Marion	Iowa	52302	Central	OFF-PA-10000474	Office Supplies	Paper	Easy-staple paper	106.32	3	0	49.9704
3398	US-2014-148362	7/1/2016	7/8/2016	Standard Class	KF-16285	Karen Ferguson	Home Office	United States	Indianapolis	Indiana	46203	Central	OFF-PA-10003441	Office Supplies	Paper	Xerox 226	25.92	4	0	12.4416
7951	CA-2011-131009	3/1/2013	3/5/2013	Standard Class	SC-20380	Shahid Collister	Consumer	United States	El Paso	Texas	79907	Central	OFF-ST-10001469	Office Supplies	Storage	Fellowes Bankers Box Recycled Super Stor/Drawer	129.552	3	0.2	-22.6716
6907	CA-2014-149468	5/20/2016	5/20/2016	Same Day	AR-10405	Allen Rosenblatt	Corporate	United States	Trenton	Michigan	48183	Central	OFF-BI-10002225	Office Supplies	Binders	Square Ring Data Binders, Rigid 75 Pt. Covers, 11" x 14-7/8"	41.28	2	0	19.8144
3047	CA-2014-125290	11/6/2016	11/10/2016	Second Class	CC-12430	Chuck Clark	Home Office	United States	Minneapolis	Minnesota	55407	Central	OFF-PA-10003127	Office Supplies	Paper	Easy-staple paper	26.38	1	0	12.1348
8977	CA-2014-156622	11/23/2016	11/26/2016	First Class	JP-15460	Jennifer Patt	Corporate	United States	Dallas	Texas	75220	Central	FUR-TA-10003008	Furniture	Tables	Lesro Round Back Collection Coffee Table, End Table	127.785	1	0.3	-31.0335
176	US-2011-100853	9/14/2013	9/19/2013	Standard Class	JB-15400	Jennifer Braxton	Corporate	United States	Chicago	Illinois	60623	Central	OFF-LA-10003148	Office Supplies	Labels	Avery 51	20.16	4	0.2	6.552
7323	CA-2014-167626	9/3/2016	9/7/2016	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Chicago	Illinois	60623	Central	TEC-AC-10004353	Technology	Accessories	Hypercom P1300 Pinpad	100.8	2	0.2	21.42
8025	CA-2011-129189	7/21/2013	7/25/2013	Standard Class	HM-14860	Harry Marie	Corporate	United States	Dallas	Texas	75217	Central	OFF-BI-10000494	Office Supplies	Binders	Acco Economy Flexible Poly Round Ring Binder	1.044	1	0.8	-1.827
5800	CA-2011-166716	8/20/2013	8/25/2013	Second Class	CR-12730	Craig Reiter	Consumer	United States	Chicago	Illinois	60610	Central	FUR-CH-10004495	Furniture	Chairs	Global Leather and Oak Executive Chair, Black	421.372	2	0.3	-6.0196
5416	US-2014-125647	9/23/2016	9/28/2016	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10004888	Office Supplies	Paper	Xerox 217	20.736	4	0.2	7.2576
3024	CA-2014-124674	11/17/2016	11/23/2016	Standard Class	JB-16000	Joy Bell-	Consumer	United States	Brownsville	Texas	78521	Central	FUR-BO-10002202	Furniture	Bookcases	Atlantic Metals Mobile 2-Shelf Bookcases, Custom Colors	327.7328	2	0.32	-14.4588
9501	CA-2013-149237	5/27/2015	5/31/2015	Standard Class	CM-12235	Chris McAfee	Consumer	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10002088	Furniture	Furnishings	Nu-Dell Float Frame 11 x 14 1/2	26.94	3	0	11.3148
772	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	TEC-PH-10004614	Technology	Phones	AT&T 841000 Phone	207	3	0	51.75
745	US-2013-146710	8/28/2015	9/2/2015	Standard Class	SS-20875	Sung Shariari	Consumer	United States	Dallas	Texas	75220	Central	OFF-PA-10004971	Office Supplies	Paper	Xerox 196	4.624	1	0.2	1.6762
8380	CA-2012-162964	11/12/2014	11/18/2014	Standard Class	MF-18250	Monica Federle	Corporate	United States	Houston	Texas	77095	Central	OFF-EN-10003055	Office Supplies	Envelopes	Blue String-Tie & Button Interoffice Envelopes, 10 x 13	223.888	7	0.2	69.965
6625	CA-2012-141250	1/19/2014	1/23/2014	Standard Class	PM-18940	Paul MacIntyre	Consumer	United States	Texas City	Texas	77590	Central	FUR-TA-10002855	Furniture	Tables	Bevis Round Conference Table Top & Single Column Base	102.438	1	0.3	-13.1706
8508	CA-2013-130400	3/9/2015	3/13/2015	Standard Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Dallas	Texas	75217	Central	OFF-EN-10001453	Office Supplies	Envelopes	Tyvek Interoffice Envelopes, 9 1/2" x 12 1/2", 100/Box	146.352	3	0.2	49.3938
3475	CA-2014-111815	3/3/2016	3/10/2016	Standard Class	EP-13915	Emily Phan	Consumer	United States	Dearborn Heights	Michigan	48127	Central	TEC-AC-10002926	Technology	Accessories	Logitech Wireless Marathon Mouse M705	99.98	2	0	42.9914
371	CA-2014-104745	5/29/2016	6/4/2016	Standard Class	GT-14755	Guy Thornton	Consumer	United States	Harlingen	Texas	78550	Central	OFF-PA-10002036	Office Supplies	Paper	Xerox 1930	25.92	5	0.2	9.396
6654	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	FUR-CH-10003535	Furniture	Chairs	Global Armless Task Chair, Royal Blue	213.43	5	0.3	-39.637
674	CA-2014-130351	12/5/2016	12/8/2016	First Class	RB-19570	Rob Beeghly	Consumer	United States	Columbus	Indiana	47201	Central	OFF-AP-10004532	Office Supplies	Appliances	Kensington 6 Outlet Guardian Standard Surge Protector	61.44	3	0	16.5888
9128	CA-2014-112473	5/25/2016	6/1/2016	Standard Class	JL-15505	Jeremy Lonsdale	Consumer	United States	Houston	Texas	77070	Central	OFF-ST-10002182	Office Supplies	Storage	Iris 3-Drawer Stacking Bin, Black	50.136	3	0.2	-11.2806
7494	US-2014-160836	9/11/2016	9/16/2016	Standard Class	CC-12475	Cindy Chapman	Consumer	United States	Houston	Texas	77070	Central	FUR-TA-10002855	Furniture	Tables	Bevis Round Conference Table Top & Single Column Base	512.19	5	0.3	-65.853
1107	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10000206	Furniture	Furnishings	GE General Purpose, Extra Long Life, Showcase & Floodlight Incandescent Bulbs	2.328	2	0.6	-0.7566
7389	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	TEC-PH-10004897	Technology	Phones	Mediabridge Sport Armband iPhone 5s	29.97	3	0	0.2997
7385	CA-2013-105732	9/14/2015	9/19/2015	Standard Class	AG-10270	Alejandro Grove	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-AP-10001394	Office Supplies	Appliances	Harmony Air Purifier	378	2	0	136.08
541	CA-2011-140795	2/1/2013	2/3/2013	First Class	BD-11500	Bradley Drucker	Consumer	United States	Green Bay	Wisconsin	54302	Central	TEC-AC-10001432	Technology	Accessories	Enermax Aurora Lite Keyboard	468.9	6	0	206.316
3545	CA-2014-121216	12/23/2016	12/25/2016	Second Class	MM-17920	Michael Moore	Consumer	United States	College Station	Texas	77840	Central	OFF-PA-10004519	Office Supplies	Paper	Spiral Phone Message Books with Labels by Adams	28.672	8	0.2	10.3936
8562	CA-2013-132829	12/24/2015	12/27/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Houston	Texas	77041	Central	FUR-FU-10000206	Furniture	Furnishings	GE General Purpose, Extra Long Life, Showcase & Floodlight Incandescent Bulbs	2.328	2	0.6	-0.7566
1786	CA-2014-166317	9/22/2016	9/26/2016	Standard Class	JE-15610	Jim Epp	Corporate	United States	Milwaukee	Wisconsin	53209	Central	OFF-BI-10002976	Office Supplies	Binders	ACCOHIDE Binder by Acco	33.04	8	0	15.5288
5851	CA-2012-121783	11/10/2014	11/14/2014	Standard Class	PO-19180	Philisse Overcash	Home Office	United States	Roseville	Minnesota	55113	Central	TEC-CO-10001571	Technology	Copiers	Sharp 1540cs Digital Laser Copier	549.99	1	0	274.995
796	CA-2014-151428	9/21/2016	9/26/2016	Standard Class	RH-19495	Rick Hansen	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	20.16	7	0	9.8784
1138	CA-2013-152170	11/13/2015	11/16/2015	Second Class	FH-14275	Frank Hawley	Corporate	United States	La Porte	Indiana	46350	Central	OFF-AP-10002350	Office Supplies	Appliances	Belkin F9H710-06 7 Outlet SurgeMaster Surge Protector	37.68	2	0	10.5504
8719	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	OFF-AR-10003469	Office Supplies	Art	Nontoxic Chalk	11.264	8	0.2	3.9424
6315	CA-2011-100762	11/24/2013	11/29/2013	Standard Class	NG-18355	Nat Gilpin	Corporate	United States	Jackson	Michigan	49201	Central	OFF-AR-10000380	Office Supplies	Art	Hunt PowerHouse Electric Pencil Sharpener, Blue	151.92	4	0	45.576
5806	CA-2014-113873	11/13/2016	11/19/2016	Standard Class	KE-16420	Katrina Edelman	Corporate	United States	Dallas	Texas	75220	Central	FUR-BO-10003441	Furniture	Bookcases	Bush Westfield Collection Bookcases, Fully Assembled	205.9992	3	0.32	-27.2646
45	CA-2013-118255	3/12/2015	3/14/2015	First Class	ON-18715	Odella Nelson	Corporate	United States	Eagan	Minnesota	55122	Central	TEC-AC-10000171	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 25/Pack	45.98	2	0	19.7714
6124	CA-2012-142139	8/31/2014	9/5/2014	Standard Class	SD-20485	Shirley Daniels	Home Office	United States	Bedford	Texas	76021	Central	OFF-PA-10003883	Office Supplies	Paper	Message Book, Phone, Wirebound Standard Line Memo, 2 3/4" X 5"	20.96	4	0.2	6.812
6765	CA-2013-144764	9/3/2015	9/9/2015	Standard Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60623	Central	TEC-MA-10003230	Technology	Machines	Okidata C610n Printer	1362.9	3	0.3	-19.47
641	CA-2013-147067	12/19/2015	12/23/2015	Standard Class	JD-16150	Justin Deggeller	Corporate	United States	Minneapolis	Minnesota	55407	Central	FUR-FU-10000732	Furniture	Furnishings	Eldon 200 Class Desk Accessories	18.84	3	0	6.0288
1106	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-ST-10000642	Office Supplies	Storage	Tennsco Lockers, Gray	100.704	6	0.2	-16.3644
1811	CA-2013-165484	10/24/2015	10/30/2015	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Chicago	Illinois	60610	Central	OFF-PA-10000595	Office Supplies	Paper	Xerox 1929	54.816	3	0.2	17.8152
8218	CA-2011-120775	10/3/2013	10/7/2013	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Dallas	Texas	75217	Central	OFF-FA-10002676	Office Supplies	Fasteners	Colored Push Pins	4.344	3	0.2	0.8688
7697	CA-2014-107958	7/2/2016	7/5/2016	First Class	AH-10120	Adrian Hane	Home Office	United States	Houston	Texas	77036	Central	OFF-BI-10001787	Office Supplies	Binders	Wilson Jones Four-Pocket Poly Binders	5.232	4	0.8	-8.1096
5350	CA-2012-149811	1/4/2014	1/10/2014	Standard Class	CS-12250	Chris Selesnick	Corporate	United States	Woodbury	Minnesota	55125	Central	OFF-PA-10004082	Office Supplies	Paper	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	39.9	5	0	19.95
3476	CA-2013-144911	11/28/2015	12/1/2015	First Class	RW-19630	Rob Williams	Corporate	United States	Overland Park	Kansas	66212	Central	TEC-AC-10004633	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 3/Pack	34.95	5	0	15.378
6506	CA-2013-152331	6/27/2015	7/1/2015	Standard Class	LD-16855	Lela Donovan	Corporate	United States	Chicago	Illinois	60653	Central	OFF-AR-10001547	Office Supplies	Art	Newell 311	5.304	3	0.2	0.4641
6173	US-2011-106299	8/2/2013	8/8/2013	Standard Class	NZ-18565	Nick Zandusky	Home Office	United States	Springfield	Missouri	65807	Central	OFF-BI-10001758	Office Supplies	Binders	Wilson Jones 14 Line Acrylic Coated Pressboard Data Binders	26.7	5	0	12.549
4688	CA-2013-101987	6/25/2015	7/1/2015	Standard Class	HL-15040	Hunter Lopez	Consumer	United States	Richmond	Indiana	47374	Central	TEC-PH-10001305	Technology	Phones	Panasonic KX TS208W Corded phone	440.91	9	0	123.4548
4944	CA-2014-106782	12/21/2016	12/27/2016	Standard Class	LP-17095	Liz Preis	Consumer	United States	Lafayette	Indiana	47905	Central	OFF-ST-10004459	Office Supplies	Storage	Tennsco Single-Tier Lockers	375.34	1	0	18.767
5076	CA-2011-134572	4/20/2013	4/22/2013	Second Class	SV-20365	Seth Vernon	Consumer	United States	Houston	Texas	77070	Central	FUR-TA-10001705	Furniture	Tables	Bush Advantage Collection Round Conference Table	744.1	5	0.3	-95.67
4384	US-2012-122784	7/20/2014	7/27/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Highland Park	Illinois	60035	Central	FUR-BO-10004690	Furniture	Bookcases	O'Sullivan Cherrywood Estates Traditional Barrister Bookcase	384.944	4	0.3	-126.4816
5450	US-2011-119081	9/12/2013	9/19/2013	Standard Class	TA-21385	Tom Ashbrook	Home Office	United States	Olathe	Kansas	66062	Central	TEC-AC-10001542	Technology	Accessories	SanDisk Cruzer 16 GB USB Flash Drive	57.4	5	0	10.906
2317	CA-2014-122035	7/20/2016	7/25/2016	Standard Class	EM-13825	Elizabeth Moffitt	Corporate	United States	Sioux Falls	South Dakota	57103	Central	FUR-CH-10003833	Furniture	Chairs	Novimex Fabric Task Chair	182.94	3	0	27.441
8495	CA-2012-109190	10/23/2014	10/28/2014	Standard Class	CC-12685	Craig Carroll	Consumer	United States	Lubbock	Texas	79424	Central	OFF-BI-10000977	Office Supplies	Binders	Ibico Plastic Spiral Binding Combs	6.08	1	0.8	-10.336
208	CA-2014-135860	12/1/2016	12/7/2016	Standard Class	JH-15985	Joseph Holt	Consumer	United States	Saginaw	Michigan	48601	Central	TEC-PH-10001700	Technology	Phones	Panasonic KX-TG6844B Expandable Digital Cordless Telephone	131.98	2	0	35.6346
5097	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10002088	Furniture	Furnishings	Nu-Dell Float Frame 11 x 14 1/2	10.776	3	0.6	-4.8492
4072	CA-2013-145303	8/29/2015	9/1/2015	First Class	TP-21415	Tom Prescott	Consumer	United States	Dallas	Texas	75081	Central	FUR-BO-10003159	Furniture	Bookcases	Sauder Camden County Collection Libraries, Planked Cherry Finish	156.3728	2	0.32	-52.8908
8561	CA-2013-132829	12/24/2015	12/27/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Houston	Texas	77041	Central	TEC-PH-10004912	Technology	Phones	Cisco SPA112 2 Port Phone Adapter	131.88	3	0.2	14.8365
1974	CA-2011-148950	12/14/2013	12/19/2013	Standard Class	JD-16015	Joy Daniels	Consumer	United States	Chicago	Illinois	60610	Central	OFF-FA-10003059	Office Supplies	Fasteners	Assorted Color Push Pins	2.896	2	0.2	0.4706
3017	US-2013-160528	8/24/2015	8/31/2015	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Pharr	Texas	78577	Central	OFF-ST-10002743	Office Supplies	Storage	SAFCO Boltless Steel Shelving	727.296	8	0.2	-172.7328
6273	CA-2014-149706	12/11/2016	12/12/2016	First Class	AS-10285	Alejandro Savely	Corporate	United States	Palatine	Illinois	60067	Central	TEC-AC-10001284	Technology	Accessories	Enermax Briskie RF Wireless Keyboard and Mouse Combo	116.312	7	0.2	23.2624
1502	CA-2014-130386	11/12/2016	11/18/2016	Standard Class	NG-18430	Nathan Gelder	Consumer	United States	Austin	Texas	78745	Central	OFF-ST-10003716	Office Supplies	Storage	Tennsco Double-Tier Lockers	540.048	3	0.2	-47.2542
5353	CA-2013-123932	9/7/2015	9/13/2015	Standard Class	YC-21895	Yoseph Carroll	Corporate	United States	Dallas	Texas	75217	Central	TEC-PH-10002447	Technology	Phones	AT&T CL83451 4-Handset Telephone	329.584	2	0.2	37.0782
6819	CA-2014-163860	12/28/2016	1/1/2017	Standard Class	LO-17170	Lori Olson	Corporate	United States	Peoria	Illinois	61604	Central	OFF-BI-10003784	Office Supplies	Binders	Computer Printout Index Tabs	1.68	5	0.8	-2.688
2045	CA-2011-129168	8/17/2013	8/23/2013	Standard Class	KB-16585	Ken Black	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10001639	Office Supplies	Paper	Xerox 203	15.552	3	0.2	5.4432
1351	CA-2011-153976	10/3/2013	10/8/2013	Second Class	BP-11290	Beth Paige	Consumer	United States	Evanston	Illinois	60201	Central	FUR-CH-10002880	Furniture	Chairs	Global High-Back Leather Tilter, Burgundy	258.279	3	0.3	-70.1043
1598	CA-2014-158876	11/19/2016	11/21/2016	Second Class	AB-10150	Aimee Bixby	Consumer	United States	Carrollton	Texas	75007	Central	OFF-PA-10000308	Office Supplies	Paper	Xerox 1901	16.896	4	0.2	5.28
9103	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	OFF-ST-10001713	Office Supplies	Storage	Gould Plastics 9-Pocket Panel Bin, 18-3/8w x 5-1/4d x 20-1/2h, Black	84.784	2	0.2	-16.9568
6998	CA-2014-117443	12/23/2016	12/25/2016	Second Class	JB-15400	Jennifer Braxton	Corporate	United States	Rockford	Illinois	61107	Central	OFF-PA-10004475	Office Supplies	Paper	Xerox 1940	175.872	4	0.2	63.7536
5026	US-2014-130953	7/29/2016	8/3/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	TEC-PH-10003012	Technology	Phones	Nortel Meridian M3904 Professional Digital phone	461.97	3	0	133.9713
5478	CA-2014-169691	6/15/2016	6/18/2016	First Class	Dp-13240	Dean percer	Home Office	United States	Maple Grove	Minnesota	55369	Central	OFF-PA-10003022	Office Supplies	Paper	Xerox 1992	17.94	3	0	8.7906
8959	CA-2014-150266	11/25/2016	11/30/2016	Standard Class	RO-19780	Rose O'Brian	Consumer	United States	Houston	Texas	77070	Central	TEC-PH-10003437	Technology	Phones	Blue Parrot B250XT Professional Grade Wireless Bluetooth Headset with	299.96	5	0.2	37.495
4873	CA-2014-164042	5/23/2016	5/27/2016	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Houston	Texas	77095	Central	OFF-AP-10001947	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	18.32	5	0.8	-46.716
7796	CA-2012-112711	7/12/2014	7/18/2014	Standard Class	FM-14380	Fred McMath	Consumer	United States	Amarillo	Texas	79109	Central	TEC-PH-10000526	Technology	Phones	Vtech CS6719	307.168	4	0.2	30.7168
125	US-2011-152030	12/26/2013	12/28/2013	Second Class	AD-10180	Alan Dominguez	Home Office	United States	Houston	Texas	77041	Central	FUR-CH-10004063	Furniture	Chairs	Global Deluxe High-Back Manager's Chair	600.558	3	0.3	-8.5794
3567	CA-2014-103877	9/7/2016	9/14/2016	Standard Class	RD-19660	Robert Dilbeck	Home Office	United States	Independence	Missouri	64055	Central	OFF-BI-10003650	Office Supplies	Binders	GBC DocuBind 300 Electric Binding Machine	1577.94	3	0	757.4112
1077	CA-2013-161781	9/30/2015	10/1/2015	First Class	CC-12100	Chad Cunningham	Home Office	United States	Columbus	Indiana	47201	Central	OFF-AR-10000255	Office Supplies	Art	Newell 328	40.88	7	0	10.6288
7988	US-2013-117793	8/24/2015	8/30/2015	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Sheboygan	Wisconsin	53081	Central	OFF-LA-10002945	Office Supplies	Labels	Permanent Self-Adhesive File Folder Labels for Typewriters, 1 1/8 x 3 1/2, White	25.2	4	0	11.592
6145	CA-2014-151190	6/27/2016	7/1/2016	Standard Class	GT-14710	Greg Tran	Consumer	United States	Omaha	Nebraska	68104	Central	OFF-PA-10000575	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4 x 5 White Forms per Page	20.07	3	0	9.2322
6633	US-2013-146857	5/7/2015	5/9/2015	Second Class	BE-11455	Brad Eason	Home Office	United States	Springfield	Missouri	65807	Central	OFF-AP-10001205	Office Supplies	Appliances	Belkin 5 Outlet SurgeMaster Power Centers	54.48	1	0	15.2544
1150	CA-2012-112452	4/4/2014	4/4/2014	Same Day	NC-18340	Nat Carroll	Consumer	United States	Lansing	Michigan	48911	Central	TEC-PH-10000307	Technology	Phones	Shocksock Galaxy S4 Armband	10.95	1	0	0.438
546	CA-2011-103849	5/11/2013	5/16/2013	Standard Class	PG-18895	Paul Gonzalez	Consumer	United States	Fort Worth	Texas	76106	Central	FUR-FU-10000723	Furniture	Furnishings	Deflect-o EconoMat Studded, No Bevel Mat for Low Pile Carpeting	66.112	4	0.6	-84.2928
4139	CA-2013-117226	12/31/2015	1/2/2016	First Class	KD-16495	Keith Dawkins	Corporate	United States	Deer Park	Texas	77536	Central	OFF-BI-10004654	Office Supplies	Binders	Avery Binding System Hidden Tab Executive Style Index Sets	6.924	6	0.8	-10.386
3923	CA-2014-146920	8/28/2016	9/1/2016	Standard Class	SC-20305	Sean Christensen	Consumer	United States	Chicago	Illinois	60623	Central	OFF-PA-10002479	Office Supplies	Paper	Xerox 4200 Series MultiUse Premium Copy Paper (20Lb. and 84 Bright)	25.344	6	0.2	7.92
9920	CA-2013-149272	3/16/2015	3/20/2015	Standard Class	MY-18295	Muhammed Yedwab	Corporate	United States	Bryan	Texas	77803	Central	FUR-CH-10000863	Furniture	Chairs	Novimex Swivel Fabric Task Chair	528.43	5	0.3	-143.431
2646	CA-2011-131002	9/7/2013	9/12/2013	Second Class	TB-21400	Tom Boeckenhauer	Consumer	United States	Tulsa	Oklahoma	74133	Central	FUR-FU-10004270	Furniture	Furnishings	Executive Impressions 13" Clairmont Wall Clock	57.69	3	0	23.6529
7400	CA-2011-124807	7/12/2013	7/15/2013	Second Class	ME-17725	Max Engle	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10002857	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 1/Pack	23.84	4	0.2	3.278
244	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AR-10004685	Office Supplies	Art	Binney & Smith Crayola Metallic Colored Pencils, 8-Color Set	7.408	2	0.2	1.2038
4234	CA-2014-100223	7/5/2016	7/10/2016	Standard Class	LS-16945	Linda Southworth	Corporate	United States	Dallas	Texas	75220	Central	OFF-BI-10004492	Office Supplies	Binders	Tuf-Vin Binders	6.316	1	0.8	-10.4214
7990	US-2013-117793	8/24/2015	8/30/2015	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Sheboygan	Wisconsin	53081	Central	OFF-ST-10002406	Office Supplies	Storage	Pizazz Global Quick File	14.97	1	0	4.1916
41	CA-2012-117415	12/27/2014	12/31/2014	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Houston	Texas	77041	Central	TEC-PH-10000486	Technology	Phones	Plantronics HL10 Handset Lifter	371.168	4	0.2	41.7564
9035	CA-2012-148873	10/1/2014	10/5/2014	Standard Class	EM-13960	Eric Murdock	Consumer	United States	Quincy	Illinois	62301	Central	OFF-BI-10003196	Office Supplies	Binders	Accohide Poly Flexible Ring Binders	2.992	4	0.8	-4.488
7493	US-2014-160836	9/11/2016	9/16/2016	Standard Class	CC-12475	Cindy Chapman	Consumer	United States	Houston	Texas	77070	Central	OFF-PA-10004239	Office Supplies	Paper	Xerox 1953	10.272	3	0.2	3.21
2573	CA-2013-155845	8/13/2015	8/16/2015	Second Class	CM-12235	Chris McAfee	Consumer	United States	Carrollton	Texas	75007	Central	TEC-AC-10004145	Technology	Accessories	Logitech diNovo Edge Keyboard	1399.944	7	0.2	52.4979
8364	CA-2014-147207	1/3/2016	1/5/2016	Second Class	TS-21655	Trudy Schmidt	Consumer	United States	El Paso	Texas	79907	Central	OFF-ST-10002615	Office Supplies	Storage	Dual Level, Single-Width Filing Carts	372.144	3	0.2	27.9108
2827	US-2011-112914	9/25/2013	9/30/2013	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Houston	Texas	77041	Central	OFF-BI-10002982	Office Supplies	Binders	Avery Self-Adhesive Photo Pockets for Polaroid Photos	2.724	2	0.8	-4.3584
2152	CA-2011-167360	11/24/2013	11/29/2013	Second Class	RB-19435	Richard Bierner	Consumer	United States	Saint Louis	Missouri	63116	Central	TEC-AC-10001772	Technology	Accessories	Memorex Mini Travel Drive 16 GB USB 2.0 Flash Drive	111.79	7	0	43.5981
4701	CA-2014-140298	5/11/2016	5/17/2016	Standard Class	JK-16120	Julie Kriz	Home Office	United States	Austin	Texas	78745	Central	OFF-ST-10004180	Office Supplies	Storage	Safco Commercial Shelving	74.416	2	0.2	-14.8832
4781	CA-2011-159310	11/7/2013	11/12/2013	Standard Class	SC-20725	Steven Cartwright	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10002758	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs, Squared Back	683.144	4	0.3	0
4479	CA-2014-130211	10/22/2016	10/22/2016	Same Day	BD-11620	Brian DeCherney	Consumer	United States	Lawton	Oklahoma	73505	Central	FUR-TA-10003748	Furniture	Tables	Bevis 36 x 72 Conference Tables	248.98	2	0	54.7756
5976	CA-2014-102155	7/13/2016	7/17/2016	Standard Class	RR-19525	Rick Reed	Corporate	United States	Overland Park	Kansas	66212	Central	OFF-ST-10001496	Office Supplies	Storage	Standard Rollaway File with Lock	360.38	2	0	93.6988
7257	CA-2013-152730	5/31/2015	6/5/2015	Standard Class	EM-14140	Eugene Moren	Home Office	United States	Superior	Wisconsin	54880	Central	OFF-AR-10003732	Office Supplies	Art	Newell 333	5.56	2	0	1.4456
2598	CA-2014-149048	5/13/2016	5/17/2016	Standard Class	BM-11650	Brian Moss	Corporate	United States	Columbus	Indiana	47201	Central	OFF-ST-10000078	Office Supplies	Storage	Tennsco 6- and 18-Compartment Lockers	530.34	2	0	95.4612
9923	US-2014-162124	5/6/2016	5/10/2016	Standard Class	JF-15490	Jeremy Farry	Consumer	United States	Chicago	Illinois	60653	Central	TEC-AC-10001990	Technology	Accessories	Kensington Orbit Wireless Mobile Trackball for PC and Mac	191.968	4	0.2	28.7952
1946	CA-2013-108581	6/21/2015	6/27/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Carrollton	Texas	75007	Central	OFF-PA-10000809	Office Supplies	Paper	Xerox 206	10.368	2	0.2	3.6288
2301	CA-2011-162362	11/14/2013	11/18/2013	Standard Class	JL-15505	Jeremy Lonsdale	Consumer	United States	Midland	Michigan	48640	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	12.72	3	0	6.36
3085	CA-2014-118773	2/10/2016	2/15/2016	Standard Class	TP-21415	Tom Prescott	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10004584	Office Supplies	Binders	GBC ProClick 150 Presentation Binding System	252.784	4	0.8	-417.0936
6829	CA-2013-118689	10/3/2015	10/10/2015	Standard Class	TC-20980	Tamara Chand	Corporate	United States	Lafayette	Indiana	47905	Central	OFF-BI-10003712	Office Supplies	Binders	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Light Blue	34.37	7	0	16.8413
4227	CA-2014-120327	11/11/2016	11/16/2016	Standard Class	WB-21850	William Brown	Consumer	United States	Urbandale	Iowa	50322	Central	OFF-FA-10004854	Office Supplies	Fasteners	Vinyl Coated Wire Paper Clips in Organizer Box, 800/Box	45.92	4	0	21.5824
1061	US-2012-125374	3/23/2014	3/29/2014	Standard Class	JD-16060	Julia Dunbar	Consumer	United States	Houston	Texas	77095	Central	FUR-CH-10003396	Furniture	Chairs	Global Deluxe Steno Chair	107.772	2	0.3	-29.2524
491	CA-2011-133753	6/9/2013	6/13/2013	Second Class	CW-11905	Carl Weiss	Home Office	United States	Huntsville	Texas	77340	Central	OFF-AR-10001953	Office Supplies	Art	Boston 1645 Deluxe Heavier-Duty Electric Pencil Sharpener	70.368	2	0.2	6.1572
2138	CA-2012-156377	12/31/2014	1/5/2015	Standard Class	TB-21625	Trudy Brown	Consumer	United States	Grand Prairie	Texas	75051	Central	OFF-BI-10002954	Office Supplies	Binders	Newell 3-Hole Punched Plastic Slotted Magazine Holders for Binders	3.656	4	0.8	-5.8496
2771	US-2012-122140	4/2/2014	4/7/2014	Standard Class	MO-17950	Michael Oakman	Consumer	United States	Dallas	Texas	75220	Central	TEC-AC-10003289	Technology	Accessories	Anker Ultra-Slim Mini Bluetooth 3.0 Wireless Keyboard	47.976	3	0.2	1.7991
249	CA-2011-131926	6/1/2013	6/6/2013	Second Class	DW-13480	Dianna Wilson	Home Office	United States	Lakeville	Minnesota	55044	Central	OFF-PA-10000061	Office Supplies	Paper	Xerox 205	25.92	4	0	12.4416
9287	CA-2014-154011	6/19/2016	6/26/2016	Standard Class	DB-13270	Deborah Brumfield	Home Office	United States	Dallas	Texas	75081	Central	OFF-BI-10003166	Office Supplies	Binders	GBC Plasticlear Binding Covers	6.888	3	0.8	-11.0208
1326	US-2011-117058	5/27/2013	5/30/2013	First Class	LE-16810	Laurel Elliston	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10004139	Office Supplies	Binders	Fellowes Presentation Covers for Comb Binding Machines	17.46	6	0.8	-30.555
8493	CA-2012-109190	10/23/2014	10/28/2014	Standard Class	CC-12685	Craig Carroll	Consumer	United States	Lubbock	Texas	79424	Central	OFF-PA-10000069	Office Supplies	Paper	TOPS 4 x 6 Fluorescent Color Memo Sheets, 500 Sheets per Pack	60.736	8	0.2	20.4984
6206	CA-2013-133697	10/21/2015	10/25/2015	Second Class	CM-12445	Chuck Magee	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000726	Office Supplies	Paper	Black Print Carbonless Snap-Off Rapid Letter, 8 1/2" x 7"	51.016	7	0.2	15.9425
5982	CA-2011-117765	9/7/2013	9/13/2013	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-ST-10003327	Office Supplies	Storage	Akro-Mils 12-Gallon Tote	19.86	2	0	5.7594
6332	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-AR-10004456	Office Supplies	Art	Panasonic KP-4ABK Battery-Operated Pencil Sharpener	43.92	3	0	12.7368
658	US-2013-156097	9/20/2015	9/20/2015	Same Day	EH-14125	Eugene Hildebrand	Home Office	United States	Aurora	Illinois	60505	Central	FUR-CH-10001215	Furniture	Chairs	Global Troy Executive Leather Low-Back Tilter	701.372	2	0.3	-50.098
2494	CA-2013-146206	9/11/2015	9/15/2015	Second Class	KT-16480	Kean Thornton	Consumer	United States	Houston	Texas	77095	Central	FUR-TA-10004086	Furniture	Tables	KI Adjustable-Height Table	300.93	5	0.3	-34.392
8583	CA-2011-130673	5/20/2013	5/22/2013	Second Class	MC-17590	Matt Collister	Corporate	United States	San Marcos	Texas	78666	Central	TEC-AC-10004227	Technology	Accessories	SanDisk Ultra 16 GB MicroSDHC Class 10 Memory Card	20.784	2	0.2	-3.6372
5281	CA-2014-152709	10/7/2016	10/12/2016	Standard Class	DB-13210	Dean Braden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-ST-10001837	Office Supplies	Storage	SAFCO Mobile Desk Side File, Wire Frame	85.52	2	0	22.2352
1553	CA-2011-130274	5/3/2013	5/5/2013	First Class	JS-15940	Joni Sundaresam	Home Office	United States	Appleton	Wisconsin	54915	Central	OFF-LA-10002195	Office Supplies	Labels	Avery 481	21.56	7	0	10.3488
3271	CA-2011-115980	7/15/2013	7/19/2013	Standard Class	VW-21775	Victoria Wilson	Corporate	United States	Sioux Falls	South Dakota	57103	Central	OFF-FA-10000304	Office Supplies	Fasteners	Advantus Push Pins	6.54	3	0	2.6814
7841	US-2011-137869	3/28/2013	4/2/2013	Standard Class	CV-12295	Christina VanderZanden	Consumer	United States	Des Moines	Iowa	50315	Central	FUR-TA-10003954	Furniture	Tables	Hon 94000 Series Round Tables	1184.72	4	0	106.6248
7216	CA-2012-103072	9/27/2014	9/30/2014	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Detroit	Michigan	48205	Central	OFF-PA-10003172	Office Supplies	Paper	Xerox 1996	25.92	4	0	12.4416
1128	CA-2012-105970	3/2/2014	3/7/2014	Standard Class	PA-19060	Pete Armstrong	Home Office	United States	Richmond	Indiana	47374	Central	OFF-AR-10003156	Office Supplies	Art	50 Colored Long Pencils	10.16	1	0	2.6416
3332	CA-2014-122595	12/14/2016	12/20/2016	Standard Class	GM-14455	Gary Mitchum	Home Office	United States	Chicago	Illinois	60653	Central	TEC-AC-10000474	Technology	Accessories	Kensington Expert Mouse Optical USB Trackball for PC or Mac	227.976	3	0.2	28.497
919	CA-2013-165218	3/6/2015	3/12/2015	Standard Class	RW-19630	Rob Williams	Corporate	United States	Dallas	Texas	75220	Central	OFF-EN-10000056	Office Supplies	Envelopes	Cameo Buff Policy Envelopes	149.352	3	0.2	50.4063
6938	CA-2011-126963	6/15/2013	6/15/2013	Same Day	PS-18760	Pamela Stobb	Consumer	United States	El Paso	Texas	79907	Central	OFF-PA-10001952	Office Supplies	Paper	Xerox 1902	36.544	2	0.2	11.8768
9288	CA-2014-154011	6/19/2016	6/26/2016	Standard Class	DB-13270	Deborah Brumfield	Home Office	United States	Dallas	Texas	75081	Central	FUR-TA-10000688	Furniture	Tables	Chromcraft Bull-Nose Wood Round Conference Table Top, Wood Base	457.485	3	0.3	-84.9615
2825	US-2011-112914	9/25/2013	9/30/2013	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Houston	Texas	77041	Central	OFF-PA-10003270	Office Supplies	Paper	Xerox 1954	33.792	8	0.2	10.56
2793	CA-2011-125514	9/21/2013	9/22/2013	First Class	BM-11650	Brian Moss	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-PA-10000029	Office Supplies	Paper	Xerox 224	6.48	1	0	3.1104
47	CA-2011-146703	10/20/2013	10/25/2013	Second Class	PO-18865	Patrick O'Donnell	Consumer	United States	Westland	Michigan	48185	Central	OFF-ST-10001713	Office Supplies	Storage	Gould Plastics 9-Pocket Panel Bin, 18-3/8w x 5-1/4d x 20-1/2h, Black	211.96	4	0	8.4784
4992	US-2014-122714	12/7/2016	12/13/2016	Standard Class	HG-14965	Henry Goldwyn	Corporate	United States	Chicago	Illinois	60653	Central	OFF-BI-10001120	Office Supplies	Binders	Ibico EPK-21 Electric Binding System	1889.99	5	0.8	-2929.4845
828	CA-2014-126956	8/21/2016	8/28/2016	Standard Class	GT-14710	Greg Tran	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-SU-10000381	Office Supplies	Supplies	Acme Forged Steel Scissors with Black Enamel Handles	37.24	4	0	10.7996
4070	CA-2013-145303	8/29/2015	9/1/2015	First Class	TP-21415	Tom Prescott	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10000050	Office Supplies	Binders	Angle-D Binders with Locking Rings, Label Holders	13.14	9	0.8	-21.681
1751	CA-2012-139094	11/22/2014	11/27/2014	Standard Class	MO-17800	Meg O'Connel	Home Office	United States	San Antonio	Texas	78207	Central	FUR-TA-10004607	Furniture	Tables	Hon 2111 Invitation Series Straight Table	206.962	2	0.3	-32.5226
4131	CA-2011-115336	11/18/2013	11/25/2013	Standard Class	AB-10600	Ann Blume	Corporate	United States	Chicago	Illinois	60623	Central	OFF-BI-10001107	Office Supplies	Binders	GBC White Gloss Covers, Plain Front	14.48	5	0.8	-23.892
978	CA-2014-159366	1/8/2016	1/11/2016	First Class	BW-11110	Bart Watters	Corporate	United States	Detroit	Michigan	48205	Central	TEC-MA-10000822	Technology	Machines	Lexmark MX611dhe Monochrome Laser Printer	3059.982	2	0.1	679.996
6728	CA-2014-145443	8/10/2016	8/15/2016	Second Class	SC-20695	Steve Chapman	Corporate	United States	Richmond	Indiana	47374	Central	OFF-PA-10003302	Office Supplies	Paper	Xerox 1906	177.2	5	0	83.284
4374	US-2014-169320	7/23/2016	7/25/2016	Second Class	LH-16900	Lena Hernandez	Consumer	United States	Elkhart	Indiana	46514	Central	TEC-AC-10002550	Technology	Accessories	Memorex 25GB 6X Branded Blu-Ray Recordable Disc, 30/Pack	159.75	5	0	11.1825
3270	CA-2011-115980	7/15/2013	7/19/2013	Standard Class	VW-21775	Victoria Wilson	Corporate	United States	Sioux Falls	South Dakota	57103	Central	TEC-AC-10003709	Technology	Accessories	Maxell 4.7GB DVD-R 5/Pack	2.97	3	0	1.3068
8219	CA-2011-120775	10/3/2013	10/7/2013	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Dallas	Texas	75217	Central	FUR-FU-10000758	Furniture	Furnishings	DAX Natural Wood-Tone Poster Frame	31.776	3	0.6	-19.0656
8932	CA-2014-143252	12/18/2016	12/24/2016	Standard Class	HE-14800	Harold Engle	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-FU-10001057	Furniture	Furnishings	Tensor Track Tree Floor Lamp	99.95	5	0	22.9885
8260	CA-2013-118101	6/27/2015	6/27/2015	Same Day	SN-20560	Skye Norling	Home Office	United States	Roseville	Michigan	48066	Central	OFF-PA-10000357	Office Supplies	Paper	White Dual Perf Computer Printout Paper, 2700 Sheets, 1 Part, Heavyweight, 20 lbs., 14 7/8 x 11	368.91	9	0	180.7659
8248	CA-2012-129217	5/10/2014	5/10/2014	Same Day	DP-13390	Dennis Pardue	Home Office	United States	Aurora	Illinois	60505	Central	OFF-AR-10004602	Office Supplies	Art	Boston KS Multi-Size Manual Pencil Sharpener	36.784	2	0.2	3.6784
9033	CA-2014-105823	6/22/2016	6/26/2016	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Detroit	Michigan	48227	Central	FUR-CH-10000454	Furniture	Chairs	Hon Deluxe Fabric Upholstered Stacking Chairs, Rounded Back	487.96	2	0	146.388
9256	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	OFF-LA-10004853	Office Supplies	Labels	Avery 483	14.94	3	0	6.8724
468	US-2012-101399	1/17/2014	1/24/2014	Standard Class	JS-15940	Joni Sundaresam	Home Office	United States	Park Ridge	Illinois	60068	Central	FUR-FU-10002918	Furniture	Furnishings	Eldon ClusterMat Chair Mat with Cordless Antistatic Protection	254.744	7	0.6	-312.0614
1668	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	OFF-PA-10000167	Office Supplies	Paper	Xerox 1925	74.352	3	0.2	23.235
8531	CA-2013-156748	12/1/2015	12/7/2015	Standard Class	BS-11755	Bruce Stewart	Consumer	United States	Detroit	Michigan	48227	Central	OFF-PA-10000380	Office Supplies	Paper	REDIFORM Incoming/Outgoing Call Register, 11" X 8 1/2", 100 Messages	33.36	4	0	16.68
1469	CA-2014-139199	12/9/2016	12/13/2016	Standard Class	DK-12835	Damala Kotsonis	Corporate	United States	Detroit	Michigan	48234	Central	FUR-CH-10000847	Furniture	Chairs	Global Executive Mid-Back Manager's Chair	872.94	3	0	226.9644
5261	CA-2011-105165	9/7/2013	9/10/2013	First Class	SZ-20035	Sam Zeldin	Home Office	United States	Houston	Texas	77036	Central	TEC-PH-10000675	Technology	Phones	Panasonic KX TS3282B Corded phone	196.776	3	0.2	14.7582
8578	CA-2014-146164	12/22/2016	12/26/2016	Standard Class	CM-12190	Charlotte Melton	Consumer	United States	Rochester	Minnesota	55901	Central	FUR-TA-10004915	Furniture	Tables	Office Impressions End Table, 20-1/2"H x 24"W x 20"D	607.52	2	0	97.2032
2557	US-2013-126844	10/9/2015	10/15/2015	Standard Class	BW-11110	Bart Watters	Corporate	United States	Houston	Texas	77070	Central	FUR-FU-10004909	Furniture	Furnishings	Contemporary Wood/Metal Frame	51.712	8	0.6	-32.32
204	US-2014-116701	12/17/2016	12/21/2016	Second Class	LC-17140	Logan Currie	Consumer	United States	Dallas	Texas	75220	Central	OFF-AP-10003217	Office Supplies	Appliances	Eureka Sanitaire  Commercial Upright	66.284	2	0.8	-178.9668
667	CA-2014-132682	6/8/2016	6/10/2016	Second Class	TH-21235	Tiffany House	Corporate	United States	Dallas	Texas	75081	Central	OFF-PA-10000474	Office Supplies	Paper	Easy-staple paper	85.056	3	0.2	28.7064
2502	CA-2014-131618	6/17/2016	6/20/2016	First Class	LS-17200	Luke Schmidt	Corporate	United States	Skokie	Illinois	60076	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	2.304	4	0.8	-3.5712
7696	CA-2014-107958	7/2/2016	7/5/2016	First Class	AH-10120	Adrian Hane	Home Office	United States	Houston	Texas	77036	Central	OFF-PA-10000357	Office Supplies	Paper	White Dual Perf Computer Printout Paper, 2700 Sheets, 1 Part, Heavyweight, 20 lbs., 14 7/8 x 11	163.96	5	0.2	59.4355
6675	CA-2012-109337	11/21/2014	11/23/2014	Second Class	DL-13330	Denise Leinenbach	Consumer	United States	Lawrence	Indiana	46226	Central	OFF-AR-10003759	Office Supplies	Art	Crayola Anti Dust Chalk, 12/Pack	10.92	6	0	4.914
1041	CA-2013-127670	3/21/2015	3/25/2015	Standard Class	RD-19660	Robert Dilbeck	Home Office	United States	Saint Peters	Missouri	63376	Central	FUR-TA-10001095	Furniture	Tables	Chromcraft Round Conference Tables	697.16	4	0	146.4036
5221	CA-2011-140487	6/14/2013	6/20/2013	Standard Class	SR-20425	Sharelle Roach	Home Office	United States	Detroit	Michigan	48234	Central	FUR-BO-10000711	Furniture	Bookcases	Hon Metal Bookcases, Gray	212.94	3	0	57.4938
5541	US-2014-150595	5/22/2016	5/26/2016	Standard Class	LE-16810	Laurel Elliston	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10003274	Office Supplies	Binders	Avery Durable Slant Ring Binders, No Labels	1.592	2	0.8	-2.6268
5570	CA-2014-157966	3/13/2016	3/13/2016	Same Day	SU-20665	Stephanie Ulpright	Home Office	United States	Chicago	Illinois	60610	Central	OFF-PA-10001934	Office Supplies	Paper	Xerox 1993	15.552	3	0.2	5.6376
94	CA-2012-149587	1/31/2014	2/5/2014	Second Class	KB-16315	Karl Braun	Consumer	United States	Minneapolis	Minnesota	55407	Central	FUR-FU-10003799	Furniture	Furnishings	Seth Thomas 13 1/2" Wall Clock	53.34	3	0	16.5354
1991	CA-2012-127509	11/9/2014	11/13/2014	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	OFF-PA-10002160	Office Supplies	Paper	Xerox 1978	17.34	3	0	8.4966
6975	CA-2014-146185	9/15/2016	9/19/2016	Standard Class	CC-12145	Charles Crestani	Consumer	United States	Houston	Texas	77095	Central	OFF-AR-10002987	Office Supplies	Art	Prismacolor Color Pencil Set	31.744	2	0.2	8.3328
3416	CA-2013-116540	9/3/2015	9/3/2015	Same Day	SS-20590	Sonia Sunley	Consumer	United States	Madison	Wisconsin	53711	Central	OFF-FA-10002676	Office Supplies	Fasteners	Colored Push Pins	1.81	1	0	0.6516
2814	CA-2012-135685	11/16/2014	11/18/2014	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Milwaukee	Wisconsin	53209	Central	TEC-AC-10004145	Technology	Accessories	Logitech diNovo Edge Keyboard	999.96	4	0	229.9908
7905	CA-2012-126669	11/7/2014	11/13/2014	Standard Class	DO-13645	Doug O'Connell	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10001357	Office Supplies	Paper	Xerox 1886	76.64	2	0.2	26.824
1723	US-2012-123218	12/20/2014	12/25/2014	Standard Class	KD-16345	Katherine Ducich	Consumer	United States	Chicago	Illinois	60623	Central	TEC-AC-10000736	Technology	Accessories	Logitech G600 MMO Gaming Mouse	255.968	4	0.2	51.1936
2828	US-2011-112914	9/25/2013	9/30/2013	Standard Class	MT-18070	Michelle Tran	Home Office	United States	Houston	Texas	77041	Central	OFF-EN-10001509	Office Supplies	Envelopes	Poly String Tie Envelopes	3.264	2	0.2	1.1016
3707	CA-2014-160087	3/18/2016	3/22/2016	Standard Class	EN-13780	Edward Nazzal	Consumer	United States	Dallas	Texas	75220	Central	OFF-AR-10001915	Office Supplies	Art	Peel-Off China Markers	23.832	3	0.2	6.5538
3504	CA-2014-125115	4/10/2016	4/10/2016	Same Day	RD-19930	Russell D'Ascenzo	Consumer	United States	Austin	Texas	78745	Central	TEC-AC-10001714	Technology	Accessories	Logitech MX Performance Wireless Mouse	95.736	3	0.2	20.3439
3261	CA-2011-151554	11/14/2013	11/15/2013	First Class	CM-11815	Candace McMahon	Corporate	United States	Pasadena	Texas	77506	Central	OFF-PA-10004609	Office Supplies	Paper	Xerox 221	20.736	4	0.2	7.2576
3509	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	OFF-PA-10001166	Office Supplies	Paper	Xerox 2	15.552	3	0.2	5.4432
9950	CA-2014-121559	6/1/2016	6/3/2016	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Indianapolis	Indiana	46203	Central	TEC-AC-10004568	Technology	Accessories	Maxell LTO Ultrium - 800 GB	83.97	3	0	15.9543
2190	CA-2014-143063	8/10/2016	8/15/2016	Standard Class	IL-15100	Ivan Liston	Consumer	United States	Columbus	Indiana	47201	Central	TEC-PH-10003645	Technology	Phones	Aastra 57i VoIP phone	1454.49	9	0	378.1674
4110	CA-2012-153717	12/25/2014	1/1/2015	Standard Class	DL-13495	Dionis Lloyd	Corporate	United States	Detroit	Michigan	48227	Central	TEC-PH-10002923	Technology	Phones	Logitech B530 USB Headset - headset - Full size, Binaural	73.98	2	0	19.9746
1547	CA-2012-111395	11/23/2014	11/27/2014	Standard Class	VB-21745	Victoria Brennan	Corporate	United States	San Antonio	Texas	78207	Central	OFF-PA-10000994	Office Supplies	Paper	Xerox 1915	335.52	4	0.2	117.432
9677	US-2011-120145	11/28/2013	12/3/2013	Standard Class	MC-17635	Matthew Clasen	Corporate	United States	Richmond	Indiana	47374	Central	OFF-EN-10003862	Office Supplies	Envelopes	Laser & Ink Jet Business Envelopes	64.02	6	0	29.4492
429	CA-2014-152275	10/1/2016	10/8/2016	Standard Class	KH-16630	Ken Heidel	Corporate	United States	San Antonio	Texas	78207	Central	OFF-AR-10000369	Office Supplies	Art	Design Ebony Sketching Pencil	6.672	6	0.2	0.5004
4547	CA-2012-126557	7/12/2014	7/17/2014	Second Class	RL-19615	Rob Lucas	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10003314	Office Supplies	Binders	Tuff Stuff Recycled Round Ring Binders	1.928	2	0.8	-2.9884
1942	CA-2014-144064	8/29/2016	9/1/2016	First Class	CP-12085	Cathy Prescott	Corporate	United States	Quincy	Illinois	62301	Central	OFF-LA-10004544	Office Supplies	Labels	Avery 505	47.36	4	0.2	17.76
809	CA-2012-140921	2/3/2014	2/5/2014	First Class	AA-10375	Allen Armold	Consumer	United States	Omaha	Nebraska	68104	Central	TEC-AC-10004901	Technology	Accessories	Kensington SlimBlade Notebook Wireless Mouse with Nano Receiver 	149.97	3	0	50.9898
9983	US-2013-157728	9/23/2015	9/29/2015	Standard Class	RC-19960	Ryan Crowe	Consumer	United States	Grand Rapids	Michigan	49505	Central	OFF-PA-10002195	Office Supplies	Paper	RSVP Cards & Envelopes, Blank White, 8-1/2" X 11", 24 Cards/25 Envelopes/Set	35.56	7	0	16.7132
751	CA-2014-126074	10/2/2016	10/6/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Trenton	Michigan	48183	Central	FUR-FU-10003577	Furniture	Furnishings	Nu-Dell Leatherette Frames	157.74	11	0	56.7864
4215	CA-2013-164637	3/5/2015	3/9/2015	Standard Class	RD-19480	Rick Duston	Consumer	United States	Mishawaka	Indiana	46544	Central	OFF-BI-10003876	Office Supplies	Binders	Green Canvas Binder for 8-1/2" x 14" Sheets	128.4	3	0	64.2
6409	CA-2014-161774	5/14/2016	5/15/2016	First Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77041	Central	OFF-AR-10001446	Office Supplies	Art	Newell 309	46.2	5	0.2	5.775
6449	US-2014-119816	3/4/2016	3/6/2016	Second Class	TT-21460	Tonja Turnell	Home Office	United States	Houston	Texas	77095	Central	OFF-ST-10000918	Office Supplies	Storage	Crate-A-Files	8.72	1	0.2	0.654
6796	CA-2012-145394	11/16/2014	11/20/2014	Standard Class	MC-17605	Matt Connell	Corporate	United States	Chicago	Illinois	60610	Central	FUR-FU-10001215	Furniture	Furnishings	Howard Miller 11-1/2" Diameter Brentwood Wall Clock	34.504	2	0.6	-15.5268
5713	CA-2014-115805	7/31/2016	7/31/2016	Same Day	KW-16435	Katrina Willman	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10003092	Technology	Phones	Motorola L804	36.792	1	0.2	4.1391
6370	CA-2013-103919	10/4/2015	10/8/2015	Standard Class	TP-21565	Tracy Poddar	Corporate	United States	Grand Prairie	Texas	75051	Central	FUR-FU-10001756	Furniture	Furnishings	Eldon Expressions Desk Accessory, Wood Photo Frame, Mahogany	38.08	5	0.6	-29.512
5248	US-2012-168914	5/21/2014	5/27/2014	Standard Class	JE-15745	Joel Eaton	Consumer	United States	Frankfort	Illinois	60423	Central	OFF-AP-10000358	Office Supplies	Appliances	Fellowes Basic Home/Office Series Surge Protectors	20.768	8	0.8	-52.9584
4371	US-2013-165078	11/6/2015	11/11/2015	Standard Class	MA-17995	Michelle Arnett	Home Office	United States	Lawrence	Indiana	46226	Central	OFF-AR-10002987	Office Supplies	Art	Prismacolor Color Pencil Set	39.68	2	0	16.2688
955	CA-2014-136539	12/28/2016	1/1/2017	Standard Class	GH-14665	Greg Hansen	Consumer	United States	Round Rock	Texas	78664	Central	FUR-BO-10004709	Furniture	Bookcases	Bush Westfield Collection Bookcases, Medium Cherry Finish	78.8528	2	0.32	-11.596
9624	CA-2014-137449	6/29/2016	6/30/2016	First Class	ME-17725	Max Engle	Consumer	United States	Dallas	Texas	75220	Central	OFF-AP-10000240	Office Supplies	Appliances	Belkin F9G930V10-GRY 9 Outlet Surge	21.392	2	0.8	-54.5496
379	CA-2012-130792	4/28/2014	5/5/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Houston	Texas	77095	Central	OFF-AP-10000696	Office Supplies	Appliances	Holmes Odor Grabber	8.652	3	0.8	-20.3322
9257	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	OFF-BI-10004728	Office Supplies	Binders	Wilson Jones Turn Tabs Binder Tool for Ring Binders	9.64	2	0	4.4344
8778	CA-2013-102813	7/3/2015	7/4/2015	First Class	EA-14035	Erin Ashbrook	Corporate	United States	Huntsville	Texas	77340	Central	OFF-PA-10000520	Office Supplies	Paper	Xerox 201	41.472	8	0.2	14.5152
1180	CA-2013-168081	4/25/2015	4/28/2015	Second Class	CA-12055	Cathy Armstrong	Home Office	United States	Houston	Texas	77070	Central	TEC-AC-10003174	Technology	Accessories	Plantronics S12 Corded Telephone Headset System	258.696	3	0.2	64.674
8134	CA-2012-131352	10/8/2014	10/13/2014	Standard Class	GH-14485	Gene Hale	Corporate	United States	Dallas	Texas	75081	Central	FUR-FU-10003708	Furniture	Furnishings	Tenex Traditional Chairmats for Medium Pile Carpet, Standard Lip, 36" x 48"	72.78	3	0.6	-70.9605
8532	CA-2013-156748	12/1/2015	12/7/2015	Standard Class	BS-11755	Bruce Stewart	Consumer	United States	Detroit	Michigan	48227	Central	OFF-PA-10002713	Office Supplies	Paper	Adams Phone Message Book, 200 Message Capacity, 8 1/16” x 11”	13.76	2	0	6.3296
7563	US-2013-104815	9/4/2015	9/8/2015	Standard Class	RB-19570	Rob Beeghly	Consumer	United States	Chicago	Illinois	60610	Central	FUR-BO-10003894	Furniture	Bookcases	Safco Value Mate Steel Bookcase, Baked Enamel Finish on Steel, Black	198.744	4	0.3	0
8563	CA-2013-123540	4/3/2015	4/7/2015	Second Class	DJ-13420	Denny Joy	Corporate	United States	Milwaukee	Wisconsin	53209	Central	FUR-CH-10000847	Furniture	Chairs	Global Executive Mid-Back Manager's Chair	1454.9	5	0	378.274
102	CA-2013-158568	8/30/2015	9/3/2015	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Chicago	Illinois	60610	Central	OFF-BI-10002609	Office Supplies	Binders	Avery Hidden Tab Dividers for Binding Systems	1.788	3	0.8	-3.0396
3211	US-2014-108245	9/22/2016	9/27/2016	Standard Class	SH-19975	Sally Hughsby	Corporate	United States	Pearland	Texas	77581	Central	OFF-EN-10001415	Office Supplies	Envelopes	Staple envelope	13.392	3	0.2	5.022
181	CA-2011-166191	12/5/2013	12/9/2013	Second Class	DK-13150	David Kendrick	Corporate	United States	Decatur	Illinois	62521	Central	OFF-ST-10003455	Office Supplies	Storage	Tenex File Box, Personal Filing Tote with Lid, Black	24.816	2	0.2	1.8612
1834	CA-2014-162691	8/1/2016	8/7/2016	Standard Class	AS-10045	Aaron Smayling	Corporate	United States	Austin	Texas	78745	Central	TEC-MA-10000488	Technology	Machines	Bady BDG101FRU Card Printer	1439.982	3	0.4	-263.9967
1277	CA-2013-119186	5/27/2015	5/27/2015	Same Day	MS-17710	Maurice Satty	Consumer	United States	Fort Worth	Texas	76106	Central	TEC-AC-10000580	Technology	Accessories	Logitech G13 Programmable Gameboard with LCD Display	63.992	1	0.2	-7.1991
2514	CA-2013-124506	11/12/2015	11/18/2015	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Chicago	Illinois	60623	Central	TEC-AC-10003280	Technology	Accessories	Belkin F8E887 USB Wired Ergonomic Keyboard	95.968	4	0.2	1.1996
5719	CA-2012-124107	10/9/2014	10/12/2014	Second Class	BM-11650	Brian Moss	Corporate	United States	Ann Arbor	Michigan	48104	Central	OFF-AP-10003971	Office Supplies	Appliances	Belkin 6 Outlet Metallic Surge Strip	29.403	3	0.1	5.2272
5717	CA-2012-124107	10/9/2014	10/12/2014	Second Class	BM-11650	Brian Moss	Corporate	United States	Ann Arbor	Michigan	48104	Central	TEC-PH-10003875	Technology	Phones	KLD Oscar II Style Snap-on Ultra Thin Side Flip Synthetic Leather Cover Case for HTC One HTC M7	29.16	3	0	8.4564
4559	CA-2011-127383	12/31/2013	1/5/2014	Standard Class	CM-11815	Candace McMahon	Corporate	United States	El Paso	Texas	79907	Central	OFF-EN-10004773	Office Supplies	Envelopes	Staple envelope	49.568	2	0.2	17.9684
5027	US-2014-130953	7/29/2016	8/3/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	137.62	2	0	60.5528
1299	CA-2013-134425	12/9/2015	12/13/2015	Second Class	QJ-19255	Quincy Jones	Corporate	United States	Saint Paul	Minnesota	55106	Central	TEC-PH-10003555	Technology	Phones	Motorola HK250 Universal Bluetooth Headset	114.95	5	0	2.299
9150	US-2011-157070	6/1/2013	6/6/2013	Standard Class	QJ-19255	Quincy Jones	Corporate	United States	Detroit	Michigan	48234	Central	OFF-BI-10001765	Office Supplies	Binders	Wilson Jones Heavy-Duty Casebound Ring Binders with Metal Hinges	138.56	4	0	66.5088
4262	CA-2014-158344	8/7/2016	8/11/2016	Standard Class	CC-12475	Cindy Chapman	Consumer	United States	Moorhead	Minnesota	56560	Central	TEC-AC-10002006	Technology	Accessories	Memorex Micro Travel Drive 16 GB	63.96	4	0	19.8276
6050	CA-2013-152765	6/16/2015	6/19/2015	First Class	LS-17245	Lynn Smith	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10000483	Office Supplies	Paper	Xerox 19	173.488	7	0.2	54.215
8070	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	OFF-ST-10002743	Office Supplies	Storage	SAFCO Boltless Steel Shelving	454.56	5	0.2	-107.958
6621	US-2014-167402	1/14/2016	1/19/2016	Second Class	CP-12085	Cathy Prescott	Corporate	United States	Springfield	Missouri	65807	Central	OFF-SU-10002881	Office Supplies	Supplies	Martin Yale Chadless Opener Electric Letter Opener	4164.05	5	0	83.281
1824	CA-2013-168956	2/16/2015	2/20/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Chicago	Illinois	60623	Central	OFF-PA-10000809	Office Supplies	Paper	Xerox 206	5.184	1	0.2	1.8144
1356	US-2011-160444	7/5/2013	7/5/2013	Same Day	DC-12850	Dan Campbell	Consumer	United States	Houston	Texas	77036	Central	OFF-ST-10001522	Office Supplies	Storage	Gould Plastics 18-Pocket Panel Bin, 34w x 5-1/4d x 20-1/2h	220.776	3	0.2	-44.1552
9322	US-2013-111563	11/5/2015	11/9/2015	Standard Class	SM-20005	Sally Matthias	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10002445	Furniture	Furnishings	DAX Two-Tone Rosewood/Black Document Frame, Desktop, 5 x 7	11.376	3	0.6	-5.688
1087	CA-2013-167584	8/13/2015	8/13/2015	Same Day	LC-16870	Lena Cacioppo	Consumer	United States	Des Moines	Iowa	50315	Central	OFF-PA-10000029	Office Supplies	Paper	Xerox 224	6.48	1	0	3.1104
7747	CA-2012-109113	12/19/2014	12/23/2014	Standard Class	EK-13795	Eileen Kiefer	Home Office	United States	Chicago	Illinois	60610	Central	TEC-AC-10004761	Technology	Accessories	Maxell 4.7GB DVD+RW 3/Pack	25.488	2	0.2	4.779
6822	CA-2014-163860	12/28/2016	1/1/2017	Standard Class	LO-17170	Lori Olson	Corporate	United States	Peoria	Illinois	61604	Central	FUR-FU-10001935	Furniture	Furnishings	3M Hangers With Command Adhesive	2.96	2	0.6	-1.406
1411	CA-2014-105144	11/4/2016	11/11/2016	Standard Class	SZ-20035	Sam Zeldin	Home Office	United States	Grand Prairie	Texas	75051	Central	OFF-LA-10003923	Office Supplies	Labels	Alphabetical Labels for Top Tab Filing	23.68	2	0.2	8.88
4037	CA-2012-148859	12/28/2014	1/1/2015	Standard Class	FH-14350	Fred Harton	Consumer	United States	Chicago	Illinois	60623	Central	OFF-ST-10004950	Office Supplies	Storage	Tenex Personal Filing Tote With Secure Closure Lid, Black/Frost	24.816	2	0.2	1.551
5163	CA-2013-115378	11/19/2015	11/24/2015	Second Class	AJ-10945	Ashley Jarboe	Consumer	United States	Taylor	Michigan	48180	Central	FUR-CH-10000863	Furniture	Chairs	Novimex Swivel Fabric Task Chair	301.96	2	0	33.2156
7985	CA-2014-152499	1/23/2016	1/26/2016	Second Class	EH-13765	Edward Hooks	Corporate	United States	Chicago	Illinois	60623	Central	OFF-AR-10003481	Office Supplies	Art	Newell 348	7.872	3	0.2	0.8856
182	CA-2011-166191	12/5/2013	12/9/2013	Second Class	DK-13150	David Kendrick	Corporate	United States	Decatur	Illinois	62521	Central	TEC-AC-10004659	Technology	Accessories	Imation Secure+ Hardware Encrypted USB 2.0 Flash Drive; 16GB	408.744	7	0.2	76.6395
4429	CA-2014-119452	3/21/2016	3/27/2016	Standard Class	CL-12565	Clay Ludtke	Consumer	United States	Tulsa	Oklahoma	74133	Central	FUR-CH-10004495	Furniture	Chairs	Global Leather and Oak Executive Chair, Black	1805.88	6	0	523.7052
5767	CA-2013-149685	10/9/2015	10/16/2015	Standard Class	PM-19135	Peter McVee	Home Office	United States	San Antonio	Texas	78207	Central	OFF-LA-10004545	Office Supplies	Labels	Avery 50	60.144	6	0.2	20.2986
9102	CA-2012-163181	11/7/2014	11/12/2014	Standard Class	AB-10105	Adrian Barton	Consumer	United States	Houston	Texas	77041	Central	OFF-AR-10001683	Office Supplies	Art	Lumber Crayons	23.64	3	0.2	5.319
3327	CA-2011-165309	11/11/2013	11/15/2013	Standard Class	KD-16270	Karen Daniels	Consumer	United States	Houston	Texas	77095	Central	OFF-AR-10003582	Office Supplies	Art	Boston Electric Pencil Sharpener, Model 1818, Charcoal Black	67.56	3	0.2	6.756
1496	CA-2014-152485	9/4/2016	9/8/2016	Standard Class	JD-15790	John Dryer	Consumer	United States	Coppell	Texas	75019	Central	OFF-AR-10003759	Office Supplies	Art	Crayola Anti Dust Chalk, 12/Pack	10.192	7	0.2	3.185
5415	US-2014-125647	9/23/2016	9/28/2016	Standard Class	LC-16870	Lena Cacioppo	Consumer	United States	Chicago	Illinois	60653	Central	OFF-AP-10000390	Office Supplies	Appliances	Euro Pro Shark Stick Mini Vacuum	73.176	6	0.8	-197.5752
8381	CA-2011-103527	9/9/2013	9/14/2013	Second Class	CC-12220	Chris Cortes	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10001622	Office Supplies	Paper	Ampad Poly Cover Wirebound Steno Book, 6" x 9" Assorted Colors, Gregg Ruled	10.896	3	0.2	3.405
2612	CA-2011-127446	11/25/2013	11/30/2013	Standard Class	MC-17590	Matt Collister	Corporate	United States	Arlington	Texas	76017	Central	OFF-PA-10000955	Office Supplies	Paper	Southworth 25% Cotton Granite Paper & Envelopes	15.696	3	0.2	5.1012
1691	CA-2014-129833	12/9/2016	12/15/2016	Standard Class	HF-14995	Herbert Flentye	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-PA-10000575	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4 x 5 White Forms per Page	33.45	5	0	15.387
6074	CA-2012-120901	12/31/2014	1/4/2015	Standard Class	BG-11035	Barry Gonzalez	Consumer	United States	Austin	Texas	78745	Central	OFF-SU-10001225	Office Supplies	Supplies	Staple remover	5.888	2	0.2	-1.3248
5768	CA-2014-126396	9/8/2016	9/12/2016	Second Class	AR-10345	Alex Russell	Corporate	United States	Houston	Texas	77070	Central	TEC-AC-10003116	Technology	Accessories	Memorex Froggy Flash Drive 8 GB	85.2	6	0.2	20.235
4364	CA-2014-111332	5/20/2016	5/22/2016	Second Class	NC-18340	Nat Carroll	Consumer	United States	Fargo	North Dakota	58103	Central	OFF-AR-10001374	Office Supplies	Art	BIC Brite Liner Highlighters, Chisel Tip	25.92	4	0	8.2944
9917	CA-2014-160927	1/30/2016	2/1/2016	Second Class	TM-21010	Tamara Manning	Consumer	United States	Marion	Iowa	52302	Central	OFF-ST-10001590	Office Supplies	Storage	Tenex Personal Project File with Scoop Front Design, Black	13.48	1	0	3.5048
897	CA-2013-140634	10/4/2015	10/7/2015	Second Class	HL-15040	Hunter Lopez	Consumer	United States	Houston	Texas	77095	Central	OFF-EN-10001099	Office Supplies	Envelopes	Staple envelope	15.648	2	0.2	5.0856
2346	CA-2013-159373	3/14/2015	3/19/2015	Standard Class	LT-17110	Liz Thompson	Consumer	United States	San Antonio	Texas	78207	Central	OFF-PA-10000659	Office Supplies	Paper	TOPS Carbonless Receipt Book, Four 2-3/4 x 7-1/4 Money Receipts per Page	70.08	5	0.2	24.528
7299	CA-2011-163468	11/18/2013	11/21/2013	First Class	JK-15730	Joe Kamberova	Consumer	United States	Des Plaines	Illinois	60016	Central	FUR-TA-10002533	Furniture	Tables	BPI Conference Tables	292.1	4	0.5	-175.26
3371	CA-2013-134887	3/26/2015	3/26/2015	Same Day	TB-21280	Toby Braunhardt	Consumer	United States	Norman	Oklahoma	73071	Central	TEC-AC-10003832	Technology	Accessories	Logitech P710e Mobile Speakerphone	1287.45	5	0	244.6155
6334	CA-2011-167927	1/20/2013	1/26/2013	Standard Class	XP-21865	Xylona Preis	Consumer	United States	Westland	Michigan	48185	Central	OFF-BI-10004364	Office Supplies	Binders	Storex Dura Pro Binders	29.7	5	0	13.365
3439	CA-2014-152583	10/30/2016	10/30/2016	Same Day	RA-19945	Ryan Akin	Consumer	United States	Dallas	Texas	75217	Central	FUR-TA-10002041	Furniture	Tables	Bevis Round Conference Table Top, X-Base	251.006	2	0.3	-68.1302
4447	US-2011-147704	11/16/2013	11/21/2013	Standard Class	SR-20740	Steven Roelle	Home Office	United States	Bloomington	Indiana	47401	Central	OFF-BI-10001634	Office Supplies	Binders	Wilson Jones Active Use Binders	29.12	4	0	14.2688
8792	CA-2014-162075	3/18/2016	3/24/2016	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	TEC-PH-10001557	Technology	Phones	Pyle PMP37LED	537.544	7	0.2	47.0351
9569	CA-2014-104388	7/5/2016	7/7/2016	First Class	DK-12835	Damala Kotsonis	Corporate	United States	Fremont	Nebraska	68025	Central	TEC-PH-10002293	Technology	Phones	Anker 36W 4-Port USB Wall Charger Travel Power Adapter for iPhone 5s 5c 5	79.96	4	0	22.3888
6107	CA-2011-120852	12/20/2013	12/25/2013	Standard Class	WB-21850	William Brown	Consumer	United States	Grand Prairie	Texas	75051	Central	OFF-AP-10001563	Office Supplies	Appliances	Belkin Premiere Surge Master II 8-outlet surge protector	19.432	2	0.8	-49.5516
1471	CA-2014-139199	12/9/2016	12/13/2016	Standard Class	DK-12835	Damala Kotsonis	Corporate	United States	Detroit	Michigan	48234	Central	OFF-PA-10001293	Office Supplies	Paper	Xerox 1946	12.96	2	0	6.2208
9951	CA-2014-121559	6/1/2016	6/3/2016	Second Class	HW-14935	Helen Wasserman	Corporate	United States	Indianapolis	Indiana	46203	Central	TEC-AC-10001714	Technology	Accessories	Logitech MX Performance Wireless Mouse	39.89	1	0	14.7593
8311	CA-2011-168312	3/1/2013	3/7/2013	Standard Class	GW-14605	Giulietta Weimer	Consumer	United States	Houston	Texas	77036	Central	FUR-TA-10001866	Furniture	Tables	Bevis Round Conference Room Tables and Bases	376.509	3	0.3	-43.0296
9263	CA-2012-124499	10/9/2014	10/13/2014	Standard Class	FM-14380	Fred McMath	Consumer	United States	Detroit	Michigan	48227	Central	FUR-CH-10000513	Furniture	Chairs	High-Back Leather Manager's Chair	389.97	3	0	35.0973
679	US-2014-119438	3/18/2016	3/23/2016	Standard Class	CD-11980	Carol Darley	Consumer	United States	Tyler	Texas	75701	Central	FUR-FU-10003553	Furniture	Furnishings	Howard Miller 13-1/2" Diameter Rosebrook Wall Clock	82.524	3	0.6	-41.262
2681	CA-2014-127026	1/22/2016	1/28/2016	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Jackson	Michigan	49201	Central	TEC-AC-10002049	Technology	Accessories	Logitech G19 Programmable Gaming Keyboard	619.95	5	0	111.591
7626	CA-2012-136805	5/23/2014	5/27/2014	Second Class	NM-18445	Nathan Mautz	Home Office	United States	Detroit	Michigan	48234	Central	FUR-FU-10003724	Furniture	Furnishings	Westinghouse Clip-On Gooseneck Lamps	75.33	9	0	19.5858
8990	US-2012-128587	12/24/2014	12/30/2014	Standard Class	HM-14860	Harry Marie	Corporate	United States	Springfield	Missouri	65807	Central	FUR-FU-10003026	Furniture	Furnishings	Eldon Regeneration Recycled Desk Accessories, Black	9.68	2	0	3.7752
827	CA-2014-126956	8/21/2016	8/28/2016	Standard Class	GT-14710	Greg Tran	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-FA-10002280	Office Supplies	Fasteners	Advantus Plastic Paper Clips	35	7	0	16.8
7303	CA-2011-163468	11/18/2013	11/21/2013	First Class	JK-15730	Joe Kamberova	Consumer	United States	Des Plaines	Illinois	60016	Central	OFF-ST-10000025	Office Supplies	Storage	Fellowes Stor/Drawer Steel Plus Storage Drawers	381.72	5	0.2	-66.801
8361	CA-2014-147207	1/3/2016	1/5/2016	Second Class	TS-21655	Trudy Schmidt	Consumer	United States	El Paso	Texas	79907	Central	OFF-AR-10001955	Office Supplies	Art	Newell 319	31.744	2	0.2	3.968
2847	CA-2014-152093	9/10/2016	9/15/2016	Standard Class	SN-20560	Skye Norling	Home Office	United States	Chicago	Illinois	60653	Central	OFF-BI-10003527	Office Supplies	Binders	Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind	762.594	3	0.8	-1143.891
8768	CA-2012-107083	11/21/2014	11/27/2014	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-BI-10002194	Office Supplies	Binders	Cardinal Hold-It CD Pocket	7.98	5	0.8	-13.167
3929	CA-2013-162082	3/15/2015	3/18/2015	First Class	JS-15880	John Stevenson	Consumer	United States	Harlingen	Texas	78550	Central	FUR-BO-10004409	Furniture	Bookcases	Safco Value Mate Series Steel Bookcases, Baked Enamel Finish on Steel, Gray	241.332	5	0.32	-14.196
5310	CA-2014-131254	11/19/2016	11/21/2016	First Class	NC-18415	Nathan Cano	Consumer	United States	Houston	Texas	77095	Central	OFF-AR-10003876	Office Supplies	Art	Avery Hi-Liter GlideStik Fluorescent Highlighter, Yellow Ink	13.04	5	0.2	3.912
9790	CA-2014-144491	3/27/2016	4/1/2016	Standard Class	CJ-12010	Caroline Jumper	Consumer	United States	Houston	Texas	77070	Central	TEC-AC-10004901	Technology	Accessories	Kensington SlimBlade Notebook Wireless Mouse with Nano Receiver 	39.992	1	0.2	6.9986
442	CA-2013-115756	9/6/2015	9/8/2015	Second Class	PK-19075	Pete Kriz	Consumer	United States	Detroit	Michigan	48227	Central	OFF-ST-10000060	Office Supplies	Storage	Fellowes Bankers Box Staxonsteel Drawer File/Stacking System	194.94	3	0	23.3928
4341	US-2011-129609	3/22/2013	3/22/2013	Same Day	VM-21835	Vivian Mathis	Consumer	United States	Portage	Indiana	46368	Central	OFF-AR-10003478	Office Supplies	Art	Avery Hi-Liter EverBold Pen Style Fluorescent Highlighters, 4/Pack	16.28	2	0	6.512
1139	CA-2013-152170	11/13/2015	11/16/2015	Second Class	FH-14275	Frank Hawley	Corporate	United States	La Porte	Indiana	46350	Central	OFF-PA-10001763	Office Supplies	Paper	Xerox 1896	19.98	2	0	8.991
9963	CA-2012-168088	3/19/2014	3/22/2014	First Class	CM-12655	Corinna Mitchell	Home Office	United States	Houston	Texas	77041	Central	FUR-BO-10004218	Furniture	Bookcases	Bush Heritage Pine Collection 5-Shelf Bookcase, Albany Pine Finish, *Special Order	383.4656	4	0.32	-67.6704
9592	US-2013-105452	7/29/2015	8/2/2015	Standard Class	BF-11005	Barry Franz	Home Office	United States	Pasadena	Texas	77506	Central	FUR-FU-10003691	Furniture	Furnishings	Eldon Image Series Desk Accessories, Ebony	24.7	5	0.6	-9.88
6808	CA-2012-128125	3/31/2014	4/5/2014	Standard Class	EB-13705	Ed Braxton	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10000357	Office Supplies	Paper	White Dual Perf Computer Printout Paper, 2700 Sheets, 1 Part, Heavyweight, 20 lbs., 14 7/8 x 11	98.376	3	0.2	35.6613
3213	CA-2011-142314	12/23/2013	12/28/2013	Standard Class	SF-20200	Sarah Foster	Consumer	United States	Richmond	Indiana	47374	Central	OFF-AP-10002350	Office Supplies	Appliances	Belkin F9H710-06 7 Outlet SurgeMaster Surge Protector	207.24	11	0	58.0272
7296	CA-2011-111899	5/4/2013	5/5/2013	First Class	NC-18340	Nat Carroll	Consumer	United States	Houston	Texas	77036	Central	OFF-AR-10001725	Office Supplies	Art	Boston Home & Office Model 2000 Electric Pencil Sharpeners	37.84	2	0.2	2.838
160	CA-2013-114104	11/21/2015	11/25/2015	Standard Class	NP-18670	Nora Paige	Consumer	United States	Edmond	Oklahoma	73034	Central	TEC-PH-10004536	Technology	Phones	Avaya 5420 Digital phone	944.93	7	0	236.2325
911	CA-2014-137596	9/2/2016	9/7/2016	Standard Class	BE-11335	Bill Eplett	Home Office	United States	Jackson	Michigan	49201	Central	TEC-AC-10004666	Technology	Accessories	Maxell iVDR EX 500GB Cartridge	1928.78	7	0	829.3754
9318	CA-2014-124940	2/22/2016	2/27/2016	Standard Class	DK-13090	Dave Kipp	Consumer	United States	Carrollton	Texas	75007	Central	TEC-AC-10002076	Technology	Accessories	Microsoft Natural Keyboard Elite	47.904	1	0.2	-2.994
3763	CA-2013-156251	8/14/2015	8/19/2015	Second Class	TS-21160	Theresa Swint	Corporate	United States	West Allis	Wisconsin	53214	Central	FUR-BO-10001337	Furniture	Bookcases	O'Sullivan Living Dimensions 2-Shelf Bookcases	241.96	2	0	24.196
5049	US-2011-104759	3/31/2013	4/4/2013	Standard Class	DD-13570	Dorothy Dickinson	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10002071	Office Supplies	Binders	Fellowes Black Plastic Comb Bindings	8.134	7	0.8	-13.8278
6643	CA-2014-128328	8/5/2016	8/9/2016	Standard Class	PO-18865	Patrick O'Donnell	Consumer	United States	Indianapolis	Indiana	46203	Central	OFF-LA-10003498	Office Supplies	Labels	Avery 475	133.2	9	0	66.6
399	CA-2013-108987	9/9/2015	9/11/2015	Second Class	AG-10675	Anna Gayman	Consumer	United States	Houston	Texas	77036	Central	OFF-ST-10001580	Office Supplies	Storage	Super Decoflex Portable Personal File	35.952	3	0.2	3.5952
1990	CA-2012-127509	11/9/2014	11/13/2014	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	OFF-EN-10000781	Office Supplies	Envelopes	#10- 4 1/8" x 9 1/2" Recycled Envelopes	26.22	3	0	12.3234
7188	CA-2014-133102	8/17/2016	8/24/2016	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77095	Central	FUR-FU-10003247	Furniture	Furnishings	36X48 HARDFLOOR CHAIRMAT	16.784	2	0.6	-22.2388
8991	US-2012-128587	12/24/2014	12/30/2014	Standard Class	HM-14860	Harry Marie	Corporate	United States	Springfield	Missouri	65807	Central	TEC-CO-10003763	Technology	Copiers	Canon PC1060 Personal Laser Copier	4899.93	7	0	2302.9671
7253	CA-2013-152457	9/13/2015	9/19/2015	Standard Class	SC-20695	Steve Chapman	Corporate	United States	Roseville	Michigan	48066	Central	OFF-PA-10003790	Office Supplies	Paper	Xerox 1991	68.52	3	0	31.5192
85	US-2014-119662	11/13/2016	11/16/2016	First Class	CS-12400	Christopher Schild	Home Office	United States	Chicago	Illinois	60623	Central	OFF-ST-10003656	Office Supplies	Storage	Safco Industrial Wire Shelving	230.376	3	0.2	-48.9549
8072	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	FUR-CH-10003199	Furniture	Chairs	Office Star - Contemporary Task Swivel Chair	310.744	4	0.3	-26.6352
3031	CA-2012-168480	9/21/2014	9/27/2014	Standard Class	DM-12955	Dario Medina	Corporate	United States	Lincoln Park	Michigan	48146	Central	FUR-BO-10000468	Furniture	Bookcases	O'Sullivan 2-Shelf Heavy-Duty Bookcases	194.32	4	0	31.0912
9301	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	FUR-CH-10000225	Furniture	Chairs	Global Geo Office Task Chair, Gray	56.686	1	0.3	-20.245
9752	CA-2013-113390	10/12/2015	10/16/2015	Standard Class	EP-13915	Emily Phan	Consumer	United States	Chicago	Illinois	60610	Central	OFF-AR-10001446	Office Supplies	Art	Newell 309	27.72	3	0.2	3.465
1265	CA-2013-155992	10/2/2015	10/3/2015	First Class	CC-12220	Chris Cortes	Consumer	United States	La Porte	Indiana	46350	Central	FUR-FU-10003724	Furniture	Furnishings	Westinghouse Clip-On Gooseneck Lamps	41.85	5	0	10.881
593	CA-2011-135405	1/9/2013	1/13/2013	Standard Class	MS-17830	Melanie Seite	Consumer	United States	Laredo	Texas	78041	Central	OFF-AR-10004078	Office Supplies	Art	Newell 312	9.344	2	0.2	1.168
1010	CA-2014-135034	8/1/2016	8/3/2016	First Class	AT-10735	Annie Thurman	Consumer	United States	Chicago	Illinois	60653	Central	TEC-PH-10003931	Technology	Phones	JBL Micro Wireless Portable Bluetooth Speaker	95.984	2	0.2	5.999
4821	CA-2012-140025	4/7/2014	4/11/2014	Standard Class	PF-19120	Peter Fuller	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AP-10002651	Office Supplies	Appliances	Hoover Upright Vacuum With Dirt Cup	463.248	8	0.8	-1181.2824
7613	US-2012-130491	2/8/2014	2/11/2014	First Class	BH-11710	Brosina Hoffman	Consumer	United States	Garden City	Kansas	67846	Central	OFF-FA-10000134	Office Supplies	Fasteners	Advantus Push Pins, Aluminum Head	5.81	1	0	1.8011
774	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	OFF-BI-10003910	Office Supplies	Binders	DXL Angle-View Binders with Locking Rings by Samsill	7.71	1	0	3.4695
7946	CA-2014-134194	12/25/2016	1/1/2017	Standard Class	GA-14725	Guy Armstrong	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10001597	Office Supplies	Binders	Wilson Jones Ledger-Size, Piano-Hinge Binder, 2", Blue	40.98	5	0.8	-65.568
4758	US-2014-144582	4/30/2016	5/5/2016	Standard Class	TC-21475	Tony Chapman	Home Office	United States	Danville	Illinois	61832	Central	OFF-BI-10001575	Office Supplies	Binders	GBC Linen Binding Covers	43.372	7	0.8	-69.3952
511	CA-2014-135307	11/26/2016	11/27/2016	First Class	LS-17245	Lynn Smith	Consumer	United States	Gladstone	Missouri	64118	Central	FUR-FU-10001290	Furniture	Furnishings	Executive Impressions Supervisor Wall Clock	126.3	3	0	40.416
9576	CA-2012-143147	5/26/2014	5/28/2014	Second Class	PS-18760	Pamela Stobb	Consumer	United States	San Antonio	Texas	78207	Central	FUR-CH-10000863	Furniture	Chairs	Novimex Swivel Fabric Task Chair	105.686	1	0.3	-28.6862
3767	CA-2013-163153	3/22/2015	3/26/2015	Standard Class	DM-12955	Dario Medina	Corporate	United States	Houston	Texas	77036	Central	OFF-AR-10001868	Office Supplies	Art	Prang Dustless Chalk Sticks	1.344	1	0.2	0.504
6851	US-2013-100461	1/8/2015	1/12/2015	Standard Class	JO-15145	Jack O'Briant	Corporate	United States	Franklin	Wisconsin	53132	Central	FUR-BO-10002545	Furniture	Bookcases	Atlantic Metals Mobile 3-Shelf Bookcases, Custom Colors	1565.88	6	0	407.1288
5172	CA-2013-122903	5/28/2015	5/30/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Detroit	Michigan	48205	Central	OFF-PA-10001790	Office Supplies	Paper	Xerox 1910	144.12	3	0	69.1776
1819	US-2011-130379	5/25/2013	5/29/2013	Standard Class	JL-15235	Janet Lee	Consumer	United States	Chicago	Illinois	60623	Central	OFF-AP-10001394	Office Supplies	Appliances	Harmony Air Purifier	75.6	2	0.8	-166.32
9745	CA-2014-141782	1/22/2016	1/26/2016	Standard Class	BE-11410	Bobby Elias	Consumer	United States	Aurora	Illinois	60505	Central	OFF-EN-10002230	Office Supplies	Envelopes	Airmail Envelopes	268.576	4	0.2	90.6444
3961	CA-2012-113901	10/19/2014	10/24/2014	Standard Class	NH-18610	Nicole Hansen	Corporate	United States	Detroit	Michigan	48227	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	38.28	6	0	17.6088
917	US-2011-141215	6/15/2013	6/21/2013	Standard Class	KL-16555	Kelly Lampkin	Corporate	United States	San Antonio	Texas	78207	Central	FUR-CH-10003379	Furniture	Chairs	Global Commerce Series High-Back Swivel/Tilt Chairs	797.944	4	0.3	-56.996
3940	US-2013-143448	12/11/2015	12/11/2015	Same Day	MH-17455	Mark Hamilton	Consumer	United States	Greenwood	Indiana	46142	Central	FUR-CH-10003379	Furniture	Chairs	Global Commerce Series High-Back Swivel/Tilt Chairs	1424.9	5	0	356.225
9400	CA-2013-103128	11/12/2015	11/16/2015	Standard Class	SC-20845	Sung Chung	Consumer	United States	Arlington Heights	Illinois	60004	Central	OFF-AR-10003394	Office Supplies	Art	Newell 332	14.112	6	0.2	1.2348
4074	US-2012-164308	9/24/2014	9/27/2014	First Class	SC-20680	Steve Carroll	Home Office	United States	Broken Arrow	Oklahoma	74012	Central	TEC-PH-10004120	Technology	Phones	AT&T 1080 Phone	821.94	6	0	213.7044
8327	CA-2014-103478	7/21/2016	7/24/2016	Second Class	KL-16555	Kelly Lampkin	Corporate	United States	Aurora	Illinois	60505	Central	OFF-BI-10001890	Office Supplies	Binders	Avery Poly Binder Pockets	2.864	4	0.8	-4.5824
5311	CA-2014-131254	11/19/2016	11/21/2016	First Class	NC-18415	Nathan Cano	Consumer	United States	Houston	Texas	77095	Central	OFF-BI-10003527	Office Supplies	Binders	Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind	1525.188	6	0.8	-2287.782
3292	CA-2013-167290	10/31/2015	11/5/2015	Standard Class	JF-15295	Jason Fortune-	Consumer	United States	Sterling Heights	Michigan	48310	Central	OFF-AR-10004078	Office Supplies	Art	Newell 312	11.68	2	0	3.504
5054	CA-2012-141243	1/3/2014	1/8/2014	Second Class	AH-10465	Amy Hunt	Consumer	United States	Dallas	Texas	75217	Central	TEC-AC-10003198	Technology	Accessories	Enermax Acrylux Wireless Keyboard	398.4	5	0.2	84.66
8765	CA-2012-107083	11/21/2014	11/27/2014	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-AR-10002257	Office Supplies	Art	Eldon Spacemaker Box, Quick-Snap Lid, Clear	5.344	2	0.2	0.7348
8074	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	6.47	5	0.8	-9.705
4811	CA-2012-151589	12/27/2014	12/30/2014	First Class	RE-19450	Richard Eichhorn	Consumer	United States	Eau Claire	Wisconsin	54703	Central	TEC-PH-10004345	Technology	Phones	Cisco SPA 502G IP Phone	239.9	2	0	71.97
8222	CA-2011-120775	10/3/2013	10/7/2013	Standard Class	RD-19930	Russell D'Ascenzo	Consumer	United States	Dallas	Texas	75217	Central	OFF-FA-10000254	Office Supplies	Fasteners	Sterling Rubber Bands by Alliance	15.072	4	0.2	-3.768
3305	CA-2011-104738	12/30/2013	1/1/2014	Second Class	SP-20620	Stefania Perrino	Corporate	United States	Laredo	Texas	78041	Central	OFF-EN-10004955	Office Supplies	Envelopes	Fashion Color Clasp Envelopes	12.984	3	0.2	4.7067
4100	CA-2011-116904	9/23/2013	9/28/2013	Standard Class	SC-20095	Sanjit Chand	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10000301	Office Supplies	Binders	GBC Instant Report Kit	12.94	2	0	6.47
9255	CA-2011-168368	2/11/2013	2/15/2013	Second Class	GA-14725	Guy Armstrong	Consumer	United States	Columbia	Missouri	65203	Central	FUR-CH-10001146	Furniture	Chairs	Global Value Mid-Back Manager's Chair, Gray	60.89	1	0	15.2225
7223	CA-2014-113075	9/2/2016	9/6/2016	Standard Class	MC-18100	Mick Crebagga	Consumer	United States	Chicago	Illinois	60623	Central	TEC-AC-10003441	Technology	Accessories	Kingston Digital DataTraveler 32GB USB 2.0	40.68	3	0.2	-7.119
3308	CA-2011-104738	12/30/2013	1/1/2014	Second Class	SP-20620	Stefania Perrino	Corporate	United States	Laredo	Texas	78041	Central	OFF-BI-10002160	Office Supplies	Binders	Acco Hanging Data Binders	2.286	3	0.8	-3.6576
2123	CA-2014-167381	9/22/2016	9/24/2016	Second Class	EH-14005	Erica Hernandez	Home Office	United States	Lansing	Michigan	48911	Central	FUR-BO-10001972	Furniture	Bookcases	O'Sullivan 4-Shelf Bookcase in Odessa Pine	241.96	2	0	41.1332
3234	US-2014-156356	4/16/2016	4/22/2016	Standard Class	ND-18370	Natalie DeCherney	Consumer	United States	Houston	Texas	77095	Central	OFF-ST-10002301	Office Supplies	Storage	Tennsco Commercial Shelving	32.544	2	0.2	-7.7292
9860	CA-2014-113278	1/15/2016	1/21/2016	Standard Class	HR-14770	Hallie Redmond	Home Office	United States	Richmond	Indiana	47374	Central	OFF-FA-10003472	Office Supplies	Fasteners	Bagged Rubber Bands	2.52	2	0	0.1008
771	CA-2014-104220	1/31/2016	2/6/2016	Standard Class	BV-11245	Benjamin Venier	Corporate	United States	Des Moines	Iowa	50315	Central	OFF-BI-10001036	Office Supplies	Binders	Cardinal EasyOpen D-Ring Binders	18.28	2	0	9.14
7136	CA-2014-141439	11/26/2016	12/1/2016	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Richmond	Indiana	47374	Central	FUR-CH-10004287	Furniture	Chairs	SAFCO Arco Folding Chair	828.6	3	0	240.294
4730	CA-2013-124681	7/19/2015	7/24/2015	Second Class	SV-20935	Susan Vittorini	Consumer	United States	Dallas	Texas	75217	Central	TEC-AC-10000487	Technology	Accessories	SanDisk Cruzer 4 GB USB Flash Drive	15.576	3	0.2	3.3099
5199	CA-2013-103982	3/4/2015	3/9/2015	Standard Class	AA-10315	Alex Avila	Consumer	United States	Round Rock	Texas	78664	Central	OFF-SU-10000151	Office Supplies	Supplies	High Speed Automatic Electric Letter Opener	3930.072	3	0.2	-786.0144
110	CA-2012-129476	10/15/2014	10/20/2014	Standard Class	PA-19060	Pete Armstrong	Home Office	United States	Orland Park	Illinois	60462	Central	TEC-AC-10000844	Technology	Accessories	Logitech Gaming G510s - Keyboard	339.96	5	0.2	67.992
1964	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	OFF-PA-10002586	Office Supplies	Paper	Xerox 1970	24.9	5	0	11.703
5492	CA-2014-164098	1/27/2016	1/28/2016	First Class	CG-12520	Claire Gute	Consumer	United States	Houston	Texas	77070	Central	OFF-ST-10000615	Office Supplies	Storage	SimpliFile Personal File, Black Granite, 15w x 6-15/16d x 11-1/4h	18.16	2	0.2	1.816
241	CA-2013-157749	6/5/2015	6/10/2015	Second Class	KL-16645	Ken Lonsdale	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10000011	Technology	Phones	PureGear Roll-On Screen Protector	31.984	2	0.2	11.1944
6713	CA-2014-107629	12/14/2016	12/14/2016	Same Day	DB-13060	Dave Brooks	Consumer	United States	Skokie	Illinois	60076	Central	FUR-FU-10002298	Furniture	Furnishings	Rubbermaid ClusterMat Chairmats, Mat Size- 66" x 60", Lip 20" x 11" -90 Degree Angle	266.352	6	0.6	-292.9872
3239	US-2013-127971	11/21/2015	11/28/2015	Standard Class	DW-13195	David Wiener	Corporate	United States	Houston	Texas	77095	Central	FUR-CH-10003774	Furniture	Chairs	Global Wood Trimmed Manager's Task Chair, Khaki	318.43	5	0.3	-77.333
6073	CA-2012-120901	12/31/2014	1/4/2015	Standard Class	BG-11035	Barry Gonzalez	Consumer	United States	Austin	Texas	78745	Central	OFF-FA-10001561	Office Supplies	Fasteners	Stockwell Push Pins	3.488	2	0.2	0.5668
1902	CA-2013-151141	8/21/2015	8/24/2015	First Class	DW-13480	Dianna Wilson	Home Office	United States	Detroit	Michigan	48205	Central	TEC-PH-10004924	Technology	Phones	SKILCRAFT Telephone Shoulder Rest, 2" x 6.5" x 2.5", Black	14.78	2	0	3.9906
2503	CA-2014-131618	6/17/2016	6/20/2016	First Class	LS-17200	Luke Schmidt	Corporate	United States	Skokie	Illinois	60076	Central	OFF-BI-10001294	Office Supplies	Binders	Fellowes Binding Cases	9.36	4	0.8	-16.38
9916	CA-2014-160927	1/30/2016	2/1/2016	Second Class	TM-21010	Tamara Manning	Consumer	United States	Marion	Iowa	52302	Central	OFF-PA-10000176	Office Supplies	Paper	Xerox 1887	94.85	5	0	45.528
5072	CA-2011-124478	8/8/2013	8/12/2013	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Trenton	Michigan	48183	Central	FUR-FU-10002088	Furniture	Furnishings	Nu-Dell Float Frame 11 x 14 1/2	53.88	6	0	22.6296
9791	CA-2014-144491	3/27/2016	4/1/2016	Standard Class	CJ-12010	Caroline Jumper	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10001714	Furniture	Chairs	Global Leather & Oak Executive Chair, Burgundy	211.246	2	0.3	-66.3916
2905	CA-2013-153577	6/28/2015	7/2/2015	Standard Class	KH-16330	Katharine Harms	Corporate	United States	Highland Park	Illinois	60035	Central	FUR-CH-10003981	Furniture	Chairs	Global Commerce Series Low-Back Swivel/Tilt Chairs	539.658	3	0.3	-7.7094
6201	CA-2012-146675	4/16/2014	4/20/2014	Standard Class	SB-20185	Sarah Brown	Consumer	United States	Evanston	Illinois	60201	Central	TEC-CO-10001766	Technology	Copiers	Canon PC940 Copier	1439.968	4	0.2	485.9892
7630	CA-2011-162089	3/30/2013	4/1/2013	First Class	MP-17470	Mark Packer	Home Office	United States	Brownsville	Texas	78521	Central	OFF-EN-10002230	Office Supplies	Envelopes	Airmail Envelopes	335.72	5	0.2	113.3055
6221	CA-2013-160220	10/21/2015	10/27/2015	Standard Class	JS-16030	Joy Smith	Consumer	United States	Trenton	Michigan	48183	Central	OFF-ST-10000617	Office Supplies	Storage	Woodgrain Magazine Files by Perma	20.86	7	0	1.4602
8150	CA-2011-167997	1/26/2013	1/29/2013	First Class	CA-11965	Carol Adams	Corporate	United States	Rapid City	South Dakota	57701	Central	OFF-BI-10001758	Office Supplies	Binders	Wilson Jones 14 Line Acrylic Coated Pressboard Data Binders	10.68	2	0	5.0196
7729	CA-2013-106915	11/27/2015	12/3/2015	Standard Class	GA-14515	George Ashbrook	Consumer	United States	El Paso	Texas	79907	Central	OFF-AR-10000716	Office Supplies	Art	DIXON Ticonderoga Erasable Checking Pencils	17.856	4	0.2	4.2408
2333	CA-2014-169285	3/21/2016	3/25/2016	Standard Class	RW-19690	Robert Waldorf	Consumer	United States	Lafayette	Indiana	47905	Central	OFF-PA-10004071	Office Supplies	Paper	Eaton Premium Continuous-Feed Paper, 25% Cotton, Letter Size, White, 1000 Shts/Box	277.4	5	0	133.152
5352	CA-2013-123932	9/7/2015	9/13/2015	Standard Class	YC-21895	Yoseph Carroll	Corporate	United States	Dallas	Texas	75217	Central	OFF-PA-10004665	Office Supplies	Paper	Advantus Motivational Note Cards	41.92	4	0.2	15.196
8414	CA-2013-147109	12/18/2015	12/22/2015	Standard Class	AH-10075	Adam Hart	Corporate	United States	Arlington	Texas	76017	Central	OFF-PA-10001972	Office Supplies	Paper	Xerox 214	51.84	10	0.2	18.144
9224	CA-2014-121160	11/4/2016	11/4/2016	Same Day	FM-14290	Frank Merwin	Home Office	United States	Bryan	Texas	77803	Central	OFF-BI-10001308	Office Supplies	Binders	GBC Standard Plastic Binding Systems' Combs	7.536	6	0.8	-13.188
8560	CA-2013-132829	12/24/2015	12/27/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Houston	Texas	77041	Central	TEC-PH-10004345	Technology	Phones	Cisco SPA 502G IP Phone	287.88	3	0.2	35.985
1713	CA-2012-145401	1/30/2014	2/4/2014	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Houston	Texas	77070	Central	OFF-PA-10004405	Office Supplies	Paper	Rediform Voice Mail Log Books	14.304	6	0.2	5.0064
4674	CA-2013-133550	8/1/2015	8/7/2015	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Detroit	Michigan	48205	Central	TEC-PH-10001079	Technology	Phones	Polycom SoundPoint Pro SE-225 Corded phone	118.99	1	0	33.3172
5898	CA-2013-167682	4/4/2015	4/10/2015	Standard Class	ZD-21925	Zuschuss Donatelli	Consumer	United States	Richmond	Indiana	47374	Central	FUR-FU-10003799	Furniture	Furnishings	Seth Thomas 13 1/2" Wall Clock	71.12	4	0	22.0472
1897	CA-2014-141789	10/3/2016	10/6/2016	First Class	AC-10450	Amy Cox	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10001359	Office Supplies	Binders	GBC DocuBind TL300 Electric Binding System	1793.98	2	0	843.1706
7173	US-2014-141677	3/26/2016	3/30/2016	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Houston	Texas	77070	Central	TEC-AC-10000158	Technology	Accessories	Sony 64GB Class 10 Micro SDHC R40 Memory Card	143.96	5	0.2	1.7995
4099	CA-2011-116904	9/23/2013	9/28/2013	Standard Class	SC-20095	Sanjit Chand	Consumer	United States	Minneapolis	Minnesota	55407	Central	OFF-BI-10001120	Office Supplies	Binders	Ibico EPK-21 Electric Binding System	9449.95	5	0	4630.4755
7176	US-2014-141677	3/26/2016	3/30/2016	Standard Class	HK-14890	Heather Kirkland	Corporate	United States	Houston	Texas	77070	Central	OFF-AP-10001205	Office Supplies	Appliances	Belkin 5 Outlet SurgeMaster Power Centers	87.168	8	0.8	-226.6368
3360	CA-2013-139234	5/7/2015	5/11/2015	Standard Class	AF-10870	Art Ferguson	Consumer	United States	Chicago	Illinois	60610	Central	TEC-AC-10004510	Technology	Accessories	Logitech Desktop MK120 Mouse and keyboard Combo	26.176	2	0.2	-3.272
8513	CA-2013-144645	2/2/2015	2/8/2015	Standard Class	NS-18640	Noel Staavos	Corporate	United States	Houston	Texas	77041	Central	FUR-FU-10003601	Furniture	Furnishings	Deflect-o RollaMat Studded, Beveled Mat for Medium Pile Carpeting	73.784	2	0.6	-77.4732
8604	US-2013-116365	1/3/2015	1/8/2015	Standard Class	CA-12310	Christine Abelman	Corporate	United States	San Antonio	Texas	78207	Central	TEC-AC-10002217	Technology	Accessories	Imation Clip USB flash drive - 8 GB	30.08	2	0.2	-5.264
2347	CA-2013-159373	3/14/2015	3/19/2015	Standard Class	LT-17110	Liz Thompson	Consumer	United States	San Antonio	Texas	78207	Central	OFF-BI-10004141	Office Supplies	Binders	Insertable Tab Indexes For Data Binders	1.272	2	0.8	-2.1624
3251	CA-2013-157868	12/24/2015	12/30/2015	Standard Class	MC-17590	Matt Collister	Corporate	United States	Grand Rapids	Michigan	49505	Central	OFF-FA-10000992	Office Supplies	Fasteners	Acco Clips to Go Binder Clips, 24 Clips in Two Sizes	24.85	7	0	11.6795
7072	CA-2013-112256	7/24/2015	7/29/2015	Standard Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Mcallen	Texas	78501	Central	OFF-AR-10001216	Office Supplies	Art	Newell 339	4.448	2	0.2	0.3336
3996	CA-2012-105627	3/8/2014	3/12/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Kenosha	Wisconsin	53142	Central	FUR-CH-10002084	Furniture	Chairs	Hon Mobius Operator's Chair	860.93	7	0	189.4046
2770	US-2012-122140	4/2/2014	4/7/2014	Standard Class	MO-17950	Michael Oakman	Consumer	United States	Dallas	Texas	75220	Central	TEC-AC-10003038	Technology	Accessories	Kingston Digital DataTraveler 16GB USB 2.0	50.12	7	0.2	-0.6265
9485	CA-2013-164770	12/3/2015	12/5/2015	Second Class	MY-18295	Muhammed Yedwab	Corporate	United States	Houston	Texas	77036	Central	FUR-BO-10003893	Furniture	Bookcases	Sauder Camden County Collection Library	781.864	10	0.32	-137.976
6916	CA-2011-142510	12/22/2013	12/29/2013	Standard Class	NP-18700	Nora Preis	Consumer	United States	Chicago	Illinois	60623	Central	OFF-BI-10002824	Office Supplies	Binders	Recycled Easel Ring Binders	17.904	6	0.8	-31.332
1972	CA-2014-140242	5/6/2016	5/11/2016	Standard Class	ML-17755	Max Ludwig	Home Office	United States	Chicago	Illinois	60623	Central	TEC-AC-10004659	Technology	Accessories	Imation Secure+ Hardware Encrypted USB 2.0 Flash Drive; 16GB	408.744	7	0.2	76.6395
1823	CA-2013-168956	2/16/2015	2/20/2015	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Chicago	Illinois	60623	Central	FUR-CH-10004754	Furniture	Chairs	Global Stack Chair with Arms, Black	62.958	3	0.3	-2.6982
1568	CA-2012-129112	11/29/2014	11/30/2014	First Class	AW-10840	Anthony Witt	Consumer	United States	Allen	Texas	75002	Central	OFF-BI-10000088	Office Supplies	Binders	GBC Imprintable Covers	8.784	4	0.8	-13.6152
67	US-2012-164175	4/30/2014	5/5/2014	Standard Class	PS-18970	Paul Stevenson	Home Office	United States	Chicago	Illinois	60610	Central	FUR-CH-10001146	Furniture	Chairs	Global Value Mid-Back Manager's Chair, Gray	213.115	5	0.3	-15.2225
6619	US-2014-167402	1/14/2016	1/19/2016	Second Class	CP-12085	Cathy Prescott	Corporate	United States	Springfield	Missouri	65807	Central	OFF-PA-10004983	Office Supplies	Paper	Xerox 23	32.4	5	0	15.552
3955	CA-2011-133228	4/4/2013	4/9/2013	Standard Class	MS-17710	Maurice Satty	Consumer	United States	Detroit	Michigan	48205	Central	FUR-FU-10004020	Furniture	Furnishings	Advantus Panel Wall Acrylic Frame	5.47	1	0	2.3521
7579	CA-2013-138597	12/19/2015	12/22/2015	First Class	PN-18775	Parhena Norris	Home Office	United States	Omaha	Nebraska	68104	Central	FUR-CH-10004997	Furniture	Chairs	Hon Every-Day Series Multi-Task Chairs	563.94	3	0	112.788
9493	CA-2014-163188	11/7/2016	11/7/2016	Same Day	EC-14050	Erin Creighton	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	38.16	9	0	19.08
6159	CA-2013-104150	8/4/2015	8/6/2015	Second Class	AG-10330	Alex Grayson	Consumer	United States	Tulsa	Oklahoma	74133	Central	TEC-AC-10004803	Technology	Accessories	Sony Micro Vault Click 4 GB USB 2.0 Flash Drive	167.28	12	0	23.4192
8024	CA-2011-129189	7/21/2013	7/25/2013	Standard Class	HM-14860	Harry Marie	Corporate	United States	Dallas	Texas	75217	Central	FUR-CH-10004997	Furniture	Chairs	Hon Every-Day Series Multi-Task Chairs	657.93	5	0.3	-93.99
4530	CA-2013-134691	11/15/2015	11/19/2015	Standard Class	KC-16540	Kelly Collister	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10002393	Office Supplies	Binders	Binder Posts	2.296	2	0.8	-3.9032
5604	CA-2013-117919	8/28/2015	8/30/2015	Second Class	TB-21355	Todd Boyes	Corporate	United States	Houston	Texas	77041	Central	OFF-PA-10004353	Office Supplies	Paper	Southworth 25% Cotton Premium Laser Paper and Envelopes	79.92	5	0.2	27.972
1906	CA-2014-154410	10/21/2016	10/24/2016	First Class	MD-17860	Michael Dominguez	Corporate	United States	Indianapolis	Indiana	46203	Central	OFF-ST-10002743	Office Supplies	Storage	SAFCO Boltless Steel Shelving	909.12	8	0	9.0912
6984	CA-2013-116526	9/2/2015	9/6/2015	Standard Class	JA-15970	Joseph Airdo	Consumer	United States	Detroit	Michigan	48227	Central	TEC-PH-10002365	Technology	Phones	Belkin Grip Candy Sheer Case / Cover for iPhone 5 and 5S	8.78	1	0	2.2828
7073	CA-2013-112256	7/24/2015	7/29/2015	Standard Class	CK-12205	Chloris Kastensmidt	Consumer	United States	Mcallen	Texas	78501	Central	OFF-PA-10004355	Office Supplies	Paper	Xerox 231	5.184	1	0.2	1.8144
1943	CA-2014-144064	8/29/2016	9/1/2016	First Class	CP-12085	Cathy Prescott	Corporate	United States	Quincy	Illinois	62301	Central	OFF-ST-10004507	Office Supplies	Storage	Advantus Rolling Storage Box	27.44	2	0.2	2.401
6265	US-2013-115952	10/7/2015	10/7/2015	Same Day	JH-15910	Jonathan Howell	Consumer	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10004654	Office Supplies	Binders	Avery Binding System Hidden Tab Executive Style Index Sets	28.85	5	0	14.425
1853	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	OFF-EN-10000483	Office Supplies	Envelopes	White Envelopes, White Envelopes with Clear Poly Window	106.75	7	0	49.105
3055	CA-2013-128517	4/10/2015	4/15/2015	Second Class	SW-20350	Sean Wendt	Home Office	United States	Detroit	Michigan	48227	Central	OFF-BI-10000831	Office Supplies	Binders	Storex Flexible Poly Binders with Double Pockets	5.28	2	0	2.4288
3867	CA-2014-146360	4/23/2016	4/25/2016	Second Class	SC-20305	Sean Christensen	Consumer	United States	Lawrence	Indiana	46226	Central	TEC-AC-10003590	Technology	Accessories	TRENDnet 56K USB 2.0 Phone, Internet and Fax Modem	155.34	6	0	55.9224
3094	CA-2012-114468	8/23/2014	8/23/2014	Same Day	TD-20995	Tamara Dahlen	Consumer	United States	Bolingbrook	Illinois	60440	Central	OFF-SU-10004231	Office Supplies	Supplies	Acme Tagit Stainless Steel Antibacterial Scissors	31.68	4	0.2	2.772
52	CA-2012-115742	4/18/2014	4/22/2014	Standard Class	DP-13000	Darren Powers	Consumer	United States	New Albany	Indiana	47150	Central	FUR-FU-10001706	Furniture	Furnishings	Longer-Life Soft White Bulbs	6.16	2	0	2.9568
470	US-2013-100419	12/17/2015	12/21/2015	Second Class	CC-12670	Craig Carreira	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10002194	Office Supplies	Binders	Cardinal Hold-It CD Pocket	4.788	3	0.8	-7.9002
7300	CA-2011-163468	11/18/2013	11/21/2013	First Class	JK-15730	Joe Kamberova	Consumer	United States	Des Plaines	Illinois	60016	Central	FUR-FU-10001546	Furniture	Furnishings	Dana Swing-Arm Lamps	8.544	2	0.6	-7.476
3295	CA-2011-138023	8/15/2013	8/18/2013	First Class	KH-16510	Keith Herrera	Consumer	United States	Dallas	Texas	75081	Central	OFF-BI-10003638	Office Supplies	Binders	GBC Durable Plastic Covers	30.96	8	0.8	-52.632
2789	US-2011-117744	12/2/2013	12/6/2013	Standard Class	MD-17860	Michael Dominguez	Corporate	United States	Corpus Christi	Texas	78415	Central	OFF-AR-10000940	Office Supplies	Art	Newell 343	16.464	7	0.2	1.4406
2107	US-2011-152723	9/26/2013	9/26/2013	Same Day	HG-14965	Henry Goldwyn	Corporate	United States	Mesquite	Texas	75150	Central	OFF-BI-10003460	Office Supplies	Binders	Acco 3-Hole Punch	0.876	1	0.8	-1.4016
523	CA-2014-145142	1/24/2016	1/26/2016	First Class	MC-17605	Matt Connell	Corporate	United States	Detroit	Michigan	48234	Central	FUR-TA-10001857	Furniture	Tables	Balt Solid Wood Rectangular Table	210.98	2	0	21.098
5452	US-2011-119081	9/12/2013	9/19/2013	Standard Class	TA-21385	Tom Ashbrook	Home Office	United States	Olathe	Kansas	66062	Central	FUR-FU-10003464	Furniture	Furnishings	Seth Thomas 8 1/2" Cubicle Clock	40.56	2	0	12.9792
5292	CA-2011-146283	9/8/2013	9/15/2013	Standard Class	KT-16465	Kean Takahito	Consumer	United States	Houston	Texas	77036	Central	OFF-PA-10000482	Office Supplies	Paper	Snap-A-Way Black Print Carbonless Ruled Speed Letter, Triplicate	182.112	6	0.2	61.4628
1667	CA-2013-128531	11/25/2015	11/27/2015	Second Class	NS-18505	Neola Schneider	Consumer	United States	Dallas	Texas	75217	Central	TEC-AC-10003023	Technology	Accessories	Logitech G105 Gaming Keyboard	94.992	2	0.2	-2.3748
4698	US-2012-138121	12/17/2014	12/17/2014	Same Day	JL-15835	John Lee	Consumer	United States	Detroit	Michigan	48205	Central	FUR-CH-10003817	Furniture	Chairs	Global Value Steno Chair, Gray	546.66	9	0	136.665
9357	CA-2012-110324	12/1/2014	12/5/2014	Standard Class	MA-17560	Matt Abelman	Home Office	United States	Jackson	Michigan	49201	Central	OFF-PA-10001776	Office Supplies	Paper	Wirebound Message Books, Four 2 3/4" x 5" Forms per Page, 600 Sets per Book	18.54	2	0	8.7138
4872	CA-2014-164042	5/23/2016	5/27/2016	Standard Class	KL-16645	Ken Lonsdale	Consumer	United States	Houston	Texas	77095	Central	OFF-FA-10000840	Office Supplies	Fasteners	OIC Thumb-Tacks	1.824	2	0.2	0.6156
8268	CA-2014-121790	1/31/2016	2/7/2016	Standard Class	LP-17095	Liz Preis	Consumer	United States	Aurora	Illinois	60505	Central	FUR-TA-10003469	Furniture	Tables	Balt Split Level Computer Training Table	69.375	1	0.5	-47.175
8723	CA-2013-120824	6/13/2015	6/17/2015	Second Class	AW-10930	Arthur Wiediger	Home Office	United States	Houston	Texas	77070	Central	OFF-BI-10001525	Office Supplies	Binders	Acco Pressboard Covers with Storage Hooks, 14 7/8" x 11", Executive Red	1.524	2	0.8	-2.667
6035	US-2012-155369	4/19/2014	4/25/2014	Standard Class	PG-18820	Patrick Gardner	Consumer	United States	Carrollton	Texas	75007	Central	OFF-AP-10002578	Office Supplies	Appliances	Fellowes Premier Superior Surge Suppressor, 10-Outlet, With Phone and Remote	19.568	2	0.8	-52.8336
9795	CA-2011-127166	5/21/2013	5/23/2013	Second Class	KH-16360	Katherine Hughes	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10000977	Office Supplies	Binders	Ibico Plastic Spiral Binding Combs	18.24	3	0.8	-31.008
189	CA-2013-157000	7/17/2015	7/23/2015	Standard Class	AM-10360	Alice McCarthy	Corporate	United States	Grand Prairie	Texas	75051	Central	OFF-PA-10001950	Office Supplies	Paper	Southworth 25% Cotton Antique Laid Paper & Envelopes	20.016	3	0.2	6.255
6828	CA-2013-118689	10/3/2015	10/10/2015	Standard Class	TC-20980	Tamara Chand	Corporate	United States	Lafayette	Indiana	47905	Central	OFF-BI-10004600	Office Supplies	Binders	Ibico Ibimaster 300 Manual Binding System	735.98	2	0	331.191
4102	US-2014-102288	6/19/2016	6/23/2016	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77095	Central	OFF-AP-10002906	Office Supplies	Appliances	Hoover Replacement Belt for Commercial Guardsman Heavy-Duty Upright Vacuum	0.444	1	0.8	-1.11
372	CA-2014-104745	5/29/2016	6/4/2016	Standard Class	GT-14755	Guy Thornton	Consumer	United States	Harlingen	Texas	78550	Central	OFF-ST-10002205	Office Supplies	Storage	File Shuttle I and Handi-File	53.424	3	0.2	4.6746
4572	US-2012-152128	5/25/2014	5/27/2014	Second Class	NM-18445	Nathan Mautz	Home Office	United States	Wichita	Kansas	67212	Central	OFF-BI-10001718	Office Supplies	Binders	GBC DocuBind P50 Personal Binding Machine	127.96	2	0	60.1412
5728	CA-2014-117324	12/8/2016	12/13/2016	Standard Class	JP-15520	Jeremy Pistek	Consumer	United States	Madison	Wisconsin	53711	Central	TEC-AC-10003023	Technology	Accessories	Logitech G105 Gaming Keyboard	178.11	3	0	32.0598
5801	CA-2011-123225	7/11/2013	7/14/2013	First Class	MN-17935	Michael Nguyen	Consumer	United States	El Paso	Texas	79907	Central	TEC-PH-10000895	Technology	Phones	Polycom VVX 310 VoIP phone	575.968	4	0.2	43.1976
2680	CA-2014-127026	1/22/2016	1/28/2016	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Jackson	Michigan	49201	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	14.4	5	0	7.056
7187	CA-2014-133102	8/17/2016	8/24/2016	Standard Class	ED-13885	Emily Ducich	Home Office	United States	Houston	Texas	77095	Central	FUR-CH-10002017	Furniture	Chairs	SAFCO Optional Arm Kit for Workspace Cribbage Stacking Chair	74.592	4	0.3	-2.1312
6620	US-2014-167402	1/14/2016	1/19/2016	Second Class	CP-12085	Cathy Prescott	Corporate	United States	Springfield	Missouri	65807	Central	OFF-AR-10004010	Office Supplies	Art	Hunt Boston Vacuum Mount KS Pencil Sharpener	209.94	6	0	54.5844
7632	CA-2011-162089	3/30/2013	4/1/2013	First Class	MP-17470	Mark Packer	Home Office	United States	Brownsville	Texas	78521	Central	FUR-CH-10002304	Furniture	Chairs	Global Stack Chair without Arms, Black	127.302	7	0.3	-9.093
5202	CA-2013-103982	3/4/2015	3/9/2015	Standard Class	AA-10315	Alex Avila	Consumer	United States	Round Rock	Texas	78664	Central	TEC-AC-10002857	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 1/Pack	41.72	7	0.2	5.7365
6676	CA-2012-109337	11/21/2014	11/23/2014	Second Class	DL-13330	Denise Leinenbach	Consumer	United States	Lawrence	Indiana	46226	Central	TEC-MA-10002930	Technology	Machines	Ricoh - Ink Collector Unit for GX3000 Series Printers	83.9	2	0	22.653
9737	US-2012-100069	6/29/2014	7/3/2014	Standard Class	NF-18475	Neil Französisch	Home Office	United States	Omaha	Nebraska	68104	Central	TEC-PH-10004667	Technology	Phones	Cisco 8x8 Inc. 6753i IP Business Phone System	269.98	2	0	72.8946
3573	US-2014-126081	6/29/2016	7/4/2016	Standard Class	FC-14335	Fred Chung	Corporate	United States	Mesquite	Texas	75150	Central	OFF-PA-10003953	Office Supplies	Paper	Xerox 218	5.184	1	0.2	1.8144
7302	CA-2011-163468	11/18/2013	11/21/2013	First Class	JK-15730	Joe Kamberova	Consumer	United States	Des Plaines	Illinois	60016	Central	OFF-BI-10004728	Office Supplies	Binders	Wilson Jones Turn Tabs Binder Tool for Ring Binders	2.892	3	0.8	-4.9164
3438	CA-2014-152583	10/30/2016	10/30/2016	Same Day	RA-19945	Ryan Akin	Consumer	United States	Dallas	Texas	75217	Central	FUR-FU-10003849	Furniture	Furnishings	DAX Metal Frame, Desktop, Stepped-Edge	16.192	2	0.6	-8.5008
625	CA-2012-138009	11/29/2014	12/3/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Dearborn	Michigan	48126	Central	OFF-ST-10001272	Office Supplies	Storage	Mini 13-1/2 Capacity Data Binder Rack, Pearl	523.48	4	0	130.87
8073	CA-2014-151750	1/2/2016	1/6/2016	Standard Class	JM-15250	Janet Martin	Consumer	United States	Huntsville	Texas	77340	Central	OFF-AR-10003158	Office Supplies	Art	Fluorescent Highlighters by Dixon	12.736	4	0.2	2.2288
8801	CA-2014-148992	11/23/2016	11/27/2016	Standard Class	CS-12250	Chris Selesnick	Corporate	United States	Chicago	Illinois	60623	Central	OFF-PA-10004285	Office Supplies	Paper	Xerox 1959	10.688	2	0.2	3.7408
6408	CA-2014-161774	5/14/2016	5/15/2016	First Class	GT-14710	Greg Tran	Consumer	United States	Houston	Texas	77041	Central	FUR-CH-10003981	Furniture	Chairs	Global Commerce Series Low-Back Swivel/Tilt Chairs	899.43	5	0.3	-12.849
6419	CA-2013-140130	11/1/2015	11/6/2015	Standard Class	HW-14935	Helen Wasserman	Corporate	United States	Tulsa	Oklahoma	74133	Central	OFF-SU-10001218	Office Supplies	Supplies	Fiskars Softgrip Scissors	21.96	2	0	6.1488
5025	US-2014-130953	7/29/2016	8/3/2016	Standard Class	RF-19735	Roland Fjeld	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	OFF-BI-10004828	Office Supplies	Binders	GBC Poly Designer Binding Covers	33.48	2	0	16.4052
6568	CA-2014-131282	2/6/2016	2/9/2016	Second Class	CB-12025	Cassandra Brandow	Consumer	United States	Waco	Texas	76706	Central	OFF-AR-10003087	Office Supplies	Art	Staples in misc. colors	7.12	5	0.2	0.712
1595	CA-2012-118423	3/24/2014	3/27/2014	First Class	DP-13390	Dennis Pardue	Home Office	United States	Peoria	Illinois	61604	Central	FUR-BO-10000362	Furniture	Bookcases	Sauder Inglewood Library Bookcases	359.058	3	0.3	-35.9058
7455	CA-2013-137743	7/31/2015	8/5/2015	Standard Class	KH-16360	Katherine Hughes	Consumer	United States	Chicago	Illinois	60623	Central	OFF-LA-10003663	Office Supplies	Labels	Avery 498	9.248	4	0.2	3.1212
8200	CA-2014-125269	4/24/2016	4/30/2016	Standard Class	AF-10870	Art Ferguson	Consumer	United States	Chicago	Illinois	60610	Central	OFF-BI-10001628	Office Supplies	Binders	Acco Data Flex Cable Posts For Top & Bottom Load Binders, 6" Capacity	10.43	5	0.8	-18.2525
9108	CA-2012-132941	5/25/2014	5/28/2014	First Class	MM-18280	Muhammed MacIntyre	Corporate	United States	Haltom City	Texas	76117	Central	OFF-SU-10002557	Office Supplies	Supplies	Fiskars Spring-Action Scissors	22.368	2	0.2	1.6776
1857	US-2014-158218	5/12/2016	5/15/2016	Second Class	AC-10420	Alyssa Crouse	Corporate	United States	Houston	Texas	77041	Central	OFF-ST-10000563	Office Supplies	Storage	Fellowes Bankers Box Stor/Drawer Steel Plus	127.92	5	0.2	-15.99
8803	CA-2013-140935	11/11/2015	11/13/2015	First Class	AB-10015	Aaron Bergman	Consumer	United States	Oklahoma City	Oklahoma	73120	Central	FUR-BO-10003966	Furniture	Bookcases	Sauder Facets Collection Library, Sky Alder Finish	341.96	2	0	54.7136
2790	US-2011-117744	12/2/2013	12/6/2013	Standard Class	MD-17860	Michael Dominguez	Corporate	United States	Corpus Christi	Texas	78415	Central	FUR-FU-10002759	Furniture	Furnishings	12-1/2 Diameter Round Wall Clock	39.96	5	0.6	-23.976
742	CA-2011-112326	1/4/2013	1/8/2013	Standard Class	PO-19195	Phillina Ober	Home Office	United States	Naperville	Illinois	60540	Central	OFF-BI-10004094	Office Supplies	Binders	GBC Standard Plastic Binding Systems Combs	3.54	2	0.8	-5.487
8413	CA-2014-132290	3/10/2016	3/14/2016	Standard Class	MD-17350	Maribeth Dona	Consumer	United States	Dallas	Texas	75217	Central	FUR-TA-10002228	Furniture	Tables	Bevis Traditional Conference Table Top, Plinth Base	933.408	4	0.3	-173.3472
8679	CA-2013-112739	9/3/2015	9/8/2015	Second Class	RD-19810	Ross DeVincentis	Home Office	United States	Houston	Texas	77070	Central	OFF-BI-10001132	Office Supplies	Binders	Acco PRESSTEX Data Binder with Storage Hooks, Dark Blue, 9 1/2" X 11"	8.608	8	0.8	-13.3424
3254	CA-2014-110373	10/27/2016	10/30/2016	Second Class	MA-17560	Matt Abelman	Home Office	United States	Chicago	Illinois	60610	Central	TEC-PH-10001536	Technology	Phones	Spigen Samsung Galaxy S5 Case Wallet	27.184	2	0.2	2.0388
6653	US-2014-124779	9/8/2016	9/11/2016	First Class	BF-11020	Barry Französisch	Corporate	United States	Arlington	Texas	76017	Central	OFF-PA-10000061	Office Supplies	Paper	Xerox 205	20.736	4	0.2	7.2576
8917	US-2013-144057	5/10/2015	5/14/2015	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Austin	Texas	78745	Central	OFF-AP-10000390	Office Supplies	Appliances	Euro Pro Shark Stick Mini Vacuum	48.784	4	0.8	-131.7168
258	US-2012-159982	11/28/2014	12/4/2014	Standard Class	DR-12880	Dan Reichenbach	Corporate	United States	Chicago	Illinois	60623	Central	TEC-PH-10001580	Technology	Phones	Logitech Mobile Speakerphone P710e - speaker phone	647.904	6	0.2	56.6916
6384	US-2014-104661	1/16/2016	1/19/2016	First Class	TB-21250	Tim Brockman	Consumer	United States	Austin	Texas	78745	Central	OFF-BI-10001597	Office Supplies	Binders	Wilson Jones Ledger-Size, Piano-Hinge Binder, 2", Blue	32.784	4	0.8	-52.4544
3309	CA-2011-104738	12/30/2013	1/1/2014	Second Class	SP-20620	Stefania Perrino	Corporate	United States	Laredo	Texas	78041	Central	TEC-AC-10003628	Technology	Accessories	Logitech 910-002974 M325 Wireless Mouse for Web Scrolling	47.984	2	0.2	14.3952
3018	US-2013-160528	8/24/2015	8/31/2015	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Pharr	Texas	78577	Central	FUR-FU-10004973	Furniture	Furnishings	Flat Face Poster Frame	22.608	3	0.6	-10.1736
9300	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	OFF-BI-10003676	Office Supplies	Binders	GBC Standard Recycled Report Covers, Clear Plastic Sheets	4.312	2	0.8	-6.8992
5324	CA-2014-134439	9/18/2016	9/23/2016	Second Class	TM-21010	Tamara Manning	Consumer	United States	Grand Island	Nebraska	68801	Central	OFF-PA-10004082	Office Supplies	Paper	Adams Telephone Message Book w/Frequently-Called Numbers Space, 400 Messages per Book	15.96	2	0	7.98
3831	CA-2014-141733	5/7/2016	5/11/2016	Standard Class	RW-19540	Rick Wilson	Corporate	United States	Detroit	Michigan	48234	Central	OFF-AP-10001563	Office Supplies	Appliances	Belkin Premiere Surge Master II 8-outlet surge protector	87.444	2	0.1	18.4604
8812	US-2013-140172	3/9/2015	3/14/2015	Standard Class	SP-20650	Stephanie Phelps	Corporate	United States	Jackson	Michigan	49201	Central	OFF-AP-10004233	Office Supplies	Appliances	Honeywell Enviracaire Portable Air Cleaner for up to 8 x 10 Room	207.144	3	0.1	48.3336
666	CA-2014-132682	6/8/2016	6/10/2016	Second Class	TH-21235	Tiffany House	Corporate	United States	Dallas	Texas	75081	Central	OFF-SU-10004231	Office Supplies	Supplies	Acme Tagit Stainless Steel Antibacterial Scissors	23.76	3	0.2	2.079
2519	CA-2013-124352	10/16/2015	10/22/2015	Standard Class	CD-12790	Cynthia Delaney	Home Office	United States	Oklahoma City	Oklahoma	73120	Central	OFF-LA-10004559	Office Supplies	Labels	Avery 49	20.16	7	0	9.8784
954	CA-2014-136539	12/28/2016	1/1/2017	Standard Class	GH-14665	Greg Hansen	Consumer	United States	Round Rock	Texas	78664	Central	OFF-AR-10001958	Office Supplies	Art	Stanley Bostitch Contemporary Electric Pencil Sharpeners	27.168	2	0.2	2.7168
5096	US-2011-140452	12/6/2013	12/10/2013	Standard Class	BK-11260	Berenike Kampe	Consumer	United States	Chicago	Illinois	60610	Central	TEC-PH-10000307	Technology	Phones	Shocksock Galaxy S4 Armband	35.04	4	0.2	-7.008
3584	CA-2012-121650	12/10/2014	12/16/2014	Standard Class	KD-16495	Keith Dawkins	Corporate	United States	Jackson	Michigan	49201	Central	FUR-TA-10003569	Furniture	Tables	Bretford CR8500 Series Meeting Room Furniture	801.96	2	0	200.49
6207	CA-2013-133697	10/21/2015	10/25/2015	Second Class	CM-12445	Chuck Magee	Consumer	United States	Houston	Texas	77095	Central	OFF-FA-10003112	Office Supplies	Fasteners	Staples	25.248	4	0.2	7.89
7827	CA-2014-117114	10/31/2016	11/5/2016	Standard Class	CY-12745	Craig Yedwab	Corporate	United States	Chicago	Illinois	60610	Central	TEC-PH-10004042	Technology	Phones	ClearOne Communications CHAT 70 OC Speaker Phone	508.768	4	0.2	38.1576
1789	CA-2012-154326	2/15/2014	2/19/2014	Standard Class	RP-19855	Roy Phan	Corporate	United States	Kenosha	Wisconsin	53142	Central	TEC-PH-10000560	Technology	Phones	Samsung Galaxy S III - 16GB - pebble blue (T-Mobile)	699.98	2	0	195.9944
8505	CA-2013-109400	5/3/2015	5/7/2015	Standard Class	NR-18550	Nick Radford	Consumer	United States	Amarillo	Texas	79109	Central	FUR-CH-10003298	Furniture	Chairs	Office Star - Contemporary Task Swivel chair with Loop Arms, Charcoal	366.744	4	0.3	-110.0232
8507	CA-2013-130400	3/9/2015	3/13/2015	Standard Class	SJ-20125	Sanjit Jacobs	Home Office	United States	Dallas	Texas	75217	Central	TEC-AC-10004633	Technology	Accessories	Verbatim 25 GB 6x Blu-ray Single Layer Recordable Disc, 3/Pack	27.96	5	0.2	8.388
9789	CA-2014-144491	3/27/2016	4/1/2016	Standard Class	CJ-12010	Caroline Jumper	Consumer	United States	Houston	Texas	77070	Central	FUR-CH-10004063	Furniture	Chairs	Global Deluxe High-Back Manager's Chair	600.558	3	0.3	-8.5794
2165	CA-2013-154018	10/14/2015	10/20/2015	Standard Class	HA-14920	Helen Andreada	Consumer	United States	Laredo	Texas	78041	Central	OFF-PA-10000551	Office Supplies	Paper	Array Memo Cubes	8.288	2	0.2	3.0044
1676	CA-2012-143077	9/17/2014	9/21/2014	Standard Class	SF-20965	Sylvia Foulston	Corporate	United States	Houston	Texas	77041	Central	OFF-BI-10000088	Office Supplies	Binders	GBC Imprintable Covers	6.588	3	0.8	-10.2114
9297	US-2012-163433	4/18/2014	4/22/2014	Second Class	MP-17965	Michael Paige	Corporate	United States	Mcallen	Texas	78501	Central	TEC-AC-10003590	Technology	Accessories	TRENDnet 56K USB 2.0 Phone, Internet and Fax Modem	41.424	2	0.2	8.2848
1843	CA-2012-135391	2/9/2014	2/11/2014	Second Class	FA-14230	Frank Atkinson	Corporate	United States	San Antonio	Texas	78207	Central	OFF-LA-10001074	Office Supplies	Labels	Round Specialty Laser Printer Labels	40.096	4	0.2	13.5324
5697	CA-2014-126123	10/14/2016	10/18/2016	Standard Class	AG-10765	Anthony Garverick	Home Office	United States	Chicago	Illinois	60623	Central	OFF-BI-10000309	Office Supplies	Binders	GBC Twin Loop Wire Binding Elements, 9/16" Spine, Black	27.396	9	0.8	-42.4638
1962	CA-2014-110905	9/10/2016	9/15/2016	Second Class	RW-19690	Robert Waldorf	Consumer	United States	Springfield	Missouri	65807	Central	TEC-AC-10002217	Technology	Accessories	Imation Clip USB flash drive - 8 GB	112.8	6	0	6.768
8020	CA-2014-167227	11/2/2016	11/5/2016	First Class	NP-18670	Nora Paige	Consumer	United States	Saint Louis	Missouri	63116	Central	OFF-AP-10001962	Office Supplies	Appliances	Black & Decker Filter for Double Action Dustbuster Cordless Vac BLDV7210	83.9	10	0	20.975
5113	CA-2012-153073	11/13/2014	11/13/2014	Same Day	HA-14905	Helen Abelman	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10001025	Furniture	Furnishings	Eldon Imàge Series Desk Accessories, Clear	17.496	9	0.6	-7.4358
8890	CA-2013-147256	10/18/2015	10/22/2015	Second Class	FC-14245	Frank Carlisle	Home Office	United States	Columbia	Missouri	65203	Central	TEC-PH-10003072	Technology	Phones	Panasonic KX-TG9541B DECT 6.0 Digital 2-Line Expandable Cordless Phone With Digital Answering System	449.97	3	0	220.4853
8112	CA-2013-130393	12/2/2015	12/4/2015	Second Class	JM-15865	John Murray	Consumer	United States	San Angelo	Texas	76903	Central	FUR-CH-10002647	Furniture	Chairs	Situations Contoured Folding Chairs, 4/Set	248.43	5	0.3	-17.745
8271	CA-2014-121790	1/31/2016	2/7/2016	Standard Class	LP-17095	Liz Preis	Consumer	United States	Aurora	Illinois	60505	Central	OFF-AR-10003602	Office Supplies	Art	Quartet Omega Colored Chalk, 12/Pack	9.344	2	0.2	3.1536
6136	CA-2012-105613	10/18/2014	10/22/2014	Standard Class	KN-16705	Kristina Nunn	Home Office	United States	Mcallen	Texas	78501	Central	TEC-AC-10000521	Technology	Accessories	Verbatim Slim CD and DVD Storage Cases, 50/Pack	27.696	3	0.2	3.462
3813	CA-2014-147753	3/5/2016	3/5/2016	Same Day	PK-19075	Pete Kriz	Consumer	United States	Milwaukee	Wisconsin	53209	Central	OFF-LA-10003537	Office Supplies	Labels	Avery 515	25.06	2	0	11.7782
9074	CA-2013-142524	9/5/2015	9/9/2015	Standard Class	MB-18085	Mick Brown	Consumer	United States	Springfield	Missouri	65807	Central	TEC-AC-10000109	Technology	Accessories	Sony Micro Vault Click 16 GB USB 2.0 Flash Drive	279.95	5	0	67.188
673	CA-2014-111178	6/15/2016	6/22/2016	Standard Class	TD-20995	Tamara Dahlen	Consumer	United States	Quincy	Illinois	62301	Central	OFF-AR-10001954	Office Supplies	Art	Newell 331	19.56	5	0.2	1.7115
9064	US-2011-151015	10/14/2013	10/20/2013	Standard Class	BD-11500	Bradley Drucker	Consumer	United States	Chicago	Illinois	60653	Central	OFF-PA-10002581	Office Supplies	Paper	Xerox 1951	322.192	13	0.2	100.685
3138	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	OFF-EN-10001219	Office Supplies	Envelopes	#10- 4 1/8" x 9 1/2" Security-Tint Envelopes	12.224	2	0.2	4.4312
5773	CA-2012-158939	11/26/2014	12/1/2014	Standard Class	EA-14035	Erin Ashbrook	Corporate	United States	Springfield	Missouri	65807	Central	TEC-CO-10002313	Technology	Copiers	Canon PC1080F Personal Copier	599.99	1	0	233.9961
4058	CA-2011-163034	11/24/2013	11/28/2013	Standard Class	DK-12985	Darren Koutras	Consumer	United States	Chicago	Illinois	60610	Central	OFF-ST-10000046	Office Supplies	Storage	Fellowes Super Stor/Drawer Files	646.2	5	0.2	-8.0775
8641	US-2014-148551	1/13/2016	1/17/2016	Standard Class	DB-13120	David Bremer	Corporate	United States	Dallas	Texas	75217	Central	OFF-BI-10000545	Office Supplies	Binders	GBC Ibimaster 500 Manual ProClick Binding System	760.98	5	0.8	-1141.47
4773	CA-2014-119746	11/23/2016	11/27/2016	Standard Class	CM-12385	Christopher Martinez	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10004909	Furniture	Furnishings	Contemporary Wood/Metal Frame	6.464	1	0.6	-4.04
9421	CA-2014-152926	10/2/2016	10/4/2016	Second Class	SC-20695	Steve Chapman	Corporate	United States	Houston	Texas	77041	Central	OFF-AP-10001947	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Plus Surge Suppressor	21.984	6	0.8	-56.0592
1459	CA-2013-123722	9/26/2015	10/2/2015	Standard Class	NH-18610	Nicole Hansen	Corporate	United States	Irving	Texas	75061	Central	OFF-LA-10001569	Office Supplies	Labels	Avery 499	15.936	4	0.2	5.1792
4393	CA-2013-108868	9/9/2015	9/13/2015	Standard Class	KB-16585	Ken Black	Corporate	United States	Dallas	Texas	75081	Central	OFF-AR-10001953	Office Supplies	Art	Boston 1645 Deluxe Heavier-Duty Electric Pencil Sharpener	70.368	2	0.2	6.1572
5681	CA-2013-141551	9/25/2015	10/1/2015	Standard Class	BP-11230	Benjamin Patterson	Consumer	United States	Broken Arrow	Oklahoma	74012	Central	OFF-BI-10001249	Office Supplies	Binders	Avery Heavy-Duty EZD View Binder with Locking Rings	6.38	1	0	2.9348
8673	CA-2014-163265	2/17/2016	2/22/2016	Standard Class	JS-16030	Joy Smith	Consumer	United States	Decatur	Illinois	62521	Central	OFF-FA-10004854	Office Supplies	Fasteners	Vinyl Coated Wire Paper Clips in Organizer Box, 800/Box	18.368	2	0.2	6.1992
675	CA-2014-130351	12/5/2016	12/8/2016	First Class	RB-19570	Rob Beeghly	Consumer	United States	Columbus	Indiana	47201	Central	OFF-PA-10002137	Office Supplies	Paper	Southworth 100% Résumé Paper, 24lb.	38.9	5	0	17.505
3019	US-2013-160528	8/24/2015	8/31/2015	Standard Class	MH-18115	Mick Hernandez	Home Office	United States	Pharr	Texas	78577	Central	TEC-AC-10002842	Technology	Accessories	WD My Passport Ultra 2TB Portable External Hard Drive	666.4	7	0.2	-33.32
8559	CA-2013-132829	12/24/2015	12/27/2015	Second Class	LA-16780	Laura Armstrong	Corporate	United States	Houston	Texas	77041	Central	OFF-LA-10002945	Office Supplies	Labels	Permanent Self-Adhesive File Folder Labels for Typewriters, 1 1/8 x 3 1/2, White	45.36	9	0.2	14.742
4442	US-2013-111290	7/23/2015	7/27/2015	Standard Class	DK-13375	Dennis Kane	Consumer	United States	Westland	Michigan	48185	Central	OFF-ST-10001932	Office Supplies	Storage	Fellowes Staxonsteel Drawer Files	965.85	5	0	135.219
8511	CA-2012-135853	12/11/2014	12/14/2014	First Class	CA-12775	Cynthia Arntzen	Consumer	United States	Detroit	Michigan	48205	Central	OFF-BI-10004965	Office Supplies	Binders	Ibico Covers for Plastic or Wire Binding Elements	23	2	0	10.35
4448	US-2011-147704	11/16/2013	11/21/2013	Standard Class	SR-20740	Steven Roelle	Home Office	United States	Bloomington	Indiana	47401	Central	OFF-ST-10000675	Office Supplies	Storage	File Shuttle II and Handi-File, Black	169.45	5	0	42.3625
3507	CA-2011-166863	6/20/2013	6/24/2013	Standard Class	SC-20020	Sam Craven	Consumer	United States	Plano	Texas	75023	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	3.392	4	0.8	-5.088
7787	US-2013-117037	5/18/2015	5/21/2015	First Class	LW-17215	Luke Weiss	Consumer	United States	Chicago	Illinois	60653	Central	OFF-BI-10000279	Office Supplies	Binders	Acco Recycled 2" Capacity Laser Printer Hanging Data Binders	2.89	1	0.8	-4.7685
4079	CA-2012-100685	12/19/2014	12/21/2014	Second Class	SM-20950	Suzanne McNair	Corporate	United States	Omaha	Nebraska	68104	Central	OFF-PA-10001289	Office Supplies	Paper	White Computer Printout Paper by Universal	116.28	3	0	56.9772
2782	CA-2014-146724	11/20/2016	11/27/2016	Standard Class	HG-15025	Hunter Glantz	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-AR-10001026	Office Supplies	Art	Sanford Uni-Blazer View Highlighters, Chisel Tip, Yellow	22	10	0	9.68
2422	CA-2013-155551	4/19/2015	4/24/2015	Standard Class	CR-12580	Clay Rozendal	Home Office	United States	Elmhurst	Illinois	60126	Central	OFF-ST-10003656	Office Supplies	Storage	Safco Industrial Wire Shelving	230.376	3	0.2	-48.9549
490	CA-2011-133753	6/9/2013	6/13/2013	Second Class	CW-11905	Carl Weiss	Home Office	United States	Huntsville	Texas	77340	Central	TEC-AC-10000303	Technology	Accessories	Logitech M510 Wireless Mouse	63.984	2	0.2	10.3974
2302	CA-2011-162362	11/14/2013	11/18/2013	Standard Class	JL-15505	Jeremy Lonsdale	Consumer	United States	Midland	Michigan	48640	Central	OFF-BI-10000546	Office Supplies	Binders	Avery Durable Binders	11.52	4	0	5.6448
4148	CA-2014-106068	10/23/2016	10/28/2016	Standard Class	RB-19330	Randy Bradley	Consumer	United States	Austin	Texas	78745	Central	OFF-BI-10000962	Office Supplies	Binders	Acco Flexible ACCOHIDE Square Ring Data Binder, Dark Blue, 11 1/2" X 14" 7/8"	9.762	3	0.8	-15.1311
6555	CA-2011-137092	10/20/2013	10/22/2013	Second Class	LS-16975	Lindsay Shagiari	Home Office	United States	Chicago	Illinois	60653	Central	OFF-ST-10003805	Office Supplies	Storage	24 Capacity Maxi Data Binder Racks, Pearl	505.32	3	0.2	31.5825
4502	CA-2011-116757	6/30/2013	7/4/2013	Standard Class	MS-17980	Michael Stewart	Corporate	United States	Houston	Texas	77095	Central	OFF-PA-10002005	Office Supplies	Paper	Xerox 225	25.92	5	0.2	9.072
2813	CA-2012-135685	11/16/2014	11/18/2014	Second Class	MP-18175	Mike Pelletier	Home Office	United States	Milwaukee	Wisconsin	53209	Central	FUR-TA-10001520	Furniture	Tables	Lesro Sheffield Collection Coffee Table, End Table, Center Table, Corner Table	214.11	3	0	36.3987
2155	US-2013-120460	5/1/2015	5/6/2015	Standard Class	BF-11170	Ben Ferrer	Home Office	United States	Dallas	Texas	75081	Central	FUR-FU-10004973	Furniture	Furnishings	Flat Face Poster Frame	22.608	3	0.6	-10.1736
2527	CA-2012-124541	4/6/2014	4/10/2014	Standard Class	TT-21220	Thomas Thornton	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10004965	Office Supplies	Binders	Ibico Covers for Plastic or Wire Binding Elements	6.9	3	0.8	-12.075
1513	CA-2014-112809	8/18/2016	8/22/2016	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Dallas	Texas	75220	Central	OFF-ST-10002276	Office Supplies	Storage	Safco Steel Mobile File Cart	200.064	3	0.2	12.504
7486	CA-2014-135111	12/28/2016	1/2/2017	Standard Class	CS-12400	Christopher Schild	Home Office	United States	Fargo	North Dakota	58103	Central	OFF-BI-10004040	Office Supplies	Binders	Wilson Jones Impact Binders	25.9	5	0	12.691
4233	CA-2014-100223	7/5/2016	7/10/2016	Standard Class	LS-16945	Linda Southworth	Corporate	United States	Dallas	Texas	75220	Central	OFF-PA-10002195	Office Supplies	Paper	Xerox 1966	31.104	6	0.2	11.2752
9293	CA-2014-124114	3/2/2016	3/2/2016	Same Day	RS-19765	Roland Schwarz	Corporate	United States	Waco	Texas	76706	Central	OFF-BI-10004022	Office Supplies	Binders	Acco Suede Grain Vinyl Round Ring Binder	0.556	1	0.8	-0.9452
8286	CA-2012-154284	12/21/2014	12/26/2014	Second Class	SZ-20035	Sam Zeldin	Home Office	United States	Saint Charles	Illinois	60174	Central	FUR-FU-10003039	Furniture	Furnishings	Howard Miller 11-1/2" Diameter Grantwood Wall Clock	51.756	3	0.6	-33.6414
7132	CA-2014-141439	11/26/2016	12/1/2016	Standard Class	TT-21460	Tonja Turnell	Home Office	United States	Richmond	Indiana	47374	Central	FUR-TA-10001039	Furniture	Tables	KI Adjustable-Height Table	257.94	3	0	67.0644
7150	CA-2012-166583	6/26/2014	6/30/2014	Standard Class	VD-21670	Valerie Dominguez	Consumer	United States	Houston	Texas	77070	Central	TEC-PH-10001578	Technology	Phones	Polycom SoundStation2 EX Conference phone	971.88	3	0.2	109.3365
522	CA-2012-157812	3/22/2014	3/26/2014	Standard Class	DB-13210	Dean Braden	Consumer	United States	Houston	Texas	77041	Central	OFF-BI-10000285	Office Supplies	Binders	XtraLife ClearVue Slant-D Ring Binders by Cardinal	14.112	9	0.8	-21.168
3949	CA-2013-119963	11/19/2015	11/23/2015	Standard Class	SN-20710	Steve Nguyen	Home Office	United States	Pasadena	Texas	77506	Central	OFF-LA-10003510	Office Supplies	Labels	Avery 4027 File Folder Labels for Dot Matrix Printers, 5000 Labels per Box, White	48.848	2	0.2	15.8756
5189	CA-2012-115567	9/13/2014	9/18/2014	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Columbus	Indiana	47201	Central	FUR-CH-10000015	Furniture	Chairs	Hon Multipurpose Stacking Arm Chairs	1516.2	7	0	394.212
6263	CA-2013-132479	9/25/2015	9/27/2015	First Class	MK-17905	Michael Kennedy	Corporate	United States	Rockford	Illinois	61107	Central	OFF-BI-10004584	Office Supplies	Binders	GBC ProClick 150 Presentation Binding System	442.372	7	0.8	-729.9138
8678	CA-2014-141705	10/24/2016	10/26/2016	First Class	PO-18850	Patrick O'Brill	Consumer	United States	Mansfield	Texas	76063	Central	FUR-TA-10004607	Furniture	Tables	Hon 2111 Invitation Series Straight Table	517.405	5	0.3	-81.3065
9314	CA-2012-111948	11/11/2014	11/11/2014	Same Day	AG-10495	Andrew Gjertsen	Corporate	United States	Detroit	Michigan	48234	Central	OFF-ST-10003282	Office Supplies	Storage	Advantus 10-Drawer Portable Organizer, Chrome Metal Frame, Smoke Drawers	418.32	7	0	117.1296
6687	US-2012-129637	12/17/2014	12/22/2014	Standard Class	MC-18100	Mick Crebagga	Consumer	United States	Bloomington	Illinois	61701	Central	OFF-AR-10003829	Office Supplies	Art	Newell 35	13.12	5	0.2	1.476
4631	US-2012-126235	10/15/2014	10/15/2014	Same Day	GA-14725	Guy Armstrong	Consumer	United States	Mount Pleasant	Michigan	48858	Central	FUR-FU-10000719	Furniture	Furnishings	DAX Cubicle Frames, 8-1/2 x 11	17.14	2	0	6.1704
3741	CA-2013-133340	12/10/2015	12/14/2015	Standard Class	LH-17155	Logan Haushalter	Consumer	United States	Jackson	Michigan	49201	Central	OFF-AP-10002311	Office Supplies	Appliances	Holmes Replacement Filter for HEPA Air Cleaner, Very Large Room, HEPA Filter	61.929	1	0.1	23.3954
1069	US-2014-139955	9/28/2016	9/30/2016	Second Class	CM-12160	Charles McCrossin	Consumer	United States	Brownsville	Texas	78521	Central	OFF-SU-10001935	Office Supplies	Supplies	Staple remover	1.744	1	0.2	-0.3488
3999	CA-2012-105627	3/8/2014	3/12/2014	Standard Class	DK-12895	Dana Kaydos	Consumer	United States	Kenosha	Wisconsin	53142	Central	FUR-FU-10000308	Furniture	Furnishings	Deflect-o Glass Clear Studded Chair Mats	373.08	6	0	82.0776
2172	US-2014-137491	11/19/2016	11/25/2016	Standard Class	LC-16930	Linda Cazamias	Corporate	United States	San Angelo	Texas	76903	Central	FUR-CH-10004675	Furniture	Chairs	Lifetime Advantage Folding Chairs, 4/Carton	305.312	2	0.3	-8.7232
6550	US-2012-164966	7/30/2014	8/1/2014	First Class	GH-14410	Gary Hansen	Home Office	United States	Lakeville	Minnesota	55044	Central	FUR-CH-10002304	Furniture	Chairs	Global Stack Chair without Arms, Black	155.88	6	0	38.97
8363	CA-2014-147207	1/3/2016	1/5/2016	Second Class	TS-21655	Trudy Schmidt	Consumer	United States	El Paso	Texas	79907	Central	FUR-TA-10002958	Furniture	Tables	Bevis Oval Conference Table, Walnut	913.43	5	0.3	-169.637
8186	CA-2012-136728	9/13/2014	9/17/2014	Second Class	AG-10900	Arthur Gainer	Consumer	United States	Chicago	Illinois	60623	Central	OFF-EN-10002621	Office Supplies	Envelopes	Staple envelope	7.824	1	0.2	2.934
4746	CA-2014-168123	3/5/2016	3/5/2016	Same Day	JD-16060	Julia Dunbar	Consumer	United States	Rochester	Minnesota	55901	Central	OFF-BI-10001071	Office Supplies	Binders	GBC ProClick Punch Binding System	127.96	2	0	62.7004
6231	CA-2014-127656	7/11/2016	7/17/2016	Standard Class	NW-18400	Natalie Webber	Consumer	United States	Waterloo	Iowa	50701	Central	OFF-AR-10001166	Office Supplies	Art	Staples in misc. colors	30.32	4	0	11.8248
9151	US-2011-157070	6/1/2013	6/6/2013	Standard Class	QJ-19255	Quincy Jones	Corporate	United States	Detroit	Michigan	48234	Central	OFF-AP-10004859	Office Supplies	Appliances	Acco 6 Outlet Guardian Premium Surge Suppressor	65.52	5	0.1	12.376
3139	CA-2014-164168	11/12/2016	11/18/2016	Standard Class	LS-16975	Lindsay Shagiari	Home Office	United States	Dallas	Texas	75081	Central	TEC-AC-10004568	Technology	Accessories	Maxell LTO Ultrium - 800 GB	44.784	2	0.2	-0.5598
8766	CA-2012-107083	11/21/2014	11/27/2014	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-BI-10000756	Office Supplies	Binders	Storex DuraTech Recycled Plastic Frosted Binders	1.696	2	0.8	-2.544
2034	CA-2013-128923	12/10/2015	12/14/2015	Standard Class	GB-14530	George Bell	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-AR-10000475	Office Supplies	Art	Hunt BOSTON Vista Battery-Operated Pencil Sharpener, Black	9.328	1	0.2	0.8162
6556	CA-2011-137092	10/20/2013	10/22/2013	Second Class	LS-16975	Lindsay Shagiari	Home Office	United States	Chicago	Illinois	60653	Central	OFF-PA-10002109	Office Supplies	Paper	Wirebound Voice Message Log Book	3.808	1	0.2	1.2376
545	CA-2011-103849	5/11/2013	5/16/2013	Standard Class	PG-18895	Paul Gonzalez	Consumer	United States	Fort Worth	Texas	76106	Central	TEC-PH-10002597	Technology	Phones	Xblue XB-1670-86 X16 Small Office Telephone - Titanium	100.792	1	0.2	6.2995
7289	CA-2011-158281	9/2/2013	9/7/2013	Standard Class	AG-10525	Andy Gerbode	Corporate	United States	Houston	Texas	77095	Central	TEC-MA-10002210	Technology	Machines	Epson TM-T88V Direct Thermal Printer - Monochrome - Desktop	559.71	3	0.4	-121.2705
6036	US-2012-155369	4/19/2014	4/25/2014	Standard Class	PG-18820	Patrick Gardner	Consumer	United States	Carrollton	Texas	75007	Central	OFF-BI-10003925	Office Supplies	Binders	Fellowes PB300 Plastic Comb Binding Machine	310.392	4	0.8	-512.1468
4446	US-2011-147704	11/16/2013	11/21/2013	Standard Class	SR-20740	Steven Roelle	Home Office	United States	Bloomington	Indiana	47401	Central	OFF-PA-10003270	Office Supplies	Paper	Xerox 1954	31.68	6	0	14.256
1923	CA-2013-156685	7/9/2015	7/11/2015	Second Class	SC-20230	Scot Coram	Corporate	United States	Arlington	Texas	76017	Central	TEC-PH-10004345	Technology	Phones	Cisco SPA 502G IP Phone	863.64	9	0.2	107.955
6885	CA-2012-120677	5/31/2014	6/4/2014	Standard Class	BD-11320	Bill Donatelli	Consumer	United States	Minneapolis	Minnesota	55407	Central	FUR-CH-10002320	Furniture	Chairs	Hon Pagoda Stacking Chairs	2567.84	8	0	770.352
7377	US-2014-145597	11/2/2016	11/5/2016	First Class	GG-14650	Greg Guthrie	Corporate	United States	Bloomington	Illinois	61701	Central	OFF-AR-10001958	Office Supplies	Art	Stanley Bostitch Contemporary Electric Pencil Sharpeners	54.336	4	0.2	5.4336
9323	US-2013-111563	11/5/2015	11/9/2015	Standard Class	SM-20005	Sally Matthias	Consumer	United States	Houston	Texas	77041	Central	FUR-FU-10000723	Furniture	Furnishings	Deflect-o EconoMat Studded, No Bevel Mat for Low Pile Carpeting	66.112	4	0.6	-84.2928
5224	CA-2014-117401	5/18/2016	5/22/2016	Second Class	PP-18955	Paul Prost	Home Office	United States	Springfield	Missouri	65807	Central	OFF-BI-10001267	Office Supplies	Binders	Universal Recycled Hanging Pressboard Report Binders, Letter Size	43.19	7	0	20.7312
169	CA-2011-139892	9/8/2013	9/12/2013	Standard Class	BM-11140	Becky Martin	Consumer	United States	San Antonio	Texas	78207	Central	OFF-AR-10002656	Office Supplies	Art	Sanford Liquid Accent Highlighters	32.064	6	0.2	6.8136
3654	CA-2014-109960	12/9/2016	12/11/2016	Second Class	DB-13210	Dean Braden	Consumer	United States	Detroit	Michigan	48234	Central	OFF-PA-10000349	Office Supplies	Paper	Easy-staple paper	14.94	3	0	7.0218
1855	CA-2012-160472	7/20/2014	7/25/2014	Second Class	RK-19300	Ralph Kennedy	Consumer	United States	South Bend	Indiana	46614	Central	OFF-ST-10003442	Office Supplies	Storage	Eldon Portable Mobile Manager	141.4	5	0	38.178
8934	CA-2013-102134	3/15/2015	3/20/2015	Standard Class	SP-20545	Sibella Parks	Corporate	United States	Green Bay	Wisconsin	54302	Central	FUR-FU-10003724	Furniture	Furnishings	Westinghouse Clip-On Gooseneck Lamps	16.74	2	0	4.3524
4367	CA-2014-111332	5/20/2016	5/22/2016	Second Class	NC-18340	Nat Carroll	Consumer	United States	Fargo	North Dakota	58103	Central	OFF-AR-10000657	Office Supplies	Art	Binney & Smith inkTank Desk Highlighter, Chisel Tip, Yellow, 12/Box	21.5	10	0	7.095
8107	CA-2014-159149	2/18/2016	2/20/2016	First Class	CR-12820	Cyra Reiten	Home Office	United States	Houston	Texas	77041	Central	OFF-AR-10000937	Office Supplies	Art	Dixon Ticonderoga Core-Lock Colored Pencils, 48-Color Set	175.44	6	0.2	52.632
1112	US-2013-110156	11/20/2015	11/25/2015	Standard Class	EH-13945	Eric Hoffmann	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10004735	Office Supplies	Paper	Xerox 1905	10.368	2	0.2	3.6288
4046	CA-2012-136378	4/2/2014	4/7/2014	Standard Class	CS-11845	Cari Sayre	Corporate	United States	Houston	Texas	77070	Central	OFF-BI-10003707	Office Supplies	Binders	Aluminum Screw Posts	9.156	3	0.8	-13.734
9779	CA-2011-169019	7/26/2013	7/30/2013	Standard Class	LF-17185	Luke Foster	Consumer	United States	San Antonio	Texas	78207	Central	OFF-BI-10001679	Office Supplies	Binders	GBC Instant Index System for Binding Systems	8.88	5	0.8	-13.32
3099	CA-2014-135692	4/27/2016	5/1/2016	Standard Class	CV-12805	Cynthia Voltz	Corporate	United States	Fort Worth	Texas	76106	Central	FUR-BO-10002268	Furniture	Bookcases	Sauder Barrister Bookcases	220.2656	4	0.32	-42.1096
3887	CA-2013-167759	3/4/2015	3/9/2015	Second Class	CC-12670	Craig Carreira	Consumer	United States	Bloomington	Indiana	47401	Central	TEC-PH-10003171	Technology	Phones	Plantronics Encore H101 Dual Earpieces Headset	134.85	3	0	37.758
1989	CA-2012-127509	11/9/2014	11/13/2014	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Springfield	Missouri	65807	Central	FUR-TA-10002855	Furniture	Tables	Bevis Round Conference Table Top & Single Column Base	1024.38	7	0	215.1198
1347	CA-2011-118339	3/17/2013	3/24/2013	Standard Class	BN-11515	Bradley Nguyen	Consumer	United States	Lakeville	Minnesota	55044	Central	OFF-PA-10000466	Office Supplies	Paper	Memo Book, 100 Message Capacity, 5 3/8” x 11”	47.18	7	0	23.59
4441	US-2013-111290	7/23/2015	7/27/2015	Standard Class	DK-13375	Dennis Kane	Consumer	United States	Westland	Michigan	48185	Central	TEC-AC-10004975	Technology	Accessories	Plantronics Audio 995 Wireless Stereo Headset	109.95	1	0	36.2835
6351	CA-2014-161557	9/3/2016	9/8/2016	Standard Class	AG-10900	Arthur Gainer	Consumer	United States	Dallas	Texas	75217	Central	FUR-FU-10004622	Furniture	Furnishings	Eldon Advantage Foldable Chair Mats for Low Pile Carpets	108.4	5	0.6	-105.69
2903	CA-2013-164035	6/13/2015	6/18/2015	Standard Class	CR-12730	Craig Reiter	Consumer	United States	Chicago	Illinois	60610	Central	OFF-PA-10002160	Office Supplies	Paper	Xerox 1978	23.12	5	0.2	8.381
281	US-2012-161991	9/26/2014	9/28/2014	Second Class	SC-20725	Steven Cartwright	Consumer	United States	Houston	Texas	77070	Central	OFF-BI-10004967	Office Supplies	Binders	Round Ring Binders	2.08	5	0.8	-3.432
1576	CA-2011-101602	12/15/2013	12/18/2013	First Class	MC-18100	Mick Crebagga	Consumer	United States	El Paso	Texas	79907	Central	FUR-CH-10004675	Furniture	Chairs	Lifetime Advantage Folding Chairs, 4/Carton	763.28	5	0.3	-21.808
8904	CA-2013-150483	6/1/2015	6/5/2015	Standard Class	BP-11290	Beth Paige	Consumer	United States	Decatur	Illinois	62521	Central	OFF-PA-10004621	Office Supplies	Paper	Xerox 212	10.368	2	0.2	3.6288
760	CA-2014-133333	9/18/2016	9/22/2016	Standard Class	BF-11020	Barry Französisch	Corporate	United States	Green Bay	Wisconsin	54302	Central	OFF-PA-10002377	Office Supplies	Paper	Adams Telephone Message Book W/Dividers/Space For Phone Numbers, 5 1/4"X8 1/2", 200/Messages	22.72	4	0	10.224
7849	CA-2013-104311	5/3/2015	5/7/2015	Standard Class	AS-10090	Adam Shillingsburg	Consumer	United States	Irving	Texas	75061	Central	OFF-ST-10000321	Office Supplies	Storage	Akro Stacking Bins	18.936	3	0.2	-3.7872
3245	CA-2014-113355	12/1/2016	12/5/2016	Standard Class	SJ-20215	Sarah Jordon	Consumer	United States	Grand Prairie	Texas	75051	Central	FUR-CH-10002602	Furniture	Chairs	DMI Arturo Collection Mission-style Design Wood Chair	317.058	3	0.3	-18.1176
7879	CA-2013-160241	11/30/2015	12/5/2015	Second Class	DR-12940	Daniel Raglin	Home Office	United States	Aurora	Illinois	60505	Central	FUR-FU-10003806	Furniture	Furnishings	Tenex Chairmat w/ Average Lip, 45" x 53"	242.176	4	0.6	-302.72
3107	CA-2014-127460	7/10/2016	7/14/2016	Standard Class	FG-14260	Frank Gastineau	Home Office	United States	Aurora	Illinois	60505	Central	OFF-ST-10004340	Office Supplies	Storage	Fellowes Mobile File Cart, Black	298.464	6	0.2	26.1156
3437	US-2012-100531	9/27/2014	9/29/2014	First Class	NM-18520	Neoma Murray	Consumer	United States	Chicago	Illinois	60610	Central	FUR-FU-10003849	Furniture	Furnishings	DAX Metal Frame, Desktop, Stepped-Edge	24.288	3	0.6	-12.7512
3276	CA-2014-116358	11/2/2016	11/6/2016	Standard Class	KM-16225	Kalyca Meade	Corporate	United States	Overland Park	Kansas	66212	Central	OFF-AR-10004685	Office Supplies	Art	Binney & Smith Crayola Metallic Colored Pencils, 8-Color Set	27.78	6	0	9.1674
5980	CA-2011-117765	9/7/2013	9/13/2013	Standard Class	RB-19465	Rick Bensley	Home Office	United States	Tulsa	Oklahoma	74133	Central	OFF-BI-10000474	Office Supplies	Binders	Avery Recycled Flexi-View Covers for Binding Systems	32.06	2	0	15.3888
9193	CA-2012-141810	11/2/2014	11/7/2014	Standard Class	BB-10990	Barry Blumstein	Corporate	United States	San Antonio	Texas	78207	Central	OFF-BI-10001524	Office Supplies	Binders	GBC Premium Transparent Covers with Diagonal Lined Pattern	29.372	7	0.8	-46.9952
4103	US-2014-102288	6/19/2016	6/23/2016	Standard Class	ZC-21910	Zuschuss Carroll	Consumer	United States	Houston	Texas	77095	Central	OFF-PA-10000740	Office Supplies	Paper	Xerox 1982	146.176	8	0.2	47.5072
8572	CA-2013-162222	4/4/2015	4/4/2015	Same Day	SR-20740	Steven Roelle	Home Office	United States	Dallas	Texas	75081	Central	OFF-PA-10003893	Office Supplies	Paper	Xerox 1962	10.272	3	0.2	3.21
1474	US-2012-105676	12/1/2014	12/2/2014	Same Day	NM-18520	Neoma Murray	Consumer	United States	Houston	Texas	77036	Central	FUR-FU-10004270	Furniture	Furnishings	Eldon Image Series Desk Accessories, Burgundy	6.688	4	0.6	-4.0128
2013	CA-2012-155761	12/11/2014	12/11/2014	Same Day	SC-20800	Stuart Calhoun	Consumer	United States	Houston	Texas	77041	Central	OFF-ST-10000943	Office Supplies	Storage	Eldon ProFile File 'N Store Portable File Tub Letter/Legal Size Black	46.344	3	0.2	4.6344
5296	CA-2014-142174	3/4/2016	3/9/2016	Standard Class	DP-13000	Darren Powers	Consumer	United States	Houston	Texas	77041	Central	OFF-PA-10000806	Office Supplies	Paper	Xerox 1934	89.568	2	0.2	32.4684
6199	CA-2012-149909	11/13/2014	11/17/2014	Standard Class	RA-19915	Russell Applegate	Consumer	United States	Columbus	Indiana	47201	Central	TEC-PH-10001536	Technology	Phones	Spigen Samsung Galaxy S5 Case Wallet	50.97	3	0	13.2522
9499	CA-2014-118213	11/5/2016	11/7/2016	First Class	AB-10060	Adam Bellavance	Home Office	United States	Greenwood	Indiana	46142	Central	OFF-PA-10000565	Office Supplies	Paper	Easy-staple paper	167.94	3	0	82.2906
8767	CA-2012-107083	11/21/2014	11/27/2014	Standard Class	BB-11545	Brenda Bowman	Corporate	United States	Fort Worth	Texas	76106	Central	OFF-AP-10004136	Office Supplies	Appliances	Kensington 6 Outlet SmartSocket Surge Protector	24.588	3	0.8	-67.617
\.


--
-- TOC entry 5083 (class 0 OID 0)
-- Dependencies: 226
-- Name: dim_ship_mode_ship_mode_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dim_ship_mode_ship_mode_key_seq', 72, true);


--
-- TOC entry 5084 (class 0 OID 0)
-- Dependencies: 223
-- Name: fact_sales_rowid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fact_sales_rowid_seq', 44137, true);


--
-- TOC entry 4895 (class 2606 OID 16545)
-- Name: dim_customer dim_customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_customer
    ADD CONSTRAINT dim_customer_pkey PRIMARY KEY (customerid);


--
-- TOC entry 4903 (class 2606 OID 16564)
-- Name: dim_date dim_date_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_date
    ADD CONSTRAINT dim_date_pkey PRIMARY KEY (orderdate);


--
-- TOC entry 4900 (class 2606 OID 16558)
-- Name: dim_location dim_location_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_location
    ADD CONSTRAINT dim_location_pkey PRIMARY KEY (postalcode);


--
-- TOC entry 4897 (class 2606 OID 16552)
-- Name: dim_product dim_product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_product
    ADD CONSTRAINT dim_product_pkey PRIMARY KEY (product_id);


--
-- TOC entry 4911 (class 2606 OID 16616)
-- Name: dim_ship_mode dim_ship_mode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_ship_mode
    ADD CONSTRAINT dim_ship_mode_pkey PRIMARY KEY (ship_mode_key);


--
-- TOC entry 4913 (class 2606 OID 16618)
-- Name: dim_ship_mode dim_ship_mode_ship_mode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_ship_mode
    ADD CONSTRAINT dim_ship_mode_ship_mode_key UNIQUE (ship_mode);


--
-- TOC entry 4905 (class 2606 OID 16575)
-- Name: fact_sales fact_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_pkey PRIMARY KEY (rowid);


--
-- TOC entry 4901 (class 1259 OID 16638)
-- Name: idx_dim_location_region; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_location_region ON public.dim_location USING btree (region);


--
-- TOC entry 4898 (class 1259 OID 16637)
-- Name: idx_dim_product_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_product_category ON public.dim_product USING btree (category);


--
-- TOC entry 4906 (class 1259 OID 16634)
-- Name: idx_fact_sales_customerid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_sales_customerid ON public.fact_sales USING btree (customerid);


--
-- TOC entry 4907 (class 1259 OID 16633)
-- Name: idx_fact_sales_orderdate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_sales_orderdate ON public.fact_sales USING btree (orderdate);


--
-- TOC entry 4908 (class 1259 OID 16636)
-- Name: idx_fact_sales_postalcode; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_sales_postalcode ON public.fact_sales USING btree (postalcode);


--
-- TOC entry 4909 (class 1259 OID 16635)
-- Name: idx_fact_sales_productid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fact_sales_productid ON public.fact_sales USING btree (productid);


--
-- TOC entry 4914 (class 2606 OID 16576)
-- Name: fact_sales fact_sales_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.dim_customer(customerid);


--
-- TOC entry 4915 (class 2606 OID 16591)
-- Name: fact_sales fact_sales_orderdate_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_orderdate_fkey FOREIGN KEY (orderdate) REFERENCES public.dim_date(orderdate);


--
-- TOC entry 4916 (class 2606 OID 16586)
-- Name: fact_sales fact_sales_postalcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_postalcode_fkey FOREIGN KEY (postalcode) REFERENCES public.dim_location(postalcode);


--
-- TOC entry 4917 (class 2606 OID 16581)
-- Name: fact_sales fact_sales_productid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_productid_fkey FOREIGN KEY (productid) REFERENCES public.dim_product(product_id);


--
-- TOC entry 4918 (class 2606 OID 16640)
-- Name: fact_sales fact_sales_shipmode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fact_sales
    ADD CONSTRAINT fact_sales_shipmode_fkey FOREIGN KEY (ship_mode_key) REFERENCES public.dim_ship_mode(ship_mode_key);


-- Completed on 2026-09-28 23:55:33

--
-- PostgreSQL database dump complete
--

\unrestrict NaKzr4cvdvFTgdrgqTWN9D0jfDCyz2O4y84lhoiD1EpnH52pYmaYevEBLRMAO4e

