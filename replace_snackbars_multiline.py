import os
import re

lib_dir = '/Users/macbook/StudioProjects/sair/lib/screens/services'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Replace error snackbar
    error_pattern = re.compile(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Row\(\s*children: \[\s*const Icon\(Icons\.error_outline.*?\),\s*\]\),\s*backgroundColor: Colors\.red\.shade700,\s*behavior: SnackBarBehavior\.floating,\s*shape:.*?\),\s*\);",
        re.DOTALL
    )
    content = error_pattern.sub(r"AppSnackBar.showError(context, msg);", content)

    # Replace success snackbar
    success_pattern = re.compile(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Row\(\s*children: \[\s*const Icon\(Icons\.check_circle_outline.*?\),\s*\]\),\s*backgroundColor: Colors\.green\.shade700,\s*behavior: SnackBarBehavior\.floating,\s*shape:.*?\),\s*\);",
        re.DOTALL
    )
    content = success_pattern.sub(r"AppSnackBar.showSuccess(context, msg);", content)

    if content != original:
        if 'AppSnackBar' in content and 'snackbar_utils.dart' not in content:
            content = re.sub(r"(import 'package:flutter/material.dart';\n)", r"\1import '../../core/utils/snackbar_utils.dart';\n", content, count=1)
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
