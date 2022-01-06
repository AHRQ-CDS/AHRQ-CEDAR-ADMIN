# frozen_string_literal: true

# Application helper methods
module ApplicationHelper
  # Adapted from: https://stackoverflow.com/questions/9879169/how-to-get-twitter-bootstrap-navigation-to-show-active-link
  def nav_bar(&block)
    tag.ul(class: 'nav navbar-nav', &block)
  end

  def nav_link(text, path)
    options = current_page?(path) ? { class: 'nav-item active' } : { class: 'nav-item' }
    tag.li(**options) do
      link_to text, path, class: 'nav-link'
    end
  end

  def format_datetime_with_tz(datetime)
    datetime.strftime "%Y-%m-%d %H:%M %Z" unless datetime.nil?
  end

  def format_date_with_tz(date)
    date.in_time_zone(Rails.application.config.time_zone).strftime "%Y-%m-%d %Z" unless date.nil?
  end

  def format_date(date)
    date.strftime "%Y-%m-%d" unless date.nil?
  end
end
