    /* JADX INFO: Access modifiers changed from: private */
    public final String read(String name) {
        Object objM8871constructorimpl;
        try {
            Result.Companion companion = Result.INSTANCE;
            OpenWeatherRepository openWeatherRepository = this;
            FileInputStream fileInputStreamOpenRead = new AtomicFile(new File(this.directory, name)).openRead();
            Intrinsics.checkNotNullExpressionValue(fileInputStreamOpenRead, "openRead(...)");
            Reader inputStreamReader = new InputStreamReader(fileInputStreamOpenRead, Charsets.UTF_8);
            BufferedReader bufferedReader = inputStreamReader instanceof BufferedReader ? (BufferedReader) inputStreamReader : new BufferedReader(inputStreamReader, 8192);
            try {
                String text = TextStreamsKt.readText(bufferedReader);
                CloseableKt.closeFinally(bufferedReader, null);
                objM8871constructorimpl = Result.m8871constructorimpl(text);
            } catch (Throwable th) {
                try {
                    throw th;
                } catch (Throwable th2) {
                    CloseableKt.closeFinally(bufferedReader, th);
                    throw th2;
                }
            }
        } catch (Throwable th3) {
            Result.Companion companion2 = Result.INSTANCE;
            objM8871constructorimpl = Result.m8871constructorimpl(ResultKt.createFailure(th3));
        }
        return (String) (Result.m8877isFailureimpl(objM8871constructorimpl) ? null : objM8871constructorimpl);
    }