# XMLSign PowerShell Module Build Script

This repository includes a PowerShell build script (`Build.ps1`) that automates the module build process following PowerShell module best practices.

## Features

- **Automatic Version Management**: Increments version numbers automatically or accepts custom versions
- **Function Discovery**: Automatically scans the `Public/` folder for PowerShell functions to export
- **Manifest Updates**: Updates the module manifest (`.psd1`) with new version and function exports
- **Build Output**: Creates versioned builds in the `bin/` folder structure
- **Validation**: Tests the built module manifest for validity

## Usage

### Basic Build (Patch Version Increment)
```powershell
.\Build.ps1
```
This increments the patch version (e.g., 1.0.0 → 1.0.1)

### Minor Version Increment
```powershell
.\Build.ps1 -IncrementMinor
```
This increments the minor version and resets patch to 0 (e.g., 1.0.5 → 1.1.0)

### Major Version Increment
```powershell
.\Build.ps1 -IncrementMajor
```
This increments the major version and resets minor and patch to 0 (e.g., 1.2.3 → 2.0.0)

### Specific Version
```powershell
.\Build.ps1 -BuildVersion "2.1.0"
```
This sets a specific version number

## Build Output Structure

The build creates the following structure:
```
bin/
├── 1.0.1/
│   └── XMLSign/
│       ├── Private/
│       ├── Public/
│       ├── XMLSign.psd1
│       └── XMLSign.psm1
├── 1.1.0/
│   └── XMLSign/
└── 2.0.0/
    └── XMLSign/
```

## What the Build Script Does

1. **Version Management**: Reads the current version from the module manifest and calculates the new version
2. **Function Scanning**: Scans all `.ps1` files in the `Public/` folder for function declarations
3. **Manifest Updates**: Updates the module manifest with:
   - New version number
   - List of functions to export (from Public folder scan)
   - Build timestamp in release notes
4. **Module Copying**: Copies the entire module structure to `bin/$version/$modulename/`
5. **Validation**: Tests the built module manifest for validity (when dependencies are available)

## Git Integration

The `bin/` folder is automatically excluded from version control via `.gitignore`, so build artifacts won't be committed to the repository.

## Requirements

- PowerShell 5.1 or later
- The build script expects a standard PowerShell module structure:
  ```
  ModuleName/
  ├── ModuleName.psd1  # Module manifest
  ├── ModuleName.psm1  # Main module file
  ├── Public/          # Exported functions
  └── Private/         # Internal functions
  ```