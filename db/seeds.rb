# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# VerificationType seeds - verification methods for webhook signatures
verification_types = [
  { name: "None / Custom", slug: "none", description: "No signature verification", position: 0 },
  { name: "Stripe", slug: "stripe", description: "Stripe webhook signature verification", position: 1 },
  { name: "Shopify", slug: "shopify", description: "Shopify HMAC verification", position: 2 },
  { name: "GitHub", slug: "github", description: "GitHub webhook signature", position: 3 },
  { name: "Generic HMAC", slug: "hmac", description: "Generic HMAC-SHA256 verification", position: 4 }
]

verification_types.each do |attrs|
  VerificationType.find_or_create_by!(slug: attrs[:slug]) do |vt|
    vt.name = attrs[:name]
    vt.description = attrs[:description]
    vt.position = attrs[:position]
  end
end

# SourceType seeds - preset configurations for common webhook providers
source_types = [
  { name: "Stripe", slug: "stripe", verification_type_slug: "stripe" },
  { name: "Shopify", slug: "shopify", verification_type_slug: "shopify" },
  { name: "GitHub", slug: "github", verification_type_slug: "github" },
  { name: "Twilio", slug: "twilio", verification_type_slug: "hmac" },
  { name: "Generic HMAC", slug: "hmac", verification_type_slug: "hmac" },
  { name: "None / Custom", slug: "none", verification_type_slug: "none" }
]

source_types.each do |attrs|
  vtype = VerificationType.find_by!(slug: attrs[:verification_type_slug])
  SourceType.find_or_create_by!(slug: attrs[:slug]) do |st|
    st.name = attrs[:name]
    st.verification_type = vtype
  end
end

# Development seeds - only run in development environment
if Rails.env.development?
  puts "Creating development seed data..."

  # Create development user (confirmed for immediate login)
  user = User.find_or_create_by!(email: "ludo@hey.com") do |u|
    u.password = "JustForDev2026"
    u.first_name = "Ludo"
    u.last_name = "Dev"
    u.confirmed_at = Time.current
  end

  # Create organization
  org = Organization.find_or_create_by!(name: "Ludo Dev - Développeur Freelance") do |o|
    o.timezone = "Paris"
  end

  # Create owner membership
  Membership.find_or_create_by!(user: user, organization: org) do |m|
    m.role = :owner
  end

  # Create source "n8n trigger"
  source_n8n = Source.find_or_create_by!(organization: org, name: "n8n trigger") do |s|
    s.source_type = SourceType.find_by(slug: "none")
    s.verification_type = VerificationType.find_by!(slug: "none")
    s.status = :active
  end

  # Create destination "Test n8n"
  dest_n8n = Destination.find_or_create_by!(organization: org, name: "Test n8n") do |d|
    d.url = "https://n8n.ludovic-frank.fr/webhook/ae6d36fb-1740-404b-b3ff-faf41e22c1de"
    d.http_method = "POST"
    d.auth_type = :none
    d.status = :active
    d.timeout_seconds = 30
  end

  # Create connection between source and destination
  Connection.find_or_create_by!(source: source_n8n, destination: dest_n8n) do |c|
    c.status = :active
    c.priority = 0
  end

  # Pagination test data - only created when SEED_PAGINATION=true
  if ENV["SEED_PAGINATION"]
    # Skip if pagination data already exists
    if Source.where(organization: org).count > 5
      puts "Pagination test data already exists, skipping..."
    else
      puts "Creating pagination test data..."

      # Fetch source types and verification types for variety
      source_types_list = SourceType.all.to_a

      # 1. Create 30 Sources
      sources = []
      30.times do |i|
        st = source_types_list[i % source_types_list.size]
        sources << Source.create!(
          organization: org,
          name: "Source #{i + 1} - #{st.name}",
          source_type: st,
          verification_type: st.verification_type,
          status: i % 5 == 0 ? :paused : :active
        )
      end
      puts "  Created #{sources.size} sources"

      # 2. Create 30 Destinations
      auth_types = %i[none bearer basic api_key]
      http_methods = %w[POST POST POST PUT PATCH] # Mostly POST
      statuses = %i[active active active paused disabled]
      destinations = []
      30.times do |i|
        auth = auth_types[i % auth_types.size]
        destinations << Destination.create!(
          organization: org,
          name: "Destination #{i + 1}",
          url: "https://api#{i + 1}.example.com/webhook",
          http_method: http_methods[i % http_methods.size],
          status: statuses[i % statuses.size],
          auth_type: auth,
          timeout_seconds: [10, 15, 30].sample
        )
      end
      puts "  Created #{destinations.size} destinations"

      # 3. Create ~45 Connections (each source connects to 1-2 destinations)
      connections = []
      created_pairs = Set.new
      sources.each_with_index do |source, i|
        num_connections = (i % 3 == 0) ? 2 : 1
        num_connections.times do |j|
          dest_idx = (i + j * 7) % destinations.size
          dest = destinations[dest_idx]
          pair = [source.id, dest.id]
          next if created_pairs.include?(pair)

          created_pairs.add(pair)
          connections << Connection.create!(
            source: source,
            destination: dest,
            status: %i[active active active paused disabled][i % 5],
            priority: i % 4
          )
        end
      end
      puts "  Created #{connections.size} connections"

      # 4. Create 50 Events spread across sources
      event_types = %w[payment.completed payment.failed customer.created customer.updated
                       order.placed order.shipped push pull_request issue.opened
                       subscription.created subscription.cancelled invoice.paid]
      events = []
      50.times do |i|
        source = sources[i % sources.size]
        events << Event.create!(
          source: source,
          event_type: event_types[i % event_types.size],
          payload: { id: SecureRandom.uuid, index: i, data: "Sample payload #{i}" }.to_json,
          headers: { "Content-Type" => "application/json", "X-Request-Id" => SecureRandom.uuid }.to_json,
          received_at: Time.current - rand(0..7).days - rand(0..23).hours
        )
      end
      puts "  Created #{events.size} events"

      # 5. Create ~60 Deliveries with mixed statuses
      delivery_statuses = %i[pending pending success success success failed]
      deliveries_created = 0
      events.each_with_index do |event, i|
        # Find connections for this event's source
        source_connections = connections.select { |c| c.source_id == event.source_id }
        next if source_connections.empty?

        # Create 1-2 deliveries per event
        num_deliveries = (i % 3 == 0) ? 2 : 1
        num_deliveries.times do |j|
          conn = source_connections[j % source_connections.size]
          status = delivery_statuses[(i + j) % delivery_statuses.size]
          attempt_count = status == :success ? 1 : (status == :failed ? 3 : 0)

          Delivery.create!(
            event: event,
            connection: conn,
            destination: conn.destination,
            status: status,
            attempt_count: attempt_count,
            max_attempts: 5,
            next_attempt_at: status == :pending ? Time.current + 1.minute : nil,
            completed_at: %i[success failed].include?(status) ? Time.current - rand(0..6).days : nil
          )
          deliveries_created += 1
        end
      end
      puts "  Created #{deliveries_created} deliveries"

      puts "Pagination test data created!"
    end
  else
    puts "Skipping pagination test data (use SEED_PAGINATION=true to include)"
  end


  puts "Development seed data created!"
  puts "  Login: ludo@hey.com / JustForDev2026"
end
