// Extract persistence/network markers from REA-decompiled repository methods.
const fs = require("fs");
const methods = ["cached", "write", "read", "saveCities", "get", "radar", "temperatures"];
const marks = [
  "SharedPreferences", "getSharedPreferences", "edit(", "getString(", "putString(",
  "File(", "readText", "writeText", "cacheDir", "filesDir",
  "HttpURLConnection", "URL(", "okhttp", "JSONObject", "JSONArray",
  "encodeToString", "decodeToString", "Base64", "GZIP",
  "System.currentTimeMillis", "Instant", "LocalDate",
  "Dispatchers", "withContext", "suspend", "IOException",
  "cacheKey", "experimental", "open-meteo", "openweathermap", "rainviewer",
  "maptiler", "tiles", "connectTimeout", "readTimeout", "requestMethod",
];
for (const m of methods) {
  const j = require("./out-m-OWR-" + m + ".json").normalized_result;
  const s = j.source.text;
  fs.writeFileSync("decompiled-OWR-" + m + ".java", s);
  console.log("==OWR." + m + "== len", s.length);
  for (const k of marks) {
    const lit = k.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const c = (s.match(new RegExp(lit, "g")) || []).length;
    if (c) console.log("   ", k, c);
  }
}
