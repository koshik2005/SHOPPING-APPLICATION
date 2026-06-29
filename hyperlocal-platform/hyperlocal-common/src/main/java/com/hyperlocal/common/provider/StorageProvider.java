package com.hyperlocal.common.provider;

import java.io.InputStream;

public interface StorageProvider {
    String uploadFile(String bucketName, String objectName, InputStream inputStream, String contentType);
    void deleteFile(String bucketName, String objectName);
}
