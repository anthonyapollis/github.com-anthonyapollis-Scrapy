# Alea AGMS – connection test + latest rows to Excel

`Get-AleaLatest.ps1` calls `POST https://lb.aleacontrol.com/AGMS/api/Stats` with the request format Trevor sent (12 Oct 2026), prints the API's `ResponseCode`/`Message`, and saves the 10 latest rows to `alea_latest.xlsx`.

```powershell
$env:ALEA_USER = "<LoginUserName>"
$env:ALEA_PASS = "<LoginPassword>"
.\Get-AleaLatest.ps1            # last 7 days, 10 rows
.\Get-AleaLatest.ps1 -Days 1    # yesterday→today
```

Notes
- The credentials are sent both in the JSON body and as headers (`LoginUserName`, `LoginPassword`), because Alea's documentation doesn't say which one it expects.
- `ResponseCode` other than success (for example `2`, which came back in an earlier Postman call) means Alea rejected the request. Usually it's the credentials, or a group/date that has no data.
- Stats is **aggregated** (grouped by location by default). "Latest rows" means the most recent aggregated rows. Transaction-level rows need Alea's raw API, which has been requested from Trevor.
- If nothing comes back, the raw response is saved to `alea_raw.json` so you can see the actual structure.
