module DevcmsCore
  module ActsAsArchive
    extend ActiveSupport::Concern

    # Returns the items in this archive.
    def acts_as_archive_items
      send(acts_as_archive_configuration[:items_name])
    end

    # Finds all items for the month determined by the given +year+, +month+
    # combination.
    def find_all_items_for_month(year, month)
      start_of_month = Date.civil(year, month).to_time
      start_of_next_month = start_of_month + 1.month
      date_field_database_name = acts_as_archive_configuration[:date_field_database_name]

      scope = acts_as_archive_items.where(date_field_database_name + ' >= ? AND ' + date_field_database_name + ' < ?', start_of_month, start_of_next_month)
      item_scope(scope)
    end

    def find_all_items_for_year(year)
      start_of_year = Time.zone.parse("#{year}-1-1").beginning_of_year
      end_of_year = Time.zone.parse("#{year}-1-1").end_of_year
      date_field_database_name = acts_as_archive_configuration[:date_field_database_name]

      scope = acts_as_archive_items.where(date_field_database_name + ' >= ? AND ' + date_field_database_name + ' < ?', start_of_year, end_of_year)
      item_scope(scope)
    end

    # Finds all items for the week determined by the given +year+, +week+
    # combination. Extra parameters can be specified with +args+, these will be
    # passed along to the internal +find+ call.
    def find_all_items_for_week(year, week)
      start_of_week = commercial_date(year, week, 1).beginning_of_week
      start_of_next_week = start_of_week.end_of_week - 1.day
      date_field_database_name = acts_as_archive_configuration[:date_field_database_name]

      scope = acts_as_archive_items.where(date_field_database_name + ' >= ? AND ' + date_field_database_name + ' < ?', start_of_week, start_of_next_week)
      item_scope(scope)
    end

    # Returns an array with all years for which this archive has items.
    def find_years_with_items
      date_field_model_name = acts_as_archive_configuration[:date_field_model_name]

      @years = acts_as_archive_items.map { |item| item.send(date_field_model_name).year }.uniq.sort { |a, b| b <=> a }
    end

    # Returns an array with all years for which this archive has items. This
    # method will be used if weeks are rendered instead of months, as the
    # commercial year can be different for the first week of a new year.
    def find_commercial_years_with_items
      date_field_model_name = acts_as_archive_configuration[:date_field_model_name]

      @years = acts_as_archive_items.map { |item| item.send(date_field_model_name).to_date.cwyear }.uniq.sort { |a, b| b <=> a }
    end

    # Returns an array with all months of the given +year+ for which this
    # archive has items.
    def find_months_with_items_for_year(year)
      @months = []
      start_of_year = Date.civil(year).to_time
      start_of_next_year = start_of_year + 1.year

      date_field_model_name    = acts_as_archive_configuration[:date_field_model_name]
      date_field_database_name = acts_as_archive_configuration[:date_field_database_name]

      scope = acts_as_archive_items.where(date_field_database_name + ' >= ? AND ' + date_field_database_name + ' < ?', start_of_year, start_of_next_year)

      item_scope(scope).each do |item|
        month = item.send(date_field_model_name).month
        @months << month unless @months.include?(month)
      end

      @months.sort { |a, b| b <=> a }
    end

    # Returns an array with all weeks of the given +year+ for which this archive
    # has items. Note that this takes into account that a given day in a
    # commercial week can be in a new year, while the commercial week itself can
    # still belong to the previous year.
    def find_weeks_with_items_for_year(year)
      @weeks = []

      date_field_model_name    = acts_as_archive_configuration[:date_field_model_name]
      date_field_database_name = acts_as_archive_configuration[:date_field_database_name]

      scope = acts_as_archive_items.where(date_field_database_name + ' >= ? AND ' + date_field_database_name + ' < ?', start_of_cwyear(year), start_of_next_cwyear(year))

      item_scope(scope).each do |item|
        week = item.send(date_field_model_name).to_date.cweek
        @weeks << week unless @weeks.include?(week)
      end

      @weeks.sort { |a, b| b <=> a }
    end

    # Destroys all items for the given year or month in a year
    def destroy_items_for_year_or_month(year, month = nil, paranoid_delete = false)
      if month.nil?
        destroy_items_for_year(year.to_i, paranoid_delete)
      else
        destroy_items_for_month(year.to_i, month.to_i, paranoid_delete)
      end
    end

    # Destroys all items for the given year
    def destroy_items_for_year(year, paranoid_delete = false)
      (1..12).each do |month|
        destroy_items_for_month(year, month, paranoid_delete)
      end
    end

    def start_of_cwyear(year)
      commercial_date(year, 1, 7).beginning_of_week
    end

    def start_of_next_cwyear(year)
      (Date.valid_commercial?(year, 53, 7) ? commercial_date(year, 53, 7) : commercial_date(year, 52, 7)).end_of_week + 1.day
    end

    def commercial_date(year, week, day = 1)
      Date.commercial(year, week, day).to_time
    end

    # Destroys all items for the given month in the given year
    def destroy_items_for_month(year, month, paranoid_delete = false)
      find_all_items_for_month(year, month).each do |item|
        if paranoid_delete
          item.node.paranoid_delete!
        else
          item.destroy
        end
      end
    end

    def item_scope(initial_scope)
      sql_options = acts_as_archive_configuration[:sql_options]

      item_scope = initial_scope.order("#{acts_as_archive_configuration[:date_field_database_name]} DESC")
      item_scope = item_scope.includes(sql_options[:include]) if sql_options && sql_options[:include]
      item_scope
    end
  end
end
