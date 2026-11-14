    /* JADX INFO: Access modifiers changed from: private */
    public final String get(String endpoint, Map<String, String> params) throws IOException {
        String strString;
        HttpUrl.Builder builderNewBuilder = HttpUrl.INSTANCE.get(endpoint).newBuilder();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            builderNewBuilder.addQueryParameter(entry.getKey(), entry.getValue());
        }
        Response responseExecute = this.client.newCall(new Request.Builder().url(builderNewBuilder.build()).build()).execute();
        try {
            Response response = responseExecute;
            if (!response.isSuccessful()) {
                throw new IOException(response.code() == 429 ? "The weather provider is busy. Please try again later." : "Weather data could not be loaded (" + response.code() + ").");
            }
            ResponseBody responseBodyBody = response.body();
            if (responseBodyBody != null && (strString = responseBodyBody.string()) != null) {
                CloseableKt.closeFinally(responseExecute, null);
                return strString;
            }
            throw new IOException("The weather provider returned no data.");
        } catch (Throwable th) {
            try {
                throw th;
            } catch (Throwable th2) {
                CloseableKt.closeFinally(responseExecute, th);
                throw th2;
            }
        }
    }