-- Dining confirmations rarely include a QR; booking_id is the Wallet barcode.
UPDATE brands SET
  required_fields = '["restaurant", "booking_id"]'::jsonb,
  optional_fields = '["time", "party_size", "qr_data"]'::jsonb,
  updated_at = NOW()
WHERE id IN ('easydiner', 'zomato-dineout', 'swiggy-dineout');
