    /* JADX WARN: Code duplicated, block: B:75:0x0121  */
    /* JADX WARN: Code duplicated, block: B:77:0x012d  */
    /* JADX WARN: Code duplicated, block: B:78:0x0132  */
    private static final void MetricScreen(Metric metric, final Weather weather, boolean z, final Function0<Unit> function0, Composer composer, final int i) {
        Composer composer2;
        Day day;
        Composer composer3;
        String str;
        boolean z2;
        int i2;
        final Context context;
        int i3;
        int i4;
        boolean z3;
        boolean z4;
        final Metric metric2 = metric;
        final boolean z5 = z;
        Composer composerStartRestartGroup = composer.startRestartGroup(-1480264169);
        ComposerKt.sourceInformation(composerStartRestartGroup, "C(MetricScreen)N(metric,w,imperial,onClose)352@23329L7,353@23350L84,355@23566L38,355@23543L61,358@24156L21,358@24067L3169:MainActivity.kt#uf01hx");
        int i5 = (i & 6) == 0 ? (composerStartRestartGroup.changed(metric2.ordinal()) ? 4 : 2) | i : i;
        if ((i & 48) == 0) {
            i5 |= (i & 64) == 0 ? composerStartRestartGroup.changed(weather) : composerStartRestartGroup.changedInstance(weather) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i5 |= composerStartRestartGroup.changed(z5) ? 256 : 128;
        }
        if ((i & 3072) == 0) {
            i5 |= composerStartRestartGroup.changedInstance(function0) ? 2048 : 1024;
        }
        if (composerStartRestartGroup.shouldExecute((i5 & 1171) != 1170, i5 & 1)) {
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventStart(-1480264169, i5, -1, "dev.kiankonrad.weather.MetricScreen (MainActivity.kt:351)");
            }
            ProvidableCompositionLocal<Context> localContext = AndroidCompositionLocals_androidKt.getLocalContext();
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 2023513938, "CC(<get-current>):CompositionLocal.kt#9igjgp");
            Object objConsume = composerStartRestartGroup.consume(localContext);
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            Context context2 = (Context) objConsume;
            String str2 = "CC(remember):MainActivity.kt#9igjgp";
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -899687221, "CC(remember):MainActivity.kt#9igjgp");
            int i6 = i5 & 14;
            boolean z6 = i6 == 4;
            Object objRememberedValue = composerStartRestartGroup.rememberedValue();
            if (z6 || objRememberedValue == Composer.INSTANCE.getEmpty()) {
                String selectedDate = Metric.INSTANCE.getSelectedDate();
                if (selectedDate == null) {
                    Day day2 = (Day) CollectionsKt.firstOrNull((List) weather.getDays());
                    selectedDate = day2 != null ? day2.getDate() : null;
                }
                objRememberedValue = SnapshotStateKt__SnapshotStateKt.mutableStateOf$default(selectedDate, null, 2, null);
                composerStartRestartGroup.updateRememberedValue(objRememberedValue);
            }
            final MutableState mutableState = (MutableState) objRememberedValue;
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            String strMetricScreen$lambda$1 = MetricScreen$lambda$1(mutableState);
            if (strMetricScreen$lambda$1 != null) {
                List<Day> days = weather.getDays();
                if (!(days instanceof Collection) || !days.isEmpty()) {
                    Iterator<T> it = days.iterator();
                    while (true) {
                        if (it.hasNext()) {
                            if (Intrinsics.areEqual(((Day) it.next()).getDate(), strMetricScreen$lambda$1)) {
                                z4 = true;
                                break;
                            }
                        } else {
                            z4 = false;
                            break;
                        }
                    }
                } else {
                    z4 = false;
                    break;
                }
                if (!z4) {
                    strMetricScreen$lambda$1 = null;
                }
                if (strMetricScreen$lambda$1 == null) {
                    day = (Day) CollectionsKt.firstOrNull((List) weather.getDays());
                    if (day != null) {
                        strMetricScreen$lambda$1 = day.getDate();
                    } else {
                        strMetricScreen$lambda$1 = null;
                    }
                }
            } else {
                day = (Day) CollectionsKt.firstOrNull((List) weather.getDays());
                if (day != null) {
                    strMetricScreen$lambda$1 = day.getDate();
                } else {
                    strMetricScreen$lambda$1 = null;
                }
            }
            Unit unit = Unit.INSTANCE;
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -899680355, "CC(remember):MainActivity.kt#9igjgp");
            Object objRememberedValue2 = composerStartRestartGroup.rememberedValue();
            if (objRememberedValue2 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue2 = new Function1() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda34
                    @Override // kotlin.jvm.functions.Function1
                    public final Object invoke(Object obj) {
                        return MainActivityKt.MetricScreen$lambda$4$0((DisposableEffectScope) obj);
                    }
                };
                composerStartRestartGroup.updateRememberedValue(objRememberedValue2);
            }
            ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
            EffectsKt.DisposableEffect(unit, (Function1<? super DisposableEffectScope, ? extends DisposableEffectResult>) objRememberedValue2, composerStartRestartGroup, 54);
            List<Hour> hours = weather.getHours();
            ArrayList arrayList = new ArrayList();
            for (Object obj : hours) {
                Context context3 = context2;
                if (Intrinsics.areEqual(Instant.ofEpochSecond(((Hour) obj).getTime()).atZone(ZoneId.of(weather.getTimezone())).toLocalDate().toString(), strMetricScreen$lambda$1)) {
                    arrayList.add(obj);
                }
                context2 = context3;
            }
            Context context4 = context2;
            final ArrayList arrayList2 = arrayList;
            Modifier modifierM1091padding3ABfNKs = PaddingKt.m1091padding3ABfNKs(ScrollKt.verticalScroll$default(WindowInsetsPadding_androidKt.navigationBarsPadding(WindowInsetsPadding_androidKt.statusBarsPadding(SizeKt.fillMaxSize$default(Modifier.INSTANCE, 0.0f, 1, null))), ScrollKt.rememberScrollState(0, composerStartRestartGroup, 0, 1), false, null, false, 14, null), Dp.m8374constructorimpl(20.0f));
            Arrangement.HorizontalOrVertical horizontalOrVerticalM783spacedBy0680j_4 = Arrangement.INSTANCE.m783spacedBy0680j_4(Dp.m8374constructorimpl(18.0f));
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1341605231, "CC(Column)N(modifier,verticalArrangement,horizontalAlignment,content)87@4443L61,88@4509L134:Column.kt#2w3rfo");
            MeasurePolicy measurePolicyColumnMeasurePolicy = ColumnKt.columnMeasurePolicy(horizontalOrVerticalM783spacedBy0680j_4, Alignment.INSTANCE.getStart(), composerStartRestartGroup, 6);
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1159599143, "CC(Layout)N(content,modifier,measurePolicy)81@3355L27,84@3521L415:Layout.kt#80mrfh");
            int iHashCode = Long.hashCode(ComposablesKt.getCurrentCompositeKeyHashCode(composerStartRestartGroup, 0));
            CompositionLocalMap currentCompositionLocalMap = composerStartRestartGroup.getCurrentCompositionLocalMap();
            Modifier modifierMaterializeModifier = ComposedModifierKt.materializeModifier(composerStartRestartGroup, modifierM1091padding3ABfNKs);
            int i7 = i5;
            Function0<ComposeUiNode> constructor = ComposeUiNode.INSTANCE.getConstructor();
            int i8 = i6;
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
            ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1688409368, "C359@24247L34,360@24290L124,360@24284L130,381@26912L209,381@27123L110,381@26893L340:MainActivity.kt#uf01hx");
            ScreenHeader(metric2.getTitle(), function0, composerStartRestartGroup, (i7 >> 6) & StylePropertiesKt.TextDirectionMask);
            Glass(null, ComposableLambdaKt.rememberComposableLambda(-1157263551, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda36
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj2, Object obj3, Object obj4) {
                    return MainActivityKt.MetricScreen$lambda$6$0(metric2, weather, z5, (ColumnScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                }
            }, composerStartRestartGroup, 54), composerStartRestartGroup, 48, 1);
            if (metric2 == Metric.SUN || metric2 == Metric.AIR) {
                composer3 = composerStartRestartGroup;
                str = "CC(remember):MainActivity.kt#9igjgp";
                z2 = true;
                i2 = i8;
                context = context4;
                i3 = 54;
                i4 = 4;
                z3 = false;
                if (metric2 == Metric.SUN) {
                    composer3.startReplaceGroup(1690369993);
                    ComposerKt.sourceInformation(composer3, "376@26320L233,376@26314L239");
                    Glass(null, ComposableLambdaKt.rememberComposableLambda(324315197, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda41
                        @Override // kotlin.jvm.functions.Function3
                        public final Object invoke(Object obj2, Object obj3, Object obj4) {
                            return MainActivityKt.MetricScreen$lambda$6$4(weather, (ColumnScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                        }
                    }, composer3, 54), composer3, 48, 1);
                    composer3.endReplaceGroup();
                } else {
                    composer3.startReplaceGroup(885820264);
                    ComposerKt.sourceInformation(composer3, "377@26569L321,377@26563L327");
                    Glass(null, ComposableLambdaKt.rememberComposableLambda(-1410494179, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda42
                        @Override // kotlin.jvm.functions.Function3
                        public final Object invoke(Object obj2, Object obj3, Object obj4) {
                            return MainActivityKt.MetricScreen$lambda$6$5(weather, (ColumnScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                        }
                    }, composer3, 54), composer3, 48, 1);
                    composer3.endReplaceGroup();
                }
            } else {
                composerStartRestartGroup.startReplaceGroup(1688586439);
                ComposerKt.sourceInformation(composerStartRestartGroup, "362@24497L21,362@24467L223,363@24700L880,363@24694L886,371@25590L686,371@25584L692");
                Modifier modifierHorizontalScroll$default = ScrollKt.horizontalScroll$default(Modifier.INSTANCE, ScrollKt.rememberScrollState(0, composerStartRestartGroup, 0, 1), false, null, false, 14, null);
                Arrangement.HorizontalOrVertical horizontalOrVerticalM783spacedBy0680j_5 = Arrangement.INSTANCE.m783spacedBy0680j_4(Dp.m8374constructorimpl(8.0f));
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 844473419, "CC(Row)N(modifier,horizontalArrangement,verticalAlignment,content)99@5125L58,100@5188L131:Row.kt#2w3rfo");
                MeasurePolicy measurePolicyRowMeasurePolicy = RowKt.rowMeasurePolicy(horizontalOrVerticalM783spacedBy0680j_5, Alignment.INSTANCE.getTop(), composerStartRestartGroup, 6);
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1159599143, "CC(Layout)N(content,modifier,measurePolicy)81@3355L27,84@3521L415:Layout.kt#80mrfh");
                int iHashCode2 = Long.hashCode(ComposablesKt.getCurrentCompositeKeyHashCode(composerStartRestartGroup, 0));
                CompositionLocalMap currentCompositionLocalMap2 = composerStartRestartGroup.getCurrentCompositionLocalMap();
                Modifier modifierMaterializeModifier2 = ComposedModifierKt.materializeModifier(composerStartRestartGroup, modifierHorizontalScroll$default);
                Function0<ComposeUiNode> constructor2 = ComposeUiNode.INSTANCE.getConstructor();
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -553112988, "CC(ReusableComposeNode)N(factory,update,content)410@16216L9:Composables.kt#9igjgp");
                if (!(composerStartRestartGroup.getApplier() instanceof Applier)) {
                    ComposablesKt.invalidApplier();
                }
                composerStartRestartGroup.startReusableNode();
                if (composerStartRestartGroup.getInserting()) {
                    composerStartRestartGroup.createNode(constructor2);
                } else {
                    composerStartRestartGroup.useNode();
                }
                Composer composerM4605constructorimpl2 = Updater.m4605constructorimpl(composerStartRestartGroup);
                Updater.m4613setimpl(composerM4605constructorimpl2, measurePolicyRowMeasurePolicy, ComposeUiNode.INSTANCE.getSetMeasurePolicy());
                Updater.m4613setimpl(composerM4605constructorimpl2, currentCompositionLocalMap2, ComposeUiNode.INSTANCE.getSetResolvedCompositionLocals());
                Updater.m4613setimpl(composerM4605constructorimpl2, Integer.valueOf(iHashCode2), ComposeUiNode.INSTANCE.getSetCompositeKeyHash());
                Updater.m4611reconcileimpl(composerM4605constructorimpl2, ComposeUiNode.INSTANCE.getApplyOnDeactivatedNodeAssertion());
                Updater.m4613setimpl(composerM4605constructorimpl2, modifierMaterializeModifier2, ComposeUiNode.INSTANCE.getSetModifier());
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1456264949, "C101@5233L9:Row.kt#2w3rfo");
                RowScopeInstance rowScopeInstance = RowScopeInstance.INSTANCE;
                ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, 1213333739, "C:MainActivity.kt#uf01hx");
                composerStartRestartGroup.startReplaceGroup(-2039069967);
                ComposerKt.sourceInformation(composerStartRestartGroup, "*362@24641L13,362@24661L26,362@24591L97");
                for (final Day day3 : weather.getDays()) {
                    boolean zAreEqual = Intrinsics.areEqual(strMetricScreen$lambda$1, day3.getDate());
                    ComposerKt.sourceInformationMarkerStart(composerStartRestartGroup, -1072311350, str2);
                    boolean zChanged = composerStartRestartGroup.changed(mutableState) | composerStartRestartGroup.changed(day3);
                    Object objRememberedValue3 = composerStartRestartGroup.rememberedValue();
                    if (zChanged || objRememberedValue3 == Composer.INSTANCE.getEmpty()) {
                        objRememberedValue3 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda37
                            @Override // kotlin.jvm.functions.Function0
                            public final Object invoke() {
                                return MainActivityKt.MetricScreen$lambda$6$1$0$0$0(day3, mutableState);
                            }
                        };
                        composerStartRestartGroup.updateRememberedValue(objRememberedValue3);
                    }
                    ComposerKt.sourceInformationMarkerEnd(composerStartRestartGroup);
                    Composer composer4 = composerStartRestartGroup;
                    ChipKt.FilterChip(zAreEqual, (Function0) objRememberedValue3, ComposableLambdaKt.rememberComposableLambda(215764298, true, new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda38
                        @Override // kotlin.jvm.functions.Function2
                        public final Object invoke(Object obj2, Object obj3) {
                            return MainActivityKt.MetricScreen$lambda$6$1$0$1(day3, (Composer) obj2, ((Integer) obj3).intValue());
                        }
                    }, composerStartRestartGroup, 54), null, false, null, null, null, null, null, null, null, composer4, 384, 0, 4088);
                    mutableState = mutableState;
                    composerStartRestartGroup = composer4;
                    i8 = i8;
                    strMetricScreen$lambda$1 = strMetricScreen$lambda$1;
                    str2 = str2;
                }
                composer3 = composerStartRestartGroup;
                final String str3 = strMetricScreen$lambda$1;
                str = str2;
                z2 = true;
                i3 = 54;
                z3 = false;
                composer3.endReplaceGroup();
                ComposerKt.sourceInformationMarkerEnd(composer3);
                ComposerKt.sourceInformationMarkerEnd(composer3);
                composer3.endNode();
                ComposerKt.sourceInformationMarkerEnd(composer3);
                ComposerKt.sourceInformationMarkerEnd(composer3);
                ComposerKt.sourceInformationMarkerEnd(composer3);
                i4 = 4;
                context = context4;
                i2 = i8;
                Function3 function3 = new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda39
                    @Override // kotlin.jvm.functions.Function3
                    public final Object invoke(Object obj2, Object obj3, Object obj4) {
                        return MainActivityKt.MetricScreen$lambda$6$2(str3, weather, metric2, arrayList2, z5, (ColumnScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                    }
                };
                metric2 = metric2;
                z5 = z5;
                Glass(null, ComposableLambdaKt.rememberComposableLambda(-2032630842, true, function3, composer3, 54), composer3, 48, 1);
                Glass(null, ComposableLambdaKt.rememberComposableLambda(1169697455, true, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda40
                    @Override // kotlin.jvm.functions.Function3
                    public final Object invoke(Object obj2, Object obj3, Object obj4) {
                        return MainActivityKt.MetricScreen$lambda$6$3(arrayList2, weather, metric2, z5, (ColumnScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                    }
                }, composer3, 54), composer3, 48, 1);
                composer3.endReplaceGroup();
            }
            ComposerKt.sourceInformationMarkerStart(composer3, 885831314, str);
            boolean zChangedInstance = composer3.changedInstance(context) | (i2 == i4 ? z2 : z3);
            Object objRememberedValue4 = composer3.rememberedValue();
            if (zChangedInstance || objRememberedValue4 == Composer.INSTANCE.getEmpty()) {
                objRememberedValue4 = new Function0() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda43
                    @Override // kotlin.jvm.functions.Function0
                    public final Object invoke() {
                        return MainActivityKt.MetricScreen$lambda$6$6$0(context, metric2);
                    }
                };
                composer3.updateRememberedValue(objRememberedValue4);
            }
            ComposerKt.sourceInformationMarkerEnd(composer3);
            composer2 = composer3;
            ButtonKt.TextButton((Function0) objRememberedValue4, null, false, null, null, null, null, null, null, ComposableLambdaKt.rememberComposableLambda(1934644548, z2, new Function3() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda45
                @Override // kotlin.jvm.functions.Function3
                public final Object invoke(Object obj2, Object obj3, Object obj4) {
                    return MainActivityKt.MetricScreen$lambda$6$7(metric2, (RowScope) obj2, (Composer) obj3, ((Integer) obj4).intValue());
                }
            }, composer3, i3), composer2, 805306368, 510);
            ComposerKt.sourceInformationMarkerEnd(composer2);
            ComposerKt.sourceInformationMarkerEnd(composer2);
            composer2.endNode();
            ComposerKt.sourceInformationMarkerEnd(composer2);
            ComposerKt.sourceInformationMarkerEnd(composer2);
            ComposerKt.sourceInformationMarkerEnd(composer2);
            if (ComposerKt.isTraceInProgress()) {
                ComposerKt.traceEventEnd();
            }
        } else {
            composer2 = composerStartRestartGroup;
            composer2.skipToGroupEnd();
        }
        ScopeUpdateScope scopeUpdateScopeEndRestartGroup = composer2.endRestartGroup();
        if (scopeUpdateScopeEndRestartGroup != null) {
            scopeUpdateScopeEndRestartGroup.updateScope(new Function2() { // from class: dev.kiankonrad.weather.MainActivityKt$$ExternalSyntheticLambda35
                @Override // kotlin.jvm.functions.Function2
                public final Object invoke(Object obj2, Object obj3) {
                    return MainActivityKt.MetricScreen$lambda$7(metric2, weather, z5, function0, i, (Composer) obj2, ((Integer) obj3).intValue());
                }
            });
        }
    }