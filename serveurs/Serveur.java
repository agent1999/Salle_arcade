import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.logging.*;

public class Serveur {

    // Logger pour faciliter notre débogage
    private static final Logger logger = Logger.getLogger(Serveur.class.getName());

    // Valeurs par défaut
    private static final String DEFAULT_IP = "localhost";
    private static final int DEFAULT_PORT = 420;

    // On donne les valeurs par défaut
    private static String serverIP = DEFAULT_IP;
    private static int serverPort = DEFAULT_PORT;

    // Informations de connexion à la BDD de alwaysdata
    private static final String DB_PORT = ""; //PORT DE LA BASE DE DONNÉES
    private static final String DB_IP = ""; //ADRESSE IP DE LA BASE DE DONNÉES
    private static final String DB_NAME = ""; //NOM DE LA BASE DE DONNÉES
    private static final String DB_USER = ""; //IDENTIFIANT
    private static final String DB_PASSWORD = ""; //MOT DE PASSE
    private static final String DB_URL = "jdbc:postgresql://" + DB_IP + ":" + DB_PORT + "/" + DB_NAME;

    public static void main(String[] args) {
        configureServer(args);
        startServer();
    }

    // Méthode pour configurer le serveur avec les paramètres
    private static void configureServer(String[] args) {
        // Lecture des arguments de ligne de commande
        if (args.length >= 1) {
            serverIP = args[0];
        }
        if (args.length >= 2) {
            try {
                serverPort = Integer.parseInt(args[1]);
            } catch (NumberFormatException e) {
                logger.warning("Port invalide, utilisation du port par défaut");
                serverPort = DEFAULT_PORT;
            }
        }
        logger.info("Configuration du serveur : IP = " + serverIP + ", Port = " + serverPort);
    }

    // Méthode pour démarrer le serveur
    private static void startServer() {
        ServerSocket serverSocket = null;
        try {
            serverSocket = new ServerSocket(serverPort, 50, InetAddress.getByName(serverIP));
            logger.info("Serveur démarré sur " + serverIP + ":" + serverPort);

            while (true) {
                Socket clientSocket = serverSocket.accept();
                logger.info("Client connecté depuis " + clientSocket.getRemoteSocketAddress());

                // Gestion du client dans un nouveau thread pour pouvoir acceuillir plusieurs connexions  de plusieurs bornes d'arcade !
                ClientHandler clientHandler = new ClientHandler(clientSocket);
                new Thread(clientHandler).start();
            }
        } catch (BindException e) {
            logger.severe("Erreur : Le port " + serverPort + " est déjà utilisé");
        } catch (IOException e) {
            logger.severe("Erreur réseau : " + e.getMessage());
        } finally {
            if (serverSocket != null) {
                try {
                    serverSocket.close();
                    logger.info("Serveur arrêté");
                } catch (IOException e) {
                    logger.warning("Erreur lors de la fermeture du serveur : " + e.getMessage());
                }
            }
        }
    }

    // inner-class pour gérer les clients
    private static class ClientHandler implements Runnable {

        private Socket clientSocket;
        private BufferedReader in;
        private PrintWriter out;
        private Connection connection;

        // Taille maximale du message
        private static final int MAX_MESSAGE_SIZE = 27; // Le mot le plus long envoyé par le client peut-être un pseudonyme de 27 caractères

        public ClientHandler(Socket socket) {
            this.clientSocket = socket;
            try {
                // On met un timeout de 60 secondes
                clientSocket.setSoTimeout(60000);
            } catch (SocketException e) {
                logger.warning("Impossible de définir le timeout : " + e.getMessage());
            }
        }

        @Override
        public void run() {
            try {
                handleClient();
            } catch (SocketTimeoutException e) {
                logger.warning("Le client a mis trop de temps à répondre : " + e.getMessage());
                sendMessage("408 Request Timeout");
            } catch (IOException e) {
                logger.warning("Connexion avec le client interrompue : " + e.getMessage());
            } catch (SQLException e) {
                logger.severe("Erreur SQL : " + e.getMessage());
                sendMessage("500 Internal Server Error");
            } finally {
                closeEverything();
            }
        }

