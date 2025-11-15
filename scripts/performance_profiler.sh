#!/bin/bash

# Performance Profiler Script for Device Lock Finance App
# This script automates performance testing and profiling

PACKAGE_NAME="com.finance.device_admin_app"
MAIN_ACTIVITY=".MainActivity"
OUTPUT_DIR="performance_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "========================================="
echo "Performance Profiler for Device Lock Finance App"
echo "========================================="
echo ""

# Check if device is connected
check_device() {
    echo "Checking for connected device..."
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}Error: No device connected${NC}"
        exit 1
    fi
    echo -e "${GREEN}Device connected${NC}"
    echo ""
}

# Test app startup time
test_startup_time() {
    echo "========================================="
    echo "Testing App Startup Time"
    echo "========================================="
    
    # Force stop app
    adb shell am force-stop "$PACKAGE_NAME"
    sleep 2
    
    # Cold start
    echo "Measuring cold start time..."
    COLD_START=$(adb shell am start -W -n "$PACKAGE_NAME/$MAIN_ACTIVITY" 2>&1 | grep "TotalTime" | awk '{print $2}')
    echo "Cold start time: ${COLD_START}ms"
    
    if [ "$COLD_START" -lt 3000 ]; then
        echo -e "${GREEN}✓ Cold start time is good (< 3s)${NC}"
    elif [ "$COLD_START" -lt 5000 ]; then
        echo -e "${YELLOW}⚠ Cold start time is acceptable (< 5s)${NC}"
    else
        echo -e "${RED}✗ Cold start time is too slow (> 5s)${NC}"
    fi
    
    sleep 3
    
    # Warm start
    echo ""
    echo "Measuring warm start time..."
    adb shell am force-stop "$PACKAGE_NAME"
    sleep 1
    WARM_START=$(adb shell am start -W -n "$PACKAGE_NAME/$MAIN_ACTIVITY" 2>&1 | grep "TotalTime" | awk '{print $2}')
    echo "Warm start time: ${WARM_START}ms"
    
    if [ "$WARM_START" -lt 1500 ]; then
        echo -e "${GREEN}✓ Warm start time is good (< 1.5s)${NC}"
    elif [ "$WARM_START" -lt 2000 ]; then
        echo -e "${YELLOW}⚠ Warm start time is acceptable (< 2s)${NC}"
    else
        echo -e "${RED}✗ Warm start time is too slow (> 2s)${NC}"
    fi
    
    echo ""
    echo "Startup times saved to $OUTPUT_DIR/startup_times_$TIMESTAMP.txt"
    echo "Cold Start: ${COLD_START}ms" > "$OUTPUT_DIR/startup_times_$TIMESTAMP.txt"
    echo "Warm Start: ${WARM_START}ms" >> "$OUTPUT_DIR/startup_times_$TIMESTAMP.txt"
    echo ""
}

# Test memory usage
test_memory_usage() {
    echo "========================================="
    echo "Testing Memory Usage"
    echo "========================================="
    
    # Ensure app is running
    adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY" > /dev/null 2>&1
    sleep 3
    
    # Get memory info
    echo "Collecting memory information..."
    adb shell dumpsys meminfo "$PACKAGE_NAME" > "$OUTPUT_DIR/memory_usage_$TIMESTAMP.txt"
    
    # Extract key metrics
    TOTAL_PSS=$(adb shell dumpsys meminfo "$PACKAGE_NAME" | grep "TOTAL PSS" | awk '{print $3}')
    JAVA_HEAP=$(adb shell dumpsys meminfo "$PACKAGE_NAME" | grep "Java Heap:" | awk '{print $3}')
    NATIVE_HEAP=$(adb shell dumpsys meminfo "$PACKAGE_NAME" | grep "Native Heap:" | awk '{print $3}')
    
    echo "Total PSS: ${TOTAL_PSS} KB"
    echo "Java Heap: ${JAVA_HEAP} KB"
    echo "Native Heap: ${NATIVE_HEAP} KB"
    
    # Convert to MB for comparison
    TOTAL_MB=$((TOTAL_PSS / 1024))
    
    if [ "$TOTAL_MB" -lt 50 ]; then
        echo -e "${GREEN}✓ Memory usage is excellent (< 50MB)${NC}"
    elif [ "$TOTAL_MB" -lt 100 ]; then
        echo -e "${GREEN}✓ Memory usage is good (< 100MB)${NC}"
    elif [ "$TOTAL_MB" -lt 150 ]; then
        echo -e "${YELLOW}⚠ Memory usage is acceptable (< 150MB)${NC}"
    else
        echo -e "${RED}✗ Memory usage is too high (> 150MB)${NC}"
    fi
    
    echo ""
    echo "Memory report saved to $OUTPUT_DIR/memory_usage_$TIMESTAMP.txt"
    echo ""
}

