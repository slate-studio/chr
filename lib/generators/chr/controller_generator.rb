require 'rails/generators/base'

module Chr
  module Generators
    class ControllerGenerator < Rails::Generators::Base
      def create_controller
        generate "controller", "admin/#{ARGV[0]} --skip-template-engine"

        inject_into_file(
          "config/routes.rb",
          "\n\tnamespace :admin do\n\t\tresources :#{ARGV[0]}\n\tend",
          after: "Application.routes.draw do",
        )
      end
    end
  end
end
