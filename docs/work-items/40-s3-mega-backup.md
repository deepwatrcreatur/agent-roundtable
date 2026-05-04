# 40 — S3/Mega Backup Strategy

## Status: `ready`

## Objective
Implement a multi-layered, sovereign backup strategy for the discussion state and repository using Mega S4 (S3-compatible) and rclone.

## Rationale
The discussion state is part of the project's intellectual capital and must be protected from infrastructure failure. We will leverage the owner's Mega S4 subscription to ensure that every fork and deliberation remains self-contained and recoverable.

## Requirements
- [ ] Configure `dolt remote add mega s3://...` using `ex_aws_s3` credentials.
- [ ] Implement `Roundtable.Backup.DoltPush` GenServer to automate nightly pushes.
- [ ] Add a `systemd` timer to the NixOS module for nightly `rclone sync` of the state directory to Mega.
- [ ] Expose "Backup Health" metrics to the Phoenix dashboard.
- [ ] Document the disaster recovery process (how to restore from a Mega backup).

## Verification
- [ ] Manual test: Perform a `dolt push mega` and verify that the database chunks appear in the Mega S4 bucket.
- [ ] Verify that `rclone sync` correctly mirrors the Git/JJ history.
- [ ] Perform a successful restore from a Mega S4 snapshot into a fresh LXC.
