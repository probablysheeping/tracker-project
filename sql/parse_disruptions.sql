-- Manually parse and update disruption events for tram and V/Line disruptions

-- Tram route 82 closure
UPDATE disruptions
SET disruption_event = '{
  "event_type": "service_suspended",
  "route_type": 1,
  "route_number": "82",
  "affected_area": {
    "start_location": "Stop 37 Union Road",
    "end_location": "Moonee Ponds",
    "type": "segment"
  },
  "periods": []
}'::jsonb
WHERE disruption_id = 351443;

-- V/Line coach delay (Geelong to Apollo Bay)
UPDATE disruptions
SET disruption_event = '{
  "event_type": "delay",
  "route_type": 3,
  "delay_minutes": 60,
  "affected_area": {
    "start_location": "Geelong",
    "end_location": "Apollo Bay",
    "type": "route"
  },
  "periods": []
}'::jsonb
WHERE disruption_id = 351530;

-- V/Line coach delay (Lorne Hotel to Geelong)
UPDATE disruptions
SET disruption_event = '{
  "event_type": "delay",
  "route_type": 3,
  "delay_minutes": 35,
  "affected_area": {
    "start_location": "Lorne Hotel",
    "end_location": "Geelong",
    "type": "route"
  },
  "periods": []
}'::jsonb
WHERE disruption_id = 351660;