        private void handleClient() throws IOException, SQLException {
            in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
            out = new PrintWriter(clientSocket.getOutputStream(), true);

            // Connexion à la base de données
            try {
                connection = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
                logger.info("Connexion à la base de données réussie");
            } catch (SQLException e) {
                logger.severe("Erreur de connexion à la base de données : " + e.getMessage());
                sendMessage("500 Internal Server Error");
                return;
            }

            // Envoi du message de bienvenue
            sendMessage("Bienvenue dans ARKD1.1, commencez par écrire le pseudo du joueur, puis entrez l'identifiant de la machine, puis acceptez, ou non, le paiement. Have fun !");

            // Étape 1: Récupération du username
            String username = readLine();
            if (username == null || username.isEmpty()) {
                sendMessage("400 Invalid username");
                return;
            }

            // Vérification du username dans la base de données
            if (!isValidUsername(username)) {
                sendMessage("401 Invalid username");
                return;
            } else {
                sendMessage("200 Username valid");
            }

            // Étape 2: Récupération de l'identifiant de la machine
            String machineId = readLine();
            if (machineId == null || machineId.isEmpty()) {
                sendMessage("402 Invalid machine ID");
                return;
            }

            // Vérification du format de l'identifiant de la machine
            if (!isValidMachineFormat(machineId)) {
                sendMessage("403 Invalid machine ID format");
                return;
            } else {
                sendMessage("201 Machine ID format valid");
            }

            // Vérification de l'existence de la machine
            if (!machineExists(machineId)) {
                sendMessage("404 Machine ID does not exist");
                return;
            } else {
                sendMessage("202 Machine ID exists");
            }

            // Vérification du statut de la machine
            String machineStatus = getMachineStatus(machineId);
            logger.info("Statut actuel de la machine '" + machineId + "' : '" + machineStatus + "'");
            switch (machineStatus) {
                case "disponible":
                    sendMessage("203 Machine available");
                    // On continue
                    break;
                case "maintenance":
                case "hors-service":
                    sendMessage("405 Machine not available");
                    return;
                case "reservee":
                    // Vérifier si la réservation est pour ce joueur
                    if (isMachineReservedForUser(machineId, username)) {
                        sendMessage("204 Machine reserved for you");
                        // Si oui on continue
                        break;
                    } else {
                        sendMessage("406 Machine reserved for another user");
                        return;
                    }
                case "occupee":
                    sendMessage("407 Machine currently occupied");
                    return;
                default:
                    sendMessage("408 Unknown machine status");
                    return;
            }

            // Étape 3: Demande de paiement
            sendMessage("Souhaitez-vous payer 5 crédits pour 1 heure de jeu ? Y/n");
            String paymentResponse = readLine();
            if (paymentResponse == null || paymentResponse.equalsIgnoreCase("n")) {
                sendMessage("409 Payment declined");
                return;
            } else if (paymentResponse.equalsIgnoreCase("Y")) {
                // Vérification du solde du joueur
                if (hasEnoughCredits(username, 5)) {
                    // Décrémenter les crédits du joueur
                    decrementCredits(username, 5);
                    // Ajouter une session de jeu
                    addGameSession(username, machineId, 1); // 1 heure de jeu
                    // Mettre à jour le statut de la machine à 'occupee'
                    updateMachineStatus(machineId, "occupee");
                    sendMessage("200 Payment successful. Amusez-vous bien!");
                } else {
                    sendMessage("410 Insufficient credits");
                    return;
                }
            } else {
                sendMessage("411 Invalid payment response");
                return;
            }
        }

        // Méthode pour lire une ligne de réponse client
        private String readLine() throws IOException {
            char[] buffer = new char[MAX_MESSAGE_SIZE]; // on met la taille max pour un message définie plus haut
            int charsRead = in.read(buffer);
            if (charsRead == -1) {
                throw new IOException("Client déconnecté");
            }
            if (charsRead >= MAX_MESSAGE_SIZE) {
                sendMessage("ERROR: Message too long");
                logger.warning("Message trop long reçu du client");
                return null;
            }
            return new String(buffer, 0, charsRead).trim();
        }

