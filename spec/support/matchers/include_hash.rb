RSpec::Matchers.define :include_hash do |expected|
  match do |actual|
    result = true
    expected.each_pair { |key,value|
      if actual[key]!=value
        result = false
      end
    }

    result
  end
end

