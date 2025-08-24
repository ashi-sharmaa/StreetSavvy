# StreetSavvy

A geospatial vendor-to-consumer promotional platform that enables businesses to reach nearby users with personalized campaigns in real-time.

## Project Overview

StreetSavvy is a location-based marketing platform consisting of two mobile applications (user and vendor) backed by a real-time Go API server with PostgreSQL/PostGIS database. The platform enables:

- **Vendors**: Create geofenced promotional campaigns, view real-time analytics, and track user engagement
- **Users**: Discover personalized deals nearby based on location and customer segments
- **Real-time Updates**: WebSocket-powered live notifications and analytics

## Architecture & Tech Stack

### Backend
- **Language**: Go 1.21+
- **Framework**: Gorilla Mux (HTTP routing)
- **Database**: PostgreSQL with PostGIS (spatial queries)
- **Real-time**: WebSocket connections using gorilla/websocket
- **Dependencies**: 
  - `github.com/gorilla/mux` - HTTP routing
  - `github.com/lib/pq` - PostgreSQL driver
  - `github.com/joho/godotenv` - Environment variables
  - `github.com/gorilla/websocket` - WebSocket support

### Frontend
- **Framework**: Flutter/Dart
- **Maps**: Google Maps Flutter plugin
- **Real-time**: WebSocket client using web_socket_channel
- **HTTP**: Built-in Dart HTTP client

### Database
- **Core**: PostgreSQL 13+
- **Extensions**: PostGIS for spatial operations
- **Features**: Geospatial indexing, real-time triggers

## Project Structure

```
streetsavvy/
├── README.md
├── .gitignore
├── backend/                    # Go API Server
│   ├── main.go                # Application entry point
│   ├── go.mod                 # Go dependencies
│   ├── go.sum                 # Dependency checksums
│   ├── .env                   # Environment configuration
│   ├── config/
│   │   └── database.go        # Database connection & config
│   ├── models/
│   │   ├── user.go           # User data models
│   │   ├── vendor.go         # Vendor data models
│   │   ├── campaign.go       # Campaign data models
│   │   └── location.go       # Location event models
│   └── handlers/
│       ├── users.go          # User API endpoints
│       ├── campaigns.go      # Campaign API endpoints
│       ├── vendors.go        # Vendor API endpoints
│       └── websocket.go      # WebSocket handlers
├── user_app/                  # Flutter User Application
│   ├── pubspec.yaml          # Flutter dependencies
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── models/
│   │   │   ├── user.dart     # User data models
│   │   │   └── campaign.dart # Campaign data models
│   │   ├── services/
│   │   │   ├── api_service.dart      # HTTP API client
│   │   │   └── websocket_service.dart # WebSocket client
│   │   ├── screens/
│   │   │   ├── user_selector.dart    # User selection screen
│   │   │   ├── user_home_screen.dart # Main user interface
│   │   │   └── campaign_detail.dart  # Campaign details
│   │   └── widgets/
│   │       └── campaign_card.dart    # Campaign UI components
├── vendor_app/               # Flutter Vendor Application
│   ├── pubspec.yaml         # Flutter dependencies  
│   ├── lib/
│   │   ├── main.dart        # App entry point
│   │   ├── models/
│   │   │   ├── vendor.dart  # Vendor data models
│   │   │   └── analytics.dart # Analytics data models
│   │   ├── services/
│   │   │   ├── api_service.dart      # HTTP API client
│   │   │   └── websocket_service.dart # WebSocket client
│   │   ├── screens/
│   │   │   ├── vendor_selector.dart   # Vendor selection
│   │   │   ├── vendor_dashboard.dart  # Analytics dashboard
│   │   │   └── campaign_management.dart # Campaign CRUD
│   │   └── widgets/
│   │       ├── analytics_card.dart   # Analytics components
│   │       ├── campaign_card.dart    # Campaign management UI
│   │       └── heatmap_overlay.dart  # Google Maps heatmap
└── database/
    ├── schema.sql           # Complete database schema
    └── test_data.sql        # Sample data for testing
```

## Features Implemented

### Core Features
- **Geospatial Campaigns**: Vendors create campaigns with configurable geofence radius
- **User Segmentation**: Target specific customer segments (loyalty tiers, vendor types)
- **Location Tracking**: Real-time user location updates via PostGIS spatial queries
- **Campaign Filtering**: Users see personalized campaigns based on location + segments

### Enhanced Features
- **Engagement Tracking**: Track campaign clicks and usage with analytics
- **Vendor Dashboard**: Real-time analytics showing campaign performance
- **Google Maps Integration**: Interactive maps with campaign markers
- **User Preferences**: Dynamic preference updates based on engagement patterns

