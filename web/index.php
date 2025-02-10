<!DOCTYPE html>
<html lang="fr">
<?php
session_start();

// Informations de connexion à la BDD à rajouter
$dbconn = pg_connect("host= port= user= password= dbname=") or die('Could not connect: ' . pg_last_error());

// Fonction pour sécuriser les entrées utilisateur
function sanitize_input($data) {
    return htmlspecialchars(trim($data), ENT_QUOTES, 'UTF-8');
}

// Gestion de la déconnexion
if (isset($_GET['action']) && $_GET['action'] == 'logout') {
    session_destroy();
    header("Location: index.php");
    exit();
}

// Gestion de l'inscription
if (isset($_POST['action']) && $_POST['action'] == 'register') {
    $pseudo = sanitize_input($_POST['pseudo']);
    $mdp = sanitize_input($_POST['mdp']);
    
    $hashed_mdp = password_hash($mdp, PASSWORD_DEFAULT);

    if (!empty($pseudo) && !empty($mdp)) {
        // Vérifier si le pseudo existe déjà
        $query = 'SELECT pseudo FROM utilisateurs WHERE pseudo = $1';
        $result = pg_query_params($dbconn, $query, array($pseudo));
        if (pg_num_rows($result) > 0) {
            $register_error = "Le pseudo existe déjà.";
        } else {
            // Insérer dans la table utilisateurs
            $insert_utilisateurs = 'INSERT INTO utilisateurs (pseudo, mot_de_passe) VALUES ($1, $2)';
            $utilisateur_result = pg_query_params($dbconn, $insert_utilisateurs, array($pseudo, $hashed_mdp));
            if ($utilisateur_result) {
                $register_success = "Inscription réussie. Vous pouvez maintenant vous connecter.";
            } else {
                $register_error = "Erreur lors de l'inscription. Veuillez réessayer.";
            }
        }
    }
}

// Gestion de la connexion
if (isset($_POST['action']) && $_POST['action'] == 'login') {
    $pseudo = sanitize_input($_POST['pseudo']);
    $mdp = sanitize_input($_POST['mdp']);

    if (!empty($pseudo) && !empty($mdp)) {
        // Récupérer l'utilisateur
        $query = 'SELECT mot_de_passe FROM utilisateurs WHERE pseudo = $1';
        $result = pg_query_params($dbconn, $query, array($pseudo));
        if (pg_num_rows($result) == 1) {
            $user = pg_fetch_assoc($result);
            if (password_verify($mdp, $user['mot_de_passe'])) {
                // Authentification réussie
                $_SESSION['pseudo'] = $pseudo;
                header("Location: index.php");
                exit();
            } else {
                $login_error = "Mot de passe incorrect.";
            }
        } else {
            $login_error = "Pseudo inexistant.";
        }
    } else {
        $login_error = "Tous les champs sont obligatoires.";
    }
}

// Fonction pour vérifier si l'utilisateur est connecté
function is_logged_in() {
    return isset($_SESSION['pseudo']);
}
?>
<head>
    <title>Arcade à GOGO - Connexion</title>
    <meta charset="utf-8">
    <meta name="titre" content="Arcade à GOGO"/>
    <meta name="description" content="Arcade à GOGO"/>
    <meta name="auteur" content="22302932, zacky, et tibsous"/>
    <meta name="date" content="01/12/2024"/>
    <meta name="lieu" content="CY CERGY PARIS UNIVERSITÉ, 2 Avenue Adolphe Chauvin, 95300 Pontoise"/>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
    <link rel="icon" href="images/favicon.ico"/>
</head>