        // Méthode pour envoyer un message au client
        private void sendMessage(String message) {
            if (out != null) {
                out.println(message);
                logger.info("Envoyé au client: " + message);
            }
        }

        // Méthode pour vérifier si le username existe dans la base de données
        private boolean isValidUsername(String username) throws SQLException {
            String query = "SELECT pseudo_joueur FROM joueur WHERE pseudo_joueur = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, username);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next();
                }
            }
        }

        // Méthode pour vérifier le format de l'identifiant de la machine
        private boolean isValidMachineFormat(String machineId) {
            return machineId.matches("^Mach\\d+$");
        }

        // Méthode pour vérifier si la machine existe
        private boolean machineExists(String machineId) throws SQLException {
            String query = "SELECT id_machine FROM machine WHERE id_machine = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, machineId);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next();
                }
            }
        }

        // Méthode pour obtenir le statut de la machine
        private String getMachineStatus(String machineId) throws SQLException {
            String query = "SELECT statut_machine FROM machine WHERE id_machine = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, machineId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return rs.getString("statut_machine");
                    }
                }
            }
            return "";
        }

        // Méthode pour vérifier si la machine réservée est pour le joueur
        private boolean isMachineReservedForUser(String machineId, String username) throws SQLException {
            String query = "SELECT pseudo_joueur FROM reservation WHERE id_machine = ? AND status_reservation = 'en_cours'";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, machineId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String reservedUsername = rs.getString("pseudo_joueur");
                        logger.info("La machine est reservee pour " + reservedUsername);
                        return reservedUsername.equals(username);
                    }
                }
            }
            return false;
        }

        // Méthode pour vérifier si le joueur a assez de crédits
        private boolean hasEnoughCredits(String username, int requiredCredits) throws SQLException {
            String query = "SELECT solde_joueur FROM joueur WHERE pseudo_joueur = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, username);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        double solde = rs.getDouble("solde_joueur");
                        return solde >= requiredCredits;
                    }
                }
            }
            return false;
        }

        // Méthode pour décrémenter les crédits du joueur
        private void decrementCredits(String username, int amount) throws SQLException {
            String query = "UPDATE joueur SET solde_joueur = solde_joueur - ? WHERE pseudo_joueur = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setInt(1, amount);
                ps.setString(2, username);
                ps.executeUpdate();
            }
        }

        // Méthode pour ajouter une session de jeu
        private void addGameSession(String username, String machineId, int durationHours) throws SQLException {
            String query = "INSERT INTO session (id_machine, pseudo_joueur, date_heure_debut, date_heure_fin, score) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                Timestamp startTime = new Timestamp(System.currentTimeMillis());
                Timestamp endTime = new Timestamp(System.currentTimeMillis() + durationHours * 3600 * 1000);

                ps.setString(1, machineId);
                ps.setString(2, username);
                ps.setTimestamp(3, startTime);
                ps.setTimestamp(4, endTime);
                ps.setInt(5, 0); // Score initial

                ps.executeUpdate();
            }
        }

        // Méthode pour mettre à jour le statut de la machine
        private void updateMachineStatus(String machineId, String newStatus) throws SQLException {
            String query = "UPDATE machine SET statut_machine = ? WHERE id_machine = ?";
            try (PreparedStatement ps = connection.prepareStatement(query)) {
                ps.setString(1, newStatus);
                ps.setString(2, machineId);
                ps.executeUpdate();
                logger.info("Statut de la machine " + machineId + " mis à jour en '" + newStatus + "'");
            }
        }

        // Méthode pour fermer toutes les ressources correctement et éviter de la fuite de mémoire
        private void closeEverything() {
            try {
                if (out != null) out.close();
                if (in != null) in.close();
                if (clientSocket != null) clientSocket.close();
                if (connection != null && !connection.isClosed()) connection.close();
                logger.info("Connexion avec le client terminée");
            } catch (IOException | SQLException e) {
                logger.warning("Erreur lors de la fermeture des ressources : " + e.getMessage());
            }
        }
    }
}
