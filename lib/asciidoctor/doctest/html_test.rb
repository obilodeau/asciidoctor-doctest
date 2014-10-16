require 'nokogiri'
require 'asciidoctor/doctest/base_test'
require 'asciidoctor/doctest/html_beautifier'
require 'asciidoctor/doctest/html_normalizer'

module Asciidoctor
  module DocTest
    class HtmlTest < BaseTest

      def self.read_tested_suite(suite_name)
        super.each_value do |opts|
          # Render 'document' examples as a full document with header and footer.
          opts[:header_footer] = [true] if suite_name.start_with? 'document'
          # When asserting inline examples, ignore paragraph "wrapper".
          opts[:include] ||= ['.//p/node()'] if suite_name.start_with? 'inline_'
        end
      end

      def assert_example(expected, actual, opts)
        actual = parse_html(actual, !opts.key?(:header_footer))
        expected = parse_html(expected)

        # Select nodes specified by the XPath expression.
        opts.fetch(:include, []).each do |xpath|
          # xpath returns NodeSet, but we need DocumentFragment, so convert it again
          actual = parse_html(actual.xpath(xpath).to_html)
        end

        # Remove nodes specified by the XPath expression.
        opts.fetch(:exclude, []).each do |xpath|
          actual.xpath(xpath).each(&:remove)
        end

        assert_equal expected.to_html, actual.to_html
      end

      ##
      # Returns a human-readable (formatted) version of +html+.
      # @note Overrides method from +Minitest::Assertions+.
      def mu_pp(html)
        HtmlBeautifier.beautify html
      end

      def parse_html(str, fragment = true)
        nokogiri = fragment ? Nokogiri::HTML::DocumentFragment : Nokogiri::HTML
        nokogiri.parse(str).normalize!
      end
    end
  end
end