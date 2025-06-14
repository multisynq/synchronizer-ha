# Architecture-Specific Image Tagging - FIXED! 🎉

## The Problem
Previously, all architectures were building to the same Docker image tag:
- `ghcr.io/multisynq/synchronizer-ha:1.1.1` 

This meant that when both amd64 and aarch64 built, one would overwrite the other.

## The Solution
Updated the `config.yaml` to use the `{arch}` placeholder:

```yaml
image: "ghcr.io/multisynq/{arch}-synchronizer-ha"
```

## How It Works Now

The Home Assistant builder automatically replaces `{arch}` with the actual architecture during build:

### For AMD64 builds:
- Image: `ghcr.io/multisynq/amd64-synchronizer-ha:1.1.1`
- Tag: `ghcr.io/multisynq/amd64-synchronizer-ha:latest`

### For AARCH64 builds:
- Image: `ghcr.io/multisynq/aarch64-synchronizer-ha:1.1.1`
- Tag: `ghcr.io/multisynq/aarch64-synchronizer-ha:latest`

## Multi-Architecture Support

Home Assistant will automatically:
1. **Select the correct architecture** when users install the addon
2. **Pull the appropriate image** for their system (Raspberry Pi = aarch64, Intel/AMD = amd64)
3. **Manage the architecture manifests** so users don't need to know which one to use

## Files Updated

1. **`config.yaml`**: 
   - Changed `image: "ghcr.io/multisynq/synchronizer-ha"` 
   - To `image: "ghcr.io/multisynq/{arch}-synchronizer-ha"`

2. **`build.yml`**: 
   - Updated workflow to use the correct builder pattern
   - Uses `--all` flag to build all supported architectures

## Verification

After you copy these files to your repository and push to main:

1. **Check GitHub Actions**: You should see separate builds for each architecture
2. **Check GitHub Container Registry**: You should see:
   - `ghcr.io/multisynq/amd64-synchronizer-ha`
   - `ghcr.io/multisynq/aarch64-synchronizer-ha`
3. **Test in Home Assistant**: The addon should install correctly on both x86 and ARM systems

## Benefits

✅ **No more overwrites**: Each architecture gets its own image tag  
✅ **Automatic selection**: Home Assistant picks the right architecture  
✅ **Better compatibility**: Works on Raspberry Pi, Intel NUC, etc.  
✅ **Follows best practices**: Uses the same pattern as official Home Assistant addons  

This follows the exact same pattern used by the official Home Assistant example addon and all Community Add-ons!
