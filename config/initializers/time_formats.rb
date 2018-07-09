Time::DATE_FORMATS[:w3cdtf] = ->(time) { time.strftime("%Y-%m-%dT%H:%M:%S#{time.formatted_offset}") }
