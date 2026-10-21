# Key wrapping, share protection and signing

The signer key module creates a symmetric KMS envelope key. Its runtime statements permit Encrypt, Decrypt and GenerateDataKey only with `custody:domain=<domain>` and `custody:purpose=share-envelope`. They do not permit policy changes or grant creation. Rotation is enabled; deletion has a 30-day window. Non-signer hosts do not receive this signer envelope key.

**This does not implement threshold signing inside KMS.** An authorized host can unwrap material and hold it in memory. A compromised live signer can then exercise that share; changing storage encryption does not repair that boundary.

At the pinned Quorum Custody revision, [native/signer.cpp](https://github.com/demis1997/quorum-custody/blob/691e253ccdc2756afe215a23384eb72e2d4fde3c/native/signer.cpp) decrypts a serialized `buf_t key` in the host process and calls `ecdsa_mp::sign_ac`; DKG uses `ecdsa_mp::dkg_ac`. That is the actual integration surface. No native source is modified or cryptographic algorithm reimplemented by this lab.

[KMS Sign](https://docs.aws.amazon.com/kms/latest/APIReference/API_Sign.html) is an operation over a managed asymmetric key and a message/digest. [CloudHSM's PKCS #11 mechanisms](https://docs.aws.amazon.com/cloudhsm/latest/userguide/pkcs11-mechanisms.html) expose enumerated operations. Ordinary ECDSA support does not establish that either API can execute cb-mpc's arbitrary secret-share arithmetic, preprocessing, serialization and protocol state. A supported curve is not a protocol integration.

Before hardware work, map every secret operation, randomness source, key buffer, serialization boundary, recovery path and required SDK mechanism. Distinguish envelope encryption, non-MPC approval/TLS keys and actual hardware-resident MPC. A no-go result is useful evidence. CloudHSM, Nitro Enclaves and hardware-backed approval keys are evaluated research options, not implemented modules or tested protections.

The Python experiments use random synthetic HMAC keys only to detect altered fixtures. Those HMACs are not threshold signatures and do not represent a production approval-key architecture. No private fixture key is logged or committed.
