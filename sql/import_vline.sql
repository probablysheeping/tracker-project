-- Import V/Line routes (route_type = 3)
INSERT INTO gtfs_routes (route_id, agency_id, route_short_name, route_long_name, route_type, route_color, route_text_color) VALUES
('aus:vic:vic-01-ABY:', '', 'Seymour', 'Albury - Melbourne Via Seymour', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-ART:', '', 'Ballarat', 'Ararat - Melbourne Via Ballarat', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-BAT:', '', 'Ballarat', 'Ballarat - Melbourne Via Melton', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-BDE:', '', 'Traralgon', 'Bairnsdale - Melbourne Via Traralgon & Sale', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-BGO:', '', 'Bendigo', 'Bendigo - Melbourne Via Sunbury', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-ECH:', '', 'Bendigo', 'Echuca/Moama - Melbourne Via Bendigo or Heathcote', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-GEL:', '', 'Geelong', 'Geelong - Melbourne Via Geelong', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-MBY:', '', 'Ballarat', 'Maryborough - Melbourne Via Ballarat', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-SER:', '', 'Seymour', 'Seymour - Melbourne Via Broadmeadows', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-SNH:', '', 'Seymour', 'Shepparton - Melbourne Via Seymour', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-SWL:', '', 'Bendigo', 'Swan Hill - Melbourne Via Bendigo', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-TRN:', '', 'Traralgon', 'Traralgon - Melbourne Via Pakenham, Moe & Morwell', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-vPK:', '', 'Pakenham', 'Pakenham - City Via Pakenham', 3, '8F1A95', 'FFFFFF'),
('aus:vic:vic-01-WBL:', '', 'Geelong', 'Warrnambool - Melbourne Via Geelong & Colac', 3, '8F1A95', 'FFFFFF')
ON CONFLICT (route_id) DO UPDATE SET
  route_short_name = EXCLUDED.route_short_name,
  route_long_name = EXCLUDED.route_long_name,
  route_type = EXCLUDED.route_type,
  route_color = EXCLUDED.route_color,
  route_text_color = EXCLUDED.route_text_color;
