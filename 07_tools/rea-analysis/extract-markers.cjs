// Extract structural markers from REA decompiled Compose methods.
const fs = require("fs");
const files = [
  "out-m-ForecastPage.json",
  "out-m-WeatherApp.json",
  "out-m-CityScreen.json",
  "out-m-MetricScreen.json",
  "out-m-SettingsScreen.json",
];
const marks = [
  "rememberPagerState", "HorizontalPager", "LazyColumn", "LazyRow",
  "verticalScroll", "rememberScrollState", "scrollBy", "animateScrollToPage",
  "currentPage", "InteractionSource", "pointerInput", "detectTapGestures",
  "detectDragGestures", "rememberLazyListState", "LaunchedEffect",
  "DisposableEffect", "collectAsState", "mutableStateOf", "BoxWithConstraints",
  "beyondBoundsPageCount", "ImageRequest", "AsyncImage", "Bitmap",
  "PagerState", "pageIndex", "pageCount",
];
for (const f of files) {
  const n = require("./" + f).normalized_result;
  const s = typeof n.source === "string" ? n.source : n.source.text;
  const name = f.replace(/out-m-|\.json/g, "");
  fs.writeFileSync("decompiled-" + name + ".java", s);
  console.log("==" + name + "== len", s.length);
  for (const m of marks) {
    const lit = m.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const c = (s.match(new RegExp(lit, "g")) || []).length;
    if (c) console.log("   ", m, c);
  }
}
