import os
import re

lib_dir = '/Users/macbook/StudioProjects/sair/lib'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content

    # Replace error snackbars
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Please fill all fields'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please fill all fields');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\('Login Failed: \$e'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Login Failed: $e');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(content: Text\('Registration Failed: \$e'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Registration Failed: $e');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Account number copied!'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showSuccess(context, 'Account number copied!');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Please enter either BVN or NIN'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please enter either BVN or NIN');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('KYC Verified Successfully\. Generating Account\.\.\.'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showSuccess(context, 'KYC Verified Successfully. Generating Account...');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Failed to verify KYC\. Please try again\.'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Failed to verify KYC. Please try again.');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Profile updated successfully'\),\s*backgroundColor: Colors\.green\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showSuccess(context, 'Profile updated successfully');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Failed to update profile'\),\s*backgroundColor: Colors\.red\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Failed to update profile');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\('Please enter a valid amount'\),\s*behavior: SnackBarBehavior\.floating,\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please enter a valid amount');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\('Insufficient balance'\),\s*behavior: SnackBarBehavior\.floating,\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Insufficient balance');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\('Please select a package'\),\s*behavior: SnackBarBehavior\.floating,\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please select a package');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\('Please enter meter number'\),\s*behavior: SnackBarBehavior\.floating,\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please enter meter number');",
        content
    )

    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: const Text\('Please enter phone number'\),\s*behavior: SnackBarBehavior\.floating,\s*\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please enter phone number');",
        content
    )

    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Please enter a valid amount'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please enter a valid amount');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Please select a bank account'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Please select a bank account');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Insufficient wallet balance'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Insufficient wallet balance');",
        content
    )
    
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(content: Text\('Withdrawal failed\. Please try again\.'\)\)\s*,?\s*\);?",
        r"AppSnackBar.showError(context, 'Withdrawal failed. Please try again.');",
        content
    )

    if content != original:
        # Need to add import if AppSnackBar is used
        if 'AppSnackBar' in content and 'snackbar_utils.dart' not in content:
            # count directory depth to root lib
            depth = filepath.count('/') - lib_dir.count('/') - 1
            prefix = '../' * depth
            import_str = f"import '{prefix}core/utils/snackbar_utils.dart';"
            
            # Insert after the first import
            content = re.sub(r"(import 'package:flutter/material.dart';\n)", r"\1" + import_str + "\n", content, count=1)
            
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
