# Slip releases (CI/CD)

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **CI** | PR / push to `master` | Maven test + package; VERSION consistency check |
| **Release** | Manual (`workflow_dispatch`) | Bump `VERSION` (patch/minor/major or exact), update Maven + iOS versions, regenerate notes/`CHANGELOG.md`, commit, tag `vX.Y.Z`, push |
| **Publish** | Push of tag `v*` (or manual re-publish) | Build jar, zip templates, create GitHub Release + notes, `mvn deploy` to GitHub Packages, push `ghcr.io/abhiudayg/slip-pass-engine` |

## Cut a release

1. Merge what you want on `master`.
2. GitHub → **Actions** → **Release** → **Run workflow**
   - bump: `patch` / `minor` / `major`, or set exact `version` (e.g. `1.1.0`)
3. Wait for **Release** (tag) then **Publish** (assets + packages).

Locally (equivalent bump only):

```bash
./scripts/version.sh bump patch   # or: ./scripts/version.sh set 1.2.0
./scripts/generate-release-notes.sh
git add -A && git commit -m "chore(release): v$(cat VERSION)"
git tag -a "v$(cat VERSION)" -F RELEASE_NOTES.md
git push origin master --tags
```

## Consuming packages

### Maven (GitHub Packages)

`~/.m2/settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GH_USERNAME</username>
      <password>YOUR_GH_PAT_WITH_read:packages</password>
    </server>
  </servers>
</settings>
```

```xml
<dependency>
  <groupId>com.slip</groupId>
  <artifactId>pass-engine</artifactId>
  <version>1.0.0</version>
</dependency>
```

Repository URL: `https://maven.pkg.github.com/abhiudayg/slip`

### Container

```bash
docker pull ghcr.io/abhiudayg/slip-pass-engine:1.0.0
docker run --rm -p 8080:8080 ghcr.io/abhiudayg/slip-pass-engine:1.0.0
```

### Release assets

From the GitHub Release page: `pass-engine-X.Y.Z.jar` and `slip-templates-X.Y.Z.zip`.

## Version sources of truth

- `VERSION` — canonical semver
- `pass-engine/pom.xml` — Maven artifact version
- `ios/project.yml` `MARKETING_VERSION` — App Store marketing version (`CURRENT_PROJECT_VERSION` auto-increments on bump)

Use `./scripts/version.sh` to keep them aligned.
