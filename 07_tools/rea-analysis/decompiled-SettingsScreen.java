    private static final void SettingsScreen(final boolean z, final Function1<? super Boolean, Unit> function1, final Function0<Unit> function0, Composer composer, final int i) {
        int i2;
        Composer composerStartRestartGroup = composer.startRestartGroup(277193119);
        ComposerKt.sourceInformation(composerStartRestartGroup, "C(SettingsScreen)N(imperial,onImperial,onClose)424@31508L7,425@31537L32,426@31660L21,426@31571L2085:MainActivity.kt#uf01hx");
        if ((i & 6) == 0) {
            i2 = (composerStartRestartGroup.changed(z) ? 4 : 2) | i;
        } else {
            i2 = i;
        }
        if ((i & 48) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function1) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i2 |= composerStartRestartGroup.changedInstance(function0) ? 256 : 128;
        }
        if (composerStartRestartGroup.shouldExecute((i2 & 147) != 146, i2 & 1)) {
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventStart(277193119, i2, -1, "dev.kiankonrad.weather.SettingsScreen (MainActivity.kt:423)");
            }
            ProvidableCompositionLocal<Context> localContext = AndroidCompositionLocals_androidKt.getLocalContext();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume = composerStartRestartGroup.consume(localContext);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            final Context context = (Context) objConsume;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 94619551, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue == Composer.INSTANCE.getEmpty()) {
                objRememberedValue = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(false, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue);
            }
            final MutableState mutableState = (MutableState) objRememberedValue;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            Modifier modifierM1091padding3ABfNKs = PaddingKt.m1091padding3ABfNKs(ScrollKt.verticalScroll$default(WindowInsetsPadding_androidKt.navigationBarsPadding(WindowInsetsPadding_androidKt.statusBarsPadding(SizeKt.fillMaxSize$default(Modifier.INSTANCE, 0.0f, 1, null))), ScrollKt.rememberScrollState(0, composerStartRestartGroup, 0, 1), false, null, false, 14, null), Dp.m8374constructorimpl(20.0f));
            Arrangement.HorizontalOrVertical horizontalOrVerticalM783spacedBy0680j_4 = Arrangement.INSTANCE.m783spacedBy0680j_4(Dp.m8374constructorimpl(18.0f));
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
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1641545184, "C427@31751L32,428@31792L353,428@31786L359,429@32148L296,430@32453L797,430@32447L803,433@33253L126,434@33401L19,434@33382L70,435@33474L144,435@33455L198:MainActivity.kt#uf01hx");
            ScreenHeader("Settings", function0, composerStartRestartGroup, ((i2 >> 3) & StylePropertiesKt.TextDirectionMask) | 6);
            Glass(null, ComposableLambdaKt.rememberComposableLambda(1031645365, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda24
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj, Object obj2, Object obj3) {
                    return MainActivityKt.SettingsScreen$lambda$3$0(z, function1, (ColumnScope) obj, (Composer) obj2, ((Integer) obj3).intValue());
                }
            }, composerStartRestartGroup, 54), composerStartRestartGroup, 48, 1);
            Glass(null, ComposableSingletons$MainActivityKt.INSTANCE.getLambda$1577843500$app_release(), composerStartRestartGroup, 48, 1);
            Glass(null, ComposableLambdaKt.rememberComposableLambda(875247661, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda25
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj, Object obj2, Object obj3) {
                    return MainActivityKt.SettingsScreen$lambda$3$1(context, (ColumnScope) obj, (Composer) obj2, ((Integer) obj3).intValue());
                }
            }, composerStartRestartGroup, 54), composerStartRestartGroup, 48, 1);
            TextKt.m3329TextNvy7gAk("Weather 1.1.1\nCreated by Kian Konrad Tajbakhsh\nOpen source · MIT license", null, Muted, null, TextUnitKt.getSp(13), null, null, null, 0L, null, null, TextUnitKt.getSp(21), 0, false, 0, 0, null, null, composerStartRestartGroup, 24966, 48, 260074);
            composerStartRestartGroup = composerStartRestartGroup;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1609665832, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue2 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue2 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue2 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda26
                    @Override // kotlin.jvm.functions.Function0
                    public final Object invoke() {
                        return MainActivityKt.SettingsScreen$lambda$3$2$0(mutableState);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue2);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ButtonKt.TextButton((Function0) objRememberedValue2, null, false, null, null, null, null, null, null, ComposableSingletons$MainActivityKt.INSTANCE.getLambda$1740200338$app_release(), composerStartRestartGroup, 805306374, 510);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1609668293, "CC(remember):MainActivity.kt#9igjgp");
            boolean zChangedInstance = composerStartRestartGroup.changedInstance(context);
            Object objRememberedValue3 = composerStartRestartGroup.rememberedValue();
            if (zChangedInstance || objRememberedValue3 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue3 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda27
                    @Override // kotlin.jvm.functions.Function0
                    public final Object invoke() {
                        return MainActivityKt.SettingsScreen$lambda$3$3$0(context);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue3);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ButtonKt.TextButton((Function0) objRememberedValue3, null, false, null, null, null, null, null, null, ComposableSingletons$MainActivityKt.INSTANCE.m8827getLambda$400627511$app_release(), composerStartRestartGroup, 805306368, 510);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            composerStartRestartGroup.endNode();
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            if (SettingsScreen$lambda$1(mutableState)) {
                composerStartRestartGroup.startReplaceGroup(-1359622895);
                ComposerKt.sourceInformation(composerStartRestartGroup, "438@33690L225,439@33947L20,441@34209L56,440@34014L176,439@33918L348");
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 94688640, "CC(remember):MainActivity.kt#9igjgp");
                Object objRememberedValue4 = composerStartRestartGroup.rememberedValue();
                if (objRememberedValue4 == Composer.INSTANCE.getEmpty()) {
                    objRememberedValue4 = CollectionsKt.joinToString$default(CollectionsKt.listOf((Object[]) new String[]{"MIT.txt", "NOTICE.txt", "Apache-2.0.txt", "MapLibre_Android_13.6.1.txt", "Bundled_Dependency_Notices.txt"}), "\n\n", null, null, 0, null, new Function1() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda28
                        @Override // kotlin.jvm.functions.Function1
                        public final Object invoke(Object obj) {
                            return MainActivityKt.SettingsScreen$lambda$4$0(context, (String) obj);
                        }
                    }, 30, null);
                    composerStartRestartGroup.updateRememberedValue(objRememberedValue4);
                }
                final String str = (String) objRememberedValue4;
                ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 94696659, "CC(remember):MainActivity.kt#9igjgp");
                Object objRememberedValue5 = composerStartRestartGroup.rememberedValue();
                if (objRememberedValue5 == Composer.INSTANCE.getEmpty()) {
                    objRememberedValue5 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda29
                        @Override // kotlin.jvm.functions.Function0
                        public final Object invoke() {
                            return MainActivityKt.SettingsScreen$lambda$5$0(mutableState);
                        }
                    };
                    composerStartRestartGroup.updateRememberedValue(objRememberedValue5);
                }
                ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
                AndroidAlertDialog_androidKt.m2322AlertDialogOix01E0((Function0) objRememberedValue5, ComposableLambdaKt.rememberComposableLambda(894999410, true, new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda30
                    @Override // kotlin.jvm.functions.Function2
                    public final Object invoke(Object obj, Object obj2) {
                        return MainActivityKt.SettingsScreen$lambda$6(mutableState, (Composer) obj, ((Integer) obj2).intValue());
                    }
                }, composerStartRestartGroup, 54), null, null, null, ComposableSingletons$MainActivityKt.INSTANCE.m8826getLambda$274543890$app_release(), ComposableLambdaKt.rememberComposableLambda(-566929715, true, new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda31
                    @Override // kotlin.jvm.functions.Function2
                    public final Object invoke(Object obj, Object obj2) {
                        return MainActivityKt.SettingsScreen$lambda$7(str, (Composer) obj, ((Integer) obj2).intValue());
                    }
                }, composerStartRestartGroup, 54), null, 0L, 0L, 0L, 0L, 0.0f, null, composerStartRestartGroup, 1769526, 0, 16284);
                composerStartRestartGroup = composerStartRestartGroup;
            } else {
                composerStartRestartGroup.startReplaceGroup(-1393047901);
            }
            composerStartRestartGroup.endReplaceGroup();
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventEnd();
            }
        } else {
            composerStartRestartGroup.skipToGroupEnd();
        }
        ScopeUpdateScope scopeUpdateScopeEndRestartGroup = composerStartRestartGroup.endRestartGroup();
        if (scopeUpdateScopeEndRestartGroup != null) {
            scopeUpdateScopeEndRestartGroup.updateScope(new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda32
                @Override // kotlin.jvm.functions.Function2
                public final Object invoke(Object obj, Object obj2) {
                    return MainActivityKt.SettingsScreen$lambda$8(z, function1, function0, i, (Composer) obj, ((Integer) obj2).intValue());
                }
            });
        }
    }