require 'json'
require 'net/http'
require 'uri'

# Generated with Claude

module Jekyll
  class GeocodePage < Generator
    safe true
    priority :low

    def generate(site)
      return unless site.data['shows']
      
      # Get unique locations
      locations = site.data['shows'].map { |show| show['Location'] }.uniq.compact
      
      # Load existing coordinates if they exist
      coords_file = File.join(site.source, '_data', 'geocoded_locations.json')
      existing_coords = {}
      if File.exist?(coords_file)
        existing_coords = JSON.parse(File.read(coords_file))
      end
      
      # Geocode new locations
      new_locations = locations.select { |loc| !existing_coords[loc] }
      
      if new_locations.any?
        puts "Geocoding #{new_locations.length} new locations..."
        
        new_locations.each do |location|
          puts "  Geocoding: #{location}"
          coords = geocode_location(location)
          
          if coords
            existing_coords[location] = coords
            puts "    ✓ Found: #{coords['lat']}, #{coords['lng']}"
          else
            puts "    ✗ Failed to geocode"
          end
          
          # Be nice to the API - wait 1 second between requests
          sleep(1)
        end
        
        # Save updated coordinates
        File.write(coords_file, JSON.pretty_generate(existing_coords))
        puts "Saved coordinates to #{coords_file}"
      else
        puts "All locations already geocoded!"
      end
      
      # Make available to templates
      site.data['location_coords'] = existing_coords
    end
    
    def geocode_location(location)
      # Using Nominatim (OpenStreetMap's free geocoding service)
      uri = URI("https://nominatim.openstreetmap.org/search")
      params = {
        q: location,
        format: 'json',
        limit: 1
      }
      uri.query = URI.encode_www_form(params)
      
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        
        request = Net::HTTP::Get.new(uri)
        # IMPORTANT: Nominatim requires a User-Agent header
        request['User-Agent'] = 'JekyllTourMap/1.0 (me@spencertweedy.com)'
        
        response = http.request(request)
        
        if response.is_a?(Net::HTTPSuccess)
          results = JSON.parse(response.body)
          if results.any?
            {
              'lat' => results[0]['lat'].to_f,
              'lng' => results[0]['lon'].to_f
            }
          else
            nil
          end
        else
          puts "    Error: HTTP #{response.code}"
          nil
        end
      rescue => e
        puts "    Exception: #{e.message}"
        nil
      end
    end
  end
end