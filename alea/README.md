# Alea AGMS

```
alea/
  postman/   Alea-AGMS.postman_collection.json, Alea.postman_environment.template.json
  scripts/   Get-AleaLatest.ps1  (connection test + 10 latest rows to Excel)
```

**Endpoint:** `POST https://lb.aleacontrol.com/AGMS/api/Stats`. The request format comes from Trevor's email of 12 Oct 2026.

**Status (13 Oct 2026, verified by Codex):** the server is reachable and returns HTTP 200 with `{"ResponseCode":2,"Message":""}`. That means the request was **not authenticated**. Alea always answers HTTP 200, so `ResponseCode` is the real check.

## What's still missing: Alea's API authentication method
Your browser login does **not** log Postman or a script in. Ask Alea or Trevor which method the API supports, then fill in the matching setting:

| Method | `.env` | Postman variable |
|---|---|---|
| Token / API key in a header | `ALEA_AUTHORIZATION` | `alea_authorization` |
| Approved session cookie | `ALEA_COOKIE` | `alea_cookie` |
| LoginUserName / LoginPassword | `ALEA_USER`, `ALEA_PASS` | `alea_username`, `alea_password` (tick those two headers) |

`ALEA_GROUP_ID` / `alea_group_id` holds the group GUID from Trevor's email. It's kept out of the code.

## Postman
1. Import both files from `postman/` and select **Alea - JSB Sports**.
2. Fill in `alea_group_id` and your auth value in **Current value** only. In the request, untick the auth headers you aren't using.
3. Send **Stats - today**. The tests check HTTP 200, `ResponseCode != 2`, and that rows came back. **Visualize** shows the 10 latest rows.

## Excel
```powershell
Copy-Item ..\.env.example ..\.env   # fill in ALEA_GROUP_ID + auth
.\scripts\Get-AleaLatest.ps1        # today -> scripts\alea_latest.xlsx
```
The script stops with a clear message on `ResponseCode 2`. It runs on Windows PowerShell 5.1 and PowerShell 7.

## Notes
- Today is sent as `StartDate` = today, `EndDate` = tomorrow (Trevor's one-day sample used 07 → 08).
- Stats returns totals (per location by default). For individual transactions, ask Alea for its raw transaction API.
- Codex's check-only script lives in `anthonyapollis/alea-raventrack-api-automation` (`scripts/Test-AleaConnection.ps1`). It uses the same `.env` keys.
