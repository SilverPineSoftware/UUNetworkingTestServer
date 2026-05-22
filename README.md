# UUNetworkingTestServer

A simple PHP REST server for integration tests with UU networking components.

## Local PHP server

```bash
./scripts/start_local.sh
./scripts/stop_local.sh
```

Or manually:

```bash
php -S 127.0.0.1:8080 -t php php/index.php
```

Uploads use `/tmp/uu-upload` unless `UU_FILE_FOLDER` is set.

- Health: `http://127.0.0.1:8080/`
- Standalone scripts: `http://127.0.0.1:8080/form.php`, `echo_json.php`, etc.
- Routed APIs: `http://127.0.0.1:8080/echo/json` (same as `?do=echo/json`)

The built-in server and Lambda **do not** use `php/.htaccess` (Apache only). Routing is in `index.php` and `common.php`.

For iOS Simulator tests, set `test_server_api_host` in `UUNetworkingTestConfig.plist` to `http://127.0.0.1:8080`.

## Deploy to AWS (Bref + Serverless)

Prereqs: AWS CLI credentials, PHP + Composer, Node (`npx`).

```bash
./scripts/deploy_lambda.sh
```

Defaults: stage `prod`, region `us-west-2`. Or:

```bash
composer install --no-dev
npx serverless@3 deploy
```

After deploy, note the **HTTP API invoke URL** (e.g. `https://xxxx.execute-api.us-west-2.amazonaws.com`). Use it to verify before/custom domain DNS:

```bash
curl -sf "https://xxxx.execute-api.us-west-2.amazonaws.com/"
# UUNetworkingTestServer OK
```

See `docs/bref-serverless-from-scratch.md` for full setup and troubleshooting (binary uploads/downloads, PHP version, etc.).

`serverless.yml` already enables Bref binary HTTP (`binaryMediaTypes`, `BREF_BINARY_RESPONSES`) for `form.php` and `download.php`.

## Custom domain (`uu.spsw.io`)

Production hostname points **directly at API Gateway** (HTTP API custom domain → Lambda). There is **no** separate CloudFront distribution in front of the PHP API.

1. **ACM certificate** in **us-west-2** (same region as `serverless.yml`) for `uu.spsw.io`, DNS-validated.
2. **API Gateway → Custom domain names** → create `uu.spsw.io` (prefer **Regional** endpoint), attach the cert.
3. **API mappings** → map the domain to your HTTP API, stage **`$default`**, empty path (so `/form.php` stays `/form.php`).
4. **DNS** → CNAME `uu` to the API Gateway domain target (e.g. `d-xxxxx.execute-api.us-west-2.amazonaws.com` from the console).

Details and troubleshooting: **`docs/custom-domain-api-gateway.md`**.

iOS / integration tests: `test_server_api_host` = `https://uu.spsw.io`.

**Note:** API Gateway may still add CloudFront-related response headers on some custom-domain configurations; that is AWS-managed, not your old manual CloudFront setup. If `POST /form.php` fails with HTML “Request blocked”, check WAF on any distribution still associated with the hostname, or test against the raw `execute-api` URL to isolate Lambda vs edge.
