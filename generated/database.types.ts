export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type CostType = 'per_night' | 'entry_fee' | 'none'

export type EnrichmentJobTypeEnum = 'enrich_llm' | 'refresh_osm' | 'google_places'

export type EnrichmentStatusEnum = 'pending' | 'processing' | 'done' | 'failed' | 'needs_review'

export type JobStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'skipped'

export type JobStatusEnum = 'queued' | 'running' | 'done' | 'failed' | 'dead'

export type PlaceTypeEnum = 'camp_site' | 'camper_stop' | 'overnight_parking' | 'parking' | 'attraction'

export type AalLevel = 'aal1' | 'aal2' | 'aal3'

export type StopType = 'camping' | 'stellplatz' | 'poi' | 'city' | 'address'

export type UserRole = 'user' | 'admin'

export type CodeChallengeMethod = 's256' | 'plain'

export type FactorStatus = 'unverified' | 'verified'

export type FactorType = 'totp' | 'webauthn' | 'phone'

export type OauthAuthorizationStatus = 'pending' | 'approved' | 'denied' | 'expired'

export type OauthClientType = 'public' | 'confidential'

export type OauthRegistrationType = 'dynamic' | 'manual'

export type OauthResponseType = 'code'

export type OneTimeTokenType = 'confirmation_token' | 'reauthentication_token' | 'recovery_token' | 'email_change_token_new' | 'email_change_token_current' | 'phone_change_token'

export type Buckettype = 'STANDARD' | 'ANALYTICS' | 'VECTOR'

