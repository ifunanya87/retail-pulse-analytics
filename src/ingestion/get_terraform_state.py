import subprocess
import json
import os
import sys


_config_cache = None

def get_terraform_config(tf_dir="./terraform"):
    global _config_cache
    
    if _config_cache:
        return _config_cache

    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=tf_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        raw_outputs = json.loads(result.stdout)
        
        _config_cache = {
            k: v.get("value")
            for k, v in raw_outputs.items()
            if "value" in v
        }

        return _config_cache

    except subprocess.CalledProcessError:
        print("CRITICAL ERROR: Failed to fetch Terraform outputs.")
        sys.exit(1)
    except FileNotFoundError:
        print("ERROR: Terraform CLI not found. Is it installed?")
        sys.exit(1)
