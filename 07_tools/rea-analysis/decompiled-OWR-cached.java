    @Override // dev.kiankonrad.weather.WeatherRepository
    public Weather cached(City city) {
        Object objM8871constructorimpl;
        Intrinsics.checkNotNullParameter(city, "city");
        try {
            Result.Companion companion = Result.INSTANCE;
            OpenWeatherRepository openWeatherRepository = this;
            String str = read("forecast-" + cacheKey(city) + ".json");
            if (str == null) {
                return null;
            }
            objM8871constructorimpl = Result.m8871constructorimpl(DataCodec.INSTANCE.cachedForecast(new JSONObject(str), city));
        } catch (Throwable th) {
            Result.Companion companion2 = Result.INSTANCE;
            objM8871constructorimpl = Result.m8871constructorimpl(ResultKt.createFailure(th));
        }
        return (Weather) (Result.m8877isFailureimpl(objM8871constructorimpl) ? null : objM8871constructorimpl);
    }