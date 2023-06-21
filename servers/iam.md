

# policy for iam-mfa-only
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Deny",
            "Action": "iam:*",
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Deny",
            "Action": "iam:*",
            "Resource": "*",
            "Condition": {
                "NumericGreaterThan": {
                    "aws:MultiFactorAuthAge": 600
                }
            }
        }
    ]
}
```

# policy for kms-mfa-only
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Deny",
            "Action": [
                "kms:EnableKey",
                "kms:ImportKeyMaterial",
                "kms:Decrypt",
                "kms:GenerateRandom",
                "kms:GenerateDataKeyWithoutPlaintext",
                "kms:Verify",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:GenerateDataKeyPair",
                "kms:SynchronizeMultiRegionKey",
                "kms:DeleteCustomKeyStore",
                "kms:UpdatePrimaryRegion",
                "kms:UpdateCustomKeyStore",
                "kms:Encrypt",
                "kms:ScheduleKeyDeletion",
                "kms:ReEncryptTo",
                "kms:CreateKey",
                "kms:ConnectCustomKeyStore",
                "kms:Sign",
                "kms:EnableKeyRotation",
                "kms:UpdateKeyDescription",
                "kms:DeleteImportedKeyMaterial",
                "kms:GenerateDataKeyPairWithoutPlaintext",
                "kms:DisableKey",
                "kms:ReEncryptFrom",
                "kms:DisableKeyRotation",
                "kms:UpdateAlias",
                "kms:CreateCustomKeyStore",
                "kms:GenerateDataKey",
                "kms:CreateAlias",
                "kms:DisconnectCustomKeyStore",
                "kms:DeleteAlias"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Deny",
            "Action": [
                "kms:EnableKey",
                "kms:ImportKeyMaterial",
                "kms:Decrypt",
                "kms:GenerateRandom",
                "kms:GenerateDataKeyWithoutPlaintext",
                "kms:Verify",
                "kms:CancelKeyDeletion",
                "kms:ReplicateKey",
                "kms:GenerateDataKeyPair",
                "kms:SynchronizeMultiRegionKey",
                "kms:DeleteCustomKeyStore",
                "kms:UpdatePrimaryRegion",
                "kms:UpdateCustomKeyStore",
                "kms:Encrypt",
                "kms:ScheduleKeyDeletion",
                "kms:ReEncryptTo",
                "kms:CreateKey",
                "kms:ConnectCustomKeyStore",
                "kms:Sign",
                "kms:EnableKeyRotation",
                "kms:UpdateKeyDescription",
                "kms:DeleteImportedKeyMaterial",
                "kms:GenerateDataKeyPairWithoutPlaintext",
                "kms:DisableKey",
                "kms:ReEncryptFrom",
                "kms:DisableKeyRotation",
                "kms:UpdateAlias",
                "kms:CreateCustomKeyStore",
                "kms:GenerateDataKey",
                "kms:CreateAlias",
                "kms:DisconnectCustomKeyStore",
                "kms:DeleteAlias"
            ],
            "Resource": "*",
            "Condition": {
                "NumericGreaterThan": {
                    "aws:MultiFactorAuthAge": 600
                }
            }
        }
    ]
}
```

