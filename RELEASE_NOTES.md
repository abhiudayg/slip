## Slip v1.0.0

Compare: `3fa731cd67c47fb326a4250221af6f7b80256f61` → `HEAD`

### Features

- feat(ios): configure TestFlight signing, API URL, and archive helper
- feat(catalog): expand default brand pack and retire Cult
- feat(ios): add Slip app, vault, and share extension
- feat(pass-engine): add Spring Boot pkpass signing API

### Chores

- ci: add release notes, GitHub Release, and package publish workflows
- docs: refresh README for public Slip layout and deploy

### Other

- chore(deploy): add Neon and OCI Always Free deploy scripts

### Packages

- `pass-engine-1.0.0.jar` — Spring Boot pass signer
- `slip-templates-1.0.0.zip` — Wallet brand templates
- Maven: `com.slip:pass-engine:1.0.0` (GitHub Packages)
- Container: `ghcr.io/abhiudayg/slip-pass-engine:1.0.0`

### Install / run

```bash
java -jar pass-engine-1.0.0.jar
# or
docker pull ghcr.io/abhiudayg/slip-pass-engine:1.0.0
```
