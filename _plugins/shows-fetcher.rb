# _plugins/baserow_fetcher.rb
require 'net/http'
require 'json'

# Made with help from Claude AI

# Load .env file
begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
  # Fallback: manually load .env if dotenv gem isn't available
  if File.exist?('.env')
    File.readlines('.env').each do |line|
      line.strip!
      next if line.empty? || line.start_with?('#')
      
      key, value = line.split('=', 2)
      ENV[key] = value.gsub(/^['"]|['"]$/, '') if key && value
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  # Configuration
  baserow_token = ENV['BASEROW_TOKEN']
  table_id = ENV['BASEROW_TABLE_ID'] || site.config.dig('baserow', 'table_id')
  baserow_host = ENV['BASEROW_HOST'] || site.config.dig('baserow', 'host') || 'https://api.baserow.io'
  
  unless baserow_token && table_id
    Jekyll.logger.warn "Baserow:", "Missing BASEROW_TOKEN or table_id, skipping fetch"
    next
  end
  
  Jekyll.logger.info "Baserow:", "Fetching shows data from #{baserow_host}..."
  
  begin
    all_shows = []
    page = 1
    per_page = 200  # Max allowed by Baserow
    
    loop do
      # Baserow API endpoint with pagination
      url = URI("#{baserow_host}/api/database/rows/table/#{table_id}/?user_field_names=true&page=#{page}&size=#{per_page}")
      
      # Make API request
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == 'https'
      
      request = Net::HTTP::Get.new(url)
      request['Authorization'] = "Token #{baserow_token}"
      request['Content-Type'] = 'application/json'
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        shows = data['results']
        
        break if shows.empty?  # No more records
        
        all_shows.concat(shows)
        Jekyll.logger.info "Baserow:", "Fetched page #{page} (#{shows.length} records)"
        
        # Check if there are more pages
        break unless data['next']
        page += 1
      else
        Jekyll.logger.error "Baserow:", "API request failed: #{response.code} #{response.message}"
        break
      end
    end
    
    if all_shows.any?
      # Create _data directory
      data_dir = File.join(site.source, '_data')
      Dir.mkdir(data_dir) unless Dir.exist?(data_dir)
      
      # Save shows data
      File.write(
        File.join(data_dir, 'shows.json'),
        JSON.pretty_generate(all_shows)
      )
      
      Jekyll.logger.info "Baserow:", "Successfully fetched #{all_shows.length} total shows"
    else
      Jekyll.logger.warn "Baserow:", "No shows found"
    end
    
  rescue => e
    Jekyll.logger.error "Baserow:", "Error: #{e.message}"
  end
end
