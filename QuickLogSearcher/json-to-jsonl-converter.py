import json
import jsonlines
json_array = json.loads(r"C:\Users\navee\security_logs.json")

# Write to jsonlines file:
out_filename = "jsonl_data.json"
with open(file_name, 'wb') as f:
    writer = jsonlines.Writer(f)
    writer.write_all(json_array)
    writer.close()