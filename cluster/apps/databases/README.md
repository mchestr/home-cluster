# Databases

## Backblaze Setup

This will set up replication to have your postgres backups sent to a [backblaze](https://www.backblaze.com/) b2 bucket.

1. Create master `key-id` and `key` on [Account > App Keys](https://secure.backblaze.com/app_keys.htm)

2. Create a `bucket`, and then a `key-id` and `key` for access only to this new bucket
    ```sh
    export B2_APPLICATION_KEY_ID="<master-key-id>"
    export B2_APPLICATION_KEY="<master-key>"
    export B2_BUCKET_NAME="<bucket-name>"
    b2 create-bucket $B2_BUCKET_NAME allPrivate --defaultServerSideEncryption "SSE-B2"  --lifecycleRules '[{"daysFromHidingToDeleting": 1,"daysFromUploadingToHiding": null,"fileNamePrefix": ""}]'
    b2 create-key --bucket $B2_BUCKET_NAME $B2_BUCKET_NAME listBuckets,readBuckets,listFiles,readFiles,writeFiles,readBucketEncryption,readBucketReplications,readBucketRetentions,readFileRetentions,writeFileRetentions,readFileLegalHolds
    ```

3. Create `secret.sops.yaml` for Postgres to use for s3 replication and reference key created in step 2.
