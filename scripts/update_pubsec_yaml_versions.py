#!/usr/bin/env python3

from ruamel.yaml import YAML

# Define the file paths
pubspec_yaml_path = "pubspec.yaml"
pubspec_lock_path = "pubspec.lock"

# Initialize YAML parser/loader
yaml = YAML()
yaml.preserve_quotes = True
yaml.indent(mapping=2, sequence=4, offset=2)

# Read the pubspec.lock file and extract the package versions
lock_versions = {}
with open(pubspec_lock_path, 'r') as lock_file:
    lock_data = yaml.load(lock_file)
    for package_name, package_info in lock_data['packages'].items():
        lock_versions[package_name] = package_info['version']

# Read the pubspec.yaml file
with open(pubspec_yaml_path, 'r') as yaml_file:
    yaml_data = yaml.load(yaml_file)

# Function to preserve formatting and update versions
def update_dependency_versions(dependencies_section):
    if not dependencies_section:
        return

    for package, details in dependencies_section.items():
        # Skip if it's an SDK or Git dependency
        if isinstance(details, dict) and ('sdk' in details or 'git' in details):
            continue
        
        # Update version if the package exists in lock_versions
        if package in lock_versions:
            dependencies_section[package] = "^" + lock_versions[package]

# Update the dependency versions in pubspec.yaml
update_dependency_versions(yaml_data.get('dependencies', {}))
update_dependency_versions(yaml_data.get('dev_dependencies', {}))

# Write the updated data back to pubspec.yaml
with open(pubspec_yaml_path, 'w') as yaml_file:
    yaml.dump(yaml_data, yaml_file)

print("pubspec.yaml has been updated with versions from pubspec.lock.")
