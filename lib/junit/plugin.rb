require_relative 'stub'

module Danger
  # Report, or inspect any JUnit XML formatted test suite report.
  #
  # Testing frameworks have standardized on the JUnit XML format for
  # reporting results, this means that projects using Rspec, Jasmine, Mocha,
  # XCTest and more - can all use the same Danger error reporting. Perfect.
  #
  # You can see some examples on [this page from Circle CI](https://circleci.com/docs/test-metadata/)
  # and on this [project's README](https://github.com/orta/danger-junit.git) about how you
  # can add JUnit XML output for your testing projects.
  #
  # @example Parse the XML file, and let the plugin do your reporting
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.report
  #
  # @example Parse multiple XML files by passing multiple file names
  #
  #          junit.parse_files "/path/to/integration-tests.xml", "/path/to/unit-tests.xml"
  #          junit.report
  #
  # @example Parse multiple XML files by passing an array
  #          result_files = %w(/path/to/integration-tests.xml /path/to/unit-tests.xml)
  #          junit.parse_files result_files
  #          junit.report
  #
  # @example Let the plugin parse the XML file, and report yourself
  #
  #          junit.parse "/path/to/output.xml"
  #          fail("Tests failed") unless junit.failures.empty?
  #
  # @example Warn on a report about skipped tests
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.show_skipped_tests = true
  #          junit.report
  #
  # @example Only show specific parts of your results
  #
  #          junit.parse "/path/to/output.xml"
  #          junit.headers = [:name, :file]
  #          junit.report
  #
  # @example Only show specific parts of your results
  #
  #          junit.parse "/path/to/output.xml"
  #          all_test = junit.tests.map(&:attributes)
  #          slowest_test = sort_by { |attributes| attributes[:time].to_f }.last
  #          message "#{slowest_test[:time]} took #{slowest_test[:time]} seconds"
  #
  #
  # @see  orta/danger-junit
  # @see  danger/danger
  # @see  artsy/eigen
  # @tags testing, reporting, junit, rspec, jasmine, jest, xcpretty
  class DangerJunit < Plugin
    # Parses an XML file, which fills all the attributes,
    # will `raise` for errors
    # @return   [void]
    def parse(file)
      parse_files(file)
    end

    # Parses multiple XML files, which fills all the attributes,
    # will `raise` for errors
    # @return   [void]
    def parse_files(*files)
      require 'ox'
      @tests = []
      failed_tests = []

      files.flatten.each do |file|
        raise "No JUnit file was found at #{file}" unless File.exist? file

        xml_string = File.read(file)
        doc = Ox.parse(xml_string)

        suite_root = doc.nodes.first.value == 'testsuites' ? doc.nodes.first : doc
        @tests += find_testcases(suite_root)

        failed_suites = find_testsuites(suite_root).select do |suite|
          suite[:failures].to_i > 0 || suite[:errors].to_i > 0
        end

        failed_suites.each do |suite|
          failed_tests += find_testcases(suite)
        end
      end

      @failures = failed_tests.select do |test|
        test.nodes.count > 0 && test.nodes.first.kind_of?(Ox::Element) && test.nodes.first.value == 'failure'
      end

      @errors = failed_tests.select do |test|
        test.nodes.count > 0 && test.nodes.first.kind_of?(Ox::Element) && test.nodes.first.value == 'error'
      end

      @skipped = @tests.select do |test|
        test.nodes.count > 0 && test.nodes.first.kind_of?(Ox::Element) && test.nodes.first.value == 'skipped'
      end

      @passes = tests - @failures - @errors - @skipped
    end

    # Causes a build fail if there are test failures,
    # and outputs a markdown table of the results.
    #
    # @return   [void]
    def report
      return if failures.nil? # because danger calls `report` before loading a file
      if show_skipped_tests && skipped.count > 0
        warn("Skipped #{skipped.count} tests.")

        message = "### Skipped: \n\n"
        message << get_report_content(skipped, skipped_headers)
        markdown message

      end

      unless failures.empty? && errors.empty?
        fail('Tests have failed, see below for more information.', sticky: false)

        message = "### Tests: \n\n"
        tests = (failures + errors)
        message << get_report_content(tests, headers)

        markdown message
      end
    end

    private

    def get_report_content(tests, headers)
      message = ''
      common_attributes = tests.map{|test| test.attributes.keys }.inject(&:&)

      # check the provided headers are available
      unless headers.nil?
        not_available_headers = headers.select { |header| not common_attributes.include?(header) }
        raise "Some of headers provided aren't available in the JUnit report (#{not_available_headers})" unless not_available_headers.empty?
      end

      keys = headers || common_attributes
      attributes = keys.map(&:to_s).map(&:capitalize)

      # Create the headers
      message << attributes.join(' | ') + "|\n"
      message << attributes.map { |_| '---' }.join(' | ') + "|\n"

      # Map out the keys to the tests
      tests.each do |test|
        row_values = keys.map { |key| test.attributes[key] }.map { |v| auto_link(v) }
        message << row_values.join(' | ') + "|\n"
      end
      message
    end

    def find_testcases(node)
      results = []
      if node.value == 'testcase'
        results << node
      else
        node.nodes.each do |child|
          if child.kind_of?(Ox::Element)
            results.concat(find_testcases(child))
          end
        end
      end
      results
    end

    def find_testsuites(node)
      suites = []
      if node.value == 'testsuite' || node.value == 'testsuites'
        suites << node
      end
      node.nodes.each do |child|
        if child.kind_of?(Ox::Element)
          suites.concat(find_testsuites(child))
        end
      end
      suites
    end

    def auto_link(value)
      if File.exist?(value) && defined?(@dangerfile.github)
        github.html_link(value, full_path: false)
      else
        value
      end
    end
  end
end
