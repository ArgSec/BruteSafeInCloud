#!/bin/bash

WORDLIST="/usr/share/wordlists/rockyou.txt"
DATABASE="SafeInCloud.db"

# Loop through each password in the wordlist
while read -r password; do
    echo "Trying password: $password"
    
    # Call expect script to try the password
    ./try_password.exp "$DATABASE" "$password"

    # Add a 0.03-second delay
    sleep 0.03
done < "$WORDLIST"