<body>
    <main>
        <h1>Arcade à GOGO</h1>
        <?php
        if (is_logged_in()) {
            // Afficher les informations de l'utilisateur
            $pseudo = sanitize_input($_SESSION['pseudo']);

            // 1ère requête SQL : Afficher les informations personnelles du joueur
            $query = 'SELECT i.pseudo, i.nom, i.prenom, a.numero_et_voie, a.code_postal, a.commune, i.telephone, i.email, i.date_naissance
                      FROM identite i
                      JOIN adresse a ON i.id_adresse = a.id_adresse
                      WHERE i.pseudo = $1';
            $result = pg_query_params($dbconn, $query, array($pseudo));
            if ($result && pg_num_rows($result) == 1) {
                $line = pg_fetch_assoc($result);
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Vos informations personnelles</h2>\n";   
                        echo "\t\t\t\t<ul>\n";
                            echo "\t\t\t\t\t<li>Nom : " . htmlspecialchars($line['nom']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Prénom : " . htmlspecialchars($line['prenom']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Adresse : " . htmlspecialchars($line['numero_et_voie']) . ", " . htmlspecialchars($line['code_postal']) . " " . htmlspecialchars($line['commune']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Téléphone : " . htmlspecialchars($line['telephone']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Email : " . htmlspecialchars($line['email']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Date de naissance : " . htmlspecialchars($line['date_naissance']) . "</li>\n";
                        echo "\t\t\t\t</ul>\n";
                echo "\t\t\t</section>\n";
                pg_free_result($result);
            } else {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Erreur</h2>\n";   
                    echo "\t\t\t\t<p>Impossible de récupérer vos informations personnelles.</p>\n";
                echo "\t\t\t</section>\n";
            }

            // 2nde requête SQL : Afficher les informations générales du joueur
            $query = 'SELECT j.pseudo_joueur, j.date_inscription_joueur, j.carte_fidelite_id_joueur, j.points_fidelite_joueur, j.solde_joueur
                      FROM joueur j
                      WHERE j.pseudo_joueur = $1';
            $result = pg_query_params($dbconn, $query, array($pseudo));
            if ($result && pg_num_rows($result) == 1) {
                $line = pg_fetch_assoc($result);
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Vos informations en tant que joueur</h2>\n";   
                        echo "\t\t\t\t<ul>\n";
                            echo "\t\t\t\t\t<li>Pseudo : " . htmlspecialchars($line['pseudo_joueur']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Date d'inscription : " . htmlspecialchars($line['date_inscription_joueur']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Carte de fidélité numéro : " . htmlspecialchars($line['carte_fidelite_id_joueur']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Points de fidélité : " . htmlspecialchars($line['points_fidelite_joueur']) . "</li>\n";
                            echo "\t\t\t\t\t<li>Solde : " . htmlspecialchars($line['solde_joueur']) . " crédits</li>\n";
                        echo "\t\t\t\t</ul>\n";
                echo "\t\t\t</section>\n";
                pg_free_result($result);
            } else {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Erreur</h2>\n";   
                    echo "\t\t\t\t<p>Impossible de récupérer vos informations en tant que joueur.</p>\n";
                echo "\t\t\t</section>\n";
            }

            // 3ème requête SQL : Afficher les réservations actives du joueur
            $query = 'SELECT r.id_reservation, r.date_debut_reservation, r.date_fin_reservation, r.status_reservation
                      FROM reservation r
                      WHERE r.pseudo_joueur = $1
                      AND r.status_reservation IN (\'en_attente\', \'confirmee\')';
            $result = pg_query_params($dbconn, $query, array($pseudo));
            if ($result) {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Vos réservations pour s'entraîner</h2>\n";   
                        if (pg_num_rows($result) > 0) {
                            echo "\t\t\t\t<ul>\n";
                            $i = 1;
                            while ($line = pg_fetch_assoc($result)) {
                                echo "\t\t\t\t\t<li>\n";
                                    echo "\t\t\t\t\t\t<h3>Réservation " . $i . "</h3>\n";
                                    echo "\t\t\t\t\t\t<ul>\n";
                                        echo "\t\t\t\t\t\t\t<li>ID de la réservation : " . htmlspecialchars($line['id_reservation']) . "</li>\n";
                                        echo "\t\t\t\t\t\t\t<li>Début : " . htmlspecialchars($line['date_debut_reservation']) . "</li>\n";
                                        echo "\t\t\t\t\t\t\t<li>Fin : " . htmlspecialchars($line['date_fin_reservation']) . "</li>\n";
                                        echo "\t\t\t\t\t\t\t<li>Statut : " . htmlspecialchars($line['status_reservation']) . "</li>\n";
                                    echo "\t\t\t\t\t\t</ul>\n";
                                echo "\t\t\t\t\t</li>\n";
                                $i++;
                            }
                            echo "\t\t\t\t</ul>\n";
                        } else {
                            echo "\t\t\t\t<p>Aucune réservation active.</p>\n";
                        }
                echo "\t\t\t</section>\n";
                pg_free_result($result);
            }

            // 4ème requête SQL : Afficher les machines disponibles
            $query = 'SELECT id_machine, nom_machine
                      FROM machine
                      WHERE statut_machine = \'disponible\'';
            $result = pg_query($dbconn, $query) or die('Query failed: ' . pg_last_error());
            if ($result && pg_num_rows($result) > 0) {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Les bornes d'arcades disponibles à essayer</h2>\n";   
                        echo "\t\t\t\t<ul>\n";
                        while ($line = pg_fetch_assoc($result)) {
                            echo "\t\t\t\t\t<li>" . htmlspecialchars($line['nom_machine']) . " (" . htmlspecialchars($line['id_machine']) . ")</li>\n";
                        }
                        echo "\t\t\t\t</ul>\n";       
                echo "\t\t\t</section>\n";
                pg_free_result($result);
            } else {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Les bornes d'arcades disponibles à essayer</h2>\n";   
                    echo "\t\t\t\t<p>Aucune borne disponible pour le moment.</p>\n";       
                echo "\t\t\t</section>\n";
            }

            // 5ème requête SQL : Afficher le meilleur score de chaque joueur
            $query = 'SELECT j.pseudo_joueur, MAX(s.score) AS meilleur_score 
                      FROM session s
                      JOIN joueur j ON s.pseudo_joueur = j.pseudo_joueur
                      GROUP BY j.pseudo_joueur 
                      ORDER BY meilleur_score DESC 
                      LIMIT 10';
            $result = pg_query($dbconn, $query) or die('Query failed: ' . pg_last_error());
            if ($result && pg_num_rows($result) > 0) {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Le meilleur score de chaque joueur à battre</h2>\n";   
                        echo "\t\t\t\t<ul>\n";
                        while ($line = pg_fetch_assoc($result)) {
                            echo "\t\t\t\t\t<li>" . htmlspecialchars($line['pseudo_joueur']) . " : " . htmlspecialchars($line['meilleur_score']) . "</li>\n";
                        }
                        echo "\t\t\t\t</ul>\n";
                echo "\t\t\t</section>\n";
                pg_free_result($result);
            } else {
                echo "\t\t<section>\n";
                    echo "\t\t\t\t<h2>Le meilleur score de chaque joueur à battre</h2>\n";   
                    echo "\t\t\t\t<p>Aucun score enregistré pour le moment.</p>\n";
                echo "\t\t\t</section>\n";
            }

            // 6ème requête SQL : Modification du contenu de la base (UPDATE)
            // Mise à jour de l'adresse email de l'utilisateur
            if (isset($_POST['action']) && $_POST['action'] == 'update_email') {
                $new_email = sanitize_input($_POST['new_email']);
                if (filter_var($new_email, FILTER_VALIDATE_EMAIL)) {
                    $update_query = 'UPDATE identite SET email = $1 WHERE pseudo = $2';
                    $update_result = pg_query_params($dbconn, $update_query, array($new_email, $pseudo));
                    if ($update_result) {
                        $update_success = "Adresse email mise à jour avec succès.";
                    } else {
                        $update_error = "Erreur lors de la mise à jour de l'adresse email.";
                    }
                } else {
                    $update_error = "Adresse email invalide.";
                }
            }

            // Afficher le formulaire de mise à jour de l'email
            echo "\t\t<section>\n";
                echo "\t\t\t\t<h2>Mettre à jour votre adresse email</h2>\n";
                if (isset($update_success)) {
                    echo "\t\t\t\t<p style=\"color: green;\">" . htmlspecialchars($update_success) . "</p>\n";
                }
                if (isset($update_error)) {
                    echo "\t\t\t\t<p style=\"color: red;\">" . htmlspecialchars($update_error) . "</p>\n";
                }
                echo "\t\t\t\t<form action=\"index.php\" method=\"POST\">\n";
                    echo "\t\t\t\t\t<input type=\"hidden\" name=\"action\" value=\"update_email\" />\n";
                    echo "\t\t\t\t\t<label for=\"new_email\">Nouvelle adresse email :</label>\n";
                    echo "\t\t\t\t\t<input type=\"email\" name=\"new_email\" id=\"new_email\" required />\n";
                    echo "\t\t\t\t\t<input type=\"submit\" value=\"Mettre à jour\" />\n";
                echo "\t\t\t\t</form>\n";
            echo "\t\t\t</section>\n";

            // 7ème requête SQL : Insertion d'une nouvelle réservation (INSERT)
            if (isset($_POST['action']) && $_POST['action'] == 'make_reservation') {
                $machine_id = sanitize_input($_POST['machine_id']);
                // Vérifier le format de l'ID de la machine
                if (preg_match('/^Mach\d+$/', $machine_id)) {
                    // Vérifier si la machine est disponible
                    $status_query = 'SELECT statut_machine FROM machine WHERE id_machine = $1';
                    $status_result = pg_query_params($dbconn, $status_query, array($machine_id));
                    if ($status_result && pg_num_rows($status_result) == 1) {
                        $status_row = pg_fetch_assoc($status_result);
                        if ($status_row['statut_machine'] == 'disponible') {
                            // Insérer la réservation
                            $insert_reservation = 'INSERT INTO reservation (id_reservation, date_debut_reservation, date_fin_reservation, status_reservation, pseudo_joueur, id_machine) 
                                                   VALUES (DEFAULT, CURRENT_DATE, CURRENT_DATE + INTERVAL \'1 hour\', \'en_cours\', $1, $2)';
                            $insert_result = pg_query_params($dbconn, $insert_reservation, array($pseudo, $machine_id));
                            if ($insert_result) {
                                // Mettre à jour le statut de la machine à 'occupee'
                                $update_status = 'UPDATE machine SET statut_machine = \'occupee\' WHERE id_machine = $1';
                                $update_result = pg_query_params($dbconn, $update_status, array($machine_id));
                                if ($update_result) {
                                    $reservation_success = "Réservation effectuée avec succès. La machine est maintenant occupée.";
                                } else {
                                    $reservation_error = "Réservation effectuée, mais impossible de mettre à jour le statut de la machine.";
                                }
                            } else {
                                $reservation_error = "Erreur lors de la réservation.";
                            }
                        } else {
                            $reservation_error = "La machine n'est pas disponible pour la réservation.";
                        }
                    } else {
                        $reservation_error = "Machine inexistante.";
                    }
                    pg_free_result($status_result);
                } else {
                    $reservation_error = "Format d'ID de machine invalide.";
                }
            }

            // Afficher le formulaire de réservation
            echo "\t\t<section>\n";
                echo "\t\t\t\t<h2>Faire une nouvelle réservation</h2>\n";
                if (isset($reservation_success)) {
                    echo "\t\t\t\t<p style=\"color: green;\">" . htmlspecialchars($reservation_success) . "</p>\n";
                }
                if (isset($reservation_error)) {
                    echo "\t\t\t\t<p style=\"color: red;\">" . htmlspecialchars($reservation_error) . "</p>\n";
                }
                echo "\t\t\t\t<form action=\"index.php\" method=\"POST\">\n";
                    echo "\t\t\t\t\t<input type=\"hidden\" name=\"action\" value=\"make_reservation\" />\n";
                    echo "\t\t\t\t\t<label for=\"machine_id\">ID de la machine :</label>\n";
                    echo "\t\t\t\t\t<input type=\"text\" name=\"machine_id\" id=\"machine_id\" required pattern=\"^Mach\\d+$\" title=\"Format attendu : Mach suivi de chiffres, par exemple Mach1\" />\n";
                    echo "\t\t\t\t\t<input type=\"submit\" value=\"Réserver\" />\n";
                echo "\t\t\t\t</form>\n";
            echo "\t\t\t</section>\n";

            // Déconnexion
            echo "\t\t\t<section>\n";
                echo "\t\t\t\t<a href=\"index.php?action=logout\">Déconnexion</a>\n";
            echo "\t\t\t</section>\n";

        } else {
            // Afficher le formulaire de connexion et d'inscription
            echo "\t\t<section>\n";
                echo "\t\t\t\t<h2>Connexion</h2>\n";
                if (isset($login_error)) {
                    echo "\t\t\t\t<p style=\"color: red;\">" . htmlspecialchars($login_error) . "</p>\n";
                }
                echo "\t\t\t\t<form action=\"index.php\" method=\"POST\">\n";
                    echo "\t\t\t\t\t<input type=\"hidden\" name=\"action\" value=\"login\" />\n";
                    echo "\t\t\t\t\t<fieldset style=\"display:inline-block;\">\n";
                        echo "\t\t\t\t\t\t<legend>Connexion</legend>\n";
                        echo "\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t<label for=\"pseudo\">Pseudo</label>\n";
                            echo "\t\t\t\t\t\t\t<input type=\"text\" name=\"pseudo\" id=\"pseudo\" required />\n";
                        echo "\t\t\t\t\t\t</div>\n";
                        echo "\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t<label for=\"mdp\">Mot de passe</label>\n";
                            echo "\t\t\t\t\t\t\t<input type=\"password\" name=\"mdp\" id=\"mdp\" required />\n";
                        echo "\t\t\t\t\t\t</div>\n";
                        echo "\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t<input type=\"submit\" value=\"Connexion\" />\n";
                        echo "\t\t\t\t\t\t</div>\n";
                    echo "\t\t\t\t\t</fieldset>\n";
                echo "\t\t\t\t</form>\n";
            echo "\t\t\t</section>\n";

            echo "\t\t<section>\n";
                echo "\t\t\t\t<h2>Inscription</h2>\n";
                if (isset($register_error)) {
                    echo "\t\t\t\t\t<p style=\"color: red;\">".$register_error."</p>\n";
                }
                if (isset($register_success)) {
                    echo "\t\t\t\t\t<p style=\"color: green;\">".$register_success."</p>\n";
                }
                echo "\t\t\t\t\t<form action=\"index.php\" method=\"POST\">\n";
                    echo "\t\t\t\t\t\t<input type=\"hidden\" name=\"action\" value=\"register\" />\n";
                    echo "\t\t\t\t\t\t<fieldset style=\"display:inline-block;\">\n";
                        echo "\t\t\t\t\t\t\t<legend>Inscription</legend>\n";
                        echo "\t\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t\t<label for=\"pseudo\">Pseudo</label>\n";
                            echo "\t\t\t\t\t\t\t\t<input type=\"text\" name=\"pseudo\" id=\"pseudo\" required/>\n";
                        echo "\t\t\t\t\t\t\t</div>\n";
                        echo "\t\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t\t<label for=\"mdp\">Mot de passe</label>\n";
                            echo "\t\t\t\t\t\t\t\t<input type=\"password\" name=\"mdp\" id=\"mdp\" required/>\n";
                        echo "\t\t\t\t\t\t\t</div>\n";
                        echo "\t\t\t\t\t\t\t<div>\n";
                            echo "\t\t\t\t\t\t\t\t<input type=\"submit\" value=\"Inscription\"/>\n";
                        echo "\t\t\t\t\t\t\t</div>\n";
                    echo "\t\t\t\t\t\t</fieldset>\n";
                echo "\t\t\t\t\t</form>\n";
            echo "\t\t\t\t</section>\n";
        }
        ?>
    </main>
</body>

</html>
