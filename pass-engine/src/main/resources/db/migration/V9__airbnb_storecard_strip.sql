-- Airbnb: storeCard so PassKit renders strip art (gradients) like brand Wallet passes.
UPDATE brands
SET apple_style = 'storeCard',
    updated_at = NOW()
WHERE id = 'airbnb' AND apple_style <> 'storeCard';
