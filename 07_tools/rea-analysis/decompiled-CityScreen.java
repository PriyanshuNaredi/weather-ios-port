    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r0v30 */
    /* JADX WARN: Type inference failed for: r11v18 */
    /* JADX WARN: Type inference failed for: r11v19 */
    /* JADX WARN: Type inference failed for: r11v21 */
    /* JADX WARN: Type inference failed for: r11v22 */
    /* JADX WARN: Type inference failed for: r11v25 */
    /* JADX WARN: Type inference failed for: r11v26 */
    /* JADX WARN: Type inference failed for: r11v32 */
    /* JADX WARN: Type inference failed for: r18v4 */
    /* JADX WARN: Type inference failed for: r18v7 */
    /* JADX WARN: Type inference failed for: r18v8 */
    /* JADX WARN: Type inference failed for: r18v9 */
    /* JADX WARN: Type inference failed for: r1v2 */
    /* JADX WARN: Type inference failed for: r1v3, types: [int] */
    /* JADX WARN: Type inference failed for: r1v8 */
    /* JADX WARN: Type inference failed for: r8v11 */
    /* JADX WARN: Type inference failed for: r8v12, types: [boolean, int] */
    /* JADX WARN: Type inference failed for: r8v17 */
    private static final void CityScreen(final List<City> list, final WeatherRepository weatherRepository, final String str, final boolean z, final Function0<Unit> function0, final Function1<? super City, Unit> function1, final Function1<? super City, Unit> function2, final Function0<Unit> function3, Composer composer, final int i) {
        int i2;
        String str2;
        MutableState mutableState;
        MutableState mutableState2;
        final MutableState mutableState3;
        MainActivityKt$CityScreen$1$1 mainActivityKt$CityScreen$1$1;
        String str3;
        ?? r8;
        ?? r1;
        String str4;
        Context context;
        float f;
        boolean z2;
        ?? r18;
        ?? r11;
        Composer composerStartRestartGroup = composer.startRestartGroup(1754846557);
        ComposerKt.sourceInformation(composerStartRestartGroup, "C(CityScreen)N(cities,repository,message,locating,onLocation,onAdd,onRemove,onClose)400@28530L7,401@28552L29,401@28597L50,401@28665L32,401@28711L40,402@28775L300,402@28753L322,403@29077L2296:MainActivity.kt#uf01hx");
        if ((i & 6) == 0) {
            i2 = (composerStartRestartGroup.changedInstance(list) ? 4 : 2) | i;
        } else {
            i2 = i;
        }
        if ((i & 48) == 0) {
            i2 |= (i & 64) == 0 ? composerStartRestartGroup.changed(weatherRepository) : composerStartRestartGroup.changedInstance(weatherRepository) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i2 |= composerStartRestartGroup.changed(str) ? 256 : 128;
        }
        if ((i & 3072) == 0) {
            i2 |= composerStartRestartGroup.changed(z) ? 2048 : 1024;
        }
        if ((i & 24576) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function0) ? 16384 : 8192;
        }
        if ((196608 & i) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function1) ? 131072 : 65536;
        }
        if ((1572864 & i) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function2) ? 1048576 : 524288;
        }
        if ((i & 12582912) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function3) ? 8388608 : 4194304;
        }
        if (composerStartRestartGroup.shouldExecute((i2 & 4793491) != 4793490, i2 & 1)) {
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventStart(1754846557, i2, -1, "dev.kiankonrad.weather.CityScreen (MainActivity.kt:399)");
            }
            ProvidableCompositionLocal<Context> localContext = AndroidCompositionLocals_androidKt.getLocalContext();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume = composerStartRestartGroup.consume(localContext);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            Context context2 = (Context) objConsume;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1514598598, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue == Composer.INSTANCE.getEmpty()) {
                objRememberedValue = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default("", null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue);
            }
            MutableState mutableState4 = (MutableState) objRememberedValue;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1514597137, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue2 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue2 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue2 = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(CollectionsKt.emptyList(), null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue2);
            }
            MutableState mutableState5 = (MutableState) objRememberedValue2;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1514594979, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue3 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue3 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue3 = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(false, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue3);
            }
            final MutableState mutableState6 = (MutableState) objRememberedValue3;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1514593499, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue4 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue4 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue4 = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(null, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue4);
            }
            MutableState mutableState7 = (MutableState) objRememberedValue4;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            String strCityScreen$lambda$1 = CityScreen$lambda$1(mutableState4);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1514591191, "CC(remember):MainActivity.kt#9igjgp");
            boolean z3 = (i2 & StylePropertiesKt.TextDirectionMask) == 32 || ((i2 & 64) != 0 && composerStartRestartGroup.changedInstance(weatherRepository));
            Object objRememberedValue5 = composerStartRestartGroup.rememberedValue();
            if (z3 || objRememberedValue5 == Composer.INSTANCE.getEmpty()) {
                str2 = "CC(remember):MainActivity.kt#9igjgp";
                mutableState = mutableState5;
                mutableState2 = mutableState7;
                mutableState3 = mutableState4;
                mainActivityKt$CityScreen$1$1 = new MainActivityKt$CityScreen$1$1(weatherRepository, mutableState5, mutableState7, mutableState6, mutableState4, null);
                composerStartRestartGroup.updateRememberedValue(mainActivityKt$CityScreen$1$1);
            } else {
                mutableState2 = mutableState7;
                mainActivityKt$CityScreen$1$1 = objRememberedValue5;
                mutableState = mutableState5;
                mutableState3 = mutableState4;
                str2 = "CC(remember):MainActivity.kt#9igjgp";
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            EffectsKt.LaunchedEffect(strCityScreen$lambda$1, (Function2<? super CoroutineScope, ? super Continuation<? super Unit>, ? extends Object>) mainActivityKt$CityScreen$1$1, composerStartRestartGroup, 0);
            Modifier modifierM1091padding3ABfNKs = PaddingKt.m1091padding3ABfNKs(WindowInsetsPadding_androidKt.imePadding(WindowInsetsPadding_androidKt.navigationBarsPadding(WindowInsetsPadding_androidKt.statusBarsPadding(SizeKt.fillMaxSize$default(Modifier.INSTANCE, 0.0f, 1, null)))), Dp.m8374constructorimpl(20.0f));
            Arrangement.HorizontalOrVertical horizontalOrVerticalM783spacedBy0680j_4 = Arrangement.INSTANCE.m783spacedBy0680j_4(Dp.m8374constructorimpl(14.0f));
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1341605231, "CC(Column)N(modifier,verticalArrangement,horizontalAlignment,content)87@4443L61,88@4509L134:Column.kt#2w3rfo");
            MeasurePolicy measurePolicyColumnMeasurePolicy = ColumnKt.columnMeasurePolicy(horizontalOrVerticalM783spacedBy0680j_4, Alignment.INSTANCE.getStart(), composerStartRestartGroup, 6);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1159599143, "CC(Layout)N(content,modifier,measurePolicy)81@3355L27,84@3521L415:Layout.kt#80mrfh");
            int iHashCode = Long.hashCode(ComposablesKt.getCurrentCompositeKeyHashCode(composerStartRestartGroup, 0));
            CompositionLocalMap currentCompositionLocalMap = composerStartRestartGroup.getCurrentCompositionLocalMap();
            Modifier modifierMaterializeModifier = ComposedModifierKt.materializeModifier(composerStartRestartGroup, modifierM1091padding3ABfNKs);
            Function0<ComposeUiNode> constructor = ComposeUiNode.INSTANCE.getConstructor();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -553112988, "CC(ReusableComposeNode)N(factory,update,content)410@16216L9:Composables.kt#9igjgp");
            if (!(composerStartRestartGroup.getApplier() instanceof Applier)) {
                ComposablesKt.invalidApplier();
            }
            composerStartRestartGroup.startReusableNode();
            if (composerStartRestartGroup.getInserting()) {
                composerStartRestartGroup.createNode(constructor);
            } else {
                composerStartRestartGroup.useNode();
            }
            Composer composerM4605constructorimpl = Updater.m4605constructorimpl(composerStartRestartGroup);
            Updater.m4613setimpl(composerM4605constructorimpl, measurePolicyColumnMeasurePolicy, ComposeUiNode.INSTANCE.getSetMeasurePolicy());
            Updater.m4613setimpl(composerM4605constructorimpl, currentCompositionLocalMap, ComposeUiNode.INSTANCE.getSetResolvedCompositionLocals());
            Updater.m4613setimpl(composerM4605constructorimpl, Integer.valueOf(iHashCode), ComposeUiNode.INSTANCE.getSetCompositeKeyHash());
            Updater.m4611reconcileimpl(composerM4605constructorimpl, ComposeUiNode.INSTANCE.getApplyOnDeactivatedNodeAssertion());
            Updater.m4613setimpl(composerM4605constructorimpl, modifierMaterializeModifier, ComposeUiNode.INSTANCE.getSetModifier());
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2093002350, "C89@4557L9:Column.kt#2w3rfo");
            ColumnScopeInstance columnScopeInstance = ColumnScopeInstance.INSTANCE;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 535754934, "C405@29513L10,405@29676L97,405@29469L337,406@29907L135,406@29809L233,410@30259L861,410@30170L950,419@31142L153,419@31123L247:MainActivity.kt#uf01hx");
            if (list.isEmpty()) {
                composerStartRestartGroup.startReplaceGroup(535754530);
                ComposerKt.sourceInformation(composerStartRestartGroup, "404@29294L30,404@29325L23,404@29349L58,404@29408L57");
                SpacerKt.Spacer(SizeKt.m1144height3ABfNKs(Modifier.INSTANCE, Dp.m8374constructorimpl(32.0f)), composerStartRestartGroup, 6);
                str3 = str2;
                r8 = 1;
                WeatherGlyph(2, true, 72, composerStartRestartGroup, 438, 0);
                TextKt.m3329TextNvy7gAk("Weather", null, 0L, null, TextUnitKt.getSp(44), null, FontWeight.INSTANCE.getLight(), null, 0L, null, null, 0L, 0, false, 0, 0, null, null, composerStartRestartGroup, 1597446, 0, 262062);
                TextKt.m3329TextNvy7gAk("Your day, at a glance.", null, Muted, null, TextUnitKt.getSp(20), null, null, null, 0L, null, null, 0L, 0, false, 0, 0, null, null, composerStartRestartGroup, 24966, 0, 262122);
                composerStartRestartGroup = composerStartRestartGroup;
                composerStartRestartGroup.endReplaceGroup();
            } else {
                composerStartRestartGroup.startReplaceGroup(-121266254);
                ComposerKt.sourceInformation(composerStartRestartGroup, "404@29256L31");
                ScreenHeader("Weather", function3, composerStartRestartGroup, ((i2 >> 18) & StylePropertiesKt.TextDirectionMask) | 6);
                composerStartRestartGroup.endReplaceGroup();
                str3 = str2;
                r8 = 1;
            }
            String strCityScreen$lambda$2 = CityScreen$lambda$1(mutableState3);
            Modifier modifierFillMaxWidth$default = SizeKt.fillMaxWidth$default(Modifier.INSTANCE, 0.0f, r8, null);
            RoundedCornerShape roundedCornerShapeM1424RoundedCornerShape0680j_4 = RoundedCornerShapeKt.m1424RoundedCornerShape0680j_4(Dp.m8374constructorimpl(16.0f));
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -121258051, str3);
            Object objRememberedValue6 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue6 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue6 = new Function1() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda1
                    @Override // kotlin.jvm.functions.Function1
                    public final Object invoke(Object obj) {
                        return MainActivityKt.CityScreen$lambda$13$0$0(mutableState3, (String) obj);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue6);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            Composer composer2 = composerStartRestartGroup;
            OutlinedTextFieldKt.OutlinedTextField(strCityScreen$lambda$2, (Function1<? super String, Unit>) objRememberedValue6, modifierFillMaxWidth$default, false, false, (TextStyle) null, (Function2<? super Composer, ? super Integer, Unit>) ComposableSingletons$MainActivityKt.INSTANCE.getLambda$396275693$app_release(), (Function2<? super Composer, ? super Integer, Unit>) null, (Function2<? super Composer, ? super Integer, Unit>) ComposableSingletons$MainActivityKt.INSTANCE.m8818getLambda$1309853909$app_release(), (Function2<? super Composer, ? super Integer, Unit>) ComposableLambdaKt.rememberComposableLambda(-15435062, r8, new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda2
                @Override // kotlin.jvm.functions.Function2
                public final Object invoke(Object obj, Object obj2) {
                    return MainActivityKt.CityScreen$lambda$13$1(mutableState3, (Composer) obj, ((Integer) obj2).intValue());
                }
            }, composerStartRestartGroup, 54), (Function2<? super Composer, ? super Integer, Unit>) null, (Function2<? super Composer, ? super Integer, Unit>) null, (Function2<? super Composer, ? super Integer, Unit>) null, false, (VisualTransformation) null, (KeyboardOptions) null, (KeyboardActions) null, true, 0, 0, (MutableInteractionSource) null, (Shape) roundedCornerShapeM1424RoundedCornerShape0680j_4, (TextFieldColors) null, composer2, 907542960, 12582912, 0, 6159544);
            ButtonKt.Button(function0, SizeKt.m1146heightInVpY3zN4$default(SizeKt.fillMaxWidth$default(Modifier.INSTANCE, 0.0f, r8, null), Dp.m8374constructorimpl(50.0f), 0.0f, 2, null), !z, null, null, null, null, null, null, ComposableLambdaKt.rememberComposableLambda(-315595581, r8, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda3
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj, Object obj2, Object obj3) {
                    return MainActivityKt.CityScreen$lambda$13$2(z, (RowScope) obj, (Composer) obj2, ((Integer) obj3).intValue());
                }
            }, composer2, 54), composer2, ((i2 >> 12) & 14) | 805306416, 504);
            composerStartRestartGroup = composer2;
            if (str == null) {
                composerStartRestartGroup.startReplaceGroup(536504853);
                composerStartRestartGroup.endReplaceGroup();
                context = context2;
                str4 = str3;
                r1 = r8;
                f = 0.0f;
                z2 = false;
            } else {
                composerStartRestartGroup.startReplaceGroup(536504854);
                ComposerKt.sourceInformation(composerStartRestartGroup, "*407@30058L20");
                long j = Muted;
                r1 = r8 == true ? 1 : 0;
                str4 = str3;
                context = context2;
                f = 0.0f;
                z2 = false;
                TextKt.m3329TextNvy7gAk(str, null, j, null, 0L, null, null, null, 0L, null, null, 0L, 0, false, 0, 0, null, null, composerStartRestartGroup, 384, 0, 262138);
                composerStartRestartGroup = composerStartRestartGroup;
                Unit unit = Unit.INSTANCE;
                composerStartRestartGroup.endReplaceGroup();
                Unit unit2 = Unit.INSTANCE;
            }
            if (CityScreen$lambda$7(mutableState6)) {
                composerStartRestartGroup.startReplaceGroup(-121239357);
                ComposerKt.sourceInformation(composerStartRestartGroup, "408@30096L48");
                ProgressIndicatorKt.m2997LinearProgressIndicatorrIrjwxo(SizeKt.fillMaxWidth$default(Modifier.INSTANCE, f, r1, null), 0L, 0L, 0, 0.0f, composerStartRestartGroup, 6, 30);
            } else {
                composerStartRestartGroup.startReplaceGroup(506689519);
            }
            composerStartRestartGroup.endReplaceGroup();
            String strCityScreen$lambda$10 = CityScreen$lambda$10(mutableState2);
            if (strCityScreen$lambda$10 == null) {
                composerStartRestartGroup.startReplaceGroup(536603681);
                composerStartRestartGroup.endReplaceGroup();
            } else {
                composerStartRestartGroup.startReplaceGroup(536603682);
                ComposerKt.sourceInformation(composerStartRestartGroup, "*409@30158L8");
                Composer composer3 = composerStartRestartGroup;
                TextKt.m3329TextNvy7gAk(strCityScreen$lambda$10, null, 0L, null, 0L, null, null, null, 0L, null, null, 0L, 0, false, 0, 0, null, null, composer3, 0, 0, 262142);
                composerStartRestartGroup = composer3;
                Unit unit3 = Unit.INSTANCE;
                composerStartRestartGroup.endReplaceGroup();
                Unit unit4 = Unit.INSTANCE;
            }
            Modifier modifierWeight$default = ColumnScope.weight$default(columnScopeInstance, Modifier.INSTANCE, 1.0f, false, 2, null);
            Arrangement.HorizontalOrVertical horizontalOrVerticalM783spacedBy0680j_5 = Arrangement.INSTANCE.m783spacedBy0680j_4(Dp.m8374constructorimpl(12.0f));
            String str5 = str4;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -121233328, str5);
            if ((i2 & 458752) == 131072) {
                ?? r12 = r1;
                r18 = r12 == true ? 1 : 0;
                r11 = r12;
            } else {
                r18 = r1;
                r11 = z2;
            }
            ?? r0 = (composerStartRestartGroup.changedInstance(list) ? 1 : 0) | r11 | ((i2 & 3670016) == 1048576 ? r18 : z2);
            Object objRememberedValue7 = composerStartRestartGroup.rememberedValue();
            if (r0 != 0 || objRememberedValue7 == Composer.INSTANCE.getEmpty()) {
                final MutableState mutableState8 = mutableState3;
                final MutableState mutableState9 = mutableState;
                final MutableState mutableState10 = mutableState2;
                Function1 function4 = new Function1() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda4
                    @Override // kotlin.jvm.functions.Function1
                    public final Object invoke(Object obj) {
                        return MainActivityKt.CityScreen$lambda$13$5$0(list, mutableState8, mutableState6, mutableState9, mutableState10, function1, function2, (LazyListScope) obj);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(function4);
                objRememberedValue7 = function4;
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            LazyDslKt.LazyColumn(modifierWeight$default, null, null, false, horizontalOrVerticalM783spacedBy0680j_5, null, null, false, null, (Function1) objRememberedValue7, composerStartRestartGroup, 24576, 494);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -121205780, str5);
            final Context context3 = context;
            boolean zChangedInstance = composerStartRestartGroup.changedInstance(context3);
            Object objRememberedValue8 = composerStartRestartGroup.rememberedValue();
            if (zChangedInstance || objRememberedValue8 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue8 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda5
                    @Override // kotlin.jvm.functions.Function0
                    public final Object invoke() {
                        return MainActivityKt.CityScreen$lambda$13$6$0(context3);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue8);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ButtonKt.TextButton((Function0) objRememberedValue8, null, false, null, null, null, null, null, null, ComposableSingletons$MainActivityKt.INSTANCE.m8823getLambda$220816368$app_release(), composerStartRestartGroup, 805306368, 510);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            composerStartRestartGroup.endNode();
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventEnd();
            }
        } else {
            composerStartRestartGroup.skipToGroupEnd();
        }
        ScopeUpdateScope scopeUpdateScopeEndRestartGroup = composerStartRestartGroup.endRestartGroup();
        if (scopeUpdateScopeEndRestartGroup != null) {
            scopeUpdateScopeEndRestartGroup.updateScope(new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda6
                @Override // kotlin.jvm.functions.Function2
                public final Object invoke(Object obj, Object obj2) {
                    return MainActivityKt.CityScreen$lambda$14(list, weatherRepository, str, z, function0, function1, function2, function3, i, (Composer) obj, ((Integer) obj2).intValue());
                }
            });
        }
    }