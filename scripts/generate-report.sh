#!/bin/bash
set -euo pipefail

echo "Generating test report..."

# Create report directory
mkdir -p /tmp/nix-runner/reports

# Function to generate JSON report
generate_json_report() {
    local json_report="/tmp/nix-runner/reports/test-report.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "Creating JSON report..."
    
    # Initialize report structure
    cat > "$json_report" << EOF
{
  "timestamp": "$timestamp",
  "version": "1.0.0",
  "status": "unknown",
  "summary": {
    "total_tests": 0,
    "passed": 0,
    "failed": 0,
    "skipped": 0
  },
  "stages": {},
  "services_detected": []
}
EOF
    
    # Add detected services
    if [[ -f "/tmp/nix-runner/detected_services.json" ]]; then
        local services
        services=$(jq -c '.services' /tmp/nix-runner/detected_services.json 2>/dev/null || echo "[]")
        jq --argjson services "$services" '.services_detected = $services' "$json_report" > /tmp/report.tmp && mv /tmp/report.tmp "$json_report"
    fi
    
    # Process results from each stage
    local overall_status="success"
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local skipped_tests=0
    
    # Flake check results
    if [[ -f "/tmp/nix-runner/results/flake_check.json" ]]; then
        local flake_result
        flake_result=$(cat /tmp/nix-runner/results/flake_check.json)
        jq --argjson result "$flake_result" '.stages.flake_check = $result' "$json_report" > /tmp/report.tmp && mv /tmp/report.tmp "$json_report"
        
        if [[ $(echo "$flake_result" | jq -r '.status') == "failure" ]]; then
            overall_status="failure"
            failed_tests=$((failed_tests + 1))
        else
            passed_tests=$((passed_tests + 1))
        fi
        total_tests=$((total_tests + 1))
    fi
    
    # NixOS build results
    if [[ -f "/tmp/nix-runner/results/nixos_build.json" ]]; then
        local nixos_result
        nixos_result=$(cat /tmp/nix-runner/results/nixos_build.json)
        jq --argjson result "$nixos_result" '.stages.nixos_build = $result' "$json_report" > /tmp/report.tmp && mv /tmp/report.tmp "$json_report"
        
        local build_status
        build_status=$(echo "$nixos_result" | jq -r '.status')
        if [[ "$build_status" == "failure" ]]; then
            overall_status="failure"
            failed_tests=$((failed_tests + $(echo "$nixos_result" | jq -r '.failed // 0')))
            passed_tests=$((passed_tests + $(echo "$nixos_result" | jq -r '(.total // 0) - (.failed // 0)')))
        elif [[ "$build_status" == "success" ]]; then
            passed_tests=$((passed_tests + $(echo "$nixos_result" | jq -r '.total // 1')))
        else
            skipped_tests=$((skipped_tests + 1))
        fi
        total_tests=$((total_tests + $(echo "$nixos_result" | jq -r '.total // 1')))
    fi
    
    # Service test results
    if [[ -f "/tmp/nix-runner/results/service_tests.json" ]]; then
        local service_result
        service_result=$(cat /tmp/nix-runner/results/service_tests.json)
        jq --argjson result "$service_result" '.stages.service_tests = $result' "$json_report" > /tmp/report.tmp && mv /tmp/report.tmp "$json_report"
        
        if [[ $(echo "$service_result" | jq -r '.status') == "failure" ]]; then
            overall_status="failure"
            failed_tests=$((failed_tests + $(echo "$service_result" | jq -r '.failed // 0')))
        elif [[ $(echo "$service_result" | jq -r '.status') == "success" ]]; then
            passed_tests=$((passed_tests + $(echo "$service_result" | jq -r '.total // 0')))
        else
            skipped_tests=$((skipped_tests + 1))
        fi
        total_tests=$((total_tests + $(echo "$service_result" | jq -r '.total // 0')))
    fi
    
    # Update summary
    jq --arg status "$overall_status" \
       --argjson total "$total_tests" \
       --argjson passed "$passed_tests" \
       --argjson failed "$failed_tests" \
       --argjson skipped "$skipped_tests" \
       '.status = $status | .summary.total_tests = $total | .summary.passed = $passed | .summary.failed = $failed | .summary.skipped = $skipped' \
       "$json_report" > /tmp/report.tmp && mv /tmp/report.tmp "$json_report"
    
    echo "JSON report generated: $json_report"
}

# Function to set GitHub outputs
set_github_outputs() {
    local json_report="/tmp/nix-runner/reports/test-report.json"
    
    if [[ -n "${GITHUB_OUTPUT:-}" && -f "$json_report" ]]; then
        echo "Setting GitHub outputs..."
        
        echo "result=$(jq -r '.status' "$json_report")" >> "$GITHUB_OUTPUT"
        echo "services-detected=$(jq -c '.services_detected' "$json_report")" >> "$GITHUB_OUTPUT"
        echo "test-report=$(jq -c '.' "$json_report")" >> "$GITHUB_OUTPUT"
        
        echo "GitHub outputs set successfully"
    fi
}

# Function to create GitHub step summary
create_github_summary() {
    local json_report="/tmp/nix-runner/reports/test-report.json"
    
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" && -f "$json_report" ]]; then
        echo "Creating GitHub step summary..."
        
        local status=$(jq -r '.status' "$json_report")
        # Get unique services with counts for better display
        local services_raw=""
        if [ -f "$GITHUB_WORKSPACE/detected_services.txt" ]; then
            local unique_services=$(sort "$GITHUB_WORKSPACE/detected_services.txt" | uniq)
            local service_display=""
            for service in $unique_services; do
                local count=$(grep -c "^$service$" "$GITHUB_WORKSPACE/detected_services.txt")
                if [ $count -gt 1 ]; then
                    service_display="${service_display}$service (${count} configs), "
                else
                    service_display="${service_display}$service, "
                fi
            done
            services_raw=$(echo "$service_display" | sed 's/, $//')
        else
            services_raw=$(jq -r '.services_detected | join(", ")' "$json_report")
        fi
        local services="$services_raw"
        local passed=$(jq -r '.summary.passed' "$json_report")
        local failed=$(jq -r '.summary.failed' "$json_report")
        
        cat >> "$GITHUB_STEP_SUMMARY" << EOF
# NixOS Flake Test Results

**Status:** $(if [[ "$status" == "success" ]]; then echo "✅ PASSED"; else echo "❌ FAILED"; fi)  
**Services Detected:** $services  
**Tests Passed:** $passed  
**Tests Failed:** $failed  

## Summary

The NixOS flake validation completed with status: **$status**
EOF
        
        echo "GitHub step summary created successfully"
    fi
}

# Main execution
main() {
    echo "Starting report generation..."
    
    generate_json_report
    set_github_outputs
    create_github_summary
    
    echo "Report generation completed successfully"
    
    # Display summary
    if [[ -f "/tmp/nix-runner/reports/test-report.json" ]]; then
        local status
        status=$(jq -r '.status' /tmp/nix-runner/reports/test-report.json)
        
        echo ""
        echo "=========================================="
        echo "TEST SUMMARY"
        echo "=========================================="
        if [[ "$status" == "success" ]]; then
            echo "✅ All tests passed!"
        else
            echo "❌ Some tests failed!"
        fi
        echo "Full report available in: /tmp/nix-runner/reports/"
        echo "=========================================="
    fi
}

main "$@"