# API connections

Each data source has its own folder with its Postman collection, environment template and scripts.

| Folder | Source | Status |
|---|---|---|
| [`alea/`](alea/) | Alea AGMS Stats API | Server reachable; login rejected (`ResponseCode 2`) |
| [`raventrack/`](raventrack/) | RavenTrack partner API (`partner.jsbsports.bet`) | Server reachable; token rejected (401). Generate a new token in the RavenTrack account |

Credentials never go in this repo. Use Postman **Current values** or environment variables. Files matching `*.local.json` are git-ignored.
