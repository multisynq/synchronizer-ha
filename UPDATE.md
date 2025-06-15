# Release Update Checklist

For updates, please ensure to update the version in **ALL** of the following files:

## Required Version Updates
1. **`CHANGELOG.md`** - Add new version entry with changes
2. **`config.yaml`** - Update the `version` field (used for local development)
3. **`config.production.yaml`** - Update the `version` field (used by CI/CD build process)
4. **`Dockerfile`** - Update the `io.hass.version` label
5. **`run.sh`** - Update the `ADDON_VERSION` variable

## Critical Notes
- ⚠️ **The CI/CD build uses `config.production.yaml`**
- The build process runs `cp config.production.yaml config.yaml` before building
- Both config files must have matching versions for consistency
- **Port 8099** is used for the web dashboard panel
- Web UI is accessible via the "OPEN WEB UI" button in Home Assistant
- **Lite Mode**: Users can disable web UI and metrics via `lite_mode: true` configuration

## Release Process
1. Update all version numbers in the files listed above
2. Commit and push your changes to the main branch
3. This will automatically trigger the GitHub Actions workflow
4. The workflow will create a new release with the updated version
5. Docker images will be built and pushed to `ghcr.io/multisynq/{arch}-synchronizer-ha:NEW_VERSION`

## Version Schema
Follow semantic versioning (semver):
- **Major** (x.0.0): Breaking changes
- **Minor** (x.y.0): New features, backward compatible
- **Patch** (x.y.z): Bug fixes, backward compatible

This ensures that users can easily see what has changed and that the add-on is properly versioned across all environments.