export interface Database {
  public: {
    Tables: {
      spatial_ref_sys: {
        Row: {
          srid: number
          auth_name: string | null
          auth_srid: number | null
          srtext: string | null
          proj4text: string | null
        }
        Insert: {
          srid: number
          auth_name?: string | null
          auth_srid?: number | null
          srtext?: string | null
          proj4text?: string | null
        }
        Update: {
          srid?: number
          auth_name?: string | null
          auth_srid?: number | null
          srtext?: string | null
          proj4text?: string | null
        }
      }
      enrichment_jobs: {
        Row: {
          id: number
          place_id: number
          job_type: string
          priority: number
          status: string
          attempts: number
          max_attempts: number
          run_after: string
          locked_by: string | null
          locked_at: string | null
          error_message: string | null
          created_at: string
          updated_at: string
          freshness_bucket: string
          lease_expires_at: string | null
          heartbeat_at: string | null
          payload: Json
          context: Json
          last_error_at: string | null
          dead_lettered_at: string | null
          classification: string | null
          source_state: string | null
          worker_id: string | null
          attempt_number: number | null
          last_error_code: string | null
          last_error_message: string | null
          canonical_place_id: string | null
          metadata: Json | null
        }
        Insert: {
          id: number
          place_id: number
          job_type: string
          priority: number
          status: string
          attempts: number
          max_attempts: number
          run_after: string
          locked_by?: string | null
          locked_at?: string | null
          error_message?: string | null
          created_at: string
          updated_at: string
          freshness_bucket: string
          lease_expires_at?: string | null
          heartbeat_at?: string | null
          payload: Json
          context: Json
          last_error_at?: string | null
          dead_lettered_at?: string | null
          classification?: string | null
          source_state?: string | null
          worker_id?: string | null
          attempt_number?: number | null
          last_error_code?: string | null
          last_error_message?: string | null
          canonical_place_id?: string | null
          metadata?: Json | null
        }
        Update: {
          id?: number
          place_id?: number
          job_type?: string
          priority?: number
          status?: string
          attempts?: number
          max_attempts?: number
          run_after?: string
          locked_by?: string | null
          locked_at?: string | null
          error_message?: string | null
          created_at?: string
          updated_at?: string
          freshness_bucket?: string
          lease_expires_at?: string | null
          heartbeat_at?: string | null
          payload?: Json
          context?: Json
          last_error_at?: string | null
          dead_lettered_at?: string | null
          classification?: string | null
          source_state?: string | null
          worker_id?: string | null
          attempt_number?: number | null
          last_error_code?: string | null
          last_error_message?: string | null
          canonical_place_id?: string | null
          metadata?: Json | null
        }
      }
      google_refresh_claims: {
        Row: {
          place_id: string
          claimed_at: string
          expires_at: string
          worker_id: string
          status: string
          attempt_count: number
          last_attempt_at: string
          last_error: string | null
          result_type: string | null
          result_at: string | null
          metadata: Json
        }
        Insert: {
          place_id: string
          claimed_at: string
          expires_at: string
          worker_id: string
          status: string
          attempt_count: number
          last_attempt_at: string
          last_error?: string | null
          result_type?: string | null
          result_at?: string | null
          metadata: Json
        }
        Update: {
          place_id?: string
          claimed_at?: string
          expires_at?: string
          worker_id?: string
          status?: string
          attempt_count?: number
          last_attempt_at?: string
          last_error?: string | null
          result_type?: string | null
          result_at?: string | null
          metadata?: Json
        }
      }
      app_errors: {
        Row: {
          id: string
          error_type: string
          message: string
          stack_trace: string | null
          location: string | null
          user_id: string | null
          user_agent: string | null
          metadata: Json | null
          status: string
          created_at: string | null
        }
        Insert: {
          id: string
          error_type: string
          message: string
          stack_trace?: string | null
          location?: string | null
          user_id?: string | null
          user_agent?: string | null
          metadata?: Json | null
          status: string
          created_at?: string | null
        }
        Update: {
          id?: string
          error_type?: string
          message?: string
          stack_trace?: string | null
          location?: string | null
          user_id?: string | null
          user_agent?: string | null
          metadata?: Json | null
          status?: string
          created_at?: string | null
        }
      }
      app_settings: {
        Row: {
          id: string
          key: string
          category: string
          type: string
          value: Json
          encrypted: boolean | null
          description: string | null
          validation_rules: Json | null
          is_archived: boolean | null
          created_by: string | null
          updated_by: string | null
          created_at: string | null
          updated_at: string | null
          version: number | null
        }
        Insert: {
          id: string
          key: string
          category: string
          type: string
          value: Json
          encrypted?: boolean | null
          description?: string | null
          validation_rules?: Json | null
          is_archived?: boolean | null
          created_by?: string | null
          updated_by?: string | null
          created_at?: string | null
          updated_at?: string | null
          version?: number | null
        }
        Update: {
          id?: string
          key?: string
          category?: string
          type?: string
          value?: Json
          encrypted?: boolean | null
          description?: string | null
          validation_rules?: Json | null
          is_archived?: boolean | null
          created_by?: string | null
          updated_by?: string | null
          created_at?: string | null
          updated_at?: string | null
          version?: number | null
        }
      }
      campsite_prices: {
        Row: {
          id: string
          place_id: string
          user_id: string | null
          price_per_night: number
          price_type: string | null
          currency: string | null
          rating: number | null
          review_text: string | null
          created_at: string | null
        }
        Insert: {
          id: string
          place_id: string
          user_id?: string | null
          price_per_night: number
          price_type?: string | null
          currency?: string | null
          rating?: number | null
          review_text?: string | null
          created_at?: string | null
        }
        Update: {
          id?: string
          place_id?: string
          user_id?: string | null
          price_per_night?: number
          price_type?: string | null
          currency?: string | null
          rating?: number | null
          review_text?: string | null
          created_at?: string | null
        }
      }
      campsite_reviews: {
        Row: {
          id: string
          user_id: string
          place_id: string
          place_name: string
          rating: number
          comment: string | null
          created_at: string | null
        }
        Insert: {
          id: string
          user_id: string
          place_id: string
          place_name: string
          rating: number
          comment?: string | null
          created_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          place_id?: string
          place_name?: string
          rating?: number
          comment?: string | null
          created_at?: string | null
        }
      }
      campsites_cache: {
        Row: {
          id: string
          place_id: string | null
          name: string
          lat: number
          lng: number
          rating: number | null
          photo_url: string | null
          estimated_price: number | null
          place_types: unknown[] | null
          last_updated: string | null
          created_at: string | null
          price_source: string | null
          user_price_count: number | null
          user_price_avg: number | null
          description: string | null
          description_source: string | null
          description_generated_at: string | null
          description_version: number | null
          opening_hours: string | null
          contact_phone: string | null
          contact_email: string | null
          scraped_website_url: string | null
          scraped_at: string | null
          scraped_price_info: Json | null
          scraped_data_source: string | null
          google_data_fetched_at: string | null
          google_data_expires_at: string | null
          google_photos: Json | null
          google_reviews: Json | null
        }
        Insert: {
          id: string
          place_id?: string | null
          name: string
          lat: number
          lng: number
          rating?: number | null
          photo_url?: string | null
          estimated_price?: number | null
          place_types?: unknown[] | null
          last_updated?: string | null
          created_at?: string | null
          price_source?: string | null
          user_price_count?: number | null
          user_price_avg?: number | null
          description?: string | null
          description_source?: string | null
          description_generated_at?: string | null
          description_version?: number | null
          opening_hours?: string | null
          contact_phone?: string | null
          contact_email?: string | null
          scraped_website_url?: string | null
          scraped_at?: string | null
          scraped_price_info?: Json | null
          scraped_data_source?: string | null
          google_data_fetched_at?: string | null
          google_data_expires_at?: string | null
          google_photos?: Json | null
          google_reviews?: Json | null
        }
        Update: {
          id?: string
          place_id?: string | null
          name?: string
          lat?: number
          lng?: number
          rating?: number | null
          photo_url?: string | null
          estimated_price?: number | null
          place_types?: unknown[] | null
          last_updated?: string | null
          created_at?: string | null
          price_source?: string | null
          user_price_count?: number | null
          user_price_avg?: number | null
          description?: string | null
          description_source?: string | null
          description_generated_at?: string | null
          description_version?: number | null
          opening_hours?: string | null
          contact_phone?: string | null
          contact_email?: string | null
          scraped_website_url?: string | null
          scraped_at?: string | null
          scraped_price_info?: Json | null
          scraped_data_source?: string | null
          google_data_fetched_at?: string | null
          google_data_expires_at?: string | null
          google_photos?: Json | null
          google_reviews?: Json | null
        }
      }
      favorites: {
        Row: {
          id: string
          user_id: string
          place_id: string
          name: string
          coordinates: Json
          type: string
          amenities: unknown[] | null
          rating: number | null
          created_at: string
          location_geo: string | null
        }
        Insert: {
          id: string
          user_id: string
          place_id: string
          name: string
          coordinates: Json
          type: string
          amenities?: unknown[] | null
          rating?: number | null
          created_at: string
          location_geo?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          place_id?: string
          name?: string
          coordinates?: Json
          type?: string
          amenities?: unknown[] | null
          rating?: number | null
          created_at?: string
          location_geo?: string | null
        }
      }
      place_google_properties: {
        Row: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          google_source_id: number | null
          google_place_id: string | null
          rating: number | null
          review_count: number | null
          business_status: string | null
          expires_at: string | null
        }
        Insert: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          google_source_id?: number | null
          google_place_id?: string | null
          rating?: number | null
          review_count?: number | null
          business_status?: string | null
          expires_at?: string | null
        }
        Update: {
          id?: number
          place_id?: number
          is_current?: boolean
          created_at?: string
          updated_at?: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          google_source_id?: number | null
          google_place_id?: string | null
          rating?: number | null
          review_count?: number | null
          business_status?: string | null
          expires_at?: string | null
        }
      }
      place_llm_properties: {
        Row: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          llm_enrichment_id: number | null
          provider: string | null
          model: string | null
          summary_de: string | null
          trust_score: number | null
          source_urls: Json | null
          last_enriched_at: string | null
          coverage_score: number | null
          last_worker_id: string | null
        }
        Insert: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          llm_enrichment_id?: number | null
          provider?: string | null
          model?: string | null
          summary_de?: string | null
          trust_score?: number | null
          source_urls?: Json | null
          last_enriched_at?: string | null
          coverage_score?: number | null
          last_worker_id?: string | null
        }
        Update: {
          id?: number
          place_id?: number
          is_current?: boolean
          created_at?: string
          updated_at?: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          llm_enrichment_id?: number | null
          provider?: string | null
          model?: string | null
          summary_de?: string | null
          trust_score?: number | null
          source_urls?: Json | null
          last_enriched_at?: string | null
          coverage_score?: number | null
          last_worker_id?: string | null
        }
      }
      place_osm_properties: {
        Row: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          osm_id: number | null
          osm_type: string | null
          osm_version: number | null
          osm_timestamp: string | null
          imported_at: string | null
          first_seen_at: string | null
          last_seen_at: string | null
          last_import_run_id: number | null
          source_metadata: Json | null
        }
        Insert: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          osm_id?: number | null
          osm_type?: string | null
          osm_version?: number | null
          osm_timestamp?: string | null
          imported_at?: string | null
          first_seen_at?: string | null
          last_seen_at?: string | null
          last_import_run_id?: number | null
          source_metadata?: Json | null
        }
        Update: {
          id?: number
          place_id?: number
          is_current?: boolean
          created_at?: string
          updated_at?: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          osm_id?: number | null
          osm_type?: string | null
          osm_version?: number | null
          osm_timestamp?: string | null
          imported_at?: string | null
          first_seen_at?: string | null
          last_seen_at?: string | null
          last_import_run_id?: number | null
          source_metadata?: Json | null
        }
      }
      places: {
        Row: {
          id: number
          geom: string
          lat: number | null
          lon: number | null
          is_active: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id: number
          geom: string
          lat?: number | null
          lon?: number | null
          is_active: boolean
          created_at: string
          updated_at: string
        }
        Update: {
          id?: number
          geom?: string
          lat?: number | null
          lon?: number | null
          is_active?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      countries: {
        Row: {
          iso_code: string
          name: string
          geofabrik_name: string
          geofabrik_url: string
          bounding_box: Json
          created_at: string | null
        }
        Insert: {
          iso_code: string
          name: string
          geofabrik_name: string
          geofabrik_url: string
          bounding_box: Json
          created_at?: string | null
        }
        Update: {
          iso_code?: string
          name?: string
          geofabrik_name?: string
          geofabrik_url?: string
          bounding_box?: Json
          created_at?: string | null
        }
      }
      country_import_status: {
        Row: {
          id: string
          country_code: string
          status: string
          source_type: string
          started_at: string | null
          completed_at: string | null
          poi_count: number | null
          error_message: string | null
          created_at: string | null
          updated_at: string | null
        }
        Insert: {
          id: string
          country_code: string
          status: string
          source_type: string
          started_at?: string | null
          completed_at?: string | null
          poi_count?: number | null
          error_message?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
        Update: {
          id?: string
          country_code?: string
          status?: string
          source_type?: string
          started_at?: string | null
          completed_at?: string | null
          poi_count?: number | null
          error_message?: string | null
          created_at?: string | null
          updated_at?: string | null
        }
      }
      cutover_audit_log: {
        Row: {
          id: number
          event_type: string
          level: string
          payload: Json
          created_at: string
        }
        Insert: {
          id: number
          event_type: string
          level: string
          payload: Json
          created_at: string
        }
        Update: {
          id?: number
          event_type?: string
          level?: string
          payload?: Json
          created_at?: string
        }
      }
      google_places_cache: {
        Row: {
          id: string
          place_id: string
          name: string | null
          data: Json | null
          fetched_at: string | null
          expires_at: string | null
        }
        Insert: {
          id: string
          place_id: string
          name?: string | null
          data?: Json | null
          fetched_at?: string | null
          expires_at?: string | null
        }
        Update: {
          id?: string
          place_id?: string
          name?: string | null
          data?: Json | null
          fetched_at?: string | null
          expires_at?: string | null
        }
      }
      osm_import_jobs: {
        Row: {
          id: string
          job_type: string
          status: string
          started_at: string | null
          completed_at: string | null
          result: Json | null
          error_message: string | null
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          job_type: string
          status: string
          started_at?: string | null
          completed_at?: string | null
          result?: Json | null
          error_message?: string | null
          created_by?: string | null
          created_at: string
          updated_at: string
        }
        Update: {
          id?: string
          job_type?: string
          status?: string
          started_at?: string | null
          completed_at?: string | null
          result?: Json | null
          error_message?: string | null
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      osm_import_queue: {
        Row: {
          id: number
          job_type: string
          status: string
          bbox: Json | null
          options: Json | null
          priority: number | null
          worker_id: string | null
          job_reference_id: string | null
          error_message: string | null
          created_at: string
          started_at: string | null
          completed_at: string | null
          updated_at: string
          country_code: string | null
          source_type: string | null
          retry_count: number
        }
        Insert: {
          id: number
          job_type: string
          status: string
          bbox?: Json | null
          options?: Json | null
          priority?: number | null
          worker_id?: string | null
          job_reference_id?: string | null
          error_message?: string | null
          created_at: string
          started_at?: string | null
          completed_at?: string | null
          updated_at: string
          country_code?: string | null
          source_type?: string | null
          retry_count: number
        }
        Update: {
          id?: number
          job_type?: string
          status?: string
          bbox?: Json | null
          options?: Json | null
          priority?: number | null
          worker_id?: string | null
          job_reference_id?: string | null
          error_message?: string | null
          created_at?: string
          started_at?: string | null
          completed_at?: string | null
          updated_at?: string
          country_code?: string | null
          source_type?: string | null
          retry_count?: number
        }
      }
      osm_import_runs: {
        Row: {
          id: number
          source: string
          status: string
          bbox: Json | null
          tile_count: number
          fetched_count: number
          normalized_count: number
          imported_count: number
          created_count: number
          updated_count: number
          noop_count: number
          failed_count: number
          stale_marked_inactive_count: number
          error_messages: Json
          started_at: string
          finished_at: string | null
          run_kind: string
          ingestion_provider: string
          tile_key: string | null
          parent_run_id: number | null
          queue_job_id: number | null
          current_tile: number | null
          total_tiles: number | null
        }
        Insert: {
          id: number
          source: string
          status: string
          bbox?: Json | null
          tile_count: number
          fetched_count: number
          normalized_count: number
          imported_count: number
          created_count: number
          updated_count: number
          noop_count: number
          failed_count: number
          stale_marked_inactive_count: number
          error_messages: Json
          started_at: string
          finished_at?: string | null
          run_kind: string
          ingestion_provider: string
          tile_key?: string | null
          parent_run_id?: number | null
          queue_job_id?: number | null
          current_tile?: number | null
          total_tiles?: number | null
        }
        Update: {
          id?: number
          source?: string
          status?: string
          bbox?: Json | null
          tile_count?: number
          fetched_count?: number
          normalized_count?: number
          imported_count?: number
          created_count?: number
          updated_count?: number
          noop_count?: number
          failed_count?: number
          stale_marked_inactive_count?: number
          error_messages?: Json
          started_at?: string
          finished_at?: string | null
          run_kind?: string
          ingestion_provider?: string
          tile_key?: string | null
          parent_run_id?: number | null
          queue_job_id?: number | null
          current_tile?: number | null
          total_tiles?: number | null
        }
      }
      osm_refresh_jobs: {
        Row: {
          id: number
          tile_key: string
          bbox: Json
          source_provider: string
          status: string
          attempts: number
          max_attempts: number
          priority: number
          run_after: string
          locked_by: string | null
          lease_expires_at: string | null
          last_run_id: number | null
          error_message: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: number
          tile_key: string
          bbox: Json
          source_provider: string
          status: string
          attempts: number
          max_attempts: number
          priority: number
          run_after: string
          locked_by?: string | null
          lease_expires_at?: string | null
          last_run_id?: number | null
          error_message?: string | null
          created_at: string
          updated_at: string
        }
        Update: {
          id?: number
          tile_key?: string
          bbox?: Json
          source_provider?: string
          status?: string
          attempts?: number
          max_attempts?: number
          priority?: number
          run_after?: string
          locked_by?: string | null
          lease_expires_at?: string | null
          last_run_id?: number | null
          error_message?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      place_duplicate_candidates: {
        Row: {
          id: number
          primary_place_id: number
          duplicate_place_id: number | null
          candidate_osm_type: string | null
          candidate_osm_id: number | null
          candidate_geometry_kind: string | null
          match_type: string
          match_score: number
          distance_meters: number | null
          name_similarity: number | null
          detected_at: string
          reviewed_at: string | null
          reviewed_by: string | null
          resolution: string | null
          resolution_notes: string | null
        }
        Insert: {
          id: number
          primary_place_id: number
          duplicate_place_id?: number | null
          candidate_osm_type?: string | null
          candidate_osm_id?: number | null
          candidate_geometry_kind?: string | null
          match_type: string
          match_score: number
          distance_meters?: number | null
          name_similarity?: number | null
          detected_at: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          resolution?: string | null
          resolution_notes?: string | null
        }
        Update: {
          id?: number
          primary_place_id?: number
          duplicate_place_id?: number | null
          candidate_osm_type?: string | null
          candidate_osm_id?: number | null
          candidate_geometry_kind?: string | null
          match_type?: string
          match_score?: number
          distance_meters?: number | null
          name_similarity?: number | null
          detected_at?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          resolution?: string | null
          resolution_notes?: string | null
        }
      }
      place_enrichment: {
        Row: {
          id: number
          place_id: number
          status: string
          provider: string | null
          model: string | null
          prompt_version: string | null
          source_urls: Json
          extracted: Json
          summary_de: string | null
          confidence: number | null
          hallucination_risk: number | null
          token_input: number | null
          token_output: number | null
          cost_usd: number | null
          validation_errors: Json
          created_at: string
          completed_at: string | null
          source_evidence: Json | null
          evidence_markers: Json | null
          collection_status: string | null
          failure_classification: string | null
          provider_attempts: Json | null
          job_cost_usd: number | null
          enrichment_schema_version: string | null
        }
        Insert: {
          id: number
          place_id: number
          status: string
          provider?: string | null
          model?: string | null
          prompt_version?: string | null
          source_urls: Json
          extracted: Json
          summary_de?: string | null
          confidence?: number | null
          hallucination_risk?: number | null
          token_input?: number | null
          token_output?: number | null
          cost_usd?: number | null
          validation_errors: Json
          created_at: string
          completed_at?: string | null
          source_evidence?: Json | null
          evidence_markers?: Json | null
          collection_status?: string | null
          failure_classification?: string | null
          provider_attempts?: Json | null
          job_cost_usd?: number | null
          enrichment_schema_version?: string | null
        }
        Update: {
          id?: number
          place_id?: number
          status?: string
          provider?: string | null
          model?: string | null
          prompt_version?: string | null
          source_urls?: Json
          extracted?: Json
          summary_de?: string | null
          confidence?: number | null
          hallucination_risk?: number | null
          token_input?: number | null
          token_output?: number | null
          cost_usd?: number | null
          validation_errors?: Json
          created_at?: string
          completed_at?: string | null
          source_evidence?: Json | null
          evidence_markers?: Json | null
          collection_status?: string | null
          failure_classification?: string | null
          provider_attempts?: Json | null
          job_cost_usd?: number | null
          enrichment_schema_version?: string | null
        }
      }
      place_google_photos: {
        Row: {
          id: number
          photo_reference: string
          width: number | null
          height: number | null
          attribution: string | null
          google_photo_id: string | null
          created_at: string
          google_property_id: number
        }
        Insert: {
          id: number
          photo_reference: string
          width?: number | null
          height?: number | null
          attribution?: string | null
          google_photo_id?: string | null
          created_at: string
          google_property_id: number
        }
        Update: {
          id?: number
          photo_reference?: string
          width?: number | null
          height?: number | null
          attribution?: string | null
          google_photo_id?: string | null
          created_at?: string
          google_property_id?: number
        }
      }
      place_google_reviews: {
        Row: {
          id: number
          author_name: string | null
          rating: number | null
          language_code: string | null
          review_text: string | null
          review_time: string | null
          relative_time_description: string | null
          google_review_id: string | null
          created_at: string
          google_property_id: number
        }
        Insert: {
          id: number
          author_name?: string | null
          rating?: number | null
          language_code?: string | null
          review_text?: string | null
          review_time?: string | null
          relative_time_description?: string | null
          google_review_id?: string | null
          created_at: string
          google_property_id: number
        }
        Update: {
          id?: number
          author_name?: string | null
          rating?: number | null
          language_code?: string | null
          review_text?: string | null
          review_time?: string | null
          relative_time_description?: string | null
          google_review_id?: string | null
          created_at?: string
          google_property_id?: number
        }
      }
      place_llm_enrichment_state: {
        Row: {
          place_id: number
          status: string
          claimed_by_worker_id: string | null
          claim_token: string | null
          claim_expires_at: string | null
          attempt_count: number
          last_attempt_at: string | null
          last_succeeded_at: string | null
          next_retry_at: string | null
          last_error_classification: string | null
          last_error_message: string | null
          updated_at: string
        }
        Insert: {
          place_id: number
          status: string
          claimed_by_worker_id?: string | null
          claim_token?: string | null
          claim_expires_at?: string | null
          attempt_count: number
          last_attempt_at?: string | null
          last_succeeded_at?: string | null
          next_retry_at?: string | null
          last_error_classification?: string | null
          last_error_message?: string | null
          updated_at: string
        }
        Update: {
          place_id?: number
          status?: string
          claimed_by_worker_id?: string | null
          claim_token?: string | null
          claim_expires_at?: string | null
          attempt_count?: number
          last_attempt_at?: string | null
          last_succeeded_at?: string | null
          next_retry_at?: string | null
          last_error_classification?: string | null
          last_error_message?: string | null
          updated_at?: string
        }
      }
      place_user_properties: {
        Row: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          user_id: string
        }
        Insert: {
          id: number
          place_id: number
          is_current: boolean
          created_at: string
          updated_at: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          user_id: string
        }
        Update: {
          id?: number
          place_id?: number
          is_current?: boolean
          created_at?: string
          updated_at?: string
          source_updated_at?: string | null
          name?: string | null
          description?: string | null
          place_type?: string | null
          source_place_type?: string | null
          source_categories?: unknown[] | null
          country_code?: string | null
          region?: string | null
          city?: string | null
          postcode?: string | null
          address?: string | null
          source_lat?: number | null
          source_lon?: number | null
          website?: string | null
          phone?: string | null
          email?: string | null
          opening_hours?: string | null
          fee_info?: string | null
          wheelchair_accessible?: boolean | null
          family_friendly?: boolean | null
          pets_allowed?: boolean | null
          indoor?: boolean | null
          outdoor?: boolean | null
          entry_fee_required?: boolean | null
          reservation_required?: boolean | null
          overnight_stay_allowed?: boolean | null
          has_parking?: boolean | null
          has_restrooms?: boolean | null
          has_drinking_water?: boolean | null
          has_wifi?: boolean | null
          has_shop?: boolean | null
          has_restaurant?: boolean | null
          has_cafe?: boolean | null
          caravan_allowed?: boolean | null
          motorhome_allowed?: boolean | null
          tent_allowed?: boolean | null
          has_electricity?: boolean | null
          has_fresh_water?: boolean | null
          has_shower?: boolean | null
          has_laundry?: boolean | null
          has_dishwashing_area?: boolean | null
          has_grey_water_disposal?: boolean | null
          has_black_water_disposal?: boolean | null
          has_chemical_toilet_disposal?: boolean | null
          has_dump_station?: boolean | null
          has_waste_disposal?: boolean | null
          has_recycling?: boolean | null
          has_bbq_area?: boolean | null
          has_fire_pit?: boolean | null
          has_playground?: boolean | null
          has_pool?: boolean | null
          has_beach?: boolean | null
          nudism_allowed?: boolean | null
          nudism_only?: boolean | null
          has_guided_tours?: boolean | null
          has_audio_guide?: boolean | null
          has_visitor_center?: boolean | null
          has_lockers?: boolean | null
          photography_allowed?: boolean | null
          user_id?: string
        }
      }
      profiles: {
        Row: {
          id: string
          email: string
          role: string
          created_at: string | null
          full_name: string | null
          home_city: string | null
          home_city_coords: Json | null
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          role: string
          created_at?: string | null
          full_name?: string | null
          home_city?: string | null
          home_city_coords?: Json | null
          updated_at: string
        }
        Update: {
          id?: string
          email?: string
          role?: string
          created_at?: string | null
          full_name?: string | null
          home_city?: string | null
          home_city_coords?: Json | null
          updated_at?: string
        }
      }
      settings_audit_log: {
        Row: {
          id: string
          setting_key: string
          operation: string
          old_value: Json | null
          new_value: Json | null
          performed_by: string | null
          performed_at: string | null
          client_ip: string | null
        }
        Insert: {
          id: string
          setting_key: string
          operation: string
          old_value?: Json | null
          new_value?: Json | null
          performed_by?: string | null
          performed_at?: string | null
          client_ip?: string | null
        }
        Update: {
          id?: string
          setting_key?: string
          operation?: string
          old_value?: Json | null
          new_value?: Json | null
          performed_by?: string | null
          performed_at?: string | null
          client_ip?: string | null
        }
      }
      trip_reminders: {
        Row: {
          id: string
          trip_id: string
          user_id: string
          reminder_days_before: number
          is_active: boolean
          last_sent_at: string | null
          created_at: string
        }
        Insert: {
          id: string
          trip_id: string
          user_id: string
          reminder_days_before: number
          is_active: boolean
          last_sent_at?: string | null
          created_at: string
        }
        Update: {
          id?: string
          trip_id?: string
          user_id?: string
          reminder_days_before?: number
          is_active?: boolean
          last_sent_at?: string | null
          created_at?: string
        }
      }
      trip_stops: {
        Row: {
          id: string
          trip_id: string
          day_number: number
          location_name: string
          coordinates: Json
          cost: number
          type: string
          name: string | null
          rating: number | null
          website: string | null
          image: string | null
          amenities: unknown[] | null
          order_index: number | null
          cost_type: string | null
          notes: string | null
          place_id: string | null
          location_geo: string | null
        }
        Insert: {
          id: string
          trip_id: string
          day_number: number
          location_name: string
          coordinates: Json
          cost: number
          type: string
          name?: string | null
          rating?: number | null
          website?: string | null
          image?: string | null
          amenities?: unknown[] | null
          order_index?: number | null
          cost_type?: string | null
          notes?: string | null
          place_id?: string | null
          location_geo?: string | null
        }
        Update: {
          id?: string
          trip_id?: string
          day_number?: number
          location_name?: string
          coordinates?: Json
          cost?: number
          type?: string
          name?: string | null
          rating?: number | null
          website?: string | null
          image?: string | null
          amenities?: unknown[] | null
          order_index?: number | null
          cost_type?: string | null
          notes?: string | null
          place_id?: string | null
          location_geo?: string | null
        }
      }
      trips: {
        Row: {
          id: string
          user_id: string
          start_location: string
          end_location: string
          start_date: string
          end_date: string
          total_distance: number
          total_cost: number
          created_at: string | null
          start_coords: Json | null
          end_coords: Json | null
          route_geometry: Json | null
          fuel_cost: number
          toll_cost: number
          is_shared: boolean | null
          share_token: string | null
          shared_at: string | null
          start_location_geo: string | null
          end_location_geo: string | null
          name: string | null
        }
        Insert: {
          id: string
          user_id: string
          start_location: string
          end_location: string
          start_date: string
          end_date: string
          total_distance: number
          total_cost: number
          created_at?: string | null
          start_coords?: Json | null
          end_coords?: Json | null
          route_geometry?: Json | null
          fuel_cost: number
          toll_cost: number
          is_shared?: boolean | null
          share_token?: string | null
          shared_at?: string | null
          start_location_geo?: string | null
          end_location_geo?: string | null
          name?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          start_location?: string
          end_location?: string
          start_date?: string
          end_date?: string
          total_distance?: number
          total_cost?: number
          created_at?: string | null
          start_coords?: Json | null
          end_coords?: Json | null
          route_geometry?: Json | null
          fuel_cost?: number
          toll_cost?: number
          is_shared?: boolean | null
          share_token?: string | null
          shared_at?: string | null
          start_location_geo?: string | null
          end_location_geo?: string | null
          name?: string | null
        }
      }
      vehicle_profiles: {
        Row: {
          id: string
          user_id: string
          name: string
          max_speed: number | null
          height: number | null
          weight: number | null
          fuel_consumption: number | null
          is_default: boolean | null
          created_at: string
        }
        Insert: {
          id: string
          user_id: string
          name: string
          max_speed?: number | null
          height?: number | null
          weight?: number | null
          fuel_consumption?: number | null
          is_default?: boolean | null
          created_at: string
        }
        Update: {
          id?: string
          user_id?: string
          name?: string
          max_speed?: number | null
          height?: number | null
          weight?: number | null
          fuel_consumption?: number | null
          is_default?: boolean | null
          created_at?: string
        }
      }
      worker_control: {
        Row: {
          worker_id: string
          registered_at: string
          last_seen_at: string
          status_desired: string
          status_actual: string
          desired_concurrency: number
          current_jobs: number
          current_ip: string | null
          cpu_pct: number | null
          ram_pct: number | null
          disk_pct: number | null
          hostname: string | null
          version: string | null
          last_error_message: string | null
          desired_updated_at: string | null
          desired_updated_by: string | null
          stats_updated_at: string
        }
        Insert: {
          worker_id: string
          registered_at: string
          last_seen_at: string
          status_desired: string
          status_actual: string
          desired_concurrency: number
          current_jobs: number
          current_ip?: string | null
          cpu_pct?: number | null
          ram_pct?: number | null
          disk_pct?: number | null
          hostname?: string | null
          version?: string | null
          last_error_message?: string | null
          desired_updated_at?: string | null
          desired_updated_by?: string | null
          stats_updated_at: string
        }
        Update: {
          worker_id?: string
          registered_at?: string
          last_seen_at?: string
          status_desired?: string
          status_actual?: string
          desired_concurrency?: number
          current_jobs?: number
          current_ip?: string | null
          cpu_pct?: number | null
          ram_pct?: number | null
          disk_pct?: number | null
          hostname?: string | null
          version?: string | null
          last_error_message?: string | null
          desired_updated_at?: string | null
          desired_updated_by?: string | null
          stats_updated_at?: string
        }
      }
      worker_llm_usage: {
        Row: {
          bucket_start: string
          worker_id: string
          input_tokens: number
          output_tokens: number
          request_count: number
          success_count: number
          failure_count: number
        }
        Insert: {
          bucket_start: string
          worker_id: string
          input_tokens: number
          output_tokens: number
          request_count: number
          success_count: number
          failure_count: number
        }
        Update: {
          bucket_start?: string
          worker_id?: string
          input_tokens?: number
          output_tokens?: number
          request_count?: number
          success_count?: number
          failure_count?: number
        }
      }
    }
    Views: {
      geography_columns: {
        Row: {
          f_table_catalog: string | null
          f_table_schema: string | null
          f_table_name: string | null
          f_geography_column: string | null
          coord_dimension: number | null
          srid: number | null
          type: string | null
        }
      }
      geometry_columns: {
        Row: {
          f_table_catalog: string | null
          f_table_schema: string | null
          f_table_name: string | null
          f_geometry_column: string | null
          coord_dimension: number | null
          srid: number | null
          type: string | null
        }
      }
      campsite_full: {
        Row: {
          place_id: string | null
          name: string | null
          location: string | null
          lat: number | null
          lng: number | null
          source_type: string | null
          osm_id: string | null
          osm_tags: Json | null
          website: string | null
          opening_hours: string | null
          contact_phone: string | null
          contact_email: string | null
          scraped_website_url: string | null
          scraped_at: string | null
          scraped_price_info: Json | null
          scraped_data_source: string | null
          description: string | null
          description_source: string | null
          description_generated_at: string | null
          description_version: number | null
          estimated_price: number | null
          price_source: string | null
          user_price_count: number | null
          user_price_avg: number | null
          place_types: unknown[] | null
          created_at: string | null
          updated_at: string | null
          google_place_id: string | null
          google_photos: Json | null
          google_reviews: Json | null
          google_data_fetched_at: string | null
          google_data_expires_at: string | null
          google_data_expired: boolean | null
          review_count: number | null
          avg_rating: number | null
          user_price_entries: number | null
          favorite_count: number | null
          google_rating: number | null
          rating: number | null
          type: string | null
          has_toilet: boolean | null
          has_shower: boolean | null
          has_electricity: boolean | null
          has_dogs_allowed: boolean | null
          has_wifi: boolean | null
          has_beach: boolean | null
          has_laundry: boolean | null
          has_restaurant: boolean | null
          has_bar: boolean | null
          has_shop: boolean | null
          has_pool: boolean | null
          has_playground: boolean | null
          has_dump_station: boolean | null
          has_water: boolean | null
          has_washing_machine: boolean | null
          has_dishwasher: boolean | null
        }
      }
      campsite_api_read_model: {
        Row: {
          place_id: string | null
          name: string | null
          location: string | null
          lat: number | null
          lng: number | null
          source_type: string | null
          osm_id: string | null
          osm_tags: Json | null
          website: string | null
          opening_hours: string | null
          contact_phone: string | null
          contact_email: string | null
          scraped_website_url: string | null
          scraped_at: string | null
          scraped_price_info: Json | null
          scraped_data_source: string | null
          description: string | null
          description_source: string | null
          description_generated_at: string | null
          description_version: number | null
          estimated_price: number | null
          price_source: string | null
          user_price_count: number | null
          user_price_avg: number | null
          place_types: unknown[] | null
          created_at: string | null
          updated_at: string | null
          google_place_id: string | null
          google_photos: Json | null
          google_reviews: Json | null
          google_data_fetched_at: string | null
          google_data_expires_at: string | null
          google_data_expired: boolean | null
          review_count: number | null
          avg_rating: number | null
          user_price_entries: number | null
          favorite_count: number | null
          google_rating: number | null
          rating: number | null
          type: string | null
          has_toilet: boolean | null
          has_shower: boolean | null
          has_electricity: boolean | null
          has_dogs_allowed: boolean | null
          has_wifi: boolean | null
          has_beach: boolean | null
          has_laundry: boolean | null
          has_restaurant: boolean | null
          has_bar: boolean | null
          has_shop: boolean | null
          has_pool: boolean | null
          has_playground: boolean | null
          has_dump_station: boolean | null
          has_water: boolean | null
          has_washing_machine: boolean | null
          has_dishwasher: boolean | null
        }
      }
      campsite_price_summary: {
        Row: {
          place_id: string | null
          osm_place_id: string | null
          price_count: number | null
          avg_price: number | null
          min_price: number | null
          max_price: number | null
          avg_rating: number | null
          review_count: number | null
        }
      }
      campsite_review_summary: {
        Row: {
          place_id: string | null
          place_name: string | null
          review_count: number | null
          avg_rating: number | null
          min_rating: number | null
          max_rating: number | null
        }
      }
      place_resolved_my: {
        Row: {
          id: number | null
          geom: string | null
          lat: number | null
          lon: number | null
          is_active: boolean | null
          place_created_at: string | null
          place_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          has_osm: boolean | null
          has_google: boolean | null
          has_llm: boolean | null
          has_user: boolean | null
          name_source: string | null
          osm_updated_at: string | null
          google_updated_at: string | null
          llm_updated_at: string | null
          user_updated_at: string | null
          osm_source_updated_at: string | null
          google_source_updated_at: string | null
          llm_source_updated_at: string | null
          user_source_updated_at: string | null
        }
      }
      place_resolved_public: {
        Row: {
          id: number | null
          geom: string | null
          lat: number | null
          lon: number | null
          is_active: boolean | null
          place_created_at: string | null
          place_updated_at: string | null
          name: string | null
          description: string | null
          place_type: string | null
          source_place_type: string | null
          source_categories: unknown[] | null
          country_code: string | null
          region: string | null
          city: string | null
          postcode: string | null
          address: string | null
          source_lat: number | null
          source_lon: number | null
          website: string | null
          phone: string | null
          email: string | null
          opening_hours: string | null
          fee_info: string | null
          wheelchair_accessible: boolean | null
          family_friendly: boolean | null
          pets_allowed: boolean | null
          indoor: boolean | null
          outdoor: boolean | null
          entry_fee_required: boolean | null
          reservation_required: boolean | null
          overnight_stay_allowed: boolean | null
          has_parking: boolean | null
          has_restrooms: boolean | null
          has_drinking_water: boolean | null
          has_wifi: boolean | null
          has_shop: boolean | null
          has_restaurant: boolean | null
          has_cafe: boolean | null
          caravan_allowed: boolean | null
          motorhome_allowed: boolean | null
          tent_allowed: boolean | null
          has_electricity: boolean | null
          has_fresh_water: boolean | null
          has_shower: boolean | null
          has_laundry: boolean | null
          has_dishwashing_area: boolean | null
          has_grey_water_disposal: boolean | null
          has_black_water_disposal: boolean | null
          has_chemical_toilet_disposal: boolean | null
          has_dump_station: boolean | null
          has_waste_disposal: boolean | null
          has_recycling: boolean | null
          has_bbq_area: boolean | null
          has_fire_pit: boolean | null
          has_playground: boolean | null
          has_pool: boolean | null
          has_beach: boolean | null
          nudism_allowed: boolean | null
          nudism_only: boolean | null
          has_guided_tours: boolean | null
          has_audio_guide: boolean | null
          has_visitor_center: boolean | null
          has_lockers: boolean | null
          photography_allowed: boolean | null
          has_osm: boolean | null
          has_google: boolean | null
          has_llm: boolean | null
          name_source: string | null
          osm_updated_at: string | null
          google_updated_at: string | null
          llm_updated_at: string | null
          osm_source_updated_at: string | null
          google_source_updated_at: string | null
          llm_source_updated_at: string | null
        }
      }
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      cost_type: 'per_night' | 'entry_fee' | 'none'
      enrichment_job_type_enum: 'enrich_llm' | 'refresh_osm' | 'google_places'
      enrichment_status_enum: 'pending' | 'processing' | 'done' | 'failed' | 'needs_review'
      job_status: 'pending' | 'processing' | 'completed' | 'failed' | 'skipped'
      job_status_enum: 'queued' | 'running' | 'done' | 'failed' | 'dead'
      place_type_enum: 'camp_site' | 'camper_stop' | 'overnight_parking' | 'parking' | 'attraction'
      aal_level: 'aal1' | 'aal2' | 'aal3'
      stop_type: 'camping' | 'stellplatz' | 'poi' | 'city' | 'address'
      user_role: 'user' | 'admin'
      code_challenge_method: 's256' | 'plain'
      factor_status: 'unverified' | 'verified'
      factor_type: 'totp' | 'webauthn' | 'phone'
      oauth_authorization_status: 'pending' | 'approved' | 'denied' | 'expired'
      oauth_client_type: 'public' | 'confidential'
      oauth_registration_type: 'dynamic' | 'manual'
      oauth_response_type: 'code'
      one_time_token_type: 'confirmation_token' | 'reauthentication_token' | 'recovery_token' | 'email_change_token_new' | 'email_change_token_current' | 'phone_change_token'
      buckettype: 'STANDARD' | 'ANALYTICS' | 'VECTOR'
    }
  }
}
