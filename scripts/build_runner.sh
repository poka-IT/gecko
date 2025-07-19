#!/bin/bash

dart run build_runner build --delete-conflicting-outputs

# Fix generated g1_wallets_list.g.dart file
FILE="lib/models/g1_wallets_list.g.dart"

if [ -f "$FILE" ]; then
    # Create a temporary file for cross-platform compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - Only remove the block in IdAdapter class
        sed -i '' '/Id read(BinaryReader reader) {/,/return Id();/{
            /final numOfFields = reader\.readByte();/d
            /final fields = <int, dynamic>{/d
            /for (int i = 0; i < numOfFields; i++) reader\.readByte(): reader\.read(),/d
            /};/d
        }' "$FILE"
        sed -i '' 's/writer\.\.writeByte(0);/writer.writeByte(0);/g' "$FILE"
    else
        # Linux - Only remove the block in IdAdapter class
        sed -i '/Id read(BinaryReader reader) {/,/return Id();/{
            /final numOfFields = reader\.readByte();/d
            /final fields = <int, dynamic>{/d
            /for (int i = 0; i < numOfFields; i++) reader\.readByte(): reader\.read(),/d
            /};/d
        }' "$FILE"
        sed -i 's/writer\.\.writeByte(0);/writer.writeByte(0);/g' "$FILE"
    fi
    echo "Fixed $FILE"
fi

