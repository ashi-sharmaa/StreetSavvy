package config

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    "time"

    _ "github.com/lib/pq"
)

// Global database connection pool
var DB *sql.DB

// InitDB initializes the global database connection pool
func InitDB() error {
    // Get database configuration from environment variables
    host := getEnv("DB_HOST", "localhost")
    port := getEnv("DB_PORT", "5432")
    user := getEnv("DB_USER", "postgres")
    password := getEnv("DB_PASSWORD", "")
    dbname := getEnv("DB_NAME", "streetsavvy")
    sslmode := getEnv("DB_SSLMODE", "disable")

    // Build connection string
    connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        host, port, user, password, dbname, sslmode)

    // DEBUG: Print connection string (remove password for security)
    debugConnStr := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s",
        host, port, user, dbname, sslmode)
    log.Printf("Attempting to connect with: %s", debugConnStr)

    // Open database connection pool
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return fmt.Errorf("error opening database: %v", err)
    }

    // Test the connection
    log.Printf("Testing database connection...")
    if err := db.Ping(); err != nil {
        return fmt.Errorf("error connecting to database: %v", err)
    }

    log.Printf("Database connection successful!")

    // Configure connection pool for performance
    db.SetMaxOpenConns(25)                 // Maximum 25 concurrent connections
    db.SetMaxIdleConns(5)                  // Keep 5 connections ready
    db.SetConnMaxLifetime(5 * time.Minute) // Refresh connections every 5 minutes

    // Store in global variable
    DB = db

    return nil
}

// Helper function to get environment variables with defaults
func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}