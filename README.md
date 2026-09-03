# NMA Auditor — installation

Outil d'audit de contenu vidéo de Newmask Agency : il collecte les vidéos verticales
d'un compte (TikTok, Instagram, Facebook, YouTube Shorts), les transcrit, analyse leurs
5 premières secondes, les classe, constitue une banque de hooks et produit un cockpit
interactif à partager.

Cette page ne sert qu'à **installer** l'outil. Un jeton fourni par Tom est nécessaire
pour accéder à l'application.

---

## Installer

Ouvre le **Terminal** (⌘ + Espace, tape « Terminal », Entrée), colle cette ligne
et appuie sur Entrée :

```bash
curl -fsSL https://raw.githubusercontent.com/CONTINUDESCROLL/nma-auditor-install/main/install.sh | bash
```

Une fenêtre te demandera le **jeton d'accès** que Tom t'a envoyé, puis le **dossier**
où installer l'application (elle ira dans un sous-dossier « NMA Auditor »). Aucun mot
de passe administrateur n'est demandé.

Si NMA Auditor est déjà installé, l'installeur le détecte et propose « Mettre à jour
ici » (tes audits sont conservés) ou « Installer ailleurs ».

---

## Ce qui va se passer

| Étape | Ce qui s'installe | Durée |
|---|---|---|
| 1 | Vérification de ton Mac | instantané |
| 2 | Jeton d'accès | quelques secondes |
| 3 | Choix du dossier d'installation | quelques secondes |
| 4 | Node, ffmpeg, yt-dlp | 1 à 3 minutes |
| 5 | Moteur de transcription (Python + modèle Whisper, 1,4 Go) | 5 à 15 minutes, instantané si Derush Studio est déjà installé |
| 6 | L'application, un lanceur sur le Bureau | quelques secondes |

À la fin, l'application s'ouvre dans le navigateur sur `http://localhost:4400`.
Au premier lancement, ouvre **Réglages** et colle les clés que Tom t'a transmises
(Anthropic, Apify, Cloudflare).

## Ensuite

- **Lancer** : double-clic sur « NMA Auditor.command » (Bureau ou dossier Applications).
- **Mettre à jour** : bouton « Mise à jour » en haut de l'application, quand il passe en vert.
- **Vérifier une installation** sans rien modifier :

```bash
curl -fsSL https://raw.githubusercontent.com/CONTINUDESCROLL/nma-auditor-install/main/install.sh | bash -s -- --verifier
```

- **Réinstaller ou réparer** : relance la commande d'installation, elle reprend là où ça a échoué et conserve tes audits.
