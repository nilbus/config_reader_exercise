class Configuration
  attr_accessor :path

  def initialize(path)
    @path = path
    @config = load_config(path)
  end

  def [](section_key_pair)
    section, key = extract_section_and_key(section_key_pair)

    @config[section][key]
  end

  def []=(section_key_pair, value)
    section, key = extract_section_and_key(section_key_pair)
    raise FormatError.new "Section name cannot contain [] brackets" if section =~ /[\[\]]/
    raise FormatError.new "Key name cannot contain the : colon character" if key =~ /:/
    @config[section][key] = value.to_s
    save_config_file
  end

  FormatError = Class.new(RuntimeError)

private

  SECTION_PATTERN = /\A\[([^\]]+)\]\s*\z/
  KEY_VALUE_PATTERN = /\A([^:]+):(.+)\z/
  BLANK_LINE = /\A\s*\z/
  CONTINUED_LINE = /^\s+\S/

  def load_config(path)
    lines = File.readlines(path)
    lines = join_mulitline_values(lines)
    current_section = nil
    config = Hash.new { |me, key| me[key] = {} }
    lines.each do |line|
      line.chomp!
      case line
      when BLANK_LINE
        next
      when SECTION_PATTERN
        current_section = line.match(SECTION_PATTERN)[1].strip
      when KEY_VALUE_PATTERN
        raise FormatError.new "Config file must start with a [section name], not #{line.inspect}" if current_section.to_s.empty?
        matches = line.match(KEY_VALUE_PATTERN)
        key = matches[1].strip
        value = matches[2].strip
        config[current_section][key] = value
      else
        raise FormatError.new "Encountered an invalid line: #{line.inspect}"
      end
    end

    config
  end

  def join_mulitline_values(config_lines)
    return config_lines unless config_lines.any? { |line| line =~ CONTINUED_LINE }
    return config_lines.each_with_object([]) do |line, joined_lines|
      if line =~ /\A\s/
        raise FormatError.new "Illegal whitespace at the beginning of the first non-blank line: #{line.inspect}" if joined_lines.empty?
        joined_lines[-1] += line.rstrip
      else
        joined_lines << line.strip
      end
    end
  end

  def extract_section_and_key(pair)
    lookup_key_error = ->{ KeyError.new 'Expected lookup by {"section" => "key"}' }
    section, key = pair.first rescue raise lookup_key_error.call
    raise lookup_key_error.call if section.nil? || key.nil?

    [section.to_s, key.to_s]
  end

  def save_config_file
    File.write path, formatted_config
  end

  def formatted_config
    output = ''
    @config.each do |section, values|
      output << "[#{section}]\r\n"
      values.each do |key, value|
        output << "#{key}: #{value}\r\n"
      end
      output << "\r\n"
    end

    output
  end
end
