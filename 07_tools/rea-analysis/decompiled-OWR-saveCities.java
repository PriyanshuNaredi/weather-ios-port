    @Override // dev.kiankonrad.weather.WeatherRepository
    public void saveCities(List<City> cities) {
        Intrinsics.checkNotNullParameter(cities, "cities");
        HashSet hashSet = new HashSet();
        ArrayList arrayList = new ArrayList();
        for (Object obj : cities) {
            if (hashSet.add(((City) obj).getId())) {
                arrayList.add(obj);
            }
        }
        SharedPreferences.Editor editorEdit = this.preferences.edit();
        JSONArray jSONArray = new JSONArray();
        ArrayList arrayList2 = arrayList;
        Iterator it = arrayList2.iterator();
        while (it.hasNext()) {
            jSONArray.put(DataCodec.INSTANCE.cityJson((City) it.next()));
        }
        Unit unit = Unit.INSTANCE;
        editorEdit.putString("cities", jSONArray.toString()).apply();
        ArrayList arrayList3 = new ArrayList(CollectionsKt.collectionSizeOrDefault(arrayList2, 10));
        Iterator it2 = arrayList2.iterator();
        while (it2.hasNext()) {
            arrayList3.add("forecast-" + cacheKey((City) it2.next()) + ".json");
        }
        Set set = CollectionsKt.toSet(arrayList3);
        File[] fileArrListFiles = this.directory.listFiles(new FileFilter() { // from class: dev.kiankonrad.weather.OpenWeatherRepository$$ExternalSyntheticLambda0
            @Override // java.io.FileFilter
            public final boolean accept(File file) {
                return OpenWeatherRepository.saveCities$lambda$3(file);
            }
        });
        if (fileArrListFiles != null) {
            ArrayList arrayList4 = new ArrayList();
            for (File file : fileArrListFiles) {
                if (!set.contains(file.getName())) {
                    arrayList4.add(file);
                }
            }
            Iterator it3 = arrayList4.iterator();
            while (it3.hasNext()) {
                ((File) it3.next()).delete();
            }
        }
    }