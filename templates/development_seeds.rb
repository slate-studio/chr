if Rails.env.development? || Rails.env.test?
  require "factory_girl"

  namespace :dev do
    desc "Seed data for development environment"
    task prime: "db:setup" do
      include FactoryGirl::Syntax::Methods

      Admin.create!(name: 'Admin', email: 'user@example.com', password: 'password')
    end
  end
end
