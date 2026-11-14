    @Override // dev.kiankonrad.weather.MapRepository
    public Object temperatures(double d, double d2, double d3, double d4, Continuation<? super TemperatureGrid> continuation) {
        return BuildersKt.withContext(Dispatchers.getIO(), new AnonymousClass2(d, d2, d3, d4, this, null), continuation);
    }