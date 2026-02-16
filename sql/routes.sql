--
-- PostgreSQL database dump
--

\restrict hcSAqNnL0EDR0ugFem0p9aQBkJhf9MQYHXrCBZwVuTQd9HJsFa7PjnJFNlFGcKM

-- Dumped from database version 18.1 (Homebrew)
-- Dumped by pg_dump version 18.1 (Homebrew)

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
-- Name: routes; Type: TABLE; Schema: public; Owner: postgres

--
-- Data for Name: routes; Type: TABLE DATA; Schema: public; Owner: postgres
--
delete from public.routes;
COPY public.routes (route_id, route_name, route_number, route_type, route_gtfs_id, route_colour) FROM stdin;
12	Sandringham		0	2-SHM	{245,126,182}
5	Mernda		0	2-MDD	{200,16,46}
6	Frankston		0	2-FKN	{0,132,48}
854	Coburg - Reservoir via Elizabeth Street	526	2	4-526	{254,80,0}
4	Cranbourne		0	2-CBE	{0,159,213}
3	Craigieburn		0	2-CGB	{255,204,0}
14	Sunbury		0	2-SUY	{255,204,0}
2	Belgrave		0	2-BEG	{21,44,107}
16	Werribee		0	2-WER	{0,132,48}
722	Box Hill - Port Melbourne	109	1	3-109	\N
724	Melbourne University - Kew	16	1	3-016	\N
725	North Coburg - Flinders Street Station	19	1	3-019	\N
887	West Maribyrnong - Flinders Street Station	57	1	3-057	\N
897	Airport West - Flinders Street Station	59	1	3-059	\N
909	Melbourne University - East Brighton	64	1	3-064	\N
913	Melbourne University - Carnegie	67	1	3-067	\N
958	Vermont South - Central Pier Docklands	75	1	3-075	\N
976	North Richmond - Balaclava	78	1	3-078	\N
1002	Moonee Ponds - Footscray	82	1	3-082	\N
1041	East Brunswick - St Kilda Beach	96	1	3-096	\N
1083	Melbourne University - Malvern	5	1	3-005	\N
1880	St Vincents Plaza - Central Pier Docklands	30	1	3-030	\N
1881	Bundoora RMIT - Waterfront City Docklands	86	1	3-086	\N
2903	North Balwyn - Victoria Harbour Docklands	48	1	3-048	\N
8314	Victoria Gardens - St Kilda(Fitzroy St)	12	1	3-012	\N
11529	West Coburg - Toorak	58	1	3-058	\N
11544	Moreland - Glen Iris	6	1	3-006	\N
15833	Melbourne University - East Malvern	3	1	3-003	\N
15834	City Circle (Free Tourist Tram)	35	1	3-035	\N
940	Waterfront City Docklands -  Wattle Park	70	1	3-070	\N
947	Melbourne University - Camberwell	72	1	3-072	\N
1734	Mildura - Ballarat via Swan Hill & Bendigo		3	1-V32	{91,44,130}
3448	City - La Trobe University-Northland SC	250-251 combined	2	4-C08	{254,80,0}
11096	Rochester Town Service		2	6-R01	{254,80,0}
7	Glen Waverley		0	2-GWY	{21,44,107}
11626	Newborough TAFE - Yallourn to Drouin North (From 14-09-2025)		2	4-w36	{254,80,0}
13661	Cowes - Anderson - Wonthaggi		2	6-a47	{254,80,0}
14922	Geelong Station - Whittington via Newcomb	30	2	4-G30	{254,80,0}
9	Lilydale		0	2-LIL	{21,44,107}
15780	Wodonga - Albury	AW	2	6-866	{254,80,0}
16011	Glen Waverley Station - Croydon Station via Knox City	967	2	4-967	{254,80,0}
17260	Moonee Ponds - Melbourne University	505	2	4-505	{254,80,0}
17262	Alphington - Moonee Ponds via Northcote & Brunswick	508	2	4-508	{254,80,0}
17263	Hawthorn to Fairfield via Kew	609	2	4-609	{254,80,0}
17264	Moonee Ponds - Clifton Hill via East Brunswick	504	2	4-504	{254,80,0}
18954	Garfield Station to Traralgon Plaza (From 14-09-2025)		2	4-V92	{254,80,0}
18955	Drouin North to Newborough TAFE (From 14-09-2025)		2	4-V91	{254,80,0}
18956	Moe - Albert St to Drouin North (From 14-09-2025)		2	4-V85	{254,80,0}
18957	Moe - Albert St to Garfield Station (From 14-09-2025)		2	4-V87	{254,80,0}
18958	Donnybrook Station to Craigieburn Station via Mickleham (From 5th October 2025)	525	2	4-525	{254,80,0}
18959	Kalkallo - Peppercorn Hill via Donnybrook Station (From 5th October 2025)	524	2	4-524	{254,80,0}
18981	Werribee - Wyndham Vale Station via Harpley and Mambourin (From 7th December)	194	2	4-194	{254,80,0}
19059	Williams Landing Station - Tarneit Station via Sayers Rd (From 7th December)	150	2	4-150	{254,80,0}
17	Williamstown		0	2-WIL	{0,132,48}
1512	Warrnambool - Melbourne via Ararat & Hamilton		3	1-995	{91,44,130}
15	Upfield		0	2-UFD	{255,204,0}
721	East Coburg - South Melbourne Beach	1	1	3-001	\N
3343	West Preston - Victoria Harbour Docklands	11	1	3-011	\N
946	Hampton Station to Carrum Station via Highett & Southland & Chelsea Heights	708	2	4-708	{254,80,0}
1176	Bayswater - Wantirna Primary School via Mountain Highway	745d	2	4-45d	{254,80,0}
1309	Albury - Beechworth via Baranduda		2	6-a31	{254,80,0}
1311	Mildura - Merbein via Seventeenth Street	250-300	2	6-920	{254,80,0}
1494	Yarram - Traralgon via Gormandale		2	6-855	{254,80,0}
1658	Ararat West via Brewster Road & Lowe Road	1	2	6-Ar1	{254,80,0}
2919	Shepparton - Parkside Gardens via GV Health	1	2	6-Sh1	{254,80,0}
13780	Sale - Glenhaven Park via Port of Sale	6	2	6-s06	{254,80,0}
13889	Wallan Link A - Wallan Station - Springridge via Wallan Central (Link A)		2	4-W12	{254,80,0}
15070	Arnolds Creek to Melton Station via Westlake	459	2	4-459	{254,80,0}
15191	Sunshine Station - Watergardens Station via Keilor Downs	941	2	4-941	{254,80,0}
15612	Fountain Gate SC - Lynbrook Station via Hallam Station	891	2	4-891	{254,80,0}
15652	City - Bulleen - Doncaster SC via Kew Junction	200-207 combined	2	4-C10	{254,80,0}
15667	Berwick Station - Berwick North via Telford Dr & Whistler Dr	839	2	4-839	{254,80,0}
15813	Southland - Box Hill Station via Chadstone & Jordanville & Deakin University	767	2	4-767	{254,80,0}
15975	North Melbourne Station - Melbourne University Loop via Royal Melbourne Hospital	401	2	4-401	{254,80,0}
16008	Croydon - Boronia via Kilsyth & Canterbury Gardens & Kilsyth South	690	2	4-690	{254,80,0}
16010	Croydon Station-Monash University via Knox City Shopping Centre &Glen Waverley	737	2	4-737	{254,80,0}
16442	Manningham Loop via Tunstall Square SC & Doncaster SC	280	2	4-280	{254,80,0}
16716	Watergardens Station - Caroline Springs Station via Caroline Springs Square SC	462	2	4-462	{254,80,0}
17259	Moonee Ponds - Westgarth Station via Brunswick	506	2	4-506	{254,80,0}
17261	Heidelberg Station - Melbourne University via Clifton Hill and Carlton	546	2	4-546	{254,80,0}
18942	Tarneit Station - Laverton Station via Truganina (From 7th December)	154	2	4-154	{254,80,0}
1731	Halls Gap - Melbourne via Stawell & Ballarat		3	1-V24	{91,44,130}
8	Hurstbridge		0	2-HBE	{200,16,46}
1	Alamein		0	2-ALM	{21,44,107}
11	Pakenham		0	2-PKM	{0,159,213}
13	Stony Point		0	2-STY	{192,0,0}
1482	Flemington Racecourse		0	2-RCE	{192,0,0}
1737	Adelaide - Melbourne via Nhill & Bendigo		3	1-V03	{91,44,130}
1738	Sydney - Adelaide via Albury		3	1-V47	{91,44,130}
1706	Albury - Melbourne via Seymour		3	1-ABY	{91,44,130}
1710	Seymour - Melbourne via Broadmeadows		3	1-SER	{91,44,130}
11625	Traralgon Station to Drouin North via TAFE Gippsland (From 14-09-2025)		2	4-w35	{254,80,0}
12753	Stud Park SC (Rowville) - Caulfield via Monash University & Chadstone (SMARTBUS Service)	900	2	4-900	{254,80,0}
1717	Batemans Bay - Melbourne via Bairnsdale		3	1-V09	{91,44,130}
1718	Canberra - Melbourne via Bairnsdale		3	1-V13	{91,44,130}
1719	Sale - Melbourne via Maffra & Traralgon		3	1-V43	{91,44,130}
1720	Cowes and Inverloch - Melbourne via Dandenong & Koo Wee Rup		3	1-V15	{91,44,130}
1721	Marlo - Lake Tyers Beach - Melbourne via Bairnsdale		3	1-V25	{91,44,130}
1722	Yarram - Melbourne via Koo Wee Rup & Dandenong		3	1-V52	{91,44,130}
1723	Griffith - Melbourne via Shepparton		3	1-V41	{91,44,130}
1724	Corowa - Melbourne via Rutherglen & Wangaratta		3	1-V17	{91,44,130}
1725	Mt Buller-Mansfield - Melbourne via Yea		3	4-V28	{91,44,130}
1726	Mulwala - Melbourne via Benalla & Seymour		3	1-V36	{91,44,130}
1727	Shepparton - Sydney via Benalla		3	1-V42	{91,44,130}
1728	Ballarat-Wendouree - Melbourne via Melton		3	1-BAT	{91,44,130}
1732	Mount Gambier - Melbourne via Hamilton & Ballarat		3	1-V29	{91,44,130}
1733	Ouyen - Melbourne via Warracknabeal & Ballarat		3	1-V38	{91,44,130}
1735	Warrnambool - Melbourne via Ballarat		3	1-V49	{91,44,130}
1740	Bendigo - Melbourne via Gisborne		3	1-BGO	{91,44,130}
1741	Sunbury - Melbourne via Sydenham		3	1-V44	{91,44,130}
1744	Barham - Melbourne via Bendigo		3	1-V10	{91,44,130}
1745	Geelong - Melbourne		3	1-GEL	{91,44,130}
1749	Warrnambool - Melbourne via Apollo Bay & Geelong		3	1-V50	{91,44,130}
1751	Geelong - Bendigo via Ballarat		3	1-V22	{91,44,130}
1755	Adelaide - Melbourne via Horsham & Ballarat & Geelong		3	1-V02	{91,44,130}
1756	Portland - Casterton - Melbourne via Hamilton & Warrnambool		3	1-V16	{91,44,130}
1758	Barmah - Melbourne via Shepparton & Heathcote		3	1-V07	{91,44,130}
1759	Albury - Bendigo via Wangaratta & Shepparton		3	1-V11	{91,44,130}
1760	Daylesford - Melbourne via  Woodend or Castlemaine		3	1-V18	{91,44,130}
1761	Deniliquin - Melbourne via Moama & Echuca & Heathcote		3	4-V20	{91,44,130}
1762	Ballarat - Warrnambool via Skipton		3	1-V06	{91,44,130}
1767	Mount Gambier - Melbourne via Warrnambool & Geelong		3	1-V30	{91,44,130}
1768	Canberra - Melbourne via Albury		3	1-V14	{91,44,130}
1773	Donald - Melbourne via Bendigo		3	1-V19	{91,44,130}
1774	Lancefield - Melbourne via Sunbury or Gisborne		3	1-V26	{91,44,130}
1775	Maryborough - Melbourne via Castlemaine		3	1-V27	{91,44,130}
1776	Mildura - Albury via Kerang & Shepparton		3	1-V31	{91,44,130}
1782	Mildura - Melbourne via Ballarat & Donald		3	1-V34	{91,44,130}
1783	Mildura - Melbourne via Swan Hill & Bendigo		3	1-V35	{91,44,130}
1784	Sea Lake - Melbourne via Charlton & Bendigo		3	1-V39	{91,44,130}
1823	Bairnsdale - Melbourne via Sale & Traralgon		3	1-BDE	{91,44,130}
1824	Traralgon - Melbourne via Morwell & Moe & Pakenham		3	1-TRN	{91,44,130}
1837	Ararat - Melbourne via Ballarat		3	1-ART	{91,44,130}
1838	Nhill - Melbourne via Ararat & Ballarat		3	1-V37	{91,44,130}
1848	Swan Hill - Melbourne via Bendigo		3	1-SWL	{91,44,130}
1849	Echuca-Moama - Melbourne via Bendigo or Heathcote		3	1-ECH	{91,44,130}
1853	Warrnambool - Melbourne via Colac & Geelong		3	1-WBL	{91,44,130}
1908	Shepparton - Melbourne via Seymour		3	1-SNH	{91,44,130}
1912	Mount Beauty - Melbourne via Bright		3	1-mtb	{91,44,130}
1914	Echuca-Moama - Melbourne via Shepparton		3	1-EC2	{91,44,130}
1915	Daylesford - Melbourne via Ballarat		3	1-DF2	{91,44,130}
2055	Alexandra - Seymour via Yea		3	5-als	{91,44,130}
2635	Pakenham Line (VLINE)		3	1-vPK	{91,44,130}
4871	Maryborough - Melbourne via  Ballarat		3	1-MBY	{91,44,130}
5838	Paynesville - Melbourne via Bairnsdale		3	1-pay	{91,44,130}
7601	Geelong - Colac via Winchelsea and Birregurra		3	5-GCL	{91,44,130}
14937	Apollo Bay - Geelong (VLINE)		3	5-GVL	{91,44,130}
855	Gowrie  - Northland via Murray Road	527	2	4-527	{254,80,0}
867	Ivanhoe - Northland via Oriel Road	549	2	4-549	{254,80,0}
869	Northland - La Trobe University via Waterdale Road	550	2	4-550	{254,80,0}
870	Heidelberg - La Trobe University Interchange	551	2	4-551	{254,80,0}
935	Olinda - Belgrave via Sherbrooke Road	694	2	4-694	{254,80,0}
937	Belgrave -  Belgrave South via Belgrave Heights	697	2	4-697	{254,80,0}
939	Belgrave - Upwey	699	2	4-699	{254,80,0}
950	Glen Iris - Glen Waverley	734	2	4-734	{254,80,0}
952	Mitcham - Blackburn via Vermont South & Glen Waverley & Forest Hill	736	2	4-736	{254,80,0}
954	Mitcham - Knox City via Knox Private Hospital & Wantirna Secondary College	738	2	4-738	{254,80,0}
955	Mitcham - Vermont East via Reserve Avenue & Churinga Avenue	740	2	4-740	{254,80,0}
957	Knox City - Bayswater -  Wantirna Primary School	745	2	4-745	{254,80,0}
959	Glen Waverley - Bayswater via Wheelers Hill & Knoxfield & Boronia	753	2	4-753	{254,80,0}
960	Rowville - Glen Waverley via Caulfield Grammar & Wheelers Hill	754	2	4-754	{254,80,0}
961	Bayswater - Knox City via Basin & Boronia & Ferntree Gully	755	2	4-755	{254,80,0}
962	Knox City - Scoresby via Old Orchards Drive	757	2	4-757	{254,80,0}
963	Knox City - Knoxfield via Wallace Road	758	2	4-758	{254,80,0}
964	Mitcham - Box Hill via Brentford Square & Forest Hill & Blackburn	765	2	4-765	{254,80,0}
970	Frankston - Eliza Heights	772	2	4-772	{254,80,0}
971	Frankston - Frankston South via Kars Street	773	2	4-773	{254,80,0}
972	Frankston - Delacombe Park	774	2	4-774	{254,80,0}
974	Frankston - Pearcedale via Baxter	776	2	4-776	{254,80,0}
975	Frankston - Belvedere via Kananook	779	2	4-779	{254,80,0}
977	Frankston Station - Carrum Station via Seaford Station	780	2	4-780	{254,80,0}
979	Frankston - Flinders via Coolart Road & Hastings	782	2	4-782	{254,80,0}
980	Frankston - Hastings via Coolart Road	783	2	4-783	{254,80,0}
982	Frankston - Portsea via Dromana & Rosebud & Sorrento	788	2	4-788	{254,80,0}
999	Dandenong - Waverley Gardens SC	813	2	4-813	{254,80,0}
1000	Springvale South - Dandenong via Waverley Gardens Shopping Centre & Springvale	814	2	4-814	{254,80,0}
1007	Moorabbin - Southland via Black Rock & Mentone	825	2	4-825	{254,80,0}
1013	Frankston - Carrum Downs via Kananook & McCormicks Road	832	2	4-832	{254,80,0}
1023	Dandenong - Brandon Park Shopping Centre via Waverley Gardens Shopping Centre	848	2	4-848	{254,80,0}
1030	Glen Waverley - Springvale via Wanda Street	885	2	4-885	{254,80,0}
1123	Skybus - Melbourne Airport - Melbourne City		2	11-SKY	{254,80,0}
1143	Frankston - Mornington East via Mt Eliza & Mornington	785	2	4-785	{254,80,0}
1150	Karingal Hub Shopping Centre - McClelland Drive	777	2	4-777	{254,80,0}
1173	Knox City - Bayswater	745a	2	4-45a	{254,80,0}
1174	Bayswater - Boronia Station	745b	2	4-45b	{254,80,0}
1175	Bayswater - Wantirna Primary School	745c	2	4-45c	{254,80,0}
1295	Wodonga - Murray Valley Private Hospital	F	2	6-867	{254,80,0}
1296	Wodonga - Gayview Drive	G	2	6-868	{254,80,0}
1297	Wodonga - Wodonga TAFE	T	2	6-869	{254,80,0}
1300	Wodonga - West Wodonga	O	2	6-872	{254,80,0}
1301	Wodonga - Cambourne Park	C	2	6-873	{254,80,0}
1302	Wodonga Shopper	WS	2	6-874	{254,80,0}
1303	Wodonga - Baranduda	B	2	6-875	{254,80,0}
786	Highpoint SC - Avondale Heights via Maribyrnong	407	2	4-407	{254,80,0}
789	Sunshine Station - Footscray via Ballarat Road	410	2	4-410	{254,80,0}
825	Williamstown - Sunshine Station via Newport & Altona Gate SC	471	2	4-471	{254,80,0}
850	Northland - St Helena via Viewbank & Greensborough Station	517	2	4-517	{254,80,0}
1310	Albury - Corowa via Howlong		2	6-984	{254,80,0}
1312	Mildura - Irymple - Red Cliffs	100-200	2	6-921	{254,80,0}
1314	Mildura - West Mildura - Mildura Central Shopping Centre	500	2	6-M50	{254,80,0}
1318	Swan Hill - Swan Hill North	1	2	6-a42	{254,80,0}
1319	Swan Hill - Swan Hill South	2	2	6-a43	{254,80,0}
1320	Swan Hill South - Schools		2	6-946	{254,80,0}
1443	Bairnsdale - East Bairnsdale	2	2	6-a32	{254,80,0}
1444	Bairnsdale - Wy Yung	3	2	6-a33	{254,80,0}
1446	Wonthaggi - Wonthaggi North - Wonthaggi		2	6-a48	{254,80,0}
1533	Swan Hill - Sea Lake via Ultima		2	6-R12	{254,80,0}
1538	Horsham - Birchip via Warracknabeal		2	6-R13	{254,80,0}
1539	Horsham - Hopetoun via Dimboola		2	6-R14	{254,80,0}
1545	Mildura - Horsham via Hopetoun		2	6-MLH	{254,80,0}
1571	Mildura - Merbein via Eleventh Street	211-311-312	2	6-40b	{254,80,0}
1610	Kyneton - Woodend		2	6-R95	{254,80,0}
1624	Daylesford - Hepburn Springs		2	6-89x	{254,80,0}
1632	Belgrave - Gembrook	695	2	4-695	{254,80,0}
1666	Williamstown - Moonee Ponds via Footscray	472	2	4-472	{254,80,0}
1947	Ballarat - Rokewood via Ross Creek		2	6-rok	{254,80,0}
1991	Omeo - Bright via Hotham Heights		2	6-ome	{254,80,0}
1995	Ararat - Lake Bolac via Willaura		2	6-alb	{254,80,0}
2079	Albury - Corryong via Walwa		2	6-a23	{254,80,0}
2126	Colac to  Colac West	2	2	6-cc2	{254,80,0}
2285	Maryborough -Princes Park-Whirrakee	2	2	6-Mx2	{254,80,0}
2293	Maryborough - Pascoe	3	2	6-MB3	{254,80,0}
2294	Maryborough - Maryborough Education Centre	4	2	6-MB4	{254,80,0}
2295	Maryborough - Hedges	1	2	6-Mx1	{254,80,0}
2339	Horsham - Kaniva via Dimboola		2	6-86N	{254,80,0}
2349	Albury - Corowa via Rutherglen		2	6-alc	{254,80,0}
2768	Bendigo - Boort via Wedderburn		2	6-Bor	{254,80,0}
2808	Kananook - Carrum Downs via Lathams Rd	778	2	4-778	{254,80,0}
2813	Frankston - Langwarrin via Karingal	771	2	4-771	{254,80,0}
2895	Seymour - Seymour North	2	2	4-SY2	{254,80,0}
2896	Seymour - Puckapunyal	3	2	4-SY3	{254,80,0}
2897	Seymour - Wimble Street AM peak	4	2	4-SY4	{254,80,0}
2916	Gembrook - Fountain Gate	695F	2	4-69F	{254,80,0}
2922	Shepparton - GOTAFE William Orr Campus via Golf Drive	3	2	6-Sh3	{254,80,0}
2925	Shepparton - Connolly Park	4	2	6-Sh4	{254,80,0}
2928	Shepparton - Archer	5	2	6-Sh5	{254,80,0}
2931	Shepparton - South East	6	2	6-Sh6	{254,80,0}
2934	Shepparton - Market Place	7	2	6-Sh7	{254,80,0}
2937	Shepparton - Kialla	8	2	6-Sh8	{254,80,0}
2943	Shepparton - Aquamoves	9	2	6-Sh9	{254,80,0}
2982	Shepparton - Parkside Gardens via The Boulevard	2	2	6-Sh2	{254,80,0}
3287	Coronet Bay - Grantville via Corinella		2	6-gvc	{254,80,0}
3321	St Arnaud - Stawell via Ararat		2	6-StA	{254,80,0}
3322	Ararat Station - Hopkins Correctional Centre		2	6-Apr	{254,80,0}
3324	Hepburn - Creswick via Daylesford		2	6-hep	{254,80,0}
3346	Wonthaggi - Traralgon via Leongatha		2	6-54n	{254,80,0}
3354	Koo Wee Rup - Pakenham		2	6-KWR	{254,80,0}
3365	Frankston - Karingal via Ashleigh Avenue	770	2	4-770	{254,80,0}
3374	Wangaratta - West End	401	2	6-a20	{254,80,0}
3377	Wangaratta - Yarrunga via Murdoch Road	402	2	6-a21	{254,80,0}
3380	Wangaratta -Yarrawonga Road	403	2	6-a22	{254,80,0}
3408	Mildura Central SC - East Mildura - Mildura	401	2	6-M41	{254,80,0}
3411	Southland SC - St Kilda Station via Sandringham	600-922-923 combined	2	4-C13	{254,80,0}
3420	Frankston - Coolart Rd - Hastings-Flinders	782-783 combined	2	4-C21	{254,80,0}
1322	Swan Hill - Tooleybuc via Nyah West		2	6-a28	{254,80,0}
1341	Mooroopna - Rodney Park	2	2	6-904	{254,80,0}
1342	Mooroopna Park	3	2	6-a39	{254,80,0}
1344	Echuca - Echuca South	1	2	6-a36	{254,80,0}
1345	Echuca - Echuca East	2 - Circular	2	6-a37	{254,80,0}
1346	Echuca - Moama	3 - Circular	2	6-a38	{254,80,0}
1350	Shepparton - Mooroopna	1	2	6-a40	{254,80,0}
1355	Portland - North	1	2	6-PT1	{254,80,0}
1365	Colac - Alvie via Warrion		2	6-a50	{254,80,0}
1396	Wangaratta - Yarrawonga		2	6-960	{254,80,0}
1439	Bairnsdale - West Bairnsdale	1	2	6-073	{254,80,0}
1440	Bairnsdale - Omeo	14	2	6-014	{254,80,0}
1441	Bairnsdale - Paynesville	13	2	6-013	{254,80,0}
1447	Wonthaggi - South Wonthaggi - Wonthaggi		2	6-a49	{254,80,0}
1448	Wonthaggi Town Service (Cape Paterson)		2	6-976	{254,80,0}
1449	Coronet Bay - Wonthaggi via Corinella		2	6-977	{254,80,0}
1452	Korumburra Town Service - Carinya Lodge		2	6-935	{254,80,0}
1461	Wonthaggi - Leongatha via Inverloch		2	6-973	{254,80,0}
1474	Wangaratta - Chiltern via Rutherglen		2	6-959	{254,80,0}
1495	Bairnsdale - Gelantipy	12	2	6-a18	{254,80,0}
1506	Albury - Wodonga - Myrtleford		2	6-a44	{254,80,0}
1515	Warrnambool - Mortlake		2	6-994	{254,80,0}
1524	Hamilton West via Coleraine Road	1	2	6-992	{254,80,0}
1532	Horsham - Donald via Murtoa and Minyip		2	6-R11	{254,80,0}
1574	Mildura - Euston - Robinvale		2	6-R21	{254,80,0}
1575	Ballarat - Stawell via Ararat		2	6-R22	{254,80,0}
1587	Castlemaine - Taradale via Chewton	5	2	6-R30	{254,80,0}
1595	Wangaratta - Cheshunt via Edi		2	6-R53	{254,80,0}
1596	Wonthaggi - Dudley - Wonthaggi		2	6-R54	{254,80,0}
1659	Ararat South via Burke Road & Churchill Avenue	2	2	6-Ar2	{254,80,0}
1660	Ararat North via Baird Street & Melbourne Polytechnic (Ararat) & Alfred Street	3	2	6-Ar3	{254,80,0}
1664	Yarraville Station - Kingsville via Somerville Road	431	2	4-431	{254,80,0}
1665	Newport - Yarraville via Altona Gate Shopping Centre	432	2	4-432	{254,80,0}
3398	Mildura City - East Mildura - Mildura Central SC	400	2	6-M40	{254,80,0}
3401	Mildura Central SC - West  Mildura - Mildura	501	2	6-M51	{254,80,0}
4663	Rye to St Andrews Beach	786	2	4-786	{254,80,0}
4729	NewNSCStops - R19 stops		2	4-NST	{254,80,0}
4745	Kyneton Town Centre  to Kyneton Station via Kyneton West	2	2	6-KY2	{254,80,0}
5767	Wodonga - Mayfair Drive	M	2	6-woM	{254,80,0}
5768	Epping Plaza SC - South Morang	569	2	4-569	{254,80,0}
5770	Bundoora RMIT - South Morang	564	2	4-564	{254,80,0}
5809	Mallacoota - Genoa via Gipsy Point		2	6-mal	{254,80,0}
5814	Sale - Seaspray via Longford		2	6-Sea	{254,80,0}
5827	Lakes Entrance - Kalimna	1	2	6-La1	{254,80,0}
5834	Lakes Entrance - Lakes Entrance North	2	2	6-La2	{254,80,0}
5837	Lakes Entrance - Lakes Entrance East	3	2	6-La3	{254,80,0}
5843	Ararat to Stawell via Western Hwy		2	6-ArS	{254,80,0}
5844	Stawell to Horsham via Western Hwy		2	6-StH	{254,80,0}
5846	Echuca - 24 Lane	5	2	6-Ec5	{254,80,0}
6647	Maffra town service		2	6-Ma1	{254,80,0}
6648	Mildura - Ouyen - Sea Lake		2	6-MiS	{254,80,0}
6649	Kerang - Echuca via Cohuna		2	6-KeE	{254,80,0}
6716	Seymour - Seymour North-East PM peak	5	2	4-SY5	{254,80,0}
7440	Caroline Springs - Highpoint SC	215	2	4-215	{254,80,0}
7627	Seymour - Seymour East	1	2	4-SY1	{254,80,0}
7726	Wodonga - South Wodonga	S	2	6-WoS	{254,80,0}
7765	Warrnambool - Dennington	1	2	6-wr1	{254,80,0}
7768	Warrnambool - Gateway Plaza	2	2	6-wr2	{254,80,0}
7771	Warrnambool - Deakin University via Gateway Plaza	3	2	6-wr3	{254,80,0}
7772	Warrnambool - Tower Square via Gateway Plaza	4	2	6-wr4	{254,80,0}
7776	Warrnambool - Lake Pertobe Loop	5	2	6-wr5	{254,80,0}
7779	Warrnambool - Merrivale	6	2	6-wr6	{254,80,0}
7782	Warrnambool - Port Fairy	8	2	6-wr8	{254,80,0}
7785	Warrnambool - Allansford	9	2	6-wr9	{254,80,0}
7788	Colac to Elliminyt	1	2	6-CL1	{254,80,0}
7791	Colac to Colac East	3	2	6-CL3	{254,80,0}
7953	Timboon - Camperdown via Cobden		2	6-Tim	{254,80,0}
8074	Elsternwick - Clifton Hill via St Kilda	246	2	4-246	{254,80,0}
8084	Doncaster SC - The Pines SC via Templestowe	295	2	4-295	{254,80,0}
8118	Garden City - City (Queen Victoria Market)	234	2	4-234	{254,80,0}
8122	Altona North - City (Queen Victoria Market)	232	2	4-232	{254,80,0}
8125	Mitcham - Ringwood via Ringwood North	370	2	4-370	{254,80,0}
8128	Box Hill - Mitcham via Blackburn North	270	2	4-270	{254,80,0}
8135	City (Queen St) - La Trobe University	250	2	4-250	{254,80,0}
8139	City (Queen St) - Northland SC	251	2	4-251	{254,80,0}
8246	Hamilton North via Kent Road	2	2	6-HA2	{254,80,0}
8307	Sunshine Station - Sunshine West via Wright St	428	2	4-428	{254,80,0}
8317	Wangaratta - Yarrunga via Mason Street	404	2	6-W04	{254,80,0}
8361	Benalla - Benalla West	1	2	6-BNI	{254,80,0}
8373	Colac - Marengo via Apollo Bay		2	6-CMO	{254,80,0}
8430	Laverton Station - Sanctuary Lakes via Sanctuary Lakes SC	496	2	4-496	{254,80,0}
8435	Alexandra - Marysville via Taggerty & Buxton		2	6-ALX	{254,80,0}
8457	Werribee Station - Wyndham Vale Station via Ballan Rd	190	2	4-190	{254,80,0}
8482	Werribee Station - Hoppers Crossing Station via Werribee Plaza SC	181	2	4-181	{254,80,0}
4747	Kyneton - Malmsbury		2	6-Kym	{254,80,0}
4802	Olinda - Monbulk via Olinda - Monbulk Road	696	2	4-696	{254,80,0}
4849	Hamilton - Penshurst via Tarrington		2	6-Hpt	{254,80,0}
4855	St Arnaud - Stawell via Marnoo		2	6-StS	{254,80,0}
4864	Ararat - Maryborough via Elmhurst & Avoca		2	6-ArM	{254,80,0}
4896	Mansfield - Woods Point via Jamieson		2	6-Woo	{254,80,0}
5023	Horsham - Naracoorte via Natimuk & Goroke & Edenhope		2	6-Nar	{254,80,0}
5038	Albury - Tallangatta via Bonegilla		2	6-Tal	{254,80,0}
5041	Shepparton - Euroa via Kialla		2	6-Eur	{254,80,0}
5048	Geelong - Inverleigh via Fyansford		2	6-GIV	{254,80,0}
5052	Swan Hill - Wycheproof via Lalbert		2	6-Wyc	{254,80,0}
5055	Bendigo - Woomelang via Wedderburn & Charlton & Wycheproof & Birchip		2	6-BxW	{254,80,0}
5069	Ballarat - Mt Egerton via Gordon		2	6-MtE	{254,80,0}
5125	Albury - Mt Beauty via Baranduda and Tawonga South		2	6-MtB	{254,80,0}
5331	Dandenong - Doveton via McCrae Street	844	2	4-844	{254,80,0}
5334	Dandenong - Glen Waverley via Mulgrave & Brandon Park	850	2	4-850	{254,80,0}
5540	Kew (Cotham Road) - La Trobe University Bundoora	548	2	4-548	{254,80,0}
5634	Maryborough - Maryborough Station		2	6-Mab	{254,80,0}
5671	Laverton Station - Williamstown via Altona	415	2	4-415	{254,80,0}
5675	Morwell - Churchill	2	2	4-L02	{254,80,0}
5681	Churchill - Boolarra via Yinnar	4	2	4-L04	{254,80,0}
5684	Traralgon - Churchill	3	2	4-L03	{254,80,0}
5700	Churchill town loop	30	2	4-L30	{254,80,0}
5722	Morwell South	20	2	4-L20	{254,80,0}
5738	Castlemaine - Chewton via Loddon Prison	6	2	6-c06	{254,80,0}
5741	Traralgon - Traralgon South	6	2	4-L06	{254,80,0}
5746	Dandenong - Brighton via Heatherton Road & Springvale	811	2	4-811	{254,80,0}
5747	Dandenong - Brighton via Parkmore Shopping Centre	812	2	4-812	{254,80,0}
5841	Echuca - Cunningham Downs Retirement Village	4	2	6-Ec4	{254,80,0}
7442	Yarraville - Highpoint SC	223	2	4-223	{254,80,0}
7455	Southland SC - St Kilda Station	922	2	4-922	{254,80,0}
7456	Southland SC - St Kilda Station	923	2	4-923	{254,80,0}
7531	Frankston - Melbourne Airport (SMARTBUS Service)	901	2	4-901	{254,80,0}
7700	Frankston - Osborne via Mt Eliza & Mornington	784	2	4-784	{254,80,0}
7703	Cobram Town Service		2	6-cob	{254,80,0}
7723	Wodonga - East Wodonga	E	2	6-WoE	{254,80,0}
8250	Hamilton East via Ballarat Road	3	2	6-HA3	{254,80,0}
8263	Garden City - City (Queen Victoria Market) via South Melbourne	236	2	4-236	{254,80,0}
8306	Sunshine Station - Sunshine West via Forrest St	427	2	4-427	{254,80,0}
8489	Hoppers Crossing Station - Werribee Station via Werribee Plaza SC	161	2	4-161	{254,80,0}
8561	Huntly - Kangaroo Flat via Bendigo Station	5	2	4-X05	{254,80,0}
8564	Bendigo Station - La Trobe University via Strathdale	61	2	4-B61	{254,80,0}
8565	Bendigo Station - Spring Gully via La Trobe University	62	2	4-B62	{254,80,0}
8567	Bendigo Station - Golden Square via Quarry Hill	64	2	4-B64	{254,80,0}
10994	Epping Plaza SC - South Morang Station via Findon Rd	577	2	4-577	{254,80,0}
11003	Kalkee Retirement Village - Belmont Village SC	49	2	4-G49	{254,80,0}
11109	Kinglake - Whittlesea via Humevale	384	2	4-384	{254,80,0}
11112	Palisades - University Hill	383	2	4-383	{254,80,0}
11118	Thomastown - RMIT Bundoora	570	2	4-570	{254,80,0}
11290	Bendigo Station - East Bendigo via Strickland Rd	60	2	4-B60	{254,80,0}
11320	Mildura Central SC - Mildura South - Mildura Central SC	601	2	6-M61	{254,80,0}
11323	St Albans Station - Brimbank Central SC via Cairnlea	423	2	4-423	{254,80,0}
11326	Mildura City - Mildura Central SC	600	2	6-M60	{254,80,0}
11329	Mildura Central SC - Mildura City	602	2	6-M62	{254,80,0}
11342	Bendigo - Shepparton via Kyabram		2	6-SBO	{254,80,0}
11366	Ballarat Station - Brown Hill	15	2	4-B15	{254,80,0}
11446	Moe - Traralgon via Morwell	1	2	4-L01	{254,80,0}
11455	Moe West	11	2	4-L11	{254,80,0}
11456	Moe South	12	2	4-L12	{254,80,0}
11457	Moe - Moe North	13	2	4-L13	{254,80,0}
11458	Moe - Newborough via Old Sale Rd	14	2	4-L14	{254,80,0}
11461	Moe - Newborough via Dinwoodie Dr	15	2	4-L15	{254,80,0}
11462	Moe - Traralgon via Yallourn North	5	2	4-L05	{254,80,0}
11464	Traralgon North	45	2	4-L45	{254,80,0}
11472	Warragul Station - Warragul North via Stoddarts Rd	82	2	4-W82	{254,80,0}
11516	St Albans Station - Watergardens Station via Keilor Plains Station	421	2	4-421	{254,80,0}
11519	St Albans Station - Watergardens Station via Delahey	425	2	4-425	{254,80,0}
11523	St Albans Station - Brimbank Central SC via Albanvale	424	2	4-424	{254,80,0}
11524	Traralgon via Cross's Road	40	2	4-L40	{254,80,0}
11525	Traralgon West	41	2	4-L41	{254,80,0}
11526	Traralgon - Southside	42	2	4-L42	{254,80,0}
11527	Traralgon East	43	2	4-L43	{254,80,0}
11528	Traralgon via Ellavale Dr	44	2	4-L44	{254,80,0}
11532	Traralgon - Churchill (Special) via Federation University	7	2	4-L07	{254,80,0}
11536	Traralgon - Moe	8	2	4-L08	{254,80,0}
11539	Traralgon - Churchill	9	2	4-L09	{254,80,0}
11591	Frankston Station - Carrum Station via Carrum Downs	833	2	4-833	{254,80,0}
11620	Drouin Station to Traralgon Station (From 14-09-2025)		2	4-V30	{254,80,0}
8569	Bendigo Station - Epsom Station via Goynes Rd	50	2	4-B50	{254,80,0}
8570	Bendigo Station - Eaglehawk via Jackass Flat	51	2	4-B51	{254,80,0}
8571	Bendigo Station - Eaglehawk via Eaglehawk Rd	53	2	4-B53	{254,80,0}
8572	Bendigo Station - Maiden Gully via Calder Hwy	54	2	4-B54	{254,80,0}
8582	Lara Station - Corio Village SC via Lara South	10	2	4-G10	{254,80,0}
8596	City - Warrandyte via Eastern Fwy and The Pines SC	906	2	4-906	{254,80,0}
8599	Geelong Station - Corio SC	20	2	4-G20	{254,80,0}
8606	City - La Trobe University via Eastern Fwy	350	2	4-350	{254,80,0}
8615	City - Deep Creek	318	2	4-318	{254,80,0}
8618	Geelong Station - North Geelong Station via Newtown	24	2	4-G24	{254,80,0}
8621	Geelong Station - Bell Post Hill	25	2	4-G25	{254,80,0}
8630	Geelong Station - Deakin University via Breakwater	40	2	4-G40	{254,80,0}
8639	Geelong Station - Deakin University via Highton	43	2	4-G43	{254,80,0}
8654	Geelong Station - Queenscliff via Ocean Grove	56	2	4-G56	{254,80,0}
8714	Geelong - Bannockburn	19	2	4-G19	{254,80,0}
8765	North Shore Station - Deakin University via Geelong City	1	2	4-G01	{254,80,0}
8871	Thomastown via West Lalor (clockwise loop)	554	2	4-554	{254,80,0}
8878	Thomastown via West Lalor (anti clockwise loop)	557	2	4-557	{254,80,0}
8879	Thomastown via Darebin Drive	559	2	4-559	{254,80,0}
8922	Dandenong - Chadstone via North Dandenong & Oakleigh	862	2	4-862	{254,80,0}
8924	Dandenong - Chadstone via Mulgrave & Oakleigh	802	2	4-802	{254,80,0}
8934	Dandenong - Chadstone via Wheelers Hill & Oakleigh	804	2	4-804	{254,80,0}
8983	Bendigo Station - Spring Gully via Carpenter St	65	2	4-B65	{254,80,0}
10830	Epping Station - Wollert East via Hayston Bvd	356	2	4-356	{254,80,0}
10839	Lara Station - Lara West	12	2	4-G12	{254,80,0}
10842	Epping Station - Wollert via Epping Plaza SC	358	2	4-358	{254,80,0}
10846	Geelong Station - Deakin University via Grovedale	41	2	4-G41	{254,80,0}
10854	Geelong Station - Deakin University via South Valley Rd	42	2	4-G42	{254,80,0}
10917	Laverton Station - Footscray via Geelong Rd	414	2	4-414	{254,80,0}
10923	Bendigo - Goornong		2	4-BGN	{254,80,0}
10924	Castlemaine - Maldon	4	2	6-xM4	{254,80,0}
10927	Footscray - Moonee Ponds via Newmarket	404	2	4-404	{254,80,0}
10937	Epping - Northland via Lalor & Thomastown & Reservoir	555	2	4-555	{254,80,0}
10955	Macleod - Pascoe Vale via La Trobe University	561	2	4-561	{254,80,0}
10964	Yarraville to Highpoint SC via Footscray	409	2	4-409	{254,80,0}
10967	Bendigo Station - Kangaroo Flat via Golden Square	55	2	4-B55	{254,80,0}
10980	Ouyen - Pinnaroo via Mallee Hwy		2	6-Ouy	{254,80,0}
11473	Warragul Station - Warragul East via Copelands Rd	83	2	4-W83	{254,80,0}
11475	Drouin Station - Drouin North via McNeilly Rd	86	2	4-W86	{254,80,0}
11478	Warragul Station - Noojee via Main Neerim Rd & Brandy Creek Rd	89	2	4-W89	{254,80,0}
11507	St Albans Station - Caroline Springs via Keilor Plains Station	418	2	4-418	{254,80,0}
11510	St Albans Station - Highpoint SC via Sunshine Station	408	2	4-408	{254,80,0}
11513	St Albans Station - Watergardens Station via Keilor Downs	419	2	4-419	{254,80,0}
11627	Warragul Station to Drouin North (From 14-09-2025)		2	4-w37	{254,80,0}
11632	Drouin Station to Warragul Station (From 14-09-2025)		2	4-w76	{254,80,0}
11633	Warragul Station to Drouin Station (From 14-09-2025)		2	4-w77	{254,80,0}
11653	North Brighton - Southland via Moorabbin	823	2	4-823	{254,80,0}
13665	Oakleigh Station - Westall Station via Clayton	704	2	4-704	{254,80,0}
13667	Cowes - Fountain Gate via Anderson		2	6-a34	{254,80,0}
13680	Rockbank Station to Aintree	444	2	4-444	{254,80,0}
13686	Sunshine Station - City via Dynon Rd	216	2	4-216	{254,80,0}
13687	Sunshine Station - City via Footscray Rd	220	2	4-220	{254,80,0}
13696	Geelong Station - Drysdale via Clifton Springs	61	2	4-G61	{254,80,0}
13697	Geelong Station - St Leonards via Portarlington	60	2	4-G60	{254,80,0}
13710	Port Melbourne - Casino East-Queens Bridge St (Cruise ship bus shuttle)	109	2	4-PMC	{254,80,0}
13712	Horsham Station - Roberts Avenue	5	2	6-HR5	{254,80,0}
13714	Horsham - Haven	4	2	6-HR4	{254,80,0}
13716	Horsham - Wawunna Rd and South Bank	3	2	6-HR3	{254,80,0}
13718	Horsham - East West (Hospital)	2	2	6-HR2	{254,80,0}
13720	Horsham - Natimuk Road - Shirley St	1	2	6-HR1	{254,80,0}
13722	Stawell South	1	2	6-S01	{254,80,0}
13731	Stawell North	2	2	6-S02	{254,80,0}
13740	Skybus - Avalon Airport - Melbourne City		2	11-Ska	{254,80,0}
13779	Sale - Glebe Estate via Port of Sale	5	2	6-s05	{254,80,0}
13783	Sale - Sale Hospital via Port of Sale	1	2	6-589	{254,80,0}
13788	Sale - Gippsland Regional Sport Complex	2	2	6-298	{254,80,0}
13789	Sale - Wurruk via Princes Highway	3	2	6-209	{254,80,0}
13794	City - Doncaster SC via Belmore Rd and Eastern Fwy	304	2	4-304	{254,80,0}
13796	City - Box Hill -Doncaster SC	302-304 Combined	2	4-C24	{254,80,0}
13797	Yarra Bend - Melbourne University	202_X	2	4-202	{254,80,0}
13826	Endeavour Hills SC - Fountain Gate SC	842	2	4-842	{254,80,0}
13828	Endeavour Hills - Dandenong Station via Daniel Solander Dr	843	2	4-843	{254,80,0}
12739	Sunshine Station - Sunshine South Loop	429	2	4-429	{254,80,0}
12743	Wallan 1 - Wallan Station - Wallan Central	1	2	4-WN1	{254,80,0}
12746	Wallan 2 - Wallan Station - Springridge	2	2	4-WN2	{254,80,0}
12750	Huntingdale -  Monash University (Clayton)	601	2	4-601	{254,80,0}
12766	Keilor East - Footscray via Avondale Heights and Maribyrnong	406	2	4-406	{254,80,0}
12769	Watergardens Station - Caroline Springs Town Centre via Fraser Rise	461	2	4-461	{254,80,0}
13024	Box Hill Station - Chadstone via Surrey Hills & Camberwell & Glen Iris	612	2	4-612	{254,80,0}
13025	Glen Waverley - St Kilda via Mount Waverley & Chadstone & Carnegie	623	2	4-623	{254,80,0}
13027	Elsternwick - Chadstone via Ormond & Oakleigh	625	2	4-625	{254,80,0}
13067	Elwood - Monash University via Gardenvale & Ormond & Huntingdale	630	2	4-630	{254,80,0}
13107	Mernda Station to Diamond Creek Station	381	2	4-381	{254,80,0}
13121	Bendigo Hospital - La Trobe University via Bendigo Station	63	2	4-B63	{254,80,0}
13132	Heathcote - Bendigo via Junortoun & Axedale & Knowsley		2	6-hea	{254,80,0}
13134	Laverton Station - Laverton Station via Laverton North	417	2	4-417	{254,80,0}
13135	Oakleigh - Bentleigh via Mackie Road & Brady Road	701	2	4-701	{254,80,0}
13171	Chirnside Park - Mooroolbark via Manchester Road	675	2	4-675	{254,80,0}
13177	Lysterfield - Knox City via Wantirna & Scoresby & Rowville (anti-clockwise)	682	2	4-682	{254,80,0}
13178	Boronia  - Waverley Gardens via Ferntree Gully & Stud Park	691	2	4-691	{254,80,0}
13179	Belgrave - Oakleigh via Ferntree Gully & Brandon Park	693	2	4-693	{254,80,0}
13263	Bendigo Station - Eaglehawk via Arnold St	52	2	4-X52	{254,80,0}
13267	Mordialloc - Noble Park Station via Keysborough South	709	2	4-709	{254,80,0}
13269	Chadstone SC - Sandringham via Murrumbeena & Southland SC	822	2	4-822	{254,80,0}
13271	Oakleigh - Box Hill via Clayton & Monash University & Mt Waverley	733	2	4-733	{254,80,0}
13287	WN05 - Kangaroo Flat - Bendigo via Golden Square		2	4-BN5	{254,80,0}
13342	Mordialloc - Springvale via Braeside & Clayton South	705	2	4-705	{254,80,0}
13343	Lara Station - Lara East via Rennie St and Lara Lifestyle Village	11	2	4-G11	{254,80,0}
13352	Moorabbin - Keysborough via Clayton & Westall	824	2	4-824	{254,80,0}
13454	Barmah - Echuca via Cummeragunja and Moama		2	6-BM8	{254,80,0}
13455	Kyneton Town Centre to Kyneton Station via Kyneton North	1	2	6-KY1	{254,80,0}
13457	Kyneton to Trentham via  Kyneton Station & Tylden	4	2	6-KY4	{254,80,0}
13459	Kyneton Town Centre  to Kyneton Station via Kyneton Hospital	3	2	6-KY3	{254,80,0}
13545	Caroline Springs - Sunshine Station	426	2	4-426	{254,80,0}
13554	Moorabbin Station - Chadstone SC via Bentleigh	627	2	4-627	{254,80,0}
13621	Skybus - Melbourne Airport - Frankston		2	11-SK4	{254,80,0}
13623	Morwell - Mid Valley Shopping Centre via Crinigan Rd	21	2	4-L21	{254,80,0}
13625	Lancefield - Sunbury-Clarkefield via Romsey & Monegeeta		2	6-LSS	{254,80,0}
13631	Lancefield - Gisborne  via Romsey & Monegeeta & Riddells Creek		2	6-LGG	{254,80,0}
13632	Lancefield - Kyneton via Newham & Carlsruhe		2	6-LKK	{254,80,0}
13636	Williams Landing Station - Saltwater Coast Estate via Sanctuary Lakes SC	497	2	4-497	{254,80,0}
13638	Werribee Station - Jubilee Estate via Greaves St	191	2	4-191	{254,80,0}
13640	Werribee Station - Riverwalk Estate via Westleigh Gardens	441	2	4-441	{254,80,0}
13669	Wangaratta - Myrtleford		2	6-858	{254,80,0}
13830	Endeavour Hills - Dandenong Station via Kennington Park Dr	845	2	4-845	{254,80,0}
13832	Endeavour Hills - Dandenong Station via Dandenong Hospital	861	2	4-861	{254,80,0}
13843	Portland - South	2	2	6-PT2	{254,80,0}
13862	Sale - Loch Sport via Longford	7	2	6-a30	{254,80,0}
13887	Kilmore Town Service (Link Bus)		2	4-KM1	{254,80,0}
14930	Ringwood - Chadstone SC via Vermont South & Glen Waverley & Oakleigh	742	2	4-742	{254,80,0}
14938	The Pines SC - Nunawading Station	273	2	4-273	{254,80,0}
14940	Sunbury Railway Station - Wilson Lane	485	2	4-485	{254,80,0}
15068	Kurunjang - Melton Station	458	2	4-458	{254,80,0}
15073	Benalla - Benalla East	2	2	6-BNZ	{254,80,0}
15074	Warragul Station - Poowong East via Drouin & Ripplebrook (From 14-09-2025)		2	4-WP1	{254,80,0}
15086	Wollert West - Thomastown Station via Epping Station	357	2	4-357	{254,80,0}
15104	Night Bus - Lilydale - Woori Yallock - Healesville - Yarra Glen loop	965	2	4-965	{254,80,0}
15119	Murtoa to Rupanyup shuttle service		2	6-MUR	{254,80,0}
15168	Ballarat Station - Canadian	20	2	4-20B	{254,80,0}
15169	Ballarat Station - Buninyong via Federation University	21	2	4-21B	{254,80,0}
15170	Ballarat Station - Federation University via Sebastopol	22	2	4-22B	{254,80,0}
15239	Chirnside Park - Warburton via Lilydale Station & Seville & Yarra Junction	683	2	4-683	{254,80,0}
15248	Middle Brighton - Chadstone via McKinnon & Carnegie	626	2	4-626	{254,80,0}
15260	Whittlesea - Northland SC via South Morang Station	382	2	4-382	{254,80,0}
15277	Wangaratta - Bright		2	6-DWB	{254,80,0}
15280	Mordialloc SC - Chelsea Railway Station	706	2	4-706	{254,80,0}
15281	Chelsea Railway Station - Dandenong Railway Station via Patterson Lakes	857	2	4-857	{254,80,0}
15284	Edithvale - Aspendale Gardens via Chelsea	858	2	4-858	{254,80,0}
15288	Sorrento - Rosebud	787	2	4-787	{254,80,0}
15504	Frankston - Dromana via Mount Eliza & Mornington and Mount Martha	781	2	4-781	{254,80,0}
15505	Frankston - Lakewood via Heatherhill Road	775	2	4-775	{254,80,0}
15506	Frankston - Rosebud via Monash University Peninsula Campus	887	2	4-887	{254,80,0}
15566	Williams Landing Station - Werribee Station via Princes Hwy	153	2	4-153	{254,80,0}
15567	Laverton Station - Hoppers Crossing Station via Dunnings Rd	498	2	4-498	{254,80,0}
15585	Brunswick Station - Glenroy Station via West Coburg	951	2	4-951	{254,80,0}
15603	Melton Station to Cobblebank Station	454	2	4-454	{254,80,0}
15614	Cranbourne Park SC - Dandenong Station	893	2	4-893	{254,80,0}
15616	Amberly Park  - Hallam Station via Hampton Park	894	2	4-894	{254,80,0}
15620	V63 - Alexandra - Eildon via Thornton		2	6-V63	{254,80,0}
15622	H46 - Wangaratta - Glenrowan		2	6-H46	{254,80,0}
15641	City - The Pines SC via Eastern Fwy and George St	305	2	4-305	{254,80,0}
15643	City - The Pines SC via Eastern Fwy and Reynolds Rd	309	2	4-309	{254,80,0}
15648	City - The Pines SC via Eastern Fwy and Thompsons Rd	905	2	4-905	{254,80,0}
15650	City - Bulleen	200	2	4-200	{254,80,0}
14941	Sunbury Railway Station - Canterbury Hills	489	2	4-489	{254,80,0}
14949	Casey Central SC - Dandenong Station via Hampton Park SC	892	2	4-892	{254,80,0}
14957	Werribee Station - Werribee South via Werribee Park Mansion	439	2	4-439	{254,80,0}
14959	Ballan - Hepburn via Daylesford		2	4-99y	{254,80,0}
14992	Ballarat - Maryborough		2	6-a29	{254,80,0}
14993	Werribee Station - Southern Loop via South Werribee	443	2	4-443	{254,80,0}
14995	Frankston Station - Langwarrin via Langwarrin North	789	2	4-789	{254,80,0}
14997	Frankston Station - Langwarrin via Langwarrin South	790	2	4-790	{254,80,0}
15009	Dandenong Station - Lynbrook Station	890	2	4-890	{254,80,0}
15021	Sale - Sale Station via Reeve Street	4	2	6-a19	{254,80,0}
15023	Sale - Stratford		2	6-947	{254,80,0}
15025	Laverton Station - Footscray via Altona Meadows & Altona & Millers Rd	411	2	4-411	{254,80,0}
15026	Laverton Station - Footscray via Altona Meadows & Altona & Mills St	412	2	4-412	{254,80,0}
15028	Ballan - Mount Egerton via Gordon		2	4-99x	{254,80,0}
15046	Castlemaine Town Loop	2	2	6-R37	{254,80,0}
15061	Melton - Melton Station via Brookfield	453	2	4-453	{254,80,0}
15063	Micasa Rise-Roslyn Park - Melton Station	455	2	4-455	{254,80,0}
15065	Sunshine Station - Melton via Caroline Springs	456	2	4-456	{254,80,0}
15067	Melton - Melton Station via Melton West	457	2	4-457	{254,80,0}
15127	Broadmeadows Station - Craigieburn via Meadow Heights	953	2	4-953	{254,80,0}
15129	Clayton Station - Dandenong Station via Mulgrave	978	2	4-978	{254,80,0}
15131	Clayton Station - Dandenong Station via Keysborough	979	2	4-979	{254,80,0}
15139	City - Broadmeadows Station via Niddrie and Airport West	959	2	4-959	{254,80,0}
15163	Ballarat Station - Wendouree Station via Howitt St	11	2	4-11B	{254,80,0}
15164	Ballarat Station - Wendouree Station via Forest St	12	2	4-12B	{254,80,0}
15171	Ballarat Station - Mount Pleasant	23	2	4-23B	{254,80,0}
15172	Ballarat Station - Sebastopol	24	2	4-24B	{254,80,0}
15173	Ballarat Station - Delacombe	25	2	4-25B	{254,80,0}
15174	Ballarat Station - Alfredton	26	2	4-26B	{254,80,0}
15175	Ballarat Station - Creswick	30	2	4-30B	{254,80,0}
15176	Wendouree Station - Miners Rest	31	2	4-31B	{254,80,0}
15197	Watergardens Station - Melton via Caroline Springs	943	2	4-943	{254,80,0}
15198	Footscray - Newport Station via Altona North	947	2	4-947	{254,80,0}
15199	Williams Landing Station - Altona Meadows via Point Cook	949	2	4-949	{254,80,0}
15203	Castlemaine - Campbells Creek	1	2	6-r89	{254,80,0}
15205	Castlemaine - Harcourt	3	2	6-R36	{254,80,0}
15224	Keysborough South - Noble Park Station	816	2	4-816	{254,80,0}
15227	Belgrave - Lilydale via Kallista & The Patch & Monbulk & Mt Evelyn	663	2	4-663	{254,80,0}
15233	Lilydale Station - Chirnside Park via Switchback Road	677	2	4-677	{254,80,0}
15235	Chirnside Park Shopping Centre - Ringwood via Canterbury Rd	679	2	4-679	{254,80,0}
15237	Lilydale - Mooroolbark via Lilydale East Estate & Lakeview Estate	680	2	4-680	{254,80,0}
15253	Mernda Station - Bundoora RMIT via Cravens Rd & South Morang Station	386	2	4-386	{254,80,0}
15165	Ballarat Station - Invermay Park	13	2	4-13B	{254,80,0}
15166	Ballarat Station - Black Hill	14	2	4-14B	{254,80,0}
15657	Berwick Station - Fountain Gate SC via Berwick North	834	2	4-834	{254,80,0}
15659	Berwick Station - Fountain Gate SC via Narre Warren	835	2	4-835	{254,80,0}
15665	Emerald - Fountain Gate SC via Beaconsfield & Berwick	838	2	4-838	{254,80,0}
15669	Berwick Station - Eden Rise SC via Bryn Mawr Bvd	846	2	4-846	{254,80,0}
15804	City - Box Hill Station via Belmore Rd and Eastern Fwy	302	2	4-302	{254,80,0}
15806	Box Hill Station - Ringwood via Park Orchards	271	2	4-271	{254,80,0}
15808	Box Hill Station - Doncaster SC via Middleborough Rd	279	2	4-279	{254,80,0}
15928	Albury - East Albury (NSW Route 903)		2	6-903	{254,80,0}
15929	Geelong Station - Torquay (Bell St)	53	2	4-G53	{254,80,0}
15931	Torquay (Bell St) - Marshall Station	54	2	4-G54	{254,80,0}
15933	Armstrong Creek - Waurn Ponds SC via Waurn Ponds Station	45	2	4-G45	{254,80,0}
15935	Bacchus Marsh Station - Telford Park via Bacchus Marsh	434	2	4-BM4	{254,80,0}
15942	Endeavour Hills SC - Cranbourne West via Hallam Rd	863	2	4-863	{254,80,0}
15976	Footscray Station - East Melbourne via North Melbourne	402	2	4-402	{254,80,0}
15977	Footscray Station - Melbourne University via Royal Melbourne Hospital	403	2	4-403	{254,80,0}
15979	Elsternwick Station - Fishermans Bend	606	2	4-606	{254,80,0}
15992	Eltham - Glenroy via Greensborough	514	2	4-514	{254,80,0}
16001	Eltham - Glenroy via Greensborough or Lower Plenty	513-514 Combined	2	4-53B	{254,80,0}
16003	Ringwood - Lilydale via Croydon & Chirnside Park	670	2	4-670	{254,80,0}
16004	Croydon - Chirnside Park via Warrien Road & Patrick Ave	671	2	4-671	{254,80,0}
16005	Croydon - Chirnside Park via Wonga Park & Croydon Hills	672	2	4-672	{254,80,0}
16006	Croydon - Upper Ferntree Gully via Olinda and Tremont	688	2	4-688	{254,80,0}
17258	Essendon - East Brunswick via Albion Street	503	2	4-503	{254,80,0}
15673	Clyde - Berwick Station	888	2	4-888	{254,80,0}
15676	Clyde North - Berwick Station via Grices Road	889	2	4-889	{254,80,0}
15680	Hampton - Berwick Station via Southland SC & Dandenong	828	2	4-828	{254,80,0}
15682	C27 - Smythesdale - Delacombe via Haddon (Snake Valley On-demand)		2	6-C27	{254,80,0}
15689	Mernda Station - Bundoora RMIT via Hawkstowe Pde & South Morang	387	2	4-387	{254,80,0}
15693	Mernda Station - Doreen - Mernda Station (Anti-clockwise)	388	2	4-388	{254,80,0}
15707	Kew - Oakleigh via Caulfield & Carnegie & Darling and Chadstone	624	2	4-624	{254,80,0}
15730	Corio SC - North Shore Station	23	2	4-G23	{254,80,0}
15742	Ringwood Station - Eildon SC via Alexandra & Healesville	684	2	4-684	{254,80,0}
15761	Narre Warren South - Fountain Gate SC via Narre Warren Station	895	2	4-895	{254,80,0}
15762	Lilydale Station - Healesville Sanctuary via Coldstream & Yarra Glen	685	2	4-685	{254,80,0}
15777	Wodonga (South) - Albury	150	2	6-876	{254,80,0}
15778	Wodonga (North) - Albury	160	2	6-877	{254,80,0}
15782	City (Southern Cross Station) - Fishermans Bend via Williamstown Road	235	2	4-235	{254,80,0}
15783	City (Southern Cross Station) - Fishermans Bend via Lorimer Street	237	2	4-237	{254,80,0}
15785	Templestowe - Box Hill Bus Station	281	2	4-281	{254,80,0}
15789	Altona - Mordialloc (SMARTBUS Service)	903	2	4-903	{254,80,0}
15798	Box Hill Station to Nunawading	735	2	4-735	{254,80,0}
15799	Box Hill Station - Upper Ferntree Gully via Vermont South & Knox City & Mountain Gate	732	2	4-732	{254,80,0}
15800	Box Hill Station - Burwood via Surrey Hills	766	2	4-766	{254,80,0}
15802	Box Hill Station - Deakin University	201	2	4-201	{254,80,0}
15810	Sunbury Station - Diggers Rest Station	475	2	4-475	{254,80,0}
15814	Southland - Waverley Gardens via Clayton & Monash University	631	2	4-631	{254,80,0}
15817	Sunbury Railway Station - Mount Lion	481	2	4-481	{254,80,0}
15821	Williams Landing Station - Tarneit Station via Sayers Rd  (Until 6th December)	150	2	4-15X	{254,80,0}
15822	Williams Landing Station - Tarneit Station via Westmeadows La (Until 6th December)	151	2	4-x15	{254,80,0}
15823	Tarneit Station - Williams Landing Station via Palmers Rd (Until 6th December)	152	2	4-15c	{254,80,0}
15824	Hoppers Crossing Station - Tarneit Station via Morris Rd (From 6th December)	160	2	4-16a	{254,80,0}
15825	Hoppers Crossing Station - Tarneit Station via Werribee Plaza SC (From 6th December)	167	2	4-16X	{254,80,0}
15826	Werribee Station - Tarneit Station via Tarneit Rd	180	2	4-180	{254,80,0}
15827	Werribee Station - Tarneit Station via Tarneit West (Until 6th December)	182	2	4-18x	{254,80,0}
15828	Werribee Station - Tarneit Station via Werribee Plaza SC (Until 6th December)	170	2	4-17X	{254,80,0}
15829	Sunbury Railway Station - Killara Heights	487	2	4-487	{254,80,0}
15830	Sunbury Railway Station - Jacksons Hill	488	2	4-488	{254,80,0}
15831	Sunbury Railway Station - Rolling Meadows	486	2	4-486	{254,80,0}
15836	Essendon Station - Ivanhoe Station via Brunswick & Northcote & Thornbury	510	2	4-510	{254,80,0}
15838	Strathmore - East Coburg via Pascoe Vale South & Coburg West & Coburg	512	2	4-512	{254,80,0}
15839	Sunbury - Moonee Ponds via Diggers Rest	483	2	4-483	{254,80,0}
15877	Mernda Station - Craigieburn Station via Wollert	390	2	4-390	{254,80,0}
15886	Sunshine Station - Laverton Station via Robinsons Road	400	2	4-400	{254,80,0}
15888	Sunshine Station - Watergardens Station via Deer Park	420	2	4-420	{254,80,0}
15890	Sunshine Station - Brimbank Central SC via Deer Park	422	2	4-422	{254,80,0}
15892	Maddingley - Darley via Bacchus Marsh Station	433	2	4-BM3	{254,80,0}
15916	Albury to Lavington via North Albury & Springdale Heights (NSW Route 906)		2	6-906	{254,80,0}
15918	Albury to Quicks Hill via TAFE & Glenroy & Lavington (NSW Route 907)		2	6-907	{254,80,0}
15920	Albury to Thurgoona via North Albury & Lavington & Uni. (NSW Route 908)		2	6-908	{254,80,0}
15922	Albury to Thurgoona via Hospital & Airport (NSW Route 909)		2	6-909	{254,80,0}
15924	Albury - West Albury (NSW Route 901)		2	6-901	{254,80,0}
15926	Albury - South Albury (NSW Route 902)		2	6-902	{254,80,0}
16019	Gembrook - Pakenham Station via Pakenham Upper	840	2	4-840	{254,80,0}
16021	Williams Landing Station - Point Cook South via Alamanda Bvd	494	2	4-494	{254,80,0}
16023	Williams Landing Station -  Point Cook South via Boardwalk Bvd	495	2	4-495	{254,80,0}
16203	Maryborough - Bendigo		2	6-b29	{254,80,0}
16228	Geelong Station - Leopold	32	2	4-G32	{254,80,0}
16230	Geelong Station - Ocean Grove via Barwon Heads	55	2	4-G55	{254,80,0}
16234	Geelong Station - St Albans Park	31	2	4-G31	{254,80,0}
16236	Jan Juc (Torquay) - Marshall Station	52	2	4-G52	{254,80,0}
16715	Moonee Ponds - Keilor East via Airport West	469	2	4-469	{254,80,0}
16723	Watergardens Station - Caroline Springs Station via Caroline Spring Town Centre	460	2	4-460	{254,80,0}
16732	Campbellfield Plaza - Coburg via Fawkner	530	2	4-530	{254,80,0}
16733	Upfield Station - North Coburg via Somerset Estate	531	2	4-531	{254,80,0}
16734	Craigieburn Station - Broadmeadows Station via Upfield Station	532	2	4-532	{254,80,0}
16735	Craigieburn Station to Roxburgh Park Station via Roxburgh Park SC	544	2	4-544	{254,80,0}
16739	Craigieburn Station - Craigieburn North via Craigieburn Central SC	529	2	4-529	{254,80,0}
16740	Craigieburn Station to Craigieburn Central SC via Elevation Bvd	528	2	4-528	{254,80,0}
16741	Craigieburn Station to Craigieburn Central SC via Cimberwood Dr	537	2	4-537	{254,80,0}
16742	Craigieburn - Craigieburn North via Hanson Rd	533	2	4-533	{254,80,0}
16743	Craigieburn Station to Donnybrook Station via Hume Fwy	501	2	4-501	{254,80,0}
17250	Hurstbridge Station - Greensborough Station via Diamond Creek Station	343	2	4-343	{254,80,0}
17253	Preston - West Preston via Reservoir	553	2	4-553	{254,80,0}
17254	Reservoir via North West Reservoir	558	2	4-558	{254,80,0}
17255	Northcote - Regent via Northland	567	2	4-567	{254,80,0}
17256	Brunswick West - Barkly Square SC via Hope St and Sydney Rd	509	2	4-509	{254,80,0}
17257	North East Reservoir - Northcote Plaza via High Street	552	2	4-552	{254,80,0}
16027	Pakenham Station - Fountain Gate Shopping Centre via Lakeside & Beaconsfield	926	2	4-926	{254,80,0}
16029	Pakenham Station - Pakenham North via Meadowvale	927	2	4-927	{254,80,0}
16033	Pakenham Station - Pakenham North via Army Rd & Windermere Bvd	929	2	4-929	{254,80,0}
16035	The Avenue Village SC - Berwick Station	899	2	4-899	{254,80,0}
16072	Gisborne Station - Willowbank Road	73	2	6-G73	{254,80,0}
16074	Gisborne Station - Willowbank Road	74	2	6-G74	{254,80,0}
16076	Bullengarook - Gisborne Station   On-demand only	77	2	6-G77	{254,80,0}
16077	Gardenvale - City (Queen Victoria Market)	605	2	4-605	{254,80,0}
16079	Ringwood Station - Croydon Station via Burnt Bridge Shopping Centre	668	2	4-668	{254,80,0}
16081	Ringwood Station - Croydon Station via Ringwood East Station	669	2	4-669	{254,80,0}
16087	Brighton Beach - Burnley Station via Elsternwick Station	603	2	4-603	{254,80,0}
16089	Elsternwick Station - Anzac Station via Toorak Station	604	2	4-604	{254,80,0}
16115	Eynesbury - Melton Station	452	2	4-452	{254,80,0}
16136	Warneet - Cranbourne Station	795	2	4-795	{254,80,0}
16137	Cranbourne Station - Clyde	796	2	4-796	{254,80,0}
16139	Clyde North - Lynbrook Station via Cranbourne Park SC	897	2	4-897	{254,80,0}
16140	Clyde North - Cranbourne Station via Cranbourne Park SC	898	2	4-898	{254,80,0}
16142	Narre Warren North - Cranbourne via Narre Warren & Cranbourne North	841	2	4-841	{254,80,0}
16143	Dandenong Station - Cranbourne via Berwick	981	2	4-981	{254,80,0}
16197	Merinda Park Station - The Avenue Village SC	799	2	4-799	{254,80,0}
16238	Ballarat Station - Lucas via Wendouree	10	2	4-10B	{254,80,0}
16269	Box Hill Station - Greensborough Station via Doncaster SC	293	2	4-293	{254,80,0}
16290	Whittlesea-Mernda Station - Greensborough Station	385	2	4-385	{254,80,0}
16367	Greensborough Station - St Helena West via St Helena	518	2	4-518	{254,80,0}
16372	Lalor - Northland via Plenty Road & Childs Road & Grimshaw Street	566	2	4-566	{254,80,0}
16396	Dandenong - Chadstone via Princes Highway & Oakleigh	800	2	4-800	{254,80,0}
16406	Chelsea Railway Station - Airport West Shopping Centre	902	2	4-902	{254,80,0}
16440	City - Doncaster Shopping Centre via Kew Junction	207	2	4-207	{254,80,0}
16445	Manningham Loop via Templestowe Village SC & Doncaster SC	282	2	4-282	{254,80,0}
16447	Doncaster Park & Ride - Box Hill Station via Union Road	284	2	4-284	{254,80,0}
16449	Doncaster Park & Ride - Camberwell via North Balwyn	285	2	4-285	{254,80,0}
16451	City - Ringwood North via Park Rd	303	2	4-303	{254,80,0}
16453	City - The Pines SC via Eastern Fwy and High St	908	2	4-908	{254,80,0}
16482	City - Mitcham via Eastern Fwy and Doncaster Rd	907	2	4-907	{254,80,0}
16535	Merinda Park Station - Clyde North	881	2	4-881	{254,80,0}
16563	Berwick Station - The Avenue Village SC	847	2	4-847	{254,80,0}
16590	Pakenham Station - Officer South via Cardinia Road Station	925	2	4-925	{254,80,0}
16613	Mernda Station - Doreen - Mernda Station (Clockwise)	389	2	4-389	{254,80,0}
16615	Cranbourne Park SC - Clyde North via Hardys Road	798	2	4-798	{254,80,0}
16624	Upfield - Broadmeadows via Coolaroo	540	2	4-540	{254,80,0}
16633	Roxburgh Park - Pascoe Vale via Meadow Heights & Broadmeadows & Glenroy	542	2	4-542	{254,80,0}
16640	Broadmeadows Station - Craigieburn North (Mt Ridley Rd)	541	2	4-541	{254,80,0}
16641	Glenroy to Coburg via Boundary Road & Sydney Road	534	2	4-534	{254,80,0}
16642	Glenroy - Gowrie via Gowrie Park	536	2	4-536	{254,80,0}
16645	Somerset Estate - Broadmeadows via Camp Road	538	2	4-538	{254,80,0}
16647	Essendon Station - Keilor Park via East Keilor	465	2	4-465	{254,80,0}
16648	Aberfeldie - Moonee Ponds via Holmes Road	467	2	4-467	{254,80,0}
16649	Essendon - Highpoint SC via Maribyrnong	468	2	4-468	{254,80,0}
16713	Watergardens Station - Hillside via Langmore Dr	463	2	4-463	{254,80,0}
16714	Watergardens - Moonee Ponds via Keilor	476	2	4-476	{254,80,0}
19061	Williams Landing Station - Tarneit Station via Westmeadows La (From 7th December)	151	2	4-151	{254,80,0}
19063	Hoppers Crossing Station - Tarneit Station via Werribee Plaza SC (From 7th December)	167	2	4-167	{254,80,0}
19065	Werribee Station - Tarneit Station via Werribee Plaza SC (From 7th December)	170	2	4-170	{254,80,0}
19081	Tarneit Station - Williams Landing Station via Palmers Rd (From 7th December)	152	2	4-152	{254,80,0}
19084	Hoppers Crossing Station - Tarneit Station via Morris Rd (From 7th December)	160	2	4-160	{254,80,0}
19086	Werribee Station - Tarneit Station via Tarneit West  (From 7th December)	182	2	4-182	{254,80,0}
19087	Skybus - Melbourne Airport - Sunshine Railway Station		2	11-SUN	{254,80,0}
17265	Eltham - Warrandyte via Research & Kangaroo Ground & Warrandyte Road	578-579 combined	2	4-C12	{254,80,0}
17289	Eltham Station - Warrandyte via Research & Kangaroo Ground-Warrandyte Road	578	2	4-578	{254,80,0}
17290	Eltham Station - Warrandyte via Research & Research - Warrandyte Road	579	2	4-579	{254,80,0}
17291	Diamond Creek - Eltham Station via Ryans Rd	580	2	4-580	{254,80,0}
17295	Eltham Town Service via Woodridge Estate	582	2	4-582	{254,80,0}
18900	Lysterfield - Knox City via Wantirna & Scoresby & Rowville (clockwise)	681	2	4-681	{254,80,0}
18901	Eltham - Glenroy via Lower Plenty	513	2	4-513	{254,80,0}
18902	Berwick Station - Clyde via Bells Rd	831	2	4-831	{254,80,0}
18903	Pakenham Station - Berwick Station via Cardinia Road Station	928	2	4-928	{254,80,0}
18904	Airport West to Gowanbrae via Melrose Dr & Gowanbrae Dr	490	2	4-490	{254,80,0}
18905	Airport West SC - Melbourne Airport via South Centre Rd	482	2	4-482	{254,80,0}
18906	Airport West SC - Melbourne Airport via Melrose Drive	478	2	4-478	{254,80,0}
18908	Moonee Ponds - Broadmeadows Station via Essendon & Airport West & Gladstone Park	477	2	4-477	{254,80,0}
18909	Broadmeadows - Roxburgh Park via Greenvale	484	2	4-484	{254,80,0}
18910	Airport West SC - Sunbury Station via Melbourne Airport	479	2	4-479	{254,80,0}
18913	Cranbourne - Seaford via Carrum Downs	760	2	4-760	{254,80,0}
18915	Berwick Station - Eden Rise SC via Bridgewater Estate	836	2	4-836	{254,80,0}
18917	Berwick Station - Beaconsfield East via Brisbane St & Beaconsfield Plaza SC	837	2	4-837	{254,80,0}
18918	Chirnside Park - Knox City via Croydon & Bayswater	664	2	4-664	{254,80,0}
18919	Croydon - Montrose via Hawthory Road & Durham Road	689	2	4-689	{254,80,0}
18923	Bendigo Station - Strathfieldsaye via Kennington	70	2	4-X70	{254,80,0}
18924	Strathfieldsaye SC Loop via Strathfieldsaye and Junortoun	71	2	4-B71	{254,80,0}
18925	SkyBus Eastern Express		2	11-box	{254,80,0}
18929	Craigieburn Central - Roxburgh Park via Greenvale Gardens (From 5th October 2025)	543	2	4-543	{254,80,0}
18934	Dandenong Station - Cranbourne via Endeavour Hills & Hampton Park	982	2	4-982	{254,80,0}
18936	Frankston Station - Cranbourne Station	791	2	4-791	{254,80,0}
18938	Cranbourne Station - Pearcedale	792	2	4-792	{254,80,0}
18945	Craigieburn Station - Mandalay via Hume Fwy (From 5th October 2025)	511	2	4-511	{254,80,0}
18946	Warragul Station - Warragul South via West Gippsland Hospital  (From 14-09-2025)	80	2	4-W80	{254,80,0}
18947	Warragul Station - Drouin Station via Drouin South  (From 14-09-2025)	85	2	4-W85	{254,80,0}
18949	Traralgon Station to Drouin North (From 14-09-2025)		2	4-V83	{254,80,0}
18951	Drouin North to Moe - Albert St (From 14-09-2025)		2	4-V89	{254,80,0}
18952	Warragul Station to Moe - Albert St (From 14-09-2025)		2	4-V90	{254,80,0}
18953	Drouin North to Warragul Station (From 14-09-2025)		2	4-V93	{254,80,0}
3394	Warrnambool - Port Campbell - Timboon via Allansford & Nullawarre & Peterborough		2	6-WPC	{254,80,0}
3438	Frankston - Mt Eliza - Mornington East-Dromana	781-784-785 combined	2	4-C15	{254,80,0}
5704	Morwell - Mid Valley Shopping Centre via Hourigan Rd	22	2	4-L22	{254,80,0}
7453	Southland Shopping Centre - St Kilda Station	600	2	4-600	{254,80,0}
7891	Warrandyte - Ringwood Station via Croydon & Warrandyte Rd & Eastland SC	364	2	4-364	{254,80,0}
8484	Hoppers Crossing Station - Wyndham Vale Station via Werribee Plaza SC	166	2	4-166	{254,80,0}
8487	Werribee Station - Wyndham Vale Station via Black Forest Rd	192	2	4-192	{254,80,0}
8611	Geelong Station - North Shore Station via Anakie Rd	22	2	4-G22	{254,80,0}
10933	Epping Plaza SC - Northland SC via Keon Park	556	2	4-556	{254,80,0}
11466	Warragul Station - Warragul North via Latrobe St	81	2	4-W81	{254,80,0}
12749	Wallan 3 - Wallan Station - Wallara Waters Shuttle (Link B)		2	4-WN3	{254,80,0}
13270	Middle Brighton - Blackburn via Bentleigh & Clayton & Monash University	703	2	4-703	{254,80,0}
\.


--
-- Name: routes routes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--



--
-- PostgreSQL database dump complete
--

\unrestrict hcSAqNnL0EDR0ugFem0p9aQBkJhf9MQYHXrCBZwVuTQd9HJsFa7PjnJFNlFGcKM

