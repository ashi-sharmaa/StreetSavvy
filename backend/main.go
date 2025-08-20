package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"fmt"
	"database/sql"

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
	api.HandleFunc("/users/{id}/nearby-campaigns", getUserNearbyPromsHandler).Methods("GET")
	api.HandleFunc("/campaigns/active", getActiveCampaignsHandler).Methods("GET")
	api.HandleFunc("/health", healthCheck).Methods("GET")
	api.HandleFunc("/users/{user_id}/campaigns/{campaign_id}/engage", recordEngagementHandler).Methods("POST")

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



func getUserNearbyPromsHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from URL path
	vars := mux.Vars(r)
	userID := vars["id"]
	log.Printf("Getting campaigns for user %s", userID)

	// Step 1: Get user's latest location from user_location_events table
	var userLat, userLng float64
	locationQuery := `
		SELECT lat, long FROM user_location_events
		WHERE user_id = $1
		ORDER BY event_time DESC
		LIMIT 1`
	
	err := config.DB.QueryRow(locationQuery, userID).Scan(&userLat, &userLng)
	if err != nil {
		log.Printf("User %s location not found: %v", userID, err)
		http.Error(w, "User location not found", http.StatusNotFound)
		return
	}
	log.Printf("User %s is at location: lat=%f, lng=%f", userID, userLat, userLng)

	// Step 2: Get campaigns with vendor address + segmentation + runtime + geofence logic
	campaignQuery := `
		SELECT 
			c.campaign_id, 
			c.vendor_id, 
			c.title, 
			c.code,
			c.description, 
			c.geofence_radius_km,
			v.address,           
			v.vendor_type,      
			v.lat as vendor_lat, 
			v.long as vendor_lng
		FROM campaigns c
		JOIN vendors v ON c.vendor_id = v.vendor_id
		JOIN segments s ON c.segment_id = s.segment_id
		JOIN users u ON u.user_id = $3
		WHERE c.enabled = true
			AND c.start_date <= CURRENT_DATE
			AND c.end_date >= CURRENT_DATE
			AND (
				CURRENT_DATE > c.start_date OR
				(CURRENT_DATE = c.start_date AND CURRENT_TIME >= c.run_time::time)
			)
			AND ST_DWithin(
				ST_Transform(ST_SetSRID(ST_MakePoint(v.long, v.lat), 4326), 3857),
				ST_Transform(ST_SetSRID(ST_MakePoint($1, $2), 4326), 3857),
				c.geofence_radius_km * 1000
			)
			AND (
				s.segment_name = CONCAT('loyalty_tier_', u.loyalty_tier)
				OR s.segment_name = CONCAT('most_frequent_vendor_type_', u.most_frequent_vendor_type)
				OR s.segment_name = CONCAT('most_frequent_vendor_', u.most_frequent_vendor)
			)`

	// Execute with user's real location + user ID for segmentation
	rows, err := config.DB.Query(campaignQuery, userLng, userLat, userID)
	if err != nil {
		log.Printf("Error executing campaign query for user %s: %v", userID, err)
		http.Error(w, "Campaign query failed", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Custom struct for response with vendor information
	type CampaignWithVendor struct {
		CampaignID       string  `json:"campaign_id"`
		VendorID         string  `json:"vendor_id"`
		Title            string  `json:"title"`
		Code             string  `json:"code"`
		Description      string  `json:"description"`
		GeofenceRadiusKm float64 `json:"geofence_radius_km"`
		VendorAddress    string  `json:"vendor_address"`    // Real address from database
		VendorType       string  `json:"vendor_type"`       // Vendor category
		VendorLat        float64 `json:"vendor_lat"`        // For map markers
		VendorLng        float64 `json:"vendor_lng"`        // For map markers
	}

	// Collect matching campaigns with vendor info
	var campaigns []CampaignWithVendor
	for rows.Next() {
		var c CampaignWithVendor
		err := rows.Scan(
			&c.CampaignID, 
			&c.VendorID, 
			&c.Title,
			&c.Code, 
			&c.Description, 
			&c.GeofenceRadiusKm,
			&c.VendorAddress,    // Real vendor address
			&c.VendorType,       // Real vendor type
			&c.VendorLat,        // Real vendor coordinates
			&c.VendorLng,
		)
		if err != nil {
			log.Printf("Error scanning campaign: %v", err)
			continue
		}
		log.Printf("✅ User %s matches campaign: %s at %s", userID, c.CampaignID, c.VendorAddress)
		campaigns = append(campaigns, c)
	}

	log.Printf("Found %d matching campaigns for user %s", len(campaigns), userID)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(campaigns)
}



// recordEngagementHandler handles user engagement with campaigns
func recordEngagementHandler(w http.ResponseWriter, r *http.Request) {
	// PART 1: Extract URL parameters
	vars := mux.Vars(r)
	userID := vars["user_id"]
	campaignID := vars["campaign_id"]
	
	log.Printf("🎯 Recording engagement: user=%s, campaign=%s", userID, campaignID)
	
	// PART 2: Parse request body (keeping struct for clarity)
	type EngagementRequest struct {
		Action string `json:"action"` // "clicked" or "used"
	}
	
	var req EngagementRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		log.Printf("❌ Error parsing request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	
	// PART 3: Validate action
	if req.Action != "clicked" && req.Action != "used" {
		log.Printf("❌ Invalid action: %s", req.Action)
		http.Error(w, "Action must be 'clicked' or 'used'", http.StatusBadRequest)
		return
	}
	
	// PART 4: Get user's real location from database
	var userLat, userLng float64
	locationQuery := `
		SELECT lat, long FROM user_location_events
		WHERE user_id = $1
		ORDER BY event_time DESC
		LIMIT 1`
	
	err = config.DB.QueryRow(locationQuery, userID).Scan(&userLat, &userLng)
	if err != nil {
		log.Printf("❌ User %s location not found: %v", userID, err)
		http.Error(w, "User location not found", http.StatusNotFound)
		return
	}
	
	log.Printf("📍 User %s location: lat=%f, lng=%f", userID, userLat, userLng)
	
	// PART 5: Check for duplicate engagement (updated for new schema)
var duplicateCheck int
var checkQuery string
var timeWindow string

if req.Action == "clicked" {
    // Check for clicks in last 5 minutes
    timeWindow = "5 minutes"
    checkQuery = `
        SELECT COUNT(*) FROM campaign_user_engagements 
        WHERE user_id = $1 AND campaign_id = $2 
        AND engagement_type = 'clicked'
        AND engagement_time > NOW() - INTERVAL '5 minutes'`
} else {
    // Check for usage today
    timeWindow = "today"
    checkQuery = `
        SELECT COUNT(*) FROM campaign_user_engagements 
        WHERE user_id = $1 AND campaign_id = $2 
        AND engagement_type = 'used'
        AND DATE(engagement_time) = CURRENT_DATE`
}

err = config.DB.QueryRow(checkQuery, userID, campaignID).Scan(&duplicateCheck)
if err != nil {
    log.Printf("❌ Error checking duplicates: %v", err)
    http.Error(w, "Database error", http.StatusInternalServerError)
    return
}

if duplicateCheck > 0 {
    log.Printf("⏭️ Duplicate %s engagement ignored (already %s %s)", 
        req.Action, req.Action, timeWindow)
    
    response := map[string]interface{}{
        "success": true,
        "message": fmt.Sprintf("Engagement already recorded %s", timeWindow),
        "duplicate": true,
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
    return
}

// PART 6: Insert new engagement record (SIMPLIFIED QUERY)
insertQuery := `
    INSERT INTO campaign_user_engagements 
    (user_id, campaign_id, engagement_type, used_loc_lat, used_loc_long, engagement_time)
    VALUES ($1, $2, $3, $4, $5, NOW())`

_, err = config.DB.Exec(insertQuery, userID, campaignID, req.Action, userLat, userLng)
if err != nil {
    log.Printf("❌ Error inserting engagement: %v", err)
    http.Error(w, "Failed to record engagement", http.StatusInternalServerError)
    return
}

log.Printf("✅ Inserted new %s engagement: user=%s, campaign=%s", 
    req.Action, userID, campaignID)
	
	// PART 7: Update user preferences based on engagement frequency (OPTIONAL)
	/*
	ANALYTICS FEATURE: Update user's most_frequent_vendor and most_frequent_vendor_type
	based on their engagement patterns
	*/
	if req.Action == "used" {
		// Only update preferences on actual usage, not just clicks
		go updateUserPreferences(userID) // Run in background to avoid slowing response
	}
	
	// PART 8: Return success response
	response := map[string]interface{}{
		"success": true,
		"message": fmt.Sprintf("New %s engagement recorded", req.Action),
		"engagement": map[string]interface{}{
			"user_id":       userID,
			"campaign_id":   campaignID,
			"action":        req.Action,
			"location": map[string]float64{
				"latitude":  userLat,
				"longitude": userLng,
			},
			"timestamp": "NOW()", // Will be set by database
		},
		"duplicate": false,
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// PART 9: Background function to update user preferences
/*
ANALYTICS LOGIC: Update user's most frequent vendor/type based on usage patterns
This runs asynchronously so it doesn't slow down the engagement recording
*/
func updateUserPreferences(userID string) {
	log.Printf("🔄 Updating preferences for user %s", userID)
	
	// Find most frequently used vendor (FIXED: use engagement_type instead of used column)
	var mostFrequentVendor string
	vendorQuery := `
		SELECT v.vendor_id 
		FROM campaign_user_engagements cue
		JOIN campaigns c ON cue.campaign_id = c.campaign_id
		JOIN vendors v ON c.vendor_id = v.vendor_id
		WHERE cue.user_id = $1 AND cue.engagement_type = 'used'
		GROUP BY v.vendor_id
		ORDER BY COUNT(*) DESC
		LIMIT 1`
	
	err := config.DB.QueryRow(vendorQuery, userID).Scan(&mostFrequentVendor)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("❌ Error finding most frequent vendor: %v", err)
		return
	}
	
	// Find most frequently used vendor type (FIXED: use engagement_type instead of used column)
	var mostFrequentVendorType string
	typeQuery := `
		SELECT v.vendor_type
		FROM campaign_user_engagements cue
		JOIN campaigns c ON cue.campaign_id = c.campaign_id
		JOIN vendors v ON c.vendor_id = v.vendor_id
		WHERE cue.user_id = $1 AND cue.engagement_type = 'used'
		GROUP BY v.vendor_type
		ORDER BY COUNT(*) DESC
		LIMIT 1`
	
	err = config.DB.QueryRow(typeQuery, userID).Scan(&mostFrequentVendorType)
	if err != nil && err != sql.ErrNoRows {
		log.Printf("❌ Error finding most frequent vendor type: %v", err)
		return
	}
	
	// Update user preferences if we found data
	if mostFrequentVendor != "" || mostFrequentVendorType != "" {
		updateQuery := `
			UPDATE users 
			SET most_frequent_vendor = COALESCE($2, most_frequent_vendor),
				most_frequent_vendor_type = COALESCE($3, most_frequent_vendor_type)
			WHERE user_id = $1`
		
		// Handle NULL values properly
		var vendorParam, typeParam interface{}
		if mostFrequentVendor != "" {
			vendorParam = mostFrequentVendor
		} else {
			vendorParam = nil
		}
		if mostFrequentVendorType != "" {
			typeParam = mostFrequentVendorType
		} else {
			typeParam = nil
		}
		
		_, err = config.DB.Exec(updateQuery, userID, vendorParam, typeParam)
		
		if err != nil {
			log.Printf("❌ Error updating user preferences: %v", err)
		} else {
			log.Printf("✅ Updated preferences for %s: vendor=%s, type=%s", 
				userID, mostFrequentVendor, mostFrequentVendorType)
		}
	} else {
		log.Printf("📊 No usage data yet for user %s - preferences unchanged", userID)
	}
}