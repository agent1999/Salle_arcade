# Salle d'arcade

Ce projet consiste à simuler des échanges réseaux entre un client en Python et un serveur en Java à partir d'un protocole basé sur TCP avec une base de données en PostgreSQL dans le contexte d'une salle d'arcade.

## Comment faire fonctionner la salle d'arcade

### Base de données et site web

- La base de données est nécéssaire au fonctionnement du serveur. Vous pouvez récupérer le fichier `DDL&DML.sql`, il suffira de copier l'intégralité du contenu du fichier et le coller dans le logiciel [pg Admin 4](https://www.pgadmin.org). 
    - Ne pas oublier de rajouter les informations de connexion à la base de données dans le fichier `Serveur.java`.
 
- Un site web permet de consulter les informations des joueurs. Vous pouvez récupérer les fichiers du dossier `web` et les mettre sur votre serveur web avec le logiciel [FileZilla](https://filezilla-project.org).
    - Ne pas oublier de rajouter les informations de connexion à la base de données dans le fichier `index.php`.

### Client et serveur

- Ouvrir 2 fenêtres du `Terminal`.
- Dans les 2 fenêtres, aller dans le dossier `serveurs` à l'aide de la commande `cd`.
- Pour lancer le serveur, dans l'une des fenêtres du Terminal, taper :
  ```
  java -cp "postgresql-42.7.4.jar" Serveur.java [@IP] [PORT]
  ```

    - Il se peut que le serveur ne se lance pas, la raison la plus probable est que le port soit déjà utilisé. Indiquez un port différent.
    - Sinon, il s'agit de l'adresse IP qui n'est pas valide. Indiquer une adresse IP valide.
- Pour lancer le client, dans l'autre fenêtre du Terminal, taper :
  ```
  python3 client.py --ip [@IP] --port [PORT]
  ```

    - Si le client n'arrive pas à se connecter, c'est que soit l'adresse IP et/ou le port sont différents de ceux indiqués au lancement du serveur, soit le serveur n'a pas été lancé.
- Le client et le serveur sont connectés, vous pouvez faire un échange.
- Le client envoie tour à tour un `identifiant d'un joueur`, le `nom d'une machine`, et `Y` pour être débité ou `n` pour annuler.
    - Des scénarios alternatifs existent comme une machine réservé ou un solde insuffisant.

## Adresse IP et port

Par défaut pour le serveur, l'adresse IP est `localhost` et le port est `420` mais il est possible que le port soit déjà utilisé par votre machine, auquel cas vous devez renseigner un port différent. Vous pouvez très bien renseigner l'adresse IP de la machine sur lequel se trouve le serveur et un port inutilisé. Voici des exemples :

| @IP                    | PORT                        |
| ---------------------- | --------------------------- |
| localhost              | 420                         |
| 127.0.0.1              | 1024                        |

## Journal des modifications

### Version 1.0

- Sortie initiale et version finale

## Crédits

- Merci à [Fan2Programmation](https://github.com/Fan2Programmation) et Zaky qui ont travaillé avec moi pour réaliser le projet.
- Merci à [alwaysdata](https://www.alwaysdata.com/fr/) pour accueillir la base de données et le site web.
