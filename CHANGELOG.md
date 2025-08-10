# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-08-10

### Added
- 🚀 **Initial MVP Release**
- ✅ Intelligent NixOS flake service detection (OpenSSH, k3s, Docker, nginx)
- ✅ Multi-stage testing pipeline (flake validation, build testing, service verification)
- ✅ GitHub Actions integration with PR status checks
- ✅ Rich reporting with JSON and GitHub output formats
- ✅ Configurable testing behavior via `.nix-runner.yaml`
- ✅ Support for both simple and modularized flake structures
- ✅ Infrastructure-agnostic design (works with local VMs, cloud, physical servers)
- ✅ Comprehensive documentation and examples
- ✅ MIT license for FOSS compatibility

### Features
- **Smart Service Detection**: Automatically detects enabled services from NixOS configurations
- **Flexible Testing**: Supports simulation mode for MVP, with architecture for real deployment testing
- **Easy Integration**: Simple GitHub Action with minimal configuration required
- **Modular Support**: Works seamlessly with complex, multi-file flake structures
- **Community Ready**: Designed for adoption across the NixOS ecosystem

### Examples Included
- Simple server configuration (SSH + nginx)
- k3s cluster configuration (SSH + k3s + Docker)
- Modularized server (demonstrates complex flake structures)

### Technical Details
- Uses `nix eval` for accurate service detection from resolved configurations
- Container-based testing environment using GitHub Actions services
- Comprehensive error handling and cleanup mechanisms
- Token-efficient design suitable for GitHub Actions limits

## Roadmap

### [1.1.0] - Coming Soon
- [ ] Real deployment testing with nixos-anywhere integration
- [ ] Container-based test environments for isolated testing
- [ ] Additional service detections (PostgreSQL, Redis, etc.)

### [1.2.0] - Future
- [ ] Performance benchmarking capabilities
- [ ] Multi-platform support (ARM, etc.)
- [ ] Integration with popular NixOS configurations

---

**Note**: This is an MVP release focusing on flake validation and service detection. Real deployment testing capabilities are planned for future releases.