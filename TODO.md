Voici un **résumé/cahier des charges** prêt à envoyer à un dev pour réaliser la fonctionnalité dans ton app Flutter + Mapbox.

# Contexte & objectif

Mettre en place une carte et un système de suivi chantier permettant :

* de **visualiser les chantiers** et leur **statut**,
* de **voir la position des ouvriers en temps (quasi) réel**,
* de **gérer les pointages** (photo + horodatage matin/soir, géolocalisation),
* de **remonter incidents** (rouge) et **demandes de matériel** (orange) avec photo(s) et description,
* d’**alerter automatiquement** la direction/gestion de chantier en cas de problème.

# Rôles & permissions

* **Admin** : crée/modifie chantiers, voit tout, exporte données, gère rôles.
* **Conducteur de travaux** : gère ses chantiers, change statuts, traite incidents/demandes, reçoit notifications.
* **Ouvrier** : pointage matin/soir, envoi d’incident (rouge) ou demande matériel (orange), partage position pendant le service.

# Carte & UI (Flutter + Mapbox)

* **Carte Mapbox** (package recommandé : `mapbox_maps_flutter`) :

  * **Marqueurs chantiers** avec statut couleur :

    * Vert = OK, Orange = Demande matériel ouverte, Rouge = Problème en cours, Gris = Terminé.
  * **Marqueurs ouvriers** : pastille (photo ou initiales) + direction (bearing) + “vu il y a X min”.
  * **Clustering** si >50 chantiers/points.
* **Bottom sheet chantier** (tap sur un chantier) :

  * Titre + statut (badge couleur) + actions (changer statut si autorisé).
  * **Présence en cours** : liste des ouvriers sur site (“depuis 1h20”).
  * **Problèmes (rouge)** : liste (gravité, description, photos, assigné à, date).
  * **Demandes matériel (orange)** : item(s) demandés, quantité, urgence, état (en attente/validé/livré).
  * Boutons : “Nouveau problème”, “Nouvelle demande matériel”, “Itinéraire”, “Appeler”.

# Pointage & présence (preuve)

* **Chaque matin** : l’ouvrier fait un **check-in** avec **photo obligatoire**, horodatage **serveur**, **géolocalisation** capturée.
* **Chaque soir** : **check-out** avec photo + horodatage + géolocalisation.
* **Géofence** par chantier (ex. rayon 150–200 m) pour **valider présence** auto et détecter entrées/sorties.
* **Règles** : pointage possible uniquement **pendant plage horaire** du chantier ; si hors géofence → avertissement + enregistrement quand même avec étiquette “hors zone”.

# Incidents & demandes matériel

* **Incident (Rouge)** : titre, description, **photo(s)**, sévérité (mineur/critique), chantier, localisation, assignation, statut (ouvert, en cours, résolu), fil de commentaires.
* **Demande matériel (Orange)** : item(s) (liste sélectionnable + champ libre), quantité, urgence, **photo(s)** éventuelles, statut (en attente/validé/livré), date souhaitée.
* **Notifications** : création/MAJ d’un incident/demande ⇒ push immédiat aux **conducteurs** concernés + **admin** (configurable).

# Notifications (temps réel)

* **Push** sur :

  * Nouveau **incident (rouge)**.
  * Nouvelle **demande matériel (orange)**.
  * **Check-in en retard** (optionnel : seuil paramétrable).
  * **Sortie anticipée** / absence de check-out.
  * **Entrée/sortie géofence** (optionnel, avec anti-spam/anti-rebond).

# Données (modèle minimal)

* `chantiers/{id}` : `{nom, adresse, center:{lat,lng}, rayon, statut, chef_chantier_id}`
* `ouvriers/{id}` : `{nom, role, avatarUrl, actif}`
* `worker_locations/{ouvrierId}` : `{lat,lng, speed, heading, lastUpdate, on_shift, chantier_id?}`
* `presences/{id}` : `{ouvrier_id, chantier_id, type: "checkin|checkout", at: serverTimestamp, lat,lng, photoUrl}`
* `incidents/{id}` : `{chantier_id, created_by, titre, description, severite, statut, photos:[...], assigned_to, created_at, updated_at}`
* `demande_materiel/{id}` : `{chantier_id, created_by, items:[{label, qty, unit}], urgence, statut, photos:[...], created_at, updated_at}`
* **Traçabilité** : `activity_logs` pour auditer changements de statut/assignation.

# Sécurité & conformité (UE/RGPD)

* **Consentement explicite** pour suivi de position, **actif uniquement sur les heures de travail**.
* Paramètres de **précision/intervalle** ajustés pour économie de batterie (ex. 60–120 s en mouvement, 3–5 min à l’arrêt ; distanceFilter 25–50 m).
* **Rétention** : définir durées (ex. présences/incidents 3–5 ans ; traces brutes de localisation 30–90 jours).
* Droits d’accès : un ouvrier **voit uniquement ses données** et les chantiers auxquels il est affecté.

# Technique (recommandations)

* **Mobile** : Flutter, `mapbox_maps_flutter`, `geolocator` + service **foreground** Android / background updates iOS (WhenInUse/Always).
  Option robuste : `flutter_background_geolocation` (TransistorSoft).
* **Back-end** (au choix) :

  * **Firestore** (+ Firebase Auth, Storage, Cloud Functions pour triggers & push).
  * **Supabase** (Postgres + Realtime + Auth + Storage, triggers SQL + Edge Functions).
* **Push** : FCM (Android/iOS).
* **Médias** : upload photo vers Storage, redimensionnement + compression côté app, **horodatage serveur** à l’écriture.
* **Offline-first** : cache local + file d’attente des events (pointages, incidents) puis sync.

# Parcours clés (acceptation)

1. **Carte** affiche chantiers (couleur par statut) + ouvriers avec “vu il y a X min”.
2. **Ouvrier** peut faire **check-in** (photo requise) si dans géofence ; horodatage serveur + coordonnées enregistrés.
3. **Ouvrier** peut créer **incident (rouge)** avec photo(s) + description ⇒ **push** au conducteur/admin.
4. **Ouvrier** peut créer **demande matériel (orange)**, lister précisément le matériel ⇒ **push** au conducteur/admin.
5. **Conducteur** change statut chantier, assigne incident, marque demande comme “livrée”.
6. **Admin/Conducteur** voit l’historique des pointages et export CSV (bonus).
7. **Règles d’accès** respectées selon rôle.

# Indicateurs & exports (optionnel)

* Taux de **retards check-in**, incidents ouverts vs résolus, délai moyen de résolution, demandes matériel en attente.
* **Exports CSV** : présences par chantier/période, incidents, demandes matériel.

# Livrables attendus

* App Flutter intégrée (pages : Carte, Chantier, Pointage, Incident, Demande matériel).
* Back-end configuré (Auth, BDD/collections, Storage, fonctions push).
* **Règles de sécurité** (Firestore ou Supabase RLS) conformes aux rôles.
* **Documentation** d’installation, variables d’environnement, clés Mapbox/FCM, et guide d’utilisation.
* Jeux de **tests** basiques (unitaires + e2e sur flux check-in/incident/demande).

---

Si tu veux, je peux te le décliner **au format Firestore** ou **Supabase** avec les règles/SQL et 2–3 écrans Flutter d’exemple (formulaire incident/demande + bottom sheet chantier).
