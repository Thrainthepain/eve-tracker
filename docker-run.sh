# Fix network issues (common for Docker Desktop and Ubuntu)
fix_network_issues() {
    print_message "$BLUE" "Checking for Docker network issues..."
    
    # Check Docker socket permissions first
    sudo_cmd=""
    if [ "$(id -u)" -ne 0 ] && [ -f "/var/run/docker.sock" ] && [ ! -w "/var/run/docker.sock" ]; then
        print_message "$YELLOW" "Docker socket is not writable by current user. Using sudo for Docker commands."
        sudo_cmd="sudo"
    fi
    
    # Check if eve-network exists, if yes remove it to prevent conflicts
    if $sudo_cmd docker network inspect eve-network &> /dev/null; then
        print_message "$YELLOW" "Found existing eve-network, removing to prevent conflicts..."
        $sudo_cmd docker network rm eve-network &> /dev/null
        
        # Verify the network was actually removed (sometimes doesn't due to running containers)
        if $sudo_cmd docker network inspect eve-network &> /dev/null; then
            print_message "$RED" "Warning: Could not remove existing eve-network."
            print_message "$YELLOW" "It may be in use by running containers. Consider stopping them first:"
            print_message "$YELLOW" "$sudo_cmd docker container ls --filter network=eve-network -q | xargs $sudo_cmd docker container stop"
            
            read -p "Attempt to stop containers using the network? (y/n): " stop_option
            if [[ "$stop_option" == "y" || "$stop_option" == "Y" ]]; then
                container_ids=$($sudo_cmd docker container ls --filter network=eve-network -q)
                if [ -n "$container_ids" ]; then
                    $sudo_cmd docker container stop $container_ids
                    $sudo_cmd docker network rm eve-network &> /dev/null
                fi
            fi
        fi
    fi
    
    # Create fresh network
    print_message "$BLUE" "Creating fresh Docker network..."
    $sudo_cmd docker network create eve-network &> /dev/null
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "Failed to create Docker network. Check Docker settings."
        return 1
    else
        print_message "$GREEN" "Created Docker network: eve-network"
        return 0
    fi
}
