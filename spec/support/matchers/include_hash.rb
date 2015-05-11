RSpec::Matchers.define :include_hash do |expected|
  match do |actual|
    result = true
    expected.each_pair { |key, value|
      result = false if actual[key] != value
    }

    result
  end
end
