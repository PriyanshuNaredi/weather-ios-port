    /* JADX INFO: Access modifiers changed from: private */
    public final void write(String name, String content) throws Exception {
        AtomicFile atomicFile = new AtomicFile(new File(this.directory, name));
        FileOutputStream fileOutputStreamStartWrite = atomicFile.startWrite();
        try {
            byte[] bytes = content.getBytes(Charsets.UTF_8);
            Intrinsics.checkNotNullExpressionValue(bytes, "getBytes(...)");
            fileOutputStreamStartWrite.write(bytes);
            atomicFile.finishWrite(fileOutputStreamStartWrite);
        } catch (Exception e) {
            atomicFile.failWrite(fileOutputStreamStartWrite);
            throw e;
        }
    }