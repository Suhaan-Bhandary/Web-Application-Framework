#include "crystal.h"
#include "./db/models/initializeTables.h"

int main() {
    // Set public and template folder path relative to the root folder
    http::Config::TEMPLATE_DIR_PATH = "/example/app/templates/";
    http::Config::PUBLIC_DIR_PATH = "/example/app/public/";

    // Configure Database
    database::SQLite::configDatabase("server.db");

    // Load models
    database::initializeTables();

    // Creating TCP/IP Server
    http::TcpServer server = http::TcpServer("127.0.0.1", 8080);
    server.startListen();

    return 0;
}