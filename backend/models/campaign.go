package models

type Campaign struct {
    CampaignID       string  `json:"campaign_id" db:"campaign_id"`
    VendorID         string  `json:"vendor_id" db:"vendor_id"`
    Title            string  `json:"title" db:"title"`
    Code             string  `json:"code" db:"code"`
    Description      string  `json:"description" db:"description"`
    GeofenceRadiusKm float64 `json:"geofence_radius_km" db:"geofence_radius_km"`
    Enabled          bool    `json:"enabled" db:"enabled"`
}