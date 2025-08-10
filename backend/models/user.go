package models
import "time"

type User struct {
    UserID                 string `json:"user_id" db:"user_id"`
    MSISDN                string `json:"msisdn" db:"msisdn"`
    IMEI                  string `json:"imei" db:"imei"`
    CreatedAt             time.Time `json:"created_at" db:"created_at"`
    UpdatedAt             *time.Time `json:"updated_at" db:"updated_at"`
    LoyaltyTier           string `json:"loyalty_tier" db:"loyalty_tier"`
    MostFrequentVendor    string `json:"most_frequent_vendor" db:"most_frequent_vendor"`
    MostFrequentVendorType string `json:"most_frequent_vendor_type" db:"most_frequent_vendor_type"`
    NotifSMS              bool `json:"notif_sms" db:"notif_sms"`
    NotifWhatsapp         bool `json:"notif_whatsapp" db:"notif_whatsapp"`
    NotifInapp            bool `json:"notif_inapp" db:"notif_inapp"`
    Privacy               bool `json:"privacy" db:"privacy"`
}
