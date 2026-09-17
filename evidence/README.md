# Evidence provenance

`current/` contains files produced or recorded in the current continuation on 2026-09-17. `FINAL_AUDIT_REPORT.json` is the summary and distinguishes all stages. Its final-archive receipt is delivered separately so the ZIP hash and post-packaging checks do not create a self-referential manifest.

The older submission ZIP is kept verbatim under `history/`; it is not counted as a current execution. The seven environment ZIPs were checked against their expected hashes before restoration, as recorded in `current/input_environment_validation.json` and `restore.log`.

Same-kernel replay and the project-authored exact-type gate are not a second independent checker. No official reviewer identity, signature, public-source timestamp, safe-version certification or award approval is fabricated.
