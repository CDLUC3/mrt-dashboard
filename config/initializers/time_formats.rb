Time::DATE_FORMATS[:w3cdtf] = lambda { |time| time.strftime("%Y-%m-%dT%H:%M:%S#{time.formatted_offset}") }
