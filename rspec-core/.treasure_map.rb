map_for(:default) do |m|

  m.watch 'lib', 'spec'

  m.add_mapping %r%spec/(.*)_spec\.rb% do |match|
    ["spec/#{match[1]}_spec.rb"]
  end

  m.add_mapping %r%spec/spec_helper\.rb% do |match|
    Dir["spec/**/*_spec.rb"]
  end

  m.add_mapping %r%lib/(.*)\.rb% do |match|
    examples_matching match[1]
  end

end