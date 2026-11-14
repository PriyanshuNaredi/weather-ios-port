    @Override // dev.kiankonrad.weather.MapRepository
    public Object radar(Continuation<? super RadarTimeline> continuation) {
        return BuildersKt.withContext(Dispatchers.getIO(), new AnonymousClass2(null), continuation);
    }