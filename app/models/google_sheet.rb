require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

class GoogleSheet
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(sheet_id)
    @sheet_id = sheet_id
  end

  def spreadsheet_service
    @service ||= begin
      authorize = Google::Auth.get_application_default(SCOPE)
      sheet_service = Google::Apis::SheetsV4::SheetsService.new
      sheet_service.key = Rails.application.config.google_api_key
      sheet_service.client_options.application_name = "Ascended Lunar Isle"
      sheet_service.authorization = authorize
      sheet_service
    end
  end

  def spreadsheet
    spreadsheet_service.get_spreadsheet(@sheet_id)
  end

  def named_range(range_name)
    spreadsheet.named_ranges.find{|range| range.name == range_name}.range
  end

  def values_from_named_range(range_name)
    spreadsheet_service.get_spreadsheet_values(@sheet_id, named_range(range_name).to_a1_notation).values
  end
end

module Google
  module Apis
    module SheetsV4
      class GridRange
        # Google API is so freaking dumb.
        # has props:
        # end_column_index
        # end_row_index
        # start_column_index
        # start_row_index
        def to_a1_notation
          notation = ""
          notation << index_to_alpha(start_column_index)
          notation << (start_row_index+1).to_s
          notation << ":" if end_column_index || end_row_index
          notation << index_to_alpha(end_column_index-1) if end_column_index
          notation << end_row_index.to_s
        end

        def index_to_alpha(index)
          val = ""
          while index >= 0
            val << ((index % 26) + 65).chr
            index -= 26
          end
          val
        end
      end
    end
  end
end