### Real-time Features
- **WebSocket Communication**: Bidirectional real-time messaging
- **Live Analytics**: Vendor dashboards update instantly when users engage
- **Campaign Notifications**: Users receive instant notifications for new nearby campaigns
- **Location Streaming**: Continuous location updates every 2-5 minutes
- **Connection Management**: Automatic reconnection and connection status indicators

## Database Schema

The complete database setup script includes all tables, indexes, and test data:

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create sequences for auto-generated IDs
CREATE SEQUENCE segment_id_seq START 1;
CREATE SEQUENCE user_id_seq START 1;
CREATE SEQUENCE vendor_id_seq START 1;
CREATE SEQUENCE loc_id_seq START 1;
CREATE SEQUENCE campaign_id_seq START 1;

-- Segments table for customer targeting
CREATE TABLE segments (
    segment_id TEXT PRIMARY KEY DEFAULT ('S' || LPAD(nextval('segment_id_seq')::text, 4, '0')),
    segment_name TEXT
);

-- Vendors table with spatial data
CREATE TABLE vendors (
    vendor_id TEXT PRIMARY KEY DEFAULT ('V' || LPAD(nextval('vendor_id_seq')::text, 4, '0')),
    vendor_type TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    long DOUBLE PRECISION NOT NULL,
    address TEXT,
    heatmap_colors TEXT[3],
    heatmap_densities INTEGER[2],
    geom GEOMETRY(Point, 4326)
);

-- Campaigns table with geofencing
CREATE TABLE campaigns (
    campaign_id TEXT PRIMARY KEY DEFAULT ('C' || LPAD(nextval('campaign_id_seq')::text, 4, '0')),
    vendor_id TEXT REFERENCES vendors(vendor_id),
    geofence_radius_km DOUBLE PRECISION,
    title TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    run_time TIMESTAMP NOT NULL,
    segment_id TEXT REFERENCES segments(segment_id),
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    enabled BOOLEAN DEFAULT TRUE,
    code TEXT,
    description TEXT
);

-- Users table with preferences
CREATE TABLE users (
    user_id TEXT PRIMARY KEY DEFAULT ('U' || LPAD(nextval('user_id_seq')::text, 4, '0')),
    msisdn TEXT,
    imei TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NULL,
    loyalty_tier TEXT,
    most_frequent_vendor TEXT,
    most_frequent_vendor_type TEXT,
    notif_sms BOOLEAN,
    notif_whatsapp BOOLEAN,
    notif_inapp BOOLEAN,
    privacy BOOLEAN DEFAULT TRUE
);

-- User location tracking with spatial data
CREATE TABLE user_location_events (
    user_id TEXT REFERENCES users(user_id),
    location_id TEXT PRIMARY KEY DEFAULT ('L' || LPAD(nextval('loc_id_seq')::text, 4, '0')),
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lat DOUBLE PRECISION NOT NULL,
    long DOUBLE PRECISION NOT NULL,
    idle_time INT,
    geom GEOMETRY(Point, 4326)
);

-- Engagement tracking for analytics
CREATE TABLE campaign_user_engagements (
    user_id TEXT REFERENCES users(user_id),
    campaign_id TEXT REFERENCES campaigns(campaign_id),
    engagement_type TEXT CHECK (engagement_type IN ('clicked', 'used')),
    engagement_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used_loc_lat DOUBLE PRECISION NOT NULL,
    used_loc_long DOUBLE PRECISION NOT NULL
);

-- Create spatial indexes for performance
CREATE INDEX idx_vendors_geom ON vendors USING GIST (geom);
CREATE INDEX idx_user_location_events_geom ON user_location_events USING GIST (geom);

-- Sample test data
INSERT INTO segments (segment_id, segment_name) VALUES
('S0001', 'loyalty_tier_bronze'),
('S0002', 'loyalty_tier_silver'),
('S0003', 'loyalty_tier_gold'),
('S0004', 'most_frequent_vendor_type_restaurant'),
('S0005', 'most_frequent_vendor_type_gas'),
('S0006', 'most_frequent_vendor_type_coffee');

-- Test vendors with real Dallas coordinates
INSERT INTO vendors (vendor_id, vendor_type, lat, long, address, heatmap_colors, heatmap_densities) VALUES
('V0001', 'restaurant', 33.1709356, -96.6422084, '123 Main St, Dallas, TX, 75001', 
 ARRAY['#4CAF50', '#FF9800', '#F44336'], ARRAY[5, 15]),
('V0002', 'gas', 33.1979930, -96.6381283, '456 Commerce Rd, Dallas, TX, 75002', 
 ARRAY['#2196F3', '#FF9800', '#F44336'], ARRAY[3, 10]),
