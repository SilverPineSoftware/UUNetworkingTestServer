# Custom domain → CloudFront → API Gateway (HTTP API) → Lambda

This project deploys **API Gateway HTTP API → Lambda** (Bref PHP-FPM). To serve it on a friendly hostname (for example `uu-networking.example.com`), use:

1. **ACM certificate (us-east-1)** for that hostname — required for CloudFront custom TLS.
2. **CloudFront** with origin = your HTTP API **`execute-api`** URL from Serverless deploy.
3. **DNS** (GoDaddy, Route 53, etc.) — **CNAME** from your hostname to the CloudFront distribution.

See also: `bref-serverless-from-scratch.md` for the initial Lambda + Serverless deploy.

## Prerequisites

- Serverless deploy succeeds and you can reach the **HTTP API invoke URL** (for example `https://xxxx.execute-api.us-west-2.amazonaws.com`). The region should match `provider.region` in `serverless.yml` (this repo defaults to **us-west-2**).
- You can create DNS records for your domain.

## 1) Deploy and copy the HTTP API invoke URL

Deploy (for example `npx serverless@3 deploy` or `./scripts/deploy_lambda.sh`) and copy the **HTTP API** URL from the output:

- `https://xxxx.execute-api.us-west-2.amazonaws.com`

Use this as the **CloudFront origin domain** (no path suffix unless you intentionally deploy behind a fixed stage prefix).

## 2) Request an ACM certificate in us-east-1 (required for CloudFront)

In **AWS Certificate Manager**:

- Switch region to **US East (N. Virginia) (`us-east-1`)** — CloudFront only uses ACM certs from this region for alternate domain names.
- Request a **public** certificate.
- Add the hostname you want (for example `uu-networking.example.com`), or a wildcard such as `*.example.com` if you will reuse it.
- Choose **DNS validation**.

ACM will show one or more **CNAME** records for validation.

### DNS validation records

Create the validation CNAME(s) at your DNS provider **exactly** as ACM specifies. Naming varies by provider:

- Some UIs want the **full** record name; others want only the **left label** relative to the zone (for example `_xmmyhost.example.com` → Host = `_xmmyhost` when the zone is `example.com`).

Wait until ACM shows the certificate status as **Issued**.

## 3) Create a CloudFront distribution

In **CloudFront**, create a distribution.

### Origin

- **Origin domain**: the `xxxx.execute-api.….amazonaws.com` hostname from step 1 (paste the hostname only, not the full request path).
- If the console offers “API Gateway” vs “custom origin”: either can work if the domain and HTTPS settings match; the important part is the correct **execute-api** host.
- **Origin protocol policy**: **HTTPS only**.
- **Origin path**: leave **empty** unless every request must be prefixed with a path (unusual for this app).

### Default cache behavior

This PHP test server is dynamic; caching often causes stale or wrong responses. Recommended:

- **Viewer protocol policy**: **Redirect HTTP to HTTPS**
- **Allowed HTTP methods**: include **POST** (choosing **All** is the simplest safe option for mixed GET/POST tests).
- **Cache policy**: **CachingDisabled** (managed: *CachingDisabled*).
- **Origin request policy**: forward what clients send
  - A practical default: **AllViewerExceptHostHeader** (forwards headers, cookies, query strings; avoids overwriting the Host header your API Gateway expects).

### Alternate domain names (CNAMEs) and TLS

Under the distribution general settings:

- **Alternate domain name (CNAME)**: your chosen hostname (for example `uu-networking.example.com`).
- **Custom SSL certificate**: the ACM certificate from **us-east-1** created in step 2.

Create the distribution and wait until status is **Deployed**.

## 4) Point your hostname at CloudFront

At your DNS provider, add a **CNAME**:

- **Name / Host**: your subdomain label (for example `uu-networking` for `uu-networking.example.com`; use `@` or provider-specific syntax for apex if you must — apex often uses **ALIAS** to CloudFront on Route 53 instead of CNAME).
- **Target / Points to**: the CloudFront domain (for example `d1111abcd.cloudfront.net`).

Remove conflicting records for the same name (duplicate CNAME, conflicting A/AAAA).

DNS propagation can take minutes to hours.

## 5) Verify

- Open `https://your-hostname/` — you should see the same plain-text health response as hitting the raw `execute-api` base URL (this app returns `UUNetworkingTestServer OK` at `/`).
- Exercise a routed path (for example `GET /echo/json` or `GET /test/single`).
- Confirm **POST** where your tests need it (for example JSON echo routes), with no **403** / **405**.

## Troubleshooting

| Symptom | Likely cause |
|--------|----------------|
| **403** from CloudFront | Alternate domain name not listed on the distribution, wrong cert, wrong region for cert (must be **us-east-1**), or DNS not pointing at this distribution yet. |
| **POST** fails or **405** | CloudFront behavior does not allow POST; widen **Allowed HTTP methods**. |
| Stale or wrong JSON/body | **Caching** still enabled; use **CachingDisabled** and an origin request policy that forwards query strings and headers your client sends. |
| Works on `execute-api` but not custom host | Wrong origin host, or Host header / API mapping issue — double-check origin domain and origin request policy. |
