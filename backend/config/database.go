package config

import (
    "database/sql"
    "fmt"
    "os"
    "log"  // Add this import

    _ "github.com/lib/pq"
)

func InitDB() (*sql.DB, error) {
    // Get database configuration from environment variables
    host := getEnv("DB_HOST", "localhost")
    port := getEnv("DB_PORT", "5432")
    user := getEnv("DB_USER", "postgres")
    password := getEnv("DB_PASSWORD", "")
    dbname := getEnv("DB_NAME", "streetsavvy")
    sslmode := getEnv("DB_SSLMODE", "disable")

    // Build connection string with explicit SCRAM support
    connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        host, port, user, password, dbname, sslmode)

    // DEBUG: Print connection string (remove password for security)
    debugConnStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s",
        host, port, user, dbname, sslmode)
    log.Printf("Attempting to connect with: %s", debugConnStr)

    // Open database connection
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return nil, fmt.Errorf("error opening database: %v", err)
    }

    // Test the connection
    log.Printf("Testing database connection...")
    if err := db.Ping(); err != nil {
        return nil, fmt.Errorf("error connecting to database: %v", err)
    }

    log.Printf("Database connection successful!")

    // Set connection pool settings for scalability
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(5)

    return db, nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}