('V0003', 'coffee', 33.1985642, -96.6156789, '789 Coffee Ave, Dallas, TX, 75003', 
 ARRAY['#8BC34A', '#FFC107', '#FF5722'], ARRAY[4, 12]);

-- Update geometry columns
UPDATE vendors SET geom = ST_SetSRID(ST_MakePoint(long, lat), 4326);

-- Test users with preferences
INSERT INTO users (user_id, loyalty_tier, most_frequent_vendor_type, notif_inapp) VALUES
('U0001', 'bronze', 'restaurant', TRUE),
('U0002', 'silver', 'gas', TRUE),
('U0003', 'gold', 'coffee', TRUE),
('U0004', 'bronze', 'coffee', TRUE),
('U0005', 'silver', 'restaurant', TRUE);

-- Test campaigns
INSERT INTO campaigns (campaign_id, vendor_id, geofence_radius_km, title, start_date, 
                      end_date, run_time, segment_id, enabled, code, description) VALUES
('C0001', 'V0001', 0.2, 'Bronze Restaurant Deal', '2025-08-11', '2025-08-20', 
 '2025-08-11 07:00:00', 'S0001', TRUE, 'BRONZREST', 'Special deal for bronze members'),
('C0002', 'V0002', 0.15, 'Gas Station Promo', '2025-08-11', '2025-08-20', 
 '2025-08-11 07:30:00', 'S0005', TRUE, 'GASPROMO', 'Gas station promotion'),
('C0003', 'V0003', 0.1, 'Gold Coffee Special', '2025-08-11', '2025-08-20', 
 '2025-08-11 06:00:00', 'S0003', TRUE, 'GOLDCOFF', 'Premium coffee for gold members');

-- Test location events (current timestamps)
INSERT INTO user_location_events (user_id, event_time, lat, long, idle_time) VALUES
('U0001', NOW() - INTERVAL '5 minutes', 33.1709356, -96.6422084, 1),
('U0002', NOW() - INTERVAL '3 minutes', 33.1979930, -96.6381283, 2),
('U0003', NOW() - INTERVAL '1 minute', 33.1985642, -96.6156789, 0),
('U0004', NOW() - INTERVAL '2 minutes', 33.1985642, -96.6156789, 1),
('U0005', NOW() - INTERVAL '4 minutes', 33.1709356, -96.6422084, 3);

-- Update geometry columns for location events
UPDATE user_location_events SET geom = ST_SetSRID(ST_MakePoint(long, lat), 4326);
```

## Setup Instructions

### Prerequisites
- **Go**: Version 1.21 or higher
- **Flutter**: Version 3.0+ with Dart SDK
- **PostgreSQL**: Version 13+ with PostGIS extension
- **Development Tools**: pgAdmin (recommended for database management)

### 1. Database Setup

1. **Create Database**:
   ```sql
   CREATE DATABASE streetsavvy;
   ```

2. **Run Schema Script**:
   - Connect to `streetsavvy` database in pgAdmin
   - Execute the complete schema script above (including test data)

3. **Verify Setup**:
   ```sql
   -- Check if PostGIS is working
   SELECT ST_Distance(ST_MakePoint(-96.6422084, 33.1709356), ST_MakePoint(-96.6381283, 33.1979930));
   
   -- Verify test data
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM vendors;
   SELECT COUNT(*) FROM campaigns;
   ```

### 2. Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   go mod tidy
   ```

3. **Configure environment** (create `.env` file):
   ```env
   # Database Configuration
   DB_HOST=127.0.0.1
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=your_password
   DB_NAME=streetsavvy
   DB_SSLMODE=disable
   
   # Server Configuration
   PORT=8080
   
   # Development Settings
   ENV=development
   ```

4. **Start the server**:
   ```bash
   go run main.go
   ```

   Expected output:
   ```
   Database connection successful!
   StreetSavvy Backend starting on port 8080
   ```

### 3. User App Setup

1. **Navigate to user app**:
   ```bash
   cd user_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### 4. Vendor App Setup

1. **Navigate to vendor app**:
   ```bash
   cd vendor_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## Features Implemented

### Core Features
- **Geospatial Campaigns**: Vendors create campaigns with configurable geofence radius
- **User Segmentation**: Target specific customer segments (loyalty tiers, vendor types)
- **Location Tracking**: Real-time user location updates via PostGIS spatial queries
- **Campaign Filtering**: Users see personalized campaigns based on location + segments

### Enhanced Features
- **Engagement Tracking**: Track campaign clicks and usage with analytics
- **Vendor Dashboard**: Real-time analytics showing campaign performance
- **Google Maps Integration**: Interactive maps with campaign markers
- **User Preferences**: Dynamic preference updates based on engagement patterns

