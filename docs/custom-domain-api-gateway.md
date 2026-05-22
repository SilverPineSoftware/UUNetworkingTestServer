# Custom domain → API Gateway (HTTP API) → Lambda

This project serves dynamic PHP on **API Gateway HTTP API → Lambda (Bref PHP-FPM)**. The production hostname **`uu.spsw.io`** uses an **API Gateway custom domain** in **us-west-2**, not a hand-built CloudFront distribution in front of the API.

## Architecture

```text
uu.spsw.io  →  API Gateway custom domain  →  HTTP API  →  Lambda (Bref)
```

Static zips / `.well-known` on S3 are a **separate** concern (`docs/s3-static-hosting.md`); they are not required for PHP API integration tests.

## Prerequisites

- Successful deploy (`./scripts/deploy_lambda.sh`) and a working **invoke URL** (`https://xxxx.execute-api.us-west-2.amazonaws.com`).
- DNS access for `spsw.io` (or your zone).

## 1) ACM certificate (us-west-2)

1. **Certificate Manager** → region **US West (Oregon) / us-west-2** (must match `provider.region` in `serverless.yml`).
2. Request a **public** certificate for **`uu.spsw.io`** (or a wildcard you control).
3. **DNS validation** — add the CNAME(s) at your DNS provider.
4. Wait until status is **Issued**.

Do **not** use us-east-1 unless you intentionally create an **edge-optimized** API Gateway domain (different model; AWS may front it with a managed CloudFront distribution).

## 2) API Gateway custom domain

**API Gateway** → **Custom domain names** (region **us-west-2**):

| Setting | Value |
|--------|--------|
| Domain name | `uu.spsw.io` |
| Endpoint type | **Regional** (recommended) |
| Certificate | ACM cert from step 1 |

Save and copy the **API Gateway domain target** (hostname like `d-xxxxxxxx.execute-api.us-west-2.amazonaws.com`).

## 3) API mapping

Open your **HTTP API** (created by Serverless) → **API mappings** (or configure from the custom domain):

| Field | Value |
|--------|--------|
| Domain | `uu.spsw.io` |
| API | `uu-networking-test-server` (or your API name) |
| Stage | **`$default`** |
| Path | *(empty)* |

An empty path avoids prefixing URLs with a stage (e.g. `/prod/form.php`).

## 4) DNS

At your DNS provider, for **`uu.spsw.io`**:

- **Type:** CNAME (or Route 53 ALIAS to API Gateway)
- **Target:** the **API Gateway domain target** from step 2 (`d-….execute-api.us-west-2.amazonaws.com`)
- **Remove** old records pointing at a **manual** CloudFront distribution (`xxxx.cloudfront.net`) if you are migrating off that setup.

Lower TTL during cutover if possible. After propagation:

```bash
dig uu.spsw.io @8.8.8.8 +short
curl -sf https://uu.spsw.io/
curl -X POST "https://uu.spsw.io/form.php" -F "uu_file=@/path/to/file.jpg"
```

## 5) Verify

| Check | Expected |
|--------|----------|
| `GET /` | Plain text `UUNetworkingTestServer OK` |
| `POST /form.php` with `uu_file` | `Upload finished, result: 1` |
| `GET /download.php?uu_file=...` | Binary file (requires deployed binary Bref settings) |

Compare with the raw invoke URL if the custom hostname misbehaves:

`https://xxxx.execute-api.us-west-2.amazonaws.com/form.php`

## Troubleshooting

| Symptom | Likely cause |
|--------|----------------|
| SSL / certificate errors | Cert not in **us-west-2**, not issued, or wrong domain on custom domain |
| 404 on `/form.php` | API mapping wrong stage or path prefix |
| `dig` correct but client still old IP | Local DNS cache; flush macOS cache; restart Simulator |
| HTML **Request blocked** + CloudFront on POST | WAF still attached to a CloudFront distribution used by the hostname; allow `POST` + `multipart/form-data` to `/form.php`, or use Regional custom domain and drop old CF DNS |
| `Unable to route request: uu/...` | Redirect scripts use `/uu/...` paths; see redirect notes in app / use `/redirect.php` at repo root paths |
| Upload OK on `execute-api`, fails on custom host | DNS, WAF, or mapping — not PHP |

## macOS DNS flush (optional)

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Confirm with `dig @8.8.8.8 uu.spsw.io` before blaming local cache.

## Related docs

- `bref-serverless-from-scratch.md` — deploy, binary HTTP, Lambda limits
- `s3-static-hosting.md` — optional static assets (separate from this API hostname)
