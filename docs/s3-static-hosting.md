# S3 static files (downloads, `.well-known`, etc.)

This repo keeps public-but-not-Lambda assets under **`static-public/`**. They are deployed to a **dedicated S3 bucket** and are usually served via **CloudFront** (same pattern as `directkey.spsw.io`’s `links-src/` → S3).

Lambda (Bref) is for dynamic PHP; large or binary static assets belong in S3.

## One-time: create the bucket

1. Pick a **globally unique** bucket name (e.g. `uu-networking-test-server-static-<yourorg>`).
2. Edit **`BUCKET`** / **`REGION`** at the top of **`scripts/setup_s3_static_bucket.sh`** (or export env vars).
3. Run:

```bash
chmod +x scripts/setup_s3_static_bucket.sh
./scripts/setup_s3_static_bucket.sh
```

This creates a **private** bucket (no public ACLs), AES-256 default encryption, and public access blocked — same baseline as the directkey setup.

## Upload / sync local files

Put files under **`static-public/`** (see `static-public/README.md`). Then:

```bash
export BUCKET=your-bucket-name
./scripts/sync_static_to_s3.sh
```

The sync is **destructive** at the bucket root (`aws s3 sync … --delete`): objects not present locally may be removed from S3. Hidden junk is skipped on upload (`.DS_Store`, `.gitkeep`, `._*`, IDE folders, etc.). **Note:** AWS CLI does **not** delete excluded keys that are already in S3, so the script runs a second step that removes those junk keys explicitly. Files under **`.well-known/`** still sync when the **filename** does not start with a dot.

After sync, the script reapplies **`Content-Type`** for:

- **`.well-known/apple-app-site-association`** → `application/json`
- **`.well-known/assetlinks.json`** → `application/json`
- **`*.zip`** anywhere under `static-public/` → `application/zip`
- **`*.html` / `*.htm`** → `text/html; charset=utf-8` (e.g. `static-public/web/index.html` → `https://<host>/web/index.html` with a CloudFront behavior **`web/*`** on the S3 origin)

List what is in the bucket:

```bash
./scripts/list_static_s3.sh
```

## Serving URLs (CloudFront)

Browsers and mobile clients should **not** hit the raw `s3.amazonaws.com` URL for a private bucket. Add this bucket as a **second origin** on CloudFront (or a separate distribution / hostname):

1. **Origin**: S3 bucket (REST API endpoint), with **Origin Access Control (OAC)** — not legacy OAI unless you already use it.
2. **Bucket policy**: allow `s3:GetObject` for that CloudFront distribution’s service principal (AWS console can generate this when you attach OAC).
3. **Behaviors**: path patterns e.g. **`downloads/*`**, **`web/*`**, **`/static/*`** (as needed), all to the same S3 origin with **empty origin path** so URL paths match object keys (`/web/index.html` → `web/index.html`).
4. **Cache**: for zips you can use a moderate TTL; well-known files often use short TTL (see sync script cache headers).

Details vary by console version; see [CloudFront + S3 OAC](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html).

## Relationship to the PHP API

- **API / JSON tests** → Lambda URL or custom domain pointing at API Gateway.
- **Static zips / universal links** → CloudFront → S3 origin using this workflow.

Your test clients can use absolute HTTPS URLs served by CloudFront for downloads, and the PHP app under Lambda for dynamic endpoints.
