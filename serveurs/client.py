#!/usr/bin/python3
# -*- coding: UTF-8 -*-

import socket
import sys
import logging
import argparse
import time

# Logger pour pouvoir deboguer facilement
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Les differentes valeurs de timeout
TIMEOUT_CONNECTION = 10  # Pour la connexion
TIMEOUT_RECEIVE = 2      # Pour réceptionner les données

def parse_arguments():
    """Analyse les arguments de ligne de commande pour obtenir l'adresse IP et le port."""
    parser = argparse.ArgumentParser(description='Client réseau TCP modulable')
    parser.add_argument('--ip', type=str, default='localhost', help="Adresse IP du serveur (par défaut: localhost)")
    parser.add_argument('--port', type=int, default=420, help="Port du serveur (par défaut: 420)")
    args = parser.parse_args()

    # On verifie que le port est correct
    if not (0 <= args.port <= 65535):
        logging.error("Le port doit être compris entre 0 et 65535.")
        sys.exit(1)
    return args.ip, args.port

def create_client_socket(adresseIP, port):
    """Crée un socket client."""
    try:
        client_socket = socket.create_connection((adresseIP, port), timeout=TIMEOUT_CONNECTION)
        logging.info(f"Connecté au serveur {adresseIP}:{port}.")
        return client_socket
    except socket.gaierror:
        logging.error("Erreur : L'adresse IP ou le nom de domaine est invalide.")
        sys.exit(1)
    except socket.timeout:
        logging.error("Erreur : Le serveur est inaccessible ou trop lent.")
        sys.exit(1)
    except ConnectionRefusedError:
        logging.error("Erreur : Le serveur refuse la connexion. Assurez-vous que le serveur est en ligne.")
        sys.exit(1)
    except Exception as e:
        logging.error(f"Erreur de connexion : {e}")
        sys.exit(1)

def receive_responses(sock):
    """Reçoit toutes les lignes envoyées par le serveur."""
    messages = []
    sock.setblocking(0)
    start_time = time.time()
    data = b""
    while True:
        # Vérifie si le timeout est dépassé grâce à la bibliothèque time !
        if time.time() - start_time > TIMEOUT_RECEIVE:
            break
        try:
            chunk = sock.recv(4096)
            if chunk:
                data += chunk
                start_time = time.time()  # Reset du timer après la réception de données
            else:
                # Si recv retourne une chaîne vide, on sort de la boucle
                break
        except BlockingIOError:
            # Aucun data disponible pour le moment
            time.sleep(0.1)  # Attend un court instant avant de réessayer
            continue
        except Exception as e:
            logging.error(f"Erreur lors de la réception des données : {e}")
            break

    # on décode et on réagence les lignes reçues si il y en a eu plusieurs
    if data:
        try:
            messages = data.decode('utf-8').split('\n')
            messages = [msg.strip() for msg in messages if msg.strip()]
        except UnicodeDecodeError as e:
            logging.error(f"Erreur de décodage des données : {e}")
    return messages

def main():
    """Fonction principale"""
    adresseIP, port = parse_arguments() #on recup l'adresse ip et le port
    client_socket = create_client_socket(adresseIP, port) # on cree le socket client

    try:
        # Lecture du message de bienvenue si il y en a un, on insiste sur la modulabilité de notre client qui peut aussi fonctionner
        # avec un serveur qui n'envoie pas de message de bienvenue
        welcome_messages = receive_responses(client_socket)
        if welcome_messages:
            for message in welcome_messages:
                print(message)
        else:
            logging.info("Aucun message de bienvenue reçu.")

        while True:
            try:
                # On demande à l'utilisateur d'entrer quelque chose
                message = input("Entrez votre message (ou 'exit' pour quitter) : ").strip()
                if message.lower() == "exit":
                    logging.info("Fermeture de la connexion.")
                    break

                # On envoie ça au serveur
                try:
                    client_socket.sendall((message + '\n').encode('utf-8'))
                    logging.info(f"Message envoyé : {message}")
                except Exception as e:
                    logging.error(f"Erreur lors de l'envoi du message : {e}")
                    break

                # Puis on reçoit la ou les réponses du serveur !
                responses = receive_responses(client_socket)
                if responses:
                    for response in responses:
                        print(response)
                else:
                    logging.warning("Pas de réponse du serveur.")
            except KeyboardInterrupt:
                logging.info("Interruption du programme par l'utilisateur (CTRL+C). Fermeture de la connexion.")
                break

    finally:
        client_socket.close()
        logging.info("Connexion fermée.")

if __name__ == "__main__":
    main()
