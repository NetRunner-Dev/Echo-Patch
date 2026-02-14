#!/bin/bash

# Simple System Monitor Script
# Author: Le Chat
# Date: 2026-02-14

# Configuration
LOG_FILE="system_monitor.log"
MAX_LOG_SIZE=10240 # 10KB
THRESHOLD_CPU=90
THRESHOLD_MEM=80
THRESHOLD_DISK=90

# Function to log messages
log_message() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
    # Rotate log if too big
    if [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        log_message "Log rotated."
    fi
}

# Function to check CPU usage
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    log_message "CPU Usage: $cpu_usage%"
    if [ $(echo "$cpu_usage > $THRESHOLD_CPU" | bc) -eq 1 ]; then
        log_message "WARNING: High CPU usage detected!"
    fi
}

# Function to check memory usage
check_memory() {
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')
    local mem_percent=$((mem_used * 100 / mem_total))
    log_message "Memory Usage: $mem_percent% ($mem_used MB / $mem_total MB)"
    if [ $mem_percent -gt $THRESHOLD_MEM ]; then
        log_message "WARNING: High memory usage detected!"
    fi
}

# Function to check disk space
check_disk() {
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    log_message "Disk Usage: $disk_usage%"
    if [ $disk_usage -gt $THRESHOLD_DISK ]; then
        log_message "WARNING: High disk usage detected!"
    fi
}

# Function to check network status
check_network() {
    local ping_result=$(ping -c 1 google.com &> /dev/null; echo $?)
    if [ $ping_result -eq 0 ]; then
        log_message "Network: Online"
    else
        log_message "Network: Offline"
    fi
}

# Function to display menu
show_menu() {
    echo "System Monitor Menu"
    echo "1. Check CPU Usage"
    echo "2. Check Memory Usage"
    echo "3. Check Disk Space"
    echo "4. Check Network Status"
    echo "5. Run All Checks"
    echo "6. View Log"
    echo "7. Exit"
    echo -n "Enter your choice: "
}

# Main script
clear
log_message "System Monitor Started"

while true; do
    show_menu
    read choice
    case $choice in
        1) check_cpu ;;
        2) check_memory ;;
        3) check_disk ;;
        4) check_network ;;
        5)
            check_cpu
            check_memory
            check_disk
            check_network
            ;;
        6) cat "$LOG_FILE" | less ;;
        7)
            log_message "System Monitor Stopped"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
    echo "Press any key to continue..."
    read -n 1 -s
    clear
done
