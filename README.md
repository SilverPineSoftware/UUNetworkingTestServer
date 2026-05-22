# UUNetworkingTestServer
A simple PHP REST server for integration tests with UU networking components.

## Local PHP server
```bash
./scripts/start_local.sh
./scripts/stop_local.sh   # stop background or orphaned server
```

Or manually: `php -S 127.0.0.1:8080 -t php php/index.php` (uploads go to `/tmp/uu-upload` unless `UU_FILE_FOLDER` is set).

Use `http://127.0.0.1:8080/` (root returns a short health line). REST routes match Apache-style paths, e.g. `http://127.0.0.1:8080/echo/json`. Query form `?do=echo/json` still works. For iOS Simulator tests, set `test_server_api_host` in `UUNetworkingTestConfig.plist` to `http://127.0.0.1:8080`.

## Deploy to AWS (Bref + Serverless Framework)
Requires AWS CLI credentials, Composer, and Node (`npx`).

```bash
composer install --no-dev
npx serverless@3 deploy
```

Or `./scripts/deploy_lambda.sh` (defaults: stage `prod`, region `us-west-2`). See `docs/bref-serverless-from-scratch.md` for details.

## Static files on S3 (zips, `.well-known`)

Put assets under **`static-public/`**, create a bucket once with **`scripts/setup_s3_static_bucket.sh`**, then **`scripts/sync_static_to_s3.sh`**. Serve them via CloudFront (OAC), not Lambda — see **`docs/s3-static-hosting.md`**.
