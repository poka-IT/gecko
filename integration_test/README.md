# Contexte des tests

Chaque test est précédé par le lancement d'un noeud Duniter v2s en docker [dont voici le compose](https://git.duniter.org/clients/gecko/-/blob/end2EndTests/integration_test/duniter/docker-compose.yml).

Voici le yaml de configuration de la monnaie de test éphémère: https://git.duniter.org/clients/gecko/-/blob/end2EndTests/integration_test/duniter/data/gecko_tests.json


Voici le mnemonic de test utilisé:
`pipe paddle ketchup filter life ice feel embody glide quantum ride usage`

Et les 5 premiers portefeuilles Gecko associés:
```
test1: 5FeggKqw2AbnGZF9Y9WPM2QTgzENS3Hit94Ewgmzdg5a3LNa
test2: 5E4i8vcNjnrDp21Sbnp32WHm2gz8YP3GGFwmdpfg5bHd8Whb
test3: 5FhTLzXLNBPmtXtDBFECmD7fvKmTtTQDtvBTfVr97tachA1p
test4: 5DXJ4CusmCg8S1yF6JGVn4fxgk5oFx42WctXqHZ17mykgje5
test5: 5Dq3giahrBfykJogPetZJ2jjSmhw49Fa7i6qKkseUvRJ2T3R
```

Seul les 4 premiers sont membres au démarrage.

Voici le scénario de test principal que j'ai réalisé pour le moment

Scénario 1
- Changer le noeud Duniter pour se connecter au nœud local (l'ip local est récupéré automatiquement, car le nœud est sur le host (votre pc), alors que l'app est dans son émulateur)
- Importer le coffre de test
- Effectuer une transaction du Portefeuille 1 (test1) vers le portefeuille 5 (test5)
- Vérifier que les frais de créations de compte ont bien été prélevés
- Certifier test5 avec test1, test2 et test3 et vérifier qu'il deviens bien membre
- Créer 10 blocs, puis encore 10, puis 30 de plus et vérifier à chaque fois si le compte génère bien ses DU à la bonne valeur, réévaluation comprise au bloc 50.

Des vérifications sur l'état du texte affiché à l'écran ou des widgets affichés ou non sont fait entre chaque étapes pour vérifier que tout ce passe toujours bien.
Si la moindre erreur intervient, le test s'arrête et vous informe de l'erreur en question.

Voici le code du test contenant ce scénario: https://git.duniter.org/clients/gecko/-/blob/end2EndTests/integration_test/gecko_complete.dart

Ce test dur environ 1 minutes et 15 seconds, compilation et lancement de nœud au démarrage inclus.

Voici le rendu (attention ça va assez vite ^^) :


https://tube.p2p.legal/w/kMc5c8KnLi9BpwJrM4EnKX

On remarque notamment que des blocs sont créés uniquement et directement après un extrinsic lancé depuis l'app

---

# Tuto contributeurs

**Il n'est nécessaire ni de connaître le code de Ğecko, ni de connaître Dart/flutter pour écrire un nouveau scénario de test !**

Il  vous suffit de comprendre par exemple cet extrait de code:

```
// Copy test mnemonic in clipboard
await clipCopy(testMnemonic);

// Open screen import chest
await goKey(keyRestoreChest, duration: 0);

// Tap on button to paste mnemonic
await goKey(keyPastMnemonic);

// Tap on next button 4 times to skip 3 screen
await goKey(keyGoNext);
await goKey(keyGoNext);
await goKey(keyGoNext);
await goKey(keyGoNext);

// Check if cached password checkbox is checked
final isCached = await isIconPresent(Icons.check_box);

// If not, tap on to cache password
if (!isCached) await goKey(keyCachePassword, duration: 0);

// Enter password
await enterText(keyPinForm, 'AAAAA', 0);

// Check if string "Accéder à mon coffre" is present in screen
await waitFor('Accéder à mon coffre');

// Go to wallets home
await goKey(keyGoWalletsHome, duration: 0);

// Check if string "ĞD" is present in screen
await waitFor('ĞD');

// Tap on add a new derivation button
await addDerivation();

// Tap on Wallet 5
await goKey(keyOpenWallet(test5.address));

// Copy address of Wallet 5
await goKey(keyCopyAddress);

// Check if string "Cette adresse a été copié" is present in screen
await waitFor('Cette adresse a été copié');

// Pop screen 2 time to go back home
await goBack();
await goBack();

// Create a new bloc (useless here, just to show you the method)
await spawnBlock();

// Check if string "y'a pas de lézard" is present in screen
await waitFor("y'a pas de lézard");
```

Vous avez dans ce bout de code commenté tous ce dont vous avez besoin pour effectuer un test d'intégration dans Ğecko :slight_smile: 

Vous trouverez toutes les clés de widgets disponibles dans l'app dans ce fichier: https://git.duniter.org/clients/gecko/-/blob/end2EndTests/lib/models/widgets_keys.dart

Ce sont ces clés qui vous permette d’interagir avec les widgets de l'app depuis votre test.

Pour créer un nouveau test **à partir de zero**, voici la marche à suivre:
- Suivez [le readme](https://git.duniter.org/clients/gecko/-/blob/master/README.md) pour configurer votre environnement de développement et ainsi pouvoir lancer Ğecko en mode debug dans un émulateur.
- Créer un nouveau fichier pour votre test dans le dossier `integration_test` (ici nous l’appellerons `mon_test.dart`)
- Prenez exemple sur le fichier `gecko_complete.dart` pour écrire votre test
- Lancer un émulateur android (1 seul)
- Exécutez votre test ainsi: `./integration_test/launch_test.sh mon_test`

Créer toute sorte de tests imaginable dans Ğecko est très utile pour éviter un maximum les régressions de bugs entre les différentes versions.

Si vous avez envie de nous aider, que vous ne savez presque pas coder mais que vous êtes prêt à mettre un peu les mains dans la sauce, et que vous avez une idée de scénario à tester, alors n'hésitez pas, je répondrais à toutes vos questions :slight_smile: 

A noter que ces tests permettent de tester Gecko mais aussi partiellement Duniter et l'indexer d'une même pierre.
