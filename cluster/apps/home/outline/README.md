# Documentation

## Outline

## S3 Configuration

1. Create the Minio CLI configuration file (`~/.mc/config.json`)
    ```sh
    mc alias set minio https://s3.<domain> <access-key> <secret-key>
    ```

2. Create the outline user and password
    ```sh
    mc admin user add minio outline <super-secret-password>
    ```

3. Create the outline bucket
    ```sh
    mc mb minio/outline
    ```

4. Create `/tmp/outline-user-policy.json`
    ```json
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
                "Resource": ["arn:aws:s3:::outline/*", "arn:aws:s3:::outline"],
                "Sid": ""
            }
        ]
    }
    ```

5. Create `/tmp/outline-bucket-policy.json`
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetBucketLocation"
                ],
                "Resource": [
                    "arn:aws:s3:::outline"
                ]
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::outline"
                ],
                "Condition": {
                    "StringEquals": {
                        "s3:prefix": [
                            "avatars",
                            "public"
                        ]
                    }
                }
            },
            {
                "Effect": "Allow",
                "Principal": {
                    "AWS": [
                        "*"
                    ]
                },
                "Action": [
                    "s3:GetObject"
                ],
                "Resource": [
                    "arn:aws:s3:::outline/avatars*",
                    "arn:aws:s3:::outline/public*"
                ]
            }
        ]
    }
    ```

6. Apply the bucket policies
    ```sh
    mc admin policy add minio outline-private /tmp/outline-user-policy.json
    ```

7. Associate private policy with the user
    ```sh
    mc admin policy set minio outline-private user=outline
    ```

8. Associate public policy with the bucket
    ```sh
    mc anonymous set-json /tmp/outline-bucket-policy.json minio/outline
    ```
