# slip-pass-edge (Cloudflare Worker)

Optional serverless **edge** in front of OCI pass-engine. Certificates and `.pkpass` signing stay on the VM.

```bash
cd deploy/cloudflare-worker
npx wrangler secret put PASS_ENGINE_ORIGIN   # or set [vars] in wrangler.toml
npx wrangler deploy
```

Point `SlipAPIBaseURL` in the iOS app at the Worker URL when ready.
