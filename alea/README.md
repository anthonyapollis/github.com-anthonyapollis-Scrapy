# Alea AGMS

```
alea/
  postman/   Alea-AGMS.postman_collection.json, Alea.postman_environment.template.json
  scripts/   Get-AleaLatest.ps1  (connection test + 10 latest rows to Excel)
```

**Endpoint:** `POST https://lb.aleacontrol.com/AGMS/api/Stats`. The request format comes from Trevor's email of 12 Oct 2026.

**Status:** the server is reachable. It returns HTTP 200 but with `ResponseCode: 2`, which means the login was not accepted. Alea always answers HTTP 200, so check `ResponseCode` in the response body: `2` means not authenticated.

## Postman
1. Import both files from `postman/` and select **Alea - JSB Sports**.
2. Fill `alea_username` / `alea_password` in **Current value** only, so they stay on your PC.
3. Send **Stats - today**. The tests check HTTP 200, `ResponseCode != 2` and that rows came back. The **Visualize** tab shows the 10 latest rows as a table.
4. `days_back` = 0 means today only. Set it to 7 for the last week.

## Excel
```powershell
$env:ALEA_USER = "<LoginUserName>"; $env:ALEA_PASS = "<LoginPassword>"
.\scripts\Get-AleaLatest.ps1        # today -> alea_latest.xlsx
```

## Notes
- The login is sent both in the JSON body and as headers, because Alea hasn't documented which one it expects. If `ResponseCode` is still 2 with credentials you know are correct, ask Alea or Trevor how the API authenticates. A web-portal login may not be enabled for API access.
- Today: `StartDate` = today, `EndDate` = tomorrow. Trevor's one-day sample used 07 → 08, so EndDate looks exclusive.
- Stats returns totals (per location by default). For individual transactions, ask Alea for its raw transaction API.
