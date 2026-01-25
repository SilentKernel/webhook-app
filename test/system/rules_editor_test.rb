require "application_system_test_case"

class RulesEditorTest < ApplicationSystemTestCase
  setup do
    @user = users(:owner)
    sign_in @user
  end

  test "rules editor displays on new connection page" do
    visit new_connection_path(locale: :en)

    assert_selector "fieldset legend", text: "Rules Configuration"
    assert_selector "[data-rules-editor-target='eventTypeInput']"
    assert_selector "[data-rules-editor-target='delayInput']"
  end

  test "can add event type filter" do
    visit new_connection_path(locale: :en)

    # Find the event type input and add a type
    fill_in_event_type "payment.completed"
    click_button "Add"

    # Verify badge appears
    assert_selector ".badge.badge-primary", text: "payment.completed"

    # Verify hidden field is updated
    hidden_field = find("[data-rules-editor-target='hiddenField']", visible: false)
    rules = JSON.parse(hidden_field.value)
    assert_equal 1, rules.length
    assert_equal "filter", rules[0]["type"]
    assert_includes rules[0]["config"]["event_types"], "payment.completed"
  end

  test "can add multiple event types" do
    visit new_connection_path(locale: :en)

    fill_in_event_type "payment.completed"
    click_button "Add"

    fill_in_event_type "checkout.session.completed"
    click_button "Add"

    # Verify both badges appear
    assert_selector ".badge.badge-primary", text: "payment.completed"
    assert_selector ".badge.badge-primary", text: "checkout.session.completed"

    # Verify hidden field contains both
    hidden_field = find("[data-rules-editor-target='hiddenField']", visible: false)
    rules = JSON.parse(hidden_field.value)
    event_types = rules[0]["config"]["event_types"]
    assert_equal 2, event_types.length
    assert_includes event_types, "payment.completed"
    assert_includes event_types, "checkout.session.completed"
  end

  test "can remove event type by clicking badge" do
    visit new_connection_path(locale: :en)

    fill_in_event_type "payment.completed"
    find("button", text: "Add", match: :first).click
    fill_in_event_type "checkout.session.completed"
    find("button", text: "Add", match: :first).click

    # Verify both badges exist
    assert_selector ".badge.badge-primary", text: "payment.completed", wait: 5
    assert_selector ".badge.badge-primary", text: "checkout.session.completed"

    # Remove one event type - click the X button inside the badge
    badge = find(".badge.badge-primary", text: "payment.completed")
    badge.find("button").click

    # Verify only one badge remains
    assert_no_selector ".badge.badge-primary", text: "payment.completed", wait: 5
    assert_selector ".badge.badge-primary", text: "checkout.session.completed"
  end

  test "can set delay" do
    visit new_connection_path(locale: :en)

    # Set a delay
    fill_in_delay 60

    # Verify hidden field is updated
    hidden_field = find("[data-rules-editor-target='hiddenField']", visible: false)
    rules = JSON.parse(hidden_field.value)
    delay_rule = rules.find { |r| r["type"] == "delay" }
    assert_not_nil delay_rule
    assert_equal 60, delay_rule["config"]["seconds"]
  end

  test "delay of 0 removes delay rule" do
    visit new_connection_path(locale: :en)

    # Set and then remove delay
    fill_in_delay 60
    fill_in_delay 0

    # Verify hidden field has no delay rule
    hidden_field = find("[data-rules-editor-target='hiddenField']", visible: false)
    assert hidden_field.value.blank? || !hidden_field.value.include?("delay")
  end

  test "editing connection shows existing rules" do
    connection = connections(:connection_with_rules)
    visit edit_connection_path(connection, locale: :en)

    # Verify existing event types are displayed
    assert_selector ".badge.badge-primary", text: "payment.completed"
    assert_selector ".badge.badge-primary", text: "checkout.session.completed"

    # Verify delay is set
    delay_input = find("[data-rules-editor-target='delayInput']")
    assert_equal "30", delay_input.value
  end

  test "can import rules from another connection" do
    # Create a new connection to import into
    visit new_connection_path(locale: :en)

    # Select the connection with rules in the import dropdown
    import_select = find("[data-rules-editor-target='importSelect']")
    import_select.select "Connection with Rules"
    find("button", text: "Import").click

    # Verify rules were imported
    assert_selector ".badge.badge-primary", text: "payment.completed", wait: 5
    assert_selector ".badge.badge-primary", text: "checkout.session.completed"

    delay_input = find("[data-rules-editor-target='delayInput']")
    assert_equal "30", delay_input.value
  end

  test "adding event type with enter key" do
    visit new_connection_path(locale: :en)

    event_input = find("[data-rules-editor-target='eventTypeInput']")
    event_input.fill_in with: "payment.completed"
    event_input.send_keys :enter

    assert_selector ".badge.badge-primary", text: "payment.completed"
  end

  test "cannot add duplicate event types" do
    visit new_connection_path(locale: :en)

    fill_in_event_type "payment.completed"
    click_button "Add"
    fill_in_event_type "payment.completed"
    click_button "Add"

    # Should only have one badge
    assert_selector ".badge.badge-primary", text: "payment.completed", count: 1
  end

  test "rules persist after form submission" do
    visit new_connection_path(locale: :en)

    # Fill in required fields
    fill_in "Name", with: "Test Connection with Rules"

    # Add rules
    fill_in_event_type "payment.completed"
    find("button", text: "Add", match: :first).click
    fill_in_delay 30

    # Verify the hidden field was set correctly
    hidden_field = find("[data-rules-editor-target='hiddenField']", visible: false)
    rules = JSON.parse(hidden_field.value)

    assert_equal 2, rules.length
    assert rules.any? { |r| r["type"] == "filter" }
    assert rules.any? { |r| r["type"] == "delay" }
  end

  private

  def sign_in(user)
    visit new_user_session_path(locale: :en)
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
    assert_no_current_path new_user_session_path(locale: :en), wait: 5
  end

  def fill_in_event_type(value)
    find("[data-rules-editor-target='eventTypeInput']").fill_in with: value
  end

  def fill_in_delay(seconds)
    delay_input = find("[data-rules-editor-target='delayInput']")
    delay_input.fill_in with: ""
    delay_input.fill_in with: seconds.to_s
    # Trigger change event
    delay_input.send_keys :tab
  end
end
