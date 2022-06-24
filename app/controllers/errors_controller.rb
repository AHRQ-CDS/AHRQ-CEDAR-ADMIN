# frozen_string_literal: true

# Controller to handle error conditions with custom error pages
class ErrorsController < ApplicationController
  def error_404
    render status: :not_found
  end

  def error_500
    render status: :internal_server_error
  end
end
