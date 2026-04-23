# PHP on AWS Lambda with Bref + Serverless Framework (from scratch)

This guide walks through converting a PHP application (like the scripts under `php/` in this repo) into an **API Gateway HTTP API → Lambda** deployment using **[Bref](https://bref.sh/)** and the **[Serverless Framework](https://www.serverless.com/)**.

It mirrors the setup used in `directkey.spsw.io` (Bref PHP-FPM layer, Serverless v3, `provided.al2` runtime).

---

## What you get

- **HTTP API** (API Gateway v2) exposes `GET`/`POST`/etc. to your PHP code.
- **Lambda** runs PHP via Bref’s **PHP-FPM** layer (good fit for traditional `$_GET` / `$_POST` / `php://input` style apps).
- **Serverless Framework** packages your code + `vendor/` and deploys CloudFormation stacks.

---

## Prerequisites

Install on your machine:

| Tool | Purpose |
|------|---------|
| **AWS CLI** (`aws`) | Credentials and optional default region/profile |
| **PHP** (same major as Lambda, e.g. 8.2) | Local `composer` and sanity checks |
| **Composer** | PHP dependencies (`bref/bref`, autoload) |
| **Node.js** | `npx serverless@3 deploy` |

Configure AWS credentials (for example `aws configure` or env vars / SSO). You need permission to create/update Lambda, IAM roles, API Gateway, CloudWatch Logs, etc.

---

## Step 1 — Create or reuse a project folder

Put your PHP sources in a dedicated directory (the reference project uses `src/`). For this repo you might later move or copy `php/*.php` into `src/` (or keep `php/` and point `handler` at the front controller—see Step 5).

---

## Step 2 — Add Composer and Bref

From the project root:

```bash
composer init
```

Then require Bref (versions align with [Bref docs](https://bref.sh/docs/) for your PHP version):

```bash
composer require bref/bref:^2.4
```

**Pin the PHP platform** so local Composer resolves dependencies for the same runtime Lambda uses (example for PHP 8.2):

```json
"config": {
  "platform": {
    "php": "8.2.0"
  }
}
```

Run:

```bash
composer install --no-dev
```

This creates `vendor/` including the Serverless plugin at `vendor/bref/bref`.

---

## Step 3 — Add `serverless.yml`

Create `serverless.yml` at the repo root. Minimal pattern (adapt `service`, `region`, `stage`, PHP layer, and handler path):

```yaml
service: my-php-service

frameworkVersion: '3'

provider:
  name: aws
  region: us-west-2
  runtime: provided.al2
  stage: prod

plugins:
  - ./vendor/bref/bref

functions:
  web:
    description: PHP web (Bref)
    handler: src/index.php
    timeout: 28
    memorySize: 512
    layers:
      - ${bref:layer.php-82-fpm}
    events:
      - httpApi:
          path: /
          method: '*'
      - httpApi:
          path: /{proxy+}
          method: '*'

package:
  patterns:
    - '!docs/**'
    - '!scripts/**'
    - '!**/.DS_Store'
```

**Important details:**

- **`runtime: provided.al2`** — required for Bref layers on Amazon Linux 2.
- **`handler`** — path to **one PHP file** that acts as the web entrypoint (front controller). Bref’s FPM integration runs this file for HTTP requests.
- **`${bref:layer.php-82-fpm}`** — must match your target PHP version (Bref provides `php-81-fpm`, `php-82-fpm`, `php-83-fpm`, etc.).
- **`httpApi` + `/{proxy+}`** — forwards all paths to the same Lambda (your router handles routing).

Tune **`timeout`** (max 29s on API Gateway unless you use Lambda Function URL / ALB with different limits) and **`memorySize`** as needed.

---

## Step 4 — Front controller / handler file

The **handler** must bootstrap your app: `require` autoload/common files, then run your router.

Reference pattern (`directkey.spsw.io`):

- **`src/dkf.php`** — registered as `handler` in `serverless.yml`; contains the real app bootstrap.
- **`src/index.php`** — optional; only `require`s the handler so **local** `php -S 127.0.0.1:8080 -t src` serves `/` correctly. Lambda still uses whichever file you set as `handler`.

For apps that today use **`index.php` + query string routing** (e.g. `?do=echo/method`), you usually **keep that file as the handler** or add a thin `src/index.php` that includes your existing `index.php`.

**Path and URL considerations on Lambda:**

- API Gateway may inject a **stage prefix** (e.g. `/prod/...`) unless you map a custom domain + route `/$default`. Build links with relative URLs or derive the public base URL from configuration when needed.
- Prefer **relative** asset and form URLs where possible.

---

## Step 5 — Wire your existing PHP into `src/` (conceptual)

1. Copy or symlink your PHP tree under `src/` (or keep a single `handler` that `chdir`s / `require`s `../php/...`—less clean but works for a quick test).
2. Ensure **all `require_once` paths** still resolve (use `__DIR__` for portability).
3. Replace or abstract any **server-specific** `.htaccess` rules: Lambda has no Apache; routing is “always to handler,” so path-based routing must happen in PHP (or API Gateway routing with multiple functions—usually unnecessary for one app).

---

## Step 6 — `.gitignore`

Typical entries:

```
/vendor/
/.serverless/
.env
.DS_Store
```

Commit `composer.json` and `composer.lock`. Do not commit `vendor/` if you install in CI from lockfile (optional: commit `vendor/` for simplicity—reference project gitignores `vendor/`).

---

## Step 7 — Deploy

```bash
composer install --no-dev
npx serverless@3 deploy
```

Or pin stage/region:

```bash
npx serverless@3 deploy --stage prod --region us-west-2
```

Copy the **`https://....execute-api....amazonaws.com`** URL from the output—that is your API base URL.

**Inspect deployed endpoints:**

```bash
npx serverless@3 info --verbose --stage prod --region us-west-2
```

---

## Step 8 — Automate deploy (optional)

A small wrapper script (like `scripts/deploy_lambda.sh` in `directkey.spsw.io`) typically:

1. `cd` to repo root  
2. `composer install --no-dev --prefer-dist --no-interaction`  
3. `npx --yes serverless@3 deploy --stage "$STAGE" --region "$REGION"`  
4. Optionally `serverless info --verbose` for URLs  

Export **`AWS_PROFILE`**, **`AWS_REGION`**, **`STAGE`**, **`REGION`** as needed.

---

## Troubleshooting

### Composer says PHP version mismatch vs Lambda

If dependencies require PHP **newer** than your layer (e.g. lockfile wants 8.4 but Lambda is 8.2), align **`config.platform.php`** with the layer, then:

```bash
composer update
```

Redeploy after `composer.lock` matches the Lambda runtime.

### Wrong “handler” or 502 from API Gateway

- Confirm **`handler`** path matches an existing file in the deployment package.
- Confirm **`layers`** PHP version matches what you built against.

### Missing extensions

Declare extensions in `composer.json` (e.g. `"ext-curl": "*"`) so Composer fails fast locally; pick a Lambda layer / runtime that includes those extensions (Bref documents included extensions).

### Large package

Use `package.patterns` in `serverless.yml` to exclude `docs/`, tests, dev assets, and anything not needed at runtime.

---

## Optional: custom domain / CloudFront

HTTPS custom domains usually use **API Gateway custom domain**, **ACM certificate**, and often **CloudFront** in front. That is orthogonal to Bref; the API’s `execute-api` URL is enough for integration testing.

---

## Quick checklist

- [ ] `composer require bref/bref` and platform PHP version set  
- [ ] `serverless.yml` with `provided.al2`, Bref plugin, FPM layer, `httpApi` catch-all  
- [ ] Single PHP **handler** file bootstrapping your app  
- [ ] `composer install --no-dev` then `npx serverless@3 deploy`  
- [ ] Hit the `execute-api` URL and verify routing and POST bodies  

---

## Reference project layout (`directkey.spsw.io`)

| File / directory | Role |
|------------------|------|
| `composer.json` | `bref/bref`, PHP platform pin |
| `serverless.yml` | Serverless + Bref layers, HTTP API events |
| `src/dkf.php` | Lambda **handler** (main entry) |
| `src/index.php` | Local dev only: includes `dkf.php` |
| `scripts/deploy_lambda.sh` | Optional deploy script |

Use that tree as a template when redoing the setup in a new folder.
