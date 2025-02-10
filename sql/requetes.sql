-- 1. Afficher les meilleurs scores en temps réel de tous les joueurs
-- Description :

-- Cette requête permet d'obtenir le meilleur score de chaque joueur. Elle utilise la fonction d'agrégation MAX(score) et regroupe les résultats par pseudo_joueur. Les résultats sont triés par ordre décroissant des scores pour afficher les meilleurs en premier.

-- Requête SQL :

SELECT pseudo_joueur, MAX(score) AS meilleur_score
FROM session
GROUP BY pseudo_joueur
ORDER BY meilleur_score DESC
LIMIT 10;

-- 2. Requête pour obtenir les machines qui ont été réservées par un joueur spécifique et qui sont actuellement disponibles :

-- Requête SQL :

SELECT m.id_machine, m.statut_machine
FROM machine m
WHERE m.id_machine IN (
    SELECT r.id_machine
    FROM reservation r
    WHERE r.pseudo_joueur = 'Tibsous' AND r.status_reservation = 'finie'
)
AND m.statut_machine = 'disponible';

-- 3. Obtenir les statistiques d'utilisation de chaque machine
-- Description :

-- Cette requête récupère le nombre total de sessions et le temps total de jeu (en heures) pour chaque machine. Elle utilise COUNT(*) pour le nombre de sessions et SUM() combiné avec EXTRACT(EPOCH FROM (date_heure_fin - date_heure_debut))/3600 pour calculer le temps total en heures. Les résultats sont regroupés par id_machine.

-- Requête SQL :

SELECT id_machine,
       COUNT(*) AS nombre_de_sessions,
       SUM(EXTRACT(EPOCH FROM (date_heure_fin - date_heure_debut))/3600) AS temps_total_heures
FROM session
GROUP BY id_machine;

-- 4. Lister les machines actuellement disponibles
-- Description :

-- Cette requête récupère la liste des machines dont le statut est 'disponible'. Elle sélectionne les champs id_machine et nom_machine pour afficher les informations pertinentes.

-- Requête SQL :

SELECT id_machine, nom_machine
FROM machine
WHERE statut_machine = 'disponible';

-- 5. Trouver les joueurs ayant un score moyen supérieur à la moyenne générale
-- Description :

-- Cette requête imbriquée identifie les joueurs dont le score moyen est supérieur au score moyen de tous les joueurs. Elle utilise AVG(score) et GROUP BY pseudo_joueur pour calculer le score moyen par joueur, puis compare ce score à la moyenne générale obtenue via une sous-requête.

-- Requête SQL :

SELECT pseudo_joueur, AVG(score) AS score_moyen
FROM session
GROUP BY pseudo_joueur
HAVING AVG(score) > (SELECT AVG(score) FROM session);

-- 6. Afficher les jeux les plus populaires en fonction du nombre de sessions
-- Description :

-- Cette requête détermine les jeux les plus joués en comptant le nombre de sessions associées à chaque jeu. Elle joint les tables session, machine et jeu pour relier les sessions aux jeux correspondants. Les résultats sont groupés par nom_jeu et triés par ordre décroissant du nombre de sessions.

-- Requête SQL :

SELECT jeu.nom_jeu, COUNT(session.id_session) AS nombre_de_sessions
FROM session
JOIN machine ON session.id_machine = machine.id_machine
JOIN jeu ON machine.id_machine = jeu.id_machine
GROUP BY jeu.nom_jeu
ORDER BY nombre_de_sessions DESC;

-- 7. Obtenir le nombre de joueurs ayant joué sur chaque machine
-- Description :

-- Cette requête compte le nombre distinct de joueurs qui ont utilisé chaque machine. Elle utilise COUNT(DISTINCT pseudo_joueur) pour éviter de compter plusieurs fois le même joueur sur une machine donnée.

-- Requête SQL :

SELECT id_machine, COUNT(DISTINCT pseudo_joueur) AS nombre_de_joueurs
FROM session
GROUP BY id_machine;

-- 8. Trouver les machines les moins utilisées
-- Description :

-- Cette requête identifie les machines ayant le moins de sessions enregistrées. Elle peut aider à déterminer quelles machines sont moins populaires ou sous-utilisées.

-- Requête SQL :

SELECT id_machine, COUNT(*) AS nombre_de_sessions
FROM session
GROUP BY id_machine
ORDER BY nombre_de_sessions ASC
LIMIT 5;

-- 9. Lister les réservations en cours pour un joueur donné
-- Description :

-- Cette requête récupère les réservations actives d'un joueur spécifique. Elle sélectionne les réservations dont le status_reservation est 'en_attente' ou 'confirmee' pour le pseudo_joueur donné.

-- Requête SQL :

SELECT id_reservation, date_debut_reservation, date_fin_reservation, status_reservation
FROM reservation
WHERE pseudo_joueur = 'pseudo_du_joueur'
AND status_reservation IN ('en_attente', 'confirmee');

-- 10. Requête pour obtenir les joueurs ayant effectué des transactions d'un montant supérieur à la moyenne de toutes les transactions :

-- Requête SQL :
SELECT j.pseudo_joueur, SUM(t.montant_transaction) AS total_transactions
FROM joueur j
JOIN transaction t ON j.pseudo_joueur = t.pseudo_joueur
WHERE t.montant_transaction > (
    SELECT AVG(montant_transaction) FROM transaction
)
GROUP BY j.pseudo_joueur;