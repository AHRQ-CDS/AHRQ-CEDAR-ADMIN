# frozen_string_literal: true

# Application helper methods
module ApplicationHelper

  # Adapted from: https://stackoverflow.com/questions/9879169/how-to-get-twitter-bootstrap-navigation-to-show-active-link
  def nav_bar
    content_tag(:ul, class: "nav navbar-nav") do
      yield
    end
  end

  def nav_link(text, path)
    options = current_page?(path) ? { class: "nav-item active" } : { class: "nav-item"}
    content_tag(:li, options) do
      link_to text, path, class: "nav-link"
    end
  end
end