# Test battery usage
test_battery_usage() {
    echo "========================================="
    echo "Testing Battery Usage"
    echo "========================================="
    
    echo "Resetting battery stats..."
    adb shell dumpsys batterystats --reset > /dev/null 2>&1
    
    echo "Battery stats reset. Please use the app for at least 1 hour."
    echo "Then run this script again with the --battery-report flag to see results."
    echo ""
    
    # If --battery-report flag is provided, show report
    if [ "$1" == "--battery-report" ]; then
        echo "Generating battery report..."
        adb shell dumpsys batterystats "$PACKAGE_NAME" > "$OUTPUT_DIR/battery_usage_$TIMESTAMP.txt"
        
        # Extract power usage
        POWER_USE=$(adb shell dumpsys batterystats "$PACKAGE_NAME" | grep "Estimated power use" | awk '{print $4}')
        echo "Estimated power use: ${POWER_USE}"
        
        echo "Battery report saved to $OUTPUT_DIR/battery_usage_$TIMESTAMP.txt"
    fi
    echo ""
}

# Test frame rate
test_frame_rate() {
    echo "========================================="
    echo "Testing Frame Rate"
    echo "========================================="
    
    # Ensure app is running
    adb shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY" > /dev/null 2>&1
    sleep 2
    
    echo "Collecting frame rate data..."
    echo "Please interact with the app for 30 seconds..."
    sleep 30
    
    # Get gfxinfo
    adb shell dumpsys gfxinfo "$PACKAGE_NAME" > "$OUTPUT_DIR/frame_rate_$TIMESTAMP.txt"
    
    # Extract frame stats
    JANKY_FRAMES=$(adb shell dumpsys gfxinfo "$PACKAGE_NAME" | grep "Janky frames:" | awk '{print $3}')
    TOTAL_FRAMES=$(adb shell dumpsys gfxinfo "$PACKAGE_NAME" | grep "Total frames rendered:" | awk '{print $4}')
    
    if [ -n "$JANKY_FRAMES" ] && [ -n "$TOTAL_FRAMES" ]; then
        JANK_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($JANKY_FRAMES/$TOTAL_FRAMES)*100}")
        echo "Janky frames: $JANKY_FRAMES / $TOTAL_FRAMES ($JANK_PERCENT%)"
        
        if (( $(echo "$JANK_PERCENT < 5" | bc -l) )); then
            echo -e "${GREEN}✓ Frame rate is excellent (< 5% jank)${NC}"
        elif (( $(echo "$JANK_PERCENT < 10" | bc -l) )); then
            echo -e "${YELLOW}⚠ Frame rate is acceptable (< 10% jank)${NC}"
        else
            echo -e "${RED}✗ Frame rate needs improvement (> 10% jank)${NC}"
        fi
    else
        echo "Could not extract frame statistics"
    fi
    
    echo ""
    echo "Frame rate report saved to $OUTPUT_DIR/frame_rate_$TIMESTAMP.txt"
    echo ""
}

# Test network usage
test_network_usage() {
    echo "========================================="
    echo "Testing Network Usage"
    echo "========================================="
    
    echo "Collecting network statistics..."
    adb shell dumpsys netstats detail > "$OUTPUT_DIR/network_usage_$TIMESTAMP.txt"
    
    # Extract app network usage
    RX_BYTES=$(adb shell dumpsys netstats detail | grep -A 20 "$PACKAGE_NAME" | grep "rx:" | head -1 | awk '{print $2}')
    TX_BYTES=$(adb shell dumpsys netstats detail | grep -A 20 "$PACKAGE_NAME" | grep "tx:" | head -1 | awk '{print $2}')
    
    if [ -n "$RX_BYTES" ] && [ -n "$TX_BYTES" ]; then
        RX_MB=$(awk "BEGIN {printf \"%.2f\", $RX_BYTES/1024/1024}")
        TX_MB=$(awk "BEGIN {printf \"%.2f\", $TX_BYTES/1024/1024}")
        TOTAL_MB=$(awk "BEGIN {printf \"%.2f\", ($RX_BYTES+$TX_BYTES)/1024/1024}")
        
        echo "Received: ${RX_MB} MB"
        echo "Transmitted: ${TX_MB} MB"
        echo "Total: ${TOTAL_MB} MB"
    else
        echo "Could not extract network statistics"
    fi
    
    echo ""
    echo "Network report saved to $OUTPUT_DIR/network_usage_$TIMESTAMP.txt"
    echo ""
}

