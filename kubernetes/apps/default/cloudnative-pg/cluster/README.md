# S3 buckets

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
      listBuckets,listFiles,readBucketEncryption,readBucketReplications,readBucketRetentions,readBuckets,readFileLegalHolds,readFileRetentions,readFiles,writeFileRetentions,writeFiles
    ```

## Minio

```admonish info
This requires installing the Minio `mc` CLI tool
```

### Creating a Bucket

1. Create the Minio CLI configuration file (`~/.mc/config.json`)
    ```sh
    mc alias set minio "https://s3.<domain>.<tld>" "<access-key>" "<secret-key>"
    ```

2. Export settings
    ```sh
    export BUCKET_NAME="<bucket-name>" # also used for the bucket username
    export BUCKET_PASSWORD="$(openssl rand -hex 20)"
    echo $BUCKET_PASSWORD
    ```

3. Create the bucket username and password
    ```sh
    mc admin user add minio "${BUCKET_NAME}" "${BUCKET_PASSWORD}"
    ```

4. Create the bucket
    ```sh
    mc mb "minio/${BUCKET_NAME}"
    ```

5. Create the user policy document
    ```sh
    cat <<EOF > /tmp/user-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": [
                    "s3:ListBucket",
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObject"
                ],
                "Effect": "Allow",
                "Resource": ["arn:aws:s3:::${BUCKET_NAME}/*", "arn:aws:s3:::${BUCKET_NAME}"],
                "Sid": ""
            }
        ]
    }
    EOF
    ```

6. Apply the bucket policies
    ```sh
    mc admin policy add minio "${BUCKET_NAME}-private" /tmp/user-policy.json
    ```

7. Associate private policy with the user
    ```sh
    mc admin policy set minio "${BUCKET_NAME}-private" "user=${BUCKET_NAME}"
    ```
