#!/bin/env python

import json
import os

def split_json_file(input_file, output_directory, max_objects=1000):
    # Ensure the output directory exists
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Read the JSON file
    with open(input_file, 'r') as file:
        data = json.load(file)
    
    objects = data.get("Objects", [])
    
    # Split objects into chunks of max_objects
    for i in range(0, len(objects), max_objects):
        chunk = objects[i:i + max_objects]
        output_data = {"Objects": chunk}
        
        # Write each chunk to a new JSON file
        output_file = os.path.join(output_directory, f"split_{i // max_objects + 1}.json")
        with open(output_file, 'w') as out_file:
            json.dump(output_data, out_file, indent=4)

# Example usage
input_file = "all.json"  # Replace with your input file path
output_directory = "parts"  # Replace with your desired output directory

split_json_file(input_file, output_directory)
