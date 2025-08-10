#!/bin/bash
set -euo pipefail

FLAKE_PATH="${1:-}"
CONFIG_FILE="${2:-.nix-runner.yaml}"

echo "Parsing flake at: $FLAKE_PATH"
echo "Using config file: $CONFIG_FILE"

# Create output directory for parsed results
mkdir -p /tmp/nix-runner

# Function to detect services from flake output
detect_services() {
    local flake_path="$1"
    local services_file="/tmp/nix-runner/detected_services.json"
    
    echo "Detecting services from flake configuration..."
    
    # Initialize services array
    echo '{"services": [], "packages": []}' > "$services_file"
    
    # Check if flake.nix exists
    if [[ ! -f "$flake_path/flake.nix" ]]; then
        echo "Error: flake.nix not found at $flake_path"
        exit 1
    fi
    
    # Parse NixOS configuration to detect services
    if nix eval --json "path:$(realpath $flake_path)#nixosConfigurations" --apply 'configs: builtins.attrNames configs' 2>/dev/null | jq -r '.[]' > /tmp/nix-runner/config_names.txt; then
        echo "Found NixOS configurations:"
        cat /tmp/nix-runner/config_names.txt
        
        # For each configuration, try to detect services
        while IFS= read -r config_name; do
            echo "Analyzing configuration: $config_name"
            
            # Check individual services (avoids JSON serialization issues)
            services_to_check=("openssh" "k3s" "docker" "nginx")
            
            for service in "${services_to_check[@]}"; do
                if service_enabled=$(nix eval --json "path:$(realpath $flake_path)#nixosConfigurations.$config_name.config.services.$service.enable" 2>/dev/null); then
                    if [[ "$service_enabled" == "true" ]]; then
                        echo "✓ Detected: $service"
                        jq --arg svc "$service" '.services += [$svc]' "$services_file" > /tmp/services.tmp && mv /tmp/services.tmp "$services_file"
                    else
                        echo "✗ $service: disabled"
                    fi
                else
                    echo "? $service: not configured"
                fi
            done
        done < /tmp/nix-runner/config_names.txt
    else
        echo "No NixOS configurations found, checking for packages..."
        
        # Fallback: check packages for service-related items
        if nix eval --json "path:$(realpath $flake_path)#packages.x86_64-linux" --apply 'pkgs: builtins.attrNames pkgs' 2>/dev/null | jq -r '.[]' | grep -E "(openssh|k3s|docker|nginx)" > /tmp/nix-runner/detected_packages.txt; then
            echo "Detected service-related packages:"
            cat /tmp/nix-runner/detected_packages.txt
            
            while IFS= read -r package; do
                jq --arg pkg "$package" '.packages += [$pkg]' "$services_file" > /tmp/services.tmp && mv /tmp/services.tmp "$services_file"
            done < /tmp/nix-runner/detected_packages.txt
        fi
    fi
    
    # Output detected services
    echo "Services detected:"
    jq -r '.services[]' "$services_file" 2>/dev/null || echo "No services detected"
    
    echo "Packages detected:"
    jq -r '.packages[]' "$services_file" 2>/dev/null || echo "No relevant packages detected"
    
    # Set GitHub output
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "services-detected=$(jq -c '.services' "$services_file")" >> "$GITHUB_OUTPUT"
    fi
}

# Main execution
main() {
    echo "Starting flake parsing..."
    
    detect_services "$FLAKE_PATH"
    
    echo "Flake parsing completed successfully"
}

main "$@"