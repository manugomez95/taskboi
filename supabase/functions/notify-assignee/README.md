# Secure notify-assignee deployment

`notify-assignee` is exclusively a Supabase Database Webhook target. It does not
accept a user JWT as proof that a request came from the database. The function
authenticates `x-taskboi-webhook-secret` against the `DATABASE_WEBHOOK_SECRET`
Edge Function secret before parsing or querying event data.

## Configure

1. Generate a high-entropy value (at least 32 random bytes) in a secret manager.
   Never put it in source control, SQL migrations, webhook URLs, or logs.
2. Set it as an Edge Function secret:

   ```sh
   supabase secrets set DATABASE_WEBHOOK_SECRET='value-from-your-secret-manager'
   ```

3. Deploy with the checked-in configuration (`verify_jwt = false` is required
   because the database webhook uses its own secret, not a Supabase user JWT):

   ```sh
   supabase functions deploy notify-assignee --no-verify-jwt
   ```

4. In **Database > Webhooks**, create INSERT and UPDATE events for
   `public.tasks`. Set the URL to the deployed `notify-assignee` function and
   add the HTTP header `x-taskboi-webhook-secret` with the exact same secret. Do
   not use an `Authorization` user token. Rotate both copies together; requests
   using an old/mismatched value fail closed with 401.

The service-role key remains an automatically provided server-side Edge Function
secret and must never be copied into the webhook configuration. Outbound agent
URLs must be HTTPS on port 443, without credentials, and must resolve
exclusively to public addresses. Redirect targets are subject to the same policy
and delivery connects to the already-validated DNS address.

## Test

From the repository root (Deno 2.x):

```sh
deno test --allow-net supabase/functions/notify-assignee/notify_assignee_test.ts
deno check supabase/functions/notify-assignee/index.ts
```

The tests use injected transports and do not make network requests;
`--allow-net` permits the production module's DNS/network APIs during type
analysis.
