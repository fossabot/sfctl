require 'tty-spinner'
require 'tty-table'
require_relative '../command'
require_relative './client'

module Sfctl
  module Toggl
    module Sync
      def self.load_data(output, connection, toggl_config, pastel, report_interval)
        spinner = TTY::Spinner.new("Loaded data from #{Sfctl::Command::TOGGL_PROVIDER}: [:spinner]", format: :dots)
        spinner.auto_spin

        time_entries = get_time_entries(connection, toggl_config, report_interval)

        spinner.success(pastel.green('Done'))

        table = TTY::Table.new %w[Date Comment Time], time_entries_table_rows(time_entries)
        output.puts
        output.print table.render(:unicode, padding: [0, 1], alignments: %i[left left right])
        output.puts
        output.puts

        time_entries['data']
      end

      def self.time_entries_table_rows(time_entries)
        rows = time_entries['data'].sort_by { |te| te['start'] }.map do |te|
          [
            Date.parse(te['start']).to_s,
            te['description'],
            "#{humanize_duration(te['dur'])}h"
          ]
        end
        rows.push(['Total:', '', "#{humanize_duration(time_entries['total_grand'])}h"])
        rows
      end

      def self.get_time_entries(connection, toggl_config, report_interval)
        _success, data = Toggl::Client.time_entries(
          toggl_config['access_token'],
          time_entries_params(connection, report_interval)
        )

        data
      end

      def self.time_entries_params(connection, report_interval)
        start_date, end_date = report_interval
        params = {
          workspace_id: connection['workspace_id'],
          project_ids: connection['project_ids'],
          billable: connection['billable'],
          rounding: connection['rounding'],
          since: start_date.to_s,
          until: end_date.to_s
        }
        params[:task_ids] = connection['task_ids'] if connection['task_ids'].length.positive?
        params
      end

      def self.humanize_duration(milliseconds)
        return '0' if milliseconds.nil?

        seconds = milliseconds / 1000
        minutes = seconds / 60
        int = (minutes / 60).ceil
        dec = minutes % 60
        amount = (dec * 100) / 60
        amount = if dec.zero?
                   ''
                 elsif amount.to_s.length == 1
                   ".0#{amount}"
                 else
                   ".#{amount}"
                 end
        "#{int}#{amount}"
      end

      def self.assignment_items(time_entries)
        time_entries.map do |te|
          {
            time: humanize_duration(te['dur']).to_f,
            date: Date.parse(te['start']).to_s,
            comment: te['description']
          }
        end
      end
    end
  end
end
