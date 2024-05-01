#!/bin/bash

# Recherche tous les fichiers .dart dans le dossier lib et ses sous-dossiers
dart_files=$(find lib -type f -name "*.dart")

# Boucle sur les tailles de police de 10 à 35
for size in {10..35}; do
  # Calcule la nouvelle taille (décrémentée de 1)
  new_size=$((size - 1))
  
  # Utilise sed pour remplacer la taille actuelle par la nouvelle taille
  sed -i "s/fontSize: $size/fontSize: $new_size/g" $dart_files
done

echo "Les tailles de police ont été mises à jour avec succès dans les fichiers .dart du dossier lib et ses sous-dossiers."
