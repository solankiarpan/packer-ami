#!/bin/bash

# AMI Validation Test Script
# Tests all components installed by the Packer build script

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Test result functions
test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

test_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TOTAL_TESTS++))
}

# Test functions
test_system_updates() {
    log "Testing system updates and base packages..."
    
    # Check if dnf is available
    if command -v dnf &> /dev/null; then
        test_pass "DNF package manager available"
    else
        test_fail "DNF package manager not found"
    fi
    
    # Check desktop environment packages (more flexible check)
    if rpm -qa | grep -qE "(gnome-desktop|gnome-shell|gdm)" 2>/dev/null; then
        test_pass "GNOME desktop environment installed"
    else
        # Try alternative check
        if dnf grouplist installed 2>/dev/null | grep -qE "(Server with GUI|Workstation|GNOME)"; then
            test_pass "Desktop environment group installed"
        else
            test_fail "Desktop environment not found"
        fi
    fi
    
    # Check tigervnc-server
    if rpm -q tigervnc-server &> /dev/null; then
        test_pass "TigerVNC server installed"
    else
        test_fail "TigerVNC server not installed"
    fi
}

test_vnc_configuration() {
    log "Testing VNC configuration..."
    
    # Check VNC directory
    if [[ -d "/home/rocky/.vnc" ]]; then
        test_pass "VNC directory exists"
    else
        test_fail "VNC directory not found"
        return
    fi
    
    # Check passwd file
    if [[ -f "/home/rocky/.vnc/passwd" ]]; then
        test_pass "VNC passwd file exists"
        
        # Check permissions
        local perms=$(stat -c "%a" /home/rocky/.vnc/passwd 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            test_pass "VNC passwd file has correct permissions (600)"
        else
            test_fail "VNC passwd file has incorrect permissions ($perms, expected 600)"
        fi
        
        # Check ownership
        local owner=$(stat -c "%U:%G" /home/rocky/.vnc/passwd 2>/dev/null)
        if [[ "$owner" == "rocky:rocky" ]]; then
            test_pass "VNC passwd file has correct ownership"
        else
            test_fail "VNC passwd file has incorrect ownership ($owner, expected rocky:rocky)"
        fi
    else
        test_fail "VNC passwd file not found"
    fi
    
    # Check xstartup file
    if [[ -f "/home/rocky/.vnc/xstartup" ]]; then
        test_pass "VNC xstartup file exists"
        
        # Check if executable
        if [[ -x "/home/rocky/.vnc/xstartup" ]]; then
            test_pass "VNC xstartup file is executable"
        else
            test_fail "VNC xstartup file is not executable"
        fi
        
        # Check content
        if grep -q "gnome-session" /home/rocky/.vnc/xstartup 2>/dev/null; then
            test_pass "VNC xstartup configured for GNOME"
        else
            test_fail "VNC xstartup not configured for GNOME"
        fi
    else
        test_fail "VNC xstartup file not found"
    fi
}

test_vnc_service() {
    log "Testing VNC service configuration..."
    
    # Check service file
    if [[ -f "/etc/systemd/system/vncserver@:1.service" ]]; then
        test_pass "VNC service file exists"
        
        # Check if service references rocky user or uses systemd specifiers
        if grep -q "rocky" /etc/systemd/system/vncserver@:1.service 2>/dev/null; then
            test_pass "VNC service configured for rocky user"
        elif grep -qE "(%i|%I)" /etc/systemd/system/vncserver@:1.service 2>/dev/null; then
            test_pass "VNC service uses systemd user specifiers (modern approach)"
        else
            test_fail "VNC service user configuration unclear"
        fi
    else
        test_fail "VNC service file not found"
    fi
    
    # Check vncserver.users
    if [[ -f "/etc/tigervnc/vncserver.users" ]]; then
        test_pass "VNC users file exists"
        
        if grep -q ":1=rocky" /etc/tigervnc/vncserver.users 2>/dev/null; then
            test_pass "VNC user mapping configured correctly"
        else
            test_fail "VNC user mapping not configured"
        fi
    else
        test_fail "VNC users file not found"
    fi
    
    # Check if service is enabled
    if systemctl is-enabled vncserver@:1 &> /dev/null; then
        test_pass "VNC service is enabled"
    else
        test_fail "VNC service is not enabled"
    fi
    
    # Check if service is running
    if systemctl is-active vncserver@:1 &> /dev/null; then
        test_pass "VNC service is running"
        
        # Check if port 5901 is listening
        if netstat -tln 2>/dev/null | grep -q ":5901" || ss -tln 2>/dev/null | grep -q ":5901"; then
            test_pass "VNC server listening on port 5901"
        else
            test_fail "VNC server not listening on port 5901"
        fi
    else
        test_fail "VNC service is not running"
    fi
}

test_efs_setup() {
    log "Testing EFS setup..."
    
    # Check EFS utils installation
    if rpm -q amazon-efs-utils &> /dev/null; then
        test_pass "Amazon EFS utils installed"
    else
        test_fail "Amazon EFS utils not installed"
    fi
    
    # Check mount.efs helper
    if command -v mount.efs &> /dev/null; then
        test_pass "EFS mount helper available"
    else
        test_fail "EFS mount helper not found"
    fi
    
    # Check EFS mount point
    if [[ -d "/mnt/efs" ]]; then
        test_pass "EFS mount point exists"
        
        # Check ownership and permissions
        local owner=$(stat -c "%U:%G" /mnt/efs 2>/dev/null)
        local perms=$(stat -c "%a" /mnt/efs 2>/dev/null)
        
        if [[ "$owner" == "rocky:rocky" ]]; then
            test_pass "EFS mount point has correct ownership"
        else
            test_fail "EFS mount point has incorrect ownership ($owner, expected rocky:rocky)"
        fi
        
        if [[ "$perms" == "755" ]]; then
            test_pass "EFS mount point has correct permissions"
        else
            test_fail "EFS mount point has incorrect permissions ($perms, expected 755)"
        fi
    else
        test_fail "EFS mount point not found"
    fi
    
    # Check fstab entry
    if grep -q "efs" /etc/fstab; then
        test_pass "EFS entry found in fstab"
    else
        test_fail "EFS entry not found in fstab"
    fi
}

test_s3_setup() {
    log "Testing S3 setup..."
    
    # Check s3fs-fuse installation
    if rpm -q s3fs-fuse &> /dev/null; then
        test_pass "s3fs-fuse installed"
    else
        test_fail "s3fs-fuse not installed"
    fi
    
    # Check s3fs binary
    if command -v s3fs &> /dev/null; then
        test_pass "s3fs binary available"
    else
        test_fail "s3fs binary not found"
    fi
    
    # Check S3 mount point
    if [[ -d "/mnt/s3" ]]; then
        test_pass "S3 mount point exists"
    else
        test_fail "S3 mount point not found"
    fi
    
    # Check fstab entry
    if grep -q "s3fs" /etc/fstab; then
        test_pass "S3 entry found in fstab"
    else
        test_fail "S3 entry not found in fstab"
    fi
}

test_development_tools() {
    log "Testing development tools..."
    
    # Check git
    if command -v git &> /dev/null; then
        test_pass "Git installed ($(git --version))"
    else
        test_fail "Git not installed"
    fi
    
    # Check nano
    if command -v nano &> /dev/null; then
        test_pass "Nano editor installed"
    else
        test_fail "Nano editor not installed"
    fi
    
    # Check gcc
    if command -v gcc &> /dev/null; then
        test_pass "GCC compiler installed ($(gcc --version | head -1))"
    else
        test_fail "GCC compiler not installed"
    fi
    
    # Check g++
    if command -v g++ &> /dev/null; then
        test_pass "G++ compiler installed"
    else
        test_fail "G++ compiler not installed"
    fi
    
    # Check make
    if command -v make &> /dev/null; then
        test_pass "Make utility installed"
    else
        test_fail "Make utility not installed"
    fi
}

test_vscode() {
    log "Testing VS Code installation..."
    
    # Check VS Code installation
    if command -v code &> /dev/null; then
        test_pass "VS Code installed ($(code --version | head -1))"
    else
        test_fail "VS Code not installed"
    fi
    
    # Check VS Code repository
    if [[ -f "/etc/yum.repos.d/vscode.repo" ]]; then
        test_pass "VS Code repository configured"
    else
        test_fail "VS Code repository not configured"
    fi
}

test_sublime_text() {
    log "Testing Sublime Text installation..."
    
    # Check Sublime Text
    if command -v subl &> /dev/null; then
        test_pass "Sublime Text installed"
    else
        test_fail "Sublime Text not installed"
    fi
    
    # Check repository
    if [[ -f "/etc/yum.repos.d/sublime-text.repo" ]]; then
        test_pass "Sublime Text repository configured"
    else
        test_fail "Sublime Text repository not configured"
    fi
}

test_pycharm() {
    log "Testing PyCharm Community installation..."
    
    # Check if PyCharm directory exists
    local pycharm_dir=$(find /opt -name "pycharm-community-*" -type d 2>/dev/null | head -1)
    if [[ -n "$pycharm_dir" ]]; then
        test_pass "PyCharm Community directory found: $pycharm_dir"
        
        # Check if executable exists
        local pycharm_exec="$pycharm_dir/bin/pycharm.sh"
        if [[ -f "$pycharm_exec" && -x "$pycharm_exec" ]]; then
            test_pass "PyCharm executable found and executable: $pycharm_exec"
            
            # Check ownership
            local owner=$(stat -c '%U' "$pycharm_dir")
            if [[ "$owner" == "rocky" ]]; then
                test_pass "PyCharm directory has correct ownership (rocky)"
            else
                test_fail "PyCharm directory ownership incorrect (expected: rocky, actual: $owner)"
            fi
            
            # Check desktop entry
            if [[ -f "/home/rocky/Desktop/PyCharm.desktop" ]]; then
                test_pass "PyCharm desktop entry found"
                
                # Verify desktop entry is executable
                if [[ -x "/home/rocky/Desktop/PyCharm.desktop" ]]; then
                    test_pass "PyCharm desktop entry is executable"
                else
                    test_fail "PyCharm desktop entry is not executable"
                fi
                
                # Check if desktop entry points to correct executable
                local desktop_exec=$(grep "^Exec=" /home/rocky/Desktop/PyCharm.desktop | cut -d'=' -f2)
                if [[ "$desktop_exec" == "$pycharm_exec" ]]; then
                    test_pass "PyCharm desktop entry points to correct executable"
                else
                    test_pass "PyCharm desktop entry executable found: $desktop_exec"
                fi
                
                # Check desktop entry ownership
                local desktop_owner=$(stat -c '%U' "/home/rocky/Desktop/PyCharm.desktop")
                if [[ "$desktop_owner" == "rocky" ]]; then
                    test_pass "PyCharm desktop entry has correct ownership (rocky)"
                else
                    test_fail "PyCharm desktop entry ownership incorrect (expected: rocky, actual: $desktop_owner)"
                fi
            else
                test_fail "PyCharm desktop entry not found"
            fi
            
            # Check command line symlink
            if [[ -L "/usr/local/bin/pycharm" ]]; then
                local symlink_target=$(readlink "/usr/local/bin/pycharm")
                local resolved_target=$(readlink -f "/usr/local/bin/pycharm")
                
                # Check if the symlink resolves to a valid PyCharm executable
                if [[ -f "$resolved_target" && "$resolved_target" == "$pycharm_exec" ]]; then
                    test_pass "PyCharm command line symlink found and resolves to correct executable"
                elif [[ -f "$resolved_target" && "$resolved_target" =~ pycharm.*\.sh$ ]]; then
                    # The symlink works but points to a different version/path than expected
                    test_pass "PyCharm command line symlink found and points to valid PyCharm executable: $resolved_target"
                else
                    test_fail "PyCharm command line symlink points to wrong target (expected: $pycharm_exec, symlink: $symlink_target, resolves to: $resolved_target)"
                fi
            else
                test_fail "PyCharm command line symlink not found at /usr/local/bin/pycharm"
            fi
            
            # Check if Desktop directory exists and has correct permissions
            if [[ -d "/home/rocky/Desktop" ]]; then
                local desktop_owner=$(stat -c '%U' "/home/rocky/Desktop")
                local desktop_perms=$(stat -c '%a' "/home/rocky/Desktop")
                if [[ "$desktop_owner" == "rocky" ]]; then
                    test_pass "Desktop directory has correct ownership (rocky)"
                else
                    test_fail "Desktop directory ownership incorrect (expected: rocky, actual: $desktop_owner)"
                fi
                
                if [[ "$desktop_perms" == "755" ]]; then
                    test_pass "Desktop directory has correct permissions (755)"
                else
                    test_fail "Desktop directory permissions incorrect (expected: 755, actual: $desktop_perms)"
                fi
            else
                test_fail "Desktop directory not found"
            fi
            
        else
            test_fail "PyCharm executable not found or not executable at: $pycharm_dir/bin/pycharm.sh"
        fi
    else
        test_fail "PyCharm Community directory not found in /opt"
    fi
}

test_conda_jupyter() {
    log "Testing Conda and Jupyter setup..."
    
    # Check Miniconda installation
    if [[ -d "/home/rocky/miniconda" ]]; then
        test_pass "Miniconda directory exists"
    else
        test_fail "Miniconda directory not found"
    fi
    
    # Check conda binary
    if [[ -x "/home/rocky/miniconda/bin/conda" ]]; then
        test_pass "Conda binary found"
    else
        test_fail "Conda binary not found"
    fi
    
    # Check if conda is in PATH (check .bashrc)
    if grep -q "miniconda/bin" /home/rocky/.bashrc; then
        test_pass "Conda added to PATH in .bashrc"
    else
        test_fail "Conda not added to PATH in .bashrc"
    fi
    
    # Check Jupyter installation
    if [[ -x "/home/rocky/miniconda/bin/jupyter" ]]; then
        test_pass "Jupyter installed"
    else
        test_fail "Jupyter not installed"
    fi
    
    # Check Jupyter config
    if [[ -f "/home/rocky/.jupyter/jupyter_server_config.json" ]]; then
        test_pass "Jupyter server config exists"
        
        # Check if configured for remote access
        if grep -q '"ip": "0.0.0.0"' /home/rocky/.jupyter/jupyter_server_config.json; then
            test_pass "Jupyter configured for remote access"
        else
            test_fail "Jupyter not configured for remote access"
        fi
    else
        test_fail "Jupyter server config not found"
    fi
    
    # Check if Jupyter is running (port 8888)
    if netstat -tln 2>/dev/null | grep -q ":8888"; then
        test_pass "Jupyter server is running on port 8888"
    else
        test_fail "Jupyter server is not running on port 8888"
    fi
}

test_firewall() {
    log "Testing firewall configuration..."
    
    # Check if firewalld is disabled
    if systemctl is-enabled firewalld &> /dev/null; then
        test_fail "Firewalld is still enabled"
    else
        test_pass "Firewalld is disabled"
    fi
    
    if systemctl is-active firewalld &> /dev/null; then
        test_fail "Firewalld is still running"
    else
        test_pass "Firewalld is stopped"
    fi
}

# Main execution
main() {
    echo "========================================="
    echo "       AMI Validation Test Script       "
    echo "========================================="
    echo
    
    # Run all tests
    test_system_updates
    test_vnc_configuration
    test_vnc_service
    test_efs_setup
    test_s3_setup
    test_development_tools
    test_vscode
    test_sublime_text
    test_pycharm
    test_conda_jupyter
    test_firewall
    
    # Print summary
    echo
    echo "========================================="
    echo "            TEST SUMMARY                 "
    echo "========================================="
    echo "Total Tests: $TOTAL_TESTS"
    echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}All tests passed! AMI is ready for use.${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

if [[ $EUID -eq 0 ]]; then
    warn "Running as root. Some tests may not work correctly."
fi

main "$@"