# Test database performance
test_database_performance() {
    echo "========================================="
    echo "Testing Database Performance"
    echo "========================================="
    
    echo "Checking database size..."
    DB_SIZE=$(adb shell run-as "$PACKAGE_NAME" du -sh /data/data/"$PACKAGE_NAME"/databases 2>/dev/null | awk '{print $1}')
    
    if [ -n "$DB_SIZE" ]; then
        echo "Database size: $DB_SIZE"
    else
        echo "Could not determine database size (requires debuggable app)"
    fi
    
    echo ""
    echo "To test query performance, use Flutter DevTools Timeline"
    echo ""
}

# Test background tasks
test_background_tasks() {
    echo "========================================="
    echo "Testing Background Tasks"
    echo "========================================="
    
    echo "Checking scheduled WorkManager tasks..."
    adb shell dumpsys jobscheduler | grep "$PACKAGE_NAME" > "$OUTPUT_DIR/background_tasks_$TIMESTAMP.txt"
    
    TASK_COUNT=$(adb shell dumpsys jobscheduler | grep -c "$PACKAGE_NAME")
    echo "Scheduled tasks: $TASK_COUNT"
    
    if [ "$TASK_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Background tasks are scheduled${NC}"
    else
        echo -e "${YELLOW}⚠ No background tasks found${NC}"
    fi
    
    echo ""
    echo "Checking for wakelocks..."
    adb shell dumpsys power | grep "$PACKAGE_NAME" > "$OUTPUT_DIR/wakelocks_$TIMESTAMP.txt"
    
    WAKELOCK_COUNT=$(adb shell dumpsys power | grep -c "$PACKAGE_NAME")
    if [ "$WAKELOCK_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ No active wakelocks${NC}"
    else
        echo -e "${YELLOW}⚠ Found $WAKELOCK_COUNT wakelocks${NC}"
    fi
    
    echo ""
    echo "Background tasks report saved to $OUTPUT_DIR/background_tasks_$TIMESTAMP.txt"
    echo ""
}

# Generate summary report
generate_summary() {
    echo "========================================="
    echo "Generating Summary Report"
    echo "========================================="
    
    SUMMARY_FILE="$OUTPUT_DIR/summary_$TIMESTAMP.txt"
    
    cat > "$SUMMARY_FILE" << EOF
Performance Test Summary
========================
Date: $(date)
Package: $PACKAGE_NAME

Test Results:
-------------
See individual report files for detailed information:
- startup_times_$TIMESTAMP.txt
- memory_usage_$TIMESTAMP.txt
- frame_rate_$TIMESTAMP.txt
- network_usage_$TIMESTAMP.txt
- background_tasks_$TIMESTAMP.txt

Recommendations:
----------------
1. Review any metrics that exceeded target thresholds
2. Use Flutter DevTools for detailed profiling
3. Test on low-end devices (2GB RAM)
4. Monitor battery usage over 24 hours
5. Check for memory leaks with extended usage

Next Steps:
-----------
1. Run: flutter run --profile
2. Open DevTools: flutter pub global run devtools
3. Profile CPU, memory, and network usage
4. Optimize identified bottlenecks
EOF
    
    echo "Summary report saved to $SUMMARY_FILE"
    echo ""
}

# Main execution
main() {
    check_device
    
    if [ "$1" == "--all" ]; then
        test_startup_time
        test_memory_usage
        test_frame_rate
        test_network_usage
        test_database_performance
        test_background_tasks
        generate_summary
    elif [ "$1" == "--startup" ]; then
        test_startup_time
    elif [ "$1" == "--memory" ]; then
        test_memory_usage
    elif [ "$1" == "--battery" ]; then
        test_battery_usage
    elif [ "$1" == "--battery-report" ]; then
        test_battery_usage "--battery-report"
    elif [ "$1" == "--frames" ]; then
        test_frame_rate
    elif [ "$1" == "--network" ]; then
        test_network_usage
    elif [ "$1" == "--database" ]; then
        test_database_performance
    elif [ "$1" == "--background" ]; then
        test_background_tasks
    else
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  --all              Run all performance tests"
        echo "  --startup          Test app startup time"
        echo "  --memory           Test memory usage"
        echo "  --battery          Reset battery stats for testing"
        echo "  --battery-report   Generate battery usage report"
        echo "  --frames           Test frame rate"
        echo "  --network          Test network usage"
        echo "  --database         Test database performance"
        echo "  --background       Test background tasks"
        echo ""
        echo "Example: $0 --all"
        exit 1
    fi
    
    echo "========================================="
    echo "Performance profiling complete!"
    echo "Reports saved to: $OUTPUT_DIR/"
    echo "========================================="
}

# Run main function
main "$@"
