import os
import re

lib_dir = '/Users/macbook/StudioProjects/sair/lib/screens/services'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Replace error snackbar specifically inside _showError
    # We look for `void _showError(String msg) {` followed by the ScaffoldMessenger call
    
    error_pattern = re.compile(r"(void _showError\(String msg\)\s*\{\s*)ScaffoldMessenger\.of\(context\)\.showSnackBar\([^;]+;\)", re.DOTALL)
    content = error_pattern.sub(r"\1AppSnackBar.showError(context, msg);", content)

    # Replace success snackbar inside _showSuccess
    success_pattern = re.compile(r"(void _showSuccess\(String msg\)\s*\{\s*)ScaffoldMessenger\.of\(context\)\.showSnackBar\([^;]+;\)", re.DOTALL)
    content = success_pattern.sub(r"\1AppSnackBar.showSuccess(context, msg);", content)

    # Handle the ones in cable_tv, electricity, convert_airtime which might just have `ScaffoldMessenger.of(context).showSnackBar(SnackBar(` directly
    # Wait, in cable_tv, convert_airtime, electricity, the _showError doesn't have the `Row` block, it just has `SnackBar(content: Text(msg))`.
    # Let's replace any ScaffoldMessenger call that contains `Colors.red` or `error_outline` with AppSnackBar.showError(context, msg) IF it's inside _showError.
    
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
