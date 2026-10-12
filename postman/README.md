# RavenTrack Postman automation

Self-authenticating Postman collection for the RavenTrack partner API (`https://partner.jsbsports.bet`).

## How it works
- The collection uses Bearer auth with `{{access_token}}`.
- RavenTrack access tokens last **one year**. `POST /api/oauth/refresh-token` takes the current, still-valid token as a **Bearer** header and returns a new one.
- A collection-level pre-request script runs before every request. If the token is missing or expires within 30 days, it calls the refresh endpoint and saves `access_token`, any returned `refresh_token` and `access_token_expires_at` to the environment.
- `Ping` (`GET /api/ping`) checks the connection: it expects HTTP 200 and `{"message": "pong"}`.

## Postman Desktop
1. Import `RavenTrack-Automated.postman_collection.json` and `RavenTrack.postman_environment.template.json`.
2. Select the **RavenTrack - JSB Sports** environment and paste a fresh refresh token into `refresh_token` (Current value).
3. Send **Ping**. The token refreshes on its own. To check everything at once, use **Run collection**.

To get automatic refresh on your existing `RavenTrack API [Account]` collection, copy the pre-request script from this collection into that collection's **Scripts → Pre-request** tab and set its Auth to Bearer `{{access_token}}`.

## Headless / scheduled (Newman)
```powershell
npm install -g newman
Copy-Item RavenTrack.postman_environment.template.json RavenTrack.postman_environment.local.json
# paste refresh_token into the .local.json file
.\run-raventrack.ps1
```
`--export-environment` writes the rotated tokens back to the `.local.json` file, so later runs keep working. Schedule it with Windows Task Scheduler for an unattended connection check. `*.local.json` is git-ignored so tokens never get committed.

## If refresh returns 401
The token you sent has expired (over a year old) or is invalid. A dead token cannot be refreshed. Get a new one from RavenTrack / your JSB Sports affiliate manager (or the API section of the partner portal), paste it into `refresh_token`, and clear `access_token`.
