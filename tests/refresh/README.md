# Boreholes refresh regression fixtures

`fixture-regression.sql` tests the actual PL/SQL package in an isolated Oracle schema named **BOREHOLES_TEST**. It refuses to run as GEOSCIENCE or another owner. It performs no DDL, commits, inference calls or network requests, and rolls back its fixture rows and diagnostic rows. Identity sequences can still advance during rolled-back inserts; use a disposable test schema.

Prerequisites are the current `GS_BOREHOLE_REFRESH_API`, APEX JSON/web-service APIs, and isolated copies of `GS_BOREHOLES`, `GS_BOREHOLE_SOURCES` and `GS_DATA_REFRESH_RUNS` with their required columns/constraints. Provisioning that schema is a separate authorized deployment action. Do not run the application installer on AIDEMODB as a shortcut.

Using SQLcl and a saved connection for that isolated owner:

```sql
@tests/refresh/fixture-regression.sql
```

The fixtures cover invalid BBOX/count, JSON failure results without network access, malformed or wrong-shaped GeoJSON, missing/repeated stable identifiers, valid empty collections, repeated loads, abandoned status on insert/update, row-count limits, invalid numeric/date values, atomic rollback after an earlier row update, and preservation of caller work/source refresh state. They execute the package implementation rather than duplicate its parser or transaction logic. Nonblank source dates require a valid `YYYY-MM-DD` date portion; unknown values should be JSON null or blank, not undocumented sentinel strings.

The loader keeps public signatures unchanged. `load_geojson_clob` still returns a run ID on success and raises on failure. Failure diagnostics remain in the **caller transaction**, so a direct caller must catch the exception and choose its transaction outcome; an unhandled statement error or caller rollback can also discard diagnostics. There are no autonomous transactions or hidden commits. `rows_rejected` counts the first row that caused an atomic batch failure (zero for a response/envelope failure); `rows_loaded` is zero on any failed batch.

`remote_refresh_json` returns `success`, `refreshRunId`, `requestUrl`, `rowsLoaded`, `rowsRejected`, `emptyResult`, `httpStatus`, `errorCode`, `responseCharacters`, `transferTimeoutSeconds`, `timingMs.download/load/total`, and `message` (nullable values may be omitted). An invalid request is rejected before creating an attempt or contacting WFS. A valid empty `FeatureCollection` succeeds and leaves existing boreholes unchanged. A run is created before network access for a valid request; HTTP, load or response-serialization failure rolls back business changes and changes it to FAILED. Detailed Oracle errors stay in that run record; the browser receives a classified message and run number. The existing `RESPONSE_BYTES` column retains its historical CLOB-character meaning, while JSON explicitly names `responseCharacters`.

Before deployment acceptance, compile and run these fixtures in the isolated schema, then use an approved controlled HTTP test path to verify non-2xx, timeout, oversized response and valid remote empty/non-empty responses. The current offline fixtures do not simulate HTTP or prove compilation. The explicit 30-second transfer timeout bounds waiting for the WFS response, not total browser-to-database processing; payload size is capped after download at 30 million characters before parsing. No package replacement or live failure injection is authorized by this test document.
