#!/bin/bash
set -euo pipefail

FLAKE_PATH="${1:-}"

echo "Running build tests for flake at: $FLAKE_PATH"

# Create results directory
mkdir -p /tmp/nix-runner/results

# Function to run nix flake check
run_flake_check() {
    local flake_path="$1"
    local result_file="/tmp/nix-runner/results/flake_check.json"
    
    echo "Running 'nix flake check'..."
    
    if nix flake check "$flake_path" --no-build --show-trace 2>&1 | tee /tmp/nix-runner/flake_check.log; then
        echo '{"status": "success", "message": "Flake check passed"}' > "$result_file"
        echo "✅ Flake check: PASSED"
    else
        echo '{"status": "failure", "message": "Flake check failed", "log": "See flake_check.log"}' > "$result_file"
        echo "❌ Flake check: FAILED"
        cat /tmp/nix-runner/flake_check.log
        return 1
    fi
}

# Function to test NixOS configurations build
test_nixos_builds() {
    local flake_path="$1"
    local result_file="/tmp/nix-runner/results/nixos_build.json"
    
    echo "Testing NixOS configuration builds..."
    
    if [[ -f "/tmp/nix-runner/config_names.txt" ]]; then
        local failed_builds=0
        local total_builds=0
        local build_results="[]"
        
        while IFS= read -r config_name; do
            echo "Building NixOS configuration: $config_name"
            total_builds=$((total_builds + 1))
            
            if nix build "$flake_path#nixosConfigurations.$config_name.config.system.build.toplevel" --dry-run --show-trace 2>&1 | tee "/tmp/nix-runner/build_$config_name.log"; then
                echo "✅ Build test for $config_name: PASSED"
                build_results=$(echo "$build_results" | jq --arg name "$config_name" '. += [{"name": $name, "status": "success"}]')
            else
                echo "❌ Build test for $config_name: FAILED"
                failed_builds=$((failed_builds + 1))
                build_results=$(echo "$build_results" | jq --arg name "$config_name" '. += [{"name": $name, "status": "failure"}]')
            fi
        done < /tmp/nix-runner/config_names.txt
        
        if [[ $failed_builds -eq 0 ]]; then
            echo "{\"status\": \"success\", \"total\": $total_builds, \"failed\": $failed_builds, \"builds\": $build_results}" > "$result_file"
            echo "✅ All NixOS configurations build successfully"
        else
            echo "{\"status\": \"failure\", \"total\": $total_builds, \"failed\": $failed_builds, \"builds\": $build_results}" > "$result_file"
            echo "❌ $failed_builds out of $total_builds builds failed"
            return 1
        fi
    else
        echo "No NixOS configurations found to build"
        echo '{"status": "skipped", "message": "No NixOS configurations found"}' > "$result_file"
    fi
}

# Main execution
main() {
    echo "Starting build tests..."
    
    local exit_code=0
    
    # Run flake check
    if ! run_flake_check "$FLAKE_PATH"; then
        exit_code=1
    fi
    
    # Test NixOS builds
    if ! test_nixos_builds "$FLAKE_PATH"; then
        exit_code=1
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ All build tests passed!"
    else
        echo "❌ Some build tests failed!"
    fi
    
    return $exit_code
}

main "$@"