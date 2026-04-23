# Static files for S3 / CloudFront

Put files here that should be served from your **S3 bucket** (not from Lambda). Typical uses:

- **`.well-known/`** — `apple-app-site-association`, `assetlinks.json`, etc.
- **`downloads/`** — `.zip` or other assets for integration tests (`Content-Type` is fixed on upload by `scripts/sync_static_to_s3.sh`).
- **`web/`** — static HTML (`*.html` / `*.htm` get `text/html; charset=utf-8`). Map **`web/*`** on CloudFront to the same S3 origin as `downloads/*`.

Edit **`BUCKET`** / **`REGION`** in the scripts under `scripts/`, then:

```bash
./scripts/setup_s3_static_bucket.sh    # once per bucket name
./scripts/sync_static_to_s3.sh        # whenever you change files here
```

Serving publicly goes through **CloudFront** with **Origin Access Control (OAC)** pointing at this bucket — see `docs/s3-static-hosting.md`.

Do not commit large secrets; zips under `downloads/` are gitignored by default (`*.zip`).
