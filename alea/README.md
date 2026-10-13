# Alea AGMS

```
alea/
  postman/   Alea-AGMS.postman_collection.json, Alea.postman_environment.template.json
  scripts/   Get-AleaLatest.ps1  (connection test + 10 latest rows to Excel)
```

**Endpoint:** `POST https://lb.aleacontrol.com/AGMS/api/Stats`. The request format comes from Trevor's email of 12 Oct 2026.

**Status (13 Oct 2026 16:31 UTC, verified):** login via `/AGMS/token` → HTTP 200 with a Bearer token. `/api/Stats` for today with **groups = null** → HTTP 200, `ResponseCode 0`, 35 location rows. Without a token, Stats returns `ResponseCode 2`. Alea always answers HTTP 200, so `ResponseCode` is the real check.

**Leave the group filter empty.** The group GUID from Trevor's email (`{609f0dd2-…}`) returns `ResponseCode 0` with `"No locations available for Geo slice"` and no rows.

## Authentication (found 13 Oct 2026)
Alea's `/api/Stats` answers with `WWW-Authenticate: Bearer`. Its login endpoint is a standard password grant:
```
POST https://lb.aleacontrol.com/AGMS/token
Content-Type: application/x-www-form-urlencoded

grant_type=password&userName=<Alea login>&password=<Alea password>
→ { "access_token": "...", "expires_in": ... }
```
Then call Stats with `Authorization: Bearer <access_token>`. Use the same username and password you use on the GMS portal. If `/token` rejects them, ask Alea to enable API access for that user.

`ALEA_GROUP_ID` / `alea_group_id` is **optional**. Leave it empty to get all groups your login can see, or set it to the group GUID from Trevor's 12 Oct email (`{609f0dd2-…}`) to filter to that group.

## Postman
1. Import both files from `postman/` and select **Alea - JSB Sports**.
2. Fill in `alea_username` and `alea_password` in **Current value** only. The collection fetches the token automatically.
3. Send **Stats - today**. The tests check HTTP 200, `ResponseCode != 2`, and that rows came back. **Visualize** shows the 10 latest rows.

## Excel
```powershell
Copy-Item ..\.env.example ..\.env   # fill in ALEA_USER, ALEA_PASS (ALEA_GROUP_ID optional)
.\scripts\Get-AleaLatest.ps1        # today -> scripts\alea_latest.xlsx
```
The script stops with a clear message on `ResponseCode 2`. It runs on Windows PowerShell 5.1 and PowerShell 7.

## Notes
- Today is sent as `StartDate` = today, `EndDate` = tomorrow (Trevor's one-day sample used 07 → 08).
- Stats returns totals (per location by default). For individual transactions, ask Alea for its raw transaction API.
- Codex's check-only script lives in `anthonyapollis/alea-raventrack-api-automation` (`scripts/Test-AleaConnection.ps1`). It uses the same `.env` keys.
