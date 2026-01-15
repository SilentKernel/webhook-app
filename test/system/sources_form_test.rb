require "application_system_test_case"

class SourcesFormTest < ApplicationSystemTestCase
  setup do
    @user = users(:owner)
    @stripe_type = source_types(:stripe)
    @github_type = source_types(:github)
    sign_in @user
  end

  test "source type combobox is searchable" do
    visit new_source_path(locale: :en)

    # Wait for page to load and find the source type combobox input
    source_type_input = find("#source-source-type", wait: 5)
    source_type_input.fill_in with: "Str"

    # Verify filtered options appear
    assert_selector ".hw-combobox__option", text: "Stripe"
  end

  test "verification type combobox is searchable" do
    visit new_source_path(locale: :en)

    # Wait for page to load and find the verification type combobox input
    verification_input = find("#source-verification-type", wait: 5)
    verification_input.fill_in with: "git"

    # Verify filtered options appear
    assert_selector ".hw-combobox__option", text: "GitHub"
  end

  test "selecting source type auto-fills verification type" do
    visit new_source_path(locale: :en)

    # Click on the source type combobox to open it
    find("#source-source-type", wait: 5).click

    # Select Stripe from the dropdown
    find(".hw-combobox__option", text: "Stripe").click

    # Wait a moment for the Stimulus controller to update the verification type
    sleep 0.2

    # Verify the verification type was auto-filled
    verification_input = find("#source-verification-type")
    assert_equal "Stripe", verification_input.value
  end

  test "can create source with combobox selections" do
    visit new_source_path(locale: :en)

    # Wait for page to load
    assert_selector "#source-source-type", wait: 5

    # Fill in the name
    fill_in "Name", with: "Test Webhook Source"

    # Select source type via combobox
    find("#source-source-type").click
    find(".hw-combobox__option", text: "GitHub").click

    # Wait for the Stimulus controller to update
    sleep 0.2

    # Verification type should be auto-filled, verify the hidden value is set
    verification_hidden = find('input[name="source[verification_type_id]"]', visible: false)
    github_vtype = VerificationType.find_by(slug: "github")
    assert_equal github_vtype.id.to_s, verification_hidden.value

    # Submit the form
    click_button "Create Source"

    # Verify redirect and success
    assert_selector ".alert", text: /created/i
    assert_text "Test Webhook Source"
  end

  test "can create source with custom source type and manual verification" do
    visit new_source_path(locale: :en)

    # Wait for page to load
    assert_selector "#source-source-type", wait: 5

    # Fill in the name
    fill_in "Name", with: "Custom Webhook Source"

    # Leave source type as Custom (no preset) - it's the default
    # Select verification type manually
    find("#source-verification-type").click
    find(".hw-combobox__option", text: "Generic HMAC").click

    # Submit the form
    click_button "Create Source"

    # Verify redirect and success
    assert_selector ".alert", text: /created/i
    assert_text "Custom Webhook Source"
  end

  test "comboboxes display default values on new source" do
    visit new_source_path(locale: :en)

    # Wait for page to load
    assert_selector "#source-source-type", wait: 5

    # Source Type shows placeholder "Custom (no preset)" when empty
    source_type_input = find("#source-source-type")
    assert_equal "Custom (no preset)", source_type_input[:placeholder]

    # Verification Type is pre-selected to "None / Custom"
    verification_input = find("#source-verification-type")
    assert_equal "None / Custom", verification_input.value

    # Select source type and verify auto-fill works
    find("#source-source-type").click
    find(".hw-combobox__option", text: "Stripe").click

    # Wait for the Stimulus controller to update
    sleep 0.2

    # Verify both comboboxes show expected values
    assert_equal "Stripe", find("#source-source-type").value
    assert_equal "Stripe", find("#source-verification-type").value
  end

  test "can edit source with combobox" do
    source = sources(:stripe_production)
    visit edit_source_path(source, locale: :en)

    # Wait for page to load
    assert_selector "#source-source-type", wait: 5

    # Change source type to GitHub
    find("#source-source-type").click
    find(".hw-combobox__option", text: "GitHub").click

    # Update the source
    click_button "Update Source"

    # Verify success
    assert_selector ".alert", text: /updated/i
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :en)
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
    # Wait for login to complete by checking we're no longer on the login page
    assert_no_current_path new_user_session_path(locale: :en), wait: 5
  end
end
