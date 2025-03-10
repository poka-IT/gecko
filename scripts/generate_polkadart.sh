#!/bin/bash

# Script to generate code with polkadart_cli and copy the analysis_options.yaml file

# Define paths
TEMPLATE_ANALYSIS_OPTIONS="scripts/analysis_options_template.yaml"
TARGET_ANALYSIS_OPTIONS="lib/generated/gdev/analysis_options.yaml"

# Execute code generation command
echo "Generating code with polkadart_cli..."
dart run polkadart_cli:generate -v

# Check if generation was successful
if [ $? -ne 0 ]; then
  echo "Error during code generation."
  exit 1
fi

echo "Code generated successfully."

# Copy the analysis_options.yaml file to the generated folder
echo "Copying analysis_options.yaml file to lib/generated/gdev"
mkdir -p "lib/generated/gdev"
cp "$TEMPLATE_ANALYSIS_OPTIONS" "$TARGET_ANALYSIS_OPTIONS"

echo "Done!" 