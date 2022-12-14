# frozen_string_literal: true

# Application helper methods
module ApplicationHelper
  # Adapted from: https://stackoverflow.com/questions/9879169/how-to-get-twitter-bootstrap-navigation-to-show-active-link
  def nav_bar(&block)
    tag.ul(class: 'menu nav navbar-nav cds-connect-nav', &block)
  end

  def nav_link(text, path)
    options = current_page?(path) ? { class: 'is-active' } : {}
    tag.li do
      link_to text, path, **options
    end
  end

  def format_datetime_with_tz(datetime)
    datetime&.strftime '%Y-%m-%d %H:%M %Z'
  end

  def format_date(date)
    date&.strftime '%Y-%m-%d'
  end

  def flash_class(level)
    {
      'alert' => 'alert-danger',
      'notice' => 'alert-info',
      'success' => 'alert-success',
      'error' => 'alert-danger',
      'warn' => 'alert-warning'
    }[level]
  end
end
