-- Geofence: location + optional lat/lon on every active brand.
UPDATE brands
SET optional_fields = (
      SELECT jsonb_agg(DISTINCT value ORDER BY value)
      FROM (
        SELECT value FROM jsonb_array_elements_text(COALESCE(optional_fields, '[]'::jsonb)) AS value
        UNION ALL SELECT 'location'
        UNION ALL SELECT 'latitude'
        UNION ALL SELECT 'longitude'
      ) s
    ),
    updated_at = NOW()
WHERE id IN (
  'bookmyshow', 'district', 'irctc', 'indigo', 'namma-metro', 'redbus', 'upi',
  'easydiner', 'zomato-dineout', 'swiggy-dineout', 'airbnb', 'zoomcar'
);
