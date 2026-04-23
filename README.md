# UUNetworkingTestServer
A simple PHP REST server for integration tests with UU networking components.

## Local PHP server
```bash
php -S 127.0.0.1:8080 -t php
```
Use `http://127.0.0.1:8080/` (root returns a short health line). REST routes match Apache-style paths, e.g. `http://127.0.0.1:8080/echo/json`. Query form `?do=echo/json` still works.

## Deploy to AWS (Bref + Serverless Framework)
Requires AWS CLI credentials, Composer, and Node (`npx`).

```bash
composer install --no-dev
npx serverless@3 deploy
```

Or `./scripts/deploy_lambda.sh` (defaults: stage `prod`, region `us-west-2`). See `docs/bref-serverless-from-scratch.md` for details.
