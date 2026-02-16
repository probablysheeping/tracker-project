-- Add disruption_mode_id column to route_types table
-- This establishes a relationship between route types and disruption modes

-- Step 1: Add the column (nullable initially to allow data migration)
ALTER TABLE route_types
ADD COLUMN disruption_mode_id INTEGER;

-- Step 2: Populate the column with appropriate mappings
UPDATE route_types SET disruption_mode_id = 1 WHERE route_type = 0; -- Train -> metro_train
UPDATE route_types SET disruption_mode_id = 3 WHERE route_type = 1; -- Tram -> metro_tram
UPDATE route_types SET disruption_mode_id = 2 WHERE route_type = 2; -- Bus -> metro_bus
UPDATE route_types SET disruption_mode_id = 5 WHERE route_type = 3; -- Vline -> regional_train
UPDATE route_types SET disruption_mode_id = 10 WHERE route_type = 4; -- Night Bus -> night_bus

-- Step 3: Make the column NOT NULL now that data is populated
ALTER TABLE route_types
ALTER COLUMN disruption_mode_id SET NOT NULL;

-- Step 4: Add foreign key constraint
ALTER TABLE route_types
ADD CONSTRAINT fk_route_types_disruption_mode
FOREIGN KEY (disruption_mode_id)
REFERENCES disruption_modes(disruption_mode_id);

-- Step 5: Verify the update
SELECT rt.route_type, rt.route_type_name, rt.disruption_mode_id, dm.disruption_mode_name
FROM route_types rt
JOIN disruption_modes dm ON rt.disruption_mode_id = dm.disruption_mode_id
ORDER BY rt.route_type;