### Real-time Features
- **WebSocket Communication**: Bidirectional real-time messaging
- **Live Analytics**: Vendor dashboards update instantly when users engage
- **Campaign Notifications**: Users receive instant notifications for new nearby campaigns
- **Location Streaming**: Continuous location updates every 2-5 minutes
- **Connection Management**: Automatic reconnection and connection status indicators

## API Endpoints

### User Endpoints
- `GET /api/users/{id}` - Get user profile
- `GET /api/users/{id}/nearby-campaigns` - Get campaigns near user
- `POST /api/users/{id}/engagements/{campaign_id}/{action}` - Record engagement

### Campaign Endpoints
- `GET /api/campaigns/active` - Get all active campaigns
- `GET /api/campaigns/nearby` - Get campaigns by location

### Vendor Endpoints
- `GET /api/vendors/{id}/analytics` - Get vendor analytics
- `GET /api/vendors/{id}/campaigns` - Get vendor campaigns

### WebSocket Endpoints
- `WS /api/users/{id}/ws` - User WebSocket connection
- `WS /api/vendors/{id}/ws` - Vendor WebSocket connection

### Health Check
- `GET /api/health` - Server health status

## Testing

### API Testing with curl

1. **Test health endpoint**:
   ```bash
   curl http://localhost:8080/api/health
   ```

2. **Get user's nearby campaigns**:
   ```bash
   curl http://localhost:8080/api/users/U0001/nearby-campaigns
   ```

3. **Record engagement**:
   ```bash
   curl -X POST http://localhost:8080/api/users/U0001/engagements/C0001/clicked
   ```

### Frontend Testing

1. **User App**: 
   - Select test user (U0001-U0005)
   - View nearby campaigns based on location/segments
   - Test engagement tracking (click/usage)
   - Verify real-time notifications

2. **Vendor App**:
   - Select test vendor (V0001-V0003) 
   - View analytics dashboard
   - Monitor real-time engagement updates
   - Test campaign management

### WebSocket Testing

Test WebSocket connections using browser developer tools or WebSocket client:
- Connect to `ws://localhost:8080/api/users/U0001/ws`
- Send test messages and verify real-time updates

## Key Features Explained

### Geofencing Logic
- Uses PostGIS `ST_DWithin` for efficient spatial queries
- Campaigns have configurable radius (e.g., 0.2km = 200 meters)
- Real-time location updates trigger geofence checks

### Customer Segmentation
- **Loyalty Tiers**: Bronze, Silver, Gold
- **Vendor Types**: Restaurant, Gas, Coffee
- **Preference Learning**: System updates user preferences based on engagement

### Real-time Analytics
- **Engagement Tracking**: Separate records for clicks vs usage
- **Live Updates**: WebSocket broadcasts engagement to vendors instantly
- **Performance Metrics**: Conversion rates, engagement counts

### Scalability Features
- **Connection Pooling**: Database connections managed efficiently
- **Spatial Indexing**: PostGIS GIST indexes for fast geospatial queries
- **WebSocket Management**: Automatic connection cleanup and reconnection

## Development Notes

### Design Patterns Used
- **Repository Pattern**: Clean data access layer
- **Service Layer**: Business logic separation  
- **Observer Pattern**: WebSocket event broadcasting
- **MVC Architecture**: Clear separation of concerns

### Performance Optimizations
- **Spatial Indexes**: GIST indexes on geometry columns
- **Connection Pooling**: Configured database connection limits
- **Query Optimization**: Efficient PostGIS spatial queries
- **Real-time Updates**: WebSocket reduces API polling

### Security Considerations
- **SQL Injection Protection**: Parameterized queries
- **CORS Configuration**: Proper cross-origin settings
- **Input Validation**: Data validation at API layer
- **Connection Management**: Secure WebSocket handling

## Future Enhancements

### Planned Features
- **Push Notifications**: Mobile push for campaign alerts
- **Advanced Analytics**: Detailed user behavior tracking
- **Campaign Scheduling**: Automated campaign activation
- **Heatmap Visualization**: Enhanced density mapping
- **Multi-tenant Support**: Enterprise vendor management

### Technical Improvements
- **Caching Layer**: Redis for frequently accessed data
- **Load Balancing**: Horizontal scaling support
- **Monitoring**: Comprehensive logging and metrics
- **Testing Suite**: Automated testing framework
- **CI/CD Pipeline**: Deployment automation

## License

This project is developed for educational purposes as part of a Computer Science curriculum.

---

**StreetSavvy** - Connecting businesses with nearby customers through intelligent, real-time geospatial marketing.
