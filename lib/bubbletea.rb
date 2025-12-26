# frozen_string_literal: true

require_relative "bubbletea/version"

begin
  major, minor, _patch = RUBY_VERSION.split(".") #: [String, String, String]
  require_relative "bubbletea/#{major}.#{minor}/bubbletea"
rescue LoadError
  require_relative "bubbletea/bubbletea"
end

require_relative "bubbletea/messages"
require_relative "bubbletea/commands"
require_relative "bubbletea/model"
require_relative "bubbletea/runner"

module Bubbletea
  class Error < StandardError; end
end
