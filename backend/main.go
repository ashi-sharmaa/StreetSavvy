package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"

	"streetsavvy-backend/config"
	"streetsavvy-backend/models"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	// Initialize database connection
	if err := config.InitDB(); err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Create router
	r := mux.NewRouter()

	// Add CORS middleware for development
	r.Use(corsMiddleware)

	// API routes
	api := r.PathPrefix("/api").Subrouter()

	// api handlers (testing)
	api.HandleFunc("/users/{id}", getUserHandler).Methods("GET")
	//api.HandleFunc("/users/{id}/nearby", getNearbyPromsHandler).Methods("GET")
	api.HandleFunc("/campaigns/active", getActiveCampaignsHandler).Methods("GET")
	api.HandleFunc("/campaigns/nearby", getNearbyPromsHandler).Methods("GET")
	api.HandleFunc("/health", healthCheck).Methods("GET")

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("StreetSavvy Backend starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

// CORS middleware for development
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// Temporary test handlers (will be moved to handlers/ later)

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status": "healthy", "service": "streetsavvy-backend"}`))
}

func getUserHandler(w http.ResponseWriter, r *http.Request) {
	// extract user id from url 
	vars := mux.Vars(r)
	userID := vars["id"]	

	// create sql query to get data; $1 is placeholder
	query := "SELECT user_id, loyalty_tier, most_frequent_vendor, most_frequent_vendor_type, notif_sms, notif_whatsapp, notif_inapp, privacy FROM users WHERE user_id = $1"

	// run query, make struct from results
	var user models.User

	// connect to db
	err := config.DB.QueryRow(query, userID).Scan(  // ← Using config.DB global
        &user.UserID, 
        &user.LoyaltyTier, 
        &user.MostFrequentVendor, 
        &user.MostFrequentVendorType)
    
    if err != nil {
        log.Printf("Error querying user %s: %v", userID, err)
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }
    

	// send json response 
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user) // struct becomes json 
}

func getActiveCampaignsHandler(w http.ResponseWriter, r *http.Request) {
    // SQL query for active campaigns (from your test data logic)
    query := `SELECT campaign_id, vendor_id, title, code, description, geofence_radius_km, enabled
              FROM campaigns 
              WHERE enabled = true 
              AND start_date <= CURRENT_DATE 
              AND end_date >= CURRENT_DATE`
    
    // Execute query - returns multiple rows
    rows, err := config.DB.Query(query)
    if err != nil {
        log.Printf("Error querying campaigns: %v", err)
        http.Error(w, "Failed to fetch campaigns", http.StatusInternalServerError)
        return
    }
    defer rows.Close()  // Always close rows when done
    
    // Create slice to hold multiple campaigns
    var campaigns []models.Campaign
    
    // Loop through each row
    for rows.Next() {
        var campaign models.Campaign
        
        // Scan current row into struct
        err := rows.Scan(
            &campaign.CampaignID,
            &campaign.VendorID, 
            &campaign.Title,
            &campaign.Code,
            &campaign.Description,
            &campaign.GeofenceRadiusKm,
            &campaign.Enabled)
        
        if err != nil {
            log.Printf("Error scanning campaign row: %v", err)
            continue  // Skip this row, continue with next
        }
        
        // Add campaign to our slice
        campaigns = append(campaigns, campaign)
    }
    
    // Check for any iteration errors
    if err = rows.Err(); err != nil {
        log.Printf("Error iterating campaigns: %v", err)
        http.Error(w, "Error processing campaigns", http.StatusInternalServerError)
        return
    }
    
    // Return JSON array of campaigns
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(campaigns)
}

func getNearbyPromsHandler(w http.ResponseWriter, r *http.Request) {
	
		// Extract location parameters from query string
		latStr := r.URL.Query().Get("lat")
		lngStr := r.URL.Query().Get("lng")
		radiusStr := r.URL.Query().Get("radius")
		
		// Validate required parameters
		if latStr == "" || lngStr == "" {
			http.Error(w, "Missing required parameters: lat, lng", http.StatusBadRequest)
			return
		}
		
		// Convert strings to numbers
		lat, err := strconv.ParseFloat(latStr, 64)
		if err != nil {
			http.Error(w, "Invalid latitude", http.StatusBadRequest)
			return
		}
		
		lng, err := strconv.ParseFloat(lngStr, 64)
		if err != nil {
			http.Error(w, "Invalid longitude", http.StatusBadRequest)
			return
		}
		
		// Default radius to 1km if not provided
		radius := 1.0
		if radiusStr != "" {
			radius, err = strconv.ParseFloat(radiusStr, 64)
			if err != nil {
				http.Error(w, "Invalid radius", http.StatusBadRequest)
				return
			}
		}
		
		radiusMeters := int(radius * 1000)
		
		log.Printf("=== Searching near lat=%f, lng=%f, radius=%dkm ===", lat, lng, radiusMeters/1000)
		
		// Check current date and C0002 status first
		var currentDate string
		config.DB.QueryRow("SELECT CURRENT_DATE::text").Scan(&currentDate)
		log.Printf("🔧 Current date: %s", currentDate)
		
		var c2ID, c2Start, c2End string
		var c2Enabled bool
		c2Err := config.DB.QueryRow("SELECT campaign_id, enabled, start_date::text, end_date::text FROM campaigns WHERE campaign_id = 'C0002'").Scan(&c2ID, &c2Enabled, &c2Start, &c2End)
		if c2Err == nil {
			log.Printf("🔧 C0002: enabled=%t, start=%s, end=%s", c2Enabled, c2Start, c2End)
		}
		
		// Main geospatial query
		query := `
			SELECT c.campaign_id, c.vendor_id, c.title, c.code, c.description, c.geofence_radius_km
			FROM campaigns c
			JOIN vendors v ON c.vendor_id = v.vendor_id
			WHERE c.enabled = true 
			AND c.start_date <= CURRENT_DATE 
			AND c.end_date >= CURRENT_DATE
			AND ST_DWithin(
				ST_Transform(ST_SetSRID(ST_MakePoint(v.long, v.lat), 4326), 3857),
				ST_Transform(ST_SetSRID(ST_MakePoint($1, $2), 4326), 3857),
				$3
			)`
		
		// Execute query
		rows, err := config.DB.Query(query, lng, lat, radiusMeters)
		if err != nil {
			log.Printf("❌ Query error: %v", err)
			http.Error(w, "Query failed", http.StatusInternalServerError)
			return
		}
		defer rows.Close()
		
		// Collect results
		var campaigns []models.Campaign
		for rows.Next() {
			var c models.Campaign
			err := rows.Scan(&c.CampaignID, &c.VendorID, &c.Title, &c.Code, &c.Description, &c.GeofenceRadiusKm)
			if err != nil {
				log.Printf("❌ Scan error: %v", err)
				continue
			}
			log.Printf("✅ Found campaign: %s (%s)", c.CampaignID, c.Title)
			campaigns = append(campaigns, c)
		}
		
		if err = rows.Err(); err != nil {
			log.Printf("❌ Iteration error: %v", err)
		}
		
		log.Printf("=== RESULT: %d campaigns found ===", len(campaigns))
		
		// Return results
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(campaigns)
	}