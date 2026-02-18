#!/bin/bash

set -e

# Intègre les traductions Weblate dans master via une branche de PR.
#
# Workflow:
#   1. Fetch les dernières modifications
#   2. Crée/recrée la branche integrate-weblate depuis master
#   3. Merge origin/weblate dedans
#   4. Push et propose de créer la PR
#
# Après merge de la PR sur master, lancer avec --cleanup pour
# supprimer la branche weblate distante (Weblate la recréera
# automatiquement depuis master à jour).
#
# Usage:
#   ./scripts/integrate-weblate.sh           # intégrer les traductions
#   ./scripts/integrate-weblate.sh --cleanup  # post-merge: reset weblate

BRANCH="integrate-weblate"
REMOTE="origin"
WEBLATE_BRANCH="weblate"

cleanup() {
    echo "=== Post-merge : suppression de la branche weblate distante ==="
    echo "Weblate la recréera automatiquement depuis master à jour."
    echo ""

    if ! git ls-remote --exit-code "$REMOTE" "refs/heads/$WEBLATE_BRANCH" > /dev/null 2>&1; then
        echo "La branche $REMOTE/$WEBLATE_BRANCH n'existe pas. Rien à faire."
        exit 0
    fi

    read -rp "Supprimer $REMOTE/$WEBLATE_BRANCH ? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Annulé."
        exit 0
    fi

    git push "$REMOTE" --delete "$WEBLATE_BRANCH"
    echo ""
    echo "Branche $REMOTE/$WEBLATE_BRANCH supprimée."
    echo "Weblate recréera sa branche depuis master au prochain commit de traduction."

    # Nettoyage de la branche d'intégration locale et distante
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH"
        echo "Branche locale $BRANCH supprimée."
    fi
    if git ls-remote --exit-code "$REMOTE" "refs/heads/$BRANCH" > /dev/null 2>&1; then
        git push "$REMOTE" --delete "$BRANCH"
        echo "Branche distante $REMOTE/$BRANCH supprimée."
    fi

    exit 0
}

integrate() {
    echo "=== Intégration des traductions Weblate ==="
    echo ""

    # Vérifier qu'on n'est pas en plein merge/rebase
    if [[ -d .git/MERGE_HEAD ]] || [[ -f .git/MERGE_HEAD ]]; then
        echo "ERREUR: Un merge est en cours. Résolvez-le d'abord ou faites 'git merge --abort'."
        exit 1
    fi

    # Fetch
    echo "Fetch des dernières modifications..."
    git fetch "$REMOTE"

    # Vérifier que la branche weblate existe
    if ! git ls-remote --exit-code "$REMOTE" "refs/heads/$WEBLATE_BRANCH" > /dev/null 2>&1; then
        echo "La branche $REMOTE/$WEBLATE_BRANCH n'existe pas. Rien à intégrer."
        exit 0
    fi

    # Vérifier s'il y a des différences à intégrer
    local diff_count
    diff_count=$(git rev-list --count "$REMOTE/master..$REMOTE/$WEBLATE_BRANCH" 2>/dev/null || echo "0")
    if [[ "$diff_count" == "0" ]]; then
        echo "Aucun nouveau commit sur $REMOTE/$WEBLATE_BRANCH. Rien à intégrer."
        exit 0
    fi
    echo "$diff_count commit(s) à intégrer depuis $REMOTE/$WEBLATE_BRANCH"
    echo ""

    # Sauvegarder la branche courante
    local current_branch
    current_branch=$(git branch --show-current)

    # Supprimer la branche d'intégration si elle existe déjà
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        echo "Suppression de l'ancienne branche locale $BRANCH..."
        git branch -D "$BRANCH"
    fi

    # Créer la branche d'intégration depuis master
    echo "Création de $BRANCH depuis $REMOTE/master..."
    git checkout -b "$BRANCH" "$REMOTE/master"
    echo ""

    # Merge
    echo "Merge de $REMOTE/$WEBLATE_BRANCH..."
    if git merge "$REMOTE/$WEBLATE_BRANCH" -m "integrate weblate translations"; then
        echo ""
        echo "Merge réussi sans conflit."
    else
        echo ""
        echo "Des conflits ont été détectés dans les fichiers suivants :"
        git diff --name-only --diff-filter=U
        echo ""
        echo "Résolvez les conflits, puis lancez :"
        echo "  git add assets/translations/*.json"
        echo "  git commit"
        echo "  git push $REMOTE $BRANCH"
        echo ""
        echo "Puis créez la PR manuellement ou relancez ce script."
        exit 1
    fi

    # Push
    echo "Push de $BRANCH..."
    git push -u "$REMOTE" "$BRANCH" --force-with-lease
    echo ""

    echo "=== Terminé ==="
    echo ""
    echo "Prochaines étapes :"
    echo "  1. Créer une PR : $BRANCH → master"
    echo "  2. Après merge de la PR, lancer :"
    echo "     ./scripts/integrate-weblate.sh --cleanup"
    echo ""

    # Revenir sur la branche d'origine
    if [[ "$current_branch" != "$BRANCH" && -n "$current_branch" ]]; then
        git checkout "$current_branch"
    fi
}

# Main
case "${1:-}" in
    --cleanup)
        cleanup
        ;;
    --help|-h)
        echo "Usage: $0 [--cleanup|--help]"
        echo ""
        echo "  (sans argument)  Intégrer les traductions Weblate dans une branche de PR"
        echo "  --cleanup        Post-merge : supprimer la branche weblate distante"
        echo "  --help           Afficher cette aide"
        ;;
    "")
        integrate
        ;;
    *)
        echo "Option inconnue: $1"
        echo "Usage: $0 [--cleanup|--help]"
        exit 1
        ;;
esac
