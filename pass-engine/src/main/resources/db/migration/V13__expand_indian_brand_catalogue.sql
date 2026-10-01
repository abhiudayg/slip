-- Expanded Indian brand catalogue (OTA, rides, gyms, retail, UTS/Chalo).
INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('cult', 'Cult.fit', 'fitness', 'storeCard', '["name", "qr_data"]'::jsonb, '["membership", "center", "plan", "valid_thru", "checkins", "member_id", "status"]'::jsonb, TRUE, TRUE, 'rgb(230, 46, 72)', NULL, 'Cult.fit gym access QR for centre check-in.', 'Gym', 'figure.run')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('golds-gym', 'Gold''s Gym', 'fitness', 'storeCard', '["name", "qr_data"]'::jsonb, '["membership", "center", "plan", "valid_thru", "checkins", "member_id", "status"]'::jsonb, TRUE, TRUE, 'rgb(217, 173, 56)', NULL, 'Gold''s Gym membership access pass.', 'Gym', 'dumbbell.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('makemytrip', 'MakeMyTrip', 'travel', 'boardingPass', '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "pnr", "booking_id", "flight", "dep", "arr", "date", "time", "duration", "seat", "status"]'::jsonb, TRUE, TRUE, 'rgb(64, 115, 242)', NULL, 'MakeMyTrip flight and trip booking passes.', 'Travel', 'suitcase.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('cleartrip', 'Cleartrip', 'travel', 'boardingPass', '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "pnr", "booking_id", "flight", "dep", "arr", "date", "time", "duration", "seat", "status"]'::jsonb, TRUE, TRUE, 'rgb(249, 115, 22)', NULL, 'Cleartrip booking passes for flights and hotels.', 'Travel', 'suitcase.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('yatra', 'Yatra', 'travel', 'boardingPass', '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "pnr", "booking_id", "flight", "dep", "arr", "date", "time", "duration", "seat", "status"]'::jsonb, TRUE, TRUE, 'rgb(234, 88, 12)', NULL, 'Yatra trip and flight e-passes.', 'Travel', 'suitcase.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('uts', 'UTS Unreserved', 'transit', 'boardingPass', '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "booking_id", "dep", "arr", "date", "time", "class", "status", "fare", "ticket_type"]'::jsonb, TRUE, TRUE, 'rgb(37, 99, 235)', NULL, 'Indian Railways UTS unreserved QR tickets.', 'UTS', 'tram.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('chalo', 'Chalo', 'transit', 'boardingPass', '["origin", "destination", "qr_data"]'::jsonb, '["passenger", "booking_id", "dep", "arr", "date", "time", "fare", "ticket_type"]'::jsonb, TRUE, TRUE, 'rgb(16, 185, 129)', NULL, 'Chalo city bus QR tickets.', 'Bus', 'bus.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('uber', 'Uber', 'travel', 'generic', '["pickup", "qr_data"]'::jsonb, '["drop_off", "destination", "vehicle", "plate", "driver", "ride_pin", "eta", "time", "status", "service", "booking_id"]'::jsonb, TRUE, TRUE, 'rgb(20, 20, 20)', NULL, 'Uber scheduled and airport ride passes.', 'Ride', 'car.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('ola', 'Ola', 'travel', 'generic', '["pickup", "qr_data"]'::jsonb, '["drop_off", "destination", "vehicle", "plate", "driver", "ride_pin", "eta", "time", "status", "service", "booking_id"]'::jsonb, TRUE, TRUE, 'rgb(34, 197, 94)', NULL, 'Ola ride and outstation booking passes.', 'Ride', 'car.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('tata-neu', 'Tata Neu', 'retail', 'storeCard', '["name", "qr_data"]'::jsonb, '["store", "offer", "offer_code", "discount", "points", "tier", "valid_thru", "member_id", "booking_id"]'::jsonb, TRUE, FALSE, 'rgb(139, 92, 246)', NULL, 'Tata Neu loyalty and store offers.', 'Loyalty', 'n.circle.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('reliance-smart', 'Reliance Smart', 'retail', 'storeCard', '["name", "qr_data"]'::jsonb, '["store", "offer", "points", "tier", "valid_thru", "member_id", "booking_id"]'::jsonb, TRUE, FALSE, 'rgb(249, 115, 22)', NULL, 'Reliance Smart grocery loyalty pass.', 'Loyalty', 'cart.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('shoppers-stop', 'Shoppers Stop', 'retail', 'storeCard', '["name", "qr_data"]'::jsonb, '["store", "offer", "points", "tier", "valid_thru", "member_id", "booking_id"]'::jsonb, TRUE, FALSE, 'rgb(124, 58, 237)', NULL, 'First Citizen loyalty pass for Shoppers Stop.', 'Loyalty', 'bag.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

INSERT INTO brands (id, display_name, category, apple_style, required_fields, optional_fields, supports_locations, supports_relevant_date, accent_hint, station_catalog, summary, badge, icon_hint)
VALUES ('bigbasket', 'BigBasket', 'retail', 'coupon', '["name", "qr_data"]'::jsonb, '["store", "offer", "offer_code", "discount", "valid_till", "booking_id"]'::jsonb, TRUE, TRUE, 'rgb(132, 204, 22)', NULL, 'BigBasket coupon and membership offers.', 'Coupon', 'leaf.fill')
ON CONFLICT (id) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  category = EXCLUDED.category,
  apple_style = EXCLUDED.apple_style,
  required_fields = EXCLUDED.required_fields,
  optional_fields = EXCLUDED.optional_fields,
  supports_locations = EXCLUDED.supports_locations,
  supports_relevant_date = EXCLUDED.supports_relevant_date,
  accent_hint = EXCLUDED.accent_hint,
  summary = EXCLUDED.summary,
  badge = EXCLUDED.badge,
  icon_hint = EXCLUDED.icon_hint;

