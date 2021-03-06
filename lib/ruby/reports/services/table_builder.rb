require 'facets/hash/rekey'
require 'iron/dsl'

# coding: utf-8
# Ruby namespace
module Ruby
  # Resque::Reports namespace
  module Reports
    # Resque::Reports::Extensions namespace
    module Services
      # Defines report table building logic
      class TableBuilder
        attr_reader :building_header
        pattr_initialize :report, :table_block, :config do
          init_table
        end

        def column(name, value = nil, options = {})
          if (skip_if = options.delete(:skip_if))
            if skip_if.is_a?(Symbol)
              return if report.send(skip_if)
            elsif skip_if.respond_to?(:call)
              return if skip_if.call
            end
          end

          building_header ? add_header_cell(name) : add_row_cell(value, options)
        end

        def build_row(row)
          @row = row.is_a?(Hash) ? row.rekey! : row
          row = DslProxy.exec(self, @row, &table_block)
          cleanup_row
          row
        end

        def build_header
          @building_header = true
          header = DslProxy.exec(self, Dummy.new, &table_block)
          @building_header = false
          header
        end

        private

        def encoded_string(obj)
          obj.to_s.encode(config.encoding, invalid: :replace, undef: :replace)
        end

        def init_table
          @table_header = []
          @table_row = []
        end

        def cleanup_row
          @table_row = []
        end

        def add_header_cell(column_name)
          @table_header << encoded_string(column_name)
        end

        def add_row_cell(column_value, options = {})
          column_value = @row[column_value] if column_value.is_a? Symbol

          if (formatter_name = options[:formatter])
            column_value = report.formatter.send(formatter_name, column_value)
          end

          @table_row << encoded_string(column_value)
        end

        class Dummy
          def method_missing(method, *arguments, &block)
            nil
          end

          def respond_to?(method, include_private = false)
            true
          end
        end
      end
    end
  end
end

