# NixOS Flake Runner

🚀 Automated CI/CD for NixOS flakes with intelligent service detection and testing.

## Overview

NixOS Flake Runner is a GitHub Action that automatically tests your NixOS flakes by:

- 🔍 **Smart Detection**: Automatically detects services (SSH, k3s, Docker, nginx) from your flake configuration
- 🧪 **Comprehensive Testing**: Runs `nix flake check`, build tests, and service validation  
- 📊 **Rich Reporting**: Provides detailed test reports with GitHub integration
- 🔧 **Configurable**: Customize test behavior with `.nix-runner.yaml`

## Quick Start

### 1. Add to your NixOS flake repository

Create `.github/workflows/test-flake.yml`:

```yaml
name: Test NixOS Flake

on:
  pull_request:
    branches: [ main ]
    paths: [ '**.nix', 'flake.nix', 'flake.lock' ]

jobs:
  test-flake:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: your-username/nix-runner@v1
        with:
          flake-path: '.'
          skip-deployment: 'true'  # Only build tests for PRs
```

### 2. Optional: Configure testing behavior

Create `.nix-runner.yaml` in your repository root:

```yaml
tests:
  openssh:
    enabled: true
    port: 22
  k3s:
    enabled: true
    timeout: 60
deployment:
  timeout: 300
  cleanup: true
```

### 3. Push changes

The action will automatically:
- Parse your `flake.nix` and detect enabled services
- Run `nix flake check` and build validation
- Test service connectivity (simulation mode in MVP)
- Generate comprehensive reports

## Features

### 🎯 Intelligent Service Detection

The runner automatically detects common NixOS services from your flake configuration:

```nix
# flake.nix
{
  nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
    modules = [{
      services.openssh.enable = true;  # ← Detected automatically
      services.k3s.enable = true;      # ← Detected automatically
      services.nginx.enable = true;    # ← Detected automatically
    }];
  };
}
```

### 🧪 Multi-Stage Testing

1. **Flake Validation**: `nix flake check` ensures your flake is well-formed
2. **Build Testing**: Validates that all configurations build successfully
3. **Service Testing**: Connectivity and health checks for detected services (simulation mode)

### 📊 Rich Reporting

- GitHub PR status checks
- Detailed test reports with service breakdown
- Failed build logs and debugging information

## Configuration Reference

### Action Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `flake-path` | Path to flake.nix | No | `.` |
| `config-file` | Path to .nix-runner.yaml | No | `.nix-runner.yaml` |
| `test-timeout` | Test timeout in seconds | No | `300` |
| `skip-deployment` | Skip deployment testing | No | `false` |

### Configuration File (.nix-runner.yaml)

```yaml
# Service test configuration
tests:
  openssh:
    enabled: true
    port: 22
    timeout: 30
  k3s:
    enabled: true
    timeout: 60
    api_port: 6443

# Deployment settings  
deployment:
  timeout: 300
  cleanup: true

# Environment configuration
environment:
  use_containers: true
  container_image: "nixos/nix:latest"
```

## Examples

### Basic PR Validation

```yaml
# .github/workflows/pr-validation.yml
name: Validate PR
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: your-username/nix-runner@v1
        with:
          skip-deployment: 'true'
```

### Multi-Configuration Testing

```yaml
# .github/workflows/matrix-test.yml
name: Matrix Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        config: [server, desktop, minimal]
    steps:
      - uses: actions/checkout@v4
      - uses: your-username/nix-runner@v1
        with:
          flake-path: './configs/${{ matrix.config }}'
```

## Supported Services

Currently auto-detected services:

- ✅ **OpenSSH**: Connection testing, authentication validation
- ✅ **k3s**: API connectivity, cluster health checks  
- ✅ **Docker**: API connectivity, daemon status
- ✅ **nginx**: HTTP connectivity, health endpoints

## Development Status

This is currently an **MVP (Minimum Viable Product)** release focusing on:

- ✅ Flake parsing and service detection
- ✅ Build testing and validation  
- ✅ GitHub Actions integration
- ✅ Basic reporting and status checks
- 🚧 Service testing (simulation mode)
- 📋 Real deployment testing (coming soon)
- 📋 Container-based testing (coming soon)
- 📋 nixos-anywhere integration (coming soon)

## Contributing

This is a FOSS project! Contributions welcome:

1. **Bug Reports**: Found an issue? Please report it!
2. **Feature Requests**: What services should we detect next?
3. **Pull Requests**: Help us improve the code
4. **Documentation**: Help make it easier for others to use

## License

MIT License - see LICENSE file for details.

## Roadmap

- [ ] Real deployment testing with nixos-anywhere
- [ ] Container-based test environments  
- [ ] More service detections (PostgreSQL, Redis, etc.)
- [ ] Performance benchmarking
- [ ] Multi-platform support (ARM, etc.)
- [ ] Integration with popular NixOS configurations

---

**Note**: This action is designed to be infrastructure-agnostic and should work with various deployment targets including local VMs, cloud instances, and physical servers.