module RspecApiDocumentation
  module Swaggers
    class Path < Node
      add_setting :get
      add_setting :put
      add_setting :post
      add_setting :delete
      add_setting :options
      add_setting :head
      add_setting :patch
    end
  end
end
