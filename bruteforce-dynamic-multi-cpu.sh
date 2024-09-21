#!/usr/bin/env python3
"""
Script Name: bruteforce-dynamic-multi-cpu.sh
Description: A multi-processing brute-force script that dynamically generates passwords and tests them using multiple CPU cores.
Date: 2024-09-06
Version: 1.1
"""

import itertools
import string
import subprocess
from multiprocessing import Pool

# Define charset to include lowercase, uppercase letters, and digits
charset = string.ascii_lowercase + string.ascii_uppercase + string.digits

# Define password length range
min_length = 8
max_length = 12

# Number of CPU cores to use (adjusted for VM environment)
num_cores = 2

# Function to test passwords using the original expect script
def test_password(password):
    password = password.strip()  # Remove any extra whitespace/newline characters
    print(f'Trying password: {password}', flush=True)

    # Call the expect script with the current password
    result = subprocess.run(['./try_password.exp', 'SafeInCloud-test.db', password, 'output.json'])

    # Check if the password was successful
    if result.returncode == 0:
        print(f'Success! The password is: {password}', flush=True)
        with open("cracked_password.txt", "w") as file:
            file.write(f"Cracked Password: {password}\n")
        exit()  # Exit all processes once the correct password is found

# Brute-force password generator (in parallel)
def brute_force_parallel(charset, min_length, max_length):
    for length in range(min_length, max_length + 1):
        with Pool(num_cores) as pool:
            # Generate all possible passwords of the current length
            password_generator = (''.join(password_tuple) for password_tuple in itertools.product(charset, repeat=length))
            # Use imap_unordered for efficient memory usage
            pool.imap_unordered(test_password, password_generator, chunksize=50)

# Start brute-force with multi-processing
if __name__ == '__main__':
    print(f'Starting brute-force attack using {num_cores} cores...', flush=True)
    brute_force_parallel(charset, min_length, max_length)
