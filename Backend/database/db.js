const mysql = require("mysql2");

const db = mysql.createConnection({
  host: "127.0.0.1",
  port: 3306,
  user: "root",
  password: "root",
  database: "sekai_atlas"
});

db.connect((err) => {
  if (err) {
    console.error("Erreur connexion MySQL :", err);
    return;
  }

  console.log("Connecté à MySQL");
});

module.exports = db;
