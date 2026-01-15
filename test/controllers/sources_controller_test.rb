# frozen_string_literal: true

require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @organization = organizations(:acme)
    @source = sources(:stripe_production)
    @other_org_source = sources(:other_org_source)
    @source_type = source_types(:stripe)
    sign_in @user
  end

  # Index tests
  test "should get index" do
    get sources_url(locale: :en)
    assert_response :success
  end

  test "redirects to login when not authenticated" do
    sign_out @user
    get sources_url(locale: :en)
    assert_redirected_to new_user_session_path(locale: :en)
  end

  # Show tests
  test "should show source" do
    get source_url(@source, locale: :en)
    assert_response :success
  end

  test "should not show source from another organization" do
    get source_url(@other_org_source, locale: :en)
    assert_response :not_found
  end

  # New tests
  test "should get new" do
    get new_source_url(locale: :en)
    assert_response :success
  end

  # Create tests
  test "should create source with valid params" do
    assert_difference("Source.count") do
      post sources_url(locale: :en), params: {
        source: {
          name: "New Source",
          source_type_id: @source_type.id,
          verification_type_id: verification_types(:stripe).id,
          status: "active"
        }
      }
    end

    source = Source.last
    assert_redirected_to source_url(source, locale: :en)
    assert_equal @organization.id, source.organization_id
  end

  test "should not create source with invalid params" do
    assert_no_difference("Source.count") do
      post sources_url(locale: :en), params: {
        source: {
          name: "",
          verification_type_id: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit tests
  test "should get edit" do
    get edit_source_url(@source, locale: :en)
    assert_response :success
  end

  test "should not get edit for source from another organization" do
    get edit_source_url(@other_org_source, locale: :en)
    assert_response :not_found
  end

  # Update tests
  test "should update source" do
    patch source_url(@source, locale: :en), params: {
      source: {
        name: "Updated Source Name"
      }
    }

    assert_redirected_to source_url(@source, locale: :en)
    @source.reload
    assert_equal "Updated Source Name", @source.name
  end

  test "should not update source with invalid params" do
    patch source_url(@source, locale: :en), params: {
      source: {
        name: ""
      }
    }

    assert_response :unprocessable_entity
  end

  test "should not update source from another organization" do
    patch source_url(@other_org_source, locale: :en), params: {
      source: {
        name: "Hacked Name"
      }
    }

    assert_response :not_found
  end

  # Destroy tests
  test "should destroy source" do
    assert_difference("Source.count", -1) do
      delete source_url(@source, locale: :en)
    end

    assert_redirected_to sources_url(locale: :en)
  end

  test "should not destroy source from another organization" do
    assert_no_difference("Source.count") do
      delete source_url(@other_org_source, locale: :en)
    end

    assert_response :not_found
  end
end
