# S3 buckets

Alternatively creating s3 buckets can be automated with Terraform.

## b2

```admonish info
This requires installing the Backblaze `b2` CLI tool
```

### Creating a bucket

1. Create master `key-id` and `key` on <ins>[Account > App Keys](https://secure.backblaze.com/app_keys.htm)</ins>

2. Export settings
    ```sh
    export B2_APPLICATION_KEY_ID="<key-id>"
    export B2_APPLICATION_KEY="<key>"
    export B2_BUCKET_NAME="<bucket-name>"
    ```

3. Create the bucket
    ```sh
    b2 create-bucket "${B2_BUCKET_NAME}" allPrivate \
      --defaultServerSideEncryption "SSE-B2"  \
      --lifecycleRules '[{"daysFromHidingToDeleting": 1,"daysFromUploadingToHiding": null,"fileNamePrefix": ""}]'
    ```

4. Create the bucket username and password
    ```sh
    b2 create-key --bucket "${B2_BUCKET_NAME}" "${B2_BUCKET_NAME}" \
      deleteFiles,listAllBucketNames,listBuckets,listFiles,readBucketEncryption,readBucketReplications,readBuckets,readFiles,shareFiles,writeBucketEncryption,writeBucketReplications,writeFiles
    ```
