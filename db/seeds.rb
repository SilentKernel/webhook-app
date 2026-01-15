# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# SourceType seeds - preset configurations for common webhook providers
source_types = [
  { name: "Stripe", slug: "stripe", verification_type: "stripe" },
  { name: "Shopify", slug: "shopify", verification_type: "shopify" },
  { name: "GitHub", slug: "github", verification_type: "github" },
  { name: "Twilio", slug: "twilio", verification_type: "hmac" },
  { name: "Generic HMAC", slug: "hmac", verification_type: "hmac" },
  { name: "None / Custom", slug: "none", verification_type: "none" }
]

source_types.each do |attrs|
  SourceType.find_or_create_by!(slug: attrs[:slug]) do |st|
    st.name = attrs[:name]
    st.verification_type = attrs[:verification_type]
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

  puts "Development seed data created!"
  puts "  Login: ludo@hey.com / JustForDev2026"
end
