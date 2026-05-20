import os
import re

lib_dir = '/Users/macbook/StudioProjects/sair/lib/screens/services'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Replace _showError block
    content = re.sub(
        r"void _showError\(String msg\)\s*\{[\s\S]*?^\s*\}",
        "void _showError(String msg) {\n    AppSnackBar.showError(context, msg);\n  }",
        content,
        flags=re.MULTILINE
    )

    # Replace _showSuccess block
    content = re.sub(
        r"void _showSuccess\(String msg\)\s*\{[\s\S]*?^\s*\}",
        "void _showSuccess(String msg) {\n    AppSnackBar.showSuccess(context, msg);\n  }",
        content,
        flags=re.MULTILINE
    )

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
