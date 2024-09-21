to default)

# Function to get the last wordlist file, line number, and password from the progress file
get_progress() {
    if [[ -f "$PROGRESS_FILE" ]]; then
        last_wordlist=$(cat "$PROGRESS_FILE" | cut -d ":" -f 1)
        last_line=$(cat "$PROGRESS_FILE" | cut -d ":" -f 2)
        echo "$last_wordlist" "$last_line"
    else
        echo "" 0  # Start from the beginning if no log exists
    fi
}

# Ask the user whether to resume or start from the beginning (accept "y" or "yes")
read -p "Do you want to resume from where it left off? (y/yes/no): " resume_choice

if [[ "$resume_choice" == "yes" || "$resume_choice" == "y" ]]; then
    read LAST_WORDLIST LAST_LINE < <(get_progress)
    echo "Resuming from wordlist: $LAST_WORDLIST, line: $LAST_LINE..."
else
    LAST_WORDLIST=""
    LAST_LINE=0  # Start from the beginning
    echo "Starting from the beginning..."
fi

# Remove the password file if it exists from a previous run
rm -f "$PASSWORD_FILE"


# Loop through each wordlist file in the directory
for WORDLIST in "$WORDLIST_DIR"/*; do
    # Skip wordlists until we reach the one from which to resume
    if [[ -n "$LAST_WORDLIST" && "$WORDLIST" != "$LAST_WORDLIST" ]]; then
        continue
    fi

    # Start reading from the next line if resuming
    if [[ "$WORDLIST" == "$LAST_WORDLIST" ]]; then
        START_LINE="$LAST_LINE"
    else
        START_LINE=0
    fi

    # Loop through each password in the wordlist, starting from the last tested line
    tail -n +"$((START_LINE + 1))" "$WORDLIST" | while IFS= read -r password; do
        ((START_LINE++))
        echo -e "${BLUE}wordlist: $WORDLIST, line: $START_LINE, password: ${RED}$password${NC}"

        # Call expect script to try the password
        ./try_password.exp "$DATABASE" "$password" "$OUTPUT"

        # Check the exit code of the expect script
        if [ $? -eq 0 ]; then
            # Password test complete message
            echo "Password test complete."

            # Yellow lines and red success message
            echo -e "${YELLOW}====================================${NC}"
            echo -e "${RED}      SUCCESS! Password is $password${NC}"
            echo -e "${YELLOW}====================================${NC}"

            # Save the correct password to a file
            echo "$password" > "$PASSWORD_FILE"

            # Clear the progress file upon success
            rm -f "$PROGRESS_FILE"
            exit 0  # Exit the script on success
        fi

        # Log the current wordlist, line number, and password to the progress file
        echo "$WORDLIST:$START_LINE:$password" > "$PROGRESS_FILE"

        # Add a delay between attempts (adjust as needed)
        sleep 0.003
    done
done

echo "No matching password found in the wordlists."
