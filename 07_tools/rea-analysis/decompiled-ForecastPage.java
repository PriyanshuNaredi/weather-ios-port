    private static final void ForecastPage(final City city, final WeatherRepository weatherRepository, final boolean z, final long j, final boolean z2, final Function1<? super Weather, Unit> function1, final Function2<? super Weather, ? super Metric, Unit> function2, final Function0<Unit> function0, Composer composer, final int i) {
        int i2;
        Composer composer2;
        final MutableIntState mutableIntState;
        String str;
        MutableState mutableState;
        MutableState mutableState2;
        int i3;
        MainActivityKt$ForecastPage$2$1 mainActivityKt$ForecastPage$2$1;
        Composer composerStartRestartGroup = composer.startRestartGroup(-978950189);
        ComposerKt.sourceInformation(composerStartRestartGroup, "C(ForecastPage)N(city,repository,imperial,now,showMapPreview,onWeather,onMetric,onMap)166@9102L7,167@9171L7,168@9255L7,169@9307L59,170@9386L41,171@9442L49,172@9505L31,173@9599L7,174@9639L29,175@9706L293,175@9670L329,179@10059L496,179@10001L554,189@10591L115,189@10557L149,194@10759L8,194@10801L7180,194@10708L7273:MainActivity.kt#uf01hx");
        if ((i & 6) == 0) {
            i2 = (composerStartRestartGroup.changed(city) ? 4 : 2) | i;
        } else {
            i2 = i;
        }
        if ((i & 48) == 0) {
            i2 |= (i & 64) == 0 ? composerStartRestartGroup.changed(weatherRepository) : composerStartRestartGroup.changedInstance(weatherRepository) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i2 |= composerStartRestartGroup.changed(z) ? 256 : 128;
        }
        if ((i & 3072) == 0) {
            i2 |= composerStartRestartGroup.changed(j) ? 2048 : 1024;
        }
        if ((i & 24576) == 0) {
            i2 |= composerStartRestartGroup.changed(z2) ? 16384 : 8192;
        }
        if ((196608 & i) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function1) ? 131072 : 65536;
        }
        if ((i & 1572864) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function2) ? 1048576 : 524288;
        }
        if ((12582912 & i) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function0) ? 8388608 : 4194304;
        }
        if (!composerStartRestartGroup.shouldExecute((i2 & 4793491) != 4793490, i2 & 1)) {
            composer2 = composerStartRestartGroup;
            composer2.skipToGroupEnd();
        } else {
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventStart(-978950189, i2, -1, "dev.kiankonrad.weather.ForecastPage (MainActivity.kt:165)");
            }
            ProvidableCompositionLocal<Context> localContext = AndroidCompositionLocals_androidKt.getLocalContext();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume = composerStartRestartGroup.consume(localContext);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            final Context context = (Context) objConsume;
            ProvidableCompositionLocal<Configuration> localConfiguration = AndroidCompositionLocals_androidKt.getLocalConfiguration();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume2 = composerStartRestartGroup.consume(localConfiguration);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            boolean z3 = ((Configuration) objConsume2).screenHeightDp < 500;
            ProvidableCompositionLocal<Density> localDensity = CompositionLocalsKt.getLocalDensity();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume3 = composerStartRestartGroup.consume(localDensity);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            final float fCoerceAtLeast = RangesKt.coerceAtLeast(((Density) objConsume3).getFontScale(), 1.0f);
            String id = city.getId();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173280114, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChanged = composerStartRestartGroup.changed(id);
            Object objRememberedValue = composerStartRestartGroup.rememberedValue();
            if (zChanged || objRememberedValue == Composer.INSTANCE.getEmpty()) {
                objRememberedValue = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(weatherRepository.cached(city), null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue);
            }
            MutableState mutableState3 = (MutableState) objRememberedValue;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            String id2 = city.getId();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173277604, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChanged2 = composerStartRestartGroup.changed(id2);
            Object objRememberedValue2 = composerStartRestartGroup.rememberedValue();
            if (zChanged2 || objRememberedValue2 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue2 = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(false, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue2);
            }
            final MutableState mutableState4 = (MutableState) objRememberedValue2;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            String id3 = city.getId();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173275804, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChanged3 = composerStartRestartGroup.changed(id3);
            Object objRememberedValue3 = composerStartRestartGroup.rememberedValue();
            if (zChanged3 || objRememberedValue3 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue3 = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(null, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue3);
            }
            MutableState mutableState5 = (MutableState) objRememberedValue3;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173273806, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue4 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue4 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue4 = SnapshotIntStateKt.mutableIntStateOf(0);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue4);
            }
            final MutableIntState mutableIntState2 = (MutableIntState) objRememberedValue4;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ProvidableCompositionLocal<LifecycleOwner> localLifecycleOwner = LocalLifecycleOwnerKt.getLocalLifecycleOwner();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume4 = composerStartRestartGroup.consume(localLifecycleOwner);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            final Lifecycle lifecycle = ((LifecycleOwner) objConsume4).getLifecycle();
            final State stateRememberUpdatedState = SnapshotStateKt.rememberUpdatedState(ForecastPage$lambda$1(mutableState3), composerStartRestartGroup, Weather.$stable);
            String id4 = city.getId();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173267112, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChanged4 = composerStartRestartGroup.changed(stateRememberUpdatedState) | composerStartRestartGroup.changedInstance(lifecycle);
            Object objRememberedValue5 = composerStartRestartGroup.rememberedValue();
            if (zChanged4 || objRememberedValue5 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue5 = new Function1() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda68
                    @Override // kotlin.jvm.functions.Function1
                    public final Object invoke(Object obj) {
                        return MainActivityKt.ForecastPage$lambda$13$0(lifecycle, stateRememberUpdatedState, mutableIntState2, (DisposableEffectScope) obj);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue5);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            EffectsKt.DisposableEffect(lifecycle, id4, (Function1) objRememberedValue5, composerStartRestartGroup, 0);
            Object[] objArr = {city.getId(), Double.valueOf(city.getLatitude()), Double.valueOf(city.getLongitude()), Integer.valueOf(ForecastPage$lambda$10(mutableIntState2))};
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173255613, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChanged5 = ((i2 & 7168) == 2048) | ((i2 & StylePropertiesKt.TextDirectionMask) == 32 || ((i2 & 64) != 0 && composerStartRestartGroup.changedInstance(weatherRepository))) | ((i2 & 14) == 4) | composerStartRestartGroup.changed(mutableState3) | ((458752 & i2) == 131072) | composerStartRestartGroup.changed(mutableState4) | composerStartRestartGroup.changed(mutableState5);
            Object objRememberedValue6 = composerStartRestartGroup.rememberedValue();
            if (zChanged5 || objRememberedValue6 == Composer.INSTANCE.getEmpty()) {
                mutableIntState = mutableIntState2;
                str = "CC(remember):MainActivity.kt#9igjgp";
                mutableState = mutableState3;
                mutableState2 = mutableState5;
                i3 = 0;
                mainActivityKt$ForecastPage$2$1 = new MainActivityKt$ForecastPage$2$1(weatherRepository, city, function1, j, mutableState, mutableIntState, mutableState4, mutableState2, null);
                composerStartRestartGroup.updateRememberedValue(mainActivityKt$ForecastPage$2$1);
            } else {
                mutableState2 = mutableState5;
                str = "CC(remember):MainActivity.kt#9igjgp";
                i3 = 0;
                mutableIntState = mutableIntState2;
                mainActivityKt$ForecastPage$2$1 = objRememberedValue6;
                mutableState = mutableState3;
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            EffectsKt.LaunchedEffect(objArr, (Function2<? super CoroutineScope, ? super Continuation<? super Unit>, ? extends Object>) mainActivityKt$ForecastPage$2$1, composerStartRestartGroup, i3);
            String id5 = city.getId();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173238970, str);
            boolean zChangedInstance = composerStartRestartGroup.changedInstance(lifecycle);
            MainActivityKt$ForecastPage$3$1 mainActivityKt$ForecastPage$3$1RememberedValue = composerStartRestartGroup.rememberedValue();
            if (zChangedInstance || mainActivityKt$ForecastPage$3$1RememberedValue == Composer.INSTANCE.getEmpty()) {
                mainActivityKt$ForecastPage$3$1RememberedValue = new MainActivityKt$ForecastPage$3$1(lifecycle, mutableIntState, null);
                composerStartRestartGroup.updateRememberedValue(mainActivityKt$ForecastPage$3$1RememberedValue);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            EffectsKt.LaunchedEffect(lifecycle, id5, (Function2) mainActivityKt$ForecastPage$3$1RememberedValue, composerStartRestartGroup, i3);
            boolean zForecastPage$lambda$4 = ForecastPage$lambda$4(mutableState4);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -173233701, str);
            Object objRememberedValue7 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue7 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue7 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda69
                    @Override // kotlin.jvm.functions.Function0
                    public final Object invoke() {
                        return MainActivityKt.ForecastPage$lambda$16$0(mutableIntState);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue7);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            Modifier modifierFillMaxSize$default = SizeKt.fillMaxSize$default(Modifier.INSTANCE, 0.0f, 1, null);
            final MutableState mutableState6 = mutableState;
            final MutableState mutableState7 = mutableState2;
            final boolean z4 = z3;
            ComposableLambda composableLambdaRememberComposableLambda = ComposableLambdaKt.rememberComposableLambda(-1251731027, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda70
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj, Object obj2, Object obj3) {
                    return MainActivityKt.ForecastPage$lambda$17(j, mutableState6, city, mutableState4, mutableState7, mutableIntState, z4, z2, function0, context, z, function2, fCoerceAtLeast, (BoxScope) obj, (Composer) obj2, ((Integer) obj3).intValue());
                }
            }, composerStartRestartGroup, 54);
            composer2 = composerStartRestartGroup;
            PullToRefreshKt.PullToRefreshBox(zForecastPage$lambda$4, (Function0) objRememberedValue7, modifierFillMaxSize$default, null, null, null, composableLambdaRememberComposableLambda, composer2, 1573296, 56);
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventEnd();
            }
        }
        ScopeUpdateScope scopeUpdateScopeEndRestartGroup = composer2.endRestartGroup();
        if (scopeUpdateScopeEndRestartGroup != null) {
            scopeUpdateScopeEndRestartGroup.updateScope(new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda71
                @Override // kotlin.jvm.functions.Function2
                public final Object invoke(Object obj, Object obj2) {
                    return MainActivityKt.ForecastPage$lambda$18(city, weatherRepository, z, j, z2, function1, function2, function0, i, (Composer) obj, ((Integer) obj2).intValue());
                }
            });
        }
    }