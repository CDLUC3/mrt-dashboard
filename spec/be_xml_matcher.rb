require 'rspec/expectations'
require 'equivalent-xml'
require 'diffy'

module BeXmlMatcher
  def self.to_nokogiri(xml)
    return nil unless xml
    case xml
      when Nokogiri::XML::Element
        xml
      when Nokogiri::XML::Document
        xml.root
      when String
        to_nokogiri(Nokogiri::XML(xml, &:noblanks))
      else
        raise "be_xml() expected XML, got #{xml.class}"
    end
  end

  def self.to_pretty(nokogiri)
    return nil unless nokogiri
    out          = StringIO.new
    save_options = Nokogiri::XML::Node::SaveOptions::FORMAT | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
    nokogiri.write_xml_to(out, encoding: 'UTF-8', indent: 2, save_with: save_options)
    out.string
  end

  def self.equivalent?(expected, actual, filename = nil)
    expected_xml = to_nokogiri(expected) || raise("expected value #{expected || 'nil'} does not appear to be XML#{" in #{filename}" if filename}")
    actual_xml   = to_nokogiri(actual)

    EquivalentXml.equivalent?(expected_xml, actual_xml, element_order: false, normalize_whitespace: true)
  end

  def self.failure_message(expected, actual, filename = nil)
    expected_string = to_pretty(to_nokogiri(expected))
    actual_string   = to_pretty(to_nokogiri(actual)) || actual

    # now = Time.now.to_i
    # FileUtils.mkdir('tmp') unless File.directory?('tmp')
    # File.open("tmp/#{now}-expected.xml", 'w') { |f| f.write(expected_string) }
    # File.open("tmp/#{now}-actual.xml", 'w') { |f| f.write(actual_string) }

    diff = Diffy::Diff.new(expected_string, actual_string).to_s(:text)

    "expected XML differs from actual#{" in #{filename}" if filename}:\n#{diff}"
  end

  def self.to_xml_string(actual)
    to_pretty(to_nokogiri(actual))
  end

  def self.failure_message_when_negated(actual, filename = nil)
    "expected not to get XML#{" in #{filename}" if filename}:\n\t#{to_xml_string(actual) || 'nil'}"
  end
end

RSpec::Matchers.define :be_xml do |expected, filename = nil|
  match { |actual| BeXmlMatcher.equivalent?(expected, actual, filename) }

  failure_message { |actual| BeXmlMatcher.failure_message(expected, actual, filename) }

  failure_message_when_negated { |actual| BeXmlMatcher.failure_message_when_negated(actual, filename) }
end
